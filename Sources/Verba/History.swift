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
        push(entry)   // sync to the cloud (text only, never the audio)
    }

    // MARK: - Cloud sync (Convex). Syncs the text of each dictation across the user's Macs.
    private static let convex = "https://fortunate-aardvark-443.convex.cloud"
    private var uid: String { Settings.shared.uid }

    private func push(_ e: HistoryEntry) {
        guard !Settings.shared.proEmail.isEmpty else { return }   // only for signed-in users
        post("mutation", "history:push", [
            "uid": uid, "ts": e.date.timeIntervalSince1970 * 1000,
            "original": e.original, "reprompted": e.reprompted,
            "profileName": e.profileName, "engine": e.engine,
        ]) { _ in }
    }

    /// Push every local entry to the cloud (used after sign-in so anything dictated while
    /// signed out reaches the account). Server dedups by (uid, ts).
    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        for e in entries { push(e) }
    }

    /// Pull cloud history and merge anything not already here (dedup by timestamp).
    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        post("query", "history:pull", ["uid": uid]) { [weak self] data in
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
                    merged.append(HistoryEntry(
                        date: Date(timeIntervalSince1970: ts / 1000),
                        original: r["original"] as? String ?? "",
                        reprompted: r["reprompted"] as? String ?? "",
                        profileName: r["profileName"] as? String ?? "",
                        engine: r["engine"] as? String ?? "", audioFile: nil))
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

    func delete(_ entry: HistoryEntry) {
        if let f = entry.audioFile {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
        }
        entries.removeAll { $0.id == entry.id }
        save()
        // Tombstone it in the cloud so it doesn't resurrect on the next sync.
        if !Settings.shared.proEmail.isEmpty {
            post("mutation", "history:remove", ["uid": uid, "ts": entry.date.timeIntervalSince1970 * 1000]) { _ in }
        }
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
