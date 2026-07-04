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
    @Published private(set) var latestVersion: String?
    /// When the last (background or user) check completed.
    @Published private(set) var lastChecked: Date?

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
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: delegate,
                                                  userDriverDelegate: nil)
        delegate.owner = self
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

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    fileprivate func didFind(_ item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateAvailable = true
            self.latestVersion = item.displayVersionString
            self.lastChecked = Date()
        }
    }

    fileprivate func didNotFind() {
        DispatchQueue.main.async {
            self.updateAvailable = false
            self.lastChecked = Date()
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
