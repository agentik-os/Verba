import type { Metadata } from "next";
import LegalDoc from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Privacy Policy — Verba",
  description: "How Verba handles your voice, transcripts, and data — on-device by default, with full control over what syncs, how long history is kept, and your connected-app keys.",
  alternates: { canonical: "/privacy" },
};

const MD = `## Verba Privacy Policy

**Effective date:** June 12, 2026

Verba is a native macOS dictation and voice-agent app, and a product of Agentik {OS}, operated by Dafnck Studio (Entreprise Individuelle), founded by Gareth Simono and registered in France ("we", "us", "Verba"). This Privacy Policy explains what data Verba processes, where it goes, and the controls you have. We built Verba to keep your voice on your Mac by default — this policy describes exactly when that is and isn't the case.

We do not sell your personal information.

## 1. Summary — what leaves your Mac

- **Your audio stays on your Mac by default.** In on-device transcription mode (WhisperKit / Parakeet), your microphone audio is converted to text locally and never transmitted to us or any third party.
- **Some features require sending data off-device** — for example AI cleanup, live translation, or the JARVIS voice agent using a cloud AI provider, and JARVIS actions on connected apps. These are described below.
- **You can stay fully local.** Using on-device transcription with a local AI model (Ollama) and without signing in keeps essentially all processing on your machine.

## 2. Information We Process

**Voice and audio.** With on-device transcription, audio is processed locally and not sent to us. If you choose a cloud AI provider for transcription, cleanup, translation, or JARVIS, the relevant text (and, where you have selected a cloud transcription path, audio) is sent to that provider under your own credentials — see "Bring-Your-Own-AI" below.

**Transcripts and notes.** Transcriptions and notes are stored locally on your Mac. If you are signed in, they may be synced to our backend so they are available across your sessions/devices. If you are not signed in, they are not synced to us.

**Account data.** When you create an account or sign in, our authentication provider (Clerk) processes your email and authentication identifiers so we can recognize you and sync your data.

**Billing data.** Subscriptions are processed by Stripe. Stripe handles your payment-card details; we do not store full card numbers. We receive limited billing metadata (subscription status, plan, last four digits, billing country) to operate your subscription.

**Connected-app credentials (JARVIS).** When you connect third-party apps for JARVIS to act on (via Composio), the access tokens/keys for those apps are held server-side by us / Composio so actions can be relayed on your behalf. These connected-app keys are **not** stored on your Mac. JARVIS actions are relayed server-side; your local machine does not hold those credentials.

**Bring-Your-Own-AI keys.** If you supply your own AI provider key (Anthropic, OpenAI, OpenRouter) or use a Claude plan / Claude Code, that key is stored in the macOS Keychain on your device. We do not collect or transmit your BYO-AI key to our servers; your app sends requests to the chosen provider directly under your key.

**Diagnostic and usage data.** We may process limited app usage and technical/diagnostic information to operate, secure, and improve Verba. We do not use it to build advertising profiles.

## 3. How We Use Information

We process data to: provide transcription, AI cleanup, translation, and the JARVIS agent; authenticate you and sync your transcripts/notes when signed in; operate billing and subscriptions; relay JARVIS actions to connected apps you authorize; provide support; secure the service; and comply with legal obligations.

## 4. Cookies & Tracking

The Verba macOS app does not rely on advertising cookies. Our website and account/billing flows (Clerk, Stripe) may use strictly necessary cookies to keep you signed in and to process payments, and limited analytics. We do not use tracking for advertising.

## 5. Third Parties We Share With

We share data only with service providers needed to operate Verba, and only as necessary for their function:

- **The AI provider you choose** (Anthropic, OpenAI, OpenRouter, or local Ollama) — receives the text/audio you send for cleanup, translation, transcription, or JARVIS, under your own key/plan. Local Ollama receives nothing off-device.
- **Composio** — relays JARVIS actions to the 1,000+ apps you connect, and holds the connected-app credentials server-side.
- **Stripe** — payment and subscription processing.
- **Clerk** — account authentication.

Each provider acts under its own privacy terms. We do not sell your personal information, and we do not share it for third-party advertising.

## 6. Data Retention & The Off-Switch

- **Local data** (audio in on-device mode, transcripts/notes when not signed in, BYO-AI keys in Keychain) lives on your Mac and is removed when you delete it or uninstall the app.
- **Synced transcripts/notes** are retained while your account is active and deleted when you delete them or close your account.
- **Connected-app credentials** are retained until you disconnect the app or close your account, after which they are revoked/deleted.
- **Billing records** are retained as required for accounting and legal compliance.

**The off-switch:** You can turn off cloud sync by not signing in (or signing out), keep transcription fully on-device, and use a local Ollama model — in that configuration Verba processes essentially everything locally. Disconnecting a JARVIS app deletes its server-side credentials.

## 7. Your Rights

Subject to applicable law (including the GDPR, as we are established in France), you may request to access, correct, delete, or export your personal data, and withdraw consent or object to certain processing. You can delete local data directly in the app and request deletion of synced/account data by contacting us. To exercise these rights, email **studio@dafnck.com**.

## 8. Security

Data in transit to our backend and to providers is encrypted (TLS). BYO-AI keys are stored in the macOS Keychain. We apply reasonable technical and organizational measures to protect data, though no method of transmission or storage is perfectly secure.

## 9. Children

Verba is not directed to children under 16, and we do not knowingly collect their data.

## 10. Changes

We may update this policy; material changes will be reflected by a new effective date and, where appropriate, in-app or website notice.

## 11. Contact

- General / privacy questions: **hello@agentik-os.com**
- Data-protection & rights requests: **studio@dafnck.com**

Data controller: Dafnck Studio (Entreprise Individuelle), Gareth Simono, Paris, France.`;

export default function Page() {
  return <LegalDoc title="Privacy Policy" md={MD} />;
}
