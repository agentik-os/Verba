import AppKit
import AuthenticationServices
import Foundation

/// The app-session token (HMAC-signed by verba.run at sign-in). It proves "this device
/// belongs to <email>/<code>" to the protected API routes and to Convex device
/// registration. Keychain-persisted; cleared on sign-out.
enum AuthToken {
    static var current: String? {
        let t = Keychain.get("app_session_token")
        return (t?.isEmpty == false) ? t : nil
    }
    static func set(_ t: String?) { Keychain.set(t ?? "", for: "app_session_token") }
    static func bearer(_ req: inout URLRequest) {
        if let t = current { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
    }
}

/// Real sign-in via the web: opens the Clerk-hosted sign-in/sign-up page on verba.run
/// (Google, email, etc.), and captures the authenticated email through a `verba://`
/// callback. No mock, the account is created in Clerk, and the affiliate ref is linked
/// server-side during the flow.
final class AuthSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthSession()
    private var session: ASWebAuthenticationSession?

    /// Starts the hosted flow. Completion gets the verified email (or nil if cancelled).
    func signIn(completion: @escaping (String?) -> Void) {
        // The referrer (if any) is attributed from the web cookie set when the user
        // clicked an affiliate link, not from this device's own code.
        var c = URLComponents(string: "https://verba.run/app-auth")!
        c.queryItems = [URLQueryItem(name: "scheme", value: "verba")]
        guard let url = c.url else { completion(nil); return }

        let s = ASWebAuthenticationSession(url: url, callbackURLScheme: "verba") { callback, _ in
            guard let callback,
                  let comps = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                  let email = comps.queryItems?.first(where: { $0.name == "email" })?.value,
                  !email.isEmpty else {
                completion(nil); return
            }
            // Keep the anonymous generated alias, never the real name: the alias is PUBLIC on the
            // leaderboard, so we deliberately do NOT adopt the Clerk first/last name here.

            // The app-session token proves this device belongs to the account; it authorizes
            // the protected API routes and the Convex device registration below.
            //
            // NO TOKEN = FAILED SIGN-IN, never a silent sign-out. A callback that carries an email but
            // no token (the server-side link step failed, or answered without one) used to be written
            // straight through, and `AuthToken.set(nil)` CLEARS the Keychain — so a user who was
            // ALREADY signed in came back from a "Done!" web page holding no token at all, and from
            // then on every JARVIS plan and every authed connected-apps call threw `.notSignedIn`.
            // Bail BEFORE mutating anything: the stored token, the account identity and the connected
            // apps all survive untouched, and the failure travels the same `nil` path a cancelled
            // sign-in already takes, which every caller treats as a failure rather than a success.
            guard let token = comps.queryItems?.first(where: { $0.name == "token" })?.value,
                  !token.isEmpty else {
                VerbaLog.app.error("sign-in callback carried no app-session token; keeping the stored one")
                ErrorReporter.report("sign-in callback carried no app-session token",
                                     context: ["area": "auth"])
                completion(nil)
                // Say it out loud: the web page's own "Done!" is the last thing the user saw, and two
                // of the four sign-in entry points just reset their button on `nil`, so without this
                // the failure would be invisible.
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    let alert = NSAlert()
                    alert.messageText = "Sign-in didn't complete"
                    alert.informativeText = "The web step finished but this Mac didn't receive a session, so nothing changed here. Please try signing in again."
                    alert.addButton(withTitle: "OK")
                    _ = alert.runModal()
                }
                return
            }
            AuthToken.set(token)

            // Connected apps are account-scoped and the store is a singleton: without this reset a
            // second account inherited the first one's Connected badges, its "Connecting…" cards and
            // its executable tools. Re-warming right after is what makes the freshly signed-in
            // account's apps usable in Action mode without reopening the connections view.
            Task { @MainActor in
                ComposioStore.shared.resetForAccountChange()
                ComposioStore.shared.refresh()
            }

            // The server returns this account's stable referral code → adopt it as the identity.
            // Re-key any data written under the device-minted uid so nothing forks on sign-in.
            if let code = comps.queryItems?.first(where: { $0.name == "code" })?.value, !code.isEmpty {
                DispatchQueue.main.async {
                    let old = Settings.shared.uid
                    Settings.shared.referralCode = code
                    Settings.shared.proEmail = email.lowercased()   // so uid resolves to the account code
                    ConvexClient.registerDevice(token: token)       // claim the account uid BEFORE any authed sync
                    Settings.shared.needsReauth = false             // fresh token → re-auth satisfied
                    if old != Settings.shared.uid {
                        Leaderboard.remove(uid: old)        // drop the orphan device-uid score row (device secret is registered under it)
                        Leaderboard.submit()                // re-submit under the account uid
                        History.shared.pushAll()            // re-key local history to the account
                        History.shared.syncFromCloud()      // pull anything from other Macs
                    }
                }
            }
            completion(email.lowercased())
        }
        s.presentationContextProvider = self
        s.prefersEphemeralWebBrowserSession = false   // reuse the browser session (Google stays signed in)
        session = s
        s.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.windows.first(where: { $0.isVisible }) ?? NSApp.windows.first ?? ASPresentationAnchor()
    }

    /// The clean inverse of `signIn`: detach the account from this device. Clears the
    /// account identity (proEmail + referralCode) so `uid` reverts to the device-minted
    /// uid, drops Pro, and re-keys the uid-scoped data (Leaderboard, History) the same way
    /// sign-in did, just in the other direction. It deliberately does NOT touch the user's
    /// local notes / transcripts / to-dos, sign-out is an account detach, not a data wipe.
    @MainActor
    func signOut() {
        let old = Settings.shared.uid
        AuthToken.set(nil)                          // drop the app-session token (the device secret stays: it still authenticates the device uid)
        ComposioStore.shared.resetForAccountChange()  // connected apps belong to the account, not the device: drop their statuses, pending OAuth and cached tools
        Settings.shared.referralCode = ""           // empty referral → uid resolves to the device-minted "anon-…" uid
        Settings.shared.proEmail = ""
        Settings.shared.isPro = false               // Pro is account-bound; signing out drops the entitlement
        Settings.shared.needsReauth = false
        if old != Settings.shared.uid {
            Leaderboard.remove(uid: old)            // drop the account-uid score row
            if Settings.shared.showOnLeaderboard {
                Leaderboard.submit()                // re-submit under the device uid (username is local, so this is safe)
            }
            // Note: History push/pull are account-only (they guard on proEmail), so once
            // signed out the local history simply stays local. We keep the user's notes,
            // transcripts and to-dos untouched, this is an account detach, not a data wipe.
        }
    }
}
