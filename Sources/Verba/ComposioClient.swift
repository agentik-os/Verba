import AppKit
import Foundation

// MARK: - Models

/// A connectable app (toolkit) from the Composio catalog, as relayed by verba.run.
struct ComposioApp: Identifiable, Equatable {
    let slug: String
    let name: String
    let cat: String
    var id: String { slug }
}

/// A single executable tool (action) inside a connected toolkit.
struct ComposioTool: Identifiable, Equatable {
    let slug: String
    let name: String
    let description: String
    let toolkit: String
    var id: String { slug }
}

enum ComposioError: LocalizedError {
    case http(Int, String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .http(let code, let msg):
            return msg.isEmpty ? "Composio request failed (HTTP \(code))." : msg
        case .badResponse:
            return "Composio returned an unexpected response."
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
    /// toolkit slug -> connection status ("ACTIVE", "INITIATED", …) from GET /connections.
    @Published var connections: [String: String] = [:]
    /// Cached executable tools of the user's ACTIVE toolkits, refreshed alongside
    /// `refresh()`. Read synchronously by the dictation pipeline to inject connected-app
    /// tools into the Action-mode prompt — never fetched on the dictation hot path.
    @Published var connectedTools: [ComposioTool] = []
    @Published var loading = false
    @Published var lastError: String?

    private static let base = "https://verba.run/api/composio"
    private init() {}

    /// True when the toolkit has an active connected account.
    func isConnected(_ toolkitSlug: String) -> Bool {
        (connections[toolkitSlug.lowercased()] ?? "").uppercased() == "ACTIVE"
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
                        cat: d["cat"] as? String ?? d["category"] as? String ?? ""
                    )
                }

                // Accept either {connections:{slack:"ACTIVE"}} or a list of
                // {toolkit,status} rows — keyed lowercased for stable lookups.
                var map: [String: String] = [:]
                if let dict = c["connections"] as? [String: String] {
                    for (k, v) in dict { map[k.lowercased()] = v }
                } else if let rows = c["connections"] as? [[String: Any]] {
                    for row in rows {
                        if let t = row["toolkit"] as? String {
                            map[t.lowercased()] = row["status"] as? String ?? "ACTIVE"
                        }
                    }
                }
                self.connections = map
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
    func connect(toolkitSlug: String) {
        Task { @MainActor in
            do {
                let obj = try await Self.request("POST", "/connect", body: ["toolkit": toolkitSlug])
                guard let raw = obj["redirectUrl"] as? String ?? obj["redirect_url"] as? String,
                      let url = URL(string: raw) else { throw ComposioError.badResponse }
                NSWorkspace.shared.open(url)
                connections[toolkitSlug.lowercased()] = "INITIATED"
                lastError = nil
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    // MARK: Tools

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
