import Foundation
import Combine

/// Tiny cross-cutting signal so a global shortcut (Fn+Z, or a custom hotkey) can open the
/// Notes tab and immediately start recording a new note, regardless of which window/view is up.
/// Also the bridge between NotesView's own recorder and the shared recording overlay /
/// Control-pause that AppDelegate owns (so a note recording shows the same pill as dictation).
final class NotesController: ObservableObject {
    static let shared = NotesController()
    private init() {}

    /// Bumped by AppDelegate to ask MainWindow to select the Notes tab.
    @Published var navSignal = 0
    /// Bumped (by the Insights "your standing" card) to ask MainWindow to open the Leaderboard tab.
    @Published var leaderboardNavSignal = 0
    /// Set true to ask NotesView to discard the current draft and start a fresh recording.
    @Published var pendingRecord = false
    /// Bumped by AppDelegate (bare-Fn tap) to ask NotesView to stop & finish the in-progress
    /// note recording — so the user needn't re-press the Fn+Z chord to finish.
    @Published var stopRecord = 0
    /// True while NotesView is actively recording a note; lets a global bare-Fn tap know it must
    /// fire the stop signal instead of starting a stray dictation. Maintained by NotesView.
    @Published var isRecording = false

    // MARK: - Pause/resume bridge (Control key + overlay pause button + in-app control)
    /// Whether the in-progress note recording is paused. Owned by NotesView (it owns the recorder),
    /// mirrored here so the overlay can show the paused state.
    @Published var paused = false
    /// Bumped to REQUEST a pause/resume toggle of the in-progress note recording. AppDelegate's
    /// Control key and the overlay's pause button bump this; NotesView performs the toggle.
    @Published var pauseToggleSignal = 0
    /// Bumped to REQUEST discarding the in-progress note recording (the overlay × / Esc). NotesView
    /// stops the recorder and throws the audio away (no transcription).
    @Published var cancelRecord = 0

    // MARK: - Overlay waveform bridge
    /// Live mic level (0…1) of the in-progress note recording, published by NotesView so the
    /// shared overlay pill can animate its waveform the same way dictation does.
    @Published var level: Float = 0
}
