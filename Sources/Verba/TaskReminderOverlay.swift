import AppKit
import SwiftUI

// Full-screen task reminder. When a to-do's reminder moment arrives, we take over the whole screen
// with a large, unmissable card: what to do, a big "Mark done", and a Dismiss. It auto-closes after a
// few seconds (Settings ▸ can turn that off to close it manually). Distinct from the macOS notification
// banner — this is for reminders you must not miss.
final class TaskReminderOverlay {
    static let shared = TaskReminderOverlay()
    private init() {}

    struct Payload: Equatable { let taskID: UUID; let isSubtask: Bool; let title: String; let project: String; let due: Date }

    private var window: NSWindow?
    private var autoCloseTimer: Timer?

    func show(_ p: Payload) { DispatchQueue.main.async { self.present(p) } }

    private func present(_ p: Payload) {
        close()   // only one at a time; a newer reminder replaces the current card
        guard let screen = NSScreen.main else { return }
        let w = ReminderWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        w.level = .screenSaver                 // above the menu bar and every app
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let auto = Settings.shared.reminderAutoClose
        let secs = max(2, Settings.shared.reminderAutoCloseSeconds)
        let host = NSHostingController(rootView: TaskReminderView(
            payload: p, autoClose: auto, seconds: secs,
            onDone: { [weak self] in
                guard Self.markDone(p) else { return false }   // task is gone: keep the card up and say so
                self?.close()
                return true
            },
            onDismiss: { [weak self] in self?.close() },
            onKeepOpen: { [weak self] in self?.autoCloseTimer?.invalidate(); self?.autoCloseTimer = nil }))
        w.contentViewController = host
        w.setFrame(screen.frame, display: true)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w

        if auto {
            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: secs, repeats: false) { [weak self] _ in self?.close() }
        }
    }

    func close() {
        autoCloseTimer?.invalidate(); autoCloseTimer = nil
        window?.orderOut(nil); window = nil
    }

    /// Mark the reminder's task (or subtask) done and REPORT whether it landed. TodoStore's
    /// mutators return Void and no-op silently when the id no longer exists — a task deleted
    /// between the reminder firing and the user pressing the button — so the card used to close on
    /// a write that never happened, telling the user a to-do was done when it was not. We read the
    /// result back out of the store instead of trusting the call.
    private static func markDone(_ p: Payload) -> Bool {
        let store = TodoStore.shared
        if p.isSubtask {
            store.markSubtaskDone(subtaskID: p.taskID)
            return store.projects.contains { $0.tasks.contains { $0.subtasks.contains { $0.id == p.taskID && $0.done } } }
        }
        store.markDone(taskID: p.taskID)
        return store.projects.contains { $0.tasks.contains { $0.id == p.taskID && $0.done } }
    }
}

/// Borderless windows return false for `canBecomeKey` by default, so SwiftUI's `.keyboardShortcut`
/// never reaches this card: Esc and Return have never actually worked on it. That was survivable
/// only while a backdrop click dismissed the card; now that the click keeps it open (honouring the
/// caption), a `.screenSaver`-level full-screen takeover needs a real keyboard way out. Same
/// override the other Verba overlays already carry (TodoGlance, ActionFeed, TransformPicker).
private final class ReminderWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private struct TaskReminderView: View {
    let payload: TaskReminderOverlay.Payload
    let autoClose: Bool
    let seconds: TimeInterval
    /// Returns false when the task no longer exists, so the card can say so instead of closing.
    let onDone: () -> Bool
    let onDismiss: () -> Void
    /// Stop the auto-close countdown, honouring the "click to keep it open" affordance.
    let onKeepOpen: () -> Void

    @State private var remaining: TimeInterval
    @State private var appeared = false
    @State private var held = false         // the user asked to keep this reminder on screen
    @State private var doneFailed = false   // "Mark done" found nothing to mark
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(payload: TaskReminderOverlay.Payload, autoClose: Bool, seconds: TimeInterval,
         onDone: @escaping () -> Bool, onDismiss: @escaping () -> Void, onKeepOpen: @escaping () -> Void) {
        self.payload = payload; self.autoClose = autoClose; self.seconds = seconds
        self.onDone = onDone; self.onDismiss = onDismiss; self.onKeepOpen = onKeepOpen
        _remaining = State(initialValue: seconds)
    }

    private var dueString: String {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short
        return f.string(from: payload.due)
    }

    private var accent: Color { VerbaAppearance.shared.accentColor }

    var body: some View {
        ZStack {
            // Take-over backdrop tinted with the user's chosen master color, so the reminder feels
            // like Verba (and a bit more joyful) instead of a plain black scrim. Clicking it keeps
            // the card open (see the tap gesture below); Dismiss or Esc closes.
            LinearGradient(colors: [accent.opacity(0.55), Color.black.opacity(0.6), accent.opacity(0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Color.black.opacity(0.25))
                .ignoresSafeArea().contentShape(Rectangle())
                // The caption promised "click anywhere to keep it open longer" while this gesture
                // DISMISSED the card and the countdown never paused — so the one gesture advertised
                // as keeping a must-not-miss reminder was the gesture that destroyed it. Now it
                // does what it says; Dismiss and Esc remain the ways out.
                .onTapGesture { keepOpen() }

            VStack(spacing: 20) {
                Label("Reminder", systemImage: "bell.fill")
                    .font(.system(size: 13, weight: .semibold)).textCase(.uppercase)
                    .foregroundStyle(accent).labelStyle(.titleAndIcon)

                Text(payload.title.isEmpty ? "Untitled task" : payload.title)
                    .font(.system(size: 34, weight: .bold)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(payload.project) · due at \(dueString)")
                    .font(.system(size: 15)).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button { if !onDone() { doneFailed = true; keepOpen() } } label: {
                        Label("Mark done", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold)).padding(.horizontal, 22).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent).tint(.green).keyboardShortcut(.defaultAction)
                    .disabled(doneFailed)

                    Button(action: onDismiss) {
                        Text(doneFailed ? "Close" : "Dismiss").font(.system(size: 16, weight: .medium)).padding(.horizontal, 20).padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered).keyboardShortcut(.cancelAction)
                }
                .padding(.top, 6)

                if doneFailed {
                    Label("This task no longer exists, so there was nothing to mark done.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.orange)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                } else if held {
                    Text("Staying open · Esc or Dismiss to close")
                        .font(.system(size: 12)).foregroundStyle(.tertiary).padding(.top, 2)
                } else if autoClose {
                    Text("Closes in \(Int(ceil(remaining)))s · click anywhere to keep it open")
                        .font(.system(size: 12)).foregroundStyle(.tertiary).padding(.top, 2)
                }
            }
            .padding(44)
            .frame(maxWidth: 560)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(accent.opacity(0.45), lineWidth: 1.5))
            .shadow(color: accent.opacity(0.35), radius: 40, y: 20)
            .scaleEffect(appeared ? 1 : 0.94).opacity(appeared ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) { appeared = true } }
        .onReceive(tick) { _ in if autoClose && !held { remaining = max(0, remaining - 1) } }
    }

    /// Cancel the auto-close so the reminder stays until the user acts on it.
    private func keepOpen() {
        guard !held else { return }
        held = true
        onKeepOpen()
    }
}
