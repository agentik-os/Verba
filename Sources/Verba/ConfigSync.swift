import Foundation
import Combine

// MARK: - Config sync (modes / styles / snippets / transforms / dictionary / tasks)
//
// These six per-account config tables already exist in Convex (push/pull/remove + a tombstones
// query each) and the mobile app syncs them — but the Mac never wired them. This file is the Mac
// half, kept entirely self-contained: it OBSERVES each store's published list via Combine and
// keeps an id↔ts map on the side, so NO existing struct or store needs to change (zero Codable
// risk on the data that already lives on disk). Mirrors the Stats/Notes sync idiom in ConvexClient.
//
// Identity: the cloud keys rows by a numeric `ts`; the Mac models key by UUID. We map each local
// UUID to a stable `ts` (minted on first sync, or derived deterministically from the UUID so it's
// identical across launches before the first persist). Deletions propagate via each table's
// tombstones query, exactly like notes — a row deleted on any device is dropped everywhere and
// never resurrected.

private func cfgConvexOK(_ data: Data?) -> Bool {
    guard let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
    return obj["status"] as? String == "success"
}

/// Deterministic, launch-stable sync id derived from a UUID (FNV-1a over its 16 bytes), so a
/// pre-existing local item gets the same `ts` every launch without having to be persisted first.
func verbaStableTs(_ id: UUID) -> Double {
    let u = id.uuid
    let bytes: [UInt8] = [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7, u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15]
    var h: UInt64 = 0xcbf29ce484222325
    for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
    return Double(h % 9_000_000_000_000)   // positive, JS-safe integer range
}

final class ConfigSync {
    static let shared = ConfigSync()
    private var bag = Set<AnyCancellable>()
    /// True while we are applying a cloud pull, so the resulting publisher emission doesn't bounce
    /// straight back out as a push/delete.
    private var applyingRemote = false
    /// Last-seen id list per table, to detect deletions between emissions.
    private var lastIDs: [String: [UUID]] = [:]
    private init() {}

    private var signedIn: Bool { !Settings.shared.proEmail.isEmpty }

    // MARK: id ↔ ts map (UserDefaults, one dict per table)

    private func tsKey(_ table: String) -> String { "cloudTs.\(table)" }
    private func tsMap(_ table: String) -> [String: Double] {
        (UserDefaults.standard.dictionary(forKey: tsKey(table)) as? [String: Double]) ?? [:]
    }
    @discardableResult
    private func ts(_ table: String, _ id: UUID) -> Double {
        var m = tsMap(table)
        if let v = m[id.uuidString] { return v }
        let v = verbaStableTs(id)
        m[id.uuidString] = v
        UserDefaults.standard.set(m, forKey: tsKey(table))
        return v
    }
    private func setTs(_ table: String, _ id: UUID, _ value: Double) {
        var m = tsMap(table)
        m[id.uuidString] = value
        UserDefaults.standard.set(m, forKey: tsKey(table))
    }

    // MARK: generic CRUD plumbing

    private func push(_ table: String, _ fields: [String: Any]) {
        guard signedIn else { return }
        ConvexClient.call("mutation", "\(table):push", ConvexClient.authedArgs(fields)) {
            if !cfgConvexOK($0) { VerbaLog.syncFailure("\(table):push") }
        }
    }
    private func remove(_ table: String, _ tsValue: Double) {
        guard signedIn else { return }
        ConvexClient.call("mutation", "\(table):remove", ConvexClient.authedArgs(["ts": tsValue])) { _ in }
    }
    /// Pull rows + tombstones together; `done` runs on the main queue with (rows, tombstoned ts).
    private func pull(_ table: String, _ done: @escaping ([[String: Any]], Set<Double>) -> Void) {
        guard signedIn else { return }
        ConvexClient.registerDevice(token: AuthToken.current)
        ConvexClient.call("query", "\(table):tombstones", ConvexClient.authedArgs()) { [weak self] td in
            guard self != nil else { return }
            var tombs = Set<Double>()
            if let td, let o = try? JSONSerialization.jsonObject(with: td) as? [String: Any],
               o["status"] as? String == "success", let arr = o["value"] as? [Any] {
                tombs = Set(arr.compactMap { ($0 as? NSNumber)?.doubleValue })
            }
            ConvexClient.call("query", "\(table):pull", ConvexClient.authedArgs()) { data in
                guard let data, let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      o["status"] as? String == "success", let rows = o["value"] as? [[String: Any]] else {
                    VerbaLog.syncFailure("\(table):pull"); return
                }
                DispatchQueue.main.async { done(rows, tombs) }
            }
        }
    }
    private func dbl(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
    private func u32(_ v: Any?) -> UInt32? { (v as? NSNumber).map { UInt32(truncatingIfNeeded: $0.intValue) } }

    /// Handle a published change: remove rows deleted since the last emission, then push the rest.
    private func onChange(_ table: String, _ newIDs: [UUID], _ pushAll: () -> Void) {
        guard !applyingRemote else { lastIDs[table] = newIDs; return }
        let old = lastIDs[table] ?? []
        lastIDs[table] = newIDs
        guard signedIn else { return }
        let newSet = Set(newIDs)
        for o in old where !newSet.contains(o) { remove(table, ts(table, o)) }
        pushAll()
    }

    // MARK: - wiring

    func start() {
        lastIDs["snippets"]   = SnippetsStore.shared.items.map(\.id)
        lastIDs["transforms"] = TransformsStore.shared.items.map(\.id)
        lastIDs["dict"]       = DictionaryStore.shared.terms.map(\.id)
        lastIDs["styles"]     = Settings.shared.styles.map(\.id)
        lastIDs["modes"]      = Settings.shared.profiles.map(\.id)
        lastIDs["tasks"]      = TodoStore.shared.projects.flatMap { $0.tasks }.map(\.id)

        SnippetsStore.shared.$items.dropFirst().sink { [weak self] v in
            self?.onChange("snippets", v.map(\.id)) { self?.pushSnippets() }
        }.store(in: &bag)
        TransformsStore.shared.$items.dropFirst().sink { [weak self] v in
            self?.onChange("transforms", v.map(\.id)) { self?.pushTransforms() }
        }.store(in: &bag)
        DictionaryStore.shared.$terms.dropFirst().sink { [weak self] v in
            self?.onChange("dict", v.map(\.id)) { self?.pushDict() }
        }.store(in: &bag)
        Settings.shared.$styles.dropFirst().sink { [weak self] v in
            self?.onChange("styles", v.map(\.id)) { self?.pushStyles() }
        }.store(in: &bag)
        Settings.shared.$profiles.dropFirst().sink { [weak self] v in
            self?.onChange("modes", v.map(\.id)) { self?.pushModes() }
        }.store(in: &bag)
        TodoStore.shared.$projects.dropFirst().sink { [weak self] v in
            self?.onChange("tasks", v.flatMap { $0.tasks }.map(\.id)) { self?.pushTasks() }
        }.store(in: &bag)
    }

    /// Pull everything from the account (launch + sign-in).
    func pullAll() {
        guard signedIn else { return }
        syncSnippets(); syncTransforms(); syncDict(); syncStyles(); syncModes(); syncTasks()
    }
    /// Push everything to the account (sign-in, so anything made while signed out reaches it).
    func pushAll() {
        guard signedIn else { return }
        ConvexClient.registerDevice(token: AuthToken.current)
        pushSnippets(); pushTransforms(); pushDict(); pushStyles(); pushModes(); pushTasks()
    }

    // MARK: - Snippets (trigger → expansion)

    private func pushSnippets() {
        for s in SnippetsStore.shared.items {
            push("snippets", ["ts": ts("snippets", s.id), "trigger": s.trigger, "expansion": s.expansion])
        }
    }
    private func syncSnippets() {
        pull("snippets") { [weak self] rows, tombs in
            guard let self else { return }
            var items = SnippetsStore.shared.items
            items.removeAll { tombs.contains(self.ts("snippets", $0.id)) }
            var byTs = [Double: Snippet]()
            for s in items { byTs[self.ts("snippets", s.id)] = s }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                if var ex = byTs[cts] {
                    ex.trigger = r["trigger"] as? String ?? ex.trigger
                    ex.expansion = r["expansion"] as? String ?? ex.expansion
                    byTs[cts] = ex
                } else {
                    let nw = Snippet(trigger: r["trigger"] as? String ?? "", expansion: r["expansion"] as? String ?? "")
                    self.setTs("snippets", nw.id, cts)
                    byTs[cts] = nw
                }
            }
            self.applyRemote("snippets", Array(byTs.values)) { SnippetsStore.shared.items = $0 }
        }
    }

    // MARK: - Transforms (name → prompt)

    private func pushTransforms() {
        for t in TransformsStore.shared.items {
            push("transforms", ["ts": ts("transforms", t.id), "name": t.name, "prompt": t.prompt])
        }
    }
    private func syncTransforms() {
        pull("transforms") { [weak self] rows, tombs in
            guard let self else { return }
            var items = TransformsStore.shared.items
            items.removeAll { tombs.contains(self.ts("transforms", $0.id)) }
            var byTs = [Double: Transform]()
            for t in items { byTs[self.ts("transforms", t.id)] = t }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                if var ex = byTs[cts] {
                    ex.name = r["name"] as? String ?? ex.name
                    ex.prompt = r["prompt"] as? String ?? ex.prompt
                    byTs[cts] = ex
                } else {
                    let nw = Transform(name: r["name"] as? String ?? "", prompt: r["prompt"] as? String ?? "")
                    self.setTs("transforms", nw.id, cts)
                    byTs[cts] = nw
                }
            }
            self.applyRemote("transforms", Array(byTs.values)) { TransformsStore.shared.items = $0 }
        }
    }

    // MARK: - Dictionary (spoken → written)

    private func pushDict() {
        for t in DictionaryStore.shared.terms {
            push("dict", ["ts": ts("dict", t.id), "spoken": t.spoken, "written": t.written, "auto": t.auto])
        }
    }
    private func syncDict() {
        pull("dict") { [weak self] rows, tombs in
            guard let self else { return }
            var items = DictionaryStore.shared.terms
            items.removeAll { tombs.contains(self.ts("dict", $0.id)) }
            var byTs = [Double: DictTerm]()
            for t in items { byTs[self.ts("dict", t.id)] = t }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                if var ex = byTs[cts] {
                    ex.spoken = r["spoken"] as? String ?? ex.spoken
                    ex.written = r["written"] as? String ?? ex.written
                    ex.auto = r["auto"] as? Bool ?? ex.auto
                    byTs[cts] = ex
                } else {
                    var nw = DictTerm(spoken: r["spoken"] as? String ?? "", written: r["written"] as? String ?? "")
                    nw.auto = r["auto"] as? Bool ?? false
                    self.setTs("dict", nw.id, cts)
                    byTs[cts] = nw
                }
            }
            self.applyRemote("dict", Array(byTs.values)) { DictionaryStore.shared.terms = $0 }
        }
    }

    // MARK: - Styles (name → prompt). Built-in "Normal" never syncs.

    private func pushStyles() {
        for s in Settings.shared.styles where !s.builtin {
            push("styles", ["ts": ts("styles", s.id), "name": s.name, "prompt": s.prompt])
        }
    }
    private func syncStyles() {
        pull("styles") { [weak self] rows, tombs in
            guard let self else { return }
            var items = Settings.shared.styles
            items.removeAll { !$0.builtin && tombs.contains(self.ts("styles", $0.id)) }
            var byTs = [Double: Style]()
            for s in items where !s.builtin { byTs[self.ts("styles", s.id)] = s }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                if var ex = byTs[cts] {
                    ex.name = r["name"] as? String ?? ex.name
                    ex.prompt = r["prompt"] as? String ?? ex.prompt
                    byTs[cts] = ex
                } else {
                    var nw = Style(name: r["name"] as? String ?? "", prompt: r["prompt"] as? String ?? "")
                    nw.builtin = false
                    self.setTs("styles", nw.id, cts)
                    byTs[cts] = nw
                }
            }
            // Preserve built-ins (Normal) at the front, then the synced user styles.
            let builtins = items.filter { $0.builtin }
            self.applyRemote("styles", builtins + Array(byTs.values)) { Settings.shared.styles = $0 }
        }
    }

    // MARK: - Modes (Profiles). Built-ins never sync; the Mac extras round-trip losslessly.

    private func pushModes() {
        for p in Settings.shared.profiles where !p.builtin {
            var f: [String: Any] = [
                "ts": ts("modes", p.id), "name": p.name, "system": p.systemPrompt, "raw": p.raw,
                "matchBundleIDs": p.matchBundleIDs, "vision": p.vision,
            ]
            if let m = p.model { f["model"] = m }
            if let h = p.hotkeyCode { f["hotkeyCode"] = Double(h) }
            if let h = p.hotkeyMods { f["hotkeyMods"] = Double(h) }
            if let l = p.targetLanguage { f["targetLanguage"] = l }
            if let s = p.seedHash { f["seedHash"] = s }
            if let e = p.explainer { f["explainer"] = e }
            push("modes", f)
        }
    }
    private func syncModes() {
        pull("modes") { [weak self] rows, tombs in
            guard let self else { return }
            var items = Settings.shared.profiles
            items.removeAll { !$0.builtin && tombs.contains(self.ts("modes", $0.id)) }
            var byTs = [Double: Profile]()
            for p in items where !p.builtin { byTs[self.ts("modes", p.id)] = p }
            func fill(_ p: inout Profile, _ r: [String: Any]) {
                p.name = r["name"] as? String ?? p.name
                p.systemPrompt = r["system"] as? String ?? p.systemPrompt
                p.raw = r["raw"] as? Bool ?? p.raw
                p.model = r["model"] as? String ?? p.model
                if let b = r["matchBundleIDs"] as? [String] { p.matchBundleIDs = b }
                if let v = r["vision"] as? Bool { p.vision = v }
                if let h = self.u32(r["hotkeyCode"]) { p.hotkeyCode = h }
                if let h = self.u32(r["hotkeyMods"]) { p.hotkeyMods = h }
                if let l = r["targetLanguage"] as? String { p.targetLanguage = l }
                if let s = r["seedHash"] as? String { p.seedHash = s }
                if let e = r["explainer"] as? String { p.explainer = e }
            }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                if var ex = byTs[cts] {
                    fill(&ex, r); byTs[cts] = ex
                } else {
                    var nw = Profile(name: r["name"] as? String ?? "", systemPrompt: r["system"] as? String ?? "")
                    fill(&nw, r)
                    self.setTs("modes", nw.id, cts)
                    byTs[cts] = nw
                }
            }
            let builtins = items.filter { $0.builtin }
            self.applyRemote("modes", builtins + Array(byTs.values)) { Settings.shared.profiles = $0 }
        }
    }

    // MARK: - Tasks (flatten Projects▸Tasks for the shared flat table; subtasks/project round-trip)

    private func pushTasks() {
        for proj in TodoStore.shared.projects {
            for task in proj.tasks {
                var f: [String: Any] = [
                    "ts": ts("tasks", task.id), "text": task.title, "done": task.done, "project": proj.name,
                ]
                if let d = task.deadline { f["due"] = d.timeIntervalSince1970 * 1000 }
                if let data = try? JSONEncoder().encode(task.subtasks), let s = String(data: data, encoding: .utf8) {
                    f["subtasks"] = s
                }
                push("tasks", f)
            }
        }
    }
    private func syncTasks() {
        pull("tasks") { [weak self] rows, tombs in
            guard let self else { return }
            var projects = TodoStore.shared.projects
            for i in projects.indices { projects[i].tasks.removeAll { tombs.contains(self.ts("tasks", $0.id)) } }
            for r in rows {
                guard let cts = self.dbl(r["ts"]), !tombs.contains(cts) else { continue }
                let text = r["text"] as? String ?? ""
                let done = r["done"] as? Bool ?? false
                let due: Date? = self.dbl(r["due"]).map { Date(timeIntervalSince1970: $0 / 1000) }
                var subs: [TodoSubtask] = []
                if let s = r["subtasks"] as? String, let d = s.data(using: .utf8),
                   let arr = try? JSONDecoder().decode([TodoSubtask].self, from: d) { subs = arr }
                let projName = (r["project"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Inbox"
                var found = false
                outer: for pi in projects.indices {
                    for ti in projects[pi].tasks.indices where self.ts("tasks", projects[pi].tasks[ti].id) == cts {
                        projects[pi].tasks[ti].title = text
                        projects[pi].tasks[ti].done = done
                        projects[pi].tasks[ti].deadline = due
                        projects[pi].tasks[ti].subtasks = subs
                        found = true; break outer
                    }
                }
                if !found {
                    var t = TodoTask(title: text); t.done = done; t.deadline = due; t.subtasks = subs
                    self.setTs("tasks", t.id, cts)
                    if let pi = projects.firstIndex(where: { $0.name == projName }) {
                        projects[pi].tasks.append(t)
                    } else {
                        var np = TodoProject(name: projName); np.tasks = [t]; projects.append(np)
                    }
                }
            }
            self.applyingRemote = true
            TodoStore.shared.projects = projects
            self.applyingRemote = false
            self.lastIDs["tasks"] = projects.flatMap { $0.tasks }.map(\.id)
        }
    }

    // MARK: - apply a merged list back to a store without bouncing it out again

    private func applyRemote<T>(_ table: String, _ items: [T], _ assign: ([T]) -> Void) where T: Identifiable, T.ID == UUID {
        applyingRemote = true
        assign(items)
        applyingRemote = false
        lastIDs[table] = items.map(\.id)
    }
}
