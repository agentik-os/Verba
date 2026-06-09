import Foundation
import Combine

/// True when a ConvexClient response reports success (nil data = transport failure).
/// R14: lets every cloud-sync call surface failures through VerbaLog.syncFailure
/// instead of swallowing them in a `{ _ in }` completion.
private func convexOK(_ data: Data?) -> Bool {
    guard let data,
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          obj["status"] as? String == "success" else { return false }
    return true
}

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
        pruneExpired()
    }

    var audioFolder: URL { dir }

    func add(original: String, reprompted: String, profileName: String, engine: String, audioURL: URL?) {
        guard Settings.shared.saveHistory else { return }   // S14: history off → nothing on disk, no audio copy, no cloud push
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
    // All calls go through the shared ConvexClient and carry the device secret (S16).

    private func push(_ e: HistoryEntry) {
        guard !Settings.shared.proEmail.isEmpty else { return }   // only for signed-in users
        ConvexClient.call("mutation", "history:push", ConvexClient.authedArgs([
            "ts": e.date.timeIntervalSince1970 * 1000,
            "original": e.original, "reprompted": e.reprompted,
            "profileName": e.profileName, "engine": e.engine,
        ])) { if !convexOK($0) { VerbaLog.syncFailure("history:push") } }   // R14
    }

    /// Push every local entry to the cloud (used after sign-in so anything dictated while
    /// signed out reaches the account). Server dedups by (uid, ts).
    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)
        for e in entries { push(e) }
    }

    /// Pull cloud history and merge anything not already here (dedup by timestamp).
    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)
        ConvexClient.call("query", "history:pull", ConvexClient.authedArgs()) { [weak self] data in
            guard let self, let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let arr = obj["value"] as? [[String: Any]] else {
                VerbaLog.syncFailure("history:pull")   // R14: a failed pull was silently dropped
                return
            }
            DispatchQueue.main.async {
                // Retention (S14): never merge back rows older than the local retention window.
                let days = Settings.shared.historyRetentionDays
                let cutoffMs = days > 0 ? (Date().timeIntervalSince1970 - Double(days) * 86400) * 1000 : 0
                let known = Set(self.entries.map { ($0.date.timeIntervalSince1970 * 1000).rounded() })
                var merged = self.entries
                for r in arr {
                    let ts = (r["ts"] as? Double) ?? 0
                    guard ts > 0, ts >= cutoffMs, !known.contains(ts.rounded()) else { continue }
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

    func delete(_ entry: HistoryEntry) {
        if let f = entry.audioFile {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
        }
        entries.removeAll { $0.id == entry.id }
        save()
        // Tombstone it in the cloud so it doesn't resurrect on the next sync.
        if !Settings.shared.proEmail.isEmpty {
            ConvexClient.call("mutation", "history:remove",
                              ConvexClient.authedArgs(["ts": entry.date.timeIntervalSince1970 * 1000])) {
                if !convexOK($0) { VerbaLog.syncFailure("history:remove") }   // R14
            }
        }
    }

    func clear() {
        for e in entries { if let f = e.audioFile { try? FileManager.default.removeItem(at: dir.appendingPathComponent(f)) } }
        entries.removeAll()
        save()
        // S10: wipe the cloud copy WITH tombstones so other Macs don't resurrect it.
        if !Settings.shared.proEmail.isEmpty {
            ConvexClient.call("mutation", "history:wipe", ConvexClient.authedArgs()) {
                if !convexOK($0) { VerbaLog.syncFailure("history:wipe") }   // R14
            }
        }
    }

    /// S14 retention: drop local entries older than the retention window (audio included)
    /// and, when signed in, tombstone-prune the same rows server-side. Called on launch.
    func pruneExpired() {
        let days = Settings.shared.historyRetentionDays
        guard days > 0 else { return }
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        let expired = entries.filter { $0.date < cutoff }
        guard !expired.isEmpty else {
            // Still prune the cloud copy: another Mac may hold older rows for this account.
            if !Settings.shared.proEmail.isEmpty {
                ConvexClient.call("mutation", "history:prune",
                                  ConvexClient.authedArgs(["beforeTs": cutoff.timeIntervalSince1970 * 1000])) {
                    if !convexOK($0) { VerbaLog.syncFailure("history:prune") }   // R14
                }
            }
            return
        }
        for e in expired { if let f = e.audioFile { try? FileManager.default.removeItem(at: dir.appendingPathComponent(f)) } }
        entries.removeAll { $0.date < cutoff }
        save()
        if !Settings.shared.proEmail.isEmpty {
            ConvexClient.call("mutation", "history:prune",
                              ConvexClient.authedArgs(["beforeTs": cutoff.timeIntervalSince1970 * 1000])) {
                if !convexOK($0) { VerbaLog.syncFailure("history:prune") }   // R14
            }
        }
    }

    func audioURL(for entry: HistoryEntry) -> URL? {
        entry.audioFile.map { dir.appendingPathComponent($0) }
    }

    /// Replace the restructured text of an entry (used by "Re-run" in History).
    func updateReprompted(_ entry: HistoryEntry, text: String) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[i].reprompted = text
        save()
        if !Settings.shared.proEmail.isEmpty {
            ConvexClient.call("mutation", "history:push", ConvexClient.authedArgs([
                "ts": entries[i].date.timeIntervalSince1970 * 1000,
                "original": entries[i].original, "reprompted": text,
                "profileName": entries[i].profileName, "engine": entries[i].engine,
            ])) { if !convexOK($0) { VerbaLog.syncFailure("history:push (re-run)") } }   // R14
        }
    }

    // MARK: - Storage / cache (audio files + temp recording buffers)

    /// Total bytes used by stored dictation audio plus the temporary recording buffers.
    func audioCacheBytes() -> Int64 {
        var total: Int64 = 0
        for d in [dir, Self.tempDir] {
            guard let items = try? FileManager.default.contentsOfDirectory(at: d, includingPropertiesForKeys: [.fileSizeKey]) else { continue }
            for u in items where u.pathExtension.lowercased() == "wav" || u.pathExtension.lowercased() == "caf" || u.pathExtension.lowercased() == "m4a" {
                total += Int64((try? u.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
        }
        return total
    }

    /// Delete every stored audio file and temp buffer, but KEEP the history text entries
    /// (they just lose their playable audio). This is the "free up disk" action.
    func clearAudioCache() {
        for e in entries where e.audioFile != nil {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(e.audioFile!))
        }
        entries = entries.map { var c = $0; c.audioFile = nil; return c }
        save()
        // Wipe the temporary recording buffers too.
        if let items = try? FileManager.default.contentsOfDirectory(at: Self.tempDir, includingPropertiesForKeys: nil) {
            for u in items { try? FileManager.default.removeItem(at: u) }
        }
    }

    private static var tempDir: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Verba", isDirectory: true)
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        do { try JSONEncoder().encode(entries).write(to: indexURL) }
        catch { VerbaLog.syncFailure("history index save", error: error) }   // R14: was silently swallowed
    }
}
