import Foundation

/// A long-form note format: a Claude prompt that turns a spoken monologue into a clean document.
struct NoteFormat: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var systemPrompt: String
    var model: String? = nil   // optional per-format model override

    private static let nodash = "NEVER use an em dash, an en dash, or a spaced hyphen; use commas, periods, parentheses, or colons instead. Detect the language spoken and write the output in that SAME language. Output ONLY the resulting document, no preamble, no quotes."

    // Most note formats are light restructuring → run them on fast Haiku so a short note returns
    // in ~1s instead of waiting on a heavy model. "Code task / ticket" keeps Opus for precision.
    private static let fast = "claude-haiku-4-5"

    static let allBuiltIn: [NoteFormat] = [
        .init(name: "Clean note", icon: "doc.text",
              systemPrompt: "Restructure this spoken transcript into a clean, faithful written note. Fix grammar and remove filler (um, uh, repetitions, false starts), order the points logically, add light headings if useful, but keep ALL the information and the speaker's voice. \(nodash)", model: fast),
        .init(name: "Brain dump → outline", icon: "list.bullet.indent",
              systemPrompt: "This is a messy brain dump. Extract the ideas into a clear nested outline with short headings and bullet points, grouping related thoughts. Add a one-line summary at the top. \(nodash)", model: fast),
        .init(name: "Summary (TL;DR)", icon: "text.append",
              systemPrompt: "Write a tight TL;DR (1 to 3 sentences) followed by 3 to 6 bullet takeaways capturing the essentials. \(nodash)", model: fast),
        .init(name: "Meeting notes", icon: "person.2",
              systemPrompt: "Turn this into structured meeting notes with these sections: Summary, Key points, Decisions, Action items (each as owner: task). Omit a section if there is nothing for it. \(nodash)", model: fast),
        .init(name: "Journal", icon: "book.closed",
              systemPrompt: "Rewrite this as a coherent, well organized first person journal entry, grouped by theme, in the speaker's natural voice. \(nodash)", model: fast),
        .init(name: "Email", icon: "envelope",
              systemPrompt: "Rewrite this monologue as a clear, courteous, well structured email (greeting, body in logical paragraphs, sign off). Keep every point the speaker made. \(nodash)", model: fast),
        .init(name: "Code task / ticket", icon: "hammer",
              systemPrompt: "Turn this into a precise engineering task. Sections: Title, Context, Goal, Acceptance criteria (checklist), Technical steps (ordered). Keep every technical detail verbatim (paths, names, commands). \(nodash)", model: "claude-opus-4-8"),
        .init(name: "To-do list", icon: "checklist",
              systemPrompt: "Extract every actionable task from this transcript as a checklist (- [ ] task), most important first, grouped if there are clear themes. Ignore non-actionable chatter. \(nodash)", model: fast),
        .init(name: "Article outline", icon: "doc.richtext",
              systemPrompt: "Turn this into a blog/article outline: a working title, a hook, then sections with their key points as bullets. \(nodash)", model: fast),
    ]

    static var cleanNote: NoteFormat { allBuiltIn[0] }
}
