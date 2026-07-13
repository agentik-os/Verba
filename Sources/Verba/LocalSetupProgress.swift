import Foundation
import SwiftUI

/// First-launch download tracker for the "Fully local" engine. A brand-new user who picks
/// Fully local needs BOTH on-device models before AI rewriting/JARVIS work:
///   • the speech model  — Parakeet (≈0.6 GB), via `EngineManager.install(.parakeet)`
///   • the AI model       — Ollama + qwen3 (≈5 GB), via `LocalLLM.setupFullyLocal()`
///
/// Both used to download SILENTLY with progress dropped, so the first prompt failed with a
/// cryptic "model not found". This singleton surfaces the real 0…1 progress of both so the
/// onboarding can show a reassuring bar, and so the reprompt/JARVIS path can show a friendly
/// "setting up… NN%" message instead of an error while the download is still running.
///
/// `start()` is the single, idempotent entry point (onboarding + launch both call it). It
/// detects the already-installed state FAST and jumps straight to `.ready` — no re-download,
/// no bar on relaunch.
@MainActor
final class LocalSetupProgress: ObservableObject {
    static let shared = LocalSetupProgress()

    enum Phase { case idle, installingEngine, pullingModel, ready, failed }

    @Published var phase: Phase = .idle
    /// Speech model (Parakeet) download, 0…1.
    @Published var engineProgress: Double = 0
    /// Second speech model (Whisper large-v3) download, 0…1 — ships alongside Parakeet by default.
    @Published var whisperProgress: Double = 0
    /// AI model (Ollama / qwen3) download, 0…1.
    @Published var modelProgress: Double = 0

    // Per-model "finished its attempt" + success flags, so we only reach .ready when the required
    // downloads actually completed (and .failed if a required one couldn't). Whisper is a SECONDARY
    // engine: it's tracked/awaited for the progress bar but its failure alone doesn't fail setup.
    private var engineDone = false
    private var whisperDone = false
    private var modelDone = false
    private var engineOK = false
    private var modelOK = false
    private var engineInFlight = false
    private var whisperInFlight = false

    private init() {}

    // MARK: derived state
    var isReady: Bool { phase == .ready }
    /// True while either model is still downloading — the signal the reprompt/JARVIS guard uses.
    var isSettingUp: Bool { phase == .installingEngine || phase == .pullingModel }
    /// Overall fraction across the three downloads (Parakeet + Whisper + AI), weighted evenly.
    var overall: Double { (engineProgress + whisperProgress + modelProgress) / 3 }
    var percent: Int { Int((overall * 100).rounded()) }

    /// A single reassuring status line for compact UI / the first-use guard.
    var statusLabel: String {
        switch phase {
        case .idle:   return ""
        case .ready:  return L("Ready")
        case .failed: return L("Setup didn't finish — retry in Settings ▸ AI rewriting.")
        case .installingEngine, .pullingModel:
            return L("Setting up your private on-device AI…") + " \(percent)%"
        }
    }
    var speechLabel: String {
        engineDone ? L("Speech model ready")
                   : L("Downloading the speech model…") + " \(Int((engineProgress * 100).rounded()))%"
    }
    var whisperLabel: String {
        whisperDone ? L("Accuracy model ready")
                    : L("Downloading the accuracy model…") + " \(Int((whisperProgress * 100).rounded()))%"
    }
    var aiLabel: String {
        modelDone ? L("AI model ready")
                  : L("Downloading the AI model…") + " \(Int((modelProgress * 100).rounded()))%"
    }

    // MARK: orchestration

    /// Kick off (or re-check) the fully-local setup. Idempotent and non-blocking: safe to call
    /// from onboarding on selection AND from launch. Already-installed models skip straight to
    /// ready with no download.
    func start() {
        // Clean slate on a retry after a previous failure, so stale done/OK flags don't
        // short-circuit settle() before the fresh download reports in.
        if phase == .failed {
            engineDone = false; whisperDone = false; modelDone = false; engineOK = false; modelOK = false
            engineProgress = 0; whisperProgress = 0; modelProgress = 0; phase = .idle
        }
        // --- Speech model (Parakeet) — the default on-device engine, loaded ready for first use. ---
        if EngineManager.isInstalled(.parakeet) {
            engineProgress = 1
            finishEngine(true)
        } else if !engineInFlight {
            engineInFlight = true
            phase = .installingEngine   // a real download is now in flight
            Task.detached(priority: .userInitiated) {
                let ok = await EngineManager.install(.parakeet, progress: { p in
                    Task { @MainActor in LocalSetupProgress.shared.engineProgress = p }
                })
                await MainActor.run { LocalSetupProgress.shared.finishEngine(ok) }
            }
        }

        // --- Second speech model (Whisper large-v3) — staged to disk so BOTH on-device engines
        // ship active by default. Download-only (no RAM load): the user can activate or uninstall
        // it in Settings ▸ Transcription engine. Its failure is non-fatal to overall setup. ---
        if EngineManager.isInstalled(.whisper) {
            whisperProgress = 1
            finishWhisper(true)
        } else if !whisperInFlight {
            whisperInFlight = true
            if phase == .idle || phase == .ready { phase = .installingEngine }
            Task.detached(priority: .userInitiated) {
                let ok = await EngineManager.download(.whisper, progress: { p in
                    Task { @MainActor in LocalSetupProgress.shared.whisperProgress = p }
                })
                await MainActor.run { LocalSetupProgress.shared.finishWhisper(ok) }
            }
        }

        // --- AI model (Ollama + qwen3) — LocalLLM reports its own progress back into us. It flips
        // phase → .pullingModel only if a real pull starts (already-present model finishes instantly).
        LocalLLM.setupFullyLocal()

        settle()
    }

    // MARK: callbacks (called by EngineManager install + LocalLLM.setupFullyLocal)
    func finishEngine(_ ok: Bool) {
        engineDone = true; engineOK = ok
        if ok { engineProgress = 1 }
        engineInFlight = false
        settle()
    }

    /// Called when the secondary Whisper (large-v3) download finishes (success or fail).
    func finishWhisper(_ ok: Bool) {
        whisperDone = true
        if ok { whisperProgress = 1 }
        whisperInFlight = false
        settle()
    }

    /// Called by `LocalLLM.setupFullyLocal` as the model pull streams progress.
    func reportModel(_ p: Double) {
        modelProgress = max(modelProgress, min(p, 1))
        if !modelDone { phase = engineDone ? .pullingModel : .installingEngine }
    }

    /// Called by `LocalLLM.setupFullyLocal` when the model is present/pulled (or failed).
    func finishModel(_ ok: Bool) {
        modelDone = true; modelOK = ok
        if ok { modelProgress = 1 }
        settle()
    }

    private func settle() {
        // Only resolve to a terminal state here. A setting-up phase is entered EXCLUSIVELY by a real
        // download starting (start() → .installingEngine, reportModel → .pullingModel), so an already
        // installed setup never flashes a spurious "setting up" during the async present-check.
        // Await all three attempts so the bar reaches 100% before we settle. Whisper is a SECONDARY
        // engine, so its success is NOT required for .ready (Parakeet + the AI model are the core);
        // if only Whisper failed the user is still fully set up and can retry it in Settings.
        guard engineDone && whisperDone && modelDone else { return }
        phase = (engineOK && modelOK) ? .ready : .failed
    }
}
