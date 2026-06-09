import SwiftUI

/// Confirmation sheet shown when Context mode (with Labs "Agentic actions" ON) resolves a spoken
/// request into a structured `VerbaAction`. Nothing is executed until the user taps Confirm; on
/// Cancel the action is discarded. Mirrors the ReviewView panel style.
struct ActionConfirmView: View {
    let action: VerbaAction
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(heading).font(.headline)
                    Text("Verba wants to do this for you. Review and confirm.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(fields, id: \.0) { label, value in
                    HStack(alignment: .top, spacing: 8) {
                        Text(label)
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(width: 78, alignment: .trailing)
                        Text(value)
                            .font(.system(.body))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button(confirmLabel) { onConfirm() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 460)
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
            return f
        case let .reminder(title, due, notes):
            var f: [(String, String)] = [("Title", title)]
            if let due { f.append(("Due", Self.fmt(due))) }
            if let notes, !notes.isEmpty { f.append(("Notes", notes)) }
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
}
