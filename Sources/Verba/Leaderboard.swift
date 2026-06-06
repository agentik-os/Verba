import Foundation

/// Public leaderboard entry (no email, ever, only the alias + metrics).
struct LeaderEntry: Identifiable, Decodable {
    let uid: String
    let alias: String
    let words: Double
    let wpm: Double
    let streak: Double
    let saved: Double?
    var id: String { uid }
}

/// Talks to the shared Convex leaderboard over its HTTP API.
enum Leaderboard {
    private static let base = "https://fortunate-aardvark-443.convex.cloud"

    /// Push this account's current stats (alias + totals). Optional completion on main.
    static func submit(_ done: @escaping () -> Void = {}) {
        let s = Settings.shared
        let uid = s.uid
        let alias = s.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !alias.isEmpty else { DispatchQueue.main.async { done() }; return }
        let args: [String: Any] = [
            "uid": uid, "alias": alias,
            "words": Stats.shared.totalWords, "wpm": Stats.shared.avgWPM,
            "streak": Stats.shared.streak, "saved": Stats.shared.timeSavedMinutes,
        ]
        post("mutation", path: "leaderboard:submit", args: args) { _ in DispatchQueue.main.async { done() } }
    }

    /// Delete a stale score row (the device-minted uid) after sign-in re-keys the identity.
    static func remove(uid: String) {
        post("mutation", path: "leaderboard:remove", args: ["uid": uid]) { _ in }
    }

    /// Fetch the whole board (alias + metrics only).
    static func fetch(_ done: @escaping ([LeaderEntry]) -> Void) {
        post("query", path: "leaderboard:board", args: [:]) { data in
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

    private static func post(_ kind: String, path: String, args: [String: Any], _ done: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(base)/api/\(kind)") else { done(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        URLSession.shared.dataTask(with: req) { data, _, _ in done(data) }.resume()
    }
}
