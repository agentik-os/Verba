import Foundation
import EventKit
import AppKit

// Private API (used by Terminal, iTerm, Chromium…) that makes a spawned child process "responsible
// for itself" — its macOS data-access (TCC) decisions are judged against the CHILD's identity, not
// Verba's. We disclaim responsibility for the helper tools we run (notably `/usr/bin/shortcuts`,
// which reads the Shortcuts app's data): that access is attributed to Apple's own, already-entitled
// `shortcuts` binary, so macOS 15's "Verba would like to access data from other apps" prompt never
// fires for it.
@_silgen_name("responsibility_spawnattrs_setdisclaim")
private func responsibility_spawnattrs_setdisclaim(_ attrs: UnsafeMutablePointer<posix_spawnattr_t?>, _ disclaim: Int32) -> Int32

// MARK: - VerbaAction — a structured agentic action dictated in Context mode
//
// Context mode can resolve a spoken request like "create an event tomorrow at 3pm" or
// "remind me to call the bank this afternoon" or "draft a reply to this email" into a
// concrete, confirmable action. `VerbaAction` is that resolved action; `ActionExecutor`
// performs it on macOS (Calendar / Reminders via EventKit, email via a mailto: draft).
// Nothing is ever executed without the user confirming first (see ActionConfirmView).

/// The categories of action the user can individually enable/disable in Settings ▸ Action mode.
enum ActionKind: String, CaseIterable, Codable {
    case calendar, reminder, email, shortcut, app, music, message, search, applescript
    case connectedApp
    var label: String {
        switch self {
        case .calendar:    return "Calendar events"
        case .reminder:    return "Reminders"
        case .email:       return "Email drafts"
        case .shortcut:    return "Run Shortcuts"
        case .app:         return "Open apps"
        case .music:       return "Play music"
        case .message:     return "Send messages"
        case .search:      return "Web search / open URL"
        case .applescript: return "AppleScript (advanced)"
        case .connectedApp: return "Connected apps"
        }
    }
    var icon: String {
        switch self {
        case .calendar: return "calendar"; case .reminder: return "checklist"
        case .email: return "envelope"; case .shortcut: return "bolt.fill"
        case .app: return "app.badge"; case .music: return "music.note"
        case .message: return "message.fill"; case .search: return "safari"
        case .applescript: return "applescript"
        case .connectedApp: return "app.connected.to.app.below.fill"
        }
    }
}

/// A user-configurable web search / quick-open target for Action mode. The model maps a spoken
/// "search X on Google" (or "open Y") to one of these by NAME, and the query fills `{q}`.
struct SearchTarget: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String          // e.g. "Google", "ChatGPT", "Claude", "YouTube"
    var urlTemplate: String   // e.g. "https://www.google.com/search?q={q}" ({q} = the spoken query)

    func url(for query: String) -> URL? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: urlTemplate.replacingOccurrences(of: "{q}", with: q))
    }

    static let defaults: [SearchTarget] = [
        SearchTarget(name: "Google",     urlTemplate: "https://www.google.com/search?q={q}"),
        SearchTarget(name: "ChatGPT",    urlTemplate: "https://chatgpt.com/?q={q}"),
        SearchTarget(name: "Claude",     urlTemplate: "https://claude.ai/new?q={q}"),
        SearchTarget(name: "Perplexity", urlTemplate: "https://www.perplexity.ai/search?q={q}"),
        SearchTarget(name: "YouTube",    urlTemplate: "https://www.youtube.com/results?search_query={q}"),
    ]
}

/// A structured, confirmable action the user dictated in Context mode.
enum VerbaAction: Codable, Equatable {
    /// Create a Calendar event. `end` defaults to start + 1h when nil.
    case calendarEvent(title: String, start: Date, end: Date?, notes: String?)
    /// Create a Reminder, optionally with a due date.
    case reminder(title: String, due: Date?, notes: String?)
    /// Open a prefilled email draft in the default mail client.
    case emailDraft(to: String?, subject: String?, body: String)
    /// Run a macOS Shortcut by name, optionally feeding it text input.
    case runShortcut(name: String, input: String?)
    /// Open / launch an application by name.
    case openApp(name: String)
    /// Play music in Music.app, optionally a specific playlist/track query.
    case playMusic(query: String?)
    /// Compose (and, after confirmation, send) a Messages.app message.
    case sendMessage(to: String, body: String)
    /// A generic AppleScript escape hatch the intent model can fill.
    case appleScript(label: String, script: String)
    /// Open a web URL (web searches, "open this site"), usually resolved from a search target.
    case openURL(label: String, url: URL)
    /// Execute a tool of a CONNECTED third-party app (Gmail, Slack, Notion, …) through the
    /// Composio relay on verba.run. `tool` is the exact Composio tool slug, `label` the
    /// human-readable description shown in the confirmation card.
    case composio(tool: String, label: String, arguments: [String: String])
    /// Mark an EXISTING Verba task (TodoStore) done, resolved by fuzzy title match. `match` is the
    /// words from the task title the user referenced ("the taxes task", "groceries").
    case completeTask(match: String)
    /// Set a reminder/deadline on an EXISTING Verba task (TodoStore), resolved by fuzzy title match.
    /// Setting the deadline schedules the existing 30-min reminder + full-screen alert.
    case setTaskReminder(match: String, due: Date)

    // MARK: Codable (tagged by "kind" so it round-trips cleanly)

    private enum CodingKeys: String, CodingKey {
        case kind, title, start, end, notes, due, to, subject, body
        case name, input, query, script, label, url
        case tool, args, match
    }
    private enum Kind: String, Codable {
        case calendarEvent, reminder, emailDraft
        case runShortcut, openApp, playMusic, sendMessage, appleScript, openURL
        case composio
        case completeTask, setTaskReminder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .calendarEvent:
            self = .calendarEvent(
                title: try c.decode(String.self, forKey: .title),
                start: try c.decode(Date.self, forKey: .start),
                end: try c.decodeIfPresent(Date.self, forKey: .end),
                notes: try c.decodeIfPresent(String.self, forKey: .notes))
        case .reminder:
            self = .reminder(
                title: try c.decode(String.self, forKey: .title),
                due: try c.decodeIfPresent(Date.self, forKey: .due),
                notes: try c.decodeIfPresent(String.self, forKey: .notes))
        case .emailDraft:
            self = .emailDraft(
                to: try c.decodeIfPresent(String.self, forKey: .to),
                subject: try c.decodeIfPresent(String.self, forKey: .subject),
                body: try c.decode(String.self, forKey: .body))
        case .runShortcut:
            self = .runShortcut(
                name: try c.decode(String.self, forKey: .name),
                input: try c.decodeIfPresent(String.self, forKey: .input))
        case .openApp:
            self = .openApp(name: try c.decode(String.self, forKey: .name))
        case .playMusic:
            self = .playMusic(query: try c.decodeIfPresent(String.self, forKey: .query))
        case .sendMessage:
            self = .sendMessage(
                to: try c.decode(String.self, forKey: .to),
                body: try c.decode(String.self, forKey: .body))
        case .appleScript:
            self = .appleScript(
                label: try c.decode(String.self, forKey: .label),
                script: try c.decode(String.self, forKey: .script))
        case .openURL:
            self = .openURL(
                label: try c.decode(String.self, forKey: .label),
                url: try c.decode(URL.self, forKey: .url))
        case .composio:
            self = .composio(
                tool: try c.decode(String.self, forKey: .tool),
                label: try c.decode(String.self, forKey: .label),
                arguments: try c.decodeIfPresent([String: String].self, forKey: .args) ?? [:])
        case .completeTask:
            self = .completeTask(match: try c.decode(String.self, forKey: .match))
        case .setTaskReminder:
            self = .setTaskReminder(
                match: try c.decode(String.self, forKey: .match),
                due: try c.decode(Date.self, forKey: .due))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .calendarEvent(title, start, end, notes):
            try c.encode(Kind.calendarEvent, forKey: .kind)
            try c.encode(title, forKey: .title)
            try c.encode(start, forKey: .start)
            try c.encodeIfPresent(end, forKey: .end)
            try c.encodeIfPresent(notes, forKey: .notes)
        case let .reminder(title, due, notes):
            try c.encode(Kind.reminder, forKey: .kind)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(due, forKey: .due)
            try c.encodeIfPresent(notes, forKey: .notes)
        case let .emailDraft(to, subject, body):
            try c.encode(Kind.emailDraft, forKey: .kind)
            try c.encodeIfPresent(to, forKey: .to)
            try c.encodeIfPresent(subject, forKey: .subject)
            try c.encode(body, forKey: .body)
        case let .runShortcut(name, input):
            try c.encode(Kind.runShortcut, forKey: .kind)
            try c.encode(name, forKey: .name)
            try c.encodeIfPresent(input, forKey: .input)
        case let .openApp(name):
            try c.encode(Kind.openApp, forKey: .kind)
            try c.encode(name, forKey: .name)
        case let .playMusic(query):
            try c.encode(Kind.playMusic, forKey: .kind)
            try c.encodeIfPresent(query, forKey: .query)
        case let .sendMessage(to, body):
            try c.encode(Kind.sendMessage, forKey: .kind)
            try c.encode(to, forKey: .to)
            try c.encode(body, forKey: .body)
        case let .appleScript(label, script):
            try c.encode(Kind.appleScript, forKey: .kind)
            try c.encode(label, forKey: .label)
            try c.encode(script, forKey: .script)
        case let .openURL(label, url):
            try c.encode(Kind.openURL, forKey: .kind)
            try c.encode(label, forKey: .label)
            try c.encode(url, forKey: .url)
        case let .composio(tool, label, arguments):
            try c.encode(Kind.composio, forKey: .kind)
            try c.encode(tool, forKey: .tool)
            try c.encode(label, forKey: .label)
            try c.encode(arguments, forKey: .args)
        case let .completeTask(match):
            try c.encode(Kind.completeTask, forKey: .kind)
            try c.encode(match, forKey: .match)
        case let .setTaskReminder(match, due):
            try c.encode(Kind.setTaskReminder, forKey: .kind)
            try c.encode(match, forKey: .match)
            try c.encode(due, forKey: .due)
        }
    }

    /// The user-facing category, for the enable/disable allow-list.
    var kind: ActionKind {
        switch self {
        case .calendarEvent: return .calendar
        case .reminder:      return .reminder
        case .emailDraft:    return .email
        case .runShortcut:   return .shortcut
        case .openApp:       return .app
        case .playMusic:     return .music
        case .sendMessage:   return .message
        case .appleScript:   return .applescript
        case .openURL:       return .search
        case .composio:      return .connectedApp
        // Acting on Verba's own to-dos is gated behind the same allow-list toggle as Reminders.
        case .completeTask:    return .reminder
        case .setTaskReminder: return .reminder
        }
    }

    // MARK: Presentation

    /// A short SF Symbol describing the action kind, for the confirmation UI.
    var icon: String {
        switch self {
        case .calendarEvent: return "calendar.badge.plus"
        case .reminder:      return "checklist"
        case .emailDraft:    return "envelope"
        case .runShortcut:   return "bolt.fill"
        case .openApp:       return "app.badge"
        case .playMusic:     return "music.note"
        case .sendMessage:   return "message.fill"
        case .appleScript:   return "applescript"
        case .openURL:       return "safari"
        case .composio:      return "app.connected.to.app.below.fill"
        case .completeTask:    return "checkmark.circle"
        case .setTaskReminder: return "alarm"
        }
    }

    /// A one-line human-readable summary, e.g. "Create event · Team sync · Tomorrow 15:00".
    var summary: String {
        switch self {
        case let .calendarEvent(title, start, _, _):
            return "Create event · \(title) · \(Self.when(start))"
        case let .reminder(title, due, _):
            if let due { return "Reminder · \(title) · \(Self.when(due))" }
            return "Reminder · \(title)"
        case let .emailDraft(to, subject, _):
            let who = (to?.isEmpty == false) ? to! : "new message"
            if let subject, !subject.isEmpty { return "Draft email · \(who) · \(subject)" }
            return "Draft email · \(who)"
        case let .runShortcut(name, input):
            if let input, !input.isEmpty { return "Run shortcut · \(name) · “\(Self.clip(input))”" }
            return "Run shortcut · \(name)"
        case let .openApp(name):
            return "Open app · \(name)"
        case let .playMusic(query):
            if let query, !query.isEmpty { return "Play music · \(query)" }
            return "Play music"
        case let .sendMessage(to, body):
            return "Send message · \(to) · “\(Self.clip(body))”"
        case let .appleScript(label, _):
            return "Run · \(label)"
        case let .openURL(label, _):
            return "Open · \(label)"
        case let .composio(tool, label, _):
            return "Connected app · \(label.isEmpty ? tool : label)"
        case let .completeTask(match):
            return "Complete task · \(Self.clip(match))"
        case let .setTaskReminder(match, due):
            return "Remind · \(Self.clip(match)) · \(Self.when(due))"
        }
    }

    /// Trim a long string for one-line summaries.
    private static func clip(_ s: String, _ max: Int = 40) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count > max ? String(t.prefix(max)) + "…" : t
    }

    /// Friendly relative-day + time formatting ("Today 15:00", "Tomorrow 09:00", "Jun 12, 15:00").
    private static func when(_ date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "HH:mm"
        let time = f.string(from: date)
        if cal.isDateInToday(date) { return "Today \(time)" }
        if cal.isDateInTomorrow(date) { return "Tomorrow \(time)" }
        let df = DateFormatter(); df.locale = .current; df.dateFormat = "MMM d, HH:mm"
        return df.string(from: date)
    }
}

// MARK: - ActionExecutor — performs a VerbaAction on macOS

/// Performs a confirmed `VerbaAction`: creates Calendar events / Reminders via EventKit
/// (requesting access first), or opens a prefilled email draft via a `mailto:` URL.
/// Each method throws `ActionError` with a clear, user-facing message on failure.
struct ActionExecutor {

    enum ActionError: LocalizedError {
        case calendarAccessDenied
        case remindersAccessDenied
        case noCalendar(String)
        case saveFailed(String)
        case mailtoFailed
        case shortcutFailed(String)
        case appNotFound(String)
        case scriptFailed(String)
        case noMatchingTask(String)
        case disabled(ActionKind)
        case notConnected(String)

        var errorDescription: String? {
            switch self {
            case .calendarAccessDenied:
                return "Calendar access is denied. Enable it in System Settings ▸ Privacy & Security ▸ Calendars."
            case .remindersAccessDenied:
                return "Reminders access is denied. Enable it in System Settings ▸ Privacy & Security ▸ Reminders."
            case let .noCalendar(kind):
                return "No default \(kind) is available to save into."
            case let .saveFailed(reason):
                return "Couldn't save: \(reason)"
            case .mailtoFailed:
                return "Couldn't open an email draft (no mail client configured?)."
            case let .shortcutFailed(reason):
                return "Couldn't run the Shortcut: \(reason)"
            case let .appNotFound(name):
                return "Couldn't find an app named “\(name)”."
            case let .scriptFailed(reason):
                return "The action couldn't be completed: \(reason)"
            case let .noMatchingTask(match):
                return "No open task matching “\(match)”."
            case let .disabled(kind):
                return "“\(kind.label)” actions are turned off in Settings ▸ Actions."
            case let .notConnected(app):
                return "\(app) isn't connected yet. Open Connected apps and connect it, then try again."
            }
        }
    }

    /// Dispatch to the right executor for the action kind.
    @discardableResult
    func perform(_ action: VerbaAction) async throws -> String {
        // Enforce the enable/disable allow-list on EVERY execution path. The non-agentic reprompt
        // gate (Pipeline) only covers the actions IT parses; the JARVIS / action-feed agentic path
        // (executeAgentAction → perform) reaches here directly and never consulted it, so a disabled
        // category could still run once confirmed. This funnel makes the allow-list actually binding.
        guard Settings.shared.isActionEnabled(action.kind) else {
            throw ActionError.disabled(action.kind)
        }
        switch action {
        case let .calendarEvent(title, start, end, notes):
            return try await createEvent(title: title, start: start, end: end, notes: notes)
        case let .reminder(title, due, notes):
            return try await createReminder(title: title, due: due, notes: notes)
        case let .emailDraft(to, subject, body):
            return try openEmailDraft(to: to, subject: subject, body: body)
        case let .runShortcut(name, input):
            return try runShortcut(name: name, input: input)
        case let .openApp(name):
            return try openApp(name: name)
        case let .playMusic(query):
            return try playMusic(query: query)
        case let .sendMessage(to, body):
            return try sendMessage(to: to, body: body)
        case let .appleScript(label, script):
            return try runAppleScript(label: label, script: script)
        case let .openURL(label, url):
            NSWorkspace.shared.open(url)
            return "Opened \(label)"
        case let .composio(tool, _, arguments):
            // Connected app: execute through the Composio relay on verba.run (the user already
            // confirmed; the relay enforces the signed-in session). Check the connection FIRST so a
            // never-connected app says "connect it" instead of returning the relay's raw 502.
            if let missing = Self.missingConnection(for: tool) { throw ActionError.notConnected(missing) }
            return try await ComposioStore.shared.execute(tool: tool, arguments: arguments)
        case let .completeTask(match):
            return try await completeVerbaTask(match: match)
        case let .setTaskReminder(match, due):
            return try await setVerbaTaskReminder(match: match, due: due)
        }
    }

    /// The name of the app a tool needs, when we can PROVE it isn't connected. Tool slugs are
    /// TOOLKIT_ACTION and connections are keyed by lowercased toolkit slug, so a live connection is
    /// a prefix of the tool slug (google_maps covers GOOGLE_MAPS_GET_DIRECTIONS).
    ///
    /// Deliberately conservative — it returns nil (execute anyway) unless ALL of these hold:
    /// `/connections` has answered successfully at least once (a failed fetch leaves the map empty,
    /// which must NOT read as "nothing is connected"), the tool's toolkit is in the catalog, that
    /// toolkit needs auth at all ("none"-auth toolkits run with no connected account), and no ACTIVE
    /// connection matches. A wrongly refused action is a worse failure than the relay's own error.
    private static func missingConnection(for tool: String) -> String? {
        let store = ComposioStore.shared
        guard store.didLoadConnections else { return nil }
        let slug = tool.lowercased()
        func covers(_ toolkit: String) -> Bool {
            let t = toolkit.lowercased()
            return !t.isEmpty && (slug == t || slug.hasPrefix(t + "_"))
        }
        // Longest match wins, so a "GOOGLE" entry can't shadow "GOOGLE_MAPS".
        let candidates = store.apps.filter { covers($0.slug) }
        guard let app = candidates.max(by: { $0.slug.count < $1.slug.count }), app.auth != "none" else { return nil }
        let connected = store.connections.contains { covers($0.key) && $0.value.uppercased() == "ACTIVE" }
        return connected ? nil : app.name
    }

    // MARK: Verba task manager (act on TodoStore's own to-dos)

    /// Mark an existing Verba task (or sub-task) done by fuzzy title match.
    @MainActor
    @discardableResult
    func completeVerbaTask(match: String) async throws -> String {
        guard let hit = Self.resolveOpenTask(match: match) else {
            throw ActionError.noMatchingTask(match)
        }
        if let subtaskID = hit.subtaskID {
            TodoStore.shared.markSubtaskDone(subtaskID: subtaskID, done: true)
        } else {
            TodoStore.shared.markDone(taskID: hit.taskID, done: true)
        }
        return "Marked “\(hit.title)” as done."
    }

    /// Set the deadline on an existing Verba task (or sub-task) by fuzzy title match. Persisting the
    /// deadline makes TodoReminders schedule the 30-min-ahead notification + full-screen alert.
    @MainActor
    @discardableResult
    func setVerbaTaskReminder(match: String, due: Date) async throws -> String {
        guard let hit = Self.resolveOpenTask(match: match) else {
            throw ActionError.noMatchingTask(match)
        }
        if let subtaskID = hit.subtaskID {
            TodoStore.shared.setSubtaskDeadline(subtaskID: subtaskID, due)
        } else {
            TodoStore.shared.setDeadline(hit.projectID, hit.taskID, due)
        }
        let df = DateFormatter(); df.locale = .current; df.dateStyle = .medium; df.timeStyle = .short
        return "Reminder set for “\(hit.title)” · \(df.string(from: due))."
    }

    /// A resolved open-task hit: the project + task (+ optional sub-task) and its display title.
    struct TaskHit { let projectID: UUID; let taskID: UUID; let subtaskID: UUID?; let title: String }

    /// Best fuzzy, case-insensitive match for `match` across every project's OPEN (not-done) tasks
    /// and sub-tasks. Returns nil when nothing scores above a small threshold. When two items tie
    /// (ambiguous phrasing) the first encountered in project/task order wins — the confirm card lets
    /// the user cancel if it picked the wrong one.
    @MainActor
    static func resolveOpenTask(match: String) -> TaskHit? {
        let query = match.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        var best: (score: Double, hit: TaskHit)? = nil
        for project in TodoStore.shared.projects {
            for task in project.tasks {
                if !task.isComplete {
                    let s = score(query, task.title)
                    if s > (best?.score ?? 0) {
                        best = (s, TaskHit(projectID: project.id, taskID: task.id, subtaskID: nil, title: task.title))
                    }
                }
                for sub in task.subtasks where !sub.done {
                    let s = score(query, sub.title)
                    if s > (best?.score ?? 0) {
                        best = (s, TaskHit(projectID: project.id, taskID: task.id, subtaskID: sub.id, title: sub.title))
                    }
                }
            }
        }
        guard let best, best.score >= 0.3 else { return nil }
        return best.hit
    }

    /// Simple title-similarity score in [0, 1]: exact = 1, substring = 0.85, else token overlap
    /// (Jaccard). Enough to map a spoken "the taxes task" onto a "File taxes" to-do.
    private static func score(_ query: String, _ title: String) -> Double {
        let t = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return 0 }
        if t == query { return 1.0 }
        if t.contains(query) || query.contains(t) { return 0.85 }
        let qw = Set(query.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        let tw = Set(t.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        guard !qw.isEmpty, !tw.isEmpty else { return 0 }
        let inter = qw.intersection(tw).count
        let union = qw.union(tw).count
        return union == 0 ? 0 : Double(inter) / Double(union)
    }

    // MARK: Calendar

    @discardableResult
    func createEvent(title: String, start: Date, end: Date?, notes: String?) async throws -> String {
        let store = EKEventStore()
        try await requestCalendarAccess(store)

        // The user's chosen calendar (Settings ▸ Action mode) wins; else the macOS default.
        let chosen = Settings.shared.eventCalendarID
        let calendar = (!chosen.isEmpty ? store.calendar(withIdentifier: chosen) : nil)
            ?? store.defaultCalendarForNewEvents
        guard let calendar else { throw ActionError.noCalendar("calendar") }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end ?? start.addingTimeInterval(3600)   // default to 1h
        if let notes, !notes.isEmpty { event.notes = notes }
        event.calendar = calendar
        do {
            try store.save(event, span: .thisEvent)
        } catch {
            throw ActionError.saveFailed(error.localizedDescription)
        }
        return "Event “\(title)” added to \(calendar.title)."
    }

    /// Request Calendar access using the modern macOS 14 API, falling back to the legacy one.
    private func requestCalendarAccess(_ store: EKEventStore) async throws {
        let granted: Bool
        if #available(macOS 14.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { ok, _ in cont.resume(returning: ok) }
            }
        }
        guard granted else { throw ActionError.calendarAccessDenied }
    }

    // MARK: Reminders

    @discardableResult
    func createReminder(title: String, due: Date?, notes: String?) async throws -> String {
        let store = EKEventStore()
        try await requestRemindersAccess(store)

        let chosen = Settings.shared.reminderListID
        let calendar = (!chosen.isEmpty ? store.calendar(withIdentifier: chosen) : nil)
            ?? store.defaultCalendarForNewReminders()
        guard let calendar else { throw ActionError.noCalendar("reminders list") }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar
        if let notes, !notes.isEmpty { reminder.notes = notes }
        if let due {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due)
        }
        do {
            try store.save(reminder, commit: true)
        } catch {
            throw ActionError.saveFailed(error.localizedDescription)
        }
        return "Reminder “\(title)” created."
    }

    /// Request Reminders access using the modern macOS 14 API, falling back to the legacy one.
    private func requestRemindersAccess(_ store: EKEventStore) async throws {
        let granted: Bool
        if #available(macOS 14.0, *) {
            granted = (try? await store.requestFullAccessToReminders()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .reminder) { ok, _ in cont.resume(returning: ok) }
            }
        }
        guard granted else { throw ActionError.remindersAccessDenied }
    }

    // MARK: Email draft

    @discardableResult
    func openEmailDraft(to: String?, subject: String?, body: String) throws -> String {
        var comps = URLComponents()
        comps.scheme = "mailto"
        // The recipient sits in the path of a mailto: URL.
        comps.path = (to ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var items: [URLQueryItem] = []
        if let subject, !subject.isEmpty { items.append(URLQueryItem(name: "subject", value: subject)) }
        if !body.isEmpty { items.append(URLQueryItem(name: "body", value: body)) }
        if !items.isEmpty { comps.queryItems = items }

        // URLComponents percent-encodes query values, but mailto bodies need spaces as %20
        // (not "+") and a few extra chars escaped; rebuild the query with the stricter set.
        if comps.queryItems != nil {
            comps.percentEncodedQuery = comps.queryItems?
                .map { "\($0.name)=\(Self.encode($0.value ?? ""))" }
                .joined(separator: "&")
        }

        guard let url = comps.url else { throw ActionError.mailtoFailed }
        guard NSWorkspace.shared.open(url) else { throw ActionError.mailtoFailed }
        return "Opened an email draft\(to.map { " to \($0)" } ?? "")."
    }

    /// Percent-encode a mailto query component (spaces → %20, escaping reserved chars).
    private static func encode(_ s: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")   // RFC 3986 unreserved
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }

    // MARK: macOS Shortcuts

    /// Run a macOS Shortcut by name via `/usr/bin/shortcuts run`. When `input` is given it's
    /// written to a temp file and passed with `--input-path` so the Shortcut receives the text.
    @discardableResult
    func runShortcut(name: String, input: String?) throws -> String {
        var args = ["run", name]
        var tmpURL: URL?
        if let input, !input.isEmpty {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("verba-shortcut-\(UUID().uuidString).txt")
            do { try input.write(to: url, atomically: true, encoding: .utf8) }
            catch { throw ActionError.shortcutFailed("couldn't stage input (\(error.localizedDescription))") }
            tmpURL = url
            args += ["--input-path", url.path]
        }
        defer { if let tmpURL { try? FileManager.default.removeItem(at: tmpURL) } }

        let (status, _, err) = Self.runProcess("/usr/bin/shortcuts", args)
        guard status == 0 else {
            let reason = err.isEmpty ? "exit code \(status)" : err
            throw ActionError.shortcutFailed(reason)
        }
        return "Ran the “\(name)” shortcut."
    }

    /// List the user's macOS Shortcuts by name (`/usr/bin/shortcuts list`) so the intent model can
    /// match a spoken request against the shortcuts they actually have. Returns [] on any failure.
    func availableShortcuts() -> [String] {
        let (status, out, _) = Self.runProcess("/usr/bin/shortcuts", ["list"])
        guard status == 0 else { return [] }
        return out.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: Launch app

    @discardableResult
    func openApp(name: String) throws -> String {
        let ws = NSWorkspace.shared
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Resolve by app name (with/without .app), then by display name.
        let candidates = [trimmed, trimmed.hasSuffix(".app") ? trimmed : "\(trimmed).app"]
        for candidate in candidates {
            if let url = ws.urlForApplication(withBundleIdentifier: candidate)
                ?? Self.appURL(named: candidate) {
                ws.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                return "Opened \(trimmed)."
            }
        }

        // Fallback: `open -a <name>` resolves fuzzy/display names the API misses.
        let (status, _, _) = Self.runProcess("/usr/bin/open", ["-a", trimmed])
        guard status == 0 else { throw ActionError.appNotFound(trimmed) }
        return "Opened \(trimmed)."
    }

    /// Look up an app bundle URL by file name across the standard Applications directories.
    private static func appURL(named name: String) -> URL? {
        let dirs = ["/Applications", "/System/Applications",
                    "\(NSHomeDirectory())/Applications"]
        for dir in dirs {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    // MARK: Music

    @discardableResult
    func playMusic(query: String?) throws -> String {
        let script: String
        if let q = query?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            let safe = Self.escapeAS(q)
            // Try a named playlist first, then fall back to plain play (e.g. resume / shuffle).
            script = """
            tell application "Music"
                activate
                try
                    play playlist "\(safe)"
                on error
                    try
                        play (every track whose name contains "\(safe)")
                    on error
                        play
                    end try
                end try
            end tell
            """
        } else {
            script = "tell application \"Music\" to play"
        }
        try Self.runScript(script)
        return query.map { "Playing “\($0)” in Music." } ?? "Playing music."
    }

    // MARK: Messages

    /// Compose and send a Messages.app message. Confirmation happens upstream (ActionConfirmView),
    /// so by the time this runs the user has already approved the send.
    @discardableResult
    func sendMessage(to: String, body: String) throws -> String {
        let safeTo = Self.escapeAS(to)
        let safeBody = Self.escapeAS(body)
        // The legacy `participant ... of (account ...)` form is unreliable on modern macOS Messages.
        // Try the more robust paths in order and only fail if every one errors:
        //   1. buddy of the iMessage service (works for a known handle / existing thread),
        //   2. participant of the iMessage service (older form, still works on some installs),
        //   3. buddy of the SMS service (texting a phone number with no iMessage).
        let script = """
        tell application "Messages"
            set theBody to "\(safeBody)"
            set theHandle to "\(safeTo)"
            try
                set iMsg to 1st service whose service type = iMessage
                send theBody to buddy theHandle of iMsg
            on error
                try
                    set iMsg to 1st service whose service type = iMessage
                    send theBody to participant theHandle of iMsg
                on error
                    set smsService to 1st service whose service type = SMS
                    send theBody to buddy theHandle of smsService
                end try
            end try
        end tell
        """
        try Self.runScript(script)
        return "Sent your message to \(to)."
    }

    // MARK: Generic AppleScript

    @discardableResult
    func runAppleScript(label: String, script: String) throws -> String {
        try Self.runScript(script)
        return "Done: \(label)."
    }

    // MARK: AppleScript / Process helpers

    /// Run an AppleScript via NSAppleScript, surfacing any error as a clean string.
    private static func runScript(_ source: String) throws {
        var errorInfo: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&errorInfo)
        if let errorInfo,
           let message = errorInfo[NSAppleScript.errorMessage] as? String {
            throw ActionError.scriptFailed(message)
        }
    }

    /// Escape a string for safe embedding inside an AppleScript double-quoted literal.
    /// Backslash and double-quote must be escaped; newlines / carriage returns can't appear
    /// literally inside a "..." literal (they'd break the string), so they're emitted as the
    /// AppleScript escapes \n / \r — letting multi-line values (e.g. a message body) survive intact.
    private static func escapeAS(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\r", with: "\\r")
         .replacingOccurrences(of: "\n", with: "\\n")
    }

    /// Run a process and capture (exit status, stdout, stderr-trimmed).
    /// Run a helper tool with responsibility DISCLAIMED (see the top-of-file note): the child owns
    /// its own TCC decisions, so `/usr/bin/shortcuts list` doesn't make macOS prompt the user with
    /// "Verba would like to access data from other apps." Falls back to a plain Process if the
    /// low-level spawn ever fails, so Action mode never silently loses these tools.
    private static func runProcess(_ launchPath: String, _ args: [String]) -> (Int32, String, String) {
        var attr: posix_spawnattr_t?
        guard posix_spawnattr_init(&attr) == 0 else { return runProcessPlain(launchPath, args) }
        defer { posix_spawnattr_destroy(&attr) }
        _ = responsibility_spawnattrs_setdisclaim(&attr, 1)

        let outPipe = Pipe(), errPipe = Pipe(), inPipe = Pipe()
        var fa: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fa)
        defer { posix_spawn_file_actions_destroy(&fa) }
        posix_spawn_file_actions_adddup2(&fa, inPipe.fileHandleForReading.fileDescriptor, 0)
        posix_spawn_file_actions_adddup2(&fa, outPipe.fileHandleForWriting.fileDescriptor, 1)
        posix_spawn_file_actions_adddup2(&fa, errPipe.fileHandleForWriting.fileDescriptor, 2)

        let argv = [launchPath] + args
        let cArgs: [UnsafeMutablePointer<CChar>?] = argv.map { strdup($0) } + [nil]
        defer { for p in cArgs where p != nil { free(p) } }

        var pid: pid_t = 0
        let spawnRC = posix_spawn(&pid, launchPath, &fa, &attr, cArgs, environ)
        // Close the child's ends (and our unused stdin) in the parent.
        try? inPipe.fileHandleForReading.close()
        try? outPipe.fileHandleForWriting.close()
        try? errPipe.fileHandleForWriting.close()
        try? inPipe.fileHandleForWriting.close()
        guard spawnRC == 0 else { return runProcessPlain(launchPath, args) }

        // Drain both pipes concurrently so a full buffer can't deadlock us.
        var outData = Data(), errData = Data()
        let group = DispatchGroup()
        let q = DispatchQueue(label: "verba.runproc.drain", attributes: .concurrent)
        q.async(group: group) { outData = outPipe.fileHandleForReading.readDataToEndOfFile() }
        q.async(group: group) { errData = errPipe.fileHandleForReading.readDataToEndOfFile() }
        group.wait()
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        let exit: Int32 = (status & 0x7f) == 0 ? (status >> 8) & 0xff : -1
        let err = (String(data: errData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (exit, String(data: outData, encoding: .utf8) ?? "", err)
    }

    /// Plain (non-disclaimed) fallback — only used if the low-level spawn fails to initialize.
    private static func runProcessPlain(_ launchPath: String, _ args: [String]) -> (Int32, String, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let outPipe = Pipe(); let errPipe = Pipe()
        p.standardOutput = outPipe; p.standardError = errPipe
        do { try p.run() } catch { return (-1, "", error.localizedDescription) }
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = (String(data: errData, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (p.terminationStatus, out, err)
    }
}
