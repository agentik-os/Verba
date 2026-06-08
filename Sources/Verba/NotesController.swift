import Foundation
import Combine

/// Tiny cross-cutting signal so a global shortcut (Fn+Z, or a custom hotkey) can open the
/// Notes tab and immediately start recording a new note, regardless of which window/view is up.
final class NotesController: ObservableObject {
    static let shared = NotesController()
    private init() {}

    /// Bumped by AppDelegate to ask MainWindow to select the Notes tab.
    @Published var navSignal = 0
    /// Set true to ask NotesView to discard the current draft and start a fresh recording.
    @Published var pendingRecord = false
    /// Bumped by AppDelegate (bare-Fn tap) to ask NotesView to stop & finish the in-progress
    /// note recording — so the user needn't re-press the Fn+Z chord to finish.
    @Published var stopRecord = 0
    /// True while NotesView is actively recording a note; lets a global bare-Fn tap know it must
    /// fire the stop signal instead of starting a stray dictation. Maintained by NotesView.
    @Published var isRecording = false
}
