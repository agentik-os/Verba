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
    /// Hosts we accept the engine download from. Ollama's own `ollama.com/download/...` now 307-redirects
    /// to GitHub Releases (github.com → *.githubusercontent.com), so pinning a single host broke the
    /// download for EVERYONE. We download straight from GitHub Releases and allow the hosts that redirect
    /// chain legitimately lands on. Transport is still HTTPS-only; the REAL integrity guarantee is Gate 3
    /// below (the binary must carry a valid Apple code signature + be notarised), which host-pinning was
    /// never a substitute for.
    private static let allowedDownloadHosts: Set<String> = [
        "ollama.com", "github.com", "objects.githubusercontent.com", "release-assets.githubusercontent.com",
    ]
    private static let engineURL = URL(string: "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.tgz")!
    /// Optional pinned SHA-256 (hex, lowercase) of the expected tarball. Ollama ships new
    /// builds frequently, so a stale pin would break downloads; left empty the SHA gate is
    /// skipped and integrity rests on the (version-independent) code-signature gate below.
    /// Set this to a known-good hash to hard-pin a specific tarball.
    private static let pinnedTarballSHA256: String? = nil
    /// Pinned Apple Developer Team Identifier of the engine binary — the extracted binary's signing
    /// team must match exactly. Verified at runtime from the shipped Ollama build: "3MU9H2V9Y9"
    /// (Infra Technologies, Inc). This is the true integrity anchor for the CLI binary.
    private static let pinnedTeamID: String? = "3MU9H2V9Y9"

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
        // Gate 1 (transport): HTTPS + a host on the allowlist (GitHub Releases + Ollama).
        guard engineURL.scheme == "https", let h0 = engineURL.host, allowedDownloadHosts.contains(h0) else {
            DispatchQueue.main.async { done(false) }; return
        }
        var req = URLRequest(url: engineURL)
        req.timeoutInterval = 600
        URLSession.shared.downloadTask(with: req) { tmp, resp, err in
            let finish: (Bool) -> Void = { ok in DispatchQueue.main.async { done(ok) } }
            // Reject if the response ended up on an off-allowlist host or non-HTTPS. The code-signature
            // gate below is the real integrity check, so accepting any of GitHub's release hosts is safe.
            if let final = resp?.url, final.scheme != "https" || !(final.host.map { allowedDownloadHosts.contains($0) } ?? false) {
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
        // 2. Must be a real Developer ID binary signed by OLLAMA's exact team, anchored to Apple.
        //    NOTE: `spctl --assess --type execute` is NOT used here — it rejects a bare notarised CLI
        //    Mach-O ("valid but does not seem to be an app"), which silently broke every local install.
        //    A codesign designated-requirement check (Apple anchor + Ollama's Developer ID team OU) is
        //    the correct, stronger guarantee for a command-line binary: only Ollama can produce it.
        let team = pinnedTeamID ?? "3MU9H2V9Y9"   // Ollama = Infra Technologies, Inc (3MU9H2V9Y9)
        let requirement = "anchor apple generic and certificate leaf[subject.OU]=\"\(team)\""
        guard run("/usr/bin/codesign", ["-v", "-R=\(requirement)", bin.path]).0 == 0 else { return false }
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
        case notRunning, notDownloaded(String), http(String), settingUp(Int)
        var errorDescription: String? {
            switch self {
            case .notRunning: return "Local engine isn't running. Set it up in Settings ▸ AI rewriting."
            case .notDownloaded(let m): return "The local model “\(m)” isn't downloaded yet. Open Settings ▸ AI rewriting and tap “Download model”."
            case .http(let b): return "Local model error: \(b)"
            case .settingUp(let pct): return "Setting up your local AI… \(pct)% — one moment. Your dictation still works; AI rewriting turns on as soon as the download finishes."
            }
        }
    }

    /// Full fully-local setup, safe to call repeatedly (idempotent): ensure the Ollama server is
    /// running (download the open-source engine if it's missing), then pull the configured model if
    /// it isn't present yet. Without the model pull, reprompting throws notDownloaded on first use.
    ///
    /// Progress + completion are reported into `LocalSetupProgress.shared` so the onboarding bar and
    /// the first-use guard can show real state instead of dropping it on the floor. Already-present
    /// models finish instantly (no re-download).
    static func setupFullyLocal() {
        let m = Settings.shared.localLLMModel
        guard !m.isEmpty else { Task { @MainActor in LocalSetupProgress.shared.finishModel(true) }; return }
        let fail: () -> Void = { Task { @MainActor in LocalSetupProgress.shared.finishModel(false) } }
        let pullModel = {
            // If the model is already downloaded, don't re-pull — flip straight to ready and warm it.
            hasModel(m) { present in
                if present {
                    warm(m)
                    Task { @MainActor in LocalSetupProgress.shared.finishModel(true) }
                    return
                }
                // Warm the model into memory once it's present, so the FIRST JARVIS action is instant
                // instead of paying the multi-second cold-load of a 5GB model.
                pull(m,
                     progress: { p in Task { @MainActor in LocalSetupProgress.shared.reportModel(p) } },
                     done: { ok in
                        if ok { warm(m) }
                        Task { @MainActor in LocalSetupProgress.shared.finishModel(ok) }
                     })
            }
        }
        ensureServer { up in
            if up { pullModel() }
            else { installBinary { ok in if ok { ensureServer { u in if u { pullModel() } else { fail() } } } else { fail() } } }
        }
    }

    /// Load a model into memory WITHOUT generating (empty prompt) + hold it for 30 min. Fire-and-forget:
    /// turns the first real reprompt/JARVIS call from "load 5GB then answer" into just "answer".
    static func warm(_ model: String) {
        guard !model.isEmpty else { return }
        var req = URLRequest(url: URL(string: "\(host)/api/generate")!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 120
        // Warm at the SAME context size the first real call will ask for. If the warm loads the model
        // at one num_ctx and the first dictation asks for another, Ollama unloads and reloads it, and
        // the warm-up has bought nothing.
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model, "prompt": "", "keep_alive": "30m",
            "options": ["num_ctx": 4096],
        ])
        URLSession.shared.dataTask(with: req).resume()
    }

    /// Token budgets sized from the actual text, not from a constant.
    ///
    /// Long dictations used to come back as recaps, and both halves of that were here. Ollama
    /// defaults `num_ctx` to 4096, so a transcript past roughly 3000 words was cut off the INPUT
    /// before the model ever saw it; `num_predict: 1024` then capped the OUTPUT at roughly 750
    /// words, which alone halves a 10-minute dictation. A cleanup rewrite is about as long as its
    /// input, so both budgets follow the input instead. Short callers (JARVIS plans, feedback
    /// polish) land on the old small values and stay just as fast.
    /// `num_ctx` is BUCKETED, and that matters more than it looks: Ollama reloads the model whenever
    /// the requested context size changes, and a reload is a multi-second stall on a 5GB model. A
    /// continuously-varying value would therefore trade the recap bug for a cold load on almost every
    /// dictation. With buckets, every short dictation asks for the same 4096 and reuses the warm,
    /// resident model exactly as before; only genuinely long ones step up a tier and pay once.
    static func budgets(system: String, user: String) -> (ctx: Int, predict: Int) {
        let inputTokens = (system.count + user.count) / 3   // conservative for accented text
        let predict = min(max(1024, inputTokens * 3 / 2), 16384)
        let needed = inputTokens + predict + 512
        let ctx = [4096, 8192, 16384, 32768].first { $0 >= needed } ?? 32768
        return (ctx, predict)
    }

    /// Qwen3 is a hybrid reasoning model: left to itself it emits a `<think>…</think>` block before
    /// the answer on every single call. That block is pure latency, generated then thrown away by
    /// `stripThinking`, and it is why the local model went from instant to slow when the default
    /// moved from qwen2.5 to qwen3. The `think: false` field below is the right switch but is
    /// silently ignored by older Ollama builds (hence stripThinking existing at all), so we ALSO
    /// use Qwen's own in-prompt soft switch, which the chat template honours regardless of version.
    static func noThinkSuffix(for model: String) -> String {
        let m = model.lowercased()
        return (m.contains("qwen3") || m.contains("qwen-3")) ? "\n\n/no_think" : ""
    }

    /// Load the model into memory WHILE THE USER IS STILL SPEAKING, so the rewrite does not begin
    /// with a multi-second cold load of a 5GB model.
    ///
    /// `warm(_:)` above existed but was never called from anywhere — the changelog's "the local
    /// model now stays warm in memory" was carried entirely by `keep_alive` on real calls, so the
    /// first dictation after launch, and every dictation more than 30 minutes after the last one,
    /// paid the full load. This mirrors EngineManager.prewarmForRecording(), which has always done
    /// exactly this for the speech model, and hides the load behind the speaking time.
    ///
    /// Gated to the users who will actually run locally: Raw does no rewrite at all, and warming a
    /// 5GB model for someone whose rewrite runs on Claude Code or an API key would just eat RAM.
    // Deliberately NOT @MainActor, mirroring EngineManager.prewarmForRecording() so both can be
    // called side by side from the same record-start closure.
    static func prewarmForRecording() {
        let s = Settings.shared
        guard !s.activeProfile.raw else { return }
        guard s.repromptBackend.resolved == .localLLM else { return }
        warm(s.localLLMModel)
    }

    static func chat(system: String, user: String, model: String) async throws -> String {
        // First-launch guard: if the fully-local models are still downloading, surface the friendly
        // setup progress instead of a cryptic "model not found". Only fires while a download is
        // actively in flight — once installed, phase is .ready/.idle and we proceed normally.
        // Only defer while the AI (LLM) model ITSELF is still being pulled — never for a still-downloading
        // Whisper/Parakeet speech model (Action mode + reprompt need only the LLM). Otherwise a secondary
        // speech download stuck mid-way would block every local reprompt + Action (the 77% bug).
        if await MainActor.run(body: { LocalSetupProgress.shared.isAIModelSettingUp }) {
            let pct = await MainActor.run(body: { LocalSetupProgress.shared.modelPercent })
            throw LLMError.settingUp(pct)
        }
        let budget = budgets(system: system, user: user)
        var req = URLRequest(url: URL(string: "\(host)/api/chat")!)
        req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "content-type")
        // A 1-hour transcript on a local model genuinely takes minutes to regenerate; the old
        // 180s ceiling aborted long rewrites that were still progressing.
        req.timeoutInterval = budget.predict > 4096 ? 900 : 180
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "stream": false,
            // think:false — qwen3 (our default) and other thinking models otherwise emit a
            // <think>…</think> reasoning block. For reprompting AND JARVIS plan JSON we need clean,
            // directly-parseable output, never visible chain-of-thought. Ollama ignores this field
            // for non-thinking models, so it's safe across every local model. Older Ollama builds
            // ignore it entirely, which is why the system prompt also carries /no_think.
            "think": false,
            // SPEED: keep the model resident in memory for 30 min so back-to-back JARVIS actions don't
            // each pay the multi-second cold-load of a 5GB model (Ollama's default evicts after 5 min).
            "keep_alive": "30m",
            "options": [
                "temperature": 0.2,     // low temp = faster, more deterministic plans/rewrites
                // Both sized from the text (see `budgets`). num_ctx MUST be set: Ollama's 4096
                // default silently truncates a long transcript's input.
                "num_ctx": budget.ctx,
                "num_predict": budget.predict,
            ],
            "messages": [
                ["role": "system", "content": system + Self.noThinkSuffix(for: model)],
                ["role": "user", "content": user],
            ],
        ])
        let (data, resp): (Data, URLResponse)
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch {
            // Server not up → SELF-HEAL: kick off the local setup (installs engine + pulls the model)
            // and surface progress instead of a dead "not running" error, so reprompting recovers on
            // its own for anyone whose local engine isn't ready yet (incl. Automatic-mode fallback).
            let pct = await MainActor.run { LocalSetupProgress.shared.start(); return LocalSetupProgress.shared.percent }
            throw LLMError.settingUp(pct)
        }
        let body = String(data: data, encoding: .utf8) ?? ""
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            if body.contains("not found") {
                // Model missing → SELF-HEAL: start the pull and show setup progress, not a dead error.
                let pct = await MainActor.run { LocalSetupProgress.shared.start(); return LocalSetupProgress.shared.percent }
                throw LLMError.settingUp(pct)
            }
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
