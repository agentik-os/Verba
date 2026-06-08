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

    static let allBuiltIn: [NoteFormat] = [
        .init(name: "Clean note", icon: "doc.text",
              systemPrompt: "Restructure this spoken transcript into a clean, faithful written note. Fix grammar and remove filler (um, uh, repetitions, false starts), order the points logically, add light headings if useful, but keep ALL the information and the speaker's voice. \(nodash)", model: fast, builtin: true),
        .init(name: "Brain dump → outline", icon: "list.bullet.indent",
              systemPrompt: "This is a messy brain dump. Extract the ideas into a clear nested outline with short headings and bullet points, grouping related thoughts. Add a one-line summary at the top. \(nodash)", model: fast, builtin: true),
        .init(name: "Summary (TL;DR)", icon: "text.append",
              systemPrompt: "Write a tight TL;DR (1 to 3 sentences) followed by 3 to 6 bullet takeaways capturing the essentials. \(nodash)", model: fast, builtin: true),
        .init(name: "Meeting notes", icon: "person.2",
              systemPrompt: "Turn this into structured meeting notes with these sections: Summary, Key points, Decisions, Action items (each as owner: task). Omit a section if there is nothing for it. \(nodash)", model: fast, builtin: true),
        .init(name: "Journal", icon: "book.closed",
              systemPrompt: "Rewrite this as a coherent, well organized first person journal entry, grouped by theme, in the speaker's natural voice. \(nodash)", model: fast, builtin: true),
        .init(name: "Email", icon: "envelope",
              systemPrompt: "Rewrite this monologue as a clear, courteous, well structured email (greeting, body in logical paragraphs, sign off). Keep every point the speaker made. \(nodash)", model: fast, builtin: true),
        .init(name: "Code task / ticket", icon: "hammer",
              systemPrompt: "Turn this into a precise engineering task. Sections: Title, Context, Goal, Acceptance criteria (checklist), Technical steps (ordered). Keep every technical detail verbatim (paths, names, commands). \(nodash)", model: "claude-opus-4-8", builtin: true),
        .init(name: "To-do list", icon: "checklist",
              systemPrompt: "Extract every actionable task from this transcript as a checklist (- [ ] task), most important first, grouped if there are clear themes. Ignore non-actionable chatter. \(nodash)", model: fast, builtin: true),
        .init(name: "Article outline", icon: "doc.richtext",
              systemPrompt: "Turn this into a blog/article outline: a working title, a hook, then sections with their key points as bullets. \(nodash)", model: fast, builtin: true),
        .intent,
    ]

    /// The "Intent" note mode: the user types or speaks a one-off instruction that shapes THIS
    /// recording (e.g. "turn this into a bug report"). The free-form instruction is prepended to
    /// the base prompt at format time (see `NotesView.applyFormat`).
    static let intent = NoteFormat(
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

    /// The instruction-aware prompt actually sent to Claude. For an Intent mode the user's one-off
    /// instruction is woven in front of the base prompt; other modes ignore it.
    func effectiveSystemPrompt(instruction: String) -> String {
        guard intent else { return systemPrompt }
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return systemPrompt }
        return "INSTRUCTION FROM THE USER: \(trimmed)\n\n\(systemPrompt)"
    }

    static var cleanNote: NoteFormat { allBuiltIn[0] }
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
