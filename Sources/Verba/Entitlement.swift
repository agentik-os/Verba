import Foundation

/// THE ONE FREE/PRO CONTRACT (mirrored in website/lib/billing.ts, README.md and /docs):
///
///   Free  Unlimited raw dictation, forever, no card. Raw is NEVER paywalled and never
///         stops working, whatever this file returns.
///   Pro   Every AI mode (Polish, Intent, Translate, Context, Prompt, custom), plus Notes,
///         Tasks and JARVIS. $9.99/month, $84/year, or a one-time $149 Founder's Edition.
///
/// Stripe is the single source of truth, checked by email through verba.run/api/entitlement.
///
/// TWO SEPARATE THINGS ARE BOTH CALLED "THE TRIAL", and confusing them is the reason this
/// file used to read as if all dictation stopped at 33:
///   1. The included AI-mode allowance below: `freeTrialDictations`, enforced locally, no card.
///   2. The 7-day Stripe checkout trial: card required, starts at checkout, enforced by Stripe
///      (`trial_period_days: 7`), invisible to this file. A user inside it comes back `active`.
enum Entitlement {
    static let pricingURL = "https://verba.run/#pricing"
    static let accountURL = "https://verba.run/account"
    private static let endpoint = "https://verba.run/api/entitlement"

    /// How many dictations a Free user may run through an AI MODE before the paywall appears.
    /// Raw dictation is unaffected: it stays free and unlimited past this number, forever.
    ///
    /// CAVEAT, and it is deliberate rather than a bug to silently "fix" here: the counter is
    /// `Stats.totalCount`, which counts EVERY dictation, raw ones included. So raw usage does
    /// spend this allowance even though raw itself is never blocked. The single enforcement
    /// point is AppDelegate.startRecording, which refuses to start only when the active mode
    /// is not raw. Renaming or re-sourcing this counter touches files outside this one.
    static let freeTrialDictations = 33

    /// How much of the allowance should remain before the UI warns the user, so the paywall at
    /// dictation \(freeTrialDictations) is not a surprise. Consumed only by `trialWarningActive()`.
    static let trialWarningThreshold = 5

    /// True when a non-Pro user has spent their included AI-mode allowance.
    /// Callers must still let RAW dictation through: this answers "is the AI locked?", not
    /// "is the app locked?". Nothing about Free stops working when this is true.
    static func freeLimitReached() -> Bool {
        !Settings.shared.isPro && Stats.shared.totalCount >= freeTrialDictations
    }

    /// AI-mode dictations left in the Free allowance. Zero does not mean dictation stops.
    static func trialsRemaining() -> Int {
        max(0, freeTrialDictations - Stats.shared.totalCount)
    }

    /// True for a non-Pro user close to the wall but not yet at it, so the UI can warn softly.
    /// NOT CURRENTLY SURFACED: no view calls this today, so the only signal a Free user gets is
    /// the usage bar in Settings and the one-time nudge at zero. Wire it into the trial card
    /// before relying on it.
    static func trialWarningActive() -> Bool {
        !Settings.shared.isPro && !freeLimitReached() && trialsRemaining() <= trialWarningThreshold
    }

    /// Token-authenticated subscription check.
    ///
    /// ONE RULE GOVERNS THIS WHOLE FUNCTION: only an explicit server "no" (HTTP 200 with
    /// `active: false`) may revoke Pro. Every other outcome is "we do not know", returns
    /// `.unreachable`, and leaves the user's last known state alone. A paying customer must
    /// never lose Pro because of a flaky network, an expired token, or a missing server key.
    ///
    /// EVERY STATE, and where it comes from (see website/app/api/entitlement/route.ts):
    ///   no token locally      .unreachable  migration or signed out, not a revoke
    ///   transport error       .unreachable  offline, DNS, TLS, timeout
    ///   401 unauthenticated   .unreachable  token rejected, drives the re-auth flow
    ///   503 not configured    .unreachable  server has no Stripe key, it cannot answer
    ///   5xx / other non-2xx   .unreachable  Stripe outage or bad key, surfaced as a throw
    ///   200 { active: true }  .active       a real yes
    ///   200 { active: false } .inactive     A REAL NO. The only path that revokes Pro.
    ///
    /// `email` (optional): the checkout email to RESTORE against, appended as `?email=`. Used by
    /// the "Restore a subscription" card so a signed-in user whose app-token email differs from
    /// their Stripe checkout email can still unlock Pro. The server honours it ONLY alongside a
    /// valid token, so this never becomes a way to probe arbitrary emails.
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
            // Catches 503 billing_not_configured and any 5xx: the server could not answer, so
            // neither can we. Decoding the body here would read `active: false` as a revoke.
            guard (200..<300).contains(code) else { return .unreachable }
            // The server also sends `plan` (monthly/annual/lifetime/free) and, on errors, an
            // `error` discriminator. Both are intentionally ignored: the app has a single Pro
            // flag, so decoding a tier it cannot display would only invite drift.
            struct R: Decodable { let active: Bool }
            return ((try? JSONDecoder().decode(R.self, from: data))?.active ?? false) ? .active : .inactive
        } catch { return .unreachable }
    }
}

/// Result of an entitlement check. `.inactive` is an explicit server "no" and is the only real
/// revoke; `.unreachable` means "unknown", and callers must keep the last known state.
enum ProStatus { case active, inactive, unreachable }
