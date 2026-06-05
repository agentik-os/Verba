import Foundation
import Combine

// MARK: - Persistence helper

private func loadJSON<T: Decodable>(_ key: String, _ type: T.Type) -> T? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}
private func saveJSON<T: Encodable>(_ key: String, _ value: T) {
    if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
}

func wordCount(_ s: String) -> Int {
    s.split { $0.isWhitespace || $0.isNewline }.count
}

private func dayKey(_ date: Date = Date()) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
    return f.string(from: date)
}

// MARK: - Stats (words / wpm / streak)

struct DayStat: Codable { var words: Int = 0; var seconds: Double = 0; var count: Int = 0 }

final class Stats: ObservableObject {
    static let shared = Stats()
    @Published private(set) var days: [String: DayStat]

    private init() { days = loadJSON("stats.days", [String: DayStat].self) ?? [:] }

    func record(words: Int, seconds: Double) {
        let k = dayKey()
        var d = days[k] ?? DayStat()
        d.words += words; d.seconds += seconds; d.count += 1
        days[k] = d
        saveJSON("stats.days", days)
    }

    /// Words dictated in the current calendar month (drives the free-tier limit).
    var wordsThisMonth: Int {
        let prefix = String(dayKey().prefix(7))   // "yyyy-MM"
        return days.filter { $0.key.hasPrefix(prefix) }.values.reduce(0) { $0 + $1.words }
    }

    var totalWords: Int { days.values.reduce(0) { $0 + $1.words } }
    var totalCount: Int { days.values.reduce(0) { $0 + $1.count } }
    var totalSeconds: Double { days.values.reduce(0) { $0 + $1.seconds } }
    var avgWPM: Int { totalSeconds > 0 ? Int(Double(totalWords) / (totalSeconds / 60)) : 0 }

    /// Consecutive days (ending today or yesterday) with at least one dictation.
    var streak: Int {
        var n = 0
        var date = Date()
        // Allow the streak to still count if nothing yet today but yesterday had activity.
        if (days[dayKey(date)]?.count ?? 0) == 0 { date = date.addingTimeInterval(-86400) }
        while (days[dayKey(date)]?.count ?? 0) > 0 {
            n += 1; date = date.addingTimeInterval(-86400)
        }
        return n
    }

    /// (label, words) for the last `n` days, oldest → newest.
    func recentDays(_ n: Int = 14) -> [(label: String, words: Int)] {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return (0..<n).reversed().map { offset in
            let date = Date().addingTimeInterval(Double(-offset) * 86400)
            return (f.string(from: date), days[dayKey(date)]?.words ?? 0)
        }
    }
}

// MARK: - Dictionary (custom spellings / vocabulary)

struct DictTerm: Codable, Identifiable { var id = UUID(); var spoken: String; var written: String }

final class DictionaryStore: ObservableObject {
    static let shared = DictionaryStore()
    @Published var terms: [DictTerm] { didSet { saveJSON("dictionary.terms", terms) } }
    private init() { terms = loadJSON("dictionary.terms", [DictTerm].self) ?? [] }

    /// Comma-separated written forms, fed to the transcription model as a vocab hint.
    func hint() -> String { terms.map(\.written).filter { !$0.isEmpty }.joined(separator: ", ") }

    /// Replace spoken forms with the intended written form (case-insensitive).
    func apply(to text: String) -> String {
        var out = text
        for t in terms where !t.spoken.isEmpty {
            out = out.replacingOccurrences(of: t.spoken, with: t.written, options: [.caseInsensitive])
        }
        return out
    }
}

// MARK: - Snippets (trigger → expansion)

struct Snippet: Codable, Identifiable { var id = UUID(); var trigger: String; var expansion: String }

final class SnippetsStore: ObservableObject {
    static let shared = SnippetsStore()
    @Published var items: [Snippet] { didSet { saveJSON("snippets.items", items) } }
    private init() { items = loadJSON("snippets.items", [Snippet].self) ?? [] }

    /// Literal trigger→expansion replacement. Used only in raw/Flow mode (no AI to
    /// understand intent); AI modes use `promptContext()` instead.
    func apply(to text: String) -> String {
        var out = text
        for s in items where !s.trigger.isEmpty {
            out = out.replacingOccurrences(of: s.trigger, with: s.expansion, options: [.caseInsensitive])
        }
        return out
    }

    /// Snippet list to hand to Claude so it inserts a block ONLY when the user asks for
    /// it by intent ("put my signature here"), not just because they mention the topic.
    func promptContext() -> String {
        let valid = items.filter { !$0.trigger.isEmpty && !$0.expansion.isEmpty }
        guard !valid.isEmpty else { return "" }
        let list = valid.map { "- \"\($0.trigger)\": \($0.expansion)" }.joined(separator: "\n")
        return """


        AVAILABLE SNIPPETS (saved blocks the user may ask you to insert):
        \(list)

        Insert a snippet's content ONLY when the user explicitly asks to, by intent, \
        e.g. "put my signature here", "insert my address", "add my booking link". If the \
        user merely mentions or describes the topic without asking to insert it, do NOT \
        add the snippet. When inserting, output the snippet content verbatim at the right place.
        """
    }
}

// MARK: - Transforms (named one-shot prompts to run on text)

struct Transform: Codable, Identifiable { var id = UUID(); var name: String; var prompt: String }

final class TransformsStore: ObservableObject {
    static let shared = TransformsStore()
    @Published var items: [Transform] { didSet { saveJSON("transforms.items", items) } }
    private init() {
        items = loadJSON("transforms.items", [Transform].self) ?? [
            Transform(name: "To bullet points", prompt: "Rewrite the text as a clear bulleted list. Keep all the information."),
            Transform(name: "Shorten", prompt: "Make the text shorter and tighter without losing meaning."),
            Transform(name: "Translate to English", prompt: "Translate the text into natural English."),
            Transform(name: "Fix grammar", prompt: "Fix grammar and spelling only. Keep wording and meaning."),
        ]
    }
}

// MARK: - Scratchpad

final class Scratchpad: ObservableObject {
    static let shared = Scratchpad()
    @Published var text: String { didSet { UserDefaults.standard.set(text, forKey: "scratchpad.text") } }
    private init() { text = UserDefaults.standard.string(forKey: "scratchpad.text") ?? "" }
    func append(_ s: String) {
        if text.isEmpty { text = s } else { text += "\n\n" + s }
    }
}
