import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileTranscribeView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = TranscriptStore.shared
    @State private var state = "idle"   // idle / working / done / error
    @State private var result = ""
    @State private var error = ""
    @State private var fileName = ""
    @State private var dropTargeted = false

    @State private var selectedID: UUID?      // saved transcript being viewed; nil = import pane
    @State private var filterTag: String?
    @State private var savedFlash = false     // brief "Saved ✓" after an import is filed

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 300)
            Divider().opacity(0.4)
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: selectedID) { _, _ in if selectedID != nil { state = "idle"; result = ""; error = ""; fileName = "" } }
    }

    // MARK: - Left: library of saved transcripts
    private var sidebar: some View {
        let entries = filterTag == nil ? store.entries : store.entries.filter { $0.tags.contains(filterTag!) }
        return VStack(spacing: 0) {
            HStack {
                Text("Transcripts").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { selectedID = nil } label: { Image(systemName: "plus.circle") }
                    .buttonStyle(.borderless).help("Transcribe a new file")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            if !store.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        tagChip(label: "All", on: filterTag == nil) { filterTag = nil }
                        ForEach(store.allTags, id: \.self) { t in
                            tagChip(label: "#\(t)", on: filterTag == t) { filterTag = (filterTag == t ? nil : t) }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 8)
                }
            }

            if entries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "waveform").font(.system(size: 26)).foregroundStyle(.tertiary)
                    Text(filterTag == nil ? "No transcripts yet" : "No transcripts with #\(filterTag!)")
                        .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                    Text(filterTag == nil ? "Files you transcribe are saved here."
                                          : "Pick another tag, or clear the filter.")
                        .font(.caption).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                Spacer()
            } else {
                List(selection: $selectedID) {
                    ForEach(entries) { e in row(e).tag(e.id).listRowSeparator(.hidden) }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func row(_ e: TranscriptEntry) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "waveform").font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.displayName.isEmpty ? snippet(e) : e.displayName).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text(e.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.tertiary)
                if !e.tags.isEmpty {
                    Text(e.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(.caption2).foregroundStyle(.tint).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button(role: .destructive) { remove(e) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func snippet(_ e: TranscriptEntry) -> String {
        for raw in e.text.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if !line.isEmpty { return String(line.prefix(80)) }
        }
        return "Transcript"
    }

    // MARK: - Right: import a file, or view a saved transcript
    @ViewBuilder private var detail: some View {
        if let id = selectedID, let e = store.entries.first(where: { $0.id == id }) {
            TranscriptDetailView(entry: e).id(e.id)
        } else {
            importPane
        }
    }

    private var importPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Transcribe file").font(.system(size: 17, weight: .bold))
                    Text("Drop in an audio or video file and Verba transcribes it with your current engine (\(settings.engine.label)). Imports are saved to your transcripts library.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                HStack {
                    Button { pick() } label: { Label("Choose file…", systemImage: "folder") }
                        .glassButton()
                        .disabled(state == "working")
                    if !fileName.isEmpty { Text(fileName).font(.callout).foregroundStyle(.secondary).lineLimit(1) }
                    Spacer()
                    if state == "working" { ProgressView().controlSize(.small) }
                }

                dropZone

                if state == "error" { Text(error).font(.callout).foregroundStyle(.red) }

                // Explicit loading state: while a file is being transcribed the body
                // shows a centered progress block instead of going blank.
                if state == "working" {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(fileName.isEmpty ? "Transcribing…" : "Transcribing \(fileName)…")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 40)
                }

                if result.isEmpty && state != "working" {
                    EmptyState(icon: "waveform.badge.plus", title: "No file transcribed yet",
                               message: "Pick an audio or video file with “Choose file…” and Verba transcribes it with your current engine. Perfect for meeting recordings, voice memos, podcasts, and interviews.")
                }

                if !result.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transcript").font(.subheadline.weight(.semibold))
                            if savedFlash {
                                Label("Saved to library", systemImage: "checkmark.circle.fill")
                                    .font(.caption).foregroundStyle(.green)
                            }
                            Spacer()
                            CopyButton(text: result, title: "Copy")
                        }
                        Text(result).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14).background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Per-transcript quick-actions / intent / mic — reuse the shared AdaptPanel.
                        AdaptPanel(source: result)
                    }
                }
            }
            .padding(28).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(dropTargeted ? Color.primary : .secondary)
            Text(dropTargeted ? "Release to transcribe" : "Drag & drop an audio or video file here")
                .font(.callout)
                .foregroundStyle(dropTargeted ? Color.primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    dropTargeted ? Color.primary : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: dropTargeted ? 2 : 1, dash: [6, 4])
                )
        )
        .animation(.easeInOut(duration: 0.15), value: dropTargeted)
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            guard state != "working", let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    fileName = url.lastPathComponent
                    transcribe(url)
                }
            }
            return true
        }
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        var types: [UTType] = [.audio, .movie, .mpeg4Movie, .mp3, .wav, .mpeg4Audio]
        // WhatsApp voice notes (.opus) / Ogg often lack a registered UTType — add them explicitly.
        types += ["opus", "ogg", "oga"].compactMap { UTType(filenameExtension: $0) }
        panel.allowedContentTypes = types
        panel.message = "Choose an audio or video file to transcribe"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        fileName = url.lastPathComponent
        transcribe(url)
    }

    private func transcribe(_ url: URL) {
        Gamification.shared.flag(.transcribedFile)
        state = "working"; error = ""; result = ""
        let source = url.lastPathComponent
        let lang = settings.transcriptionLanguage
        let t: Transcriber
        switch settings.engine {
        case .openAI:   t = OpenAITranscriber()
        case .whisper:  t = LocalTranscriber.shared
        case .parakeet: t = ParakeetTranscriber.shared
        }
        Task {
            do {
                // WhatsApp .opus / .ogg and other AVFoundation-unreadable inputs are
                // transcoded to a 16 kHz mono WAV first; readable files pass through.
                let readable = try await AudioInput.readable(url)
                defer { AudioInput.cleanup(readable, original: url) }
                var text = try await t.transcribe(fileURL: readable, language: lang, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                let clean = Output.trimTrailingNewlines(text)
                await MainActor.run {
                    result = clean; state = "done"
                    // SAVE every import into the transcripts library.
                    if !clean.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        store.add(text: clean, sourceName: source)
                        savedFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { savedFlash = false }
                    }
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; state = "error" }
            }
        }
    }

    private func remove(_ e: TranscriptEntry) {
        let wasSelected = (selectedID == e.id)
        store.delete(e)
        if wasSelected { selectedID = nil }
    }

    private func tagChip(label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            Text(label)
                .font(.system(size: 12.5, weight: on ? .semibold : .medium))
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
}

/// View/edit a saved transcript: its text, tags, an optional note, plus AdaptPanel quick-actions.
private struct TranscriptDetailView: View {
    let entry: TranscriptEntry
    @ObservedObject private var store = TranscriptStore.shared
    @State private var note = ""
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var noteSaveTask: Task<Void, Never>?
    @State private var titleText = ""
    @State private var titleSaveTask: Task<Void, Never>?

    /// Current persisted name shown in the field (custom title, else the imported file name).
    private var currentName: String { entry.title ?? entry.sourceName }

    /// Debounce rename persistence, like the note: save 0.5s after the last keystroke.
    private func scheduleTitleSave(_ value: String) {
        titleSaveTask?.cancel()
        titleSaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            store.rename(entry, to: value)
        }
    }

    /// Flush a pending debounced rename immediately (on submit/disappear).
    private func flushTitleSave() {
        titleSaveTask?.cancel()
        titleSaveTask = nil
        if titleText != currentName { store.rename(entry, to: titleText) }
    }

    /// Debounce note persistence: cancel any pending write and schedule a trailing
    /// save 0.5s after the last keystroke, instead of re-encoding the whole library on every char.
    private func scheduleNoteSave(_ value: String) {
        noteSaveTask?.cancel()
        noteSaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            store.update(entry, note: value)
        }
    }

    /// Flush a pending debounced note write immediately (on blur/disappear).
    private func flushNoteSave() {
        guard noteSaveTask != nil else { return }
        noteSaveTask?.cancel()
        noteSaveTask = nil
        if note != entry.note { store.update(entry, note: note) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Editable name — rename an imported transcript after the fact. Persists
                        // debounced (and on submit/blur); a blank name reverts to the file name.
                        TextField("Transcript", text: $titleText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold)).lineLimit(1)
                            .onChange(of: titleText) { _, v in scheduleTitleSave(v) }
                            .onSubmit { flushTitleSave() }
                            .help("Rename this transcript")
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    CopyButton(text: entry.text, title: "Copy")
                    Button(role: .destructive) { store.delete(entry) } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless).foregroundStyle(.secondary).help("Delete transcript")
                }

                Text(entry.text).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                tagEditor

                VStack(alignment: .leading, spacing: 6) {
                    Text("Note").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    TextEditor(text: $note)
                        .font(.body).frame(minHeight: 70)
                        .padding(6).background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: note) { _, v in scheduleNoteSave(v) }
                }

                // Per-transcript quick-actions / intent / mic — reuse the shared AdaptPanel.
                AdaptPanel(source: entry.text)
            }
            .padding(24)
        }
        .onAppear { note = entry.note; tags = entry.tags; titleText = currentName }
        .onDisappear { flushNoteSave(); flushTitleSave() }
    }

    private var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { t in
                        HStack(spacing: 4) {
                            Text("#\(t)").font(.caption)
                            Button { tags.removeAll { $0 == t }; store.update(entry, tags: tags) } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.plain).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "number").foregroundStyle(.secondary)
                TextField("Add tags (press Enter)", text: $tagInput)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        let new = NotesStore.mergeTags(tagInput.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init))
                        tags = NotesStore.mergeTags(tags + new); tagInput = ""
                        store.update(entry, tags: tags)
                    }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
