import SwiftUI
import EventKit

/// Confirmation sheet shown when Context mode (with Labs "Agentic actions" ON) resolves a spoken
/// request into a structured `VerbaAction`. Nothing is executed until the user taps Confirm; on
/// Cancel the action is discarded. Mirrors the ReviewView panel style.
struct ActionConfirmView: View {
    let action: VerbaAction
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GlassDialog(icon: action.icon,
                    title: heading,
                    subtitle: "Verba wants to do this for you. Review and confirm.",
                    width: 460,
                    drawsCard: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(fields, id: \.0) { label, value in
                    GlassLabeledValue(label: label) {
                        Text(value)
                            .font(.system(.body))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } buttons: {
            Spacer()
            Button("Cancel", role: .cancel) { onCancel() }
                .dialogSecondary()
                .keyboardShortcut(.cancelAction)
            Button(confirmLabel) { onConfirm() }
                .dialogPrimary()
                .keyboardShortcut(.return, modifiers: [.command])   // deliberate ⌘↩, not bare ↩ (agentic safety)
        }
    }

    // MARK: Presentation

    private var heading: String {
        switch action {
        case .calendarEvent: return "Create a Calendar event?"
        case .reminder:      return "Create a Reminder?"
        case .emailDraft:    return "Open an email draft?"
        case let .runShortcut(name, _): return "Run the “\(name)” shortcut?"
        case let .openApp(name):        return "Open \(name)?"
        case .playMusic:                return "Play music?"
        case let .sendMessage(to, _):   return "Send a message to \(to)?"
        case let .appleScript(label, _): return "\(label)?"
        }
    }

    private var confirmLabel: String {
        switch action {
        case .calendarEvent: return "Create event"
        case .reminder:      return "Create reminder"
        case .emailDraft:    return "Open draft"
        case .runShortcut:   return "Run shortcut"
        case .openApp:       return "Open app"
        case .playMusic:     return "Play"
        case .sendMessage:   return "Send message"
        case .appleScript:   return "Run"
        }
    }

    /// The key fields shown in the card, labelled.
    private var fields: [(String, String)] {
        switch action {
        case let .calendarEvent(title, start, end, notes):
            var f: [(String, String)] = [("Title", title), ("Starts", Self.fmt(start))]
            if let end { f.append(("Ends", Self.fmt(end))) }
            if let notes, !notes.isEmpty { f.append(("Notes", notes)) }
            f.append(("Calendar", Self.defaultEventCalendar))   // WHERE it lands (your macOS default calendar)
            return f
        case let .reminder(title, due, notes):
            var f: [(String, String)] = [("Title", title)]
            if let due { f.append(("Due", Self.fmt(due))) }
            if let notes, !notes.isEmpty { f.append(("Notes", notes)) }
            f.append(("List", Self.defaultReminderList))
            return f
        case let .emailDraft(to, subject, body):
            var f: [(String, String)] = []
            if let to, !to.isEmpty { f.append(("To", to)) }
            if let subject, !subject.isEmpty { f.append(("Subject", subject)) }
            if !body.isEmpty { f.append(("Body", body)) }
            if f.isEmpty { f.append(("Email", "New message")) }
            return f
        case let .runShortcut(name, input):
            var f: [(String, String)] = [("Shortcut", name)]
            if let input, !input.isEmpty { f.append(("Input", input)) }
            return f
        case let .openApp(name):
            return [("App", name)]
        case let .playMusic(query):
            return [("Music", (query?.isEmpty == false) ? query! : "Resume playback")]
        case let .sendMessage(to, body):
            return [("To", to), ("Message", body)]
        case let .appleScript(label, script):
            return [("Action", label), ("Script", script)]
        }
    }

    private static func fmt(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = .current
        f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: date)
    }

    // The macOS default calendar / reminders list the event or reminder will be created in, so the
    // user can see WHERE it goes (set the default in Calendar.app / Reminders.app to change it).
    private static let store = EKEventStore()
    static var defaultEventCalendar: String {
        store.defaultCalendarForNewEvents?.title ?? "Default calendar"
    }
    static var defaultReminderList: String {
        store.defaultCalendarForNewReminders()?.title ?? "Default list"
    }
}
