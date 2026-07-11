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
        let w = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
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
                if p.isSubtask { TodoStore.shared.markSubtaskDone(subtaskID: p.taskID) }
                else { TodoStore.shared.markDone(taskID: p.taskID) }
                self?.close()
            },
            onDismiss: { [weak self] in self?.close() }))
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
}

private struct TaskReminderView: View {
    let payload: TaskReminderOverlay.Payload
    let autoClose: Bool
    let seconds: TimeInterval
    let onDone: () -> Void
    let onDismiss: () -> Void

    @State private var remaining: TimeInterval
    @State private var appeared = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(payload: TaskReminderOverlay.Payload, autoClose: Bool, seconds: TimeInterval,
         onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.payload = payload; self.autoClose = autoClose; self.seconds = seconds
        self.onDone = onDone; self.onDismiss = onDismiss
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
            // like Verba (and a bit more joyful) instead of a plain black scrim. Click away to dismiss.
            LinearGradient(colors: [accent.opacity(0.55), Color.black.opacity(0.6), accent.opacity(0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Color.black.opacity(0.25))
                .ignoresSafeArea().contentShape(Rectangle())
                .onTapGesture { onDismiss() }

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
                    Button(action: onDone) {
                        Label("Mark done", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold)).padding(.horizontal, 22).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent).tint(.green).keyboardShortcut(.defaultAction)

                    Button(action: onDismiss) {
                        Text("Dismiss").font(.system(size: 16, weight: .medium)).padding(.horizontal, 20).padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered).keyboardShortcut(.cancelAction)
                }
                .padding(.top, 6)

                if autoClose {
                    Text("Closes in \(Int(ceil(remaining)))s · click anywhere to keep it open longer")
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
        .onReceive(tick) { _ in if autoClose { remaining = max(0, remaining - 1) } }
    }
}
