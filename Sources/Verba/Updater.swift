import AppKit
import Sparkle

/// Silent auto-updates via Sparkle. Reads `SUFeedURL` + `SUPublicEDKey` from the
/// Info.plist, checks on a schedule, and installs signed updates in the
/// background (the user just gets a "relaunch to update" prompt).
final class Updater {
    static let shared = Updater()

    let controller: SPUStandardUpdaterController

    private init() {
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
    }

    /// User-initiated check (menu): shows UI even if already up to date.
    func checkForUpdates() { controller.updater.checkForUpdates() }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
