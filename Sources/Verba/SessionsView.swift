import SwiftUI

/// The Sessions panel: a lightweight list of recently-completed dictation Sessions, newest first.
/// Each row shows its mode, a one-line preview, when it finished, and a Copy button — so a result
/// the user ran in the background (while busy in another app) is never lost and can be pasted later.
/// Mirrors the simple list idiom of the Notes/Transcripts views; observes SessionStore for live
/// updates as Sessions complete.
struct SessionsView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Results").font(.headline)
                Spacer()
                if !store.completed.isEmpty {
                    Button("Clear") { store.clearCompleted() }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 10)

            if store.completed.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "tray").font(.system(size: 26)).foregroundStyle(.secondary)
                    Text("No recent results yet").foregroundStyle(.secondary).font(.system(size: 13))
                    Text("Finished dictations land here so you can copy them later.")
                        .foregroundStyle(.tertiary).font(.system(size: 11)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.completed) { sess in
                            SessionRow(session: sess) { store.remove(sess) }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 14)
                }
            }
        }
        .frame(minWidth: 380, minHeight: 320)
    }
}

private struct SessionRow: View {
    @ObservedObject var session: Session
    let onRemove: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: session.status == .failed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(session.status == .failed ? Color.red : Color.green)
                Text(session.modeName).font(.system(size: 12, weight: .semibold))
                if session.autoPasted {
                    Text("pasted").font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(timeLabel).font(.system(size: 10)).foregroundStyle(.tertiary)
            }

            if session.status == .failed {
                Text(session.error ?? "Failed")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            } else {
                Text(session.resultText.isEmpty ? "(empty)" : session.resultText)
                    .font(.system(size: 12)).foregroundStyle(.primary)
                    .lineLimit(4).fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            if session.status != .failed {
                HStack(spacing: 8) {
                    Button {
                        Output.copyToClipboard(session.resultText, rich: session.rich)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .disabled(session.resultText.isEmpty)

                    Button(role: .destructive) { onRemove() } label: {
                        Image(systemName: "trash").font(.system(size: 11))
                    }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var timeLabel: String {
        let date = session.finishedAt ?? session.startedAt
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}
