import Foundation

/// Shared between the app and the keyboard via the App Group.
public enum Verba {
    public static let appGroup = "group.com.agentik.verba"
    public static let modes = ["Flow", "Polish", "Casual", "Intent", "Coding"]

    /// The keyboard writes the requested mode; the app reads it. The app writes the
    /// finished text; the keyboard reads + inserts it then clears it.
    public static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
    public static func setPendingResult(_ s: String) { defaults?.set(s, forKey: "pendingResult") }
    public static func takePendingResult() -> String? {
        guard let s = defaults?.string(forKey: "pendingResult"), !s.isEmpty else { return nil }
        defaults?.removeObject(forKey: "pendingResult"); return s
    }
}
