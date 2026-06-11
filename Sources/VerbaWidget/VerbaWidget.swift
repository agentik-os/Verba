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

// MARK: - Widget appearance (shared App-Group, read-only mirror of VAppr's WIDGET namespace)
//
// The widget extension links NOTHING from the app target (see the note at the
// top of this file), so it cannot reference `VAppr`. Instead it reads the same
// `widget.appr.*` keys VAppr writes into the shared App-Group suite. The key
// names, raw enum orders, and defaults MUST stay byte-for-byte identical to
// Sources/Verba/Appearance.swift (the WIDGET namespace).
//
// DEFAULTS REPRODUCE THE CURRENT LOOK EXACTLY: material .frosted, accent
// .monochrome (→ .primary, no forced color), corner scale 1.0, blur 0 — so a
// fresh install / unprovisioned App Group renders identically to before.

enum WidgetAppearance {
    /// Glass material → a translucent overlay tint. The widget can't host an
    /// NSVisualEffectView (WidgetKit composites the widget itself), so each
    /// material maps to an opacity over `.fill`, approximating its depth.
    enum Material: Int {
        case frosted = 0, soft, sidebar, hud, crystal, ultra
        /// Opacity of the `.fill` glass overlay behind the content. SwiftUI clamps
        /// `.opacity()` to [0,1], so values are kept ≤ 1.0 — `.hud`'s extra depth is
        /// rendered via `tintOverlay` instead of an out-of-range (no-op) opacity.
        var fillOpacity: Double {
            switch self {
            case .frosted: return 1.00   // .fill.tertiary baseline (current look)
            case .soft:    return 0.80
            case .sidebar: return 0.90
            case .hud:     return 1.00   // heaviest base; extra depth via tintOverlay
            case .crystal: return 0.55   // deep, very translucent
            case .ultra:   return 0.40
            }
        }

        /// An additional tint layered over the glass fill so materials at the same
        /// (clamped) opacity still read as distinct depths. `.hud` gets a darker
        /// primary wash that `.frosted` (same fillOpacity 1.0) does not — making the
        /// 'hud' selection a visible change rather than a silent no-op.
        var tintOverlay: Color? {
            switch self {
            case .hud: return Color.primary.opacity(0.06)
            default:   return nil
            }
        }
    }

    enum Accent: Int {
        case monochrome = 0, indigo, blue, teal, green, orange, pink, purple, custom
        /// nil = monochrome (use `.primary`); otherwise a fixed sRGB color.
        var color: Color? {
            switch self {
            case .monochrome: return nil
            case .indigo: return Color(.sRGB, red: 0.40, green: 0.36, blue: 0.95)
            case .blue:   return Color(.sRGB, red: 0.20, green: 0.52, blue: 1.00)
            case .teal:   return Color(.sRGB, red: 0.13, green: 0.70, blue: 0.74)
            case .green:  return Color(.sRGB, red: 0.18, green: 0.72, blue: 0.40)
            case .orange: return Color(.sRGB, red: 1.00, green: 0.52, blue: 0.13)
            case .pink:   return Color(.sRGB, red: 0.95, green: 0.30, blue: 0.55)
            case .purple: return Color(.sRGB, red: 0.66, green: 0.34, blue: 0.92)
            case .custom: return nil   // resolved from the stored hex by `resolvedAccent`
            }
        }
    }

    enum ColorMode: Int {
        case auto = 0, light, dark
        var colorScheme: ColorScheme? {
            switch self {
            case .auto:  return nil
            case .light: return .light
            case .dark:  return .dark
            }
        }
    }

    private static let cornerScaleRange: ClosedRange<Double> = 0.7...1.4
    private static func clamp(_ v: Double, _ r: ClosedRange<Double>) -> Double {
        Swift.min(r.upperBound, Swift.max(r.lowerBound, v))
    }
    private static var suite: UserDefaults? { UserDefaults(suiteName: kAppGroup) }

    // Live reads from the shared suite (graceful defaults if unprovisioned).
    static var material: Material {
        Material(rawValue: suite?.integer(forKey: "widget.appr.material") ?? 0) ?? .frosted
    }
    static var accent: Accent {
        Accent(rawValue: suite?.integer(forKey: "widget.appr.accent") ?? 0) ?? .monochrome
    }
    static var accentHex: String {
        suite?.string(forKey: "widget.appr.accenthex") ?? "5b5bd6"
    }
    static var colorMode: ColorMode {
        ColorMode(rawValue: suite?.integer(forKey: "widget.appr.colormode") ?? 0) ?? .auto
    }
    static var cornerScale: Double {
        clamp(suite?.object(forKey: "widget.appr.cornerscale") as? Double ?? 1.0, cornerScaleRange)
    }

    /// Resolved accent as a SwiftUI Color. Monochrome (and a bad custom hex) →
    /// nil, which callers render as `.primary` — the monochrome default look.
    static var resolvedAccent: Color? {
        if accent == .custom { return Color(vWidgetHex: accentHex) }
        return accent.color
    }

    /// A base corner radius scaled by the user's preference.
    static func corner(_ base: CGFloat) -> CGFloat { CGFloat(cornerScale) * base }
}

private extension Color {
    /// Parse "RRGGBB" / "#RRGGBB" into an sRGB Color (nil on bad input).
    init?(vWidgetHex hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xff) / 255,
                  green: Double((v >> 8) & 0xff) / 255,
                  blue: Double(v & 0xff) / 255)
    }
}

/// Deep links the widget opens in the app (handled by the `verba://` URL scheme).
enum WidgetLink {
    /// Opens Verba's Task Manager (Today / Todos). Tapping any non-checkbox area
    /// of the widget routes here so the surface is never a dead-end.
    static let todos = URL(string: "verba://todos")!
}

enum WidgetData {
    /// Read today's real tasks from the shared App-Group defaults. Returns `nil`
    /// when the app hasn't written a snapshot yet (fresh install, or App Group not
    /// yet provisioned) — the caller then renders the empty/"open Verba" state
    /// rather than fabricating tasks. Real data is the ONLY thing the live widget
    /// ever shows; `placeholder` is reserved for WidgetKit's gallery preview.
    static func todayOrNil() -> [WidgetTodo]? {
        guard let defaults = UserDefaults(suiteName: kAppGroup),
              let data = defaults.data(forKey: kTodayKey),
              let rows = try? JSONDecoder().decode([WidgetTodo].self, from: data) else {
            return nil
        }
        return rows
    }

    /// Sample tasks shown ONLY in WidgetKit's add-widget gallery / placeholder
    /// preview — never on the user's actual home screen (see `todayOrNil`).
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
    /// True when no real App-Group snapshot exists yet (fresh install / App Group
    /// not provisioned). The view then shows a "connect Verba" prompt instead of
    /// pretending the (empty) list is the user's real, all-clear day.
    var notConnected: Bool = false
}

struct TodayProvider: TimelineProvider {
    /// WidgetKit's gallery/preview context — sample tasks are appropriate ONLY here.
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todos: WidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        // The add-widget gallery preview uses sample data; the real installed
        // widget always reflects the user's actual snapshot (or the connect prompt).
        if context.isPreview {
            completion(TodayEntry(date: Date(), todos: WidgetData.placeholder))
        } else {
            completion(entryFromSnapshot())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = entryFromSnapshot()
        // Refresh hourly as a backstop; the app nudges WidgetKit on every store change.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    /// Build the live entry from the real snapshot — never from sample data.
    private func entryFromSnapshot() -> TodayEntry {
        if let rows = WidgetData.todayOrNil() {
            return TodayEntry(date: Date(), todos: rows)
        }
        return TodayEntry(date: Date(), todos: [], notConnected: true)
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
    /// User accent (nil = monochrome → `.secondary` open checkbox, the default).
    var accent: Color? = nil
    /// Corner radius for the time chip capsule (already accent/scale-resolved).
    var chipRadius: CGFloat = 8

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
                // Soft glass chip: a subtle primary tint, no hard box outline —
                // overdue reads through red text + a faint red wash, not a border.
                Text(timeChip(d))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(todo.overdue ? AnyShapeStyle(Brand.overdue) : AnyShapeStyle(.secondary))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(
                        (todo.overdue ? Brand.overdue.opacity(0.10) : Color.primary.opacity(0.06)),
                        in: RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                    )
                    .fixedSize()
            }
        }
    }

    @ViewBuilder private var checkbox: some View {
        let symbol = todo.done ? "checkmark.circle.fill" : "circle"
        // Open (not-done, not-overdue) checkboxes pick up the user's widget accent
        // when set; monochrome (accent == nil) keeps the default `.secondary` look.
        let openTint: AnyShapeStyle = accent.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.secondary)
        let tint: AnyShapeStyle = todo.done
            ? AnyShapeStyle(.green)
            : (todo.overdue ? AnyShapeStyle(Brand.overdue) : openTint)
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
        case .systemMedium: return 3
        // Large rows are two-line (title + project), so 9 + header + "+N more"
        // overflowed the frame and clipped the last rows. 6 two-line rows fit the
        // large widget's content height with the header and the overflow line.
        default: return 6
        }
    }

    /// Open items only, sorted — the SINGLE base for the header count, the visible
    /// rows, and the "+N more" overflow so they can never disagree (e.g. during the
    /// optimistic toggle window when a checked item is still present in the snapshot).
    private var open: [WidgetTodo] { openFirst.filter { !$0.done } }

    private var openCount: Int { open.count }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 8 : 6) {
            header

            if entry.notConnected {
                connectState
            } else if open.isEmpty {
                // No OPEN items (snapshot empty, or only checked-off rows linger
                // during the toggle window) → the honest "all clear" state.
                emptyState
            } else {
                let rows = Array(open.prefix(rowLimit))
                VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
                    ForEach(rows) { todo in
                        // showProject only on large: medium rows stay single-line so
                        // rowLimit rows + header + "+N more" never overflow the frame.
                        TodoRow(todo: todo,
                                showProject: family == .systemLarge,
                                showTime: family != .systemSmall,
                                compact: family == .systemSmall,
                                accent: WidgetAppearance.resolvedAccent,
                                chipRadius: WidgetAppearance.corner(8))
                    }
                }
                if open.count > rows.count {
                    // Tapping "+N more" opens the full Task Manager (no dead-end).
                    // Counted off `open` (same base as the header) so they agree.
                    Text("+\(open.count - rows.count) more")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // The whole surface is a deep link into Verba's Task Manager, so tapping a
        // task title, the header, or empty space opens the app instead of doing
        // nothing. (The per-row checkbox keeps its own AppIntent — it wins locally.)
        .widgetURL(WidgetLink.todos)
        // Honour the user's widget light/dark selection (auto → nil, follows system).
        .preferredColorScheme(WidgetAppearance.colorMode.colorScheme)
        // Material-aware glass: the baseline `.fill.tertiary` look at material
        // .frosted (fillOpacity 1.0), thinning/thickening with the chosen material,
        // plus a faint accent wash when a non-monochrome accent is set.
        .containerBackground(for: .widget) {
            ZStack {
                Color.clear.background(.fill.tertiary)
                    .opacity(WidgetAppearance.material.fillOpacity)
                // Per-material depth tint (e.g. .hud) so same-opacity materials differ.
                if let tint = WidgetAppearance.material.tintOverlay {
                    tint
                }
                if let accent = WidgetAppearance.resolvedAccent {
                    accent.opacity(0.06)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: Brand.mark)
                .font(.system(size: family == .systemSmall ? 12 : 13, weight: .semibold))
                // Tint the mark with the user's widget accent (monochrome → inherit .primary).
                .foregroundStyle(WidgetAppearance.resolvedAccent ?? .primary)
            // The snapshot is overdue + due-today (with an undated fallback), not strictly
            // "today" — so the header reads "Up next" to honestly match the list's contents
            // and the open-item count beside it.
            Text("Up next")
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
        // Top-anchored (no leading Spacer) so the message sits directly under the
        // header, matching the populated list's top-leading anchor across families.
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.green)
                Text("Nothing on deck")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Shown when no real snapshot exists yet — instead of fake tasks or a
    /// misleading "all clear", we invite the user to open Verba (the whole
    /// widget deep-links there) so today's tasks start syncing.
    private var connectState: some View {
        // Top-anchored like the list/empty states so the header+first-content
        // baseline stays at the same Y across connect / empty / populated.
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text("Open Verba")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            if family != .systemSmall {
                Text("Tap to sync today's tasks.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
