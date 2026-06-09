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

    private init() {
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: delegate,
                                                  userDriverDelegate: nil)
        delegate.owner = self
    }

    /// User-initiated check (menu / Settings): shows UI even if already up to date.
    func checkForUpdates() { controller.updater.checkForUpdates() }

    /// Install the found update — runs Sparkle's download/install/relaunch UI.
    func installUpdate() { controller.updater.checkForUpdates() }

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
}
