import SwiftUI
import AppKit
import Combine

// MARK: - Today's relevant to-dos

/// A single row in the glance: a task, the project it belongs to, and whether it's overdue.
struct GlanceItem: Identifiable {
    let id: UUID            // the task id (used for markDone)
    let projectID: UUID
    let project: String
    let title: String
    var done: Bool
    let deadline: Date?
    let overdue: Bool
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
                               title: t.title, done: t.done, deadline: t.deadline, overdue: overdue)
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

    private var items: [GlanceItem] { TodoGlance.items(from: store.projects) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checklist").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Text("Today").font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 18)
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary).padding(6).contentShape(Rectangle())
                }
                .buttonStyle(.plain).help("Close (Esc)")
            }

            if items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle").font(.system(size: 13)).foregroundStyle(.tertiary)
                    Text("Nothing on for today — you're all clear.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                // Group by project, preserving the order items first appear in.
                let groups = grouped(items)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groups, id: \.0) { projectID, rows in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(rows.first?.project ?? "")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            ForEach(rows) { row in glanceRow(row) }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(width: 300, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder private func glanceRow(_ row: GlanceItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Button {
                store.markDone(taskID: row.id, done: !row.done)
            } label: {
                Image(systemName: row.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(row.done ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.plain)

            Text(row.title.isEmpty ? "Untitled task" : row.title)
                .font(.system(size: 12))
                .foregroundStyle(row.done ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                .strikethrough(row.done, color: .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            if let d = row.deadline {
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text(deadlineLabel(d)).font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(row.overdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.softFill, in: Capsule())
                .fixedSize()
            }
        }
    }

    /// Preserve first-seen project order while grouping rows.
    private func grouped(_ items: [GlanceItem]) -> [(UUID, [GlanceItem])] {
        var order: [UUID] = []
        var map: [UUID: [GlanceItem]] = [:]
        for it in items {
            if map[it.projectID] == nil { order.append(it.projectID) }
            map[it.projectID, default: []].append(it)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    /// Compact deadline: "Today HH:mm" for today, "EEE HH:mm" within ~6 days, else "MMM d, HH:mm".
    private func deadlineLabel(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale.current
        if cal.isDateInToday(d) {
            f.dateFormat = "'Today' HH:mm"
        } else if let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day,
                  days >= 0, days <= 6 {
            f.dateFormat = "EEE HH:mm"
        } else {
            f.dateFormat = "MMM d, HH:mm"
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
        let host = NSHostingController(rootView: TodoGlanceView(onClose: { [weak self] in self?.hide() }))
        host.sizingOptions = [.preferredContentSize]   // window tracks SwiftUI's intrinsic size
        p.contentViewController = host
        p.alphaValue = 1
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
