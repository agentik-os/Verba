import Foundation
import Combine

/// One record→transcribe→reprompt run. Sessions let the app process several dictations at once:
/// the recorder is free again the instant a recording stops (handed off to a Session), so the user
/// can start a NEW dictation while a previous (e.g. slow intent) Session is still processing.
/// Each Session's processing runs as its own concurrent Task (see AppDelegate); this is the
/// observable record of that work — in flight for the processing overlay, completed for the
/// Sessions list so a background result that couldn't be auto-pasted is never lost.
/// `@unchecked Sendable`: a Session is created on the main thread and every field is only ever
/// read/written on the main thread (the processing Task touches it solely inside MainActor.run /
/// DispatchQueue.main), so passing it into the @Sendable processing closure is safe.
final class Session: Identifiable, ObservableObject, @unchecked Sendable {
    enum Status: Equatable { case transcribing, processing, done, failed, cancelled }

    let id = UUID()
    let startedAt = Date()
    var finishedAt: Date?

    /// The reprompt mode this dictation used (for the Sessions list label).
    let modeName: String
    @Published var status: Status = .transcribing
    /// The delivered/result text once done (what the user can Copy from the list).
    @Published var resultText: String = ""
    /// The raw transcript, kept alongside the result.
    var original: String = ""
    /// Whether the result was auto-pasted into the original target (vs. only copyable from the list).
    var autoPasted = false
    /// Whether the result should be copied as rich text (chosen from the captured target app at
    /// deliver time) — used by the Sessions list Copy button so it preserves formatting.
    var rich = false
    /// A short error message when the Session failed (nil otherwise).
    @Published var error: String?

    init(modeName: String) { self.modeName = modeName }
}

/// Holds the in-flight Sessions (driving the processing overlay) plus a short rolling list of
/// recently-completed Sessions (driving the Sessions panel with per-result Copy). ObservableObject
/// so the SwiftUI Sessions list re-renders as Sessions complete. Every mutation happens on the
/// main thread from AppDelegate (mirrors NotesStore / TranscriptStore — not actor-isolated).
final class SessionStore: ObservableObject {
    static let shared = SessionStore()
    private init() {}

    /// Sessions currently transcribing/processing.
    @Published private(set) var inflight: [Session] = []
    /// The most recent completed Sessions (newest first), capped so the list stays small.
    @Published private(set) var completed: [Session] = []

    private let maxCompleted = 12

    var hasInflight: Bool { !inflight.isEmpty }

    func start(_ session: Session) {
        inflight.append(session)
    }

    /// Move a Session out of the in-flight list into the completed list (newest first), tagging it
    /// with the given final status + result. A cancelled Session is dropped, not surfaced.
    func complete(_ session: Session) {
        inflight.removeAll { $0.id == session.id }
        session.finishedAt = Date()
        guard session.status != .cancelled else { return }
        completed.insert(session, at: 0)
        if completed.count > maxCompleted { completed.removeLast(completed.count - maxCompleted) }
    }

    /// Take a Session out of the in-flight list WITHOUT listing it (its processing is done but it's
    /// awaiting user confirmation in review-before-send). It's added to `completed` later via complete().
    func endInflight(_ session: Session) {
        inflight.removeAll { $0.id == session.id }
    }

    func remove(_ session: Session) {
        completed.removeAll { $0.id == session.id }
    }

    func clearCompleted() {
        completed.removeAll()
    }
}
