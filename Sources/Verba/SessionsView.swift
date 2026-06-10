import SwiftUI

/// The Sessions panel: a lightweight list of recently-completed dictation Sessions, newest first.
/// Each row shows its mode, a one-line preview, when it finished, and a Copy button — so a result
/// the user ran in the background (while busy in another app) is never lost and can be pasted later.
///
/// Master-detail layout (like Notes / Modes / History): the left sidebar scrolls through every
/// in-flight + completed Session; the right pane shows the full selected result, ready to copy.
struct SessionsView: View {
    @ObservedObject var store: SessionStore
    @State private var query = ""
    @State private var filter: SessionFilter = .all
    @State private var selectedID: UUID?

    /// View-local search over completed results (text or mode name); in-flight rows always show.
    private var filteredCompleted: [Session] {
        var list = store.completed
        switch filter {
        case .all:    break
        case .done:   list = list.filter { $0.status != .failed }
        case .failed: list = list.filter { $0.status == .failed }
        }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.resultText.lowercased().contains(q) || $0.modeName.lowercased().contains(q)
        }
    }

    /// In-flight rows are only shown when the filter doesn't restrict to a finished status, and
    /// there's no active search (they have no result text to match yet).
    private var visibleInflight: [Session] {
        guard filter == .all,
              query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return store.inflight
    }

    // MARK: - Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider().opacity(0.4)
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 360)
        .onChange(of: store.completed.count) { _, _ in pruneSelection() }
    }

    // MARK: - Left: scrollable list of all results
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Results").font(.system(size: 17, weight: .bold))
                if !store.inflight.isEmpty {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.small).scaleEffect(0.7)
                        Text("\(store.inflight.count)")
                            .font(.system(size: 11, weight: .medium)).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.06)))
                }
                Spacer()
                if !store.completed.isEmpty {
                    Button { store.clearCompleted(); selectedID = nil } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all results")
                }
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

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
            .padding(.horizontal, 14).padding(.bottom, 8)

            // Filter chips.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SessionFilter.allCases) { f in
                        chip(label: f.label, icon: f.icon, on: filter == f) { filter = f }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
            }

            if store.completed.isEmpty && store.inflight.isEmpty {
                Spacer()
                EmptyState(icon: "tray", title: "No recent results yet",
                           message: "Run a dictation and the finished result will appear here, ready to copy.")
                    .padding(.horizontal, 14)
                Spacer()
            } else if visibleInflight.isEmpty && filteredCompleted.isEmpty {
                Spacer()
                Text("No matches for “\(query)”.")
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                // Tap-selected cards (exemplar grammar) — in-flight first (live), then completed.
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(visibleInflight) { sess in
                            InflightRow(session: sess)
                        }
                        ForEach(filteredCompleted) { sess in
                            sessionRow(sess)
                                .onTapGesture { selectedID = sess.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func sessionRow(_ sess: Session) -> some View {
        let selected = selectedID == sess.id
        let failed = sess.status == .failed
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: failed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(failed ? Color.red : Color.green)
                .frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(rowPreview(sess)).font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(sess.modeName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    Text("·").font(.caption2).foregroundStyle(.tertiary)
                    Text(timeLabel(sess)).font(.caption2).monospacedDigit().foregroundStyle(.tertiary)
                    if sess.autoPasted {
                        Text("· pasted").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.12 : 0.04))
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(selected ? 0.4 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { remove(sess) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func rowPreview(_ sess: Session) -> String {
        if sess.status == .failed { return sess.error ?? "Failed" }
        let t = sess.resultText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "(empty)" : t
    }

    // MARK: - Right: the selected result, full and copyable
    @ViewBuilder private var detail: some View {
        if let id = selectedID, let sess = store.completed.first(where: { $0.id == id }) {
            SessionDetail(session: sess) { remove(sess) }
                .id(sess.id)
        } else {
            EmptyState(icon: "doc.text",
                       title: "No result selected",
                       message: "Pick a result on the left to read it in full and copy it.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: shared bits
    @ViewBuilder private func chip(label: String, icon: String?, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 10, weight: .semibold)) }
                Text(label).font(.system(size: 12, weight: on ? .semibold : .medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 6.5)
            .foregroundStyle(on ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
            .background(
                Capsule(style: .continuous)
                    .fill(on ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(on ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func remove(_ sess: Session) {
        let wasSelected = (selectedID == sess.id)
        store.remove(sess)
        if wasSelected { selectedID = nil }
    }

    /// Drop a stale selection when the underlying result list shrinks (e.g. cleared / pruned).
    private func pruneSelection() {
        if let id = selectedID, !store.completed.contains(where: { $0.id == id }) { selectedID = nil }
    }

    private func timeLabel(_ sess: Session) -> String {
        let date = sess.finishedAt ?? sess.startedAt
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

private enum SessionFilter: String, CaseIterable, Identifiable {
    case all, done, failed
    var id: String { rawValue }
    var label: String { switch self { case .all: "All"; case .done: "Done"; case .failed: "Failed" } }
    var icon: String { switch self { case .all: "tray"; case .done: "checkmark.circle"; case .failed: "exclamationmark.triangle" } }
}

/// The right-pane viewer for one completed Session: mode badge + time, the full result text in a
/// scrollable glass card, and Copy / Delete actions.
private struct SessionDetail: View {
    @ObservedObject var session: Session
    let onRemove: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: mode + status + time + actions
            HStack(spacing: 8) {
                Image(systemName: session.status == .failed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(session.status == .failed ? Color.red : Color.green)
                Text(session.modeName).font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 2.5)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.08)))
                if session.autoPasted {
                    Text("pasted").font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6).padding(.vertical, 1.5)
                        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.08)))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(timeLabel).font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)

                if session.status != .failed {
                    Button {
                        Output.copyToClipboard(session.resultText, rich: session.rich)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .disabled(session.resultText.isEmpty)
                    .help("Copy result")
                }
                Button(role: .destructive) { onRemove() } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help("Delete result")
            }

            // The full result (or error), scrollable, filling the pane.
            ScrollView {
                Text(displayText)
                    .font(.system(size: 14))
                    .foregroundStyle(session.status == .failed ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(card(14))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
    }

    private var displayText: String {
        if session.status == .failed { return session.error ?? "Failed" }
        return session.resultText.isEmpty ? "(empty)" : session.resultText
    }

    private func card(_ r: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color.primary.opacity(0.035))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(Color.primary.opacity(0.07), lineWidth: 1))
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
/// once it completes the store moves it into `completed` and this row is replaced by a session card.
private struct InflightRow: View {
    @ObservedObject var session: Session

    var body: some View {
        HStack(spacing: 9) {
            ProgressView().controlSize(.small).scaleEffect(0.8).frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.modeName).font(.system(size: 13, weight: .semibold))
                Text(stageLabel).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
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
