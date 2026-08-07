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

    /// Presents the later "finish updating?" prompt when a postponed install is re-offered on
    /// an idle moment. Wired by AppDelegate like `presentRelaunchPrompt`; the closure receives
    /// the action to run on confirmation. Called on the main thread.
    var presentReofferPrompt: (@escaping () -> Void) -> Void = { _ in }

    // MARK: - Postponed-update memory & idle re-offer
    //
    // Verba is LSUIElement and lives in the menu bar for weeks, so Sparkle's fallback of
    // "install on the next quit" after a postponed relaunch can mean months, or never.
    // One "Not Now" must not strand the user on an old build: remember the postpone and
    // politely re-offer the install once the app is idle again, bounded below.

    private enum PostponeKeys {
        static let version = "updatePostpone.version"           // display version the user postponed
        static let at = "updatePostpone.at"                     // when they postponed (epoch seconds)
        static let offerDay = "updatePostpone.offerDay"         // day the offer counter belongs to
        static let offersToday = "updatePostpone.offersToday"   // relaunch offers shown that day
        static let lastOfferAt = "updatePostpone.lastOfferAt"   // last offer of any kind (epoch seconds)
        static let firstSeenVersion = "updateFirstSeen.version" // version the first-seen stamp is for
        static let firstSeenAt = "updateFirstSeen.at"           // when that version first appeared (epoch seconds)
    }

    /// Minimum gap between two install offers (the busy-postpone prompt counts as one).
    private static let reofferMinGap: TimeInterval = 2 * 60 * 60
    /// Ceiling on install offers per calendar day; beyond it the menu surface carries the state.
    private static let reofferMaxPerDay = 3
    /// How often the idle re-offer check runs. Each tick is a cheap guard cascade.
    private static let reofferCheckInterval: TimeInterval = 15 * 60
    /// An update unapplied for this long is "long pending": the menu-bar surface says so.
    static let longPendingThreshold: TimeInterval = 3 * 24 * 60 * 60

    /// Sparkle's install handler from a postponed relaunch. Invoking it resumes the exact
    /// staged install; it is only reused while that build is still the latest on the feed,
    /// otherwise a re-offer goes through a fresh check so the LATEST build is what lands.
    fileprivate var pendingInstallHandler: (() -> Void)?
    private var reofferTimer: Timer?

    /// The display version the user postponed, while one is pending. Persisted so a postpone
    /// survives a relaunch (the in-memory handler does not; the fresh-check path covers that).
    var postponedVersion: String? { UserDefaults.standard.string(forKey: PostponeKeys.version) }

    /// When the currently available update was FIRST seen on the feed. Nil when up to date or
    /// when the stamp belongs to another version. Feeds the "pending for N days" menu surface.
    var updatePendingSince: Date? {
        guard updateAvailable else { return nil }
        let d = UserDefaults.standard
        guard d.string(forKey: PostponeKeys.firstSeenVersion) == latestVersion else { return nil }
        let t = d.double(forKey: PostponeKeys.firstSeenAt)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    /// Called (from the prompt wiring in AppDelegate) when the user answers an install offer
    /// with Not Now. Records WHICH version was postponed and when, so the decision is no longer
    /// fire and forget and the re-offer loop has something to work from.
    func recordPostpone() {
        let version = latestVersion ?? "unknown"
        let d = UserDefaults.standard
        d.set(version, forKey: PostponeKeys.version)
        d.set(Date().timeIntervalSince1970, forKey: PostponeKeys.at)
        VerbaLog.updater.info("update postponed: version=\(version, privacy: .public); will re-offer when idle")
    }

    /// Stamps offer bookkeeping (per-day count + last-offer time) whenever an install offer is
    /// actually shown, whatever the user answers. Keeps the re-offer cadence honest and bounded.
    fileprivate func noteOfferShown() {
        let d = UserDefaults.standard
        let today = Self.dayString(Date())
        if d.string(forKey: PostponeKeys.offerDay) != today {
            d.set(today, forKey: PostponeKeys.offerDay)
            d.set(0, forKey: PostponeKeys.offersToday)
        }
        d.set(d.integer(forKey: PostponeKeys.offersToday) + 1, forKey: PostponeKeys.offersToday)
        d.set(Date().timeIntervalSince1970, forKey: PostponeKeys.lastOfferAt)
    }

    /// Stamps when a version first showed up on the feed, and invalidates a postponed install
    /// that a NEWER release has superseded — resuming its held handler would land the old build.
    fileprivate func noteVersionSeen(_ version: String) {
        let d = UserDefaults.standard
        if d.string(forKey: PostponeKeys.firstSeenVersion) != version {
            d.set(version, forKey: PostponeKeys.firstSeenVersion)
            d.set(Date().timeIntervalSince1970, forKey: PostponeKeys.firstSeenAt)
        }
        if let postponed = d.string(forKey: PostponeKeys.version), postponed != version {
            VerbaLog.updater.info("postponed update superseded: postponed=\(postponed, privacy: .public), latest=\(version, privacy: .public); dropping stale install handler")
            pendingInstallHandler = nil
            clearPostponeRecord()
        }
    }

    private func clearPostponeRecord() {
        let d = UserDefaults.standard
        d.removeObject(forKey: PostponeKeys.version)
        d.removeObject(forKey: PostponeKeys.at)
        // Offer-day counters are left alone on purpose: they self-reset daily and keeping them
        // means a superseding release cannot be used to exceed the per-day offer ceiling.
    }

    /// The idle re-offer tick. Runs on the main run loop every `reofferCheckInterval`; every
    /// guard below is deliberate and each exit is silent (a quiet tick is the normal case).
    private func maybeReofferPostponedUpdate() {
        guard updateAvailable, let postponed = postponedVersion else { return }
        // Absolute: never interrupt a live recording or processing dictations. That constraint
        // is the whole reason the postpone path exists.
        guard !isBusy() else { return }
        let d = UserDefaults.standard
        let now = Date()
        let last = Date(timeIntervalSince1970: d.double(forKey: PostponeKeys.lastOfferAt))
        guard now.timeIntervalSince(last) >= Self.reofferMinGap else { return }
        let offersToday = d.string(forKey: PostponeKeys.offerDay) == Self.dayString(now)
            ? d.integer(forKey: PostponeKeys.offersToday) : 0
        guard offersToday < Self.reofferMaxPerDay else { return }
        // Prefer resuming Sparkle's staged install (the build the user already agreed to), but
        // ONLY while it is still the latest on the feed. Anything else goes through a fresh
        // user-facing check so the download happens at install time and the LATEST lands.
        let install: () -> Void
        if let handler = pendingInstallHandler, postponed == (latestVersion ?? postponed) {
            install = { [weak self] in
                VerbaLog.updater.info("user accepted re-offered update: resuming staged install of \(postponed, privacy: .public)")
                self?.pendingInstallHandler = nil
                handler()
            }
        } else {
            pendingInstallHandler = nil
            install = { [weak self] in
                VerbaLog.updater.info("user accepted re-offered update: running fresh install flow for \(postponed, privacy: .public)")
                self?.installUpdate()
            }
        }
        noteOfferShown()
        VerbaLog.updater.info("re-offering postponed update: version=\(postponed, privacy: .public), offer \(offersToday + 1) of \(Self.reofferMaxPerDay) today")
        presentReofferPrompt(install)
    }

    private static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

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
        // Idle re-offer loop for a postponed install (see the MARK below). Scheduled on the main
        // run loop explicitly: `isBusy` and the prompt closures are main-thread contracts.
        let t = Timer(timeInterval: Self.reofferCheckInterval, repeats: true) { [weak self] _ in
            self?.maybeReofferPostponedUpdate()
        }
        t.tolerance = 120
        RunLoop.main.add(t, forMode: .common)
        reofferTimer = t
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
            self.noteVersionSeen(display.isEmpty ? build : display)
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
            // Up to date resolves any pending postpone: stop re-offering, drop the stale state.
            // This is also how a postpone left behind by an install-on-quit gets cleaned up.
            if let postponed = self.postponedVersion {
                VerbaLog.updater.info("postponed update resolved: app is up to date, clearing postpone of \(postponed, privacy: .public)")
            }
            self.pendingInstallHandler = nil
            self.clearPostponeRecord()
            let d = UserDefaults.standard
            d.removeObject(forKey: PostponeKeys.firstSeenVersion)
            d.removeObject(forKey: PostponeKeys.firstSeenAt)
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
    /// update on the next quit — but Verba is a menu-bar app that may never quit, so the owner
    /// also KEEPS the handler and re-offers the install on a later idle moment (see the
    /// postponed-update section in `Updater`).
    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        guard let owner, owner.isBusy() else { return false }   // idle → relaunch immediately
        VerbaLog.updater.info("postponing update relaunch: a dictation is recording or processing")
        // Liquid Glass prompt (wired by AppDelegate) instead of a stock NSAlert; "Not Now"
        // leaves the handler uninvoked, so Sparkle installs the update on the next quit.
        DispatchQueue.main.async {
            owner.pendingInstallHandler = installHandler
            owner.noteOfferShown()
            owner.presentRelaunchPrompt(installHandler)
        }
        return true
    }

    /// Fires when an install actually begins, whichever path got it there (immediate relaunch,
    /// re-offered install, or install-on-quit). Together with the postpone / re-offer lines this
    /// makes a stranded user diagnosable from one log query on the "updater" category.
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        let version = item.displayVersionString.isEmpty ? item.versionString : item.displayVersionString
        VerbaLog.updater.info("installing update \(version, privacy: .public) (build \(item.versionString, privacy: .public))")
    }

    /// The moment the update truly lands for a running menu-bar app: the relaunch.
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        VerbaLog.updater.info("relaunching to complete update install")
    }
}
