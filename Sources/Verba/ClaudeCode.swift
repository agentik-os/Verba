import Foundation

/// Reprompt via the local Claude Code CLI, using the user's Claude subscription
/// (Max/Pro plan) instead of a pay-per-token API key. Verba shells out to
/// `claude -p` with a full system-prompt override.
enum ClaudeCode {
    /// Resolve the `claude` binary path once (login-shell PATH, then common spots).
    static let binaryPath: String? = {
        // Ask a login shell so npm/bun/homebrew install locations are on PATH.
        if let p = try? runCapture("/bin/zsh", ["-lc", "command -v claude"]).trimmingCharacters(in: .whitespacesAndNewlines),
           !p.isEmpty, FileManager.default.isExecutableFile(atPath: p) {
            return p
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude",
            "\(home)/.bun/bin/claude", "\(home)/.npm-global/bin/claude",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }()

    static var isAvailable: Bool { binaryPath != nil }

    enum CCError: LocalizedError {
        case notInstalled, failed(String)
        var errorDescription: String? {
            switch self {
            case .notInstalled: return "Claude Code isn't installed / on PATH. Install it and run `claude` once to sign in, or switch to the Anthropic API key in Settings."
            case .failed(let s): return "Claude Code failed: \(s)"
            }
        }
    }

    static func reprompt(systemPrompt: String, userText: String, model: String) async throws -> String {
        guard let bin = binaryPath else { throw CCError.notInstalled }
        let alias = model.contains("opus") ? "opus" : model.contains("haiku") ? "haiku" : "sonnet"
        // Run in a neutral dir so no project CLAUDE.md leaks into the session.
        let cwd = FileManager.default.temporaryDirectory
        let args = ["-p",
                    "--system-prompt", systemPrompt,
                    "--exclude-dynamic-system-prompt-sections",
                    "--model", alias,
                    "--output-format", "text",
                    userText]
        let out = try await run(bin, args, cwd: cwd)
        let text = out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CCError.failed("empty response") }
        return text
    }

    // MARK: - Process plumbing

    /// Mutable box so a concurrent stderr-drain closure can hand back its bytes.
    private final class ErrBox { var data = Data() }

    private static func run(_ path: String, _ args: [String], cwd: URL? = nil) async throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        if let cwd { task.currentDirectoryURL = cwd }
        let outPipe = Pipe(), errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe

        // withTaskCancellationHandler so cancel/timeout kills the CLI instead of leaking it
        // (waitUntilExit on a detached queue would otherwise keep a hung `claude` alive forever).
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try task.run()
                        // Drain stderr concurrently so a chatty child (>~64KB stderr) can't
                        // block on its stderr write while we're blocked reading stdout — that
                        // sequential two-pipe drain is a classic deadlock that wedges the
                        // dictation pipeline in .processing forever.
                        let errBox = ErrBox()
                        let errReady = DispatchSemaphore(value: 0)
                        DispatchQueue.global(qos: .userInitiated).async {
                            errBox.data = errPipe.fileHandleForReading.readDataToEndOfFile()
                            errReady.signal()
                        }
                        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                        task.waitUntilExit()
                        errReady.wait()
                        let errData = errBox.data
                        if Task.isCancelled {
                            cont.resume(throwing: CancellationError())
                        } else if task.terminationStatus == 0 {
                            cont.resume(returning: String(data: outData, encoding: .utf8) ?? "")
                        } else {
                            cont.resume(throwing: CCError.failed(String(data: errData, encoding: .utf8) ?? "exit \(task.terminationStatus)"))
                        }
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            if task.isRunning { task.terminate() }   // unblocks waitUntilExit → continuation resumes
        }
    }

    private static func runCapture(_ path: String, _ args: [String]) throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        // Discard stderr to the null device so a chatty child (>~64KB stderr) can
        // always write without blocking — leaving an unread Pipe() here is the same
        // sequential/undrained-pipe deadlock as run().
        task.standardError = FileHandle.nullDevice
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
