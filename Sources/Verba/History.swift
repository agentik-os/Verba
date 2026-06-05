import Foundation
import Combine

/// One dictation: the raw transcript + Claude's restructured version, kept side by
/// side like Wispr Flow's backup. The audio file is moved into the history folder.
struct HistoryEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var original: String        // raw transcription
    var reprompted: String      // Claude-restructured (== original if reprompt was off)
    var profileName: String
    var engine: String
    var audioFile: String?      // filename inside the history folder
}

final class History: ObservableObject {
    static let shared = History()
    @Published private(set) var entries: [HistoryEntry] = []

    private let dir: URL
    private let indexURL: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/History", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        dir = base
        indexURL = base.appendingPathComponent("index.json")
        load()
    }

    var audioFolder: URL { dir }

    func add(original: String, reprompted: String, profileName: String, engine: String, audioURL: URL?) {
        var stored: String?
        if let audioURL {
            let dest = dir.appendingPathComponent(audioURL.lastPathComponent)
            try? FileManager.default.copyItem(at: audioURL, to: dest)
            stored = dest.lastPathComponent
        }
        let entry = HistoryEntry(original: original, reprompted: reprompted,
                                 profileName: profileName, engine: engine, audioFile: stored)
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: HistoryEntry) {
        if let f = entry.audioFile {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
        }
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        for e in entries { if let f = e.audioFile { try? FileManager.default.removeItem(at: dir.appendingPathComponent(f)) } }
        entries.removeAll()
        save()
    }

    func audioURL(for entry: HistoryEntry) -> URL? {
        entry.audioFile.map { dir.appendingPathComponent($0) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) { try? data.write(to: indexURL) }
    }
}
