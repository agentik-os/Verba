import Foundation

struct WishComment: Identifiable, Decodable {
    let id: String
    let author: String
    let text: String
    let createdAt: String

    /// `createdAt` as an ISO-8601 date, when parseable (Linear sends fractional seconds).
    var created: Date? { WishComment.iso.date(from: createdAt) }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

struct WishItem: Identifiable, Decodable {
    let id: String
    let text: String
    let author: String
    let votes: Double
    let shipped: Bool
    let commentCount: Int
    let comments: [WishComment]
    /// Server-computed "I voted on this" (S12 — replaces the leaked `voters` uid list).
    private let serverMine: Bool

    private enum CodingKeys: String, CodingKey {
        case id, text, author, votes, shipped, commentCount, comments, mine
    }

    /// "Did I vote on this?" — the server's `mine` flag (set when the caller proved its
    /// device identity), merged with the local vote cache for unauthenticated fetches.
    var mine: Bool { serverMine || Wishlist.votedIDs.contains(id) }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        author = try c.decode(String.self, forKey: .author)
        votes = try c.decode(Double.self, forKey: .votes)
        // HANDOFF-5: the hardened server returns `mine` instead of the voters uid list.
        serverMine = (try? c.decodeIfPresent(Bool.self, forKey: .mine)) ?? false
        // The bridge always sends shipped; tolerate its absence to stay forward/backward compatible.
        shipped = (try? c.decodeIfPresent(Bool.self, forKey: .shipped)) ?? false
        comments = (try? c.decodeIfPresent([WishComment].self, forKey: .comments)) ?? []
        commentCount = (try? c.decodeIfPresent(Int.self, forKey: .commentCount)) ?? comments.count
    }
}

/// Shared feature wishlist with upvotes, routed through the verba.run bridge so the
/// app receives the `shipped` flag (derived from the linked Linear issue's state).
enum Wishlist {
    private static let endpoint = "https://verba.run/api/wishlist"
    static var myUID: String {
        let s = Settings.shared
        return s.uid
    }

    static func list(_ done: @escaping ([WishItem]) -> Void) {
        get { data in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["ok"] as? Bool == true,
                  let value = obj["items"],
                  let vd = try? JSONSerialization.data(withJSONObject: value),
                  let items = try? JSONDecoder().decode([WishItem].self, from: vd) else {
                DispatchQueue.main.async { done([]) }; return
            }
            DispatchQueue.main.async { done(items) }
        }
    }

    // MARK: Local vote cache (replaces the server's voters uid list, which leaked uids).
    private static let votedKey = "wishlist.votedIDs"
    static var votedIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: votedKey) ?? [])
    }
    private static func toggleVoted(_ id: String) {
        var v = votedIDs
        if v.contains(id) { v.remove(id) } else { v.insert(id) }
        UserDefaults.standard.set(Array(v), forKey: votedKey)
    }

    static func add(_ text: String, _ done: @escaping () -> Void) {
        ConvexClient.registerDevice(token: AuthToken.current)   // wishlist writes require a registered device
        post(["action": "add", "uid": myUID, "secret": DeviceSecret.current,
              "alias": Settings.shared.username, "text": text]) { _ in
            DispatchQueue.main.async { done() }
        }
    }

    static func upvote(_ id: String, _ done: @escaping () -> Void) {
        ConvexClient.registerDevice(token: AuthToken.current)
        post(["action": "upvote", "id": id, "uid": myUID, "secret": DeviceSecret.current]) { data in
            DispatchQueue.main.async {
                // Remember the toggle locally on success ("did I vote" no longer comes from the server).
                if let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   obj["ok"] as? Bool == true {
                    toggleVoted(id)
                }
                done()
            }
        }
    }

    static func comment(_ id: String, _ text: String, _ done: @escaping () -> Void) {
        ConvexClient.registerDevice(token: AuthToken.current)
        post(["action": "comment", "id": id, "uid": myUID, "secret": DeviceSecret.current,
              "alias": Settings.shared.username, "text": text]) { _ in
            DispatchQueue.main.async { done() }
        }
    }

    private static func get(_ cb: @escaping (Data?) -> Void) {
        guard let url = URL(string: endpoint) else { cb(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }

    private static func post(_ body: [String: Any], _ cb: @escaping (Data?) -> Void) {
        guard let url = URL(string: endpoint) else { cb(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }
}
