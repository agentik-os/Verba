import Foundation
import FluidAudio

/// On-device transcription with NVIDIA Parakeet TDT v3 (multilingual, strong on
/// French). Models auto-download from Hugging Face on first use, then run offline.
actor ParakeetTranscriber: Transcriber {
    static let shared = ParakeetTranscriber()

    private var manager: AsrManager?

    /// Human-readable load status (e.g. while downloading the model the first time).
    nonisolated(unsafe) var onStatus: ((String) -> Void)?

    func unload() { manager = nil }

    func ensureLoaded() async throws -> AsrManager {
        if let manager { return manager }
        let cached = AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: .v3))
        onStatus?(cached ? "Loading model…" : "Downloading model… (first run)")
        // Load straight from cache when present (no re-download); otherwise fetch + load.
        let models = cached ? try await AsrModels.loadFromCache(version: .v3)
                            : try await AsrModels.downloadAndLoad(version: .v3)
        let m = AsrManager(config: .default)
        try await m.loadModels(models)
        manager = m
        onStatus?("")
        return m
    }

    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String {
        let m = try await ensureLoaded()
        var state = try TdtDecoderState()
        // v3 auto-detects language; the file-URL API resamples to 16 kHz internally.
        let result = try await m.transcribe(fileURL, decoderState: &state, language: nil)
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranscribeError.empty }
        return text
    }
}
