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
}
