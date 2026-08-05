import Foundation
import Combine

/// A long-form note mode: a Claude prompt that turns a spoken monologue into a clean document.
/// Mirrors `Profile` (the dictation modes) — each mode has a name + an editable system prompt and
/// an optional per-mode model. Modes are user-editable (add / customize / delete) and persisted.
struct NoteFormat: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var systemPrompt: String
    var model: String? = nil   // optional per-mode model override
    var builtin: Bool = false  // shipped default (vs. user-created)
    var intent: Bool = false   // free-form: the user supplies a one-off instruction per recording

    private static let nodash = "NEVER use an em dash, an en dash, or a spaced hyphen; use commas, periods, parentheses, or colons instead. Detect the language spoken and write the output in that SAME language. Output ONLY the resulting document, no preamble, no quotes."

    // Most note formats are light restructuring → run them on fast Haiku so a short note returns
    // in ~1s instead of waiting on a heavy model. "Code task / ticket" keeps Opus for precision.
    private static let fast = "claude-haiku-4-5"

    // Built-in note formats carry hard-coded ids so their identity is stable across launches and
    // re-seeds (the default `id = UUID()` would mint a fresh id every launch, breaking any reference
    // — e.g. the user's selected format — that keys off the id).
    static let allBuiltIn: [NoteFormat] = [
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!, name: "Clean note", icon: "doc.text",
              systemPrompt: "Restructure this spoken transcript into a clean, faithful written note. Fix grammar and remove filler (um, uh, repetitions, false starts), order the points logically, add light headings if useful, but keep ALL the information and the speaker's voice. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!, name: "Brain dump → outline", icon: "list.bullet.indent",
              systemPrompt: "This is a messy brain dump. Extract the ideas into a clear nested outline with short headings and bullet points, grouping related thoughts. Add a one-line summary at the top. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B3")!, name: "Summary (TL;DR)", icon: "text.append",
              systemPrompt: "Write a tight TL;DR (1 to 3 sentences) followed by 3 to 6 bullet takeaways capturing the essentials. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B4")!, name: "Meeting notes", icon: "person.2",
              systemPrompt: "Turn this into structured meeting notes with these sections: Summary, Key points, Decisions, Action items (each as owner: task). Omit a section if there is nothing for it. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B5")!, name: "Journal", icon: "book.closed",
              systemPrompt: "Rewrite this as a coherent, well organized first person journal entry, grouped by theme, in the speaker's natural voice. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B6")!, name: "Email", icon: "envelope",
              systemPrompt: "Rewrite this monologue as a clear, courteous, well structured email (greeting, body in logical paragraphs, sign off). Keep every point the speaker made. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B7")!, name: "Code task / ticket", icon: "hammer",
              systemPrompt: "Turn this into a precise engineering task. Sections: Title, Context, Goal, Acceptance criteria (checklist), Technical steps (ordered). Keep every technical detail verbatim (paths, names, commands). \(nodash)", model: "claude-opus-4-8", builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B8")!, name: "To-do list", icon: "checklist",
              systemPrompt: "Extract every actionable task from this transcript as a checklist (- [ ] task), most important first, grouped if there are clear themes. Ignore non-actionable chatter. \(nodash)", model: fast, builtin: true),
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B9")!, name: "Article outline", icon: "doc.richtext",
              systemPrompt: "Turn this into a blog/article outline: a working title, a hook, then sections with their key points as bullets. \(nodash)", model: fast, builtin: true),
        .intent,
    ]

    /// The "Intent" note mode: the user types or speaks a one-off instruction that shapes THIS
    /// recording (e.g. "turn this into a bug report"). The free-form instruction is prepended to
    /// the base prompt at format time (see `NotesView.applyFormat`).
    static let intent = NoteFormat(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BA")!,
        name: "Intent", icon: "wand.and.rays",
        systemPrompt: """
        The user speaks their INTENT first — how they want this shaped (e.g. "as a bug report", \
        "summarize as bullets", "turn this into a polite email") — then the content itself, all in \
        one recording. Read the intent from the START of the transcript, apply it FAITHFULLY to the \
        rest, and output only the result. If the intent asks you to summarize, extract, reformat, \
        change tone, translate, or filter, do exactly that, and do not echo the intent line back. \
        If no clear intent is spoken, just clean up the transcript lightly. Never add facts the \
        speaker did not provide; resolve self-corrections to the final intended meaning. Keep the \
        speaker's one dominant language unless the intent says otherwise. \(nodash)
        """,
        builtin: true, intent: true)

    /// False when this mode carries no prompt of its own (the user cleared the editor, or a bridged /
    /// remotely-synced mode arrived with `systemPrompt: ""`). Callers use it to warn BEFORE running,
    /// so the fallback below is never a silent substitution.
    var hasUsablePrompt: Bool { !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// False when the mode has nothing to label its chip with. The name is also the key a saved note
    /// is restored by (`NoteModesStore.mode(named:)`), so a blank one is worth surfacing.
    var hasUsableName: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// The base prompt a run must use, guaranteed non-empty. An EMPTY system prompt is not a no-op:
    /// the reprompter still answers, unguided, and the "successful" note is whatever the model chose
    /// to invent from a bare transcript. So a blank mode falls back to a shipped prompt, and the
    /// fallback is picked to KEEP the mode's semantics: a blanked Intent mode falls back to the
    /// shipped Intent prompt (it still reads the spoken intent from the head of the transcript),
    /// anything else falls back to the shipped Clean note prompt (faithful, non-destructive).
    /// Both fall back to the SHIPPED constants, never to a stored mode the user may also have blanked.
    var effectiveBasePrompt: String {
        guard !hasUsablePrompt else { return systemPrompt }
        return intent ? Self.intent.systemPrompt : Self.cleanNote.systemPrompt
    }

    /// The instruction-aware prompt actually sent to Claude. Whenever the user supplied a one-off
    /// instruction (Intent mode, or an intent typed alongside any mode) it is woven IN FRONT of the
    /// base prompt with strong precedence, so the note honours it instead of being passed verbatim.
    /// An empty instruction leaves the mode's base prompt untouched. The result is never empty and
    /// never whitespace-only (see `effectiveBasePrompt`).
    func effectiveSystemPrompt(instruction: String) -> String {
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = effectiveBasePrompt
        guard !trimmed.isEmpty else { return base }
        return """
        INSTRUCTION FROM THE USER (apply this faithfully — it takes precedence over the formatting \
        guidance below): \(trimmed)

        \(base)
        """
    }

    static var cleanNote: NoteFormat { allBuiltIn[0] }

    /// Bridge a custom DICTATION mode (Settings.profiles, non-builtin) into a note quick-action so
    /// the user's own modes are one-tap re-formats in Notes too (VER-7). The id is derived
    /// deterministically from the profile id (XOR'd with a fixed salt) so chip/menu selection stays
    /// stable across re-renders and never collides with a built-in note-format id. We carry the
    /// profile's `effectiveSystemPrompt` (so a Translate target-language mode keeps translating) and
    /// its per-mode model. Use `bridgeable(_:)` to decide WHICH profiles may come through.
    ///
    /// INTENT SEMANTICS, and this is the one thing this bridge must never blur: `Profile.intent` (a
    /// dictation mode that happens to be named "Intent") and `NoteFormat.intent` (`intent == true`,
    /// the mode that takes a one-off instruction per recording) are two different objects. A bridged
    /// profile is a plain prompt: it is NEVER marked `intent`, whatever it is called, so it never
    /// claims the per-recording-instruction affordance the real Intent note mode owns. A typed
    /// instruction still applies to it through `effectiveSystemPrompt(instruction:)`, exactly as it
    /// does for every other non-Intent mode.
    static func fromProfile(_ p: Profile) -> NoteFormat {
        var bytes = withUnsafeBytes(of: p.id.uuid) { Array($0) }
        let salt: [UInt8] = [0x4E, 0x6F, 0x74, 0x65, 0x4D, 0x6F, 0x64, 0x65, 0x42, 0x72, 0x69, 0x64, 0x67, 0x65, 0x21, 0x00]
        for i in 0..<16 { bytes[i] ^= salt[i] }
        let derived = uuid_t(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                             bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return NoteFormat(id: UUID(uuid: derived), name: p.name, icon: "wand.and.stars",
                          systemPrompt: p.effectiveSystemPrompt, model: p.model, intent: false)
    }

    /// Which dictation modes may appear as note quick-actions. Four exclusions, each for a reason a
    /// note run cannot satisfy:
    /// - `builtin`: the shipped dictation modes duplicate what the note modes already do.
    /// - `raw`: pure dictation, no reprompting, so it is a no-op as a format.
    /// - `vision`: Context mode acts on a SCREENSHOT (`Pipeline.swift` captures the screen for it).
    ///   Notes never captures a screen, so a bridged vision mode would run against a prompt whose
    ///   premise is absent and answer about a screen it never saw. `AdaptPanel` excludes it for the
    ///   same reason.
    /// - a blank effective prompt: nothing to run (`ConfigSync` can materialise `systemPrompt: ""`).
    static func bridgeable(_ p: Profile) -> Bool {
        !p.builtin && !p.raw && !p.vision
            && !p.effectiveSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A name that is free in `taken`, derived from `name` without ever discarding the entry.
    /// Terminates: each attempt raises `n`, and `taken` is finite.
    static func disambiguated(_ name: String, taken: Set<String>) -> String {
        guard taken.contains(name) else { return name }
        var candidate = "\(name) (mode)"
        var n = 2
        while taken.contains(candidate) { candidate = "\(name) (mode \(n))"; n += 1 }
        return candidate
    }

    /// THE quick-action list contract: the stored note modes, then every bridgeable dictation mode.
    ///
    /// A name collision RENAMES the bridged entry, it never drops it. The previous merge filtered the
    /// bridged modes against the note-mode names, so a dictation mode the user had called "Email" or
    /// "Journal" vanished from Notes with no message, and the user's own prompt was silently replaced
    /// by the note mode that happened to share its title. Renaming keeps both reachable and keeps the
    /// label honest about which list the entry came from.
    ///
    /// Ids are deduped as well: `ForEach` requires unique ids, and this merge is the only place two
    /// sources meet.
    static func quickActions(noteModes: [NoteFormat], profiles: [Profile]) -> [NoteFormat] {
        var taken = Set(noteModes.map(\.name))
        var ids = Set(noteModes.map(\.id))
        var out = noteModes
        for p in profiles where bridgeable(p) {
            var f = fromProfile(p)
            guard !ids.contains(f.id) else { continue }
            f.name = disambiguated(f.name, taken: taken)
            taken.insert(f.name); ids.insert(f.id)
            out.append(f)
        }
        return out
    }
}

/// Persisted, editable store for the note modes (mirrors `Settings.profiles` for dictation modes).
/// Ships the built-in formats as defaults, re-seeds on a version bump, and is migration-safe:
/// a fresh install or a bumped version starts from `allBuiltIn`.
final class NoteModesStore: ObservableObject {
    static let shared = NoteModesStore()
    private let d = UserDefaults.standard

    // Bump when the built-in note modes change so users inherit the new prompts.
    // v2 (VER-20): the Intent mode now reads the spoken intent from the start of the recording.
    static let version = 2

    @Published var modes: [NoteFormat] { didSet { persist() } }

    private init() {
        // Use a LOCAL UserDefaults here: referencing the stored `d` inside the closure would touch
        // `self` before `modes` is initialized (a compile error).
        let ud = UserDefaults.standard
        let upToDate = ud.integer(forKey: "noteModesVersion") >= Self.version
        let saved: [NoteFormat]? = {
            guard let data = ud.data(forKey: "noteModes"),
                  let s = try? JSONDecoder().decode([NoteFormat].self, from: data), !s.isEmpty else { return nil }
            return s
        }()
        if upToDate, let saved {
            modes = saved
        } else if let saved {
            // Version bump WITH existing data → refresh the built-in prompts in place by id (so
            // fixes like the rewritten Intent prompt reach existing users) while KEEPING the user's
            // custom modes and order. The old code full-reset to allBuiltIn here, silently wiping
            // every user-created note mode; this merge never does that.
            let fresh = Dictionary(uniqueKeysWithValues: NoteFormat.allBuiltIn.map { ($0.id, $0) })
            var merged: [NoteFormat] = saved.map { m in
                guard m.builtin, let f = fresh[m.id] else { return m }
                var c = m
                c.systemPrompt = f.systemPrompt; c.model = f.model; c.intent = f.intent
                c.name = f.name; c.icon = f.icon
                return c
            }
            let have = Set(merged.map(\.id))
            for b in NoteFormat.allBuiltIn where !have.contains(b.id) { merged.append(b) }
            modes = merged
            d.set(Self.version, forKey: "noteModesVersion")
            if let data = try? JSONEncoder().encode(merged) { d.set(data, forKey: "noteModes") }
        } else {
            modes = NoteFormat.allBuiltIn
            d.set(Self.version, forKey: "noteModesVersion")
            if let data = try? JSONEncoder().encode(NoteFormat.allBuiltIn) { d.set(data, forKey: "noteModes") }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(modes) { d.set(data, forKey: "noteModes") }
    }

    /// Find the stored mode matching a saved note's format name. Notes persist the format by NAME
    /// (`NotesStore.NotesEntry.formatName`), so this is a lookup over a key the user can duplicate or
    /// rename: first match wins, and `isNameDuplicated(_:)` is what warns them.
    ///
    /// On a MISS (the mode was renamed or deleted since the note was written) the old fallback was
    /// `modes.first`, i.e. whatever mode happens to sit at the top of the list — reopening an old
    /// note then armed an unrelated prompt, and a re-format rewrote it with that mode. We fall back
    /// to Clean note instead: the user's own if they still have it, otherwise the shipped one. It is
    /// faithful, non-destructive and the same for everyone, which makes the miss debuggable.
    func mode(named name: String) -> NoteFormat {
        if let exact = modes.first(where: { $0.name == name }) { return exact }
        return modes.first { $0.id == NoteFormat.cleanNote.id } ?? NoteFormat.cleanNote
    }

    /// A name no stored mode is using yet ("New note mode", "New note mode 2", …). Names are the key
    /// saved notes are restored by, so handing out a duplicate by default builds the ambiguity in.
    func uniqueName(_ base: String) -> String {
        let taken = Set(modes.map(\.name))
        guard taken.contains(base) else { return base }
        var n = 2
        while taken.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// True when another stored mode already answers to this one's name (see `mode(named:)`).
    func isNameDuplicated(_ id: UUID) -> Bool {
        guard let m = modes.first(where: { $0.id == id }) else { return false }
        return modes.contains { $0.id != id && $0.name == m.name }
    }

    @discardableResult
    func addBlank() -> NoteFormat {
        let m = NoteFormat(name: uniqueName("New note mode"), icon: "doc.text",
                           systemPrompt: NoteFormat.cleanNote.systemPrompt)
        modes.append(m)
        return m
    }

    /// Delete a mode. Returns false, and changes nothing, when the mode may not be deleted:
    /// the Intent mode is the only source of one-off instructions and cannot be re-created without a
    /// full reset, and the list must never end up empty (an empty store leaves Notes with no mode to
    /// select at all). The guard lives HERE rather than in the view so every caller inherits it.
    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard let m = modes.first(where: { $0.id == id }), !m.intent, modes.count > 1 else { return false }
        modes.removeAll { $0.id == id }
        return true
    }

    func resetToDefaults() { modes = NoteFormat.allBuiltIn }
}
