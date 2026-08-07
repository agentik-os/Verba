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
    /// True while a user-requested clean reinstall of the local engine is in flight
    /// (`LocalLLM.reinstallEngine`). UI can bind a spinner + disable the repair button on this.
    @Published var isRepairingEngine = false

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
    /// True while ANY model (speech or AI) is still downloading — used by the onboarding UI/bar.
    var isSettingUp: Bool { phase == .installingEngine || phase == .pullingModel }
    /// The signal the reprompt / Action-mode (JARVIS) guard uses. Deliberately keyed to the AI (LLM)
    /// model ALONE, never the Whisper/Parakeet speech downloads: reprompting and Action mode need only
    /// the LLM, so a slow/stuck/failed SECONDARY speech download must not block them. (This was the
    /// "Action mode does nothing on local" bug: selecting Turbo left Whisper mid-download, which pinned
    /// the whole setup at ~77% and the old guard — keyed to that global phase — threw "setting up 77%"
    /// on every local reprompt + Action.) Only blocks while the AI model is ACTIVELY being pulled.
    var isAIModelSettingUp: Bool { !modelDone && modelProgress > 0 && modelProgress < 1 }
    /// Overall fraction across the three downloads (Parakeet + Whisper + AI), weighted evenly.
    var overall: Double { (engineProgress + whisperProgress + modelProgress) / 3 }
    var percent: Int { Int((overall * 100).rounded()) }
    /// Progress of the AI (LLM) model alone — shown by the reprompt/Action guard so the "setting up NN%"
    /// message reflects the download that actually gates them, not the combined speech+AI bar.
    var modelPercent: Int { Int((modelProgress * 100).rounded()) }

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
    /// Status line for a user-requested engine repair (empty when no repair is running).
    var repairLabel: String { isRepairingEngine ? L("Reinstalling the local engine…") : "" }

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

    /// Called by `LocalLLM.reinstallEngine` when a user-requested clean reinstall starts.
    func beginEngineRepair() {
        isRepairingEngine = true
    }

    /// Called by `LocalLLM.reinstallEngine` with the reinstall outcome. On success the normal
    /// model phases take over (setupFullyLocal re-reports them); on failure the terminal
    /// `.failed` phase surfaces the standard retry hint in the setup UI.
    func finishEngineRepair(_ ok: Bool) {
        isRepairingEngine = false
        if !ok { phase = .failed }
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
        // Resolve on the CORE two — Parakeet (speech) + the AI model. Whisper is a SECONDARY engine:
        // do NOT gate the terminal state on whisperDone, or a slow/stuck/failed Whisper download (e.g.
        // when the user picked Turbo and it's still fetching) pins the whole setup in "setting up"
        // FOREVER — which used to block every local reprompt + Action mode. Whisper keeps downloading
        // in the background and just updates its own label; it never holds the AI hostage.
        guard engineDone && modelDone else { return }
        phase = (engineOK && modelOK) ? .ready : .failed
    }
}
