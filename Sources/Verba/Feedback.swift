import Foundation

/// General user feedback (distinct from Wishlist feature-requests),
/// submitted through the same Convex deployment Wishlist uses.
enum Feedback {
    private static let base = "https://fortunate-aardvark-443.convex.cloud"
    static var myUID: String { Settings.shared.uid }

    /// Submit a free-form feedback message, optionally with a screenshot PNG.
    /// When a screenshot is supplied we first ask Convex for an upload URL, PUT the
    /// PNG bytes to it to obtain a storageId, then call `feedback:submit` with it.
    /// Calls back with `nil` on success or a human-readable error string on failure.
    static func submit(_ text: String, screenshot: Data? = nil, _ done: @escaping (String?) -> Void) {
        guard let png = screenshot else {
            doSubmit(text: text, screenshotId: nil, done)
            return
        }
        // 1. Get an upload URL.
        post("mutation", "feedback:generateUploadUrl", [:]) { data in
            guard let url = unwrapString(data) else {
                finish(done, "Couldn't prepare the screenshot upload. Please try again.")
                return
            }
            // 2. PUT the PNG bytes to it → { storageId }.
            uploadPNG(png, to: url) { storageId in
                guard let storageId else {
                    finish(done, "Couldn't upload the screenshot. Please try again.")
                    return
                }
                // 3. Submit with the screenshot's storageId.
                doSubmit(text: text, screenshotId: storageId, done)
            }
        }
    }

    private static func doSubmit(text: String, screenshotId: String?, _ done: @escaping (String?) -> Void) {
        var args: [String: Any] = [
            "uid": myUID,
            "alias": Settings.shared.username,
            "text": text,
            "version": Updater.currentVersion,
        ]
        if let screenshotId { args["screenshotId"] = screenshotId }
        post("mutation", "feedback:submit", args) { data in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                finish(done, "No response from server. Check your connection and try again.")
                return
            }
            if obj["status"] as? String == "success" {
                finish(done, nil)
            } else {
                let msg = (obj["errorMessage"] as? String) ?? "Feedback couldn't be delivered right now. Please try again later."
                finish(done, msg)
            }
        }
    }

    /// PUT raw PNG bytes to a Convex storage upload URL; returns the `storageId` or nil.
    private static func uploadPNG(_ png: Data, to urlString: String, _ cb: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else { cb(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("image/png", forHTTPHeaderField: "Content-Type")
        req.httpBody = png
        URLSession.shared.dataTask(with: req) { d, _, _ in
            guard let d,
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let sid = obj["storageId"] as? String else { cb(nil); return }
            cb(sid)
        }.resume()
    }

    /// Pull the `value` string out of a Convex {status, value} envelope.
    private static func unwrapString(_ data: Data?) -> String? {
        guard let data,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["status"] as? String == "success",
              let val = obj["value"] as? String else { return nil }
        return val
    }

    private static func finish(_ done: @escaping (String?) -> Void, _ msg: String?) {
        DispatchQueue.main.async { done(msg) }
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
