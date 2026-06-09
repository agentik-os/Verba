import Foundation

/// General user feedback (distinct from Wishlist feature-requests).
/// Submits to the verba.run website endpoint, which files a rich Linear issue in the
/// Verba team's Feedback project. The Linear API key lives server-side only — the app
/// never holds it; it just POSTs the feedback + full context to /api/feedback.
enum Feedback {
    private static let endpoint = "https://verba.run/api/feedback"
    static var myUID: String { Settings.shared.uid }

    /// Submit a free-form feedback message, optionally with a screenshot PNG.
    /// The screenshot (if any) is base64-encoded and sent inline; the website uploads it
    /// to Linear and embeds it in the issue. We attach MAXIMUM context (version, OS, engine,
    /// active mode, signed-in user) so the issue can pinpoint the source of the problem.
    /// Calls back with `nil` on success or a human-readable error string on failure.
    static func submit(_ text: String, screenshot: Data? = nil, _ done: @escaping (String?) -> Void) {
        let s = Settings.shared
        var body: [String: Any] = [
            "text": text,
            "version": Updater.currentVersion,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "engine": s.engine.label,
            "mode": s.activeProfile.name,
            "uid": s.uid,
            "alias": s.username,
            "email": s.proEmail,
        ]
        if let png = screenshot {
            body["screenshotBase64"] = png.base64EncodedString()
        }

        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            finish(done, "Couldn't prepare the feedback. Please try again.")
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = httpBody
        req.timeoutInterval = 30

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                finish(done, "No response from server. Check your connection and try again.")
                return
            }
            if obj["ok"] as? Bool == true {
                finish(done, nil)
            } else {
                let msg = (obj["error"] as? String) ?? "Feedback couldn't be delivered right now. Please try again later."
                finish(done, msg)
            }
        }.resume()
    }

    private static func finish(_ done: @escaping (String?) -> Void, _ msg: String?) {
        DispatchQueue.main.async { done(msg) }
    }
}
