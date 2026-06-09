import Foundation

/// General user feedback (distinct from Wishlist feature-requests),
/// submitted through the same Convex deployment Wishlist uses.
enum Feedback {
    private static let base = "https://fortunate-aardvark-443.convex.cloud"
    static var myUID: String { Settings.shared.uid }

    /// Submit a free-form feedback message. Calls back with `nil` on success
    /// or a human-readable error string on failure.
    static func submit(_ text: String, _ done: @escaping (String?) -> Void) {
        let args: [String: Any] = [
            "uid": myUID,
            "alias": Settings.shared.username,
            "text": text,
            "kind": "feedback"
        ]
        post("mutation", "wishlist:feedback", args) { data in
            // The Convex HTTP API wraps results in a {status, value/errorMessage} envelope.
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { done("No response from server. Check your connection and try again.") }
                return
            }
            if obj["status"] as? String == "success" {
                DispatchQueue.main.async { done(nil) }
            } else {
                let msg = (obj["errorMessage"] as? String) ?? "Feedback couldn't be delivered right now. Please try again later."
                DispatchQueue.main.async { done(msg) }
            }
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
