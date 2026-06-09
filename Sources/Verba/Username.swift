import Foundation

/// Syncs the PUBLIC leaderboard username (a deliberate handle the user chooses,
/// NEVER their real name or email) with the Clerk user via verba.run.
///
/// Clerk's `publicMetadata.username` is the cross-device source of truth:
///  - On sign-in / launch we GET it and, if set, adopt it into `Settings.username`
///    so the handle follows the account across Macs and the web.
///  - When the user sets/changes the username (onboarding or Settings) we POST it
///    so Clerk becomes the source of truth. Best-effort and non-blocking; any
///    network failure is ignored — the local value still works locally.
enum Username {
    private static let endpoint = "https://verba.run/api/username"

    /// Fetch the Clerk username for the signed-in account. The account is identified by the
    /// app-session token (Authorization: Bearer …), never by a spoofable email parameter; the
    /// `email` argument is kept for call-site compatibility but only gates "are we signed in".
    static func fetch(email: String) async -> String? {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, let url = URL(string: endpoint) else { return nil }
        var req = URLRequest(url: url)
        AuthToken.bearer(&req)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            struct R: Decodable { let username: String? }
            let r = try? JSONDecoder().decode(R.self, from: data)
            let name = r?.username?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (name?.isEmpty == false) ? name : nil
        } catch {
            return nil
        }
    }

    /// Clamp a handle to what the server accepts (≤24 chars, single spaces), so a long
    /// or oddly-spaced handle never silently fails to sync (the POST would 400 and be
    /// swallowed). Mirrors the /api/username server validation's length + whitespace rules.
    static func sanitize(_ raw: String) -> String {
        let collapsed = raw.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return String(collapsed.prefix(24))
    }

    /// Push the username to Clerk for the signed-in account. Best-effort: failures are
    /// swallowed. The target account comes from the app-session token, never from the body;
    /// the `email` argument is kept for call-site compatibility (signed-in gate only).
    static func push(_ username: String, email: String) async {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = sanitize(username)
        guard !email.isEmpty, !username.isEmpty, let url = URL(string: endpoint) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthToken.bearer(&req)
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username])
        _ = try? await URLSession.shared.data(for: req)
    }

    /// On sign-in / launch: if Clerk already has a username, adopt it locally (so it
    /// syncs across devices); if Clerk has none, seed Clerk from the local username
    /// so this device's handle becomes the account's source of truth.
    @MainActor
    static func reconcileOnSignIn() async {
        let email = Settings.shared.proEmail
        guard !email.isEmpty else { return }
        if let remote = await fetch(email: email) {
            if remote != Settings.shared.username {
                Settings.shared.username = remote   // $username sink re-submits the leaderboard
            }
        } else {
            // Clerk has no username yet → publish this device's current one.
            await push(Settings.shared.username, email: email)
        }
    }
}
