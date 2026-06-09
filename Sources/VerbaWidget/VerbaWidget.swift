import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared data contract (app↔widget)
//
// The app writes a small JSON snapshot of "today's" tasks into the shared
// App-Group UserDefaults under `widget.today` whenever the TodoStore changes,
// then nudges WidgetKit (WidgetCenter.reloadAllTimelines). The widget reads it
// here — it can NOT touch TodoStore directly (different process).
//
// Kept deliberately tiny + self-contained so the extension links nothing from
// the main app target. The matching writer lives in the app at
// Sources/Verba/WidgetBridge.swift; the `WidgetTodo` shape + `kAppGroup` +
// the two defaults keys MUST stay byte-for-byte identical on both sides.

/// App Group suite shared by Verba.app and this widget. Must match the
/// `com.apple.security.application-groups` entitlement on BOTH bundles and
/// be registered on the Apple Developer portal for the team.
let kAppGroup = "group.975755H4ZC.verba"

/// Defaults keys inside the App-Group suite.
private let kTodayKey = "widget.today"          // JSON [WidgetTodo] snapshot
private let kToggleKey = "widget.pendingToggles" // [String] of task UUIDs toggled from the widget

/// One task row in the widget's "today" snapshot. Mirror of the app-side type.
struct WidgetTodo: Codable, Identifiable {
    var id: String          // the task's UUID string (used by the toggle intent)
    var title: String
    var project: String
    var done: Bool
    var overdue: Bool
    var deadline: Date?

    // Tolerant decode so an older/newer snapshot shape never crashes the widget.
    init(id: String, title: String, project: String, done: Bool, overdue: Bool, deadline: Date?) {
        self.id = id; self.title = title; self.project = project
        self.done = done; self.overdue = overdue; self.deadline = deadline
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        project = try c.decodeIfPresent(String.self, forKey: .project) ?? ""
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
        overdue = try c.decodeIfPresent(Bool.self, forKey: .overdue) ?? false
        deadline = try c.decodeIfPresent(Date.self, forKey: .deadline)
    }
}

enum WidgetData {
    /// Read today's tasks from the shared App-Group defaults. Returns a static
    /// placeholder list if the app hasn't written a snapshot yet (fresh install,
    /// or App Group not yet provisioned) so the widget always renders something.
    static func today() -> [WidgetTodo] {
        if let defaults = UserDefaults(suiteName: kAppGroup),
           let data = defaults.data(forKey: kTodayKey),
           let rows = try? JSONDecoder().decode([WidgetTodo].self, from: data) {
            return rows
        }
        return placeholder
    }

    static let placeholder: [WidgetTodo] = [
        WidgetTodo(id: "p1", title: "Ship the widget", project: "Verba", done: false, overdue: false, deadline: Date()),
        WidgetTodo(id: "p2", title: "Reply to Gareth", project: "Inbox", done: false, overdue: true, deadline: Date().addingTimeInterval(-3600)),
        WidgetTodo(id: "p3", title: "Review the PR", project: "Verba", done: true, overdue: false, deadline: nil),
    ]
}

// MARK: - Interactive toggle (AppIntent, macOS 14+)
//
// Tapping a row's checkbox records the task id into a pending-toggles list in
// the shared defaults and optimistically flips the snapshot so the widget
// updates instantly. The app, when next active / on its own store subscription,
// drains the pending list and applies the real TodoStore.markDone — then writes
// a fresh authoritative snapshot. No direct cross-process store mutation.

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var isDiscoverable = false

    @Parameter(title: "Task ID") var id: String

    init() {}
    init(id: String) { self.id = id }

    func perform() async throws -> some IntentResult {
        guard let defaults = UserDefaults(suiteName: kAppGroup) else { return .result() }

        // Queue the toggle for the app to apply authoritatively.
        var pending = defaults.stringArray(forKey: kToggleKey) ?? []
        pending.append(id)
        defaults.set(pending, forKey: kToggleKey)

        // Optimistically flip the snapshot so the checkbox responds immediately.
        if let data = defaults.data(forKey: kTodayKey),
           var rows = try? JSONDecoder().decode([WidgetTodo].self, from: data) {
            if let i = rows.firstIndex(where: { $0.id == id }) {
                rows[i].done.toggle()
                if let out = try? JSONEncoder().encode(rows) { defaults.set(out, forKey: kTodayKey) }
            }
        }
        return .result()
    }
}

// MARK: - Timeline

struct TodayEntry: TimelineEntry {
    let date: Date
    let todos: [WidgetTodo]
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todos: WidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), todos: WidgetData.today()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: Date(), todos: WidgetData.today())
        // Refresh hourly as a backstop; the app nudges WidgetKit on every store change.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Brand

private enum Brand {
    /// The Verba mark is monochrome black/white; the widget stays neutral and
    /// uses a single restrained accent (red) only to flag overdue work.
    static let mark = "checklist"
    static let overdue = Color.red
}

private func timeChip(_ d: Date) -> String {
    let cal = Calendar.current
    let f = DateFormatter()
    f.locale = Locale.current
    if cal.isDateInToday(d) { f.dateFormat = "HH:mm" }
    else if let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day,
            days >= -6, days <= 6 { f.dateFormat = "EEE HH:mm" }
    else { f.dateFormat = "MMM d" }
    return f.string(from: d)
}

// MARK: - Row

private struct TodoRow: View {
    let todo: WidgetTodo
    var showProject: Bool = false
    var showTime: Bool = false
    var compact: Bool = false

    private var titleSize: CGFloat { compact ? 12 : 13 }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            checkbox

            VStack(alignment: .leading, spacing: 1) {
                Text(todo.title.isEmpty ? "Untitled task" : todo.title)
                    .font(.system(size: titleSize, weight: .regular))
                    .foregroundStyle(todo.done ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                    .strikethrough(todo.done, color: .secondary)
                    .lineLimit(1)
                if showProject, !todo.project.isEmpty {
                    Text(todo.project)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if showTime, let d = todo.deadline {
                Text(timeChip(d))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(todo.overdue ? AnyShapeStyle(Brand.overdue) : AnyShapeStyle(.secondary))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                    .fixedSize()
            }
        }
    }

    @ViewBuilder private var checkbox: some View {
        let symbol = todo.done ? "checkmark.circle.fill" : "circle"
        let tint: AnyShapeStyle = todo.done
            ? AnyShapeStyle(.green)
            : (todo.overdue ? AnyShapeStyle(Brand.overdue) : AnyShapeStyle(.secondary))
        let icon = Image(systemName: symbol)
            .font(.system(size: compact ? 13 : 15))
            .foregroundStyle(tint)

        // Interactive check-off on macOS 14+ (AppIntent button). Placeholder
        // rows (no real UUID) stay non-interactive so they never queue a toggle.
        if #available(macOS 14.0, *), todo.id.count >= 8, !todo.id.hasPrefix("p") {
            Button(intent: ToggleTodoIntent(id: todo.id)) { icon }
                .buttonStyle(.plain)
        } else {
            icon
        }
    }
}

// MARK: - Entry view

struct VerbaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TodayEntry

    private var openFirst: [WidgetTodo] {
        // Overdue first, then due-today/undated; done items sink to the bottom.
        entry.todos.sorted { a, b in
            if a.done != b.done { return !a.done }
            if a.overdue != b.overdue { return a.overdue && !b.overdue }
            return (a.deadline ?? .distantFuture) < (b.deadline ?? .distantFuture)
        }
    }

    private var rowLimit: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 9
        }
    }

    private var openCount: Int { entry.todos.filter { !$0.done }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 8 : 6) {
            header

            if entry.todos.isEmpty {
                emptyState
            } else {
                let rows = Array(openFirst.prefix(rowLimit))
                VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
                    ForEach(rows) { todo in
                        TodoRow(todo: todo,
                                showProject: family != .systemSmall,
                                showTime: family != .systemSmall,
                                compact: family == .systemSmall)
                    }
                }
                if openFirst.count > rows.count {
                    Text("+\(openFirst.count - rows.count) more")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: Brand.mark)
                .font(.system(size: family == .systemSmall ? 12 : 13, weight: .semibold))
            Text("Today")
                .font(.system(size: family == .systemSmall ? 13 : 14, weight: .semibold))
            Spacer(minLength: 4)
            if openCount > 0 {
                Text("\(openCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.primary)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.green)
                Text("Nothing due today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            if family != .systemSmall {
                Text("You're all clear.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget + Bundle

struct VerbaTodayWidget: Widget {
    let kind = "VerbaTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            VerbaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Verba — Today")
        .description("Your tasks due today, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct VerbaWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerbaTodayWidget()
    }
}
