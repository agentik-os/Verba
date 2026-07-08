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
    /// AI model (Ollama / qwen3) download, 0…1.
    @Published var modelProgress: Double = 0

    // Per-model "finished its attempt" + success flags, so we only reach .ready when BOTH
    // downloads actually completed (and .failed if either couldn't).
    private var engineDone = false
    private var modelDone = false
    private var engineOK = false
    private var modelOK = false
    private var engineInFlight = false

    private init() {}

    // MARK: derived state
    var isReady: Bool { phase == .ready }
    /// True while either model is still downloading — the signal the reprompt/JARVIS guard uses.
    var isSettingUp: Bool { phase == .installingEngine || phase == .pullingModel }
    /// Overall fraction across both downloads (weighted evenly).
    var overall: Double { (engineProgress + modelProgress) / 2 }
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
            engineDone = false; modelDone = false; engineOK = false; modelOK = false
            engineProgress = 0; modelProgress = 0; phase = .idle
        }
        // --- Speech model (Parakeet) ---
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
        guard engineDone && modelDone else { return }
        phase = (engineOK && modelOK) ? .ready : .failed
    }
}
