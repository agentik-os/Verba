import AppKit
import AuthenticationServices

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

            // The server returns this account's stable referral code → adopt it as the identity.
            // Re-key any data written under the device-minted uid so nothing forks on sign-in.
            if let code = comps.queryItems?.first(where: { $0.name == "code" })?.value, !code.isEmpty {
                DispatchQueue.main.async {
                    let old = Settings.shared.uid
                    Settings.shared.referralCode = code
                    Settings.shared.proEmail = email.lowercased()   // so uid resolves to the account code
                    if old != Settings.shared.uid {
                        Leaderboard.remove(uid: old)        // drop the orphan device-uid score row
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
        Settings.shared.referralCode = ""           // empty referral → uid resolves to the device-minted "anon-…" uid
        Settings.shared.proEmail = ""
        Settings.shared.isPro = false               // Pro is account-bound; signing out drops the entitlement
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
