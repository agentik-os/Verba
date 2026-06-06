import Foundation
import FluidAudio
import WhisperKit

/// Install / detect / uninstall lifecycle for the on-device engines (Whisper,
/// Parakeet). OpenAI is remote and has no lifecycle.
enum EngineManager {
    /// Approximate download size, shown before installing.
    static func sizeGB(_ engine: TranscriptionEngine) -> String {
        switch engine {
        case .openAI:   return ""
        case .parakeet: return "≈ 0.6 GB"
        case .whisper:
            switch Settings.shared.localModel {
            case "base":  return "≈ 0.15 GB"
            case "small": return "≈ 0.5 GB"
            case "large-v3": return "≈ 1.6 GB"
            default:      return "≈ 1.5 GB"   // large-v3 turbo
            }
        }
    }

    private static var whisperBase: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/huggingface/models/argmaxinc/whisperkit-coreml")
    }
    private static func whisperFolder(_ model: String) -> URL {
        whisperBase.appendingPathComponent("openai_whisper-\(model)")
    }

    static func isInstalled(_ engine: TranscriptionEngine) -> Bool {
        switch engine {
        case .openAI: return true
        case .whisper:
            let f = whisperFolder(Settings.shared.localModel)
            let items = (try? FileManager.default.contentsOfDirectory(atPath: f.path)) ?? []
            return items.contains { !$0.hasPrefix(".") }
        case .parakeet:
            return AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: .v3))
        }
    }

    /// Last install/load failure, surfaced in Settings so the user sees the real cause.
    static var lastInstallError: String?

    /// Download + load the model, reporting 0...1 progress. Returns true on success.
    static func install(_ engine: TranscriptionEngine, progress: @escaping (Double) -> Void = { _ in }) async -> Bool {
        do {
            switch engine {
            case .whisper:
                _ = try await WhisperKit.download(variant: Settings.shared.localModel,
                    progressCallback: { p in DispatchQueue.main.async { progress(p.fractionCompleted) } })
                _ = try await LocalTranscriber.shared.ensureLoaded(model: Settings.shared.localModel)
            case .parakeet:
                _ = try await AsrModels.download(version: .v3,
                    progressHandler: { pr in DispatchQueue.main.async { progress(pr.fractionCompleted) } })
                _ = try await ParakeetTranscriber.shared.ensureLoaded()
            case .openAI:
                break
            }
            DispatchQueue.main.async { progress(1.0) }
            lastInstallError = nil
            return true
        } catch {
            let msg = (error as NSError).localizedDescription
            NSLog("Verba: install \(engine.rawValue) failed: \(error)")
            lastInstallError = msg
            return false
        }
    }

    static func uninstall(_ engine: TranscriptionEngine) async {
        switch engine {
        case .openAI: break
        case .whisper:
            try? FileManager.default.removeItem(at: whisperFolder(Settings.shared.localModel))
            await LocalTranscriber.shared.unload()
        case .parakeet:
            try? FileManager.default.removeItem(at: AsrModels.defaultCacheDirectory(for: .v3))
            await ParakeetTranscriber.shared.unload()
        }
    }
}
