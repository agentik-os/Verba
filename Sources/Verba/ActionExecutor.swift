import Foundation
import EventKit
import AppKit

// MARK: - VerbaAction — a structured agentic action dictated in Context mode
//
// Context mode can resolve a spoken request like "create an event tomorrow at 3pm" or
// "remind me to call the bank this afternoon" or "draft a reply to this email" into a
// concrete, confirmable action. `VerbaAction` is that resolved action; `ActionExecutor`
// performs it on macOS (Calendar / Reminders via EventKit, email via a mailto: draft).
// Nothing is ever executed without the user confirming first (see ActionConfirmView).

/// A structured, confirmable action the user dictated in Context mode.
enum VerbaAction: Codable, Equatable {
    /// Create a Calendar event. `end` defaults to start + 1h when nil.
    case calendarEvent(title: String, start: Date, end: Date?, notes: String?)
    /// Create a Reminder, optionally with a due date.
    case reminder(title: String, due: Date?, notes: String?)
    /// Open a prefilled email draft in the default mail client.
    case emailDraft(to: String?, subject: String?, body: String)

    // MARK: Codable (tagged by "kind" so it round-trips cleanly)

    private enum CodingKeys: String, CodingKey {
        case kind, title, start, end, notes, due, to, subject, body
    }
    private enum Kind: String, Codable { case calendarEvent, reminder, emailDraft }

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
        }
    }

    // MARK: Presentation

    /// A short SF Symbol describing the action kind, for the confirmation UI.
    var icon: String {
        switch self {
        case .calendarEvent: return "calendar.badge.plus"
        case .reminder:      return "checklist"
        case .emailDraft:    return "envelope"
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
        }
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
            }
        }
    }

    /// Dispatch to the right executor for the action kind.
    @discardableResult
    func perform(_ action: VerbaAction) async throws -> String {
        switch action {
        case let .calendarEvent(title, start, end, notes):
            return try await createEvent(title: title, start: start, end: end, notes: notes)
        case let .reminder(title, due, notes):
            return try await createReminder(title: title, due: due, notes: notes)
        case let .emailDraft(to, subject, body):
            return try openEmailDraft(to: to, subject: subject, body: body)
        }
    }

    // MARK: Calendar

    @discardableResult
    func createEvent(title: String, start: Date, end: Date?, notes: String?) async throws -> String {
        let store = EKEventStore()
        try await requestCalendarAccess(store)

        guard let calendar = store.defaultCalendarForNewEvents else {
            throw ActionError.noCalendar("calendar")
        }
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
        return "Event “\(title)” added to your calendar."
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

        guard let calendar = store.defaultCalendarForNewReminders() else {
            throw ActionError.noCalendar("reminders list")
        }
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
}
