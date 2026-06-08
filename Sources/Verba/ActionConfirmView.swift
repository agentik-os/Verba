import SwiftUI

/// #4: confirmation card for an agentic Context action. No state, no async — AppDelegate
/// owns the window and runs the action on confirm.
struct ActionConfirmView: View {
    let action: ActionPayload
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var icon: String {
        switch action.action {
        case .createCalendarEvent: return "calendar.badge.plus"
        case .createReminder:      return "checklist"
        case .draftEmailReply:     return "envelope.badge"
        }
    }
    private var heading: String {
        switch action.action {
        case .createCalendarEvent: return "Create calendar event"
        case .createReminder:      return "Create reminder"
        case .draftEmailReply:     return "Open email draft"
        }
    }
    private var detail: String {
        switch action.action {
        case .createCalendarEvent:
            var s = action.title ?? "(untitled)"
            if let d = action.dueDate { s += "\n\(prettyDate(d))" }
            if let dur = action.duration { s += " · \(dur) min" }
            return s
        case .createReminder:
            var s = action.title ?? "(untitled)"
            if let d = action.dueDate { s += "\n\(prettyDate(d))" }
            return s
        case .draftEmailReply:
            var s = "To: \(action.replyTo ?? "—")"
            if let t = action.title, !t.isEmpty { s += "\nSubject: \(t)" }
            return s
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(.tint)
                Text(heading).font(.title3.bold())
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(detail).font(.callout).fixedSize(horizontal: false, vertical: true)
                if let body = action.draftBody ?? action.description, !body.isEmpty {
                    Divider()
                    ScrollView { Text(body).font(.callout).frame(maxWidth: .infinity, alignment: .leading) }
                        .frame(maxHeight: 140)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Verba will only do this if you confirm.").font(.caption).foregroundStyle(.secondary)

            HStack {
                Button("Cancel", action: onCancel).buttonStyle(.plain).foregroundStyle(.secondary)
                Spacer()
                Button(action: onConfirm) { Text("Confirm").frame(minWidth: 110) }.buttonStyle(DarkButton())
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func prettyDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        let d = f.date(from: iso) ?? { f.formatOptions = [.withInternetDateTime]; return f.date(from: iso) }()
        guard let d else { return iso }
        return d.formatted(date: .abbreviated, time: .shortened)
    }
}
