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

// MARK: - Tone store (#5): a few of the user's recent messages per app, used as few-shot
// style examples so reprompts match how they actually write in that app.
enum ToneStore {
    private static let maxPerApp = 3
    private static func key(_ bundleID: String) -> String { "tone.\(bundleID)" }

    static func record(bundleID: String?, text: String) {
        guard let bundleID, !bundleID.isEmpty else { return }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 12, t.count <= 600 else { return }   // skip tiny/huge samples
        var arr = (loadJSON(key(bundleID), [String].self) ?? []).filter { $0 != t }
        arr.insert(t, at: 0)
        if arr.count > maxPerApp { arr = Array(arr.prefix(maxPerApp)) }
        saveJSON(key(bundleID), arr)
    }

    static func examples(bundleID: String?) -> [String] {
        guard let bundleID, !bundleID.isEmpty else { return [] }
        return loadJSON(key(bundleID), [String].self) ?? []
    }
}

func wordCount(_ s: String) -> Int {
    s.split { $0.isWhitespace || $0.isNewline }.count
}

private func dayKey(_ date: Date = Date()) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
    return f.string(from: date)
}

// MARK: - Stats (words / wpm / streak)

struct DayStat: Codable, Equatable { var words: Int = 0; var seconds: Double = 0; var count: Int = 0 }

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
        push(day: k)   // keep the cloud copy (Insights) in sync
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
    /// Minutes saved vs typing (~40 wpm) the same words by hand.
    var timeSavedMinutes: Int { max(0, Int(Double(totalWords) / 40.0 - totalSeconds / 60.0)) }
    var avgWordsPerDictation: Int { totalCount > 0 ? totalWords / totalCount : 0 }
    var bestDayWords: Int { days.values.map(\.words).max() ?? 0 }
    var wordsThisWeek: Int {
        (0..<7).reduce(0) { sum, off in
            sum + (days[dayKey(Date().addingTimeInterval(Double(-off) * 86400))]?.words ?? 0)
        }
    }

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

    // MARK: - Cloud sync (Convex). Insights / Total Words follow the account across Macs.
    private static let convex = "https://fortunate-aardvark-443.convex.cloud"
    private var uid: String { Settings.shared.uid }

    /// Push one day's totals to the cloud (called after each dictation).
    func push(day: String) {
        guard !Settings.shared.proEmail.isEmpty, let d = days[day] else { return }
        post("mutation", "stats:push",
             ["uid": uid, "day": day, "words": d.words, "seconds": d.seconds, "count": d.count])
    }

    /// Push every day (after sign-in, so anything dictated while signed out reaches the account).
    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        for k in days.keys { push(day: k) }
    }

    /// Pull cloud stats and merge them in (max per day), so a new Mac / reinstall restores Insights.
    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        post("query", "stats:pull", ["uid": uid]) { [weak self] data in
            guard let self, let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let arr = obj["value"] as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                var merged = self.days
                for r in arr {
                    guard let day = r["day"] as? String else { continue }
                    let cw = (r["words"] as? Int) ?? 0
                    let cs = (r["seconds"] as? Double) ?? 0
                    let cc = (r["count"] as? Int) ?? 0
                    let cur = merged[day] ?? DayStat()
                    merged[day] = DayStat(words: max(cur.words, cw),
                                          seconds: max(cur.seconds, cs),
                                          count: max(cur.count, cc))
                }
                if merged != self.days {
                    self.days = merged
                    saveJSON("stats.days", merged)
                }
            }
        }
    }

    private func post(_ kind: String, _ path: String, _ args: [String: Any], _ cb: @escaping (Data?) -> Void = { _ in }) {
        guard let url = URL(string: "\(Self.convex)/api/\(kind)") else { cb(nil); return }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }
}

// MARK: - Dictionary (custom spellings / vocabulary)

struct DictTerm: Codable, Identifiable {
    var id = UUID()
    var spoken: String
    var written: String
    var auto: Bool = false          // true = Verba auto-learned it from an edit

    init(id: UUID = UUID(), spoken: String, written: String, auto: Bool = false) {
        self.id = id; self.spoken = spoken; self.written = written; self.auto = auto
    }
    // Decode old saved dictionaries (no `auto` key) without losing them.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        spoken = try c.decode(String.self, forKey: .spoken)
        written = try c.decode(String.self, forKey: .written)
        auto = try c.decodeIfPresent(Bool.self, forKey: .auto) ?? false
    }
}

final class DictionaryStore: ObservableObject {
    static let shared = DictionaryStore()
    @Published var terms: [DictTerm] { didSet { saveJSON("dictionary.terms", terms) } }
    private init() { terms = loadJSON("dictionary.terms", [DictTerm].self) ?? [] }

    /// Comma-separated written forms, fed to the transcription model as a vocab hint.
    func hint() -> String { terms.map(\.written).filter { !$0.isEmpty }.joined(separator: ", ") }

    /// Replace spoken forms with the intended written form (case-insensitive).
    func apply(to text: String) -> String {
        var out = text
        for t in terms where !t.spoken.isEmpty && !t.written.isEmpty {
            out = out.replacingOccurrences(of: t.spoken, with: t.written, options: [.caseInsensitive])
        }
        return out
    }

    /// Auto-learn from a MANUAL post-paste edit: `pasted` is what Verba inserted, `current` is
    /// the field's text now (read back via Accessibility). We locate the pasted segment inside
    /// the current text (it may have moved or been lightly edited) and learn the word swaps.
    /// Conservative on purpose: the matched window must stay ≥60% identical (a correction, not a
    /// rewrite), then `learn` applies its own per-word guards.
    func learnFromEdit(pasted: String, current: String) {
        let tokens: (String) -> [String] = { $0.split { $0 == " " || $0 == "\n" || $0 == "\t" }.map(String.init) }
        let pasted = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard pasted.count >= 3, !current.isEmpty else { return }
        if current.contains(pasted) { return }                       // unedited → nothing to learn
        let pw = tokens(pasted), cw = tokens(current)
        let n = pw.count
        guard n >= 1, cw.count >= n, cw.count <= 4000 else { return }
        var best: (score: Int, window: [String])? = nil
        for start in 0...(cw.count - n) {
            let window = Array(cw[start..<start + n])
            var identical = 0
            for (a, b) in zip(pw, window) where a.lowercased() == b.lowercased() { identical += 1 }
            if best == nil || identical > best!.score { best = (identical, window) }
        }
        guard let best, best.score < n, Double(best.score) / Double(n) >= 0.6 else { return }
        learn(from: pw.joined(separator: " "), edited: best.window.joined(separator: " "))
    }

    /// Auto-learn: when the user fixes a word in the review screen, remember the correction
    /// so Verba applies it automatically next time. Only handles in-place single-word swaps.
    func learn(from before: String, edited after: String) {
        let a = before.split(separator: " ").map(String.init)
        let b = after.split(separator: " ").map(String.init)
        guard a.count == b.count, a.count > 0 else { return }   // same length = simple swaps only
        let strip: (String) -> String = { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
        for (x0, y0) in zip(a, b) {
            let x = strip(x0), y = strip(y0)
            guard x.lowercased() != y.lowercased(),                       // actually changed
                  x.count >= 3, y.count >= 2, x.count <= 30,             // sane word lengths
                  x.allSatisfy({ $0.isLetter }), y.allSatisfy({ $0.isLetter }),
                  editDistance(x.lowercased(), y.lowercased()) <= 3,     // a correction, not a rewrite
                  !terms.contains(where: { $0.spoken.lowercased() == x.lowercased() }) else { continue }
            terms.append(DictTerm(spoken: x, written: y, auto: true))
        }
    }

    private func editDistance(_ s: String, _ t: String) -> Int {
        let s = Array(s), t = Array(t)
        var d = Array(0...t.count)
        for i in 1...max(1, s.count) where !s.isEmpty {
            var prev = d[0]; d[0] = i
            for j in 1...t.count {
                let tmp = d[j]
                d[j] = s[i-1] == t[j-1] ? prev : min(prev, d[j], d[j-1]) + 1
                prev = tmp
            }
        }
        return d[t.count]
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

// MARK: - To-dos (Projects ▸ Tasks ▸ Sub-tasks)

struct TodoSubtask: Codable, Identifiable { var id = UUID(); var title: String; var done: Bool = false }
struct TodoTask: Codable, Identifiable { var id = UUID(); var title: String; var done: Bool = false; var subtasks: [TodoSubtask] = []; var deadline: Date? = nil }
struct TodoProject: Codable, Identifiable {
    var id = UUID()
    var name: String
    var tasks: [TodoTask] = []
    var tags: [String] = []

    init(id: UUID = UUID(), name: String, tasks: [TodoTask] = [], tags: [String] = []) {
        self.id = id; self.name = name; self.tasks = tasks; self.tags = tags
    }
    // Decode old saved projects (no `tags` key) without losing them.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        tasks = try c.decodeIfPresent([TodoTask].self, forKey: .tasks) ?? []
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

/// Voice-first to-dos, organized by project. Each project holds tasks, each task
/// holds sub-tasks. Persisted like the other small stores.
final class TodoStore: ObservableObject {
    static let shared = TodoStore()
    @Published var projects: [TodoProject] { didSet { saveJSON("todos.projects", projects) } }
    private init() { projects = loadJSON("todos.projects", [TodoProject].self) ?? [] }

    // MARK: project ops
    @discardableResult
    func addProject(_ name: String = "New project") -> UUID {
        let p = TodoProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New project" : name)
        projects.append(p)
        return p.id
    }
    func removeProject(_ id: UUID) { projects.removeAll { $0.id == id } }

    // MARK: tag ops
    func addTag(_ projectID: UUID, _ tag: String) {
        let t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let pi = projects.firstIndex(where: { $0.id == projectID }),
              !projects[pi].tags.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) else { return }
        projects[pi].tags.append(t)
    }
    func removeTag(_ projectID: UUID, _ tag: String) {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pi].tags.removeAll { $0 == tag }
    }
    /// All distinct tags across projects, sorted (case-insensitive), for the filter bar.
    var allTags: [String] {
        var seen = Set<String>(); var out: [String] = []
        for p in projects { for t in p.tags where seen.insert(t.lowercased()).inserted { out.append(t) } }
        return out.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // MARK: task ops
    func addTask(_ projectID: UUID, _ title: String = "") {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pi].tasks.append(TodoTask(title: title))
    }
    func removeTask(_ projectID: UUID, _ taskID: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pi].tasks.removeAll { $0.id == taskID }
    }

    /// Set (or clear, with nil) a task's deadline.
    func setDeadline(_ projectID: UUID, _ taskID: UUID, _ deadline: Date?) {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }),
              let ti = projects[pi].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        projects[pi].tasks[ti].deadline = deadline
    }

    // MARK: sub-task ops
    func addSubtask(_ projectID: UUID, _ taskID: UUID, _ title: String = "") {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }),
              let ti = projects[pi].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        projects[pi].tasks[ti].subtasks.append(TodoSubtask(title: title))
    }

    /// Insert a project produced by the agent (name + tasks, each with optional sub-tasks
    /// and an optional deadline).
    func addGenerated(name: String, tasks: [(String, [String], Date?)]) {
        var p = TodoProject(name: name)
        p.tasks = tasks.map { t in TodoTask(title: t.0, subtasks: t.1.map { TodoSubtask(title: $0) }, deadline: t.2) }
        projects.append(p)
    }

    /// Append agent-built tasks (each with optional sub-tasks and deadline) to an existing project.
    func appendTasks(_ projectID: UUID, _ tasks: [(String, [String], Date?)]) {
        guard let pi = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pi].tasks.append(contentsOf: tasks.map { t in
            TodoTask(title: t.0, subtasks: t.1.map { TodoSubtask(title: $0) }, deadline: t.2)
        })
    }

    // MARK: completion ops
    /// Mark a task done by id (also checks every sub-task so progress reflects completion).
    func markDone(taskID: UUID, done: Bool = true) {
        for pi in projects.indices {
            if let ti = projects[pi].tasks.firstIndex(where: { $0.id == taskID }) {
                projects[pi].tasks[ti].done = done
                for si in projects[pi].tasks[ti].subtasks.indices { projects[pi].tasks[ti].subtasks[si].done = done }
                return
            }
        }
    }

    /// Mark a single sub-task done by id; if all its siblings end up done, the parent task is marked done too.
    func markSubtaskDone(subtaskID: UUID, done: Bool = true) {
        for pi in projects.indices {
            for ti in projects[pi].tasks.indices {
                if let si = projects[pi].tasks[ti].subtasks.firstIndex(where: { $0.id == subtaskID }) {
                    projects[pi].tasks[ti].subtasks[si].done = done
                    if done, projects[pi].tasks[ti].subtasks.allSatisfy(\.done) { projects[pi].tasks[ti].done = true }
                    return
                }
            }
        }
    }

    /// Done-progress for a project (completed leaf items / total), for the header chip.
    func progress(_ p: TodoProject) -> (done: Int, total: Int) {
        var done = 0, total = 0
        for t in p.tasks {
            if t.subtasks.isEmpty { total += 1; if t.done { done += 1 } }
            else { for s in t.subtasks { total += 1; if s.done { done += 1 } } }
        }
        return (done, total)
    }
}
