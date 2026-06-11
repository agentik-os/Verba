import Foundation
import Security

/// Per-DEVICE secret that authenticates this Mac's Convex writes. One secret per device
/// (not per uid): the device registers the same secret under every uid it legitimately
/// uses (its `deviceUid`, and the account uid after a token-verified sign-in).
/// Never deleted on sign-out (it still authenticates the device uid).
enum DeviceSecret {
    /// 32 random bytes, hex (64 chars), minted once, Keychain-persisted.
    static var current: String {
        if let s = Keychain.get("convex_device_secret"), !s.isEmpty { return s }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)
        let s = bytes.map { String(format: "%02x", $0) }.joined()
        Keychain.set(s, for: "convex_device_secret")
        return s
    }
}

/// Single home for the Convex deployment URL + the HTTP plumbing that used to be
/// copy-pasted in History.swift, NotesStore.swift, Stores.swift and Leaderboard.swift.
enum ConvexClient {
    static let base = "https://prestigious-wolf-290.eu-west-1.convex.cloud"

    /// uid + device secret, merged into every private call's args.
    static func authedArgs(_ extra: [String: Any] = [:]) -> [String: Any] {
        var a = extra
        a["uid"] = Settings.shared.uid
        a["secret"] = DeviceSecret.current
        return a
    }

    /// kind = "query" | "mutation". Callback receives raw response Data (nil on transport error).
    static func call(_ kind: String, _ path: String, _ args: [String: Any], _ cb: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(base)/api/\(kind)") else { cb(nil); return }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }

    /// Registers this device's secret under the current uid (idempotent; the server dedups).
    /// A valid account token is required to claim a non-anonymous (account) uid.
    static func registerDevice(token: String?) {
        var args: [String: Any] = ["uid": Settings.shared.uid, "secret": DeviceSecret.current]
        if let token { args["token"] = token }
        call("mutation", "auth:register", args) { _ in }
    }
}
