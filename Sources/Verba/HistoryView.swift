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

    // Per-message "Adapt" state (re-process the text through a mode or a typed intent).
    @State private var expandedCard: HistoryEntry.ID?     // list card showing full text
    @State private var adapting = false
    @State private var adaptResult = ""
    @State private var adaptError: String?
    @State private var adaptLabel = ""                     // which mode/intent produced the result
    @State private var customIntent = ""

    /// Modes offered for one-click re-adaptation: every reprompting mode except raw flow
    /// and the screen-capture Context mode (which needs a screenshot it can't get here).
    private var adaptModes: [Profile] {
        Settings.shared.profiles.filter { !$0.raw && !$0.vision }
    }

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
        .onChange(of: selection) { _, _ in audio.stop(); resetAdapt() }   // stop & clear when switching entry
        .onDisappear { audio.stop() }
    }

    private func resetAdapt() {
        adapting = false; adaptResult = ""; adaptError = nil; adaptLabel = ""; customIntent = ""
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

                adaptSection(e)
            }.padding(24)
        }
    }

    /// Per-message "Adapt" panel: re-process this dictation through any reprompting mode in
    /// one click, or with a custom typed instruction, and show/copy the adapted result.
    private func adaptSection(_ e: HistoryEntry) -> some View {
        let source = e.reprompted.isEmpty ? e.original : e.reprompted
        return VStack(alignment: .leading, spacing: 10) {
            Text("Adapt this dictation").font(.headline)

            // One-click mode buttons.
            AdaptModeChips(modes: adaptModes) { mode in adapt(source, mode: mode) }
                .disabled(adapting)

            // Custom "Intent" adapt: type how you want it transformed.
            HStack(spacing: 8) {
                TextField("Describe how to adapt it (e.g. make it a bug report)", text: $customIntent)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .onSubmit { adaptCustom(source) }
                Button { adaptCustom(source) } label: { Label("Adapt", systemImage: "wand.and.stars") }
                    .buttonStyle(.borderless)
                    .disabled(adapting || customIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Result / progress / error.
            if adapting {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Adapting\(adaptLabel.isEmpty ? "" : " · \(adaptLabel)")…")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if let err = adaptError {
                Text(err).font(.caption).foregroundStyle(.red)
            } else if !adaptResult.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(adaptLabel.isEmpty ? "Result" : "Result · \(adaptLabel)")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        CopyButton(text: adaptResult)
                    }
                    Text(adaptResult)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.top, 4)
    }

    /// Re-process `text` through a built-in mode and surface the result (does not overwrite history).
    private func adapt(_ text: String, mode: Profile) {
        guard !adapting else { return }
        runAdapt(label: mode.name, systemPrompt: mode.effectiveSystemPrompt,
                 model: mode.model ?? Settings.shared.claudeModel, transcript: text)
    }

    /// Re-process `text` with the user's typed instruction.
    private func adaptCustom(_ text: String) {
        let intent = customIntent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !adapting, !intent.isEmpty else { return }
        // Build a faithful single-language prompt around the user's instruction.
        let sys = """
        You adapt an existing piece of text according to the user's instruction below. \
        Apply it faithfully and output ONLY the adapted text, with no preamble, notes, or quotes.

        INSTRUCTION: \(intent)

        Do not add facts that are not in the text. Keep every detail the instruction does not \
        ask you to drop. ALWAYS write the output in the SAME language as the input text, unless \
        the instruction explicitly asks for another language. This is mandatory.
        NEVER use an em dash, an en dash, or a spaced hyphen; use commas, periods, parentheses, \
        or colons instead.
        """
        runAdapt(label: "Intent", systemPrompt: sys,
                 model: Settings.shared.claudeModel, transcript: text)
    }

    private func runAdapt(label: String, systemPrompt: String, model: String, transcript: String) {
        adapting = true; adaptError = nil; adaptResult = ""; adaptLabel = label
        Task {
            do {
                let out = try await Reprompter(model: model).reprompt(transcript: transcript, systemPrompt: systemPrompt)
                await MainActor.run { adaptResult = out; adapting = false }
            } catch {
                await MainActor.run { adaptError = error.localizedDescription; adapting = false }
            }
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

/// Wrapping row of small mode chips used by the History "Adapt" panel. Reuses the shared
/// FlowLayout from ModesView so chips wrap as the detail pane resizes.
private struct AdaptModeChips: View {
    let modes: [Profile]
    let action: (Profile) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(modes) { mode in
                Button { action(mode) } label: {
                    Text(mode.name)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.softFill, in: Capsule())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
