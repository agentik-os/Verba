import Foundation

/// Free vs Pro. Pro unlocks editing the reprompting system prompts (full control
/// over how Verba reinterprets your audio) and creating custom modes.
/// Source of truth is the Stripe subscription, checked by email via verba.run.
enum Entitlement {
    static let pricingURL = "https://verba.run/#pricing"
    static let accountURL = "https://verba.run/account"
    private static let endpoint = "https://verba.run/api/entitlement"

    /// Free plan = a full-Pro trial of this many dictations, then the paywall kicks in.
    static let freeTrialDictations = 33

    /// How many trial dictations remain before we start warning the user, so the
    /// dictation-33 paywall isn't a surprise. Surfaced by the trial card / a one-time nudge.
    static let trialWarningThreshold = 5

    /// True when a non-Pro user has used up their free Pro-trial dictations.
    static func freeLimitReached() -> Bool {
        !Settings.shared.isPro && Stats.shared.totalCount >= freeTrialDictations
    }

    static func trialsRemaining() -> Int {
        max(0, freeTrialDictations - Stats.shared.totalCount)
    }

    /// True for a non-Pro user who is close to the wall (but not yet at it): the UI should
    /// show a soft warning so the paywall at dictation \(freeTrialDictations) is expected.
    static func trialWarningActive() -> Bool {
        !Settings.shared.isPro && !freeLimitReached() && trialsRemaining() <= trialWarningThreshold
    }

    /// Token-authenticated subscription check. `.unreachable` (offline, server error, or a
    /// rejected/missing token) is deliberately distinct from `.inactive`: only an explicit
    /// server "no" revokes Pro — everything else goes through the S7 offline-grace window.
    /// `email` (optional): the checkout email to RESTORE against, appended as `?email=`. Used by the
    /// "Restore a subscription" card so a signed-in user whose app-token email differs from their
    /// Stripe checkout email can still unlock Pro. The server only honours it alongside a valid token.
    static func check(email: String? = nil) async -> ProStatus {
        guard AuthToken.current != nil else { return .unreachable }   // migration: no token yet ≠ revoke
        var comps = URLComponents(string: endpoint)
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            comps?.queryItems = [URLQueryItem(name: "email", value: email)]
        }
        guard let url = comps?.url else { return .unreachable }
        var req = URLRequest(url: url)
        AuthToken.bearer(&req)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code != 401 else { return .unreachable }            // token rejected → re-auth flow, not silent revoke
            guard (200..<300).contains(code) else { return .unreachable }
            struct R: Decodable { let active: Bool }
            return ((try? JSONDecoder().decode(R.self, from: data))?.active ?? false) ? .active : .inactive
        } catch { return .unreachable }
    }
}

/// Result of an entitlement check (S7): an explicit "no" is the only real revoke.
enum ProStatus { case active, inactive, unreachable }
