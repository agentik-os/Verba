import Foundation
import Combine

/// A saved file-import transcript: the transcribed text + where it came from, with Bear-style
/// tags and an optional free-form note. Mirrors NotesEntry / HistoryEntry.
struct TranscriptEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var text: String            // the transcribed text
    var sourceName: String      // original file name it was imported from
    var tags: [String] = []     // #hashtags for filing/filtering
    var note: String = ""       // optional free-form note
}

/// Local store for imported transcripts (mirrors NotesStore; local-only — no cloud sync).
final class TranscriptStore: ObservableObject {
    static let shared = TranscriptStore()
    @Published private(set) var entries: [TranscriptEntry] = []

    private let indexURL: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/Transcripts", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        indexURL = base.appendingPathComponent("index.json")
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode([TranscriptEntry].self, from: data) { entries = decoded }
    }

    @discardableResult
    func add(text: String, sourceName: String, tags: [String] = [], note: String = "") -> TranscriptEntry {
        let allTags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: text))
        let entry = TranscriptEntry(text: text, sourceName: sourceName, tags: allTags, note: note)
        entries.insert(entry, at: 0)
        save()
        return entry
    }

    func update(_ entry: TranscriptEntry, text: String? = nil, tags: [String]? = nil, note: String? = nil) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        if let text { entries[i].text = text }
        if let note { entries[i].note = note }
        if let tags { entries[i].tags = NotesStore.mergeTags(tags) }
        save()
    }

    func delete(_ entry: TranscriptEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    /// All distinct tags across saved transcripts (for the filter bar), most common first.
    var allTags: [String] {
        var count: [String: Int] = [:]
        for e in entries { for t in e.tags { count[t, default: 0] += 1 } }
        return count.keys.sorted { (count[$0] ?? 0, $1) > (count[$1] ?? 0, $0) }
    }

    private func save() {
        let snapshot = entries
        let url = indexURL
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: url) }
        }
    }
}
