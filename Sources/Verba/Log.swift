import Foundation
import os

/// Tiny logging façade (R14): a thin os.Logger wrapper so errors that used to be swallowed in
/// silent `catch`es land in the unified log — inspectable via Console.app or
/// `log stream --predicate 'subsystem == "run.verba.app"'`.
enum VerbaLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "run.verba.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let updater = Logger(subsystem: subsystem, category: "updater")

    // MARK: - Repeated-sync-failure surfacing (R14)

    /// Set by AppDelegate: routes a "cloud sync keeps failing" notice to the user-visible
    /// channel (overlay error flash, or the menu-bar text flash in menu-bar-only mode).
    static var onRepeatedSyncFailure: ((String) -> Void)?

    private static var syncFailureCount = 0
    private static var syncFailureSurfaced = false
    private static let lock = NSLock()

    /// Record a cloud-sync / persistence failure. Always logged; surfaced to the user ONCE per
    /// session once it repeats (a single transient blip stays silent — data is safe locally).
    static func syncFailure(_ context: String, error: Error? = nil) {
        let detail = error.map { "\(context): \($0.localizedDescription)" } ?? context
        sync.error("\(detail, privacy: .public)")
        lock.lock()
        syncFailureCount += 1
        let surface = syncFailureCount >= 2 && !syncFailureSurfaced
        if surface { syncFailureSurfaced = true }
        lock.unlock()
        if surface {
            DispatchQueue.main.async {
                onRepeatedSyncFailure?("Cloud sync is failing — your data is safe locally")
            }
        }
    }
}
