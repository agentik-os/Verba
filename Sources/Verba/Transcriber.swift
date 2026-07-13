import Foundation
import WhisperKit

enum TranscribeError: LocalizedError {
    case missingKey
    case http(Int, String)
    case empty
    var errorDescription: String? {
        switch self {
        case .missingKey: return "No OpenAI API key set. Add it in Verba ▸ Settings."
        case .http(let code, let body): return "OpenAI transcription failed (\(code)): \(body)"
        case .empty: return "Nothing was transcribed (silent or unreadable audio)."
        }
    }
}

protocol Transcriber {
    /// `language` is an ISO-639-1 code, or nil/empty for auto-detect.
    /// `hint` is optional vocabulary (custom dictionary terms) to bias transcription.
    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String
}

// MARK: - OpenAI (cloud, BYOK)

struct OpenAITranscriber: Transcriber {
    var model = "gpt-4o-transcribe"

    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String {
        guard let key = Keychain.openAIKey, !key.isEmpty else { throw TranscribeError.missingKey }

        let boundary = "verba-\(UUID().uuidString)"
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 600   // 20-min audios can take a while to upload+process

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        field("model", model)
        field("response_format", "json")
        if let language, !language.isEmpty { field("language", language) }
        if let hint, !hint.isEmpty { field("prompt", "Vocabulary: \(hint)") }

        let fileData = try Data(contentsOf: fileURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw TranscribeError.http(code, String(data: data, encoding: .utf8) ?? "")
        }
        let parsed = try JSONDecoder().decode(OpenAITranscription.self, from: data)
        let text = parsed.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranscribeError.empty }
        return text
    }

    private struct OpenAITranscription: Decodable { let text: String }
}

// MARK: - Local (WhisperKit, on-device)

actor LocalTranscriber: Transcriber {
    static let shared = LocalTranscriber()

    /// Reentrancy gate: the (in-flight or completed) load for `loadTaskModel`. Concurrent
    /// callers all await this SAME task, so actor reentrancy can never double-load the model.
    private var loadTask: Task<WhisperKit, Error>?
    private var loadTaskModel: String?

    /// Tail of the serialized transcription queue: each new transcribe chains on the previous
    /// one, so two dictations can never run concurrently on the one WhisperKit pipeline.
    private var queueTail: Task<String, Error>?

    /// Called with human-readable load status (e.g. while downloading the model the first time).
    nonisolated(unsafe) var onStatus: ((String) -> Void)?

    func unload() { loadTask?.cancel(); loadTask = nil; loadTaskModel = nil }

    /// Where WhisperKit stores models — the single source of truth is EngineManager (Application
    /// Support, NOT ~/Documents; see EngineManager.modelsDownloadBase for why).
    private static func folder(_ model: String) -> String {
        EngineManager.whisperFolder(model).path
    }

    func ensureLoaded(model: String) async throws -> WhisperKit {
        if let loadTask, loadTaskModel == model { return try await loadTask.value }
        loadTask?.cancel()                  // model switched mid-flight: drop the stale load
        let path = Self.folder(model)
        let installed = (try? FileManager.default.contentsOfDirectory(atPath: path))?.contains { !$0.hasPrefix(".") } ?? false
        // If it's already on disk, load straight from the folder with NO hub round-trip
        // (no re-download, faster). Otherwise allow WhisperKit to fetch it.
        onStatus?(installed ? "Loading model…" : "Downloading model… (first run)")
        let task = Task<WhisperKit, Error> {
            // downloadBase MUST be set even on the installed path: it becomes WhisperKit's
            // tokenizerFolder, so the tokenizer resolves under Application Support (bundled/seeded
            // there) instead of the Hub. Without it the tokenizer couldn't load and Activation hung
            // on "Activating…" forever, and any Hub fallback re-created ~/Documents/huggingface.
            let config = installed
                ? WhisperKitConfig(model: model, downloadBase: EngineManager.modelsDownloadBase,
                                   modelFolder: path, download: false)
                : WhisperKitConfig(model: model, downloadBase: EngineManager.modelsDownloadBase)
            return try await WhisperKit(config)
        }
        loadTask = task
        loadTaskModel = model
        do {
            let kit = try await task.value
            onStatus?("")
            return kit
        } catch {
            // A failed load must not poison future loads (only clear if it's still ours).
            if loadTaskModel == model { loadTask = nil; loadTaskModel = nil }
            onStatus?("")
            throw error
        }
    }

    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String {
        // Serialize on the previous job (success OR failure) — one transcription at a time.
        let previous = queueTail
        let job = Task<String, Error> {
            _ = try? await previous?.value
            let model = Settings.shared.localModel
            let kit = try await self.ensureLoaded(model: model)
            let lang = (language?.isEmpty ?? true) ? nil : language
            let options = DecodingOptions(
                task: .transcribe,
                language: lang,
                detectLanguage: lang == nil,
                // withoutTimestamps: dictation only ever uses the plain text — we already discard
                // timestamps. Skipping the timestamp tokens is ~10% fewer tokens to decode per clip
                // (measured on-device) with zero quality change. temperatureFallbackCount stays at the
                // default so a rare low-confidence decode still self-corrects (it has no cost on clean
                // audio — the fallback only fires when a decode actually fails).
                withoutTimestamps: true,
                chunkingStrategy: .vad      // handles long (20-min) audio by voice-activity windows
            )
            let results: [TranscriptionResult] = try await kit.transcribe(audioPath: fileURL.path, decodeOptions: options)
            let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw TranscribeError.empty }
            return text
        }
        queueTail = job
        return try await job.value
    }
}
