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
                    subtitle: L("Verba wants to do this for you. Review and confirm."),
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
            Button(L("Cancel"), role: .cancel) { onCancel() }
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
        case .calendarEvent: return L("Create a Calendar event?")
        case .reminder:      return L("Create a Reminder?")
        case .emailDraft:    return L("Open an email draft?")
        case let .runShortcut(name, _): return L("Run the “\(name)” shortcut?")
        case let .openApp(name):        return L("Open \(name)?")
        case .playMusic:                return L("Play music?")
        case let .sendMessage(to, _):   return L("Send a message to \(to)?")
        case let .appleScript(label, _): return "\(label)?"
        case let .openURL(label, _): return L("Open \(label)?")
        }
    }

    private var confirmLabel: String {
        switch action {
        case .calendarEvent: return L("Create event")
        case .reminder:      return L("Create reminder")
        case .emailDraft:    return L("Open draft")
        case .runShortcut:   return L("Run shortcut")
        case .openApp:       return L("Open app")
        case .playMusic:     return L("Play")
        case .sendMessage:   return L("Send message")
        case .appleScript:   return L("Run")
        case .openURL:       return L("Open")
        }
    }

    /// The key fields shown in the card, labelled.
    private var fields: [(String, String)] {
        switch action {
        case let .calendarEvent(title, start, end, notes):
            var f: [(String, String)] = [(L("Title"), title), (L("Starts"), Self.fmt(start))]
            if let end { f.append((L("Ends"), Self.fmt(end))) }
            if let notes, !notes.isEmpty { f.append((L("Notes"), notes)) }
            f.append((L("Calendar"), Self.defaultEventCalendar))   // WHERE it lands (your macOS default calendar)
            return f
        case let .reminder(title, due, notes):
            var f: [(String, String)] = [(L("Title"), title)]
            if let due { f.append((L("Due"), Self.fmt(due))) }
            if let notes, !notes.isEmpty { f.append((L("Notes"), notes)) }
            f.append((L("List"), Self.defaultReminderList))
            return f
        case let .emailDraft(to, subject, body):
            var f: [(String, String)] = []
            if let to, !to.isEmpty { f.append((L("To"), to)) }
            if let subject, !subject.isEmpty { f.append((L("Subject"), subject)) }
            if !body.isEmpty { f.append((L("Body"), body)) }
            if f.isEmpty { f.append((L("Email"), L("New message"))) }
            return f
        case let .runShortcut(name, input):
            var f: [(String, String)] = [(L("Shortcut"), name)]
            if let input, !input.isEmpty { f.append((L("Input"), input)) }
            return f
        case let .openApp(name):
            return [(L("App"), name)]
        case let .playMusic(query):
            return [(L("Music"), (query?.isEmpty == false) ? query! : L("Resume playback"))]
        case let .sendMessage(to, body):
            return [(L("To"), to), (L("Message"), body)]
        case let .appleScript(label, script):
            return [(L("Action"), label), ("Script", script)]
        case let .openURL(label, url):
            return [(L("Open"), label), ("URL", url.absoluteString)]
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
        store.defaultCalendarForNewEvents?.title ?? L("Default calendar")
    }
    static var defaultReminderList: String {
        store.defaultCalendarForNewReminders()?.title ?? L("Default list")
    }
}
