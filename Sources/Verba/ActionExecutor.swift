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

    // MARK: Codable (tagged by "kind" so it round-trips cleanly)

    private enum CodingKeys: String, CodingKey {
        case kind, title, start, end, notes, due, to, subject, body
        case name, input, query, script, label
    }
    private enum Kind: String, Codable {
        case calendarEvent, reminder, emailDraft
        case runShortcut, openApp, playMusic, sendMessage, appleScript
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
    private static func runProcess(_ launchPath: String, _ args: [String]) -> (Int32, String, String) {
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
