import AppKit
import Foundation

// MARK: - Models

/// A connectable app (toolkit) from the Composio catalog, as relayed by verba.run.
struct ComposioApp: Identifiable, Equatable {
    let slug: String
    let name: String
    let cat: String
    /// Connection style: "oauth" → browser flow; "api_key"/"bearer"/"basic" → credential modal;
    /// "none" → connect directly.
    var auth: String = "oauth"
    var id: String { slug }
    /// Composio's hosted app logo (PNG), e.g. https://logos.composio.dev/api/gmail.
    var logoURL: URL? { URL(string: "https://logos.composio.dev/api/\(slug.lowercased())") }
}

/// One credential field a non-OAuth toolkit needs (rendered in the connect modal).
struct ComposioField: Identifiable {
    let name: String
    let label: String
    let description: String
    let required: Bool
    var value: String
    var id: String { name }
}

/// A single executable tool (action) inside a connected toolkit.
struct ComposioTool: Identifiable, Equatable {
    let slug: String
    let name: String
    let description: String
    let toolkit: String
    var id: String { slug }
}

/// One browsable action of an app: what it does + example phrases the user can say to JARVIS.
struct ComposioAction: Identifiable, Equatable {
    let slug: String
    let name: String
    let description: String
    let phrases: [String]
    var id: String { slug }
}

enum ComposioError: LocalizedError {
    case http(Int, String)
    case badResponse
    /// No app-session token: every relay route that touches the user's own accounts 401s, so say
    /// what to do instead of surfacing a bare "HTTP 401".
    case notSignedIn
    /// The relay answered 200 but the tool itself did not run (Composio reports failure INSIDE the
    /// payload). Carrying it as an error is what keeps a failed write off the "done" path.
    case toolFailed(String, String)
    case browserFailed

    var errorDescription: String? {
        switch self {
        case .http(let code, let msg):
            return msg.isEmpty ? String(format: L("Connected apps request failed (HTTP %d)."), code) : msg
        case .badResponse:
            return L("Connected apps returned an unexpected response.")
        case .notSignedIn:
            return L("Sign in to Verba to connect and use your apps.")
        case let .toolFailed(tool, reason):
            let app = ComposioStore.prettyToolName(tool)
            return reason.isEmpty
                ? String(format: L("%@ couldn't complete that."), app)
                : String(format: L("%@ couldn't complete that: %@"), app, reason)
        case .browserFailed:
            return L("Couldn't open your browser to finish connecting.")
        }
    }
}

// MARK: - Store

/// Client for the Composio relay hosted on verba.run (`/api/composio/*`, backed by
/// @composio/core; the COMPOSIO_API_KEY never leaves the server). Every call is gated
/// by the signed-in app session: `Authorization: Bearer <AuthToken.current>` — same
/// pattern as Reprompter.verbaHosted. The signed-in user IS the Composio entity.
final class ComposioStore: ObservableObject {
    static let shared = ComposioStore()

    /// Catalog of connectable apps (from GET /apps).
    @Published var apps: [ComposioApp] = []
    /// toolkit slug (lowercased) -> connection status ("ACTIVE", "INITIALIZING", …). A toolkit can
    /// have several accounts; we fold them with ACTIVE winning (see `foldConnections`).
    @Published var connections: [String: String] = [:]
    /// Toolkits with an OAuth flow in flight (lowercased). The card shows "Connecting…" while a
    /// slug is here; it's cleared on success, on a terminal failure (denied/expired), on timeout,
    /// or on Cancel — so the Connect button always comes back.
    @Published var pending: Set<String> = []
    /// Cached executable tools of the user's ACTIVE toolkits, refreshed alongside
    /// `refresh()`. Read synchronously by the dictation pipeline to inject connected-app
    /// tools into the Action-mode prompt — never fetched on the dictation hot path.
    @Published var connectedTools: [ComposioTool] = []
    @Published var loading = false
    @Published var lastError: String?
    /// True once a catalog fetch has completed (successfully or not), so the grid can tell
    /// "still loading" apart from "loaded, and this is the bundled fallback".
    @Published var didLoadOnce = false
    /// True only once `/connections` has answered SUCCESSFULLY at least once. Anything that reasons
    /// about "this app isn't connected" must gate on THIS, not on `didLoadOnce`: a transient failure
    /// on the connections half leaves the map empty, and treating that as "nothing is connected"
    /// would refuse every connected-app action the user has.
    @Published private(set) var didLoadConnections = false

    /// Toolkits the RELAY reported active without Composio ever creating a connected account
    /// ("none"-auth apps like Hacker News answer `{ok:true,status:"ACTIVE"}` and never appear in
    /// /connections). Without remembering them, every reload would wipe the ACTIVE status and the
    /// card would fall back to "Connect" forever right after a successful connect.
    private var assumedActive: Set<String> = []

    /// The toolkit set `connectedTools` was fetched for (lowercased). Comparing against it is what
    /// lets the cheap connections reload notice "a new app went ACTIVE" and re-fetch the tools,
    /// without hitting /tools on every one of the 45 poll ticks that change nothing.
    private var toolsToolkits: Set<String> = []

    /// Bumped on every account change. Async work captures it before awaiting and drops its result
    /// if it no longer matches, so a slow answer for the PREVIOUS account cannot repopulate the
    /// caches `resetForAccountChange` just cleared.
    private var accountEpoch = 0

    /// Claimed by every tool sync BEFORE it awaits `/tools`, and re-checked before it commits.
    /// The epoch alone only rejects answers for a PREVIOUS account: two syncs racing for the SAME
    /// account (a disconnect landing right behind a connect) both pass the epoch check, so whichever
    /// response arrived last won, even when it was the older request describing a stale toolkit set.
    /// A monotonic generation makes that impossible — only the newest claim may write the caches.
    private var toolsSyncGeneration = 0

    private static let base = "https://verba.run/api/composio"
    private init() {
        // Returning from an OAuth flow in the browser → re-check connection state.
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            // Gate on a session (or an OAuth still in flight), NOT on the catalog: `/apps` is a
            // separate, independently failing request, and when it failed `apps` stayed empty and
            // this observer silently skipped the one refresh the OAuth return depends on.
            guard AuthToken.current != nil || !self.pending.isEmpty else { return }
            self.refreshConnections()
        }
    }

    /// Drop everything scoped to the signed-in account and reject anything still in flight for it.
    /// The store is a singleton, so without this a sign-out (or a switch to another account) kept
    /// the previous user's connection statuses, pending OAuth and executable tools. The PUBLIC
    /// catalog (`apps`, `didLoadOnce`) is deliberately kept: it carries no user data and dropping
    /// it would send the grid back to its bundled fallback for no reason.
    @MainActor
    func resetForAccountChange() {
        accountEpoch &+= 1
        toolsSyncGeneration &+= 1
        connections = [:]
        pending = []
        connectedTools = []
        assumedActive = []
        toolsToolkits = []
        toolSchemas = [:]
        didLoadConnections = false
        lastError = nil
    }

    /// True when the toolkit has an active connected account.
    func isConnected(_ toolkitSlug: String) -> Bool {
        (connections[toolkitSlug.lowercased()] ?? "").uppercased() == "ACTIVE"
    }

    /// True while an OAuth flow for the toolkit is in flight (drives the "Connecting…" card state).
    func isConnecting(_ toolkitSlug: String) -> Bool { pending.contains(toolkitSlug.lowercased()) }

    /// Abandon an in-flight connection (user hit Cancel) → the Connect button comes back.
    func cancelConnect(_ toolkitSlug: String) {
        let key = toolkitSlug.lowercased()
        pending.remove(key)
        assumedActive.remove(key)
        if (connections[key] ?? "").uppercased() != "ACTIVE" { connections[key] = nil }
    }

    /// A tool slug is TOOLKIT_ACTION (GMAIL_SEND_EMAIL) → "Gmail · send email", for error lines and
    /// success announcements that a person can actually read.
    static func prettyToolName(_ tool: String) -> String {
        let parts = tool.split(separator: "_").map(String.init)
        guard let app = parts.first, !app.isEmpty else { return tool }
        let appName = app.prefix(1).uppercased() + app.dropFirst().lowercased()
        let rest = parts.dropFirst().map { $0.lowercased() }.joined(separator: " ")
        return rest.isEmpty ? appName : "\(appName) · \(rest)"
    }

    /// Statuses that mean an account exists and is usable.
    private static func rank(_ s: String) -> Int {
        switch s.uppercased() {
        case "ACTIVE": return 3
        case "INITIALIZING", "INITIATED": return 1
        default: return 0   // EXPIRED / FAILED / INACTIVE / DELETED / …
        }
    }

    /// Fold the /connections payload (which may list SEVERAL accounts per toolkit) into one
    /// status per toolkit, with ACTIVE winning over INITIALIZING/EXPIRED — so a stale EXPIRED row
    /// never masks a live ACTIVE one. Accepts either {connections:{slug:status}} or a row list.
    private static func foldConnections(_ obj: [String: Any]) -> [String: String] {
        var map: [String: String] = [:]
        func put(_ key: String, _ status: String) {
            let k = key.lowercased()
            if map[k] == nil || rank(status) > rank(map[k]!) { map[k] = status }
        }
        if let dict = obj["connections"] as? [String: String] {
            for (k, v) in dict { put(k, v) }
        } else if let rows = obj["connections"] as? [[String: Any]] {
            for row in rows {
                // An unreadable status ranks 0 (not connected). Defaulting it to ACTIVE would fail
                // OPEN and show a Connected badge for an account we know nothing about.
                if let t = row["toolkit"] as? String { put(t, row["status"] as? String ?? "") }
            }
        }
        return map
    }

    // MARK: Refresh (apps + connections)

    /// Reloads the app catalog and the user's connection statuses. The two halves fail
    /// INDEPENDENTLY on purpose: `/apps` is public, so a signed-out user (or an expired session)
    /// still gets the full browsable catalog plus one clear "sign in" line, instead of the old
    /// behaviour where a 401 on /connections threw away the catalog too and left the grid on its
    /// 50-app bundled fallback with no explanation.
    func refresh() {
        Task { @MainActor in
            loading = true
            defer { loading = false; self.didLoadOnce = true }

            var problems: [String] = []

            do {
                let a = try await Self.request("GET", "/apps", requiresAuth: false)
                let rawApps = (a["apps"] as? [[String: Any]]) ?? []
                let parsed: [ComposioApp] = rawApps.compactMap { d in
                    guard let slug = d["slug"] as? String, !slug.isEmpty else { return nil }
                    return ComposioApp(
                        slug: slug,
                        name: d["name"] as? String ?? slug.capitalized,
                        cat: d["cat"] as? String ?? d["category"] as? String ?? "",
                        auth: d["auth"] as? String ?? "oauth"
                    )
                }
                if !parsed.isEmpty { self.apps = parsed }
            } catch {
                problems.append(error.localizedDescription)
            }

            let epoch = self.accountEpoch
            do {
                let c = try await Self.request("GET", "/connections")
                // A sign-out / account switch while this was in flight already cleared the caches;
                // writing the old account's answer over them is exactly what the epoch prevents.
                guard epoch == self.accountEpoch else { return }
                // Fold the (possibly multi-account) payload with ACTIVE winning, and clear any
                // pending OAuth that has since gone ACTIVE.
                let map = self.merged(Self.foldConnections(c))
                self.connections = map
                self.didLoadConnections = true
                self.pending = self.pending.filter { (map[$0] ?? "").uppercased() != "ACTIVE" }
                if map.values.contains(where: { $0.uppercased() == "ACTIVE" }) { Gamification.shared.flag(.connectedApp) }

                // Warm the tools cache for ACTIVE toolkits (for the Action-mode prompt). A full
                // refresh always re-fetches (`force`), so an explicit reload still picks up tools
                // that changed server-side for an unchanged set of toolkits.
                try await self.syncTools(active: Self.activeToolkits(map), force: true)
            } catch {
                problems.append(error.localizedDescription)
            }

            self.lastError = problems.isEmpty ? nil : problems.joined(separator: " ")
        }
    }

    /// Overlay the toolkits we know are live but that Composio never lists (see `assumedActive`).
    private func merged(_ map: [String: String]) -> [String: String] {
        var out = map
        for key in assumedActive where Self.rank(out[key] ?? "") < Self.rank("ACTIVE") {
            out[key] = "ACTIVE"
        }
        return out
    }

    // MARK: Connect (OAuth via browser)

    /// Starts an OAuth connection for the toolkit: POST /connect returns Composio's
    /// hosted redirectUrl, which we open in the default browser. The user finishes the
    /// consent there; `refresh()` later picks up the ACTIVE status.
    /// Connect a toolkit. OAuth → opens the browser; "none" → links directly. Credential auth
    /// (api_key/bearer/basic) goes through `connectWithCredentials` after the modal collects fields.
    func connect(toolkitSlug: String, auth: String = "oauth") {
        let key = toolkitSlug.lowercased()
        Task { @MainActor in
            pending.insert(key)   // card shows "Connecting…" immediately
            do {
                let obj = try await Self.request("POST", "/connect", body: ["toolkit": toolkitSlug, "auth": auth])
                try await finishConnect(key, response: obj)
            } catch {
                pending.remove(key)
                lastError = error.localizedDescription
            }
        }
    }

    /// Common tail of both connect paths: open the browser for an OAuth redirect, or record the
    /// status the relay reported for a link that needs no browser step.
    @MainActor
    private func finishConnect(_ key: String, response obj: [String: Any]) async throws {
        if let raw = (obj["redirectUrl"] as? String) ?? (obj["redirect_url"] as? String),
           !raw.isEmpty, let url = URL(string: raw) {
            // A browser that refuses to open is a dead end the user cannot see: without this the
            // card sat on "Connecting…" for 90 seconds and then quietly reverted to "Connect".
            guard NSWorkspace.shared.open(url) else {
                pending.remove(key)
                throw ComposioError.browserFailed
            }
            lastError = nil
            pollUntilConnected(key)   // OAuth completes in the browser
            return
        }
        // No redirect: "none"-auth toolkits (and credential links that go live at once) answer
        // {ok:true,status:…}. Composio creates NO connected account for a no-auth toolkit, so
        // /connections will never list it — trust the relay's status or the card would show
        // "Connect" again straight after a successful connect, with nothing to explain it.
        let reported = ((obj["status"] as? String) ?? "").uppercased()
        let ok = (obj["ok"] as? Bool) ?? !reported.isEmpty
        guard ok else { pending.remove(key); throw ComposioError.badResponse }
        let status = reported.isEmpty ? "ACTIVE" : reported
        lastError = nil
        connections[key] = status
        guard Self.rank(status) >= Self.rank("ACTIVE") else {
            // Linked but still settling (INITIALIZING): keep "Connecting…" and let the poll close it,
            // instead of dropping back to a Connect button that looks like the click did nothing.
            await reloadConnections()
            pollUntilConnected(key)
            return
        }
        pending.remove(key)
        assumedActive.insert(key)
        Gamification.shared.flag(.connectedApp)
        await reloadConnections()
    }

    /// The credential fields a non-OAuth toolkit needs (GET /connect-fields), for the connect modal.
    /// THROWS rather than returning [] on failure: an empty list and a failed request look identical
    /// to the modal, and swallowing the reason is what made it show a dead "try again" with no cause.
    func connectFields(toolkitSlug: String, auth: String) async throws -> [ComposioField] {
        let tk = toolkitSlug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toolkitSlug
        let sc = auth.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? auth
        let obj = try await Self.request("GET", "/connect-fields?toolkit=\(tk)&scheme=\(sc)", requiresAuth: false)
        guard let raw = obj["fields"] as? [[String: Any]] else { return [] }
        return raw.compactMap { d in
            guard let name = d["name"] as? String, !name.isEmpty else { return nil }
            return ComposioField(
                name: name,
                label: d["label"] as? String ?? name,
                description: d["description"] as? String ?? "",
                required: d["required"] as? Bool ?? true,
                value: d["default"] as? String ?? ""
            )
        }
    }

    /// Submit the user's credentials for a non-OAuth toolkit (POST /connect with fields).
    func connectWithCredentials(toolkitSlug: String, auth: String, fields: [String: String]) {
        let key = toolkitSlug.lowercased()
        Task { @MainActor in
            pending.insert(key)
            do {
                let obj = try await Self.request("POST", "/connect",
                                                 body: ["toolkit": toolkitSlug, "auth": auth, "fields": fields])
                try await finishConnect(key, response: obj)
            } catch {
                pending.remove(key)
                lastError = error.localizedDescription
            }
        }
    }

    /// Poll /connections (~90s) after starting an OAuth. Resolves three ways so the card never
    /// hangs: ACTIVE → Connected; a terminal status (denied/expired/failed) → back to Connect;
    /// timeout (user abandoned or denied silently) → back to Connect.
    private func pollUntilConnected(_ key: String) {
        Task { @MainActor in
            for _ in 0..<45 {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard pending.contains(key) else { return }   // user hit Cancel
                await reloadConnections()
                let status = (connections[key] ?? "").uppercased()
                if status == "ACTIVE" { pending.remove(key); return }
                if ["FAILED", "EXPIRED", "INACTIVE", "DELETED", "ERROR"].contains(status) {
                    pending.remove(key); connections[key] = nil   // access denied / failed
                    lastError = L("That connection didn't go through. Try connecting again.")
                    return
                }
            }
            // Timed out without going ACTIVE → assume abandoned/denied; restore the Connect button
            // AND say so, otherwise 90 seconds of "Connecting…" end in silence.
            guard pending.contains(key) else { return }
            pending.remove(key)
            if (connections[key] ?? "").uppercased() != "ACTIVE" {
                connections[key] = nil
                lastError = L("The connection wasn't finished in the browser. Try again when you're ready.")
            }
        }
    }

    /// Refresh ONLY the connection statuses (cheap; used on focus + while polling).
    func refreshConnections() { Task { @MainActor in await reloadConnections() } }

    /// Every caller already runs on the main actor (the poll, the focus refresh, connect/disconnect),
    /// and it mutates @Published state, so the isolation is stated rather than assumed.
    @MainActor
    private func reloadConnections() async {
        let epoch = accountEpoch
        guard let c = try? await Self.request("GET", "/connections") else { return }
        guard epoch == accountEpoch else { return }   // account changed while this was in flight
        let map = merged(Self.foldConnections(c))
        connections = map
        // A pending OAuth that's now ACTIVE has succeeded — stop showing "Connecting…". Failures
        // and timeouts are handled by the poll; focus-refresh only promotes successes here.
        pending = pending.filter { (map[$0] ?? "").uppercased() != "ACTIVE" }
        // The whole point of the cheap reload: this is the path an OAuth return actually takes
        // (poll tick + focus refresh), so the tools of a toolkit that just went ACTIVE have to land
        // HERE. Without it the badge flipped to Connected while the Action-mode prompt kept the tool
        // list from before the connection, until a full refresh happened to run.
        try? await syncTools(active: Self.activeToolkits(map))
    }

    /// Disconnect a connected app (deletes its connected account on Composio).
    func disconnect(toolkitSlug: String) {
        let key = toolkitSlug.lowercased()
        Task { @MainActor in
            pending.remove(key)
            assumedActive.remove(key)
            connections[key] = nil   // optimistic
            do {
                _ = try await Self.request("POST", "/disconnect", body: ["toolkit": toolkitSlug])
                lastError = nil
            } catch {
                // The optimistic removal above would otherwise make a FAILED disconnect look like a
                // success until the next reload silently put the app back.
                lastError = error.localizedDescription
            }
            await reloadConnections()
        }
    }

    // MARK: Tools

    /// Lists an app's actions with example phrases (GET /actions?toolkit=X) — for the app detail view.
    /// THROWS on failure so the sheet can say WHY it's empty instead of claiming the app has no
    /// actions (which is what a swallowed network error used to look like).
    func actions(for toolkit: String) async throws -> [ComposioAction] {
        let tk = toolkit.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toolkit
        let obj = try await Self.request("GET", "/actions?toolkit=\(tk)", requiresAuth: false)
        guard let raw = obj["actions"] as? [[String: Any]] else { return [] }
        return raw.compactMap { d in
            guard let slug = d["slug"] as? String else { return nil }
            return ComposioAction(
                slug: slug,
                name: d["name"] as? String ?? slug,
                description: d["description"] as? String ?? "",
                phrases: (d["phrases"] as? [String]) ?? []
            )
        }
    }

    /// Lists the executable tools for the given toolkits (GET /tools?toolkits=a,b).
    /// THROWS so a failed refresh keeps the PREVIOUS cache instead of silently emptying the
    /// connected-app tool list the Action-mode prompt is built from.
    func tools(for toolkits: [String]) async throws -> [ComposioTool] {
        guard !toolkits.isEmpty else { return [] }
        // An empty fallback would send `toolkits=`, which the route reads as "ALL my active
        // toolkits" — a silently different query. Keep the raw list instead.
        let joined = toolkits.joined(separator: ",")
        let qs = joined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? joined
        let obj = try await Self.request("GET", "/tools?toolkits=\(qs)")
        guard let raw = obj["tools"] as? [[String: Any]] else { return [] }
        return raw.compactMap { d in
            guard let slug = d["slug"] as? String else { return nil }
            return ComposioTool(
                slug: slug,
                name: d["name"] as? String ?? slug,
                description: d["description"] as? String ?? "",
                toolkit: d["toolkit"] as? String ?? ""
            )
        }
    }

    /// The toolkits of a folded connections map that are usable right now (lowercased by `fold`).
    private static func activeToolkits(_ map: [String: String]) -> [String] {
        map.filter { $0.value.uppercased() == "ACTIVE" }.map(\.key)
    }

    /// Bring `connectedTools` in line with the toolkits that are ACTIVE right now.
    ///
    /// Both refresh paths go through here so the Action-mode tool cache can never drift from the
    /// badges again. It re-fetches only when the toolkit SET changed (or on `force`), because
    /// `reloadConnections` runs on every focus and on all 45 ticks of the OAuth poll, and a /tools
    /// round-trip per tick would be pure waste while the set is unchanged.
    ///
    /// Throws like `tools(for:)` so a full refresh can still report WHY the warm-up failed; a
    /// failure deliberately leaves both the previous cache and `toolsToolkits` alone, so the next
    /// sync retries instead of the Action prompt losing every connected app to one flaky request.
    @MainActor
    private func syncTools(active: [String], force: Bool = false) async throws {
        let want = Set(active.map { $0.lowercased() })
        guard force || want != toolsToolkits else { return }
        // Claim the caches for THIS sync: every request already in flight is now stale and will
        // refuse to commit below. Claimed before the empty-set branch too, so clearing the cache
        // can't be undone by an older fetch that lands after it.
        toolsSyncGeneration &+= 1
        let generation = toolsSyncGeneration
        guard !want.isEmpty else {
            connectedTools = []
            toolsToolkits = []
            return
        }
        let epoch = accountEpoch
        let fetched = try await tools(for: want.sorted())
        guard epoch == accountEpoch else { return }   // signed out / switched account mid-fetch
        guard generation == toolsSyncGeneration else { return }   // a newer sync superseded this one
        connectedTools = fetched
        toolsToolkits = want
    }

    // MARK: Execute

    /// Executes a tool (POST /execute) and returns ONE readable line for the feed.
    ///
    /// Two things this deliberately does that the previous version didn't:
    ///  1. It treats an in-payload failure as a failure. Composio answers HTTP 200 with
    ///     `{successful:false, error:…}` when the tool itself refused (bad recipient, missing
    ///     scope, revoked token). Returning that payload as the success string is exactly how a
    ///     write that never happened got a green checkmark and a "Done." in the JARVIS feed.
    ///  2. It reports a sentence, not a JSON dump. The raw payload is ids and etags.
    func execute(tool: String, arguments: [String: Any]) async throws -> String {
        // 300s matches the route's own maxDuration: a shorter client deadline abandons a write the
        // relay may still be performing, and the user is then invited to send it twice.
        let obj = try await Self.request("POST", "/execute",
                                         body: ["tool": tool, "arguments": retyped(arguments, tool: tool)],
                                         timeout: 300)
        if (obj["ok"] as? Bool) == false {
            throw ComposioError.toolFailed(tool, (obj["error"] as? String) ?? "")
        }
        if let payload = obj["result"] as? [String: Any] {
            if (payload["successful"] as? Bool) == false || (payload["success"] as? Bool) == false {
                throw ComposioError.toolFailed(tool, Self.errorText(payload) ?? "")
            }
            let data = payload["data"] as? [String: Any]
            // Composio nests the tool's own error under `data` for several toolkits, so a payload
            // can carry a failure while the envelope looks clean.
            if let err = Self.errorText(payload) ?? Self.errorText(data ?? [:]) {
                throw ComposioError.toolFailed(tool, err)
            }
            return Self.summarize(tool: tool, data: data ?? payload)
        }
        if let s = obj["result"] as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        // Anything else (a bare list, a number) still counts as a run — but a 200 carrying neither
        // `ok` nor a result is not evidence that anything happened, and must not read as success.
        guard (obj["ok"] as? Bool) == true || obj["result"] != nil else { throw ComposioError.badResponse }
        return Self.summarize(tool: tool, data: obj["result"] ?? [String: Any]())
    }

    /// Input schemas of the tools the planner considered, keyed by tool slug, cached from
    /// `/agent-context`. Used ONLY to re-type arguments on the way out (see `retyped`).
    private var toolSchemas: [String: [String: Any]] = [:]

    /// Remember the tool schemas the planner was given, so execution can undo the flattening the
    /// action model imposes. Called by ActionAgentClient after each context fetch.
    func cacheToolSchemas(_ schemas: [String: Any]) {
        for (slug, spec) in schemas {
            if let dict = spec as? [String: Any] { toolSchemas[slug] = dict }
        }
    }

    /// Undo the flattening `Pipeline.parseAgenticAction` performs. `VerbaAction.composio` carries
    /// `[String: String]` so the action stays Codable and printable in the confirmation card, which
    /// turns every array, object, number and boolean argument into TEXT. Nothing downstream re-types
    /// it (website/app/api/composio/execute/route.ts forwards `arguments` verbatim), so Composio
    /// rejected those calls against the tool schema — including the ones the planner's own repair
    /// pass had just fixed.
    ///
    /// The tool's SCHEMA decides, never the string's shape: a value is converted only where the tool
    /// declares that type. That is what makes it safe to fix "42" and "true", which a shape-based
    /// guess would corrupt whenever the field is genuinely a string. With no schema cached, only
    /// unambiguous containers are restored.
    private func retyped(_ arguments: [String: Any], tool: String) -> [String: Any] {
        let props = (toolSchemas[tool]?["properties"] as? [String: Any]) ?? [:]
        var out: [String: Any] = [:]
        for (key, value) in arguments {
            guard let text = value as? String else { out[key] = value; continue }
            let declared = ((props[key] as? [String: Any])?["type"] as? String)?.lowercased()
            out[key] = Self.coerce(text, to: declared) ?? value
        }
        return out
    }

    /// One argument, converted to the type the schema declares. Returns nil to keep the string.
    private static func coerce(_ text: String, to declared: String?) -> Any? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        func json() -> Any? {
            guard let data = t.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        }
        switch declared {
        case "string":
            return nil                                   // declared text stays text, always
        case "array":
            return (json() as? [Any])
        case "object":
            return (json() as? [String: Any])
        case "boolean":
            if ["true", "yes", "1"].contains(t.lowercased()) { return true }
            if ["false", "no", "0"].contains(t.lowercased()) { return false }
            return nil
        case "integer":
            return Int(t)
        case "number":
            return Double(t)
        default:
            // Unknown or absent schema: only a well-formed container is unambiguous enough to fix.
            let container = (t.hasPrefix("[") && t.hasSuffix("]")) || (t.hasPrefix("{") && t.hasSuffix("}"))
            guard container, let parsed = json(), parsed is [Any] || parsed is [String: Any] else { return nil }
            return parsed
        }
    }

    /// A non-empty error string carried inside a 200 payload, if any.
    private static func errorText(_ payload: [String: Any]) -> String? {
        // Deliberately NOT "message": a successful payload often carries one, and reading it as a
        // failure would turn a completed write into a false error — worse than a noisy success.
        for key in ["error", "errorMessage"] {
            if let s = payload[key] as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return String(t.prefix(240)) }
            }
        }
        return nil
    }

    /// One human sentence for a successful tool run, with a useful reference when the payload
    /// carries one (a message id, a permalink, a created record's url).
    private static func summarize(tool: String, data: Any) -> String {
        // A tool that only READS says how much it found. Reads normally go through /agent-reads, but
        // a planner that mis-buckets one into a proposed action would otherwise answer "Done." and
        // throw the answer away.
        if ActionAgentClient.isReadShaped(tool), let found = readDigest(data) {
            return String(format: L("%@: %@"), prettyToolName(tool), found)
        }
        let base = String(format: L("Done in %@."), prettyToolName(tool))
        guard let d = data as? [String: Any] else { return base }
        for key in ["permalink", "html_url", "htmlUrl", "url", "link", "webViewLink"] {
            if let s = d[key] as? String, !s.isEmpty { return "\(base) \(s)" }
        }
        for key in ["title", "subject", "name", "summary"] {
            if let s = d[key] as? String, !s.isEmpty { return "\(base) \u{201C}\(s.prefix(80))\u{201D}" }
        }
        return base
    }

    /// A one-line digest of a read result: how many items, and what the first one is called.
    private static func readDigest(_ data: Any) -> String? {
        var items: [Any]?
        if let list = data as? [Any] { items = list }
        else if let d = data as? [String: Any] {
            items = d.values.compactMap { $0 as? [Any] }.max(by: { $0.count < $1.count })
        }
        guard let items, !items.isEmpty else { return nil }
        var line = String(format: L("%d result(s)"), items.count)
        if let first = items.first as? [String: Any] {
            for key in ["title", "subject", "name", "summary", "text"] {
                if let s = first[key] as? String, !s.isEmpty {
                    line += " · \u{201C}\(s.prefix(60))\u{201D}"
                    break
                }
            }
        }
        return line
    }

    // MARK: HTTP plumbing

    /// One JSON round-trip to the relay. Throws ComposioError.http on non-2xx, surfacing the
    /// server's {error} message when present (same style as Reprompter).
    ///
    /// `requiresAuth: false` is for the routes that carry no user data (`/apps`, `/actions`,
    /// `/connect-fields` — none of them call requireUid server-side). Sending an empty
    /// `Bearer ` on those is what made a signed-out user lose the whole browsable catalog to a
    /// 401; sending it on the others produced a bare "HTTP 401" instead of "sign in".
    private static func request(_ method: String, _ path: String,
                                body: [String: Any]? = nil,
                                requiresAuth: Bool = true,
                                timeout: TimeInterval = 120) async throws -> [String: Any] {
        guard let url = URL(string: base + path) else { throw ComposioError.badResponse }
        let token = AuthToken.current
        if requiresAuth, (token ?? "").isEmpty { throw ComposioError.notSignedIn }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        if let token, !token.isEmpty { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.timeoutInterval = timeout
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            if code == 401 { throw ComposioError.notSignedIn }
            let msg = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["error"] as? String
            let fallback = String((String(data: data, encoding: .utf8) ?? "").prefix(240))
            throw ComposioError.http(code, msg ?? fallback)
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ComposioError.badResponse
        }
        return obj
    }
}
