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

    /// True when a non-Pro user has used up their free Pro-trial dictations.
    static func freeLimitReached() -> Bool {
        !Settings.shared.isPro && Stats.shared.totalCount >= freeTrialDictations
    }

    static func trialsRemaining() -> Int {
        max(0, freeTrialDictations - Stats.shared.totalCount)
    }

    /// Verify an email against the live subscription and return whether it's active.
    static func verify(email: String) async -> Bool {
        guard var c = URLComponents(string: endpoint), !email.isEmpty else { return false }
        c.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = c.url else { return false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct R: Decodable { let active: Bool }
            return (try? JSONDecoder().decode(R.self, from: data))?.active ?? false
        } catch {
            return false
        }
    }
}
