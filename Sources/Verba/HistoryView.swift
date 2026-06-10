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
    @State private var showSearch = false
    @State private var filterMode: String?     // filter by profile / mode name; nil = All
    @State private var filterEngine: String?   // filter by engine family (e.g. "openai"); nil = All
    @State private var rerunning = false
    @State private var rerunError: String?      // surfaced inline when a re-run fails
    @State private var confirmClear = false     // guard the destructive "clear all"

    // MARK: - Derived filter sets
    /// Distinct mode (profile) names present in history, in first-seen order.
    private var modeNames: [String] {
        var seen = Set<String>(); var out: [String] = []
        for e in history.entries where !e.profileName.isEmpty {
            if seen.insert(e.profileName).inserted { out.append(e.profileName) }
        }
        return out
    }

    /// Distinct engine families present in history (the part before the ":" in the stored
    /// "family:model" label, e.g. "openai", "whisper", "parakeet"), in first-seen order.
    private var engineFamilies: [String] {
        var seen = Set<String>(); var out: [String] = []
        for e in history.entries {
            let fam = Self.engineFamily(e.engine)
            guard !fam.isEmpty else { continue }
            if seen.insert(fam).inserted { out.append(fam) }
        }
        return out
    }

    private static func engineFamily(_ raw: String) -> String {
        String(raw.split(separator: ":").first ?? "")
    }

    private static func engineLabel(_ fam: String) -> String {
        switch fam.lowercased() {
        case "openai":   return "OpenAI"
        case "whisper":  return "Whisper"
        case "parakeet": return "Parakeet"
        default:         return fam.isEmpty ? "Engine" : fam.capitalized
        }
    }

    private var filtered: [HistoryEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return history.entries.filter { e in
            if let m = filterMode, e.profileName != m { return false }
            if let f = filterEngine, Self.engineFamily(e.engine) != f { return false }
            guard !q.isEmpty else { return true }
            return e.reprompted.lowercased().contains(q)
                || e.original.lowercased().contains(q)
                || e.profileName.lowercased().contains(q)
        }
    }

    private var hasFilters: Bool { filterMode != nil || filterEngine != nil }

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider().opacity(0.4)
            // Detail.
            Group {
                if let e = history.entries.first(where: { $0.id == selection }) {
                    detail(e)
                } else {
                    EmptyState(icon: "clock.arrow.circlepath", title: "Select a dictation",
                               message: "Pick an entry on the left to read, replay, or re-adapt it.")
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selection) { _, _ in audio.stop(); rerunError = nil }   // stop + clear stale error when switching entry
        .onDisappear { audio.stop() }
    }

    // MARK: - Left: header + filter chips + search + scrollable cards
    private var sidebar: some View {
        let items = filtered
        return VStack(spacing: 0) {
            HStack {
                Text("History").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { withAnimation(.easeInOut(duration: 0.18)) { showSearch.toggle(); if !showSearch { query = "" } } } label: {
                    Image(systemName: showSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .buttonStyle(.borderless).help("Search dictations")
                if !history.entries.isEmpty {
                    Button(role: .destructive) { confirmClear = true } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).help("Clear all")
                        .confirmationDialog("Clear all dictations?", isPresented: $confirmClear, titleVisibility: .visible) {
                            Button("Clear all", role: .destructive) { audio.stop(); history.clear(); selection = nil }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("This permanently deletes every dictation in your history, including their transcripts and recordings. This can't be undone.")
                        }
                }
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            // Filter chips: by mode and/or by engine (Notes chip grammar).
            if !modeNames.isEmpty || !engineFamilies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip(label: "All", icon: nil, on: !hasFilters) { filterMode = nil; filterEngine = nil }
                        ForEach(modeNames, id: \.self) { m in
                            chip(label: m, icon: "text.bubble", on: filterMode == m) { filterMode = (filterMode == m ? nil : m) }
                        }
                        ForEach(engineFamilies, id: \.self) { f in
                            chip(label: Self.engineLabel(f), icon: "waveform", on: filterEngine == f) { filterEngine = (filterEngine == f ? nil : f) }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 8)
                }
            }

            // Search field over dictation text + mode (toggled from the header action).
            if showSearch {
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
                .padding(.horizontal, 14).padding(.bottom, 8)
                .transition(.opacity)
            }

            if items.isEmpty {
                Spacer()
                if history.entries.isEmpty {
                    EmptyState(icon: "clock.arrow.circlepath", title: "No dictations yet",
                               message: "Every dictation you make lands here, searchable, replayable, and re-adaptable.")
                        .padding(.horizontal, 14)
                } else {
                    EmptyState(icon: "magnifyingglass", title: "No matches",
                               message: "No dictation matches the current search or filters. Clear them to see everything.")
                        .padding(.horizontal, 14)
                }
                Spacer()
            } else {
                // Tap-selected cards (Notes grammar) — NOT a Button/List, whose system-blue
                // highlight would paint under our custom card and double-box it.
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(items) { e in
                            card(e, selected: e.id == selection)
                                .onTapGesture { selection = e.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func card(_ e: HistoryEntry, selected: Bool) -> some View {
        let full = e.reprompted.isEmpty ? e.original : e.reprompted
        return VStack(alignment: .leading, spacing: 3) {
            Text(snippet(full)).font(.system(size: 13, weight: .medium)).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 5) {
                Text(e.profileName.isEmpty ? "Flow" : e.profileName)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 1.5)
                    .background(Capsule(style: .continuous).fill(.softFill))
                    .lineLimit(1)
                Text("·").font(.caption2).foregroundStyle(.tertiary)
                Text(e.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(selected: selected, cornerRadius: 12)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            Button { Output.copyToClipboard(full) } label: { Label("Copy", systemImage: "doc.on.doc") }
            Button(role: .destructive) {
                audio.stop(); history.delete(e)
                if selection == e.id { selection = nil }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    /// First meaningful line of the dictation for the list title (single line, trimmed).
    private func snippet(_ text: String) -> String {
        for raw in text.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if !line.isEmpty { return String(line.prefix(120)) }
        }
        return "Empty dictation"
    }

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
                    .fill(Color.primary.opacity(on ? VGlass.fillSelected : VGlass.fillSecondary))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(on ? VGlass.hairlineSelected : VGlass.hairline), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func detail(_ e: HistoryEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section("Restructured (Claude)", e.reprompted)
                section("Raw transcript", e.original)
                // Action toolbar: borderless icons in one soft row, no stock bordered buttons.
                HStack(spacing: 10) {
                    if let url = history.audioURL(for: e) {
                        let playing = audio.playingURL == url
                        Button { audio.toggle(url) } label: {
                            Image(systemName: playing ? "stop.circle" : "play.circle")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .help(playing ? "Stop playback" : "Play audio")
                        Button { exportAudio(url) } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .help("Save this recording to your Mac so you can re-import it into Transcribe file")
                        Divider().frame(height: 12)
                    }
                    if rerunning {
                        ProgressView().controlSize(.small)
                        Text("Re-running…").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button { rerun(e) } label: {
                            Label("Re-run as \(rerunModeLabel(e))", systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .help("Re-run with Claude using this dictation's own mode (\(rerunModeLabel(e))) on its raw transcript")
                    }
                    Spacer()
                    Button(role: .destructive) { audio.stop(); history.delete(e); selection = nil } label: {
                        Image(systemName: "trash").font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help("Delete this dictation")
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Surface a failed re-run inline instead of silently stopping the spinner.
                if let err = rerunError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        Text(err).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity)
                }

                AdaptPanel(source: e.reprompted.isEmpty ? e.original : e.reprompted)
                    .id(e.id)   // reset the panel's state when switching entry
            }.padding(24)
        }
    }

    /// Resolve the Profile a re-run should use: the entry's OWN mode (matched by name),
    /// falling back to the active profile only if that mode no longer exists. If the
    /// resolved mode is raw (no reprompting) we borrow the first reprompting mode's prompt,
    /// since re-run exists precisely to restructure the raw transcript.
    private func rerunProfile(_ e: HistoryEntry) -> Profile {
        if !e.profileName.isEmpty,
           let own = Settings.shared.profiles.first(where: { $0.name == e.profileName }) {
            return own
        }
        return Settings.shared.activeProfile
    }

    /// Short label for the mode a re-run will use, shown on the button so the user knows.
    private func rerunModeLabel(_ e: HistoryEntry) -> String {
        let p = rerunProfile(e)
        if p.raw, let first = Settings.shared.profiles.first(where: { !$0.raw }) { return first.name }
        return p.name
    }

    /// Re-run the AI restructuring on this entry's raw transcript using the entry's OWN mode
    /// (e.g. if Claude failed or it was never reprompted), and update the saved entry in place.
    /// Failures are surfaced inline via `rerunError` instead of silently stopping the spinner.
    private func rerun(_ e: HistoryEntry) {
        guard !rerunning else { return }
        rerunning = true
        rerunError = nil
        Task {
            do {
                let p = rerunProfile(e)
                // Re-run is about restructuring: if the entry's own mode is raw, borrow the
                // first reprompting mode's prompt so re-run actually does something.
                let sys = p.raw
                    ? Settings.shared.profiles.first(where: { !$0.raw })?.effectiveSystemPrompt ?? ""
                    : p.effectiveSystemPrompt
                let r = Reprompter(model: p.model ?? Settings.shared.claudeModel)
                let out = try await r.reprompt(transcript: e.original, systemPrompt: sys)
                await MainActor.run {
                    history.updateReprompted(e, text: out)
                    rerunning = false
                }
            } catch {
                await MainActor.run {
                    rerunError = "Re-run failed: \(error.localizedDescription)"
                    rerunning = false
                }
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
            Group {
                if body.isEmpty {
                    Text("Nothing here for this entry.").foregroundStyle(.secondary)
                } else {
                    Text(body).textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
