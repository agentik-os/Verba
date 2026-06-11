import Foundation
import Combine
import UserNotifications

/// Schedules local notifications 30 minutes before a to-do task's deadline.
///
/// Reconciles the system's pending notification set with `TodoStore`: for every task that
/// has a FUTURE deadline, is not done, and whose 30-min mark is still ahead, it schedules
/// ONE notification (identifier = the task's UUID, so an updated deadline replaces the old
/// one). Tasks that are done, deleted, had the deadline cleared, or whose 30-min mark is
/// already past get no notification (cleared by the full re-sync). Gated by
/// `Settings.todoReminders`.
/// Lets local notifications show as a banner + sound even while Verba is frontmost.
final class NotifPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

final class TodoReminders: ObservableObject {
    static let shared = TodoReminders()

    /// Whether reminders can actually fire: false when the user denied notifications (or hasn't
    /// decided yet) while reminders are ON. Views observe this to show an inline "enable
    /// notifications" nudge near a future deadline. `nil` until the first status read.
    @Published private(set) var notificationsAllowed: Bool?

    /// Minutes before the deadline that the reminder fires.
    private static let leadMinutes: TimeInterval = 30 * 60
    /// Prefix on every identifier so we only ever clear OUR requests, never anyone else's.
    private static let idPrefix = "todo-reminder."

    private var cancellable: AnyCancellable?
    private var authRequested = false

    private init() {}

    /// Presents notifications even when Verba is the frontmost app (a menu-bar app often is),
    /// so reminders actually appear instead of being silently suppressed.
    private let presenter = NotifPresenter()

    /// Call once at launch. Subscribes to store changes and does an initial reconcile.
    func start() {
        UNUserNotificationCenter.current().delegate = presenter
        cancellable = TodoStore.shared.$projects
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reconcile() }
        if Settings.shared.todoReminders {
            requestAuthorizationIfNeeded()
        }
        refreshAuthStatus()
        reconcile()
    }

    /// Refresh `notificationsAllowed` from the system's current authorization state.
    /// `.authorized`/`.provisional`/`.ephemeral` → true; denied/undetermined → false.
    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let ok: Bool
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: ok = true
            default: ok = false
            }
            DispatchQueue.main.async { self?.notificationsAllowed = ok }
        }
    }

    /// Ask for notification permission (alert + sound). Triggers the system prompt the first
    /// time; afterwards it's a no-op if already decided. Safe to call repeatedly.
    func requestAuthorizationIfNeeded() {
        guard !authRequested else { return }
        authRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            self?.refreshAuthStatus()
        }
    }

    /// React to the settings toggle: ON → request permission + (re)schedule; OFF → cancel all.
    func onSettingChanged(enabled: Bool) {
        if enabled {
            authRequested = false           // allow re-prompting if they'd never been asked
            requestAuthorizationIfNeeded()
            refreshAuthStatus()
            reconcile()
        } else {
            cancelAll()
        }
    }

    /// Remove every pending to-do reminder we scheduled.
    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
            if !ours.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ours) }
        }
    }

    /// Full re-sync: clear our pending requests, then reschedule every qualifying task.
    /// Simple and correct — the set of scheduled reminders always matches the store.
    func reconcile() {
        guard Settings.shared.todoReminders else { cancelAll(); return }
        let snapshot = TodoStore.shared.projects
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
            if !ours.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ours) }

            let now = Date()
            let df = DateFormatter()
            df.dateStyle = .none; df.timeStyle = .short

            /// Schedule one 30-min-ahead reminder for a single deadline-bearing item.
            func schedule(id: UUID, title: String, deadline: Date, project: String, isSubtask: Bool) {
                let fireAt = deadline.addingTimeInterval(-Self.leadMinutes)
                guard fireAt > now else { return }   // 30-min mark already passed → skip

                let content = UNMutableNotificationContent()
                content.title = "Soon: \(title.isEmpty ? (isSubtask ? "Untitled sub-task" : "Untitled task") : title)"
                content.body = "\(project) · due at \(df.string(from: deadline))"
                content.sound = .default

                let interval = fireAt.timeIntervalSince(now)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                center.add(UNNotificationRequest(
                    identifier: Self.idPrefix + id.uuidString,
                    content: content,
                    trigger: trigger))
            }

            for project in snapshot {
                for task in project.tasks {
                    if !task.done, let deadline = task.deadline {
                        schedule(id: task.id, title: task.title, deadline: deadline,
                                 project: project.name, isSubtask: false)
                    }
                    // Sub-task deadlines fire too — the row offers a DeadlinePicker, so it must reconcile.
                    for sub in task.subtasks {
                        guard !sub.done, let deadline = sub.deadline else { continue }
                        schedule(id: sub.id, title: sub.title, deadline: deadline,
                                 project: project.name, isSubtask: true)
                    }
                }
            }
        }
    }
}
