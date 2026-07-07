# Schema.org structured data audit and recommendations, verba.run

Skill: `structured-data` (Cogny AI). Verified live 2026-07-07 via `curl https://verba.run` and WebFetch, cross-checked against the source in `website/app/layout.tsx` and `website/app/page.tsx`. All prices, versions, and social links below are real values pulled from the live page, nothing fabricated.

## 1. What already exists (verified live)

verba.run already ships four schema types across two script tags. This is a stronger baseline than most sites reaching for this skill start from.

### 1a. Homepage `@graph`, in `<head>` on every page

Source: `website/app/layout.tsx:44-102` (constant `SITE_JSONLD`), confirmed present verbatim in the live page source at `https://verba.run`.

- **`SoftwareApplication`** (`layout.tsx:48-73`), name "Verba", `operatingSystem: "macOS 14+"`, `applicationCategory: "UtilitiesApplication"`, `softwareVersion: "0.9.29"`, `downloadUrl` to the GitHub release, one `Offer` at `price: "9.99"` / `priceCurrency: "USD"` / `availability: InStock` / `priceValidUntil: "2027-12-31"`, `creator` (Gareth Simono), and a `featureList` of 7 items.
- **`WebSite`** (`layout.tsx:74-81`), name "Verba", `url`, `inLanguage: "en"`, `publisher` pointing at the org node.
- **`Organization`** (`layout.tsx:82-100`), `@id: "https://verba.run/#org"`, name "Agentik OS", `logo: "https://verba.run/icon.png"`, `founder` (Gareth Simono), and 8 verified `sameAs` links (GitHub, Instagram, TikTok, YouTube, X, Reddit, Pinterest, Telegram).

### 1b. `FAQPage`, homepage FAQ section

Source: `website/app/page.tsx:1372-1405`. The 18 Q&A pairs are generated from the same `qa` array that renders the visible accordion (`page.tsx:1373-1391`), which is exactly the "keep schema in sync with visible content" best practice the skill calls for. Good structural choice, do not break that coupling when fixing the copy below.

### Verdict on structure

No changes needed to the shape: `SoftwareApplication` + `WebSite` + `Organization` + `FAQPage` is the correct type set for this product page. The problem is entirely in the field values, not the schema choice.

## 2. Hard-rule violations found in the live JSON-LD

Rule check for this deliverable: never name underlying tech in a description field (no Parakeet, Whisper, Claude, Anthropic, GPT, OpenAI, and by the same spirit no OpenRouter or Ollama), never the phrases "reuse your AI", "pay twice", or "bring your own", never the word "cloud". Keep "JARVIS". The live site fails this in several places:

| Field | File:line | Offending text |
|---|---|---|
| `SoftwareApplication.description` | `layout.tsx:53-54` | "Bring your own AI, including your **Claude Code** plan with no key" |
| `SoftwareApplication.featureList[0]` | `layout.tsx:68` | "On-device voice-to-text (**WhisperKit, NVIDIA Parakeet**)" |
| `SoftwareApplication.featureList[5]` | `layout.tsx:71` | "**Bring your own** AI (**Claude, OpenRouter,** local **Ollama**)" |
| FAQ answer, "Can it work offline?" | `page.tsx:1375` | "(**Whisper or Parakeet**)" |
| FAQ answer, "What languages does it understand?" | `page.tsx:1376` | "On-device **Whisper** covers... **Parakeet** is a faster option" |
| FAQ answer, "Do I need an API key?" | `page.tsx:1378` | "**Claude Code** plan... **bring your own Anthropic** key, an **OpenRouter** key, or run a local **Ollama** model... someone's **cloud**" |
| FAQ answer, "What is Context mode?" | `page.tsx:1379` | "(**Anthropic** API key or **OpenRouter** key)" |
| FAQ answer, "How much does Verba cost?" | `page.tsx:1386` | "you **bring your own** AI plan or key" |
| FAQ answer, "Is Verba accurate..." | `page.tsx:1387` | "(**WhisperKit and Parakeet**)" |
| FAQ answer, "Does Verba work offline?" | `page.tsx:1389` | "transcribes your voice locally using **WhisperKit or Parakeet**... **cloud** AI features... (local **Ollama** lets you run AI offline too)" |
| FAQ answer, "Is my data and audio private..." | `page.tsx:1390` | "with **WhisperKit or Parakeet**... by **your own** AI (**your Claude** plan...)... run AI fully locally with **Ollama**" |
| FAQ answer, "What can JARVIS actually do?" | `page.tsx:1391` | "It plans on your Mac with **your own** AI" |

These same strings feed the visible FAQ accordion too (the `qa` array is the single source for both), so fixing them fixes the structured data and the on-page copy in one pass. No em dash or en dash found in the current JSON-LD strings.

## 3. Recommended JSON-LD (sanitized, ready to ship)

### 3a. `Organization`, unchanged, already clean

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": "https://verba.run/#org",
  "name": "Agentik OS",
  "url": "https://verba.run",
  "logo": "https://verba.run/icon.png",
  "founder": { "@type": "Person", "name": "Gareth Simono" },
  "sameAs": [
    "https://github.com/agentik-os",
    "https://www.instagram.com/verba.run/",
    "https://www.tiktok.com/@verba.run",
    "https://www.youtube.com/@VerbaRun",
    "https://x.com/verba_run",
    "https://www.reddit.com/user/VerbaRun/",
    "https://es.pinterest.com/verbarun/",
    "https://t.me/verbarun"
  ]
}
```

No action needed. Verified live, no forbidden terms, no invented facts.

### 3b. `WebSite`, unchanged, already clean

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Verba",
  "url": "https://verba.run",
  "inLanguage": "en",
  "publisher": { "@id": "https://verba.run/#org" }
}
```

No `potentialAction` (`SearchAction`) added: verba.run has no on-site search, so a `SearchAction` would be fabricated. Omit until a real search endpoint exists.

### 3c. `SoftwareApplication`, revised description and featureList

```json
{
  "@type": "SoftwareApplication",
  "name": "Verba",
  "applicationCategory": "UtilitiesApplication",
  "operatingSystem": "macOS 14+",
  "description": "The private Mac voice agent: on-device voice-to-text and AI cleanup in any app, plus JARVIS, a voice agent that acts across 1,000+ connected apps only after you confirm. Works with the AI you already use, no markup.",
  "url": "https://verba.run",
  "downloadUrl": "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg",
  "softwareVersion": "0.9.29",
  "offers": {
    "@type": "Offer",
    "price": "9.99",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock",
    "priceValidUntil": "2027-12-31",
    "url": "https://verba.run"
  },
  "creator": { "@type": "Person", "name": "Gareth Simono" },
  "featureList": [
    "On-device voice-to-text, runs locally on your Mac",
    "AI rewriting and cleanup in any app",
    "Live translation",
    "Reads your screen (Context mode)",
    "JARVIS voice agent, acts across 1,000+ connected apps, only after you confirm",
    "Works with the AI you already use, no markup",
    "15 UI languages"
  ]
}
```

Notes on what was deliberately kept out:
- **`aggregateRating`**: no real rating data exists on the site, so it is omitted rather than invented. Add it only once a genuine review count exists (App Store, Product Hunt, or an on-site review widget), matching the skill's "do not fabricate reviews or ratings" rule.
- **Second `Offer` for the $84/year plan**: the pricing section (`#pricing`) genuinely shows both a monthly ($9.99) and annual ($84, about $7/mo) price, plus a one-time $149 Founder's Edition. Optional upgrade: wrap these in an `AggregateOffer` (`lowPrice: "7"`, `highPrice: "9.99"`, `offerCount: "2"`) or a small `offers` array, since all three numbers are real and currently on-page. Left as a single Offer here to match the existing minimal pattern; flagged as an option, not required.

### 3d. `FAQPage`, all 18 answers sanitized

Same 18 questions, same order, same meaning, tech names and banned phrases removed. This must be applied to the `qa` array in `page.tsx:1374-1391` (not just the JSON-LD block) so the visible accordion and the structured data stay in sync, per the skill's own best practice.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Does it work in every app?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, Verba pastes into whatever you're typing in: editors, browsers, chat apps, mail, notes. If your cursor is there, Verba can write there." }
    },
    {
      "@type": "Question",
      "name": "Can it work offline?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes. On-device transcription runs entirely on your Mac, no internet needed, and your audio never leaves the device." }
    },
    {
      "@type": "Question",
      "name": "What languages does it understand?",
      "acceptedAnswer": { "@type": "Answer", "text": "On-device transcription covers around 99 languages worldwide, with a faster option for 25 European languages. It writes back in the language you spoke." }
    },
    {
      "@type": "Question",
      "name": "How do the AI modes work?",
      "acceptedAnswer": { "@type": "Answer", "text": "Verba ships six modes: Raw (verbatim, no AI, the default), Polish (resolves your self-corrections), Intent, Translate, Context, and Prompt (turns what you say into an optimized prompt for any AI, including coding agents). Each mode is a system prompt that shapes how the model rewrites your speech. Context also takes a screenshot to ground the output in what is on your screen. You can edit any prompt, or just describe what you need and AI builds you a custom mode." }
    },
    {
      "@type": "Question",
      "name": "Do I need an API key?",
      "acceptedAnswer": { "@type": "Answer", "text": "No. Verba can use an AI subscription you already have, so no separate key is required. You can also connect an AI key of your choice, or run a fully local model for complete privacy. There is no markup on the AI you use." }
    },
    {
      "@type": "Question",
      "name": "What is Context mode?",
      "acceptedAnswer": { "@type": "Answer", "text": "Context mode takes a screenshot of your screen, analyzes it with a vision model, and writes based on what you say and what it sees. Say \"reply to this email\" and it drafts a reply to the message on screen. It requires macOS Screen Recording permission and a vision-capable AI connected to your account." }
    },
    {
      "@type": "Question",
      "name": "Can it handle long recordings?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, talk for twenty minutes and Verba turns the whole thing into clean, well-ordered text." }
    },
    {
      "@type": "Question",
      "name": "Is my data private?",
      "acceptedAnswer": { "@type": "Answer", "text": "In on-device mode your audio never leaves your Mac. Transcripts are saved to your local history by default. You can turn history off entirely (nothing written, nothing synced) or auto-delete entries after 7, 30, or 90 days. When you sign in, your history, notes, and stats sync to your account so they follow you across Macs; signed out, nothing is uploaded. API keys live in your macOS Keychain, and you can delete all your account data at any time." }
    },
    {
      "@type": "Question",
      "name": "Can Verba take notes?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes. The Notes tab lets you record up to a full hour of speech and Verba turns it into a clean, structured document. Pick a format before you start: Clean note, Brain dump to outline, Summary, Meeting notes, Journal, Email, Code task, To-do list, or Article outline. Markdown is rendered (headings, bold, checkboxes). You can tag notes with hashtags to file and filter them, edit the result in place, and copy it anywhere." }
    },
    {
      "@type": "Question",
      "name": "Can it create calendar events or reminders?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, with the Labs toggle on in Context mode. Say \"create an event tomorrow at 3pm\", \"remind me to call the bank\", or \"draft a reply to this email\" and Verba creates the Calendar event, Reminder, or email draft for you. It always asks you to confirm before doing anything." }
    },
    {
      "@type": "Question",
      "name": "Do my notes sync across my Macs?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes. Notes are tied to your Verba account, so they follow you when you sign in on another Mac. No iCloud setup needed." }
    },
    {
      "@type": "Question",
      "name": "How does the Translate mode work?",
      "acceptedAnswer": { "@type": "Answer", "text": "Pick a target language once in the Translate mode (English, French, Spanish, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean, Arabic, Hindi, Turkish, Polish). Then just speak in whatever language is natural to you and Verba writes the result in your chosen language, every time, preserving tone, names, numbers and code. You can also make a dedicated mode per language and auto-switch it by app." }
    },
    {
      "@type": "Question",
      "name": "How much does Verba cost?",
      "acceptedAnswer": { "@type": "Answer", "text": "Verba costs $9.99 per month or $84 per year (a saving versus monthly), billed securely through Stripe. New users get 33 free dictations to try it before subscribing, and you use the AI plan or key of your choice so there are no hidden token charges." }
    },
    {
      "@type": "Question",
      "name": "Is Verba accurate, and how good is the transcription?",
      "acceptedAnswer": { "@type": "Answer", "text": "Verba uses state-of-the-art on-device speech models for fast, high-accuracy voice-to-text on Apple Silicon Macs. Its AI cleanup layer then automatically fixes filler words, punctuation, and formatting in whatever app you're typing in, so the final text reads polished rather than raw." }
    },
    {
      "@type": "Question",
      "name": "Does Verba have a free trial or refund?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, Verba gives you 33 free dictations to try the full app with no payment required, so you can confirm it works for you before subscribing at $9.99/mo or $84/yr. Billing is handled through Stripe, so subscriptions can be managed and cancelled at any time." }
    },
    {
      "@type": "Question",
      "name": "Does Verba work offline?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, in on-device mode Verba transcribes your voice locally, so core dictation works without an internet connection and your audio never leaves your Mac. You only need a connection for features that call a connected AI model, such as AI cleanup with a hosted model, live translation, or the JARVIS agent (a fully local model lets you run AI offline too)." }
    },
    {
      "@type": "Question",
      "name": "Is my data and audio private with Verba?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, in on-device mode your audio never leaves your Mac, since transcription runs locally. With JARVIS, the action plan is generated on your Mac using the AI account you connect, never a server-side key, and every action runs only after you confirm. The keys that connect your apps are held by a secure relay, never on your Mac, and a fully local model option lets you run AI entirely offline for maximum privacy." }
    },
    {
      "@type": "Question",
      "name": "What can the JARVIS voice agent actually do?",
      "acceptedAnswer": { "@type": "Answer", "text": "JARVIS is Verba's voice agent that takes action across 1,000+ connected apps, so you can speak commands to send emails, create calendar events, update tasks, and more without leaving your current app. It plans on your Mac using the AI account you connect, shows you the steps, and only acts once you confirm. The keys that connect your apps are held by a secure relay, never on your Mac." }
    }
  ]
}
```

## 4. What to add (optional, nothing fabricated)

- **`BreadcrumbList`** on the deeper pages that already exist (`/features/*`, `/compare`, `/vs/wispr-flow`, `/best-mac-dictation-app`, `/changelog`, `/docs`): a real, verifiable navigation path exists for each, so this is a safe addition, not invented data. Not included here since it needs one block per page template; flag as a follow-up if the operator wants full site coverage.
- **`AggregateOffer`** on `SoftwareApplication` covering the $9.99/mo, $84/yr, and $149 one-time Founder's Edition tiers: all three prices are real and live on `#pricing`. Optional, see 3c.
- **`aggregateRating` / `review`**: explicitly not added. No genuine rating source exists yet (no App Store listing cited on the page, no visible review widget). Adding one now would be exactly the "fabricate reviews or ratings" spam pattern the skill warns against, and risks a Google manual action across the whole domain.
- **`VideoObject`**: only worth adding once a real product demo video with a stable URL and duration is embedded; none found on the current homepage.

## 5. Validation

Once the sanitized copy lands in `layout.tsx` and `page.tsx`, validate before calling it done:
- Google Rich Results Test: `https://search.google.com/test/rich-results?url=https://verba.run`
- Schema Markup Validator: `https://validator.schema.org/#url=https://verba.run`
- Confirm the FAQ rich result still parses after the copy edit (FAQPage is sensitive to exact question/answer pairing between visible text and JSON-LD).

## 6. Summary of required code changes (for whoever implements)

Two files, same fix pattern (remove tech names and banned phrases, keep meaning and JARVIS):
- `website/app/layout.tsx:53-54` (description) and `:68`, `:71` (featureList items 1 and 6)
- `website/app/page.tsx:1375, 1376, 1378, 1379, 1386, 1387, 1389, 1390, 1391` (the `qa` array, which also drives the visible FAQ accordion, so this is a copy fix, not just a schema fix)

This document only produces the recommended content. Landing it in the website repo is an engineering change outside this marketing skill's scope; hand section 3 and section 6 to whoever owns `website/app/`.
