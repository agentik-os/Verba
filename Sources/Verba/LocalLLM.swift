import CryptoKit
import Foundation

/// Fully-offline reprompting via a local Ollama server. Verba can START Ollama itself
/// (if installed) and even DOWNLOAD the engine binary, so the user doesn't have to.
enum LocalLLM {
    static let host = "http://127.0.0.1:11434"
    private static var serverProc: Process?

    // MARK: engine-download integrity policy
    //
    // The engine binary is fetched over the network and then executed with full user
    // privileges (Verba is unsandboxed and holds Accessibility + Keychain access), so a
    // MITM'd or CDN-swapped download would be straight RCE. We therefore NEVER run a
    // freshly downloaded binary unless it survives three independent gates:
    //
    //   1. transport: HTTPS + exact host match (no http://, no redirect to another host)
    //   2. content:   optional pinned SHA-256 of the tarball (enforced when set), and the
    //                 archive is extracted with a path-sanitiser that rejects `..` and
    //                 absolute paths (defeats tar path-traversal writes outside binDir)
    //   3. provenance: the extracted Mach-O must carry a valid Apple code signature, be
    //                 notarised (Gatekeeper/`spctl` accepts it), and — when a Team ID is
    //                 pinned below — be signed by that exact Developer ID team.
    //
    /// The only host we will ever download the engine from.
    private static let engineHost = "ollama.com"
    private static let engineURL = URL(string: "https://ollama.com/download/ollama-darwin.tgz")!
    /// Optional pinned SHA-256 (hex, lowercase) of the expected tarball. Ollama ships new
    /// builds frequently, so a stale pin would break downloads; left empty the SHA gate is
    /// skipped and integrity rests on the (version-independent) code-signature gate below.
    /// Set this to a known-good hash to hard-pin a specific tarball.
    private static let pinnedTarballSHA256: String? = nil
    /// Optional pinned Apple Developer Team Identifier of the engine binary. When set, the
    /// extracted binary's signing team must match exactly. Ollama's published Developer ID
    /// team is "EUDNPXK4V8"; pin it once verified in your environment.
    private static let pinnedTeamID: String? = nil

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
    ///
    /// Hardened: the download is verified (optional pinned SHA-256), extracted with a
    /// path-sanitiser, and the resulting binary's Apple code signature + notarisation are
    /// checked BEFORE it is ever made executable or run. Any failed gate aborts with
    /// done(false) and the partially-downloaded artefacts are removed — we never chmod or
    /// exec an unverified binary.
    static func installBinary(_ done: @escaping (Bool) -> Void) {
        // Gate 1 (transport): never anything but our exact HTTPS host.
        guard engineURL.scheme == "https", engineURL.host == engineHost else {
            DispatchQueue.main.async { done(false) }; return
        }
        var req = URLRequest(url: engineURL)
        req.timeoutInterval = 600
        URLSession.shared.downloadTask(with: req) { tmp, resp, err in
            let finish: (Bool) -> Void = { ok in DispatchQueue.main.async { done(ok) } }
            // Reject if the response ended up on a different host (redirect away from ollama.com).
            if let final = resp?.url, final.scheme != "https" || final.host != engineHost {
                if let tmp { try? FileManager.default.removeItem(at: tmp) }
                finish(false); return
            }
            guard err == nil, let tmp,
                  (resp as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true else {
                if let tmp { try? FileManager.default.removeItem(at: tmp) }
                finish(false); return
            }

            let tgz = binDir.appendingPathComponent("ollama.tgz")
            let extractDir = binDir.appendingPathComponent("_staging", isDirectory: true)
            try? FileManager.default.removeItem(at: tgz)
            try? FileManager.default.removeItem(at: extractDir)
            let cleanup = {
                try? FileManager.default.removeItem(at: tgz)
                try? FileManager.default.removeItem(at: extractDir)
            }
            do { try FileManager.default.moveItem(at: tmp, to: tgz) }
            catch { try? FileManager.default.removeItem(at: tmp); finish(false); return }

            // Gate 2a (content): pinned SHA-256 of the tarball, when configured.
            if let pin = pinnedTarballSHA256?.lowercased(), !pin.isEmpty {
                guard let digest = sha256Hex(of: tgz), digest == pin else {
                    cleanup(); finish(false); return
                }
            }

            // Gate 2b (content): path-sanitised extraction — refuse any archive entry that
            // escapes the staging directory via "..", an absolute path, or a leading "/".
            try? FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
            guard archiveEntriesAreSafe(tgz) else { cleanup(); finish(false); return }
            let tar = Process()
            tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            // -P NOT passed: tar then refuses absolute paths and strips a leading "/" by
            // default; combined with the pre-scan above this blocks traversal outside extractDir.
            tar.arguments = ["-xzf", tgz.path, "-C", extractDir.path]
            do { try tar.run() } catch { cleanup(); finish(false); return }
            tar.waitUntilExit()
            guard tar.terminationStatus == 0 else { cleanup(); finish(false); return }

            // Find the extracted binary INSIDE the sanitised staging dir only.
            guard let staged = findOllamaBinary(in: extractDir) else { cleanup(); finish(false); return }

            // Gate 3 (provenance): valid Apple code signature + notarisation (+ pinned team).
            guard verifyCodeSignature(at: staged) else { cleanup(); finish(false); return }

            // Only now is it safe: move into place, make executable, and run.
            let dest = binDir.appendingPathComponent("ollama")
            try? FileManager.default.removeItem(at: dest)
            do { try FileManager.default.moveItem(at: staged, to: dest) }
            catch { cleanup(); finish(false); return }
            cleanup()
            _ = try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            startServe(dest.path)
            poll(20) { done($0) }
        }.resume()
    }

    // MARK: download-integrity helpers

    /// Lowercase hex SHA-256 of a file, streamed so a ~143 MB tarball isn't held in memory.
    private static func sha256Hex(of file: URL) -> String? {
        guard let fh = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? fh.close() }
        var hasher = SHA256()
        while true {
            let chunk = (try? fh.read(upToCount: 1 << 20)) ?? nil
            guard let chunk, !chunk.isEmpty else { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// Scan a gzip tar's table of contents and reject it if ANY entry would escape the
    /// extraction root: absolute paths, a leading "/", a "~", or a ".." path component.
    private static func archiveEntriesAreSafe(_ tgz: URL) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        p.arguments = ["-tzf", tgz.path]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return false }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0, let listing = String(data: data, encoding: .utf8) else { return false }
        var sawEntry = false
        for raw in listing.split(separator: "\n") {
            let entry = String(raw)
            if entry.isEmpty { continue }
            sawEntry = true
            if entry.hasPrefix("/") { return false }                        // absolute
            if entry.hasPrefix("~") { return false }                        // home-relative
            let comps = entry.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
            if comps.contains("..") { return false }                        // traversal
        }
        return sawEntry
    }

    /// Locate the `ollama` Mach-O anywhere under a (trusted, sanitised) directory tree.
    private static func findOllamaBinary(in root: URL) -> URL? {
        let direct = root.appendingPathComponent("ollama")
        if FileManager.default.fileExists(atPath: direct.path) { return direct }
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let u as URL in en where u.lastPathComponent == "ollama" {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), !isDir.boolValue { return u }
        }
        return nil
    }

    /// Verify the downloaded binary's Apple code signature + notarisation before we trust it.
    /// Requires: `codesign --verify` (intact signature) AND Gatekeeper assessment via `spctl`
    /// (notarised / accepted), AND — when `pinnedTeamID` is set — an exact TeamIdentifier match.
    private static func verifyCodeSignature(at bin: URL) -> Bool {
        func run(_ launchPath: String, _ args: [String]) -> (Int32, String) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: launchPath)
            p.arguments = args
            let out = Pipe(); p.standardOutput = out; p.standardError = out
            do { try p.run() } catch { return (-1, "") }
            let data = out.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        }
        // 1. Signature must be present and intact.
        guard run("/usr/bin/codesign", ["--verify", "--deep", "--strict", bin.path]).0 == 0 else { return false }
        // 2. Must pass Gatekeeper as a notarised executable (rejects ad-hoc / unnotarised).
        guard run("/usr/sbin/spctl", ["--assess", "--type", "execute", "--context", "context:primary-signature", bin.path]).0 == 0 else { return false }
        // 3. Optional exact Developer ID team pin.
        if let team = pinnedTeamID, !team.isEmpty {
            let info = run("/usr/bin/codesign", ["-dvv", bin.path]).1
            guard info.contains("TeamIdentifier=\(team)") else { return false }
        }
        return true
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

    /// Full fully-local setup, safe to call repeatedly (idempotent): ensure the Ollama server is
    /// running (download the open-source engine if it's missing), then pull the configured model if
    /// it isn't present yet. Without the model pull, reprompting throws notDownloaded on first use.
    static func setupFullyLocal() {
        let pullModel = {
            let m = Settings.shared.localLLMModel
            guard !m.isEmpty else { return }
            pull(m, progress: { _ in }, done: { _ in })   // Ollama skips the download if already present
        }
        ensureServer { up in
            if up { pullModel() }
            else { installBinary { ok in if ok { ensureServer { u in if u { pullModel() } } } } }
        }
    }

    static func chat(system: String, user: String, model: String) async throws -> String {
        var req = URLRequest(url: URL(string: "\(host)/api/chat")!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 180
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "stream": false,
            // think:false — qwen3 (our default) and other thinking models otherwise emit a
            // <think>…</think> reasoning block. For reprompting AND JARVIS plan JSON we need clean,
            // directly-parseable output, never visible chain-of-thought. Ollama ignores this field
            // for non-thinking models, so it's safe across every local model.
            "think": false,
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
        let content = (obj?["message"] as? [String: Any])?["content"] as? String ?? ""
        return Self.stripThinking(content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Belt-and-suspenders for thinking models (qwen3, glm…): even with think:false some builds still
    /// emit a <think>…</think> block. Strip it so reprompt output and JARVIS plan JSON are clean.
    private static func stripThinking(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "(?s)<think>.*?</think>", with: "", options: .regularExpression)
        if let open = out.range(of: "<think>") { out = String(out[..<open.lowerBound]) }  // unclosed (truncated)
        return out
    }
}
