import SwiftUI

/// Submits an iPhone TestFlight beta-signup to the verba.run website endpoint, which stores it
/// durably in Convex (deduped by email) and pings the operator. Mirrors `Feedback.submit`: the
/// app never holds any key — it just POSTs the email + light context to /api/beta-signup, and an
/// app-session bearer (when signed in) lets the server record the originating account.
enum BetaInvite {
    private static let endpoint = "https://verba.run/api/beta-signup"

    /// Basic client-side email format check. The server validates again; this only keeps the
    /// "Request invite" button honest so we never POST an obviously malformed address.
    static func looksLikeEmail(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 6, t.count <= 254, !t.contains(" ") else { return false }
        let parts = t.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    /// POST the signup. Calls back with `nil` on success or a human-readable error string.
    static func submit(email: String, _ done: @escaping (String?) -> Void) {
        let s = Settings.shared
        let body: [String: Any] = [
            "email": email,
            "deviceAlias": s.username,
            "appVersion": Updater.currentVersion,
            "uid": s.uid,
        ]
        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            finish(done, "Couldn't prepare the request. Please try again.")
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        AuthToken.bearer(&req)   // lets the server record which account the signup came from
        req.httpBody = httpBody
        req.timeoutInterval = 30

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                finish(done, "No response from server. Check your connection and try again.")
                return
            }
            if obj["ok"] as? Bool == true {
                finish(done, nil)
            } else {
                let msg = (obj["error"] as? String) ?? "Couldn't submit right now. Please try again later."
                finish(done, msg)
            }
        }.resume()
    }

    private static func finish(_ done: @escaping (String?) -> Void, _ msg: String?) {
        DispatchQueue.main.async { done(msg) }
    }
}

/// The iPhone-beta invite sheet, opened from the small card in the sidebar footer.
/// Explains the TestFlight beta, collects the user's iCloud email, and submits it durably.
/// Pre-filled with the signed-in account email (editable, since TestFlight needs the iCloud one).
struct BetaInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appearance = VerbaAppearance.shared

    @State private var email = Settings.shared.proEmail
    @State private var submitting = false
    @State private var done = false
    @State private var error: String?

    private var validEmail: Bool { BetaInvite.looksLikeEmail(email) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: iPhone glyph + title/subtitle (mirrors the CredentialConnectView sheet grammar).
            HStack(spacing: 11) {
                Image(systemName: "iphone")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(appearance.accentColor)
                    .frame(width: 30, height: 30)
                    .background(appearance.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Verba is coming to iPhone")).font(.system(size: 16, weight: .bold))
                    Text(done ? L("You're on the list.") : L("Want early access?"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            Divider()

            if done {
                successBody
            } else {
                formBody
            }

            Divider()
            footer
        }
        .frame(width: 440)
        .background(VisualEffectView().ignoresSafeArea())
    }

    private var formBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("If you have an iPhone, share your iCloud email and we'll send you a TestFlight invite. You'll accept it by email."))
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(L("iCloud email")).font(.system(size: 11, weight: .medium))
                TextField(L("you@icloud.com"), text: $email)
                    .textFieldStyle(.plain).font(.system(size: 13))
                    .padding(.horizontal, 9).padding(.vertical, 8)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                    .onChange(of: email) { _, _ in if error != nil { error = nil } }
                    .onSubmit { if validEmail && !submitting { submit() } }
                Text(L("Use the email tied to your iPhone's Apple ID. TestFlight sends the invite there, so it can differ from your Verba account email."))
                    .font(.system(size: 10.5)).foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    private var successBody: some View {
        HStack(spacing: 11) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24)).foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(L("You're on the list.")).font(.system(size: 14, weight: .semibold))
                Text(L("Watch your inbox for a TestFlight invite. You'll accept it right from the email."))
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 22)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if done {
                Spacer()
                Button(L("Done")) { dismiss() }
                    .dialogPrimary(tint: appearance.accentColor)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(L("Cancel")) { dismiss() }.dialogSecondary()
                Spacer()
                Button(action: submit) {
                    Group {
                        if submitting { ProgressView().controlSize(.small) }
                        else { Text(L("Request invite")) }
                    }.frame(minWidth: 120)
                }
                .dialogPrimary(tint: appearance.accentColor)
                .disabled(!validEmail || submitting)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }

    private func submit() {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard BetaInvite.looksLikeEmail(e), !submitting else { return }
        submitting = true
        error = nil
        BetaInvite.submit(email: e) { err in
            submitting = false
            if let err {
                error = err
            } else {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { done = true }
            }
        }
    }
}
