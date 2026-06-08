import Foundation
import Combine

/// Tiny cross-cutting signal so the "Capture by voice" button (or a global shortcut) can ask
/// AppDelegate to start a voice to-do capture, regardless of which window/view is up.
final class TodoCaptureController: ObservableObject {
    static let shared = TodoCaptureController()
    private init() {}

    /// Bumped to ask AppDelegate to start (or stop, while in progress) a voice to-do capture.
    @Published var captureSignal = 0
    /// True while a capture is recording/processing, so the button can reflect state.
    @Published var capturing = false
    /// Last user-facing error from a capture, surfaced in TodosView.
    @Published var lastError: String?

    func requestCapture() { captureSignal &+= 1 }
}
