import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var history = History.shared
    @State private var selection: HistoryEntry.ID?

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    Text("History").font(.title2.bold())
                    Spacer()
                    Button(role: .destructive) { history.clear() } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all")
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                Divider()
                List(history.entries, selection: $selection) { e in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.reprompted.isEmpty ? e.original : e.reprompted)
                            .lineLimit(2).font(.callout)
                        Text("\(e.date.formatted(date: .abbreviated, time: .shortened)) · \(e.profileName)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }.tag(e.id)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 260, idealWidth: 300)

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
        .background(Color(nsColor: .windowBackgroundColor))
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
            }.padding(20)
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
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
