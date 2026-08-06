import SwiftUI
import AVFoundation
import AppKit

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
    // Transcribe/organize failures. These used to be written into `status`, which is only rendered
    // inside `if busy { processingRow }` — and every failure branch clears `busy` in the same
    // breath, so the message was mathematically unreachable and a failed note looked like nothing
    // happened at all. This banner renders whether or not we're busy.
    @State private var workError = ""
    @State private var workFailure: WorkFailure?
    /// What failed, so "Try again" can re-run the right step instead of a generic retry.
    private enum WorkFailure: Equatable {
        case transcribe(URL)   // the audio is still on disk: re-run transcription
        case format            // the transcript is in hand: re-run the formatting
    }
    @State private var work: Task<Void, Never>?
    /// Monotonic id of the current transcribe/organize run. Bumped whenever work is started or
    /// cancelled, so a superseded or cancelled Task can be told to write nothing.
    @State private var workGen = 0
    @State private var activityToken: UUID?     // bottom-right activity chip for this note's transcribe→organize
    @State private var filterTag: String?
    @State private var expandedTags: Set<String> = []   // Bear-style tag tree: which parent tags are open
    // Per-note password lock
    @State private var unlocked: Set<UUID> = []         // notes decrypted this session (cleared on quit)
    @State private var unlockedKeys: [UUID: String] = [:]   // session-only note passwords (never persisted) to re-encrypt locked-note edits
    @State private var lockSheetFor: NotesEntry?        // note being assigned a NEW password
    @State private var newPassword = ""
    @State private var newPasswordConfirm = ""
    @State private var lockError = ""                   // why the last "Lock note" attempt did not protect the note
    @State private var gatePassword = ""                // password typed at the unlock gate
    @State private var gateError = false
    @State private var appendMode = false   // next recording is appended to the current note
    @State private var hasComposed = false  // true once a composition has produced content (title/tags/transcript/text); gates the recorder→editor flip so a transient empty edit doesn't yank the editor away
    @State private var lastRecordedSeconds = 0   // duration snapshotted when the recording stops, used for Stats (live `elapsed` is reset before formatting finishes)
    @State private var autosaveTask: Task<Void, Never>?
    @State private var savedFlash = false   // brief "Saved ✓" after an autosave commit
    /// The note a first-save just created and adopted. That adoption moves `selectedID`, which
    /// re-enters loadSelection; this marker tells it the draft is already persisted so it does not
    /// save a second copy.
    @State private var justAdopted: UUID?
    // Why the last autosave did NOT commit. A refused commit used to `return` silently, so the badge
    // kept reading "Auto-saved" while every edit was being dropped (a locked note re-locked from
    // another device is the real case). Empty = the note is saved.
    @State private var saveError = ""
    // Outcome of the last "Add to Tasks", read back from TodoStore rather than assumed. Every
    // TodoStore mutator is a fire-and-forget Void that no-ops when it can't find its project, so a
    // plain success flash could (and did) claim tasks that were never created.
    @State private var taskFlash: TaskFlash?
    private struct TaskFlash { let text: String; let ok: Bool }
    @StateObject private var md = MarkdownEditorController()   // drives the formatting toolbar

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Layout
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 270)
            Divider().opacity(0.4)
            detail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // VER-11 / VER-18: ⌘⌫ deletes the selected note. SwiftUI's inline keyboardShortcut(.delete)
        // never fires (it isn't registered into AppKit's performKeyEquivalent chain), so the real
        // ⌘⌫ lives as an AppKit menu item (AppDelegate) that bumps this signal.
        .onChange(of: notesCtl.deleteSelectedSignal) { _, _ in deleteSelectedNote() }
        .onAppear { notesCtl.visible = true }
        .onDisappear { notesCtl.visible = false }
        .onReceive(tick) { _ in if isRecording && !isPaused { elapsed = pausedAccum + Int(Date().timeIntervalSince(recordStart)) } }
        // `previous` matters: onChange fires AFTER selectedID moved, so the outgoing note's pending
        // edit must be flushed into the id we came FROM, never into the one just clicked.
        .onChange(of: selectedID) { old, id in loadSelection(id, previous: old) }
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
                if !lockError.isEmpty {
                    Label(lockError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Button(L("Cancel")) { lockSheetFor = nil; newPassword = ""; newPasswordConfirm = ""; lockError = "" }.buttonStyle(.plain)
                    Spacer()
                    Button(L("Lock note")) { commitLock() }
                        .dialogPrimary().keyboardShortcut(.defaultAction)
                        .disabled(newPassword.isEmpty || newPassword != newPasswordConfirm)
                }
            }
            .padding(22).frame(width: 420)
            .presentationBackground(.thinMaterial).dialogAppear()
        }
        // Cancel first, then flush: the commit bails while `busy`, so cancelling afterwards
        // left the in-flight note unsaved AND the view stuck busy the next time it appeared.
        .onDisappear { notesCtl.isRecording = false; levelTimer?.invalidate(); levelTimer = nil; autosaveTask?.cancel(); autosaveTask = nil; cancelWork(); autosaveCommit(target: selectedID); if isRecording { _ = recorder.stop(); recorder.releaseArmed() } }
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
                .disabled(gatePassword.isEmpty)   // empty field said "Wrong password" instead of asking for it
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func tryUnlock(_ e: NotesEntry) {
        guard let dec = store.decrypt(e, password: gatePassword) else { gateError = true; return }
        unlockedKeys[e.id] = gatePassword   // retain the session key so edits can be re-encrypted on save
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
        // Re-read from the store: removePassword just rewrote this entry to plaintext, and `e` is
        // the stale pre-decrypt snapshot. loadEntry (not loadSelection) because the selection has
        // not changed, so there is no outgoing note to flush.
        if let fresh = store.entries.first(where: { $0.id == e.id }) { loadEntry(fresh) }
    }

    private func commitLock() {
        guard let e = lockSheetFor, !newPassword.isEmpty, newPassword == newPasswordConfirm else { return }
        // Flush the latest edit before we encrypt it — and REFUSE to lock if that flush did not
        // land. store.lock encrypts what is on DISK, so locking over a failed flush would seal the
        // older text while the wipe below destroys the only copy of the newer one.
        if selectedID == e.id, !autosaveCommit(target: selectedID) {
            lockError = L("Couldn't save this note's latest changes, so it was not locked. Copy your changes, then try again.")
            return
        }
        if store.lock(e, password: newPassword) {
            unlocked.remove(e.id)
            unlockedKeys.removeValue(forKey: e.id)   // don't keep the password for a note we just sealed
            if selectedID == e.id {
                // Wipe the plaintext from the editor BEFORE newNote(). newNote() flushes, and with
                // the selection already cleared that flush hit the CREATE branch and wrote the
                // just-encrypted body back out as a brand-new UNLOCKED note, then pushed the
                // plaintext to the cloud: locking a note quietly published a clear copy of it.
                transcript = ""; editorText = ""; noteTitle = ""; noteTags = []
                selectedID = nil
                newNote()   // drop the now-encrypted text from the editor
            }
        } else {
            // store.lock returns false on an empty password, a missing entry, an already-locked
            // note, or a crypto failure (now including an RNG failure, which used to degrade to a
            // zero salt). Closing the sheet silently told the user their note was protected while
            // it stayed in plaintext on disk and in the cloud.
            lockError = L("Couldn't lock this note, so it is still unprotected. Try again.")
            return
        }
        lockError = ""
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
                Button { lockError = ""; newPassword = ""; newPasswordConfirm = ""; lockSheetFor = e } label: { Label(L("Lock with password…"), systemImage: "lock") }
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
            if !isRecording { writeInsteadButton }
            if isRecording { pauseControl }
            problemBanners
            formatChips
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32).padding(.horizontal, 24)
        .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// VER-44: a text-first path into a note. The Notes tab defaults to voice, but a note can also
    /// be written or pasted. This button reveals the always-editable editor on an empty draft, with
    /// no recording required, so typing and paste (Cmd+V, native to the editor) create a note too.
    private var writeInsteadButton: some View {
        Button { startTypedNote() } label: {
            HStack(spacing: 7) {
                Image(systemName: "keyboard").font(.system(size: 12, weight: .semibold))
                Text(L("Write it instead")).font(.callout.weight(.medium))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(Color.primary.opacity(0.055)))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(L("Type or paste a note instead of recording"))
    }

    /// VER-44: open the note editor on a fresh, empty draft so the user can type or paste directly.
    /// Latching `hasComposed` flips `detail` from the record-only card to the editable editor; the
    /// existing debounced autosave (autosaveCommit) then persists any non-empty text with no store
    /// changes, exactly like a dictated note after formatting.
    private func startTypedNote() {
        newNote()             // fresh, empty draft (clears any stale transcript / record state)
        hasComposed = true    // reveal the editor even though nothing was recorded
        // Best-effort focus so the caret lands in the body for immediate typing / paste. Deferred so
        // the editor's NSTextView exists after SwiftUI rebuilds; if it isn't ready yet, the user
        // simply clicks into the editor.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let tv = md.textView { tv.window?.makeFirstResponder(tv) }
        }
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
                // Retry can only fail again on a hard permission denial (macOS won't re-prompt);
                // offer the actionable path — open the Microphone privacy pane directly.
                Button(L("Open Settings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                        NSWorkspace.shared.open(url)
                    }
                }.glassButton()
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

    /// Transcribe / organize outcome banner. Amber rather than red: in every case here the note's
    /// words are still on screen and saved, so this reports a step that didn't finish, not a loss.
    /// "Try again" re-runs the step that actually failed; it is hidden when a retry could only fail
    /// the same way (silent audio), so the button is never a lie (R-LOOP: no unbounded retry).
    private var workErrorBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 14, weight: .semibold))
                Text(workError).font(.callout.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(Color.orange)
            HStack(spacing: 10) {
                if let f = workFailure {
                    Button(f == .format ? L("Organize again") : L("Transcribe again")) { retryWork(f) }
                        .glassProminentButton().tint(.orange).disabled(busy)
                }
                Button(L("Dismiss")) { workError = ""; workFailure = nil }.glassButton()
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.orange.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.orange.opacity(0.35), lineWidth: 1))
        )
        .transition(.opacity)
    }

    /// The two problem banners as ONE child. They are grouped because `noteEditor`'s VStack sits at
    /// exactly ViewBuilder's 10-subview ceiling; adding an 11th direct child there is a compile
    /// error, not a layout nit.
    @ViewBuilder private var problemBanners: some View {
        if !recordError.isEmpty { recordErrorBanner }
        if !workError.isEmpty { workErrorBanner }
    }

    private func retryWork(_ f: WorkFailure) {
        workError = ""; workFailure = nil
        switch f {
        case .transcribe(let url): transcribe(url)
        case .format:              applyFormat()
        }
    }

    private var formatChips: some View {
        VStack(spacing: 10) {
            FlowLayout(spacing: 8, alignment: .center) {
                ForEach(quickActionModes) { f in
                    chip(label: f.name, icon: f.icon, on: f.id == format.id) {
                        format = f; if !transcript.isEmpty { applyFormat() }
                    }
                }
            }
            if format.intent { intentHelper }
            Button { showModeManager = true } label: {
                Label(L("Manage modes"), systemImage: "slider.horizontal.3").font(.caption)
            }
            .buttonStyle(.borderless).foregroundStyle(.secondary)
        }
    }

    /// VER-20: before recording, explain that the intent is SPOKEN at the start of the note (not
    /// typed in a separate box); once a note exists, the typed field returns so it can be refined.
    @ViewBuilder private var intentHelper: some View {
        if transcript.isEmpty {
            intentExplanation
        } else {
            intentField
        }
    }

    /// The "how Intent works" card shown while composing — invites recording instead of typing.
    private var intentExplanation: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "wand.and.rays").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(L("Say your intent, then your note, in one recording"))
                    .font(.system(size: 12, weight: .medium))
                Text(L("Start by saying how you want it shaped (e.g. “as a bug report”, “summarize as bullets”), then speak your content. Verba applies your intent to the rest. Just press your trigger and talk."))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .frame(maxWidth: 460)
    }

    /// Free-form instruction to REFINE an existing Intent note: a one-off directive reshaping it.
    /// Multi-line / auto-expanding so a long intent stays fully visible; Enter (or the Validate
    /// button) confirms it, flipping an "applied" state so the user knows the instruction registered.
    private var intentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "wand.and.rays").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 2)
                Divider().frame(height: 16)
                // axis:.vertical grows the field to fit the instruction; the field is wrapped in a
                // bounded ScrollView so a LONG intent stays fully accessible (scrolls) instead of
                // being truncated past a fixed line cap (VER-51).
                ScrollView {
                    TextField(L("How should this note be shaped? (e.g. \u{201C}as a bug report\u{201D})"),
                              text: $intentText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...)
                        .focused($intentFocused)
                        .onSubmit { applyIntentNow() }                                // Enter re-formats now
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
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

    /// Export the current note to a user-chosen file (VER-9). The body (`editorText`) is already
    /// Markdown, so we write it verbatim; the default filename comes from the note's title (or its
    /// first non-empty line). Mirrors the NSSavePanel pattern used elsewhere in the app.
    private func exportNote(ext: String) {
        let body = editorText
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let titleTrim = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = body.split(separator: "\n", omittingEmptySubsequences: true).first
            .map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: "# ")) } ?? ""
        let rawBase = titleTrim.isEmpty ? (firstLine.isEmpty ? "Note" : firstLine) : titleTrim
        // Strip filename-illegal characters and cap length.
        let illegal = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let base = String(rawBase.components(separatedBy: illegal).joined().prefix(60))
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(base.isEmpty ? "Note" : base).\(ext)"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if panel.runModal() == .OK, let url = panel.url {
            try? body.data(using: .utf8)?.write(to: url)
        }
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
        let store = TodoStore.shared
        let pid = store.addProject(name)
        store.appendTasks(pid, items.map { (title, _) in (title, [String](), nil) })
        // Confirm against the store instead of assuming. Every TodoStore mutator is a
        // fire-and-forget Void that silently no-ops when it can't find its project, so the old code
        // flashed "Added to Tasks" whether or not a single task had been created.
        guard let pi = store.projects.firstIndex(where: { $0.id == pid }),
              store.projects[pi].tasks.count >= items.count else {
            flashTaskResult(L("Couldn't add these to Tasks. Open the Tasks tab and try again."), ok: false)
            return
        }
        // Carry over already-checked items so a partially-done list lands consistent. The project
        // was created empty a line ago, so checklist item N is task N.
        for (idx, item) in items.enumerated() where item.done && idx < store.projects[pi].tasks.count {
            store.projects[pi].tasks[idx].done = true
        }
        let n = items.count
        flashTaskResult("\(L("Added to Tasks")) · \(n) \(n == 1 ? L("task") : L("tasks")) \(L("in")) “\(name)”", ok: true)
    }

    private func flashTaskResult(_ text: String, ok: Bool) {
        withAnimation(.easeInOut(duration: 0.18)) { taskFlash = TaskFlash(text: text, ok: ok) }
        // A failure stays up longer than a confirmation: it is the one the user must actually read.
        DispatchQueue.main.asyncAfter(deadline: .now() + (ok ? 2.6 : 5.0)) {
            withAnimation(.easeOut(duration: 0.25)) { taskFlash = nil }
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
                    ForEach(quickActionModes) { f in
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
                // Export the note to a portable file (the body is already Markdown). VER-9.
                Menu {
                    Button(L("Markdown (.md)")) { exportNote(ext: "md") }
                    Button(L("Plain text (.txt)")) { exportNote(ext: "txt") }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .help(L("Export note"))
                .disabled(editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                CopyButton(text: editorText)
                Button(role: .destructive) { if let id = selectedID, let e = store.entries.first(where: { $0.id == id }) { remove(e) } else { discardDraft() } } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help(selectedID == nil ? L("Discard") : L("Delete note"))
            }
            formatToolbar
            if format.intent { intentHelper }
            if let f = taskFlash {
                Label(f.text, systemImage: f.ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(f.ok ? Color.green : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
            if busy { processingRow }
            problemBanners
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
        if !saveError.isEmpty {
            // A refused commit must never read "Auto-saved" — that is the badge telling the user
            // their work is safe while it is being dropped on every keystroke.
            Label(L("Not saved"), systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.orange).help(saveError)
        } else if autosaveTask != nil {
            HStack(spacing: 5) { ProgressView().controlSize(.small); Text(L("Saving…")).font(.caption) }
                .foregroundStyle(.secondary)
        } else if savedFlash {
            Label(L("Saved"), systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green)
        } else if selectedID != nil {
            Label(L("Auto-saved"), systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary)
        } else {
            Label(L("Draft"), systemImage: "pencil.circle").font(.caption).foregroundStyle(.tertiary)
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

    private func iconFor(_ name: String) -> String { quickActionModes.first { $0.name == name }?.icon ?? "doc.text" }

    /// All one-tap note actions: every note format (built-in + custom note modes) PLUS the user's
    /// custom DICTATION modes (Settings.profiles, non-builtin, non-raw) bridged into note formats so
    /// they re-format a note in one tap (VER-7). Raw/pure-dictation profiles are excluded (no
    /// reprompting = no-op as a format). De-duped by name so a custom note mode that shares a name
    /// with a dictation mode isn't listed twice.
    private var quickActionModes: [NoteFormat] {
        let noteNames = Set(modes.modes.map { $0.name })
        let bridged = settings.profiles
            .filter { !$0.builtin && !$0.raw && !noteNames.contains($0.name) }
            .map(NoteFormat.fromProfile)
        return modes.modes + bridged
    }

    // MARK: selection / lifecycle
    private func newNote() {
        autosaveTask?.cancel(); autosaveTask = nil
        // Clear `busy` BEFORE flushing: the commit guards on `!busy`, so the old order
        // (commit, then cancel) silently threw away the text of a note that was still organizing.
        cancelWork()
        autosaveCommit(target: selectedID)   // flush any pending title/body edit before clearing
        if isRecording { stopRecorderHard() }
        selectedID = nil
        transcript = ""; editorText = ""; noteTitle = ""; noteTags = []; tagInput = ""; intentText = ""
        recordingURL = nil; appendMode = false
        recordError = ""; workError = ""; workFailure = nil; saveError = ""
        // The flush above may have adopted a draft; clearing the selection right after means
        // loadSelection never runs to consume that marker. Left set, the NEXT draft the user types
        // would be flushed into the note this one became.
        justAdopted = nil
        hasComposed = false; lastRecordedSeconds = 0
    }

    /// Throw the unsaved draft away WITHOUT committing it. The trash control is labelled "Discard"
    /// on a new note, but it routed through newNote(), which FLUSHES first — so the one destructive
    /// button in the header actually created the note, filed it in the sidebar, recorded it in Stats
    /// and fired the savedNote flag. Emptying the editor first makes newNote's flush a no-op.
    private func discardDraft() {
        autosaveTask?.cancel(); autosaveTask = nil
        cancelWork()
        transcript = ""; editorText = ""; noteTitle = ""; noteTags = []
        newNote()
    }

    /// Cancel any in-flight transcribe/organize work and leave the UI in a clean, non-busy state.
    /// The Tasks themselves return early on `Task.isCancelled`, so the CANCELLER owns the cleanup:
    /// without this, `busy` stayed true forever (a permanent "Working…" row that also disabled
    /// autosave, which guards on `!busy`) and the ActivityCenter chip was never resolved.
    private func cancelWork() {
        work?.cancel(); work = nil
        workGen &+= 1               // invalidate anything still in flight (see beginWork)
        busy = false; status = ""
        if let t = activityToken { ActivityCenter.shared.drop(t); activityToken = nil }
    }

    /// Take ownership of the work slot and return the generation the new task must run under.
    ///
    /// `Task.isCancelled` alone is not enough: both transcribe and applyFormat suspend across
    /// `await MainActor.run`, and a cancel landing in that gap still let the old task write its
    /// transcript into whatever note is now loaded and then call applyFormat, which set `busy` back
    /// to true and installed a fresh Task the canceller no longer held. applyFormat also used to
    /// replace `work` WITHOUT cancelling the previous format task, so a superseded run could paint
    /// a permanent "Couldn't organize" banner over a note that had organized fine. One monotonic
    /// counter closes both: a task whose generation is stale writes nothing.
    private func beginWork() -> Int {
        work?.cancel()
        workGen &+= 1
        return workGen
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

    private func loadSelection(_ id: UUID?, previous: UUID?) {
        guard let id, let e = store.entries.first(where: { $0.id == id }) else { return }
        autosaveTask?.cancel(); autosaveTask = nil
        cancelWork()   // clear `busy` first, else the flush below is a no-op (see newNote)
        // Reset the transient banners BEFORE the flush, never after: the flush can set `saveError`
        // (the outgoing note was deleted or locked elsewhere) and clearing afterwards wiped that
        // warning before it ever rendered — on precisely the path where loadEntry below overwrites
        // the editor and those edits become unrecoverable.
        recordError = ""; workError = ""; workFailure = nil; saveError = ""
        // Which note does the editor's current content belong to? Normally the note we came FROM.
        // But a first save adopts the draft into a real note and moves `selectedID` itself, and
        // SwiftUI may coalesce that with the user's next click into a single onChange (old = nil),
        // so `previous` alone would read as "unsaved draft" and save a SECOND copy. `justAdopted`
        // carries the real owner across that gap.
        let outgoing = previous ?? justAdopted
        justAdopted = nil
        if outgoing != id {
            // `adopt: false` so committing a draft on the way out cannot reassign selectedID and
            // fight the selection the user just made.
            autosaveCommit(target: outgoing, adopt: false)
        }
        // outgoing == id means this change IS our own adoption: already committed, nothing to flush.
        if isRecording { stopRecorderHard() }
        // Locked + not yet unlocked → the lock gate (not the editor) is shown; never load the
        // ciphertext into the editor or let autosave touch it. tryUnlock() loads the plaintext.
        if e.locked && !unlocked.contains(id) { gatePassword = ""; gateError = false; return }
        loadEntry(e)
    }

    /// Load a note's stored content into the editor. Deliberately does NOT flush: only a caller
    /// that is SWITCHING notes has an outgoing note to commit, and that caller is loadSelection.
    /// Re-loading the SAME note (after unlocking it, say) must not flush, because while a lock gate
    /// is up the editor still holds the previously-open note's text.
    private func loadEntry(_ e: NotesEntry) {
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

    /// Delete the currently-selected note (⌘⌫). No-op while composing a new, unsaved note.
    private func deleteSelectedNote() {
        guard let id = selectedID, let e = store.entries.first(where: { $0.id == id }) else { return }
        remove(e)
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
                if editorText == snapshot { autosaveCommit(target: selectedID) }   // settled → commit
            }
        }
    }

    /// Create the note (first commit) or update it. Idempotent; safe to call on disappear.
    ///
    /// `target` is the note the CURRENT editor content belongs to, and it is explicit for a reason:
    /// a caller that is SWITCHING notes must pass the OUTGOING id, because `selectedID` has already
    /// moved by the time `.onChange(of: selectedID)` fires. Reading `selectedID` here meant that
    /// clicking note B flushed note A's body into B and pushed it to the cloud, while the editor
    /// repainted from a snapshot taken before the write, so the damage stayed invisible until the
    /// next launch or sync.
    ///
    /// `adopt` says whether a note CREATED here should become the selection. False when we are only
    /// flushing a draft on the way out, so the flush cannot fight the user's new selection.
    /// Returns true when the editor's content is safely on disk (committed now, or already
    /// identical to what is stored). Callers that are about to DESTROY the editor content, like
    /// commitLock, must check this rather than assume the flush landed.
    @discardableResult
    private func autosaveCommit(target: UUID?, adopt: Bool = true) -> Bool {
        let doc = editorText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !doc.isEmpty, !busy else { return false }
        let titleTrim = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = target {
            // The note is gone (the user just deleted it). Falling through to the create branch
            // here RESURRECTED the note that was just deleted, under a fresh id and date that the
            // tombstone (keyed on the old timestamp) could not suppress.
            guard let e = store.entries.first(where: { $0.id == id }) else {
                // Deleted underneath the editor (a cloud pull can do this without going through
                // remove()). Say so rather than let the badge keep reading "Auto-saved".
                saveError = L("This note was deleted on another device. Copy your changes to keep them.")
                return false
            }
            let mergedTags = NotesStore.mergeTags(noteTags + NotesStore.hashtags(in: doc))
            if e.formatted == doc, e.formatName == format.name, e.tags == mergedTags, e.title == titleTrim {
                saveError = ""   // in sync: never leave a stale "Not saved" on a clean note
                return true      // already identical on disk: safe to destroy the editor
            }
            // A locked-but-unlocked-this-session note must be re-encrypted, not written as plaintext —
            // and we must NOT flash "Saved" if the commit didn't actually happen (was silent data loss).
            let committed: Bool
            if e.locked, let pw = unlockedKeys[id] {
                committed = store.updateUnlockedNote(e, original: transcript, formatted: doc, formatName: format.name, tags: noteTags, title: titleTrim, password: pw)
            } else if e.locked {
                // The note is locked but this session holds no password for it — it was locked on
                // another device and adopted by a cloud pull while the editor was open. Writing it
                // as plaintext would defeat the lock, so we refuse; say so instead of dropping the
                // edit behind an "Auto-saved" badge.
                committed = false
            } else {
                committed = store.update(e, formatted: doc, formatName: format.name, tags: noteTags, title: titleTrim)
            }
            guard committed else {
                saveError = e.locked
                    ? L("This note was locked on another device. Copy your changes, then unlock it with its password to save them.")
                    : L("Couldn't save this note. Copy your changes before closing Verba.")
                return false
            }
        } else {
            let e = store.add(original: transcript, formatted: doc, formatName: format.name, audioURL: recordingURL, tags: noteTags, title: titleTrim)
            Stats.shared.record(words: wordCount(doc), seconds: Double(lastRecordedSeconds))
            if adopt {
                // Adopting reassigns selectedID, which re-enters loadSelection with `previous ==
                // nil`. Without this marker that flush takes the create branch AGAIN and saves a
                // SECOND copy of the note (and pushes it), on every single first save.
                justAdopted = e.id
                selectedID = e.id          // keep editing the just-saved note
                noteTags = e.tags          // reflect auto-extracted #hashtags
                // First save with no title yet: focus the Title field so the (easy-to-miss) titling
                // affordance is discoverable and the sidebar list gains a real label, not "Untitled".
                if titleTrim.isEmpty && !titleFocused { titleFocused = true }
            }
        }
        saveError = ""
        savedFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { savedFlash = false }
        return true
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
        if !appendMode {
            transcript = ""; editorText = ""; noteTags = []
        } else if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !editorText.isEmpty {
            // Appending to a note that has no raw source — one typed via "Write it instead", or
            // adopted from a cloud pull, both of which store an empty `original`. transcribe() ends
            // with `editorText = transcript`, so without seeding the transcript from the body the
            // ENTIRE existing note was replaced by the new recording alone, then autosaved over.
            transcript = editorText
        }
        status = ""; recordError = ""; workError = ""; workFailure = nil; recordStart = Date(); elapsed = 0
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
        let gen = beginWork()
        // transcribe is the only place that MINTS a token; applyFormat just updates the one it
        // inherits. Resolve any token still held before overwriting the slot, or a superseded run
        // would strand its chip in the activity list forever.
        if let t = activityToken { ActivityCenter.shared.drop(t); activityToken = nil }
        busy = true; status = L("Transcribing…")
        // Activity chip (multitask visibility): this note is transcribing (then organizing) in the
        // background, so the user can watch it alongside any other in-flight work.
        activityToken = ActivityCenter.shared.begin(kind: .note, label: L("Transcribing note…"))
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
                    language: s.transcriptionLanguage, hint: DictionaryStore.shared.hint())
                text = DictionaryStore.shared.apply(to: text)
                if s.voiceCommands { text = VoiceCommands.apply(text) }
                if Task.isCancelled { return }
                // Empty/garbled audio → a readable banner, not a stuck "Transcribing…" spinner
                // (applyFormat() bails on empty transcript without ever clearing busy). The three
                // engines THROW TranscribeError.empty rather than returning "", so this guard is the
                // second net; the catch below handles the thrown case identically.
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    await MainActor.run { if gen == workGen { reportHeardNothing() } }
                    return
                }
                await MainActor.run {
                    // Cancellation can land in the actor hop above. Without this the abandoned
                    // recording's text was written into whatever note is now loaded, and the
                    // applyFormat() below re-armed `busy` with a Task the canceller had let go.
                    guard gen == workGen else { return }
                    // Safety net: every note dictation ALSO lands in History (tagged "note"),
                    // so the dictated text stays recoverable even if the note is later deleted.
                    History.shared.add(original: text, reprompted: text, profileName: format.name,
                                       engine: Self.engineLabel(s), audioURL: nil, source: "note")
                    if appendMode { transcript = (transcript + "\n\n" + text).trimmingCharacters(in: .whitespacesAndNewlines); appendMode = false }
                    else { transcript = text }
                    editorText = transcript
                    // VER-20: Intent now reads the spoken intent from the START of the recording (the
                    // user says "as a bug report", then the content, in one take) — no separate typed
                    // field required. So always apply the format; a typed instruction, if present, still
                    // takes precedence (effectiveSystemPrompt prepends it). Called INSIDE this block so
                    // it is atomic with the generation check above.
                    applyFormat()
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard gen == workGen else { return }
                    // Silence is not a failure. The engines throw TranscribeError.empty for a silent
                    // or unreadable recording, and the old code surfaced that as "Transcription
                    // failed: …" — alarming, and it offered a retry that could only fail again.
                    if case TranscribeError.empty = error { reportHeardNothing(); return }
                    busy = false; status = ""; appendMode = false
                    workError = "\(L("Couldn't transcribe this recording.")) \(error.localizedDescription)"
                    workFailure = .transcribe(url)   // the audio is still on disk, so a retry is real
                    if let t = activityToken { ActivityCenter.shared.finish(t, ok: false, resultLabel: L("Note failed")); activityToken = nil }
                }
            }
        }
    }

    /// The recording carried no speech. Nothing is overwritten: `transcript` and `editorText` are
    /// left exactly as they were, so an append onto an existing note keeps that note intact.
    private func reportHeardNothing() {
        busy = false; status = ""; appendMode = false
        workError = L("Didn't catch anything. The recording sounded silent, so nothing was changed. Try recording again.")
        workFailure = nil   // re-transcribing the same silent audio can only fail again
        if let t = activityToken { ActivityCenter.shared.drop(t); activityToken = nil }
    }

    private func applyFormat() {
        guard !transcript.isEmpty else { return }
        // Supersede any run already in flight. Re-picking a format used to leave the previous task
        // alive, and BOTH wrote back: the loser could stamp a permanent "Couldn't organize" banner
        // (and its older output) over a note the winner had organized fine.
        let gen = beginWork()
        busy = true; status = "\(L("Organizing into")) \(format.name)…"
        if let t = activityToken { ActivityCenter.shared.update(t, label: L("Organizing note…")) }
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
                    guard gen == workGen else { return }   // superseded or cancelled: write nothing
                    // An EMPTY model reply must never blank the note. Every HTTP backend throws on
                    // empty, but the local-model path (Reprompter falls back to LocalLLM whenever
                    // `fast` is set and no Anthropic key is present) returns "" with no guard — so
                    // this assigned an empty editorText, flashed "Note ready", and autosaved a blank
                    // note over the user's words. Keep what we have and say what happened.
                    guard !out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        busy = false; status = ""
                        workError = L("The model returned an empty note, so your transcript was kept as it was recorded.")
                        workFailure = .format
                        autosaveTask?.cancel(); autosaveTask = nil
                        autosaveCommit(target: selectedID)   // the raw transcript is still worth saving
                        if let t = activityToken { ActivityCenter.shared.finish(t, ok: false, resultLabel: L("Note failed")); activityToken = nil }
                        return
                    }
                    editorText = out; busy = false; status = ""
                    workError = ""; workFailure = nil
                    autosaveTask?.cancel(); autosaveTask = nil
                    autosaveCommit(target: selectedID)   // persist the finished note immediately (no debounce wait)
                    if let t = activityToken { ActivityCenter.shared.finish(t, ok: true, resultLabel: L("Note ready")); activityToken = nil }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard gen == workGen else { return }   // superseded or cancelled: write nothing
                    // editorText still holds the raw transcript here (transcribe() assigned it before
                    // calling us), so nothing is lost — commit it so the words survive the failure.
                    busy = false; status = ""
                    workError = "\(L("Couldn't organize this note, your transcript was kept.")) \(error.localizedDescription)"
                    workFailure = .format
                    autosaveTask?.cancel(); autosaveTask = nil
                    autosaveCommit(target: selectedID)
                    if let t = activityToken { ActivityCenter.shared.finish(t, ok: false, resultLabel: L("Note failed")); activityToken = nil }
                }
            }
        }
    }

    private func timeString(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }

    /// Same engine label the dictation pipeline writes into History (Pipeline.engineLabel is
    /// private to it), so note-sourced entries filter identically in the History tab.
    private static func engineLabel(_ s: Settings) -> String {
        switch s.engine {
        case .openAI:   return "openai:gpt-4o-transcribe"
        case .whisper:  return "whisper:\(s.localModel)"
        case .parakeet: return "parakeet:v3"
        }
    }
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
