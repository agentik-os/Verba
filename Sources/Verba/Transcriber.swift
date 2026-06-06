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

    private var pipe: WhisperKit?
    private var loadedModel: String?

    /// Called with human-readable load status (e.g. while downloading the model the first time).
    nonisolated(unsafe) var onStatus: ((String) -> Void)?

    func unload() { pipe = nil; loadedModel = nil }

    /// Where WhisperKit stores models (matches EngineManager's install path).
    private static func folder(_ model: String) -> String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/huggingface/models/argmaxinc/whisperkit-coreml/openai_whisper-\(model)")
            .path
    }

    func ensureLoaded(model: String) async throws -> WhisperKit {
        if let pipe, loadedModel == model { return pipe }
        let path = Self.folder(model)
        let installed = (try? FileManager.default.contentsOfDirectory(atPath: path))?.contains { !$0.hasPrefix(".") } ?? false
        // If it's already on disk, load straight from the folder with NO hub round-trip
        // (no re-download, faster). Otherwise allow WhisperKit to fetch it.
        onStatus?(installed ? "Loading model…" : "Downloading model… (first run)")
        let config = installed
            ? WhisperKitConfig(model: model, modelFolder: path, download: false)
            : WhisperKitConfig(model: model)
        let kit = try await WhisperKit(config)
        pipe = kit
        loadedModel = model
        onStatus?("")
        return kit
    }

    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String {
        let model = Settings.shared.localModel
        let kit = try await ensureLoaded(model: model)
        let lang = (language?.isEmpty ?? true) ? nil : language
        let options = DecodingOptions(
            task: .transcribe,
            language: lang,
            detectLanguage: lang == nil,
            chunkingStrategy: .vad          // handles long (20-min) audio by voice-activity windows
        )
        let results: [TranscriptionResult] = try await kit.transcribe(audioPath: fileURL.path, decodeOptions: options)
        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranscribeError.empty }
        return text
    }
}
