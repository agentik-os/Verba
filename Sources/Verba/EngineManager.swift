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

    /// What's currently loaded into memory (warm + ready to transcribe). Set after a
    /// successful load, CLEARED by the engines' idle auto-unload; used to show a truthful
    /// "Active & ready" state in Settings.
    nonisolated(unsafe) static var loaded: (engine: TranscriptionEngine, model: String)?

    /// Warm the selected LOCAL engine in the background when a recording STARTS, so a lazily
    /// idle-unloaded model (see ParakeetTranscriber.idleUnloadAfter) is reloaded behind the
    /// user's speaking time and the first dictation after an unload stays fast. No-op for the
    /// cloud engine or when the model isn't installed yet (no surprise multi-GB download here —
    /// install stays an explicit Settings action / first-use path).
    static func prewarmForRecording() {
        let s = Settings.shared
        guard s.engine.isLocal, isInstalled(s.engine) else { return }
        guard !isReady(s.engine, model: s.localModel) else { return }   // already warm
        Task.detached(priority: .userInitiated) { _ = await load(s.engine) }
    }

    /// True if `engine` (with `model` for Whisper) is actually loaded and ready right now.
    static func isReady(_ engine: TranscriptionEngine, model: String) -> Bool {
        if engine == .openAI { return !(Keychain.openAIKey ?? "").isEmpty }
        guard let l = loaded, l.engine == engine else { return false }
        return engine == .whisper ? l.model == model : true
    }

    /// Load (downloading first if needed) and mark it ready. Returns true on success.
    /// This is what the Settings "Activate" button calls so activation is verified, not assumed.
    @discardableResult
    static func load(_ engine: TranscriptionEngine) async -> Bool {
        do {
            switch engine {
            case .openAI:
                loaded = (.openAI, "")
            case .whisper:
                let m = Settings.shared.localModel
                _ = try await LocalTranscriber.shared.ensureLoaded(model: m)
                loaded = (.whisper, m)
            case .parakeet:
                _ = try await ParakeetTranscriber.shared.ensureLoaded()
                loaded = (.parakeet, "v3")
            }
            lastInstallError = nil
            return true
        } catch {
            lastInstallError = (error as NSError).localizedDescription
            NSLog("Verba: load \(engine.rawValue) failed: \(error)")
            return false
        }
    }

    /// Copy the model that ships inside the app bundle into the FluidAudio cache on first
    /// launch, so a fresh install transcribes offline instantly with no download or API key.
    /// No-op if the model is already cached or wasn't bundled.
    static func seedBundledModels() {
        let cache = AsrModels.defaultCacheDirectory(for: .v3)
        if AsrModels.modelsExist(at: cache) { return }
        guard let bundled = Bundle.main.resourceURL?
                .appendingPathComponent("Models/parakeet-tdt-0.6b-v3", isDirectory: true),
              FileManager.default.fileExists(atPath: bundled.path) else { return }
        do {
            try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: cache)
            try FileManager.default.copyItem(at: bundled, to: cache)
        } catch {
            lastInstallError = "Couldn't seed the bundled model: \(error.localizedDescription)"
        }
    }

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
            loaded = engine == .whisper ? (.whisper, Settings.shared.localModel) : (engine, "v3")
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
