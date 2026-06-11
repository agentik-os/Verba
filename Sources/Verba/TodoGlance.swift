import SwiftUI
import AppKit
import Combine

// MARK: - Today's relevant to-dos

/// A single row in the glance: a task, the project it belongs to, and whether it's overdue.
struct GlanceItem: Identifiable {
    let id: UUID            // the task id, or the sub-task id when isSubtask (used for markDone routing)
    let projectID: UUID
    let project: String
    let title: String
    var done: Bool
    let deadline: Date?
    let overdue: Bool
    let subtaskCount: Int   // >0 → checking off here cascades to this many sub-tasks
    let isSubtask: Bool     // true → check-off routes to markSubtaskDone(subtaskID:)
}

/// Computes "today's" relevant to-dos across all projects:
///   • tasks due today  • overdue (due before today, still open)
///   • if NOTHING is dated/overdue, the top open undated tasks as a gentle fallback.
/// Done tasks are excluded; results are grouped by project (project order preserved),
/// dated items first (soonest first) then undated.
enum TodoGlance {
    static func items(from projects: [TodoProject], fallbackLimit: Int = 6) -> [GlanceItem] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        guard let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart) else { return [] }

        var dated: [GlanceItem] = []
        var undated: [GlanceItem] = []
        for p in projects {
            for t in p.tasks where !t.done {
                let item: (Bool) -> GlanceItem = { overdue in
                    GlanceItem(id: t.id, projectID: p.id, project: p.name,
                               title: t.title, done: t.done, deadline: t.deadline, overdue: overdue,
                               subtaskCount: t.subtasks.count, isSubtask: false)
                }
                if let d = t.deadline {
                    if d < todayStart {              // overdue
                        dated.append(item(true))
                    } else if d < todayEnd {         // due today
                        dated.append(item(false))
                    }
                    // due later than today → not relevant to the glance
                } else {
                    undated.append(item(false))
                }

                // Sub-tasks carry their own deadlines (and fire their own reminders), so an
                // overdue/due-today open sub-task must surface here too — otherwise it buzzes the
                // user yet stays invisible. Only the dated branch: undated sub-tasks aren't glanced.
                for s in t.subtasks where !s.done {
                    guard let sd = s.deadline else { continue }
                    let title = t.title.isEmpty ? s.title : "\(t.title) ▸ \(s.title)"
                    let subItem: (Bool) -> GlanceItem = { overdue in
                        GlanceItem(id: s.id, projectID: p.id, project: p.name,
                                   title: title, done: s.done, deadline: sd, overdue: overdue,
                                   subtaskCount: 0, isSubtask: true)
                    }
                    if sd < todayStart {             // overdue
                        dated.append(subItem(true))
                    } else if sd < todayEnd {        // due today
                        dated.append(subItem(false))
                    }
                }
            }
        }

        // Dated items always show (overdue + due-today), soonest deadline first.
        dated.sort { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
        if !dated.isEmpty { return dated }

        // Nothing dated/overdue → show the top open undated tasks as a quick "what's on" glance.
        return Array(undated.prefix(fallbackLimit))
    }
}

// MARK: - Glance view

/// A compact, on-brand floating list of today's to-dos. Each row has a checkbox (tap → done)
/// and, when dated, a deadline chip. Empty → a friendly line.
struct TodoGlanceView: View {
    @ObservedObject var store = TodoStore.shared
    var onClose: () -> Void
    var onAddTodo: () -> Void = {}   // mic + button: start a voice "add a to-do" capture

    /// IDs currently animating out after being checked off (checkmark + strikethrough show briefly,
    /// then the item is marked done in the store and slides away).
    @State private var completing: Set<UUID> = []

    /// Projects with at least one open task to show (full hierarchy: project → tasks → subtasks).
    private var visibleProjects: [TodoProject] {
        store.projects.filter { p in p.tasks.contains { !$0.done } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                Text("Tasks").font(.system(size: 15, weight: .semibold))
                Spacer(minLength: 18)
                Button(action: onAddTodo) {
                    HStack(spacing: 5) {
                        Image(systemName: "mic.fill").font(.system(size: 11, weight: .semibold))
                        Image(systemName: "plus").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.softFill, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.hairlineTint, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain).help("Add a to-do by voice")
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary).padding(6).contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Close (Esc)")
            }

            if visibleProjects.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(.green)
                    Text("All clear. Nothing left to do.")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(visibleProjects) { project in
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 6) {
                                    Text(project.name).font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary).textCase(.uppercase)
                                    let open = project.tasks.filter { !$0.done }.count
                                    Text("\(open)").font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
                                        .padding(.horizontal, 6).padding(.vertical, 1)
                                        .background(.softFill, in: Capsule())
                                }
                                ForEach(project.tasks.filter { !$0.done }) { task in
                                    taskBlock(task)
                                }
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: 460)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(width: 420, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: completing)
    }

    @ViewBuilder private func taskBlock(_ task: TodoTask) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            itemRow(id: task.id, title: task.title, deadline: task.deadline,
                    indent: 0, bold: true) {
                store.markDone(taskID: task.id, done: true)
            }
            // Open sub-tasks, indented under their task.
            ForEach(task.subtasks.filter { !$0.done }) { sub in
                itemRow(id: sub.id, title: sub.title, deadline: sub.deadline,
                        indent: 1, bold: false) {
                    store.markSubtaskDone(subtaskID: sub.id, done: true)
                }
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    /// One checkable row (task or sub-task). On tap: fill the check + strike through, then after a
    /// beat mark it done in the store, which slides it out of the list.
    @ViewBuilder private func itemRow(id: UUID, title: String, deadline: Date?, indent: CGFloat, bold: Bool, complete: @escaping () -> Void) -> some View {
        let isDoing = completing.contains(id)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if indent > 0 { Spacer().frame(width: 22 * indent) }
            Button {
                guard !isDoing else { return }
                withAnimation(.easeOut(duration: 0.2)) { _ = completing.insert(id) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        complete()
                        completing.remove(id)
                    }
                }
            } label: {
                ZStack {
                    Image(systemName: isDoing ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: indent > 0 ? 14 : 16))
                        .foregroundStyle(isDoing ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                        .scaleEffect(isDoing ? 1.15 : 1)
                }
            }
            .buttonStyle(.plain)

            Text(title.isEmpty ? "Untitled" : title)
                .font(.system(size: indent > 0 ? 12 : 13, weight: bold ? .medium : .regular))
                .foregroundStyle(isDoing ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                .strikethrough(isDoing, color: .green)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            if let d = deadline {
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text(deadlineLabel(d)).font(.system(size: 10, weight: .medium)).monospacedDigit()
                }
                .foregroundStyle(d < Date() ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.softFill, in: Capsule())
                .fixedSize()
            }
        }
        .opacity(isDoing ? 0.85 : 1)
    }

    /// Compact deadline: "Today 15:00" for today, "Fri 15:00" within ~6 days, else "Jun 12, 15:00".
    /// Locale-aware: 12/24-hour follows the user's locale via the localized format template.
    private func deadlineLabel(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale.current
        if cal.isDateInToday(d) {
            f.setLocalizedDateFormatFromTemplate("jmm")
            return "Today " + f.string(from: d)
        } else if let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day,
                  days >= 0, days <= 6 {
            f.setLocalizedDateFormatFromTemplate("EEE jmm")
        } else {
            f.setLocalizedDateFormatFromTemplate("MMM d jmm")
        }
        return f.string(from: d)
    }
}

// MARK: - Floating panel controller

/// Borderless panels return false for `canBecomeKey` by default; override so the glance can own
/// key focus (without activating the app, since it's also .nonactivatingPanel) and thus receive
/// the Esc keystroke via the local monitor immediately on show.
private final class GlancePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Owns the borderless floating glance panel. Toggle-on-repeat, Esc and click-away dismiss it.
final class TodoGlanceController {
    static let shared = TodoGlanceController()

    private var panel: NSPanel?
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    var isShowing: Bool { panel?.isVisible ?? false }

    /// ⌥ + Fn entry point: show if hidden, hide if already showing.
    func toggle() {
        if isShowing { hide() } else { show() }
    }

    private func build() {
        guard panel == nil else { return }
        let p = GlancePanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.ignoresMouseEvents = false   // checkboxes must be clickable
        let host = NSHostingController(rootView: TodoGlanceView(
            onClose: { [weak self] in self?.hide() },
            onAddTodo: { [weak self] in
                self?.hide()   // close the glance so the recording overlay is clear
                (NSApp.delegate as? AppDelegate)?.startTodoCapture()
            }))
        host.sizingOptions = [.preferredContentSize]   // window tracks SwiftUI's intrinsic size
        p.contentViewController = host
        p.alphaValue = 1
        // Clip the whole panel to rounded corners at the window layer, so the glass material (and the
        // window shadow) never bleed a square edge past the rounded card.
        host.view.wantsLayer = true
        host.view.layer?.cornerRadius = 20
        host.view.layer?.cornerCurve = .continuous
        host.view.layer?.masksToBounds = true
        panel = p
        p.layoutIfNeeded()
    }

    func show() {
        build()
        guard let panel, let screen = NSScreen.main else { return }
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 300, height: 160)
        let vf = screen.visibleFrame
        let x = vf.midX - size.width / 2
        let y = vf.midY - size.height / 2   // centered glance, distinct from the bottom dictation pill
        let frame = NSRect(origin: NSPoint(x: x, y: y),
                           size: panel.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size)
        panel.setFrame(frame, display: true)
        // .nonactivatingPanel can become key WITHOUT activating Verba (no app switch), so the
        // local Esc monitor receives keystrokes immediately — not only after the panel is clicked.
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        installDismissMonitors()
    }

    func hide() {
        panel?.orderOut(nil)
        removeDismissMonitors()
    }

    // Esc dismisses; a click outside the panel dismisses (click-away).
    private func installDismissMonitors() {
        removeDismissMonitors()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.hide(); return nil }   // 53 = Esc
            return event
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    private func removeDismissMonitors() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    }
}
