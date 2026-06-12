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
    @FocusState private var intentFocused: Bool
    @FocusState private var titleFocused: Bool
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
    @State private var expandedTags: Set<String> = []   // Bear-style tag tree: which parent tags are open
    // Per-note password lock
    @State private var unlocked: Set<UUID> = []         // notes decrypted this session (cleared on quit)
    @State private var lockSheetFor: NotesEntry?        // note being assigned a NEW password
    @State private var newPassword = ""
    @State private var newPasswordConfirm = ""
    @State private var gatePassword = ""                // password typed at the unlock gate
    @State private var gateError = false
    @State private var appendMode = false   // next recording is appended to the current note
    @State private var hasComposed = false  // true once a composition has produced content (title/tags/transcript/text); gates the recorder→editor flip so a transient empty edit doesn't yank the editor away
    @State private var lastRecordedSeconds = 0   // duration snapshotted when the recording stops, used for Stats (live `elapsed` is reset before formatting finishes)
    @State private var autosaveTask: Task<Void, Never>?
    @State private var savedFlash = false   // brief "Saved ✓" after an autosave commit
    @State private var addedToTasksFlash = false   // brief confirmation after "Add to Tasks"
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
        .onChange(of: editorText) { _, _ in markComposedIfNeeded(); scheduleAutosave() }
        .onChange(of: noteTags) { _, _ in markComposedIfNeeded(); scheduleAutosave() }
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
                    Text(L("Note modes")).font(.title3.weight(.semibold))
                    Spacer()
                    Button(L("Done")) { showModeManager = false }
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
        .sheet(item: $lockSheetFor) { e in
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill").font(.system(size: 14, weight: .semibold)).foregroundStyle(.orange)
                        .frame(width: 32, height: 32).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text(L("Protect this note")).font(.title3.weight(.semibold))
                    Spacer()
                }
                Text(L("Choose a password for this note. Each note can have its own. Without it, the note can't be read — there's no recovery, so keep it safe."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                SecureField(L("Password"), text: $newPassword).textFieldStyle(.roundedBorder)
                SecureField(L("Confirm password"), text: $newPasswordConfirm).textFieldStyle(.roundedBorder)
                if !newPasswordConfirm.isEmpty && newPassword != newPasswordConfirm {
                    Text(L("Passwords don't match.")).font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Button(L("Cancel")) { lockSheetFor = nil; newPassword = ""; newPasswordConfirm = "" }.buttonStyle(.plain)
                    Spacer()
                    Button(L("Lock note")) { commitLock() }
                        .dialogPrimary().keyboardShortcut(.defaultAction)
                        .disabled(newPassword.isEmpty || newPassword != newPasswordConfirm)
                }
            }
            .padding(22).frame(width: 420)
            .presentationBackground(.thinMaterial).dialogAppear()
        }
        .onDisappear { notesCtl.isRecording = false; levelTimer?.invalidate(); levelTimer = nil; autosaveTask?.cancel(); autosaveCommit(); work?.cancel(); if isRecording { _ = recorder.stop(); recorder.releaseArmed() } }
    }

    /// Notes matching the current tag filter. A parent tag (e.g. "work") matches its own notes AND
    /// any nested child ("work/projects"), like Bear. The "__untagged__" sentinel shows notes with
    /// no tags at all.
    private var filteredEntries: [NotesEntry] {
        guard let f = filterTag else { return store.entries }
        if f == "__untagged__" { return store.entries.filter { $0.tags.isEmpty } }
        return store.entries.filter { e in e.tags.contains { $0 == f || $0.hasPrefix(f + "/") } }
    }

    // MARK: - Left: Bear-style tag tree + scrollable list of notes
    private var sidebar: some View {
        let entries = filteredEntries
        return VStack(spacing: 0) {
            HStack {
                Text(L("Notes")).font(.system(size: 17, weight: .bold))
                Spacer()
                Button { newNote() } label: { Image(systemName: "square.and.pencil") }
                    .buttonStyle(.borderless).help(L("New note"))
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            // Bear-style filing: All Notes / Untagged, then a nested, collapsible tag tree with counts.
            tagSidebar
                .padding(.bottom, 4)
            Divider().opacity(0.35).padding(.horizontal, 10).padding(.bottom, 2)

            if entries.isEmpty {
                Spacer()
                EmptyState(icon: "note.text",
                           title: filterTag == nil ? L("No notes yet")
                               : filterTag == "__untagged__" ? L("No untagged notes")
                               : "\(L("No notes with")) #\(filterTag!)",
                           message: filterTag == nil
                               ? L("Record a voice memo and Verba turns it into a clean note.")
                               : L("Pick another tag, or All Notes to see every note."))
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

    // MARK: - Password lock

    /// Shown in the detail pane when a locked note is selected — asks for that note's password.
    private func lockGate(_ e: NotesEntry) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.system(size: 34)).foregroundStyle(.secondary)
            Text(e.title.isEmpty ? L("Locked note") : e.title).font(.title3.weight(.semibold))
            Text(L("This note is protected. Enter its password to read it.")).font(.callout).foregroundStyle(.secondary)
            SecureField(L("Password"), text: $gatePassword)
                .textFieldStyle(.roundedBorder).frame(width: 240)
                .onSubmit { tryUnlock(e) }
            if gateError {
                Text(L("Wrong password. Try again.")).font(.caption).foregroundStyle(.red)
            }
            Button(L("Unlock")) { tryUnlock(e) }.buttonStyle(.borderedProminent).disabled(gatePassword.isEmpty)
            Button(L("Remove password…"), role: .destructive) { tryRemovePassword(e) }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func tryUnlock(_ e: NotesEntry) {
        guard let dec = store.decrypt(e, password: gatePassword) else { gateError = true; return }
        gateError = false; gatePassword = ""
        unlocked.insert(e.id)
        // Load the decrypted content into the editor (transient — re-locked on disk, plaintext only in memory).
        transcript = dec.original; editorText = dec.formatted; noteTitle = e.title; noteTags = e.tags
        format = modes.mode(named: e.formatName); recordingURL = nil; appendMode = false; hasComposed = true
    }

    private func tryRemovePassword(_ e: NotesEntry) {
        // Reuse the gate field as the confirmation password for removal.
        guard !gatePassword.isEmpty, store.removePassword(e, password: gatePassword) else { gateError = true; return }
        gateError = false; gatePassword = ""; unlocked.insert(e.id)
        loadSelection(e.id)
    }

    private func commitLock() {
        guard let e = lockSheetFor, !newPassword.isEmpty, newPassword == newPasswordConfirm else { return }
        autosaveCommit()   // make sure the latest edit is saved before we encrypt it
        if store.lock(e, password: newPassword) {
            unlocked.remove(e.id)
            if selectedID == e.id { selectedID = nil; newNote() }   // drop the now-encrypted text from the editor
        }
        lockSheetFor = nil; newPassword = ""; newPasswordConfirm = ""
    }

    // MARK: - Bear-style tag tree

    /// One node in the nested tag tree. `id` is the full path ("work/projects"); `count` is the
    /// number of notes filed under this tag OR any of its descendants.
    private struct TagNode: Identifiable {
        let id: String
        let name: String
        var children: [TagNode]
        let count: Int
    }

    /// Build the nested tree from every note's tags, splitting each tag on "/". Counts are unique
    /// notes per path (a note tagged "work/projects" counts toward both "work" and "work/projects").
    private var tagTree: [TagNode] {
        var notesAt: [String: Set<UUID>] = [:]
        var childPaths: [String: Set<String>] = [:]
        var roots: Set<String> = []
        for e in store.entries {
            for tag in e.tags {
                let parts = tag.split(separator: "/").map(String.init)
                var path = ""
                for (i, part) in parts.enumerated() {
                    let parent = path
                    path = path.isEmpty ? part : path + "/" + part
                    notesAt[path, default: []].insert(e.id)
                    if i == 0 { roots.insert(path) } else { childPaths[parent, default: []].insert(path) }
                }
            }
        }
        func build(_ path: String) -> TagNode {
            let name = path.split(separator: "/").last.map(String.init) ?? path
            let kids = (childPaths[path] ?? []).sorted().map(build)
            return TagNode(id: path, name: name, children: kids, count: notesAt[path]?.count ?? 0)
        }
        return roots.sorted().map(build)
    }

    private var untaggedCount: Int { store.entries.filter { $0.tags.isEmpty }.count }

    private var tagSidebar: some View {
        VStack(spacing: 1) {
            tagFolderRow(icon: "tray.full", label: L("All Notes"), count: store.entries.count,
                         on: filterTag == nil, depth: 0, hasChildren: false) { filterTag = nil }
            if untaggedCount > 0 {
                tagFolderRow(icon: "tag.slash", label: L("Untagged"), count: untaggedCount,
                             on: filterTag == "__untagged__", depth: 0, hasChildren: false) {
                    filterTag = (filterTag == "__untagged__" ? nil : "__untagged__")
                }
            }
            if !tagTree.isEmpty {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(visibleTagRows, id: \.node.id) { item in
                            tagFolderRow(icon: "number", label: item.node.name, count: item.node.count,
                                         on: filterTag == item.node.id, depth: item.depth,
                                         hasChildren: !item.node.children.isEmpty,
                                         expanded: expandedTags.contains(item.node.id),
                                         onToggle: { toggleTag(item.node.id) }) {
                                filterTag = (filterTag == item.node.id ? nil : item.node.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(.horizontal, 8)
    }

    /// The tag tree flattened to the currently-visible rows (children shown only under expanded
    /// parents) — avoids a self-referential recursive ViewBuilder.
    private var visibleTagRows: [(node: TagNode, depth: Int)] {
        var out: [(TagNode, Int)] = []
        func walk(_ nodes: [TagNode], _ depth: Int) {
            for n in nodes {
                out.append((n, depth))
                if expandedTags.contains(n.id) { walk(n.children, depth + 1) }
            }
        }
        walk(tagTree, 0)
        return out
    }

    private func toggleTag(_ id: String) {
        if expandedTags.contains(id) { expandedTags.remove(id) } else { expandedTags.insert(id) }
    }

    private func tagFolderRow(icon: String, label: String, count: Int, on: Bool, depth: Int,
                              hasChildren: Bool, expanded: Bool = false,
                              onToggle: (() -> Void)? = nil, select: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            if hasChildren {
                Button { onToggle?() } label: {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                        .frame(width: 12, height: 12)
                }.buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 12, height: 12)
            }
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(on ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)).frame(width: 15)
            Text(label).font(.system(size: 12.5, weight: on ? .semibold : .regular)).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(count)").font(.system(size: 10)).foregroundStyle(.tertiary).monospacedDigit()
        }
        .padding(.vertical, 4).padding(.trailing, 8)
        .padding(.leading, CGFloat(6 + depth * 14))
        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(on ? Color.primary.opacity(0.08) : .clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }

    private func noteRow(_ e: NotesEntry) -> some View {
        let selected = selectedID == e.id
        let isLocked = e.locked && !unlocked.contains(e.id)
        return HStack(alignment: .top, spacing: 9) {
            Image(systemName: isLocked ? "lock.fill" : iconFor(e.formatName)).font(.system(size: 13))
                .foregroundStyle(isLocked ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary)).frame(width: 16).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(isLocked ? (e.title.isEmpty ? L("Locked note") : e.title) : snippet(e))
                    .font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(isLocked ? L("Protected") : e.formatName).font(.caption2).foregroundStyle(.secondary)
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
        .glassCard(selected: selected, cornerRadius: 12)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            if e.locked {
                Button { selectedID = e.id } label: { Label(L("Unlock to read"), systemImage: "lock.open") }
            } else {
                Button { lockSheetFor = e } label: { Label(L("Lock with password…"), systemImage: "lock") }
            }
            Button(role: .destructive) { remove(e) } label: { Label(L("Delete"), systemImage: "trash") }
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
    /// The selected note IF it's locked and not yet unlocked this session — gate it.
    private var gatedNote: NotesEntry? {
        guard let id = selectedID, let e = store.entries.first(where: { $0.id == id }),
              e.locked, !unlocked.contains(id) else { return nil }
        return e
    }

    @ViewBuilder private var detail: some View {
        if let e = gatedNote {
            lockGate(e)
        } else if selectedID == nil && !hasComposed && !busy {
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
            Text(L("New note")).font(.system(size: 17, weight: .bold))
            Text(L("Speak freely, even for an hour — this is for long-form documents. Verba transcribes it and turns it into a clean, formatted note."))
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Label(L("Just capturing quick to-dos? Use the Tasks tab — short spoken commands become tasks."),
                  systemImage: "checklist")
                .font(.caption).foregroundStyle(.tertiary).fixedSize(horizontal: false, vertical: true)
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
            .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
            .transition(.opacity)
        }
    }

    /// In-app pause/resume + play-again control, visible while a note is recording (mirrors the
    /// Control-key / overlay pause and lets the user resume from inside the app).
    private var pauseControl: some View {
        Button { togglePauseNote() } label: {
            HStack(spacing: 7) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill").font(.system(size: 12, weight: .semibold))
                Text(isPaused ? L("Resume") : L("Pause")).font(.callout.weight(.medium))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(isPaused ? L("Resume recording (Control)") : L("Pause recording (Control)"))
    }

    private var recorderCard: some View {
        VStack(spacing: 22) {
            noteContextBadge
            RecordButton(isRecording: isRecording, disabled: busy, action: toggleRecord)
            VStack(spacing: 4) {
                if isRecording {
                    Text(timeString(elapsed)).font(.system(size: 22, weight: .semibold, design: .monospaced)).monospacedDigit()
                    Text(isPaused ? L("Paused · tap the mic to stop") : L("Tap to stop · Control pauses")).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(L("Tap to record")).font(.callout.weight(.medium))
                    Text(L("Pick a mode below")).font(.caption).foregroundStyle(.secondary)
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
                Button(L("Retry")) { recordError = ""; toggleRecord() }.glassProminentButton().tint(.red)
                Button(L("Dismiss")) { recordError = "" }.glassButton()
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
                Label(L("Manage modes"), systemImage: "slider.horizontal.3").font(.caption)
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
                TextField(L("How should this note be shaped? (e.g. \u{201C}as a bug report\u{201D})"),
                          text: $intentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($intentFocused)
                    .onSubmit { applyIntentNow() }                                // Enter re-formats now
                // No confirm/applied ceremony: applyFormat() always reads the CURRENT intent text,
                // so the live text IS what gets sent. This button just re-formats the existing
                // transcript with the latest instruction right now.
                Button { applyIntentNow() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .disabled(busy || transcript.isEmpty || intentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help(L("Re-format this note with the current instruction"))
            }
            if !intentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label(transcript.isEmpty ? L("This instruction will shape your note") : L("This note follows your instruction"),
                      systemImage: "checkmark.circle")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .frame(maxWidth: 460)
    }

    /// Re-format the existing transcript with the CURRENT intent text. No "applied" flag to keep in
    /// sync — applyFormat() snapshots the live intentText, so what you see is what gets sent.
    private func applyIntentNow() {
        let trimmed = intentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        intentFocused = false
        if !transcript.isEmpty { applyFormat() }
    }

    /// Checklist lines (`- [ ]` / `- [x]`) parsed out of the current note text, in order. Empty
    /// when the note isn't a checklist, which hides the "Add to Tasks" affordance.
    private var checklistItems: [(title: String, done: Bool)] {
        var out: [(String, Bool)] = []
        for raw in editorText.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            // Match "- [ ] task", "* [x] task", "- [X] task" (Markdown task-list syntax).
            guard line.count > 5 else { continue }
            let lower = line.lowercased()
            guard lower.hasPrefix("- [") || lower.hasPrefix("* [") else { continue }
            let afterBullet = line.dropFirst(2).trimmingCharacters(in: .whitespaces)   // "[ ] task"
            guard afterBullet.hasPrefix("["), afterBullet.count >= 3 else { continue }
            let mark = afterBullet[afterBullet.index(afterBullet.startIndex, offsetBy: 1)]
            guard afterBullet.dropFirst(2).first == "]" else { continue }
            let title = afterBullet.drop(while: { $0 != "]" }).dropFirst().trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            out.append((title, mark == "x" || mark == "X"))
        }
        return out
    }

    /// Turn the note's checklist into a real Tasks project so the markdown isn't a dead end.
    /// Each `- [ ]` line becomes a task (its checked state carried over), filed under a project
    /// named after the note's title (or its format).
    private func sendChecklistToTasks() {
        let items = checklistItems
        guard !items.isEmpty else { return }
        let name: String = {
            let t = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
            return format.name == "To-do list" ? "To-do list" : "\(format.name) tasks"
        }()
        let pid = TodoStore.shared.addProject(name)
        TodoStore.shared.appendTasks(pid, items.map { (title, _) in (title, [String](), nil) })
        // Carry over already-checked items so a partially-done list lands consistent.
        if let pi = TodoStore.shared.projects.firstIndex(where: { $0.id == pid }) {
            for (idx, item) in items.enumerated() where item.done && idx < TodoStore.shared.projects[pi].tasks.count {
                TodoStore.shared.projects[pi].tasks[idx].done = true
            }
        }
        withAnimation(.easeInOut(duration: 0.18)) { addedToTasksFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) { addedToTasksFlash = false }
        }
    }

    private var processingRow: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text(status.isEmpty ? L("Working…") : status).font(.callout).foregroundStyle(.secondary)
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
                    Button { showModeManager = true } label: { Label(L("Manage modes…"), systemImage: "slider.horizontal.3") }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: format.icon).font(.system(size: 11, weight: .semibold))
                        Text(format.name).font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 11).padding(.vertical, 5.5)
                    .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
                    .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .help(L("Change format (re-organizes from your words)"))

                Spacer(minLength: 8)

                autosaveBadge
                // Always-visible way back to "record a new note" — the recorder card only shows for an
                // empty, unsaved composition, so without this a saved note has no path to a fresh one.
                Button { newNote() } label: {
                    Label(L("New note"), systemImage: "square.and.pencil").font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless).help(L("Start a new note (record again)")).disabled(busy && !isRecording)
                Button { applyFormat() } label: { Image(systemName: "wand.and.stars") }
                    .buttonStyle(.borderless).help(L("Re-apply format")).disabled(busy || transcript.isEmpty)
                Button { appendMode = true; toggleRecord() } label: { Image(systemName: isRecording ? "stop.circle.fill" : "mic.badge.plus") }
                    .buttonStyle(.borderless).help(L("Record more and add it to this note")).disabled(busy && !isRecording)
                // When this note is a checklist (- [ ] lines), offer to send it to the Task Manager so
                // the markdown isn't a dead end. Parses every checklist line into a new project's tasks.
                if !checklistItems.isEmpty {
                    Button { sendChecklistToTasks() } label: {
                        Label(L("Add to Tasks"), systemImage: "checklist").font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help("\(L("Create a Tasks project from this checklist")) (\(checklistItems.count) \(checklistItems.count == 1 ? L("item") : L("items")))")
                }
                CopyButton(text: editorText)
                Button(role: .destructive) { if let id = selectedID, let e = store.entries.first(where: { $0.id == id }) { remove(e) } else { newNote() } } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help(selectedID == nil ? L("Discard") : L("Delete note"))
            }
            formatToolbar
            if format.intent { intentField }
            if addedToTasksFlash {
                Label(L("Added to Tasks — open the Tasks tab to see them"), systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.green)
                    .transition(.opacity)
            }
            if busy { processingRow }
            if !recordError.isEmpty { recordErrorBanner }
            if isRecording {
                HStack(spacing: 10) {
                    Circle().fill(isPaused ? .orange : .red).frame(width: 8, height: 8)
                    Text(isPaused ? "\(L("Paused…")) \(timeString(elapsed))" : "\(L("Recording more…")) \(timeString(elapsed)) · \(L("tap the mic to stop"))")
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    Button { togglePauseNote() } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill").font(.system(size: 11))
                    }.buttonStyle(.borderless).help(isPaused ? L("Resume (Control)") : L("Pause (Control)"))
                }
            }
            // Title field, then the content below.
            TextField(L("Add a title"), text: $noteTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .bold))
                .focused($titleFocused)
                .padding(.horizontal, 4).padding(.top, 4).padding(.bottom, 2)
                .onChange(of: noteTitle) { _, _ in markComposedIfNeeded(); scheduleAutosave() }
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
            fmtBtn("bold", L("Bold (**)")) { md.wrap("**") }
            fmtBtn("italic", L("Italic (*)")) { md.wrap("*") }
            fmtBtn("strikethrough", L("Strikethrough (~~)")) { md.wrap("~~") }
            fmtBtn("chevron.left.forwardslash.chevron.right", L("Inline code (`)")) { md.wrap("`") }
            Divider().frame(height: 16).padding(.horizontal, 4)
            Menu {
                Button(L("Heading 1")) { md.toggleLinePrefix("# ") }
                Button(L("Heading 2")) { md.toggleLinePrefix("## ") }
                Button(L("Heading 3")) { md.toggleLinePrefix("### ") }
            } label: { Image(systemName: "textformat.size") }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().frame(width: 30).help(L("Heading"))
            fmtBtn("list.bullet", L("Bullet list")) { md.toggleLinePrefix("- ") }
            fmtBtn("list.number", L("Numbered list")) { md.toggleLinePrefix("1. ") }
            fmtBtn("checklist", L("Checklist")) { md.toggleLinePrefix("- [ ] ") }
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
            HStack(spacing: 5) { ProgressView().controlSize(.small); Text(L("Saving…")).font(.caption) }
                .foregroundStyle(.secondary)
        } else if savedFlash {
            Label(L("Saved"), systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green)
        } else {
            Label(L("Auto-saved"), systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary)
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
                        .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                    }
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "number").font(.system(size: 12)).foregroundStyle(.secondary)
                Divider().frame(height: 12)
                TextField(L("Add tags (press Enter)"), text: $tagInput)
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
        RoundedRectangle(cornerRadius: r, style: .continuous).fill(Color.primary.opacity(VGlass.fillRest))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
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

    private func iconFor(_ name: String) -> String { modes.modes.first { $0.name == name }?.icon ?? "doc.text" }

    // MARK: selection / lifecycle
    private func newNote() {
        autosaveTask?.cancel(); autosaveTask = nil; autosaveCommit()   // flush any pending title/body edit before clearing
        work?.cancel(); busy = false; status = ""
        if isRecording { stopRecorderHard() }
        selectedID = nil
        transcript = ""; editorText = ""; noteTitle = ""; noteTags = []; tagInput = ""; intentText = ""
        recordingURL = nil; appendMode = false
        hasComposed = false; lastRecordedSeconds = 0
    }

    /// Latch `hasComposed` once any composition content exists. Drives the recorder→editor flip from
    /// "has the user begun composing?" rather than from a live, user-clearable `editorText`, so a
    /// transient empty body (select-all + delete) during a NEW note doesn't yank the editor (and the
    /// in-progress title/tags) away and replace it with the empty recorder card.
    private func markComposedIfNeeded() {
        guard !hasComposed else { return }
        if !editorText.isEmpty
            || !transcript.isEmpty
            || !noteTags.isEmpty
            || !noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasComposed = true
        }
    }

    /// Stop the recorder and clear all recording-related UI state + the overlay-feeding timer.
    private func stopRecorderHard() {
        levelTimer?.invalidate(); levelTimer = nil
        isRecording = false; isPaused = false; notesCtl.level = 0
        _ = recorder.stop(); recorder.releaseArmed()
    }

    private func loadSelection(_ id: UUID?) {
        guard let id, let e = store.entries.first(where: { $0.id == id }) else { return }
        autosaveTask?.cancel(); autosaveTask = nil; autosaveCommit()   // flush the outgoing note's pending edit before loading the new one
        work?.cancel(); busy = false; status = ""
        if isRecording { stopRecorderHard() }
        // Locked + not yet unlocked → the lock gate (not the editor) is shown; never load the
        // ciphertext into the editor or let autosave touch it. tryUnlock() loads the plaintext.
        if e.locked && !unlocked.contains(id) { gatePassword = ""; gateError = false; return }
        transcript = e.original
        editorText = e.formatted
        noteTitle = e.title
        noteTags = e.tags
        format = modes.mode(named: e.formatName)
        recordingURL = store.audioURL(for: e)
        appendMode = false
        hasComposed = true   // a loaded saved note is already a composition
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
            Stats.shared.record(words: wordCount(doc), seconds: Double(lastRecordedSeconds))
            selectedID = e.id          // keep editing the just-saved note
            noteTags = e.tags          // reflect auto-extracted #hashtags
            // First save with no title yet: focus the Title field so the (easy-to-miss) titling
            // affordance is discoverable and the sidebar list gains a real label, not "Untitled".
            if titleTrim.isEmpty && !titleFocused { titleFocused = true }
        }
        savedFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { savedFlash = false }
    }

    // MARK: actions
    private func toggleRecord() {
        if isRecording {
            if isPaused { _ = recorder.resume() }   // a paused recorder won't flush a final file
            levelTimer?.invalidate(); levelTimer = nil
            // Snapshot the true recorded duration NOW, before newNote()/beginNoteRecording() reset the
            // live `elapsed` clock to 0. Stats.record (at autosave-commit) reads this stable value.
            // Append keeps the running total across legs; a fresh recording replaces it.
            lastRecordedSeconds = appendMode ? (lastRecordedSeconds + elapsed) : elapsed
            isRecording = false; isPaused = false; notesCtl.level = 0
            recordingURL = recorder.stop()
            // stop() re-arms this Notes recorder (prewarm), which keeps the prepared input
            // holding the mic. Nothing else releases it, so a following Fn dictation / to-do
            // capture would cold-start against a still-held mic and fail ("Couldn't start
            // recording") with no retry. Free it now — symmetric to AppDelegate's releaseArmed().
            recorder.releaseArmed()
            if let url = recordingURL { transcribe(url) }
            else { recordError = L("Couldn't capture audio — try recording again."); appendMode = false }
        } else {
            recorder.requestPermission { ok in
                guard ok else { recordError = L("Microphone access denied. Allow Verba under System Settings ▸ Privacy & Security ▸ Microphone."); return }
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
                            recordError = L("Couldn't start recording. The microphone may be in use — wait a moment, then tap Retry.")
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
        busy = true; status = L("Transcribing…")
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
                        recordError = L("Didn't catch anything — try recording again.")
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
                await MainActor.run { busy = false; status = "\(L("Transcription failed:")) \(error.localizedDescription)" }
            }
        }
    }

    private func applyFormat() {
        guard !transcript.isEmpty else { return }
        busy = true; status = "\(L("Organizing into")) \(format.name)…"
        // Snapshot the intent on the main actor so the system prompt always reflects what the user
        // typed RIGHT NOW (the live text is the single source of truth — no separate applied flag).
        let intentSnapshot = intentText
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
                await MainActor.run { busy = false; status = "\(L("Couldn't organize:")) \(error.localizedDescription)" }
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
