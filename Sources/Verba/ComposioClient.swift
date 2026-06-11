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

    var errorDescription: String? {
        switch self {
        case .http(let code, let msg):
            return msg.isEmpty ? "Connected apps request failed (HTTP \(code))." : msg
        case .badResponse:
            return "Connected apps returned an unexpected response."
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

    private static let base = "https://verba.run/api/composio"
    private init() {
        // Returning from an OAuth flow in the browser → re-check connection state.
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self, !self.apps.isEmpty else { return }
            self.refreshConnections()
        }
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
        if (connections[key] ?? "").uppercased() != "ACTIVE" { connections[key] = nil }
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
                if let t = row["toolkit"] as? String { put(t, row["status"] as? String ?? "ACTIVE") }
            }
        }
        return map
    }

    // MARK: Refresh (apps + connections)

    /// Reloads the app catalog and the user's connection statuses.
    func refresh() {
        Task { @MainActor in
            loading = true
            defer { loading = false }
            do {
                async let appsObj = Self.request("GET", "/apps")
                async let connsObj = Self.request("GET", "/connections")

                let (a, c) = try await (appsObj, connsObj)

                let rawApps = (a["apps"] as? [[String: Any]]) ?? []
                self.apps = rawApps.compactMap { d in
                    guard let slug = d["slug"] as? String else { return nil }
                    return ComposioApp(
                        slug: slug,
                        name: d["name"] as? String ?? slug.capitalized,
                        cat: d["cat"] as? String ?? d["category"] as? String ?? "",
                        auth: d["auth"] as? String ?? "oauth"
                    )
                }

                // Fold the (possibly multi-account) payload with ACTIVE winning, and clear any
                // pending OAuth that has since gone ACTIVE.
                let map = Self.foldConnections(c)
                self.connections = map
                self.pending = self.pending.filter { (map[$0] ?? "").uppercased() != "ACTIVE" }
                self.lastError = nil

                // Warm the tools cache for ACTIVE toolkits (for the Action-mode prompt).
                let active = map.filter { $0.value.uppercased() == "ACTIVE" }.map(\.key)
                self.connectedTools = active.isEmpty ? [] : await self.tools(for: active)
            } catch {
                self.lastError = error.localizedDescription
            }
        }
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
                if let raw = obj["redirectUrl"] as? String ?? obj["redirect_url"] as? String, let url = URL(string: raw) {
                    NSWorkspace.shared.open(url)
                    lastError = nil
                    pollUntilConnected(key)   // OAuth completes in the browser
                } else {
                    // No-auth link: active immediately.
                    lastError = nil
                    await reloadConnections()
                    pending.remove(key)
                }
            } catch {
                pending.remove(key)
                lastError = error.localizedDescription
            }
        }
    }

    /// The credential fields a non-OAuth toolkit needs (GET /connect-fields), for the connect modal.
    func connectFields(toolkitSlug: String, auth: String) async -> [ComposioField] {
        let tk = toolkitSlug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toolkitSlug
        guard let obj = try? await Self.request("GET", "/connect-fields?toolkit=\(tk)&scheme=\(auth)"),
              let raw = obj["fields"] as? [[String: Any]] else { return [] }
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
                lastError = nil
                if let raw = obj["redirectUrl"] as? String, let url = URL(string: raw) {
                    NSWorkspace.shared.open(url); pollUntilConnected(key)
                } else {
                    await reloadConnections(); pending.remove(key)
                }
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
                    pending.remove(key); connections[key] = nil; return   // access denied / failed
                }
            }
            // Timed out without going ACTIVE → assume abandoned/denied; restore the Connect button.
            if (connections[key] ?? "").uppercased() != "ACTIVE" {
                pending.remove(key)
                if (connections[key] ?? "").uppercased() != "ACTIVE" { connections[key] = nil }
            }
        }
    }

    /// Refresh ONLY the connection statuses (cheap; used on focus + while polling).
    func refreshConnections() { Task { @MainActor in await reloadConnections() } }

    private func reloadConnections() async {
        guard let c = try? await Self.request("GET", "/connections") else { return }
        let map = Self.foldConnections(c)
        connections = map
        // A pending OAuth that's now ACTIVE has succeeded — stop showing "Connecting…". Failures
        // and timeouts are handled by the poll; focus-refresh only promotes successes here.
        pending = pending.filter { (map[$0] ?? "").uppercased() != "ACTIVE" }
    }

    /// Disconnect a connected app (deletes its connected account on Composio).
    func disconnect(toolkitSlug: String) {
        let key = toolkitSlug.lowercased()
        Task { @MainActor in
            pending.remove(key)
            connections[key] = nil   // optimistic
            _ = try? await Self.request("POST", "/disconnect", body: ["toolkit": toolkitSlug])
            await reloadConnections()
        }
    }

    // MARK: Tools

    /// Lists an app's actions with example phrases (GET /actions?toolkit=X) — for the app detail view.
    func actions(for toolkit: String) async -> [ComposioAction] {
        let tk = toolkit.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? toolkit
        guard let obj = try? await Self.request("GET", "/actions?toolkit=\(tk)"),
              let raw = obj["actions"] as? [[String: Any]] else { return [] }
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
    func tools(for toolkits: [String]) async -> [ComposioTool] {
        guard !toolkits.isEmpty else { return [] }
        let qs = toolkits.joined(separator: ",")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let obj = try? await Self.request("GET", "/tools?toolkits=\(qs)"),
              let raw = obj["tools"] as? [[String: Any]] else { return [] }
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

    // MARK: Execute

    /// Executes a tool (POST /execute) and returns the result rendered as a string —
    /// what the voice pipeline feeds back into the conversation.
    func execute(tool: String, arguments: [String: Any]) async throws -> String {
        let obj = try await Self.request("POST", "/execute", body: ["tool": tool, "arguments": arguments])
        if let s = obj["result"] as? String { return s }
        if let nested = obj["result"],
           let data = try? JSONSerialization.data(withJSONObject: nested, options: [.sortedKeys]),
           let s = String(data: data, encoding: .utf8) { return s }
        // Fall back to the whole payload so the caller always gets something inspectable.
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]),
           let s = String(data: data, encoding: .utf8) { return s }
        throw ComposioError.badResponse
    }

    // MARK: HTTP plumbing

    /// One authed JSON round-trip to the relay. Throws ComposioError.http on non-2xx,
    /// surfacing the server's {error} message when present (same style as Reprompter).
    private static func request(_ method: String, _ path: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: base + path) else { throw ComposioError.badResponse }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(AuthToken.current ?? "")", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 120
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let msg = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["error"] as? String
            throw ComposioError.http(code, msg ?? (String(data: data, encoding: .utf8) ?? ""))
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ComposioError.badResponse
        }
        return obj
    }
}
