import Foundation

/// Fully-offline reprompting via a local Ollama server (no cloud, no API key).
/// The user installs Ollama once; Verba pulls the model (with progress) and chats with it.
enum LocalLLM {
    static let host = "http://localhost:11434"

    /// Is the Ollama server reachable right now?
    static func isRunning(_ done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/tags")!)
        req.timeoutInterval = 2
        URLSession.shared.dataTask(with: req) { _, resp, err in
            let ok = err == nil && (resp as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { done(ok) }
        }.resume()
    }

    /// Is a given model already pulled?
    static func hasModel(_ name: String, _ done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/tags")!)
        req.timeoutInterval = 3
        URLSession.shared.dataTask(with: req) { data, _, _ in
            var found = false
            if let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = obj["models"] as? [[String: Any]] {
                let base = name.split(separator: ":").first.map(String.init) ?? name
                found = models.contains { ($0["name"] as? String)?.hasPrefix(base) ?? false }
            }
            DispatchQueue.main.async { done(found) }
        }.resume()
    }

    /// Pull a model, streaming download progress (0...1) on the main thread.
    static func pull(_ name: String, progress: @escaping (Double) -> Void, done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/pull")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["name": name, "stream": true])
        Task {
            do {
                let (bytes, _) = try await URLSession.shared.bytes(for: req)
                for try await line in bytes.lines {
                    guard let d = line.data(using: .utf8),
                          let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { continue }
                    if let total = o["total"] as? Double, let comp = o["completed"] as? Double, total > 0 {
                        await MainActor.run { progress(comp / total) }
                    }
                    if (o["status"] as? String) == "success" {
                        await MainActor.run { progress(1.0); done(true) }; return
                    }
                    if o["error"] != nil { await MainActor.run { done(false) }; return }
                }
                await MainActor.run { done(true) }
            } catch {
                await MainActor.run { done(false) }
            }
        }
    }

    enum LLMError: LocalizedError {
        case notRunning, http(String)
        var errorDescription: String? {
            switch self {
            case .notRunning: return "Ollama isn't running. Install it from ollama.com and pull the model in Settings."
            case .http(let b): return "Local model error: \(b)"
            }
        }
    }

    /// Chat completion (non-streaming) against the local model.
    static func chat(system: String, user: String, model: String) async throws -> String {
        var req = URLRequest(url: URL(string: "\(host)/api/chat")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 180
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "stream": false,
            "messages": [["role": "system", "content": system], ["role": "user", "content": user]],
        ])
        let (data, resp): (Data, URLResponse)
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch { throw LLMError.notRunning }
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw LLMError.http(String(data: data, encoding: .utf8) ?? "")
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = ((obj?["message"] as? [String: Any])?["content"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return content
    }
}
