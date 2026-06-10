import SwiftUI
import AVFoundation

/// Notes tab (#A): record a long voice memo, transcribe it, reorganize into a clean document
/// with a chosen format, render markdown, tag it (Bear-style #hashtags), edit/copy/save.
///
/// Master-detail layout (like Modes / History): the left sidebar scrolls through every saved
/// note; the right pane records a new note or views/edits the selected one.
struct NotesView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = NotesStore.shared
    @ObservedObject private var notesCtl = NotesController.shared
    @ObservedObject private var modes = NoteModesStore.shared

    @State private var recorder = AudioRecorder()
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var recordStart = Date()
    @State private var pausedAccum = 0         // seconds accumulated before the current (possibly paused) leg
    @State private var pauseStart: Date?
    @State private var elapsed = 0
    @State private var recordingURL: URL?
    @State private var levelTimer: Timer?      // fast timer feeding the shared overlay's waveform

    @State private var selectedID: UUID?      // saved note being viewed/edited; nil = composing a new note
    @State private var format = NoteFormat.cleanNote
    @State private var intentText = ""        // Intent mode: the one-off instruction to apply
    @State private var intentApplied = false  // the user confirmed (Enter / Validate) the intent above
    @FocusState private var intentFocused: Bool
    @State private var showModeManager = false  // CRUD sheet for note modes
    @State private var transcript = ""        // raw source (for re-formatting)
    @State private var editorText = ""        // shown / edited / saved document
    @State private var noteTitle = ""         // user-set note title (optional)
    @State private var noteTags: [String] = []
    @State private var tagInput = ""
    @State private var busy = false
    @State private var status = ""
    @State private var recordError = ""     // legible, persistent "couldn't record" banner (cleared on success / dismiss)
    @State private var work: Task<Void, Never>?
    @State private var filterTag: String?
    @State private var appendMode = false   // next recording is appended to the current note
    @State private var autosaveTask: Task<Void, Never>?
    @State private var savedFlash = false   // brief "Saved ✓" after an autosave commit
    @StateObject private var md = MarkdownEditorController()   // drives the formatting toolbar

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider().opacity(0.4)
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(tick) { _ in if isRecording && !isPaused { elapsed = pausedAccum + Int(Date().timeIntervalSince(recordStart)) } }
        .onChange(of: selectedID) { _, id in loadSelection(id) }
        .onChange(of: editorText) { _, _ in scheduleAutosave() }
        .onChange(of: noteTags) { _, _ in scheduleAutosave() }
        .onChange(of: notesCtl.pendingRecord) { _, v in if v { consumePending() } }
        // Mirror the recording state into the shared controller so a global bare-Fn tap knows a
        // note is recording (and must stop it rather than start a stray dictation), and so the
        // shared overlay pill (labelled "Note") can show/hide.
        .onChange(of: isRecording) { _, v in notesCtl.isRecording = v }
        .onChange(of: isPaused) { _, v in notesCtl.paused = v }
        // A global bare-Fn tap (AppDelegate) bumps stopRecord to finish the in-progress note.
        .onChange(of: notesCtl.stopRecord) { _, _ in if isRecording { toggleRecord() } }
        // Control key / overlay pause button (AppDelegate) → pause/resume this note recording.
        .onChange(of: notesCtl.pauseToggleSignal) { _, _ in if isRecording { togglePauseNote() } }
        // Esc / overlay × (AppDelegate) → discard this note recording (no transcription).
        .onChange(of: notesCtl.cancelRecord) { _, _ in if isRecording { discardRecording() } }
        .onAppear { if !modes.modes.contains(where: { $0.id == format.id }) { format = modes.modes.first ?? .cleanNote }; consumePending() }
        .sheet(isPresented: $showModeManager) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text("Note modes").font(.title3.weight(.semibold))
                    Spacer()
                    Button("Done") { showModeManager = false }
                        .dialogPrimary()
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                NoteModesView()
            }
            .frame(width: 760, height: 520)
            .presentationBackground(.thinMaterial)
            .dialogAppear()
        }
        .onDisappear { notesCtl.isRecording = false; levelTimer?.invalidate(); levelTimer = nil; autosaveTask?.cancel(); autosaveCommit(); work?.cancel(); if isRecording { _ = recorder.stop(); recorder.releaseArmed() } }
    }

    // MARK: - Left: scrollable list of all notes
    private var sidebar: some View {
        let entries = filterTag == nil ? store.entries : store.entries.filter { $0.tags.contains(filterTag!) }
        return VStack(spacing: 0) {
            HStack {
                Text("Notes").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { newNote() } label: { Image(systemName: "square.and.pencil") }
                    .buttonStyle(.borderless).help("New note")
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            if !store.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip(label: "All", icon: nil, on: filterTag == nil) { filterTag = nil }
                        ForEach(store.allTags, id: \.self) { t in
                            chip(label: "#\(t)", icon: nil, on: filterTag == t) { filterTag = (filterTag == t ? nil : t) }
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 8)
                }
            }

            if entries.isEmpty {
                Spacer()
                EmptyState(icon: "note.text",
                           title: filterTag == nil ? "No notes yet" : "No notes with #\(filterTag!)",
                           message: filterTag == nil
                               ? "Record a voice memo and Verba turns it into a clean note."
                               : "Pick another tag, or All to see every note.")
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                // Tap-selected cards (Leaderboard grammar) — NOT List(selection:), whose
                // system-blue highlight would paint UNDER our custom card and double-box it.
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(entries) { e in
                            noteRow(e)
                                .onTapGesture { selectedID = e.id }
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func noteRow(_ e: NotesEntry) -> some View {
        let selected = selectedID == e.id
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: iconFor(e.formatName)).font(.system(size: 13))
                .foregroundStyle(.secondary).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet(e)).font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(e.formatName).font(.caption2).foregroundStyle(.secondary)
                    Text("·").font(.caption2).foregroundStyle(.tertiary)
                    Text(e.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.tertiary)
                }
                if !e.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(e.tags.prefix(3), id: \.self) { t in
                            Text("#\(t)")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
                                .lineLimit(1)
                        }
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
            Button(role: .destructive) { remove(e) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    /// The list-row title: the user-set title if any, else the first meaningful line of the note.
    private func snippet(_ e: NotesEntry) -> String {
        let t = e.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return String(t.prefix(80)) }
        for raw in e.formatted.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: CharacterSet(charactersIn: " #*->`"))
            if !line.isEmpty { return String(line.prefix(80)) }
        }
        return e.formatName
    }

    // MARK: - Right: record a new note, or view/edit the selected one
    @ViewBuilder private var detail: some View {
        if selectedID == nil && editorText.isEmpty && !busy {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    recorderCard
                }
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 28).padding(.vertical, 32)
            }
        } else {
            // Full-bleed editor: header + toolbar pinned, the note fills all remaining space.
            VStack(alignment: .leading, spacing: 10) {
                noteEditor
                tagEditor
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New note").font(.system(size: 17, weight: .bold))
            Text("Speak freely, even for an hour. Verba transcribes it and turns it into a clean, formatted document.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Small "Note" context badge, shown while a note is recording so the user always knows this
    /// capture is a Note (mirrors the overlay pill's context badge used for dictation / to-do).
    @ViewBuilder private var noteContextBadge: some View {
        if isRecording {
            HStack(spacing: 5) {
                Image(systemName: CaptureContext.note.symbol).font(.system(size: 9, weight: .semibold))
                Text(CaptureContext.note.label).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
            .transition(.opacity)
        }
    }

    /// In-app pause/resume + play-again control, visible while a note is recording (mirrors the
    /// Control-key / overlay pause and lets the user resume from inside the app).
    private var pauseControl: some View {
        Button { togglePauseNote() } label: {
            HStack(spacing: 7) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill").font(.system(size: 12, weight: .semibold))
                Text(isPaused ? "Resume" : "Pause").font(.callout.weight(.medium))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(isPaused ? "Resume recording (Control)" : "Pause recording (Control)")
    }

    private var recorderCard: some View {
        VStack(spacing: 22) {
            noteContextBadge
            RecordButton(isRecording: isRecording, disabled: busy, action: toggleRecord)
            VStack(spacing: 4) {
                if isRecording {
                    Text(timeString(elapsed)).font(.system(size: 22, weight: .semibold, design: .monospaced)).monospacedDigit()
                    Text(isPaused ? "Paused · tap the mic to stop" : "Tap to stop · Control pauses").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Tap to record").font(.callout.weight(.medium))
                    Text("Pick a mode below").font(.caption).foregroundStyle(.secondary)
                }
            }
            if isRecording { pauseControl }
            if !recordError.isEmpty { recordErrorBanner }
            formatChips
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32).padding(.horizontal, 24)
        .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// A legible, persistent error when a note recording can't start (the old gray sub-flash was
    /// unreadable). Red, large enough to read, with a Retry and a Dismiss; it does NOT auto-loop.
    private var recordErrorBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 14, weight: .semibold))
                Text(recordError).font(.callout.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(Color.red)
            HStack(spacing: 10) {
                Button("Retry") { recordError = ""; toggleRecord() }.glassProminentButton().tint(.red)
                Button("Dismiss") { recordError = "" }.glassButton()
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.red.opacity(0.35), lineWidth: 1))
        )
        .transition(.opacity)
    }

    private var formatChips: some View {
        VStack(spacing: 10) {
            FlowLayout(spacing: 8, alignment: .center) {
                ForEach(modes.modes) { f in
                    chip(label: f.name, icon: f.icon, on: f.id == format.id) {
                        format = f; if !transcript.isEmpty { applyFormat() }
                    }
                }
            }
            if format.intent { intentField }
            Button { showModeManager = true } label: {
                Label("Manage modes", systemImage: "slider.horizontal.3").font(.caption)
            }
            .buttonStyle(.borderless).foregroundStyle(.secondary)
        }
    }

    /// Free-form instruction for the Intent note mode: a one-off directive shaping THIS note.
    /// Multi-line / auto-expanding so a long intent stays fully visible; Enter (or the Validate
    /// button) confirms it, flipping an "applied" state so the user knows the instruction registered.
    private var intentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "wand.and.rays").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 2)
                Divider().frame(height: 16)
                // axis:.vertical grows the field to fit a long instruction (1…6 visible lines).
                TextField("How should this note be shaped? (e.g. \u{201C}as a bug report\u{201D})",
                          text: $intentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($intentFocused)
                    .onChange(of: intentText) { _, _ in intentApplied = false }   // editing un-confirms
                    .onSubmit { validateIntent() }                                // Enter confirms
                Button { validateIntent() } label: {
                    Image(systemName: intentApplied ? "checkmark.circle.fill" : "return")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(intentApplied ? Color.green : Color.secondary)
                }
                .buttonStyle(.borderless)
                .disabled(intentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help(intentApplied ? "Intent applied" : "Validate this intent (Enter)")
            }
            if intentApplied, !intentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label("Intent applied — this note will follow it", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .frame(maxWidth: 460)
    }

    /// Confirm the typed intent: flip the "applied" state (visible feedback) and, if a transcript is
    /// already present, immediately re-format the note so it picks up the new instruction.
    private func validateIntent() {
        let trimmed = intentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { intentApplied = false; return }
        withAnimation(.easeInOut(duration: 0.18)) { intentApplied = true }
        intentFocused = false
        if !transcript.isEmpty { applyFormat() }
    }

    private var processingRow: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text(status.isEmpty ? "Working…" : status).font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: format menu + actions
            HStack(spacing: 10) {
                Menu {
                    ForEach(modes.modes) { f in
                        Button { format = f; if !transcript.isEmpty { applyFormat() } } label: {
                            Label(f.name, systemImage: f.icon)
                        }
                    }
                    Divider()
                    Button { showModeManager = true } label: { Label("Manage modes…", systemImage: "slider.horizontal.3") }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: format.icon).font(.system(size: 11, weight: .semibold))
                        Text(format.name).font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 5.5)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
                    .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .help("Change format (re-organizes from your words)")

                Spacer(minLength: 8)

                autosaveBadge
                Button { applyFormat() } label: { Image(systemName: "wand.and.stars") }
                    .buttonStyle(.borderless).help("Re-apply format").disabled(busy || transcript.isEmpty)
                Button { appendMode = true; toggleRecord() } label: { Image(systemName: isRecording ? "stop.circle.fill" : "mic.badge.plus") }
                    .buttonStyle(.borderless).help("Record more and add it to this note").disabled(busy && !isRecording)
                CopyButton(text: editorText)
                Button(role: .destructive) { if let id = selectedID, let e = store.entries.first(where: { $0.id == id }) { remove(e) } else { newNote() } } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help(selectedID == nil ? "Discard" : "Delete note")
            }
            formatToolbar
            if format.intent { intentField }
            if busy { processingRow }
            if !recordError.isEmpty { recordErrorBanner }
            if isRecording {
                HStack(spacing: 10) {
                    Circle().fill(isPaused ? .orange : .red).frame(width: 8, height: 8)
                    Text(isPaused ? "Paused… \(timeString(elapsed))" : "Recording more… \(timeString(elapsed)) · tap the mic to stop")
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    Button { togglePauseNote() } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill").font(.system(size: 11))
                    }.buttonStyle(.borderless).help(isPaused ? "Resume (Control)" : "Pause (Control)")
                }
            }
            // Title field, then the content below.
            TextField("Title", text: $noteTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 4).padding(.top, 4).padding(.bottom, 2)
                .onChange(of: noteTitle) { _, _ in scheduleAutosave() }
            // Single always-editable Markdown editor (Bear-style live styling), fills all space.
            MarkdownEditor(text: $editorText, controller: md)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(card(14))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Bear-style formatting toolbar — wraps the selection or toggles a line prefix.
    private var formatToolbar: some View {
        HStack(spacing: 1) {
            fmtBtn("bold", "Bold (**)") { md.wrap("**") }
            fmtBtn("italic", "Italic (*)") { md.wrap("*") }
            fmtBtn("strikethrough", "Strikethrough (~~)") { md.wrap("~~") }
            fmtBtn("chevron.left.forwardslash.chevron.right", "Inline code (`)") { md.wrap("`") }
            Divider().frame(height: 16).padding(.horizontal, 4)
            Menu {
                Button("Heading 1") { md.toggleLinePrefix("# ") }
                Button("Heading 2") { md.toggleLinePrefix("## ") }
                Button("Heading 3") { md.toggleLinePrefix("### ") }
            } label: { Image(systemName: "textformat.size") }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().frame(width: 30).help("Heading")
            fmtBtn("list.bullet", "Bullet list") { md.toggleLinePrefix("- ") }
            fmtBtn("list.number", "Numbered list") { md.toggleLinePrefix("1. ") }
            fmtBtn("checklist", "Checklist") { md.toggleLinePrefix("- [ ] ") }
            Spacer()
        }
        .disabled(busy)
    }

    private func fmtBtn(_ icon: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12.5)).frame(width: 28, height: 24).contentShape(Rectangle())
        }
        .buttonStyle(.borderless).help(help)
    }

    /// Auto-save status. Reflects ONLY the actual save (disk + cloud), which is instant — it is
    /// NOT tied to `busy` (transcription/formatting), so the LLM wait is never mislabeled "Saving".
    @ViewBuilder private var autosaveBadge: some View {
        if autosaveTask != nil {
            HStack(spacing: 5) { ProgressView().controlSize(.small); Text("Saving…").font(.caption) }
                .foregroundStyle(.secondary)
        } else if savedFlash {
            Label("Saved", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green)
        } else {
            Label("Auto-saved", systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !noteTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(noteTags, id: \.self) { t in
                        HStack(spacing: 4) {
                            Text("#\(t)").font(.caption)
                            Button { noteTags.removeAll { $0 == t } } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.plain).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
                        .overlay(Capsule(style: .continuous).strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
                    }
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "number").font(.system(size: 12)).foregroundStyle(.secondary)
                Divider().frame(height: 12)
                TextField("Add tags (press Enter)", text: $tagInput)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        let new = NotesStore.mergeTags(tagInput.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init))
                        noteTags = NotesStore.mergeTags(noteTags + new); tagInput = ""
                    }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }

    // MARK: shared bits
    private func card(_ r: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color.primary.opacity(0.035))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(Color.primary.opacity(0.07), lineWidth: 1))
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
                    .fill(on ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(on ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ name: String) -> String { modes.modes.first { $0.name == name }?.icon ?? "doc.text" }

    // MARK: selection / lifecycle
    private func newNote() {
        work?.cancel(); busy = false; status = ""
        if isRecording { stopRecorderHard() }
        selectedID = nil
        transcript = ""; editorText = ""; noteTitle = ""; noteTags = []; tagInput = ""; intentText = ""; intentApplied = false
        recordingURL = nil; appendMode = false
    }

    /// Stop the recorder and clear all recording-related UI state + the overlay-feeding timer.
    private func stopRecorderHard() {
        levelTimer?.invalidate(); levelTimer = nil
        isRecording = false; isPaused = false; notesCtl.level = 0
        _ = recorder.stop(); recorder.releaseArmed()
    }

    private func loadSelection(_ id: UUID?) {
        guard let id, let e = store.entries.first(where: { $0.id == id }) else { return }
        work?.cancel(); busy = false; status = ""
        if isRecording { stopRecorderHard() }
        transcript = e.original
        editorText = e.formatted
        noteTitle = e.title
        noteTags = e.tags
        format = modes.mode(named: e.formatName)
        recordingURL = store.audioURL(for: e)
        appendMode = false
    }

    private func remove(_ e: NotesEntry) {
        let wasSelected = (selectedID == e.id)
        store.delete(e)
        if wasSelected { newNote() }
    }

    private func consumePending() {
        guard notesCtl.pendingRecord else { return }
        notesCtl.pendingRecord = false
        newNote()
        // Start on the next runloop turn: Fn+Z's AppDelegate path released the shared (pre-armed)
        // recorder's mic synchronously a beat earlier; deferring lets the audio input actually free
        // before this window's recorder grabs it, so the first start() succeeds cleanly.
        DispatchQueue.main.async { if !isRecording { toggleRecord() } }
    }

    // MARK: auto-save
    /// Debounced auto-save: every edit (text or tags) schedules a commit ~0.7s later.
    private func scheduleAutosave() {
        autosaveTask?.cancel()
        let snapshot = editorText
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                autosaveTask = nil
                if editorText == snapshot { autosaveCommit() }   // settled → commit
            }
        }
    }

    /// Create the note (first commit) or update it. Idempotent; safe to call on disappear.
    private func autosaveCommit() {
        let doc = editorText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !doc.isEmpty, !busy else { return }
        let titleTrim = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = selectedID, let e = store.entries.first(where: { $0.id == id }) {
            let mergedTags = NotesStore.mergeTags(noteTags + NotesStore.hashtags(in: doc))
            if e.formatted == doc, e.formatName == format.name, e.tags == mergedTags, e.title == titleTrim { return }   // unchanged → skip
            store.update(e, formatted: doc, formatName: format.name, tags: noteTags, title: titleTrim)
        } else {
            let e = store.add(original: transcript, formatted: doc, formatName: format.name, audioURL: recordingURL, tags: noteTags, title: titleTrim)
            Stats.shared.record(words: wordCount(doc), seconds: Double(elapsed))
            selectedID = e.id          // keep editing the just-saved note
            noteTags = e.tags          // reflect auto-extracted #hashtags
        }
        savedFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { savedFlash = false }
    }

    // MARK: actions
    private func toggleRecord() {
        if isRecording {
            if isPaused { _ = recorder.resume() }   // a paused recorder won't flush a final file
            levelTimer?.invalidate(); levelTimer = nil
            isRecording = false; isPaused = false; notesCtl.level = 0
            recordingURL = recorder.stop()
            // stop() re-arms this Notes recorder (prewarm), which keeps the prepared input
            // holding the mic. Nothing else releases it, so a following Fn dictation / to-do
            // capture would cold-start against a still-held mic and fail ("Couldn't start
            // recording") with no retry. Free it now — symmetric to AppDelegate's releaseArmed().
            recorder.releaseArmed()
            if let url = recordingURL { transcribe(url) }
            else { recordError = "Couldn't capture audio — try recording again."; appendMode = false }
        } else {
            recorder.requestPermission { ok in
                guard ok else { recordError = "Microphone access denied. Allow Verba under System Settings ▸ Privacy & Security ▸ Microphone."; return }
                // Single deferred retry (NOT a loop): if the shared dictation recorder only just
                // released the mic, the input can take a beat to free. Try once now; if it fails,
                // retry once after a short delay before surfacing a readable error.
                if recorder.start() {
                    beginNoteRecording()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if recorder.start() {
                            beginNoteRecording()
                        } else {
                            recordError = "Couldn't start recording. The microphone may be in use — wait a moment, then tap Retry."
                        }
                    }
                }
            }
        }
    }

    /// Latch the UI into the recording state after the recorder successfully started.
    private func beginNoteRecording() {
        if !appendMode { transcript = ""; editorText = ""; noteTags = [] }   // append keeps the current note
        status = ""; recordError = ""; recordStart = Date(); elapsed = 0
        pausedAccum = 0; pauseStart = nil; isPaused = false; notesCtl.level = 0
        isRecording = true
        // Feed the shared overlay pill's waveform (AppDelegate reads notesCtl.level) AND drive the
        // elapsed clock from this same proven timer — the body-level Timer.publish tick can detach
        // after the two-pane refactor and leave the displayed time stuck at 0:00.
        levelTimer?.invalidate()
        let t = Timer(timeInterval: 0.04, repeats: true) { _ in
            notesCtl.level = isPaused ? 0 : recorder.level()
            if isRecording && !isPaused { elapsed = pausedAccum + Int(Date().timeIntervalSince(recordStart)) }
        }
        RunLoop.main.add(t, forMode: .common)
        levelTimer = t
    }

    /// Pause/resume the in-progress note recording (Control key, overlay pause, or the in-app
    /// button all route here). Keeps the elapsed clock honest across pauses.
    private func togglePauseNote() {
        guard isRecording else { return }
        if isPaused {
            if recorder.resume() {
                isPaused = false
                recordStart = Date()   // start a fresh leg; pausedAccum holds the earlier time
            }
        } else {
            recorder.pause()
            isPaused = true
            pausedAccum += Int(Date().timeIntervalSince(recordStart))
            elapsed = pausedAccum
        }
    }

    /// Discard the in-progress note recording (overlay × / Esc): stop and throw the audio away.
    private func discardRecording() {
        guard isRecording else { return }
        levelTimer?.invalidate(); levelTimer = nil
        isRecording = false; isPaused = false; notesCtl.level = 0
        _ = recorder.stop()
        recorder.releaseArmed()
        recordingURL = nil; appendMode = false
    }

    private func transcribe(_ url: URL) {
        busy = true; status = "Transcribing…"
        work = Task {
            do {
                let s = Settings.shared
                let transcriber: Transcriber
                switch s.engine {
                case .openAI:   transcriber = OpenAITranscriber()
                case .whisper:  transcriber = LocalTranscriber.shared
                case .parakeet: transcriber = ParakeetTranscriber.shared
                }
                var text = try await transcriber.transcribe(fileURL: url,
                    language: s.language.isEmpty ? nil : s.language, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                if s.voiceCommands { text = VoiceCommands.apply(text) }
                if Task.isCancelled { return }
                // Empty/garbled audio → a readable banner, not a stuck "Transcribing…" spinner
                // (applyFormat() bails on empty transcript without ever clearing busy).
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    await MainActor.run {
                        busy = false; status = ""; appendMode = false
                        recordError = "Didn't catch anything — try recording again."
                    }
                    return
                }
                await MainActor.run {
                    if appendMode { transcript = (transcript + "\n\n" + text).trimmingCharacters(in: .whitespacesAndNewlines); appendMode = false }
                    else { transcript = text }
                    editorText = transcript
                }
                applyFormat()
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { busy = false; status = "Transcription failed: \(error.localizedDescription)" }
            }
        }
    }

    private func applyFormat() {
        guard !transcript.isEmpty else { return }
        busy = true; status = "Organizing into \(format.name)…"
        // Snapshot the intent on the main actor so the system prompt always reflects what the user
        // typed, and flag it applied so the note demonstrably follows the instruction (Point 4).
        let intentSnapshot = intentText
        if !intentSnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { intentApplied = true }
        let fmt = format
        work = Task {
            do {
                var sys = fmt.effectiveSystemPrompt(instruction: intentSnapshot)
                let style = Settings.shared.activeStyle.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                if !style.isEmpty { sys += "\n\nSTYLE: \(style)" }
                let r = Reprompter(model: fmt.model ?? Settings.shared.claudeModel)
                let out = try await r.reprompt(transcript: transcript, systemPrompt: sys, fast: true)
                if Task.isCancelled { return }
                await MainActor.run {
                    editorText = out; busy = false; status = ""
                    autosaveTask?.cancel(); autosaveTask = nil
                    autosaveCommit()   // persist the finished note immediately (no debounce wait)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { busy = false; status = "Couldn't organize: \(error.localizedDescription)" }
            }
        }
    }

    private func timeString(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}

/// Big circular record control with a soft pulsing ring while recording.
private struct RecordButton: View {
    let isRecording: Bool
    let disabled: Bool
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.12) : Color.primary.opacity(0.06))
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(isRecording ? Color.red.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: 2))
                    .scaleEffect(isRecording && pulse ? 1.08 : 1)
                    .animation(isRecording ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: pulse)
                if isRecording {
                    RoundedRectangle(cornerRadius: 6).fill(Color.red).frame(width: 30, height: 30)
                } else {
                    Image(systemName: "mic.fill").font(.system(size: 34, weight: .medium)).foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.5 : 1)
        .onAppear { pulse = true }
    }
}
