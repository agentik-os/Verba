import AppKit
import Combine
import Sparkle

/// Silent auto-updates via Sparkle. Reads `SUFeedURL` + `SUPublicEDKey` from the
/// Info.plist, checks on a schedule, and installs signed updates in the
/// background (the user just gets a "relaunch to update" prompt).
///
/// Also publishes update state so the menu-bar (a prominent "Install update" item
/// + an icon badge) and Settings (auto-check / auto-download toggles, current
/// version, last-checked) can reflect what Sparkle found WITHOUT forcing a popup —
/// the delegate's `didFindValidUpdate` fires on silent background checks too.
final class Updater: ObservableObject {
    static let shared = Updater()

    let controller: SPUStandardUpdaterController
    private let delegate = UpdaterDelegate()

    /// True once Sparkle reports a newer version on the appcast (via the delegate).
    @Published private(set) var updateAvailable = false
    /// The display version of the available update (e.g. "1.2.0"), when one is found.
    /// Cleared again as soon as a check reports no update, so a pulled or rolled-back
    /// release can never leave a phantom version behind in the menu / prompts.
    @Published private(set) var latestVersion: String?
    /// When the last SUCCESSFUL check completed. A failed check does not stamp this —
    /// it sets `lastError` instead, so the UI can never show a fresh "checked just now"
    /// for a check that never reached the appcast.
    @Published private(set) var lastChecked: Date?
    /// Why the last check failed, when it did. Cleared by the next successful check.
    @Published private(set) var lastError: String?

    /// R8: queried right before a Sparkle-driven install/relaunch. Set by AppDelegate; returns
    /// true while a recording is live or dictations are still processing, so an update never
    /// silently kills an active dictation. Always called on the main thread.
    var isBusy: () -> Bool = { false }

    /// Presents the "Install update and relaunch now?" prompt. AppDelegate replaces this at
    /// launch with a Liquid Glass panel (GlassAlertView via makeWindow(glass:)+presentFocused);
    /// the closure receives Sparkle's install handler to invoke on confirmation. The default
    /// (pre-wiring — unreachable in practice, isBusy can't be true before launch finishes)
    /// postpones: Sparkle then installs the update on the next quit. Called on the main thread.
    var presentRelaunchPrompt: (@escaping () -> Void) -> Void = { _ in }

    private init() {
        // startingUpdater: FALSE on purpose. With `true`, Sparkle starts its update cycle inside
        // this initializer — i.e. BEFORE the two lines below run — so a check kicked off at launch
        // would resolve with `delegate.owner` still nil (its result silently dropped, leaving the
        // menu indicator and `lastChecked` stale) and with the persisted SUAutomaticallyUpdate
        // default still in force. Wire everything first, then start.
        controller = SPUStandardUpdaterController(startingUpdater: false,
                                                  updaterDelegate: delegate,
                                                  userDriverDelegate: nil)
        delegate.owner = self
        // Belt-and-suspenders with Info.plist SUAutomaticallyUpdate=false: never silently pre-download
        // an update in the background (which could stage an intermediate build). Sparkle still checks
        // on schedule; the actual download happens on the user's Update click, fetching the LATEST.
        controller.updater.automaticallyDownloadsUpdates = false
        controller.startUpdater()
    }

    /// User-initiated check (menu / Settings): shows UI even if already up to date.
    /// Verba is a menu-bar / accessory app, so we must ACTIVATE it first — otherwise Sparkle's
    /// update window opens unfocused behind everything and it looks like the button did nothing.
    func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        controller.updater.checkForUpdates()
    }

    /// Install the found update — runs Sparkle's download/install/relaunch UI (brought to front).
    func installUpdate() { checkForUpdates() }

    /// Silent background check — refreshes the menu indicator without a popup.
    func checkInBackground() { controller.updater.checkForUpdatesInBackground() }

    /// Sparkle's "automatically check for updates" setting (proxied for Settings).
    var autoCheck: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Sparkle's "automatically download & install updates" setting (proxied for Settings).
    var autoDownload: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }

    /// The marketing version (`CFBundleShortVersionString`), falling back to `CFBundleVersion`
    /// rather than the meaningless "0" — bundle.sh stamps both to the same release string, so a
    /// missing short key still yields the real version instead of a wrong one in feedback,
    /// crash reports and Settings.
    static var currentVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
            ?? "0"
    }

    /// The build version (`CFBundleVersion`) — the field the appcast's `sparkle:version` is
    /// compared against. Read separately from `currentVersion` so the guard below compares
    /// like for like even if the two Info.plist keys ever diverge.
    static var currentBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? "0"
    }

    fileprivate func didFind(_ item: SUAppcastItem) {
        // `sparkle:version` (build) is what Sparkle compares; `sparkle:shortVersionString` is
        // what we show. generate_appcast emits both on the enclosure.
        let build = item.versionString
        let display = item.displayVersionString
        // Never light up "update available" for the version we are already running. Sparkle's
        // comparator normally filters that, but an appcast that was rolled back, republished
        // at the same version, or served without a usable version string must not produce a
        // false positive that sends the user into a download of the build they already have.
        guard !build.isEmpty, build != Self.currentBuild else {
            VerbaLog.updater.info("ignoring appcast item that is not newer than the running build (feed=\(build, privacy: .public), running=\(Self.currentBuild, privacy: .public))")
            didNotFind()
            return
        }
        VerbaLog.updater.info("update available: \(display.isEmpty ? build : display, privacy: .public) (running \(Self.currentVersion, privacy: .public))")
        DispatchQueue.main.async {
            self.updateAvailable = true
            self.latestVersion = display.isEmpty ? build : display
            self.lastChecked = Date()
            self.lastError = nil
        }
    }

    fileprivate func didNotFind() {
        DispatchQueue.main.async {
            self.updateAvailable = false
            // Clear the version too: leaving the previously found one behind made the menu and
            // the install prompt advertise a release that the feed no longer offers.
            self.latestVersion = nil
            self.lastChecked = Date()
            self.lastError = nil
        }
    }

    /// A check that never reached a verdict (offline, appcast 404 / unparsable, signature
    /// mismatch). Sparkle otherwise fails these silently: no delegate callback fires, so the
    /// UI keeps showing the previous `lastChecked` as if the check had succeeded.
    fileprivate func didFailCheck(_ error: NSError) {
        VerbaLog.updater.error("update check failed: \(error.localizedDescription, privacy: .public) [\(error.domain, privacy: .public) \(error.code)]")
        DispatchQueue.main.async {
            self.lastError = error.localizedDescription
        }
    }
}

/// A tiny delegate that mirrors Sparkle's results onto the observable `Updater`.
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    weak var owner: Updater?

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        owner?.didFind(item)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        owner?.didNotFind()
    }

    /// The failure funnel. `didFindValidUpdate` / `updaterDidNotFindUpdate` only cover the two
    /// happy paths, so an offline check, a 404 appcast, an unparsable feed or an EdDSA mismatch
    /// produced NO callback at all and no log line: the app went on showing a stale "last
    /// checked" and a stale update indicator forever.
    ///
    /// This is the widest hook Sparkle offers: it fires for every aborted cycle, whereas
    /// `updater:didFinishUpdateCycleForUpdateCheck:error:` is skipped whenever the driver is
    /// about to show update UI immediately (Sparkle SPUUpdater.m:794-813) — implementing both
    /// would only double-report the same NSError. Two outcomes reach here that are not failures
    /// and are filtered out: `SUNoUpdateError` ("already up to date", which
    /// `updaterDidNotFindUpdate` has just handled) and `SUInstallationCanceledError` (the user
    /// dismissed the install). Sparkle itself declines to log both (SPUUpdater.m:798).
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let error = error as NSError
        guard error.code != Int(SUError.noUpdateError.rawValue),
              error.code != Int(SUError.installationCanceledError.rawValue) else { return }
        owner?.didFailCheck(error)
    }

    /// R8: Sparkle is about to relaunch to install. If a recording is live or Sessions are still
    /// processing, postpone the relaunch and ask the user first — a silent relaunch would discard
    /// them. "Not Now" leaves the handler uninvoked, so Sparkle falls back to installing the
    /// update on the next quit instead of dropping it.
    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        guard let owner, owner.isBusy() else { return false }   // idle → relaunch immediately
        VerbaLog.updater.info("postponing update relaunch: a dictation is recording or processing")
        // Liquid Glass prompt (wired by AppDelegate) instead of a stock NSAlert; "Not Now"
        // leaves the handler uninvoked, so Sparkle installs the update on the next quit.
        DispatchQueue.main.async {
            owner.presentRelaunchPrompt(installHandler)
        }
        return true
    }
}
