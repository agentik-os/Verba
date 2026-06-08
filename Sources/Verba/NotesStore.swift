import Foundation
import Combine

/// A saved long-form note: the raw transcript + the formatted document + which format made it.
struct NotesEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var original: String        // raw transcription
    var formatted: String       // organized document
    var formatName: String
    var audioFile: String?      // filename inside the notes folder
    var tags: [String] = []     // #hashtags for Bear-style filing
}

/// Local store for long-form notes (mirrors History.swift; local-only for v1).
final class NotesStore: ObservableObject {
    static let shared = NotesStore()
    @Published private(set) var entries: [NotesEntry] = []

    private let dir: URL
    private let indexURL: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/Notes", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        dir = base
        indexURL = base.appendingPathComponent("index.json")
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode([NotesEntry].self, from: data) { entries = decoded }
    }

    @discardableResult
    func add(original: String, formatted: String, formatName: String, audioURL: URL?, tags: [String] = []) -> NotesEntry {
        var stored: String?
        if let audioURL {
            let dest = dir.appendingPathComponent(audioURL.lastPathComponent)
            try? FileManager.default.copyItem(at: audioURL, to: dest)
            stored = dest.lastPathComponent
        }
        let allTags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted))
        let entry = NotesEntry(original: original, formatted: formatted, formatName: formatName, audioFile: stored, tags: allTags)
        entries.insert(entry, at: 0)
        save()
        push(entry)   // sync text to the cloud (never the audio)
        return entry
    }

    func update(_ entry: NotesEntry, formatted: String, formatName: String? = nil, tags: [String]? = nil) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[i].formatted = formatted
        if let formatName { entries[i].formatName = formatName }
        if let tags { entries[i].tags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted)) }
        save()
        push(entries[i])   // re-sync the edited note
    }

    /// All distinct tags across saved notes (for the filter bar), most common first.
    var allTags: [String] {
        var count: [String: Int] = [:]
        for e in entries { for t in e.tags { count[t, default: 0] += 1 } }
        return count.keys.sorted { (count[$0] ?? 0, $1) > (count[$1] ?? 0, $0) }
    }

    /// Extract #hashtags (Bear-style) from text.
    static func hashtags(in text: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: "#([\\p{L}0-9_/-]+)") else { return [] }
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: 1)).lowercased()
        }
    }

    static func mergeTags(_ tags: [String]) -> [String] {
        var seen = Set<String>(); var out: [String] = []
        for t in tags { let c = t.trimmingCharacters(in: CharacterSet(charactersIn: " #")).lowercased()
            if !c.isEmpty, !seen.contains(c) { seen.insert(c); out.append(c) } }
        return out
    }

    func delete(_ entry: NotesEntry) {
        if let f = entry.audioFile { try? FileManager.default.removeItem(at: dir.appendingPathComponent(f)) }
        entries.removeAll { $0.id == entry.id }
        save()
        if !Settings.shared.proEmail.isEmpty {
            post("mutation", "notes:remove", ["uid": uid, "ts": entry.date.timeIntervalSince1970 * 1000]) { _ in }
        }
    }

    // MARK: - Cloud sync (Convex), text-only, mirrors History.
    private static let convex = "https://fortunate-aardvark-443.convex.cloud"
    private var uid: String { Settings.shared.uid }

    private func push(_ e: NotesEntry) {
        guard !Settings.shared.proEmail.isEmpty else { return }
        post("mutation", "notes:push", [
            "uid": uid, "ts": e.date.timeIntervalSince1970 * 1000,
            "original": e.original, "formatted": e.formatted, "formatName": e.formatName, "tags": e.tags,
        ]) { _ in }
    }

    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        for e in entries { push(e) }
    }

    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        post("query", "notes:pull", ["uid": uid]) { [weak self] data in
            guard let self, let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let arr = obj["value"] as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                let known = Set(self.entries.map { ($0.date.timeIntervalSince1970 * 1000).rounded() })
                var merged = self.entries
                for r in arr {
                    let ts = (r["ts"] as? Double) ?? 0
                    guard ts > 0, !known.contains(ts.rounded()) else { continue }
                    merged.append(NotesEntry(
                        date: Date(timeIntervalSince1970: ts / 1000),
                        original: r["original"] as? String ?? "",
                        formatted: r["formatted"] as? String ?? "",
                        formatName: r["formatName"] as? String ?? "Note",
                        audioFile: nil,
                        tags: (r["tags"] as? [String]) ?? []))
                }
                if merged.count != self.entries.count {
                    self.entries = merged.sorted { $0.date > $1.date }
                    self.save()
                }
            }
        }
    }

    private func post(_ kind: String, _ path: String, _ args: [String: Any], _ cb: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(Self.convex)/api/\(kind)") else { cb(nil); return }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        URLSession.shared.dataTask(with: req) { d, _, _ in cb(d) }.resume()
    }

    func audioURL(for entry: NotesEntry) -> URL? {
        entry.audioFile.map { dir.appendingPathComponent($0) }
    }

    private func save() {
        // Snapshot on the caller (main) thread, write off-thread so a save never hitches the UI.
        let snapshot = entries
        let url = indexURL
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: url) }
        }
    }
}
