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
    private func write(_ projects: [TodoProject]) {
        guard let defaults else { return }
        let items = TodoGlance.items(from: projects)
        let rows = items.map {
            WidgetTodo(id: $0.id.uuidString, title: $0.title, project: $0.project,
                       done: $0.done, overdue: $0.overdue, deadline: $0.deadline)
        }
        if let data = try? JSONEncoder().encode(rows) {
            defaults.set(data, forKey: kTodayKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
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
