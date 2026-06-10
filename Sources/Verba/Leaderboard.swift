import Foundation

/// Public leaderboard entry (no email — and no uid once the server strips it; only the
/// alias + metrics). `me` is set server-side when the caller proved its identity
/// (uid + device secret), so views can highlight the user's own row without any uid.
struct LeaderEntry: Identifiable, Decodable {
    let id = UUID().uuidString   // local-only identity; the server no longer exposes uids
    let uid: String?             // legacy field, nil once the server strips it (views move to `me`, HANDOFF-3)
    let alias: String
    let words: Double
    let wpm: Double
    let streak: Double
    let saved: Double?
    let me: Bool?

    private enum CodingKeys: String, CodingKey { case uid, alias, words, wpm, streak, saved, me }
}

/// Talks to the shared Convex leaderboard through the shared ConvexClient (S16).
enum Leaderboard {

    /// Push this account's current stats (alias + totals). Optional completion on main.
    static func submit(_ done: @escaping () -> Void = {}) {
        let s = Settings.shared
        guard s.showOnLeaderboard else { DispatchQueue.main.async { done() }; return }   // opted out → never publish
        let alias = s.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !alias.isEmpty else { DispatchQueue.main.async { done() }; return }
        let args = ConvexClient.authedArgs([
            "alias": alias,
            "words": Stats.shared.totalWords, "wpm": Stats.shared.avgWPM,
            "streak": Stats.shared.streak, "saved": Stats.shared.timeSavedMinutes,
        ])
        // Chain submit AFTER auth:register commits, so a fresh device's secret is keyed under
        // its uid before the authed submit runs — otherwise the first submit can race ahead of
        // registration and be rejected, silently dropping the device's first board appearance.
        var registerArgs: [String: Any] = ["uid": s.uid, "secret": DeviceSecret.current]
        if let token = AuthToken.current { registerArgs["token"] = token }
        ConvexClient.call("mutation", "auth:register", registerArgs) { _ in
            ConvexClient.call("mutation", "leaderboard:submit", args) { _ in DispatchQueue.main.async { done() } }
        }
    }

    /// Delete a stale score row after sign-in/out re-keys the identity. You can only remove
    /// YOUR OWN row: this device's secret is registered under the old uid too.
    static func remove(uid: String) {
        ConvexClient.call("mutation", "leaderboard:remove",
                          ["uid": uid, "secret": DeviceSecret.current]) { _ in }
    }

    /// Fetch the whole board (alias + metrics only). Passing uid+secret lets the server
    /// mark the caller's own row with `me: true`.
    static func fetch(_ done: @escaping ([LeaderEntry]) -> Void) {
        ConvexClient.call("query", "leaderboard:board", ConvexClient.authedArgs()) { data in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let value = obj["value"],
                  let vd = try? JSONSerialization.data(withJSONObject: value),
                  let entries = try? JSONDecoder().decode([LeaderEntry].self, from: vd) else {
                DispatchQueue.main.async { done([]) }; return
            }
            DispatchQueue.main.async { done(entries) }
        }
    }
}
