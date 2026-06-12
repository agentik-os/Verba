# Verba

A native macOS **menu-bar dictation app** — speak, and Verba transcribes you and
uses an LLM you control to turn your rambling stream-of-consciousness into clean,
well-ordered text. Then **JARVIS**, Verba's voice agent, can act on it across
**1,000+ connected apps**. Think Wispr Flow, but local-first, BYO-AI, and with a
real agent behind it.

Website: **[verba.run](https://verba.run)** · Changelog: **[verba.run/changelog](https://verba.run/changelog)**

---

## What it does

1. **Dictate anywhere** — tap **Fn**, talk, tap again. Clean text lands right at
   your cursor in any app. No window, no copy-paste.
2. **AI rewriting** — your raw transcript is restructured by the model/backend
   you choose, using the active **mode** (see below).
3. **JARVIS — Action mode** (**Fn + X**) — speak a command and Verba's voice
   agent understands it however you phrase it, plans the steps, asks a quick
   question when something's ambiguous or missing, and acts — on your Mac and on
   your connected apps — always after your confirmation.

## Modes

Every mode is an editable system prompt with app-bundle auto-matching:

- **Flow** — raw transcript, no rewriting.
- **Polish** — clean grammar, punctuation, structure.
- **Intent** — select text + say how to transform it.
- **Translate** — to a target language.
- **Context** — reads your screen (vision) and writes from it (reply to the
  email in front of you, summarize a document…).
- **Coding** — dev-focused prompt shaping for coding agents.
- **Custom** — build your own; one tap to generate a friendly description.

## JARVIS & connected apps

- **1,000+ apps** connectable from **Settings ▸ Connected apps** — search the
  catalog, filter by category, connect in one tap.
- **Adaptive connect** — OAuth apps open a secure browser sign-in; the many
  API-key apps open a small in-app form asking for exactly the keys they need.
- **Tap any app** to see all its actions, each with example phrases you can say
  to JARVIS.
- **Multi-step + clarify + fill-in** — JARVIS reads context (read-only), asks
  when unsure, shows editable fields for missing details, and proposes a smart
  **post-action follow-up** ("Invite people to the event?").
- **Local, model-free action retrieval** (BM25) surfaces the right action fast —
  no embeddings, no extra tokens.
- Your connection keys stay on Verba's servers, never on your Mac.

## Transcription

Your choice of:

- **Local, on-device** (free, offline, no size limit — handles 20-minute
  monologues) via **WhisperKit** or **NVIDIA Parakeet** (FluidAudio), or
- **Cloud** (OpenAI) for maximum accuracy.

## AI backend (BYOK)

Pick the engine that powers rewriting and JARVIS, per mode:

- **Your Claude subscription** (via the Claude Code CLI) — no API key,
- **Verba hosted** (signed-in account),
- **Anthropic API key**, **OpenRouter** (any model), or a **local LLM** (Ollama).

Keys live in the macOS Keychain. Context mode and JARVIS use the same backend
you selected — never a stray API key.

## Other

- **15 languages** — the whole UI translates; pick your language.
- **Voice notes & to-dos**, a **task glance** (⌥Fn), **gamification**
  (100 levels), and a synced **History**.
- **Shortcuts** are all rebindable in **Settings ▸ Shortcuts**.

## Build

```sh
swift build -c release      # or ./bundle.sh to assemble Verba.app
# release.sh signs + notarizes + publishes the Sparkle appcast
```

Requires macOS 14+, Swift 6 (Xcode 26). Local transcription downloads its model
on first use, then runs fully offline.

## Repo layout

- `Sources/Verba/` — the macOS app (SwiftUI / SwiftPM).
- `Localizations/` — `<lang>.lproj` strings for the 15 languages.
- `website/` — the Next.js site (verba.run) + the Composio secure-relay API
  routes (`app/api/composio/*`) and Convex backend (`convex/`).
- `bundle.sh` / `sign-and-notarize.sh` / `release.sh` — build + release.

## Permissions

- **Microphone** — to record you.
- **Accessibility** — to auto-paste (⌘V) into other apps; without it, Verba
  copies to the clipboard.

---

Proprietary. © 2026 Agentik / Dafnck Studio.
