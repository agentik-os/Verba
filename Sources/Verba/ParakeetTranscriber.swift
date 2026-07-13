import Foundation
import FluidAudio

/// On-device transcription with NVIDIA Parakeet TDT v3 (multilingual, strong on
/// French). Models auto-download from Hugging Face on first use, then run offline.
///
/// Lifecycle: the model is loaded LAZILY (first use / explicit prewarm) and auto-unloaded
/// after `idleUnloadAfter` of no use, so its ~0.6 GB doesn't sit in memory forever. Every
/// use re-arms the idle timer; the next use after an unload transparently reloads.
actor ParakeetTranscriber: Transcriber {
    static let shared = ParakeetTranscriber()

    /// Reentrancy gate: the (in-flight or completed) load. Concurrent callers all await this
    /// SAME task, so actor reentrancy can never double-load the model.
    private var loadTask: Task<AsrManager, Error>?

    /// Tail of the serialized transcription queue: each new transcribe chains on the previous
    /// one, so two dictations can never run concurrently on the one AsrManager (actor
    /// reentrancy would otherwise interleave them across the `await`s).
    private var queueTail: Task<String, Error>?

    /// Unload the model after this much idle time (R9). Re-armed on every load/transcribe.
    static let idleUnloadAfter: TimeInterval = 10 * 60
    private var idleTimer: Task<Void, Never>?

    /// Human-readable load status (e.g. while downloading the model the first time).
    nonisolated(unsafe) var onStatus: ((String) -> Void)?

    func unload() {
        idleTimer?.cancel(); idleTimer = nil
        loadTask?.cancel()
        loadTask = nil
        // Keep EngineManager's "warm & ready" state truthful after an (auto-)unload.
        if EngineManager.loaded?.engine == .parakeet { EngineManager.loaded = nil }
    }

    /// Drop the cached model after `idleUnloadAfter` of no use. Safe against an in-flight
    /// job: a running transcription holds its own strong `AsrManager` reference, so unloading
    /// only clears the cache for the NEXT dictation (which lazily reloads).
    private func scheduleIdleUnload() {
        idleTimer?.cancel()
        idleTimer = Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.idleUnloadAfter * 1_000_000_000))
            guard !Task.isCancelled else { return }
            NSLog("Verba: Parakeet idle for %.0f min — unloading model", Self.idleUnloadAfter / 60)
            unload()
        }
    }

    /// Kick off a background load so the model is warm by the time it's needed — called when a
    /// recording STARTS with Parakeet selected, hiding the (re)load behind the speaking time.
    nonisolated func prewarm() {
        Task(priority: .userInitiated) { _ = try? await self.ensureLoaded() }
    }

    func ensureLoaded() async throws -> AsrManager {
        scheduleIdleUnload()                       // any use re-arms the idle clock
        if let loadTask { return try await loadTask.value }
        // Verba-owned cache dir (NOT ~/…/FluidAudio, which triggers the "access data from other apps"
        // prompt — see EngineManager.parakeetDir).
        let dir = EngineManager.parakeetDir
        let cached = AsrModels.modelsExist(at: dir)
        onStatus?(cached ? "Loading model…" : "Downloading model… (first run)")
        let task = Task<AsrManager, Error> {
            // Load straight from cache when present (no re-download); otherwise fetch + load.
            let models = cached ? try await AsrModels.load(from: dir, version: .v3)
                                : try await AsrModels.downloadAndLoad(to: dir, version: .v3)
            let m = AsrManager(config: .default)
            try await m.loadModels(models)
            return m
        }
        loadTask = task
        do {
            let m = try await task.value
            onStatus?("")
            // A lazy (re)load is just as "warm & ready" as an explicit Activate.
            EngineManager.loaded = (.parakeet, "v3")
            scheduleIdleUnload()
            return m
        } catch {
            loadTask = nil                          // a failed load must not poison future loads
            onStatus?("")
            throw error
        }
    }

    func transcribe(fileURL: URL, language: String?, hint: String?) async throws -> String {
        // Serialize on the previous job (success OR failure) — one transcription at a time.
        let previous = queueTail
        let job = Task<String, Error> {
            _ = try? await previous?.value
            let m = try await self.ensureLoaded()
            var state = try TdtDecoderState()
            // Honor a pinned Spoken language (script-aware filtering on v3) so a French dictation
            // isn't peppered with another-script guesses; nil = auto-detect. (Whisper enforces the
            // language harder — same-script FR/EN pinning is fully reliable only there.) The file-URL
            // API resamples to 16 kHz internally.
            let forced = (language?.isEmpty ?? true) ? nil : Language(rawValue: language!.lowercased())
            let result = try await m.transcribe(fileURL, decoderState: &state, language: forced)
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw TranscribeError.empty }
            return text
        }
        queueTail = job
        defer { scheduleIdleUnload() }
        return try await job.value
    }
}
