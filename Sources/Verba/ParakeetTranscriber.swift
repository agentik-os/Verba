import Foundation
import FluidAudio

/// On-device transcription with NVIDIA Parakeet TDT v3 (multilingual, strong on
/// French). Models auto-download from Hugging Face on first use, then run offline.
actor ParakeetTranscriber: Transcriber {
    static let shared = ParakeetTranscriber()

    private var manager: AsrManager?

    /// Human-readable load status (e.g. while downloading the model the first time).
    nonisolated(unsafe) var onStatus: ((String) -> Void)?

    private func ensureLoaded() async throws -> AsrManager {
        if let manager { return manager }
        onStatus?("Loading Parakeet model… (first run downloads it)")
        let models = try await AsrModels.downloadAndLoad(version: .v3)
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
