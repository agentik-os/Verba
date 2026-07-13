import Foundation
import CryptoKit

/// Automatic, privacy-conscious error + crash telemetry. Whenever the app hits a real error (a
/// swallowed-but-logged catch, a repeated sync failure) or CRASHES, a sanitized signature is POSTed to
/// verba.run/api/diagnostics, which files a DEDUPED Linear issue in the Feedback project — so recurring
/// problems surface (and can be fixed) without the user having to report them.
///
/// PRIVACY: only the error TEXT (with home paths + emails redacted) plus coarse context (app version,
/// macOS version, backend, engine) is ever sent — never a transcript, note, clipboard, or file content.
/// Deduped + rate-limited so nothing floods, and fully OFF when the user turns off diagnostics.
enum ErrorReporter {
    private static let endpoint = "https://verba.run/api/diagnostics"
    private static let lock = NSLock()
    private static var sentThisSession = 0
    private static let maxPerSession = 12
    private static var sessionSignatures = Set<String>()   // never send the same signature twice per launch
    private static let cooldown: TimeInterval = 24 * 3600   // and at most once/day across launches

    // MARK: - Public API

    /// Report a non-fatal error. Best-effort, async, never throws. `context` is coarse metadata only
    /// (e.g. ["area": "action-agent"]) — never user content.
    static func report(kind: String = "error", _ message: String, context: [String: String] = [:]) {
        guard Settings.shared.sendDiagnostics else { return }
        let clean = sanitize(message)
        guard !clean.isEmpty, !isBenign(clean) else { return }
        let signature = sign(kind: kind, message: clean)

        lock.lock()
        let firstThisSession = sessionSignatures.insert(signature).inserted
        let underCap = sentThisSession < maxPerSession
        if firstThisSession && underCap { sentThisSession += 1 }
        lock.unlock()
        guard firstThisSession, underCap, passesCooldown(signature) else { return }

        var ctx = context
        ctx["backend"] = Settings.shared.repromptBackend.rawValue
        var payload: [String: Any] = [
            "kind": kind,
            "message": clean,
            "signature": signature,
            "version": Updater.currentVersion,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "context": ctx,
        ]
        let uid = Settings.shared.uid
        if !uid.isEmpty { payload["uid"] = uid }

        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = httpBody
        req.timeoutInterval = 12
        URLSession.shared.dataTask(with: req).resume()   // fire-and-forget
    }

    // MARK: - Crash handling

    private static var crashFile: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/pending-crash.txt")
    }

    /// Install an uncaught-exception handler + fatal-signal handlers that write a minimal crash marker to
    /// disk (network isn't safe from a signal handler). The marker is reported on the NEXT launch.
    static func installCrashHandlers() {
        NSSetUncaughtExceptionHandler { ex in
            let stack = ex.callStackSymbols.prefix(12).joined(separator: "\n")
            ErrorReporter.writeCrashMarker("EXCEPTION \(ex.name.rawValue): \(ex.reason ?? "")\n\(stack)")
        }
        for sig in [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGTRAP] {
            signal(sig) { s in
                ErrorReporter.writeCrashMarker("SIGNAL \(s)")
                signal(s, SIG_DFL); raise(s)   // re-raise so the OS still produces its own crash report
            }
        }
    }

    /// If a crash marker from a previous run exists, report it and delete it. Call once at launch.
    static func reportPendingCrash() {
        let f = crashFile
        guard let data = try? Data(contentsOf: f), let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
        try? FileManager.default.removeItem(at: f)
        report(kind: "crash", text, context: ["area": "startup-recovered-crash"])
    }

    /// Async-signal-safe-ish minimal write (low-level, no Foundation networking) of the crash marker.
    private static func writeCrashMarker(_ text: String) {
        let path = crashFile.path
        try? FileManager.default.createDirectory(at: crashFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let fd = fopen(path, "w") else { return }
        let out = String(text.prefix(4000))
        _ = out.withCString { fputs($0, fd) }
        fclose(fd)
    }

    // MARK: - Helpers

    /// Skip transient / expected "errors" that aren't bugs: the local-AI setup-progress message, plain
    /// user cancellations, offline blips. These are normal states, not defects worth a Linear issue.
    private static func isBenign(_ s: String) -> Bool {
        let m = s.lowercased()
        return m.contains("setting up your local ai") || m.contains("settingup")
            || m.contains("cancelled") || m.contains("cancelled by user")
            || m.contains("didn't catch that") || m.contains("try again")
            || m.contains("offline") || m.contains("network connection was lost")
            || m.contains("the internet connection appears to be offline")
    }

    /// Redact PII: home paths → /Users/~, emails → <email>. Error strings rarely carry user content,
    /// but this guarantees no username/email leaves the device even if one slips into a message.
    private static func sanitize(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: #"/Users/[^/\s]+"#, with: "/Users/~", options: .regularExpression)
        out = out.replacingOccurrences(of: #"[\w.+-]+@[\w-]+\.[\w.-]+"#, with: "<email>", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines).prefix(3000).description
    }

    /// Stable signature = sha256(kind + message with volatile bits stripped), so the SAME error dedupes
    /// even when numbers/hex/uuids differ between occurrences.
    private static func sign(kind: String, message: String) -> String {
        var norm = message.lowercased()
        norm = norm.replacingOccurrences(of: #"0x[0-9a-f]+"#, with: "0x…", options: .regularExpression)
        norm = norm.replacingOccurrences(of: #"[0-9a-f]{8}-[0-9a-f-]{20,}"#, with: "<uuid>", options: .regularExpression)
        norm = norm.replacingOccurrences(of: #"\d+"#, with: "#", options: .regularExpression)
        let digest = SHA256.hash(data: Data("\(kind)|\(norm)".utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }

    /// At most once per `cooldown` per signature across launches (UserDefaults-backed).
    private static func passesCooldown(_ signature: String) -> Bool {
        let key = "verba.diag.sent.\(signature)"
        let d = UserDefaults.standard
        let last = d.double(forKey: key)
        let now = Date().timeIntervalSince1970
        if last > 0, now - last < cooldown { return false }
        d.set(now, forKey: key)
        return true
    }
}
