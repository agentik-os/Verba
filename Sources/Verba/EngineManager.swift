import Foundation
import FluidAudio
import Network
import WhisperKit

/// Install / detect / uninstall lifecycle for the on-device engines (Whisper,
/// Parakeet). OpenAI is remote and has no lifecycle.
enum EngineManager {
    /// Approximate download size, shown before installing.
    static func sizeGB(_ engine: TranscriptionEngine) -> String {
        switch engine {
        case .openAI:   return ""
        case .parakeet: return "≈ 0.6 GB"
        case .whisper:  return "≈ 1.6 GB"   // large-v3 (the only Whisper variant Verba ships)
        }
    }

    /// Verba-owned model root: ~/Library/Application Support/Verba. WhisperKit lays models out UNDER
    /// this as <base>/models/argmaxinc/whisperkit-coreml/openai_whisper-<model>. Kept OUT of
    /// ~/Documents ON PURPOSE: that old location was in the iCloud Desktop&Documents sync scope AND
    /// carried macOS app-data-isolation tags (com.apple.macl / com.apple.provenance) created by other
    /// Hugging Face tools, so macOS re-prompted "Verba would like to access data from other apps" on
    /// EVERY launch (preloadEngine enumerates it), and an iCloud-offloaded model read as corrupt.
    /// Application Support is Verba's own container — no TCC prompt, never offloaded.
    static var modelsDownloadBase: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba", isDirectory: true)
    }
    private static var whisperBase: URL {
        modelsDownloadBase.appendingPathComponent("models/argmaxinc/whisperkit-coreml")
    }
    /// Internal (not private): LocalTranscriber loads Whisper from this exact folder.
    static func whisperFolder(_ model: String) -> URL {
        whisperBase.appendingPathComponent("openai_whisper-\(model)")
    }

    /// One-time migration: move Whisper models an earlier build stored in ~/Documents/huggingface
    /// into Verba's Application Support root. The old path triggered the recurring "access data from
    /// other apps" prompt (macl-tagged, iCloud-synced) on every launch. Best-effort: if the user
    /// denies the one-time read, the move no-ops and Whisper simply re-downloads to the new base on
    /// next use. MUST run before any isInstalled() check so a migrated model reads as installed.
    static func migrateWhisperModelsOutOfDocuments() {
        let fm = FileManager.default
        let oldRoot = fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents/huggingface")
        let oldModels = oldRoot.appendingPathComponent("models/argmaxinc/whisperkit-coreml")
        guard fm.fileExists(atPath: oldModels.path),
              let entries = try? fm.contentsOfDirectory(at: oldModels, includingPropertiesForKeys: nil) else { return }
        try? fm.createDirectory(at: whisperBase, withIntermediateDirectories: true)
        for src in entries where src.hasDirectoryPath {
            let dest = whisperBase.appendingPathComponent(src.lastPathComponent)
            if fm.fileExists(atPath: dest.path) { continue }   // already migrated
            try? fm.moveItem(at: src, to: dest)
        }
        // Drop the now-orphaned old tree so it's never enumerated again (kills the recurring prompt).
        try? fm.removeItem(at: oldRoot)
    }

    /// On-disk model folder for a local engine (nil for OpenAI). Used by the self-heal to move a
    /// corrupt model aside instead of deleting it outright.
    private static func modelFolder(_ engine: TranscriptionEngine) -> URL? {
        switch engine {
        case .whisper:  return whisperFolder(Settings.shared.localModel)
        case .parakeet: return AsrModels.defaultCacheDirectory(for: .v3)
        case .openAI:   return nil
        }
    }

    /// A Whisper model counts as installed ONLY if it's actually COMPLETE, not merely present. The old
    /// check ("any file in the folder") accepted a truncated download, which then failed to load with
    /// "Could not open …/weights/weight.bin". Require the .mlmodelc components AND every weight.bin
    /// non-empty, so a half-finished download reads as not-installed and re-downloads cleanly.
    private static func whisperModelComplete(_ folder: URL) -> Bool {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue,
              let en = fm.enumerator(at: folder, includingPropertiesForKeys: [.fileSizeKey]) else { return false }
        var mlmodelcCount = 0, weightFiles = 0
        for case let url as URL in en {
            if url.pathExtension == "mlmodelc" { mlmodelcCount += 1 }
            if url.lastPathComponent == "weight.bin" {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size <= 0 { return false }        // present but empty = truncated download
                weightFiles += 1
            }
        }
        // A complete large-v3 has the AudioEncoder/TextDecoder/MelSpectrogram components each carrying
        // weights. Require the components AND at least one non-empty weight.bin.
        return mlmodelcCount >= 3 && weightFiles >= 1
    }

    static func isInstalled(_ engine: TranscriptionEngine) -> Bool {
        switch engine {
        case .openAI: return true
        case .whisper:
            return whisperModelComplete(whisperFolder(Settings.shared.localModel))
        case .parakeet:
            return AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: .v3))
        }
    }

    /// `loaded` and `lastInstallError` are written from genuinely concurrent, unsynchronized executors
    /// (prewarm's detached load, Settings Activate's off-main load, preloadEngine's install/download,
    /// and the transcriber actors' idle-unload). Route BOTH through one lock so concurrent ARC writes
    /// to the String-bearing values can't tear or crash.
    private static let stateLock = NSLock()

    /// Last install/load failure, surfaced in Settings so the user sees the real cause.
    private nonisolated(unsafe) static var _lastInstallError: String?
    static var lastInstallError: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _lastInstallError }
        set { stateLock.lock(); _lastInstallError = newValue; stateLock.unlock() }
    }

    /// What's currently loaded into memory (warm + ready to transcribe). Set after a
    /// successful load, CLEARED by the engines' idle auto-unload; used to show a truthful
    /// "Active & ready" state in Settings.
    private nonisolated(unsafe) static var _loaded: (engine: TranscriptionEngine, model: String)?
    static var loaded: (engine: TranscriptionEngine, model: String)? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _loaded }
        set { stateLock.lock(); _loaded = newValue; stateLock.unlock() }
    }

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
            let msg = (error as NSError).localizedDescription
            NSLog("Verba: load \(engine.rawValue) failed: \(error)")
            // The user tapped Activate to retry a model that failed to load. If it's genuinely corrupt
            // on disk, reloading the same files fails forever — repair it. selfHealCorruptModel moves
            // the bad copy ASIDE (never a bare delete) and restores it if the re-download fails, so a
            // false-positive or an offline retry can never leave the user with no model.
            if engine.isLocal, isCorruptModelError(msg) {
                return await selfHealCorruptModel(engine, progress: { _ in })
            }
            lastInstallError = msg
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
        await install(engine, progress: progress, allowCleanRetry: true)
    }

    private static func install(_ engine: TranscriptionEngine, progress: @escaping (Double) -> Void, allowCleanRetry: Bool) async -> Bool {
        do {
            switch engine {
            case .whisper:
                _ = try await WhisperKit.download(variant: Settings.shared.localModel,
                    downloadBase: modelsDownloadBase,
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
            // SELF-HEAL a corrupt/incomplete on-disk model. A truncated download leaves broken files
            // ("Could not open …/weights/weight.bin", "Error parsing MIL model") that a plain retry
            // reloads forever. Repair via selfHealCorruptModel (move-aside + restore-on-failure) so
            // the recovery is non-destructive even if the re-download fails.
            if engine.isLocal, allowCleanRetry, isCorruptModelError(msg) {
                NSLog("Verba: \(engine.rawValue) model looks corrupt — repairing (move-aside + re-download)")
                return await selfHealCorruptModel(engine, progress: progress)
            }
            lastInstallError = msg
            return false
        }
    }

    /// True ONLY for a GENUINE on-disk corruption / truncation signature. Deliberately narrow: Core ML
    /// load/compile NSErrors routinely embed the compiled ".../AudioEncoder.mlmodelc/weights/weight.bin"
    /// path, so bare "mlmodelc" / "could not open" also matched TRANSIENT failures of a perfectly good
    /// model (a busy or momentarily-unavailable file), which then got wiped. These substrings appear
    /// only on real truncation/corruption, or "could not open"/"truncated" specifically about weight.bin.
    private static func isCorruptModelError(_ msg: String) -> Bool {
        let m = msg.lowercased()
        return m.contains("parsing mil") || m.contains("corrupt") || m.contains("unexpected eof")
            || (m.contains("weight.bin") && (m.contains("could not open") || m.contains("truncat")))
    }

    /// Repair a model that failed to load with a genuine corruption error, WITHOUT ever risking the
    /// user's working copy. Bail out offline (re-download impossible → keep what's on disk), move the
    /// bad folder ASIDE (never a bare delete), re-download, and RESTORE the aside if that fails.
    private static func selfHealCorruptModel(_ engine: TranscriptionEngine, progress: @escaping (Double) -> Void) async -> Bool {
        guard engine.isLocal, let folder = modelFolder(engine) else { return false }
        guard await networkLikelyReachable() else {
            lastInstallError = "This model looks corrupt but you appear to be offline — reconnect, then tap Activate to re-download it."
            return false
        }
        let fm = FileManager.default
        let aside = folder.appendingPathExtension("corrupt-bak")
        try? fm.removeItem(at: aside)
        let moved = (try? fm.moveItem(at: folder, to: aside)) != nil
        let ok = await install(engine, progress: progress, allowCleanRetry: false)
        if ok {
            try? fm.removeItem(at: aside)                 // repaired → drop the bad copy
        } else if moved {
            try? fm.removeItem(at: folder)                // clear any partial re-download
            try? fm.moveItem(at: aside, to: folder)       // restore the prior model (better than none)
        }
        return ok
    }

    /// One-shot network reachability check (2s cap). Gates the destructive-repair path so a corrupt
    /// model is never moved aside when a re-download couldn't possibly succeed. Assumes reachable on
    /// timeout so a slow-but-online link still repairs.
    private static func networkLikelyReachable() async -> Bool {
        /// Ensures the continuation resumes exactly once (first of the path callback / timeout wins).
        final class Gate: @unchecked Sendable {
            private let lock = NSLock()
            private var claimed = false
            func claim() -> Bool { lock.lock(); defer { lock.unlock() }; if claimed { return false }; claimed = true; return true }
        }
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "verba.reachability")
            let gate = Gate()
            monitor.pathUpdateHandler = { path in
                if gate.claim() { monitor.cancel(); cont.resume(returning: path.status == .satisfied) }
            }
            monitor.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 2) {
                if gate.claim() { monitor.cancel(); cont.resume(returning: true) }
            }
        }
    }

    /// Download `engine`'s model to disk ONLY — no RAM load, doesn't touch `loaded`. Used to
    /// pre-stage the non-active local engine at launch/onboarding so BOTH on-device engines ship
    /// ready without paying a memory cost for the one you're not currently using. Reports 0…1.
    @discardableResult
    static func download(_ engine: TranscriptionEngine, progress: @escaping (Double) -> Void = { _ in }) async -> Bool {
        guard engine.isLocal else { return true }
        if isInstalled(engine) { DispatchQueue.main.async { progress(1.0) }; return true }
        do {
            switch engine {
            case .whisper:
                _ = try await WhisperKit.download(variant: Settings.shared.localModel,
                    downloadBase: modelsDownloadBase,
                    progressCallback: { p in DispatchQueue.main.async { progress(p.fractionCompleted) } })
            case .parakeet:
                _ = try await AsrModels.download(version: .v3,
                    progressHandler: { pr in DispatchQueue.main.async { progress(pr.fractionCompleted) } })
            case .openAI:
                break
            }
            DispatchQueue.main.async { progress(1.0) }
            lastInstallError = nil
            return true
        } catch {
            let msg = (error as NSError).localizedDescription
            NSLog("Verba: download \(engine.rawValue) failed: \(error)")
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
