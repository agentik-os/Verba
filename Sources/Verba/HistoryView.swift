import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var history = History.shared
    @State private var selection: HistoryEntry.ID?

    var body: some View {
        HStack(spacing: 0) {
            // List column — block cards, no separator lines.
            VStack(spacing: 0) {
                HStack {
                    Text("History").font(.system(size: 26, weight: .bold))
                    Spacer()
                    Button(role: .destructive) { history.clear() } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all")
                }
                .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(history.entries) { e in
                            Button { selection = e.id } label: { card(e, selected: e.id == selection) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 16)
                }
            }
            .frame(width: 340)

            // Detail.
            Group {
                if let e = history.entries.first(where: { $0.id == selection }) {
                    detail(e)
                } else {
                    ContentUnavailableView("Select a dictation", systemImage: "clock.arrow.circlepath")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func card(_ e: HistoryEntry, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(e.reprompted.isEmpty ? e.original : e.reprompted)
                .lineLimit(2).font(.callout).foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(selected ? 0.45 : 0), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detail(_ e: HistoryEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section("Restructured (Claude)", e.reprompted)
                section("Raw transcript", e.original)
                HStack {
                    if let url = history.audioURL(for: e) {
                        Button { NSWorkspace.shared.open(url) } label: { Label("Play audio", systemImage: "play.circle") }
                    }
                    Spacer()
                    Button(role: .destructive) { history.delete(e); selection = nil } label: { Label("Delete", systemImage: "trash") }
                }
            }.padding(24)
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button { Output.copyToClipboard(body) } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless)
            }
            Text(body.isEmpty ? "—" : body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
