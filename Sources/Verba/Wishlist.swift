import Foundation

struct WishItem: Identifiable, Decodable {
    let id: String
    let text: String
    let author: String
    let votes: Double
    let voters: [String]
}

/// Shared feature wishlist with upvotes, backed by the same Convex deployment.
enum Wishlist {
    private static let base = "https://fortunate-aardvark-443.convex.cloud"
    static var myUID: String {
        let s = Settings.shared
        return s.referralCode.isEmpty ? "anon-" + (s.proEmail.isEmpty ? "local" : s.proEmail) : s.referralCode
    }

    static func list(_ done: @escaping ([WishItem]) -> Void) {
        post("query", "wishlist:list", [:]) { data in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let value = obj["value"],
                  let vd = try? JSONSerialization.data(withJSONObject: value),
                  let items = try? JSONDecoder().decode([WishItem].self, from: vd) else {
                DispatchQueue.main.async { done([]) }; return
            }
            DispatchQueue.main.async { done(items) }
        }
    }

    static func add(_ text: String, _ done: @escaping () -> Void) {
        post("mutation", "wishlist:add", ["uid": myUID, "alias": Settings.shared.username, "text": text]) { _ in
            DispatchQueue.main.async { done() }
        }
    }

    static func upvote(_ id: String, _ done: @escaping () -> Void) {
        post("mutation", "wishlist:upvote", ["id": id, "uid": myUID]) { _ in
            DispatchQueue.main.async { done() }
        }
    }

    private static func post(_ kind: String, _ path: String, _ args: [String: Any], _ cb: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(base)/api/\(kind)") else { cb(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }
}
