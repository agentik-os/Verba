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
            // The server returns this account's stable referral code → use it as our link.
            if let code = comps.queryItems?.first(where: { $0.name == "code" })?.value, !code.isEmpty {
                DispatchQueue.main.async { Settings.shared.referralCode = code }
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
}
