import type { Metadata } from "next";
import LegalDoc from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Terms of Service — Verba",
  description: "The Terms of Service for Verba, the native macOS AI dictation app by Agentik OS: subscriptions, the JARVIS voice agent, bring-your-own-AI, and acceptable use.",
  alternates: { canonical: "/terms" },
};

const MD = `## Verba Terms of Service

**Effective date:** June 12, 2026

These Terms of Service ("Terms") govern your use of Verba, a native macOS dictation and voice-agent application, and a product of Agentik {OS}, operated by Dafnck Studio (Entreprise Individuelle), founded by Gareth Simono and registered in France ("we", "us", "Verba"). By downloading, installing, or using Verba, you agree to these Terms. If you do not agree, do not use Verba.

## 1. The Service

Verba provides on-device voice-to-text transcription (WhisperKit / Parakeet), AI-assisted text cleanup in any app, live translation, and JARVIS — a voice agent that can act on 1,000+ connected apps via Composio. We may add, modify, or discontinue features. We reserve the right to modify the Service to maintain quality, security, and compliance.

## 2. License

We grant you a personal, non-exclusive, non-transferable, revocable license to install and use Verba on Macs you own or control, for your own use, subject to these Terms. You may not reverse-engineer (except as permitted by law), resell, sublicense, or redistribute the app, or use it to build a competing product.

## 3. Accounts

Some features (cloud sync, billing, JARVIS) require an account, authenticated via Clerk. You are responsible for keeping your credentials secure and for activity under your account.

## 4. Subscriptions, Billing & Refunds

- Verba offers a free tier of **33 dictations**. Continued use of paid features requires a subscription.
- Paid plans are **$9.99 USD / month** or **$84 USD / year**, billed through **Stripe**.
- Subscriptions **renew automatically** at the end of each billing period until cancelled. You can cancel at any time; cancellation takes effect at the end of the current paid period and you retain access until then.
- Prices and plans may change on a prospective basis with notice; changes do not affect the period you have already paid for.
- **Refunds:** To the extent required by applicable French and EU consumer law, you may be entitled to a refund or right of withdrawal. Outside any mandatory statutory right, fees already paid are generally non-refundable. Refund requests: **hello@agentik-os.com**.

## 5. Acceptable Use

You agree to use Verba lawfully and not to: use it for unlawful, infringing, harassing, or harmful purposes; transcribe or record others without any consent required by law; attempt to disrupt, attack, or gain unauthorized access to the Service; or use JARVIS to perform actions you are not authorized to perform on a connected service. You are responsible for complying with recording-consent laws in your jurisdiction.

## 6. Bring-Your-Own-AI (BYO-AI)

Verba lets you connect your own AI provider (a Claude plan / Claude Code, or an Anthropic, OpenAI, or OpenRouter key, or local Ollama). Your use of those providers is governed by **their** terms and pricing, and you are responsible for your own usage, costs, and key security. We are not responsible for the availability, accuracy, output, or acts of third-party AI providers, and AI output may be inaccurate — review it before relying on it.

## 7. JARVIS & Connected Apps — Your Responsibility

JARVIS can take actions on apps you connect via Composio, relayed on your behalf server-side. **You are solely responsible for which apps you connect and for the actions you instruct JARVIS to perform**, including any sending, deleting, posting, purchasing, or modifying of data in those apps. We do not review or guarantee individual actions and are not liable for the consequences of actions you authorize. Disconnect any app at any time to revoke access.

## 8. Intellectual Property

Verba, including its software, branding, and design, is owned by us and our licensors. Your transcripts, notes, and content remain yours; we claim no ownership over them. We retain rights in our methodology, technology, and improvements.

## 9. Confidentiality

We treat your synced content as confidential and access it only as needed to operate, secure, support, and improve the Service, or as required by law, consistent with our Privacy Policy.

## 10. Warranty Disclaimer

VERBA IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. We do not warrant that transcription, translation, or AI output will be accurate or that the Service will be uninterrupted or error-free. This does not exclude warranties that cannot be excluded under applicable law.

## 11. Limitation of Liability

To the maximum extent permitted by law, we are not liable for indirect, incidental, special, or consequential damages, or loss of data or profits. Our total liability for any claim relating to the Service is limited to the amounts you paid us for Verba in the twelve (12) months before the claim. Nothing limits liability that cannot be limited under applicable law.

## 12. Termination

You may stop using Verba and cancel your subscription at any time. We may suspend or terminate access for breach of these Terms or unlawful use. On termination, your license ends; you may export or delete your data as described in the Privacy Policy.

## 13. Governing Law

These Terms are governed by French law. Disputes are subject to the competent French courts, without prejudice to any mandatory consumer-protection rights you have in your country of residence.

## 14. Changes

We may update these Terms; material changes take effect on a new effective date and, where appropriate, with in-app or website notice. Continued use after changes means you accept the updated Terms.

## 15. Contact

Questions about these Terms: **hello@agentik-os.com**. Operating entity: Dafnck Studio (Entreprise Individuelle), Gareth Simono, Paris, France.`;

export default function Page() {
  return <LegalDoc title="Terms of Service" md={MD} />;
}
