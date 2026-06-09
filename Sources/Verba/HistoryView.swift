import SwiftUI
import AppKit
import AVFoundation

/// In-app audio preview so you can play AND stop a dictation from History.
final class AudioPreview: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var playingURL: URL?
    private var player: AVAudioPlayer?

    func toggle(_ url: URL) {
        if playingURL == url { stop(); return }
        stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.play()
        playingURL = url
    }

    func stop() {
        player?.stop(); player = nil; playingURL = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.playingURL = nil }
    }
}

struct HistoryView: View {
    @ObservedObject var history = History.shared
    @StateObject private var audio = AudioPreview()
    @State private var selection: HistoryEntry.ID?
    @State private var query = ""
    @State private var rerunning = false

    // List card showing full text (the detail "Adapt" panel manages its own state).
    @State private var expandedCard: HistoryEntry.ID?

    private var filtered: [HistoryEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return history.entries }
        return history.entries.filter {
            $0.reprompted.lowercased().contains(q)
            || $0.original.lowercased().contains(q)
            || $0.profileName.lowercased().contains(q)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // List column, block cards, no separator lines.
            VStack(spacing: 0) {
                HStack {
                    Text("History").font(.system(size: 26, weight: .bold))
                    Spacer()
                    Button(role: .destructive) { audio.stop(); history.clear() } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all")
                }
                .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 10)

                // Search field.
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 12))
                    TextField("Search your dictations", text: $query)
                        .textFieldStyle(.plain)
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .padding(.horizontal, 14).padding(.bottom, 10)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        let items = filtered
                        if items.isEmpty {
                            Text(query.isEmpty ? "No dictations yet." : "No matches for “\(query)”.")
                                .font(.callout).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity).padding(.top, 30)
                        }
                        ForEach(items) { e in
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
        .onChange(of: selection) { _, _ in audio.stop() }   // stop when switching entry
        .onDisappear { audio.stop() }
    }

    private func card(_ e: HistoryEntry, selected: Bool) -> some View {
        let full = e.reprompted.isEmpty ? e.original : e.reprompted
        let expanded = expandedCard == e.id
        let long = full.count > 140 || full.contains("\n")
        return VStack(alignment: .leading, spacing: 5) {
            Text(full)
                .lineLimit(expanded ? nil : 2).font(.callout).foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            if long {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        expandedCard = expanded ? nil : e.id
                    }
                } label: {
                    Text(expanded ? "Show less" : "Show more")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
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
                        let playing = audio.playingURL == url
                        Button { audio.toggle(url) } label: {
                            Label(playing ? "Stop" : "Play audio", systemImage: playing ? "stop.circle" : "play.circle")
                        }
                        Button { exportAudio(url) } label: {
                            Label("Download audio", systemImage: "square.and.arrow.down")
                        }
                        .help("Save this recording to your Mac so you can re-import it into Transcribe file")
                    }
                    if rerunning {
                        ProgressView().controlSize(.small); Text("Re-running…").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button { rerun(e) } label: { Label("Re-run with Claude", systemImage: "arrow.clockwise") }
                            .help("Restructure the raw transcript again")
                    }
                    Spacer()
                    Button(role: .destructive) { audio.stop(); history.delete(e); selection = nil } label: { Label("Delete", systemImage: "trash") }
                }

                AdaptPanel(source: e.reprompted.isEmpty ? e.original : e.reprompted)
                    .id(e.id)   // reset the panel's state when switching entry
            }.padding(24)
        }
    }

    /// Re-run the AI restructuring on this entry's raw transcript (e.g. if Claude failed or
    /// it was never reprompted), and update the saved entry in place.
    private func rerun(_ e: HistoryEntry) {
        guard !rerunning else { return }
        rerunning = true
        Task {
            do {
                let p = Settings.shared.activeProfile
                let sys = p.raw ? Settings.shared.profiles.first(where: { !$0.raw })?.systemPrompt ?? "" : p.systemPrompt
                let r = Reprompter(model: p.model ?? Settings.shared.claudeModel)
                let out = try await r.reprompt(transcript: e.original, systemPrompt: sys)
                await MainActor.run { history.updateReprompted(e, text: out); rerunning = false }
            } catch {
                await MainActor.run { rerunning = false }
            }
        }
    }

    /// Export an entry's recorded audio to a user-chosen location (so it can be re-imported).
    private func exportAudio(_ url: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = url.lastPathComponent
        panel.canCreateDirectories = true
        panel.message = "Save this dictation's audio"
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        try? FileManager.default.removeItem(at: dest)   // overwrite if the user chose an existing name
        try? FileManager.default.copyItem(at: url, to: dest)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                CopyButton(text: body)
            }
            Text(body.isEmpty ? ", " : body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
