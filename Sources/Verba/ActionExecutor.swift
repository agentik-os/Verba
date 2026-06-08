import EventKit
import AppKit

/// Agentic Context actions (#4): the vision model may return a single JSON action instead of
/// text. We parse it strictly and execute it natively (Calendar / Reminders / email draft),
/// always behind an explicit confirmation window (driven by AppDelegate).
enum ActionIntent: String, Codable { case createCalendarEvent, createReminder, draftEmailReply }

struct ActionPayload: Codable {
    let action: ActionIntent
    var title: String?
    var description: String?
    var dueDate: String?       // ISO8601 with offset (prompt injects today's date + timezone)
    var duration: Int?         // minutes (calendar events)
    var replyTo: String?       // email recipient
    var draftBody: String?     // email body
}

enum ActionError: LocalizedError {
    case permissionDenied(String), noTarget(String), invalid(String)
    var errorDescription: String? {
        switch self { case .permissionDenied(let m), .noTarget(let m), .invalid(let m): return m }
    }
}

@MainActor
enum ActionExecutor {
    /// Strict parse: the response must be a single JSON object with a known `action`. Anything
    /// else (normal prose) returns nil so the plain-text path is used unchanged.
    static func parse(_ response: String) -> ActionPayload? {
        var t = response.trimmingCharacters(in: .whitespacesAndNewlines)
        // tolerate ```json fences
        if t.hasPrefix("```") {
            t = t.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard t.hasPrefix("{"), t.hasSuffix("}"), let data = t.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ActionPayload.self, from: data)
    }

    static func execute(_ p: ActionPayload) async -> Result<String, ActionError> {
        switch p.action {
        case .createCalendarEvent: return await createEvent(p)
        case .createReminder:      return await createReminder(p)
        case .draftEmailReply:     return draftEmail(p)
        }
    }

    // MARK: Calendar
    private static func createEvent(_ p: ActionPayload) async -> Result<String, ActionError> {
        let store = EKEventStore()
        guard await requestAccess(store, .event) else {
            return .failure(.permissionDenied("Calendar access denied. Enable Verba in System Settings ▸ Privacy ▸ Calendars."))
        }
        guard let title = p.title, !title.isEmpty else { return .failure(.invalid("No event title.")) }
        guard let start = parseDate(p.dueDate) else { return .failure(.invalid("Couldn't understand the date/time.")) }
        let ev = EKEvent(eventStore: store)
        ev.title = title
        ev.notes = p.description
        ev.startDate = start
        ev.endDate = start.addingTimeInterval(TimeInterval((p.duration ?? 60) * 60))
        guard let cal = store.defaultCalendarForNewEvents else { return .failure(.noTarget("No default calendar.")) }
        ev.calendar = cal
        do { try store.save(ev, span: .thisEvent); return .success("Event “\(title)” added to \(cal.title).") }
        catch { return .failure(.invalid("Couldn't save the event: \(error.localizedDescription)")) }
    }

    // MARK: Reminders
    private static func createReminder(_ p: ActionPayload) async -> Result<String, ActionError> {
        let store = EKEventStore()
        guard await requestAccess(store, .reminder) else {
            return .failure(.permissionDenied("Reminders access denied. Enable Verba in System Settings ▸ Privacy ▸ Reminders."))
        }
        guard let title = p.title, !title.isEmpty else { return .failure(.invalid("No reminder text.")) }
        let r = EKReminder(eventStore: store)
        r.title = title
        r.notes = p.description
        if let due = parseDate(p.dueDate) {
            r.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            r.addAlarm(EKAlarm(absoluteDate: due))
        }
        guard let cal = store.defaultCalendarForNewReminders() else { return .failure(.noTarget("No default reminders list.")) }
        r.calendar = cal
        do { try store.save(r, commit: true); return .success("Reminder “\(title)” added.") }
        catch { return .failure(.invalid("Couldn't save the reminder: \(error.localizedDescription)")) }
    }

    // MARK: Email draft (opens the composer pre-filled, never sends)
    private static func draftEmail(_ p: ActionPayload) -> Result<String, ActionError> {
        let to = p.replyTo ?? ""
        let subject = p.title ?? ""
        let body = p.draftBody ?? p.description ?? ""
        var s = "mailto:\(to)"
        var q: [String] = []
        let enc: (String) -> String = { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? $0 }
        if !subject.isEmpty { q.append("subject=\(enc(subject))") }
        if !body.isEmpty { q.append("body=\(enc(body))") }
        if !q.isEmpty { s += "?" + q.joined(separator: "&") }
        guard let url = URL(string: s) else { return .failure(.invalid("Couldn't build the email draft.")) }
        NSWorkspace.shared.open(url)
        return .success(to.isEmpty ? "Email draft opened." : "Email draft to \(to) opened.")
    }

    // MARK: helpers
    private static func requestAccess(_ store: EKEventStore, _ type: EKEntityType) async -> Bool {
        await withCheckedContinuation { cont in
            let handler: (Bool, Error?) -> Void = { granted, _ in cont.resume(returning: granted) }
            if type == .event { store.requestFullAccessToEvents(completion: handler) }
            else { store.requestFullAccessToReminders(completion: handler) }
        }
    }

    private static func parseDate(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            df.dateFormat = fmt
            if let d = df.date(from: s) { return d }
        }
        return nil
    }
}

private extension CharacterSet {
    /// Query-value-safe set (mailto bodies need + and & escaped).
    static let urlQueryValueAllowed: CharacterSet = {
        var cs = CharacterSet.urlQueryAllowed
        cs.remove(charactersIn: "+&=?#")
        return cs
    }()
}
