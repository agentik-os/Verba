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
    // Version clock for sync: bumped on every local edit, compared on pull/push so a stale
    // copy (cloud or local) can never overwrite a newer one. Optional so pre-existing
    // index.json files still decode; nil falls back to `date` (creation = last edit).
    var updatedAt: Date? = nil

    init(id: UUID = UUID(), date: Date = Date(), title: String = "", original: String,
         formatted: String, formatName: String, audioFile: String? = nil, tags: [String] = [],
         locked: Bool = false, salt: String? = nil, updatedAt: Date? = nil) {
        self.id = id; self.date = date; self.title = title; self.original = original
        self.formatted = formatted; self.formatName = formatName; self.audioFile = audioFile
        self.tags = tags; self.locked = locked; self.salt = salt; self.updatedAt = updatedAt
    }

    // Schema-evolution-proof decoding. Swift's synthesized Codable REQUIRES every
    // non-optional key even when the property has a default, so each new field added to
    // NotesEntry made every pre-existing index.json fail to decode → the notes list came
    // up EMPTY and the next save overwrote the file (notes lost — the Jun 12 '26 `locked`
    // addition did exactly this). Every field is decodeIfPresent so an index.json written
    // by ANY older build always decodes.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        date = (try? c.decodeIfPresent(Date.self, forKey: .date)) ?? Date()
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        original = (try? c.decodeIfPresent(String.self, forKey: .original)) ?? ""
        formatted = (try? c.decodeIfPresent(String.self, forKey: .formatted)) ?? ""
        formatName = (try? c.decodeIfPresent(String.self, forKey: .formatName)) ?? "Note"
        audioFile = try? c.decodeIfPresent(String.self, forKey: .audioFile)
        tags = (try? c.decodeIfPresent([String].self, forKey: .tags)) ?? []
        locked = (try? c.decodeIfPresent(Bool.self, forKey: .locked)) ?? false
        salt = try? c.decodeIfPresent(String.self, forKey: .salt)
        updatedAt = try? c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
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
        if let data = try? Data(contentsOf: indexURL) {
            if let decoded = try? JSONDecoder().decode([NotesEntry].self, from: data) {
                entries = decoded
            } else if !data.isEmpty {
                // Never let an undecodable index be silently clobbered by the next save():
                // park a rescue copy first so the notes remain recoverable, then start empty.
                let rescue = base.appendingPathComponent("index.rescue-\(Int(Date().timeIntervalSince1970)).json")
                try? data.write(to: rescue)
                VerbaLog.syncFailure("notes index decode — rescued to \(rescue.lastPathComponent)")
            }
        }
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
        Gamification.shared.flag(.savedNote)
        if !allTags.isEmpty { Gamification.shared.flag(.taggedNote) }
        return entry
    }

    /// Returns true only when the edit was actually committed. A locked note returns false here —
    /// the editor must route locked edits through updateUnlockedNote(...) so they get re-encrypted
    /// (otherwise edits were silently dropped while the UI still flashed "Saved" — data loss).
    @discardableResult
    func update(_ entry: NotesEntry, formatted: String, formatName: String? = nil, tags: [String]? = nil, title: String? = nil) -> Bool {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return false }
        if entries[i].locked { return false }   // locked notes go through updateUnlockedNote (re-encrypt)
        entries[i].formatted = formatted
        if let formatName { entries[i].formatName = formatName }
        if let title { entries[i].title = title.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let tags { entries[i].tags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted)) }
        entries[i].updatedAt = Date()
        save()
        push(entries[i])   // re-sync the edited note
        return true
    }

    /// Commit an edit to a note that's locked but unlocked THIS session: re-encrypt the new
    /// plaintext with the note's own password (key = SHA-256(salt ‖ password)) so the body stays
    /// ciphertext at rest. Title + tags stay in clear (so the note is findable). Returns false if
    /// the note isn't locked, the password is empty, or crypto fails.
    @discardableResult
    func updateUnlockedNote(_ entry: NotesEntry, original: String, formatted: String,
                            formatName: String? = nil, tags: [String]? = nil, title: String? = nil,
                            password: String) -> Bool {
        guard !password.isEmpty, let i = entries.firstIndex(where: { $0.id == entry.id }), entries[i].locked else { return false }
        let blob = NoteCrypto.pack(original: original, formatted: formatted)
        guard let (cipher, salt) = NoteCrypto.encrypt(blob, password: password) else { return false }
        entries[i].original = ""          // ciphertext-only at rest
        entries[i].formatted = cipher
        entries[i].salt = salt
        if let formatName { entries[i].formatName = formatName }
        if let title { entries[i].title = title.trimmingCharacters(in: .whitespacesAndNewlines) }
        // Tags are visible while locked, so extract #hashtags from the PLAINTEXT before encrypting.
        if let tags { entries[i].tags = NotesStore.mergeTags(tags + NotesStore.hashtags(in: formatted)) }
        entries[i].updatedAt = Date()
        save()
        push(entries[i])
        return true
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
        entries[i].updatedAt = Date()
        save()
        push(entries[i])
        Gamification.shared.flag(.lockedNote)
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
        entries[i].updatedAt = Date()
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
        var args: [String: Any] = [
            "ts": e.date.timeIntervalSince1970 * 1000,
            "title": e.title,
            "original": e.original, "formatted": e.formatted, "formatName": e.formatName, "tags": e.tags,
            "locked": e.locked,
            "updatedAt": (e.updatedAt ?? e.date).timeIntervalSince1970 * 1000,
        ]
        // Sync the per-note salt so the account's other devices (Mac, iPhone) can decrypt
        // this note with ITS password — the derived key itself never leaves any device.
        if let salt = e.salt { args["salt"] = salt }
        ConvexClient.call("mutation", "notes:push", ConvexClient.authedArgs(args)) {
            if !convexOK($0) { VerbaLog.syncFailure("notes:push") }   // R14
        }
    }

    func pushAll() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)   // S16: claim the account uid before pushing
        for e in entries { push(e) }
    }

    func syncFromCloud() {
        guard !Settings.shared.proEmail.isEmpty else { return }
        ConvexClient.registerDevice(token: AuthToken.current)   // S16: claim the account uid before pulling
        // Propagate deletions from the account's OTHER devices FIRST, THEN pull. notes:tombstones
        // and notes:pull must NOT race: if the pull block ran before the tombstone merge, a note
        // deleted elsewhere could be re-adopted AND re-pushed by the reconcile pass, resurrecting
        // it server-side. We serialize the pull inside the tombstones completion, after the merge.
        ConvexClient.call("query", "notes:tombstones", ConvexClient.authedArgs()) { [weak self] data in
            guard let self else { return }
            let cloud: Set<Double> = {
                guard let data,
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      obj["status"] as? String == "success",
                      let arr = obj["value"] as? [Any] else { return [] }   // additive query absent/failed → skip merge, still pull
                return Set(arr.compactMap { ($0 as? NSNumber)?.doubleValue.rounded() })
            }()
            DispatchQueue.main.async {
                let fresh = cloud.subtracting(self.tombstones)
                if !fresh.isEmpty {
                    self.tombstones.formUnion(fresh)
                    let doomed = self.entries.filter { fresh.contains(($0.date.timeIntervalSince1970 * 1000).rounded()) }
                    for e in doomed {
                        if let f = e.audioFile { try? FileManager.default.removeItem(at: self.dir.appendingPathComponent(f)) }
                    }
                    if !doomed.isEmpty {
                        self.entries.removeAll { e in doomed.contains { $0.id == e.id } }
                        self.save()
                    }
                    self.saveTombstones()
                }
                self.pullFromCloud()   // pull AFTER cloud deletions merged → resurrect-guard + reconcile see them
            }
        }
    }

    /// Pull cloud notes, adopt strictly-newer remote edits in place, and reconcile (re-push any
    /// local note the cloud is missing or holds an older version of). Always runs AFTER the
    /// tombstone merge (see syncFromCloud) so a note deleted elsewhere is never resurrected.
    private func pullFromCloud() {
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
                    let locked = (r["locked"] as? Bool) ?? false
                    let salt = r["salt"] as? String
                    let cloudUpd = (r["updatedAt"] as? Double) ?? ts
                    if let i = indexByTs[ts.rounded()] {
                        // Known note: pull remote edits (formatted/tags/title/formatName) in place —
                        // but ONLY when the cloud copy is strictly newer (version guard). A stale
                        // cloud row (e.g. local edits whose push failed) must never overwrite newer
                        // local content; the reconcile pass below re-pushes local-newer notes instead.
                        // Legacy pairs (neither side has a clock yet) keep the historical
                        // cloud-wins behavior so pre-clock edits still propagate.
                        let localUpd = (merged[i].updatedAt ?? merged[i].date).timeIntervalSince1970 * 1000
                        let legacyPair = r["updatedAt"] == nil && merged[i].updatedAt == nil
                        guard cloudUpd > localUpd.rounded() || legacyPair else { continue }
                        if merged[i].formatted != formatted || merged[i].tags != tags
                            || merged[i].title != title || merged[i].formatName != formatName
                            || merged[i].locked != locked {
                            merged[i].formatted = formatted
                            merged[i].tags = tags
                            merged[i].formatName = formatName
                            merged[i].title = title   // adopt as-is: the guard proved cloud is newer, so a cleared title clears everywhere
                            // Adopt a lock made on another device (or an unlock): the
                            // ciphertext travels in `formatted`, the note's salt alongside.
                            merged[i].locked = locked
                            merged[i].salt = salt
                            if locked { merged[i].original = "" }
                            else if let original = r["original"] as? String { merged[i].original = original }
                            changed = true
                        }
                        if !legacyPair {
                            merged[i].updatedAt = Date(timeIntervalSince1970: cloudUpd / 1000)
                            changed = true   // the guard ensured cloudUpd is strictly newer than the stored clock
                        }
                    } else {
                        merged.append(NotesEntry(
                            date: Date(timeIntervalSince1970: ts / 1000),
                            title: title,
                            original: r["original"] as? String ?? "",
                            formatted: formatted,
                            formatName: formatName,
                            audioFile: nil,
                            tags: tags,
                            locked: locked,
                            salt: salt,
                            updatedAt: Date(timeIntervalSince1970: cloudUpd / 1000)))
                        changed = true
                    }
                }
                if changed {
                    self.entries = merged.sorted { $0.date > $1.date }
                    self.save()
                }
                // Reconcile (push-back): any local note the cloud is missing — or only holds an
                // older version of — is re-pushed now. A failed notes:push (offline, transient
                // server error, the Jun 10–12 '26 validator outage) can therefore never strand a
                // note on one device: the next pull self-heals the account.
                var cloudUpdByTs: [Double: Double] = [:]
                for r in arr {
                    let ts = (r["ts"] as? Double) ?? 0
                    guard ts > 0 else { continue }
                    cloudUpdByTs[ts.rounded()] = (r["updatedAt"] as? Double) ?? ts
                }
                // notes:pull caps at the 500 newest rows: when the cap is hit, a local note
                // older than the oldest pulled row may well exist server-side beyond the cap —
                // don't re-push those every pull (unbounded mutation spam for big libraries).
                let cloudCapped = arr.count >= 500
                let cloudMinTs = cloudUpdByTs.keys.min() ?? 0
                for e in self.entries {
                    let tsMs = (e.date.timeIntervalSince1970 * 1000).rounded()
                    guard !self.tombstones.contains(tsMs) else { continue }
                    let localUpd = ((e.updatedAt ?? e.date).timeIntervalSince1970 * 1000).rounded()
                    if let cloudUpd = cloudUpdByTs[tsMs] {
                        if localUpd > cloudUpd.rounded() { self.push(e) }
                    } else if !(cloudCapped && tsMs < cloudMinTs) {
                        self.push(e)
                    }
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
