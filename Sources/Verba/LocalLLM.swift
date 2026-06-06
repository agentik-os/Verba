import Foundation

/// Fully-offline reprompting via a local Ollama server. Verba can START Ollama itself
/// (if installed) and even DOWNLOAD the engine binary, so the user doesn't have to.
enum LocalLLM {
    static let host = "http://127.0.0.1:11434"
    private static var serverProc: Process?

    private static var binDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/ollama", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    // MARK: server lifecycle
    static func isRunning(_ done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/tags")!); req.timeoutInterval = 2
        URLSession.shared.dataTask(with: req) { _, resp, err in
            DispatchQueue.main.async { done(err == nil && (resp as? HTTPURLResponse)?.statusCode == 200) }
        }.resume()
    }

    static func locateBinary() -> String? {
        let candidates = ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama",
                          "/Applications/Ollama.app/Contents/Resources/ollama",
                          binDir.appendingPathComponent("ollama").path]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func startServe(_ bin: String) {
        if serverProc?.isRunning == true { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: bin)
        p.arguments = ["serve"]
        var env = ProcessInfo.processInfo.environment
        env["OLLAMA_HOST"] = "127.0.0.1:11434"
        p.environment = env
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        serverProc = p
    }

    /// Make sure the server is up: start the local binary if needed. done(false) = no binary
    /// found, the caller should offer to download it.
    static func ensureServer(_ done: @escaping (Bool) -> Void) {
        isRunning { up in
            if up { done(true); return }
            guard let bin = locateBinary() else { done(false); return }
            startServe(bin)
            poll(20, done)
        }
    }

    private static func poll(_ retries: Int, _ done: @escaping (Bool) -> Void) {
        isRunning { up in
            if up || retries <= 0 { done(up); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poll(retries - 1, done) }
        }
    }

    /// Download the Ollama engine binary (~143 MB) and start it. For users without Ollama.
    static func installBinary(_ done: @escaping (Bool) -> Void) {
        let url = URL(string: "https://ollama.com/download/ollama-darwin.tgz")!
        URLSession.shared.downloadTask(with: url) { tmp, _, _ in
            guard let tmp else { DispatchQueue.main.async { done(false) }; return }
            let tgz = binDir.appendingPathComponent("ollama.tgz")
            try? FileManager.default.removeItem(at: tgz)
            try? FileManager.default.moveItem(at: tmp, to: tgz)
            let tar = Process()
            tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            tar.arguments = ["-xzf", tgz.path, "-C", binDir.path]
            try? tar.run(); tar.waitUntilExit()
            try? FileManager.default.removeItem(at: tgz)
            if let bin = locateBinary() {
                _ = try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bin)
                startServe(bin)
                poll(20) { done($0) }
            } else {
                DispatchQueue.main.async { done(false) }
            }
        }.resume()
    }

    // MARK: models
    static func hasModel(_ name: String, _ done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/tags")!); req.timeoutInterval = 3
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

    static func pull(_ name: String, progress: @escaping (Double) -> Void, done: @escaping (Bool) -> Void) {
        var req = URLRequest(url: URL(string: "\(host)/api/pull")!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type")
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
                    if (o["status"] as? String) == "success" { await MainActor.run { progress(1); done(true) }; return }
                    if o["error"] != nil { await MainActor.run { done(false) }; return }
                }
                await MainActor.run { done(true) }
            } catch { await MainActor.run { done(false) } }
        }
    }

    enum LLMError: LocalizedError {
        case notRunning, notDownloaded(String), http(String)
        var errorDescription: String? {
            switch self {
            case .notRunning: return "Local engine isn't running. Set it up in Settings ▸ AI rewriting."
            case .notDownloaded(let m): return "The local model “\(m)” isn't downloaded yet. Open Settings ▸ AI rewriting and tap “Download model”."
            case .http(let b): return "Local model error: \(b)"
            }
        }
    }

    static func chat(system: String, user: String, model: String) async throws -> String {
        var req = URLRequest(url: URL(string: "\(host)/api/chat")!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 180
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "stream": false,
            "messages": [["role": "system", "content": system], ["role": "user", "content": user]],
        ])
        let (data, resp): (Data, URLResponse)
        do { (data, resp) = try await URLSession.shared.data(for: req) } catch { throw LLMError.notRunning }
        let body = String(data: data, encoding: .utf8) ?? ""
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            if body.contains("not found") { throw LLMError.notDownloaded(model) }
            throw LLMError.http(body)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return ((obj?["message"] as? [String: Any])?["content"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
