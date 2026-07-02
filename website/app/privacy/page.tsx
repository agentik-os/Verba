import type { Metadata } from "next";
import LegalDoc from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Privacy Policy, Verba",
  description:
    "How Verba handles your voice and data: on-device by default on macOS, Apple speech on iOS, our included AI (OpenRouter/Anthropic) or your own key, Convex sync you control, and exactly which third parties see what.",
  alternates: { canonical: "/privacy" },
};

const MD = `## Verba Privacy Policy

**Effective date:** July 2, 2026

Verba is a native macOS dictation and voice-agent app (with a companion iOS app), and a product of Agentik {OS}, operated by Dafnck Studio (Entreprise Individuelle), founded by Gareth Simono and registered in France ("we", "us", "Verba"). This Privacy Policy explains what data Verba processes, where it goes, and the controls you have. We built Verba to keep your voice on your device by default; this policy describes exactly when that is and isn't the case.

We do not sell your personal information, and we do not use your voice, transcripts, or content to train AI models.

## 1. Summary, what leaves your device

- **On macOS, your audio stays on your Mac by default.** With on-device transcription (WhisperKit or Parakeet), your microphone audio is turned into text locally and never sent to us or any third party.
- **On iOS**, dictation uses Apple's speech recognition, so audio is processed by **Apple** (on-device where the device supports it, otherwise on Apple's servers). See §2.
- **Some features send data off-device**, e.g. our included AI cleanup, live translation, and the JARVIS voice agent (a cloud AI provider), plus JARVIS actions on the apps you connect. These are detailed below.
- **You can stay essentially fully local on macOS**: on-device transcription + a local AI model (Ollama) + not signing in keeps almost all processing on your machine.

## 2. Information We Process, and where it goes

**Voice and audio.**
- *macOS, on-device mode (default):* audio is transcribed locally (WhisperKit / Parakeet) and is not sent to us or anyone.
- *macOS, cloud transcription (OpenAI, optional):* if you choose it, audio is sent to OpenAI under your own key.
- *iOS:* dictation uses Apple's Speech framework (SFSpeechRecognizer). To favor accuracy, your audio may be sent to Apple for recognition, which Apple processes under its own privacy terms. We never receive your raw audio.

**AI cleanup, translation, and JARVIS (text).** After transcription, the *text* may be rewritten or translated by an AI, through one of:
- *Your own AI (Bring-Your-Own):* your Anthropic, OpenAI, or OpenRouter key, or your Claude plan via Claude Code, the request goes directly to that provider under your credentials. Claude Code runs the local \`claude\` CLI on your Mac.
- *Verba's included AI (signed in, no key set):* the transcript text (and, in Context mode, a screenshot you trigger) is sent to our relay at verba.run, which processes it through **OpenRouter** (primary) and **Anthropic** (fallback) under our keys. Requests are tied to your account; we do not use them to train models.
- *Local model (Ollama):* runs on your Mac; nothing leaves the device.

**Transcripts, notes, tasks, and settings.** Stored locally on your device. If you sign in, they sync to our backend (**Convex**) so they follow your account across devices: dictation history, notes, to-dos, per-day usage stats, app settings, and your custom modes, styles, snippets, transforms and personal dictionary. If you do not sign in, none of this syncs to us.

**Account data.** Sign-in is handled by **Clerk**, which processes your email and authentication identifiers so we can recognize you and sync your data.

**Billing data.** Subscriptions run on **Stripe**. Stripe handles your card details; we do not store full card numbers, only limited billing metadata (plan, status, last four digits, billing country).

**Connected-app credentials (JARVIS).** When you connect third-party apps for JARVIS to act on (via **Composio**), the OAuth tokens/keys for those apps are held server-side by us / Composio so actions can be relayed on your behalf. Google-based connections (e.g. Gmail) authenticate through Google. These connected-app credentials are **not** stored on your Mac.

**Bring-Your-Own-AI keys.** Any AI provider key you supply (Anthropic, OpenAI, OpenRouter) is stored in the macOS **Keychain** on your device. We do not collect or transmit it; your app calls the provider directly under your key.

**Public profile (opt-in).** If you turn on the leaderboard, a public profile (your chosen alias, level, badges, and dictation stats) is stored and visible to other users. It is off unless you enable it, and you can turn it off at any time.

**Feedback.** Feedback you send from the app is stored in our backend and filed as a ticket in **Linear** so we can act on it, together with the context you include (app version, OS, active mode, and your alias/email if signed in).

**Diagnostic and usage data.** We process limited technical and usage information to operate, secure, and improve Verba. We do not use it to build advertising profiles.

## 3. How We Use Information

To provide transcription, AI cleanup, translation and the JARVIS agent; authenticate you and sync your content when signed in; operate billing; relay JARVIS actions to the apps you authorize; run the opt-in leaderboard; handle support and feedback; secure the service; and comply with legal obligations.

## 4. Cookies, Analytics & Advertising

The Verba **apps** (macOS and iOS) contain no advertising SDKs and no ad tracking.

Our **website** (verba.run) uses:
- **Vercel Analytics**, privacy-friendly, aggregate traffic measurement.
- **Google Ads (gtag.js)**, a conversion tag that measures ad performance (for example, whether a visit from an ad led to a download or sign-up). It sets a Google cookie on the website only, and is not present in the apps.
- **Clerk** and **Stripe** set strictly-necessary cookies to keep you signed in and to process payments.

You can block cookies in your browser; the apps are unaffected.

## 5. Third Parties We Share With

We share data only with the service providers needed to run Verba, each acting under its own privacy terms and only for its function:

- **Apple** (iOS), speech recognition of your dictation audio.
- **OpenRouter** and **Anthropic**, our included AI cleanup / translation / JARVIS (server-side, under our keys); or **Anthropic / OpenAI / OpenRouter** directly under your key if you bring your own. **Ollama** (local) receives nothing off-device.
- **Composio**, relays JARVIS actions to the 1,000+ apps you connect and holds those connected-app credentials server-side.
- **Google**, OAuth for Google-based connected apps (e.g. Gmail), and Google Ads conversion measurement on the website.
- **Convex**, our sync backend for your account content.
- **Clerk**, account authentication. **Stripe**, payments. **Linear**, feedback tickets. **Vercel**, website hosting and analytics.

We do not sell your personal information, and we do not share it for third-party advertising beyond the conversion measurement described above.

## 6. Data Retention & The Off-Switch

- **Local data** (audio in on-device mode, transcripts/notes when not signed in, BYO-AI keys in the Keychain) lives on your device and is removed when you delete it or uninstall the app.
- **Synced content** (history, notes, tasks, stats, settings, custom modes and the rest) is kept while your account is active and deleted when you delete it or close your account.
- **Connected-app credentials** are kept until you disconnect the app or close your account, after which they are revoked/deleted.
- **Billing records** are kept as required for accounting and legal compliance.

**The off-switch (macOS):** do not sign in (or sign out) to disable cloud sync, keep transcription on-device, and use a local Ollama model, in that configuration Verba processes essentially everything locally. Disconnecting a JARVIS app deletes its server-side credentials. On iOS, dictation relies on Apple's speech recognition by design.

## 7. Your Rights

Subject to applicable law (including the GDPR, as we are established in France), you may access, correct, delete, or export your personal data, and withdraw consent or object to certain processing. You can delete local data directly in the app and request deletion of synced/account data by contacting us. To exercise these rights, email **studio@dafnck.com**.

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
