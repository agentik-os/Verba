import Foundation
import Combine

/// True when a Convex response reports success (nil data = transport failure).
/// R14: lets the notes cloud sync surface failures through VerbaLog.syncFailure
/// instead of swallowing them in a `{ _ in }` completion.
private func convexOK(_ data: Data?) -> Bool {
    guard let data,
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          obj["status"] as? String == "success" else { return false }
    return true
}

/// A saved long-form note: the raw transcript + the formatted document + which format made it.
struct NotesEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""      // user-set note title (optional; falls back to a content snippet)
    var original: String        // raw transcription
    var formatted: String       // organized document
    var formatName: String
    var audioFile: String?      // filename inside the notes folder
    var tags: [String] = []     // #hashtags for Bear-style filing
    // Per-note password protection: when locked, `formatted` holds the AES-GCM ciphertext of the
    // packed (original‖formatted) text, `original` is cleared, and `salt` is this note's own salt.
    var locked: Bool = false
    var salt: String? = nil
}

/// Local store for long-form notes (mirrors History.swift; local-only for v1).
final class NotesStore: ObservableObject {
    static let shared = NotesStore()
    @Published private(set) var entries: [NotesEntry] = []

    private let dir: URL
    private let indexURL: URL
    private let tombstoneURL: URL

    /// Persisted set of deleted note timestamps (ms, rounded). Mirrors History's intent
    /// but survives across pulls: a row the user deleted must never be re-appended by a
    /// later cloud pull, even if the server still returns it (notes:remove failed transiently).
    private var tombstones: Set<Double> = []

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Verba/Notes", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        dir = base
        indexURL = base.appendingPathComponent("index.json")
        tombstoneURL = base.appendingPathComponent("tombstones.json")
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode([NotesEntry].self, from: data) { entries = decoded }
        if let data = try? Data(contentsOf: tombstoneURL),
           let decoded = try? JSONDecoder().decode([Double].self, from: data) { tombstones = Set(decoded) }
    }

    @discardableResult
    func add(original: String, formatted: String, formatName: String, audioURL: URL?, tags: [String] = [], title: String = "") -> NotesEntry {
        var stored: String?
        if let audioURL {
            let dest = dir.appendingPathComponent(audioURL.lastPathComponent)
            try? FileManager.default.copyItem(at: audioURL, to: dest)
            stored = dest.lastPathComponent
        }
        let allTags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted))
        let entry = NotesEntry(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                               original: original, formatted: formatted, formatName: formatName, audioFile: stored, tags: allTags)
        entries.insert(entry, at: 0)
        save()
        push(entry)   // sync text to the cloud (never the audio)
        return entry
    }

    func update(_ entry: NotesEntry, formatted: String, formatName: String? = nil, tags: [String]? = nil, title: String? = nil) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        if entries[i].locked { return }   // never overwrite a locked note's ciphertext via the editor
        entries[i].formatted = formatted
        if let formatName { entries[i].formatName = formatName }
        if let title { entries[i].title = title.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let tags { entries[i].tags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted)) }
        save()
        push(entries[i])   // re-sync the edited note
    }

    // MARK: - Per-note password lock (each note has its OWN password)

    /// Encrypt a note with `password` and lock it. The title + tags stay visible (so you can find
    /// the note); the body is encrypted at rest. Returns false if already locked or crypto fails.
    @discardableResult
    func lock(_ entry: NotesEntry, password: String) -> Bool {
        guard !password.isEmpty, let i = entries.firstIndex(where: { $0.id == entry.id }), !entries[i].locked else { return false }
        let blob = NoteCrypto.pack(original: entries[i].original, formatted: entries[i].formatted)
        guard let (cipher, salt) = NoteCrypto.encrypt(blob, password: password) else { return false }
        entries[i].original = ""
        entries[i].formatted = cipher
        entries[i].salt = salt
        entries[i].locked = true
        save()
        push(entries[i])
        return true
    }

    /// Try to decrypt a locked note WITHOUT unlocking it on disk — for viewing. Returns the
    /// plaintext (original, formatted) on the right password, nil otherwise.
    func decrypt(_ entry: NotesEntry, password: String) -> (original: String, formatted: String)? {
        guard entry.locked, let salt = entry.salt,
              let plain = NoteCrypto.decrypt(entry.formatted, password: password, salt: salt) else { return nil }
        return NoteCrypto.unpack(plain)
    }

    /// Permanently remove the password: decrypt with the correct password and store as plaintext.
    @discardableResult
    func removePassword(_ entry: NotesEntry, password: String) -> Bool {
        guard let dec = decrypt(entry, password: password), let i = entries.firstIndex(where: { $0.id == entry.id }) else { return false }
        entries[i].original = dec.original
        entries[i].formatted = dec.formatted
        entries[i].salt = nil
        entries[i].locked = false
        save()
        push(entries[i])
        return true
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
        let tsMs = entry.date.timeIntervalSince1970 * 1000
        // Tombstone the deleted ts so a later pull can't resurrect it even if notes:remove
        // fails transiently on the server side. Persisted across launches.
        tombstones.insert(tsMs.rounded())
        save()
        saveTombstones()
        if !Settings.shared.proEmail.isEmpty {
            // S16: route through ConvexClient so the required device `secret` is injected.
            removeRemote(tsMs: tsMs, retry: true)
        }
    }

    /// Send notes:remove and retry once on a transient failure instead of only logging it,
    /// so a dropped delete doesn't strand the row server-side until the next manual delete.
    private func removeRemote(tsMs: Double, retry: Bool) {
        ConvexClient.call("mutation", "notes:remove",
                          ConvexClient.authedArgs(["ts": tsMs])) { [weak self] data in
            guard !convexOK(data) else { return }
            if retry {
                self?.removeRemote(tsMs: tsMs, retry: false)
            } else {
                VerbaLog.syncFailure("notes:remove")   // R14
            }
        }
    }

    private func saveTombstones() {
        let snapshot = Array(tombstones)
        let url = tombstoneURL
        DispatchQueue.global(qos: .utility).async {
            do { try JSONEncoder().encode(snapshot).write(to: url) }
            catch { VerbaLog.syncFailure("notes tombstone save", error: error) }
        }
    }

    // MARK: - Cloud sync (Convex), text-only, mirrors History.
    // All calls go through the shared ConvexClient and carry the device secret (S16).

    private func push(_ e: NotesEntry) {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.call("mutation", "notes:push", ConvexClient.authedArgs([
            "ts": e.date.timeIntervalSince1970 * 1000,
            "title": e.title,
            "original": e.original, "formatted": e.formatted, "formatName": e.formatName, "tags": e.tags,
        ])) { if !convexOK($0) { VerbaLog.syncFailure("notes:push") } }   // R14
    }

    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)   // S16: claim the account uid before pushing
        for e in entries { push(e) }
    }

    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)   // S16: claim the account uid before pulling
        ConvexClient.call("query", "notes:pull", ConvexClient.authedArgs()) { [weak self] data in
            guard let self, let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["status"] as? String == "success",
                  let arr = obj["value"] as? [[String: Any]] else {
                VerbaLog.syncFailure("notes:pull")   // R14: a failed pull was silently dropped
                return
            }
            DispatchQueue.main.async {
                // ts → index of the local entry with that timestamp (for in-place updates).
                var indexByTs: [Double: Int] = [:]
                for (i, e) in self.entries.enumerated() {
                    indexByTs[(e.date.timeIntervalSince1970 * 1000).rounded()] = i
                }
                var merged = self.entries
                var changed = false
                for r in arr {
                    let ts = (r["ts"] as? Double) ?? 0
                    // Skip rows the user deleted locally (tombstoned): never resurrect them,
                    // even if notes:remove hasn't yet taken effect server-side.
                    guard ts > 0, !self.tombstones.contains(ts.rounded()) else { continue }
                    let title = r["title"] as? String ?? ""
                    let formatted = r["formatted"] as? String ?? ""
                    let formatName = r["formatName"] as? String ?? "Note"
                    let tags = (r["tags"] as? [String]) ?? []
                    if let i = indexByTs[ts.rounded()] {
                        // Known note: pull remote edits (formatted/tags/title/formatName) in place.
                        if merged[i].formatted != formatted || merged[i].tags != tags
                            || merged[i].title != title || merged[i].formatName != formatName {
                            merged[i].formatted = formatted
                            merged[i].tags = tags
                            merged[i].formatName = formatName
                            if !title.isEmpty { merged[i].title = title }
                            changed = true
                        }
                    } else {
                        merged.append(NotesEntry(
                            date: Date(timeIntervalSince1970: ts / 1000),
                            title: title,
                            original: r["original"] as? String ?? "",
                            formatted: formatted,
                            formatName: formatName,
                            audioFile: nil,
                            tags: tags))
                        changed = true
                    }
                }
                if changed {
                    self.entries = merged.sorted { $0.date > $1.date }
                    self.save()
                }
            }
        }
    }

    func audioURL(for entry: NotesEntry) -> URL? {
        entry.audioFile.map { dir.appendingPathComponent($0) }
    }

    private func save() {
        // Snapshot on the caller (main) thread, write off-thread so a save never hitches the UI.
        let snapshot = entries
        let url = indexURL
        DispatchQueue.global(qos: .utility).async {
            do { try JSONEncoder().encode(snapshot).write(to: url) }
            catch { VerbaLog.syncFailure("notes index save", error: error) }   // R14: was silently swallowed
        }
    }
}
