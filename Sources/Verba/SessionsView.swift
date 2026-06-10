import SwiftUI

/// The Sessions panel: a lightweight list of recently-completed dictation Sessions, newest first.
/// Each row shows its mode, a one-line preview, when it finished, and a Copy button — so a result
/// the user ran in the background (while busy in another app) is never lost and can be pasted later.
/// Mirrors the simple list idiom of the Notes/Transcripts views; observes SessionStore for live
/// updates as Sessions complete.
struct SessionsView: View {
    @ObservedObject var store: SessionStore
    @State private var query = ""

    /// View-local search over completed results (text or mode name); in-flight rows always show.
    private var filteredCompleted: [Session] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.completed }
        return store.completed.filter {
            $0.resultText.lowercased().contains(q) || $0.modeName.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 20px inset (not the 28px grammar): compact 380pt-min window.
            HStack(spacing: 8) {
                Text("Recent Results").font(.system(size: 28, weight: .bold))
                if !store.inflight.isEmpty {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.small).scaleEffect(0.7)
                        Text("\(store.inflight.count) processing")
                            .font(.system(size: 11, weight: .medium)).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.06)))
                }
                Spacer()
                if !store.completed.isEmpty {
                    Button { store.clearCompleted() } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all results")
                }
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 2)
            Text("Finished dictations land here so you can copy them later.")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal, 20).padding(.bottom, 10)

            if store.completed.isEmpty && store.inflight.isEmpty {
                Spacer()
                EmptyState(icon: "tray", title: "No recent results yet",
                           message: "Run a dictation and the finished result will appear here, ready to copy.")
                Spacer()
            } else {
                // Search field.
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 12))
                    TextField("Search results", text: $query).textFieldStyle(.plain)
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .padding(.horizontal, 20).padding(.bottom, 10)

                if filteredCompleted.isEmpty && store.inflight.isEmpty {
                    Text("No matches for “\(query)”.")
                        .font(.callout).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.top, 30)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // In-flight Sessions first (still processing), then completed (newest first),
                            // so the user can watch a background dictation land and copy it the moment it's done.
                            ForEach(store.inflight) { sess in
                                InflightRow(session: sess)
                            }
                            ForEach(filteredCompleted) { sess in
                                SessionRow(session: sess) { store.remove(sess) }
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 14)
                    }
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
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: session.status == .failed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(session.status == .failed ? Color.red : Color.green)
                Text(session.modeName).font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 7).padding(.vertical, 1.5)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.08)))
                if session.autoPasted {
                    Text("pasted").font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.08)))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(timeLabel).font(.system(size: 10)).monospacedDigit().foregroundStyle(.tertiary)
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
                // Hover-revealed actions: keep the row quiet until the pointer is over it.
                // Fixed-height row stays in the layout (opacity only) so the list never reflows.
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
                .opacity(hovering || copied ? 1 : 0)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovering)
    }

    private var timeLabel: String {
        let date = session.finishedAt ?? session.startedAt
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

/// A live row for an in-flight Session — its mode plus a spinner and the current stage, so the user
/// can see background work happening. Observes the Session so its status flips to "Processing…" live;
/// once it completes the store moves it into `completed` and this row is replaced by a SessionRow.
private struct InflightRow: View {
    @ObservedObject var session: Session

    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small).scaleEffect(0.8)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.modeName).font(.system(size: 12, weight: .semibold))
                Text(stageLabel).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var stageLabel: String {
        switch session.status {
        case .transcribing: return "Transcribing…"
        case .processing:   return "Processing…"
        default:            return "Working…"
        }
    }
}
