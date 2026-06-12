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
        You receive a one-off INSTRUCTION from the user describing how to shape the following \
        spoken transcript, then the transcript itself. Apply the instruction FAITHFULLY to the \
        transcript and output only the result. If the instruction asks you to summarize, extract, \
        reformat, change tone, translate, or filter, do exactly that. Never add facts the speaker \
        did not provide; resolve self-corrections to the final intended meaning. Keep the speaker's \
        one dominant language unless the instruction says otherwise. \(nodash)
        """,
        builtin: true, intent: true)

    /// The instruction-aware prompt actually sent to Claude. Whenever the user supplied a one-off
    /// instruction (Intent mode, or an intent typed alongside any mode) it is woven IN FRONT of the
    /// base prompt with strong precedence, so the note honours it instead of being passed verbatim.
    /// An empty instruction leaves the mode's base prompt untouched.
    func effectiveSystemPrompt(instruction: String) -> String {
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return systemPrompt }
        return """
        INSTRUCTION FROM THE USER (apply this faithfully — it takes precedence over the formatting \
        guidance below): \(trimmed)

        \(systemPrompt)
        """
    }

    static var cleanNote: NoteFormat { allBuiltIn[0] }

    /// Bridge a custom DICTATION mode (Settings.profiles, non-builtin) into a note quick-action so
    /// the user's own modes are one-tap re-formats in Notes too (VER-7). The id is derived
    /// deterministically from the profile id (XOR'd with a fixed salt) so chip/menu selection stays
    /// stable across re-renders and never collides with a built-in note-format id. We carry the
    /// profile's `effectiveSystemPrompt` (so a Translate target-language mode keeps translating) and
    /// its per-mode model. `raw` (pure-dictation) profiles are skipped by the caller.
    static func fromProfile(_ p: Profile) -> NoteFormat {
        var bytes = withUnsafeBytes(of: p.id.uuid) { Array($0) }
        let salt: [UInt8] = [0x4E, 0x6F, 0x74, 0x65, 0x4D, 0x6F, 0x64, 0x65, 0x42, 0x72, 0x69, 0x64, 0x67, 0x65, 0x21, 0x00]
        for i in 0..<16 { bytes[i] ^= salt[i] }
        let derived = uuid_t(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                             bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return NoteFormat(id: UUID(uuid: derived), name: p.name, icon: "wand.and.stars",
                          systemPrompt: p.effectiveSystemPrompt, model: p.model)
    }
}

/// Persisted, editable store for the note modes (mirrors `Settings.profiles` for dictation modes).
/// Ships the built-in formats as defaults, re-seeds on a version bump, and is migration-safe:
/// a fresh install or a bumped version starts from `allBuiltIn`.
final class NoteModesStore: ObservableObject {
    static let shared = NoteModesStore()
    private let d = UserDefaults.standard

    // Bump when the built-in note modes change so users inherit the new prompts.
    static let version = 1

    @Published var modes: [NoteFormat] { didSet { persist() } }

    private init() {
        let upToDate = d.integer(forKey: "noteModesVersion") >= Self.version
        if upToDate, let data = d.data(forKey: "noteModes"),
           let saved = try? JSONDecoder().decode([NoteFormat].self, from: data), !saved.isEmpty {
            modes = saved
        } else {
            modes = NoteFormat.allBuiltIn
            d.set(Self.version, forKey: "noteModesVersion")
            if let data = try? JSONEncoder().encode(NoteFormat.allBuiltIn) { d.set(data, forKey: "noteModes") }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(modes) { d.set(data, forKey: "noteModes") }
    }

    /// Find the stored mode matching a saved note's format name (falls back to the first mode).
    func mode(named name: String) -> NoteFormat {
        modes.first { $0.name == name } ?? modes.first ?? NoteFormat.cleanNote
    }

    @discardableResult
    func addBlank() -> NoteFormat {
        let m = NoteFormat(name: "New note mode", icon: "doc.text",
                           systemPrompt: NoteFormat.cleanNote.systemPrompt)
        modes.append(m)
        return m
    }

    func delete(_ id: UUID) { modes.removeAll { $0.id == id } }

    func resetToDefaults() { modes = NoteFormat.allBuiltIn }
}
