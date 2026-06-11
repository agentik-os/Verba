import Foundation
import Combine
import WidgetKit

// MARK: - App → Widget data bridge
//
// The WidgetKit extension runs in a SEPARATE process and can't read TodoStore.
// This bridge is the app's side of the contract: it serialises "today's" tasks
// (the same set the in-app Today glance shows — due today + overdue, with an
// undated fallback) into the shared App-Group UserDefaults and nudges WidgetKit
// to reload. It also drains check-offs the user made from the widget itself.
//
// The `WidgetTodo` shape, the App-Group suite name, and the two defaults keys
// MUST stay byte-for-byte identical to Sources/VerbaWidget/VerbaWidget.swift.

/// App Group shared with the widget. Registered on the Apple Developer portal
/// and granted to both bundle IDs via the App-Group entitlement (see
/// sign-and-notarize.sh). Until that provisioning lands, `UserDefaults(suiteName:)`
/// silently falls back to a sandboxed store the widget can't see — the widget
/// then renders its placeholder, which is the intended graceful degradation.
private let kAppGroup = "group.975755H4ZC.verba"
private let kTodayKey = "widget.today"
private let kToggleKey = "widget.pendingToggles"

/// Row written to the shared snapshot. Mirror of the widget-side type (same
/// field names/order so the JSON is identical on both sides).
private struct WidgetTodo: Codable {
    var id: String
    var title: String
    var project: String
    var done: Bool
    var overdue: Bool
    var deadline: Date?
}

/// Keeps the shared App-Group snapshot of "today's" tasks in sync with TodoStore
/// and applies check-offs made from the widget. One instance, started at launch.
final class WidgetBridge {
    static let shared = WidgetBridge()

    private var cancellable: AnyCancellable?
    private var defaults: UserDefaults? { UserDefaults(suiteName: kAppGroup) }

    /// How long a just-completed row keeps lingering in the snapshot as a checked,
    /// struck-through "done" row before it's dropped. Long enough for the satisfying
    /// "completed" resting state (and to outlast the in-app glance slide-out), short
    /// enough that the next manual glance is clean.
    private let lingerWindow: TimeInterval = 6

    /// Rows the user just completed, kept briefly so the widget shows a checked
    /// resting state instead of the row vanishing (a layout jump). Keyed by row id;
    /// each carries the row as it should render (done = true) plus when it completed.
    /// Built in-process from snapshot diffs — no model/timestamp change required.
    private var lingering: [String: (row: WidgetTodo, at: Date)] = [:]

    /// The open-row ids in the last snapshot we wrote, so the next write can detect
    /// which rows transitioned open → gone (i.e. were just completed) and linger them.
    private var lastOpenRows: [String: WidgetTodo] = [:]

    private init() {}

    /// Call once at launch. Drains any widget check-offs queued while we were
    /// gone, subscribes to store changes, and writes the initial snapshot.
    func start() {
        drainPendingToggles()
        cancellable = TodoStore.shared.$projects
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] projects in self?.write(projects) }
        write(TodoStore.shared.projects)
    }

    /// Re-apply any check-offs the user made from the widget (e.g. on app
    /// activation). Safe to call repeatedly.
    func syncFromWidget() { drainPendingToggles() }

    // MARK: writing

    /// Serialise today's glance items into the shared defaults + reload the widget.
    ///
    /// `TodoGlance.items()` only ever emits OPEN tasks, so a task the user just
    /// checked off vanishes from the very next snapshot — the widget row would pop
    /// out and every row below it would jump up, with no satisfying "completed"
    /// resting state. To match the in-app glance's slide-out, we keep a just-
    /// completed row in the snapshot as `done = true` for a short linger window:
    /// the widget's openFirst sort sinks it to the bottom (struck-through, green
    /// check) and its own `open` filter keeps it out of the count, then it drops in
    /// one clean reflow when the window passes. Recently-completed rows are inferred
    /// purely from snapshot diffs here — no TodoTask timestamp/field is needed.
    private func write(_ projects: [TodoProject]) {
        guard let defaults else { return }
        let now = Date()

        // Live open rows from the glance (these are always `done = false`).
        let openRows = TodoGlance.items(from: projects).map {
            WidgetTodo(id: $0.id.uuidString, title: $0.title, project: $0.project,
                       done: $0.done, overdue: $0.overdue, deadline: $0.deadline)
        }
        let openIDs = Set(openRows.map(\.id))

        // Any row that was open in the last snapshot but is gone now was just
        // completed (or deleted) — capture it as a checked row so it can linger.
        for (id, prev) in lastOpenRows where !openIDs.contains(id) {
            var checked = prev
            checked.done = true
            lingering[id] = (row: checked, at: now)
        }

        // Expire stale lingerers, and never linger a row that's open again (e.g. the
        // user re-opened it from the widget) — the live open row wins.
        lingering = lingering.filter { _, v in now.timeIntervalSince(v.at) < lingerWindow }
        for id in openIDs { lingering.removeValue(forKey: id) }

        let rows = openRows + lingering.values.map(\.row)

        if let data = try? JSONEncoder().encode(rows) {
            defaults.set(data, forKey: kTodayKey)
            WidgetCenter.shared.reloadAllTimelines()
        }

        // Remember this snapshot's open rows for the next diff.
        lastOpenRows = Dictionary(openRows.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // Schedule a follow-up write so the lingering rows actually drop (and the
        // widget reflows once cleanly) even if no further store change arrives.
        scheduleLingerSweep()
    }

    /// One pending timer that re-writes the snapshot after the linger window so the
    /// just-completed rows fall away on their own. Coalesced: only the latest matters.
    private var lingerSweep: DispatchWorkItem?
    private func scheduleLingerSweep() {
        lingerSweep?.cancel()
        guard !lingering.isEmpty else { lingerSweep = nil; return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.lingerSweep = nil
            self.write(TodoStore.shared.projects)
        }
        lingerSweep = work
        DispatchQueue.main.asyncAfter(deadline: .now() + lingerWindow + 0.1, execute: work)
    }

    // MARK: draining widget toggles

    /// Apply (and clear) any task check-offs the widget's AppIntent queued.
    /// Each queued id is a task UUID; toggling means "mark done if open, reopen
    /// if done" — matched to the optimistic flip the widget already showed.
    private func drainPendingToggles() {
        guard let defaults,
              let pending = defaults.stringArray(forKey: kToggleKey), !pending.isEmpty else { return }
        defaults.removeObject(forKey: kToggleKey)

        let store = TodoStore.shared
        for idString in pending {
            guard let uuid = UUID(uuidString: idString) else { continue }
            let isDone = store.projects.contains { p in
                p.tasks.contains { $0.id == uuid && $0.done }
            }
            store.markDone(taskID: uuid, done: !isDone)
        }
        // markDone mutated `projects`; write a fresh authoritative snapshot.
        write(store.projects)
    }
}
