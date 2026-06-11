# Product Marketing Context

*Last updated: 2026-06-11*

> **Single source of truth** for Verba's positioning, ICP, audience and messaging.
> Written by `/omg-product-marketing-context` (R-MARKETING: run first). Every other marketing skill
> (`marketing-strategist`, `content-strategy`, `social-content`, `ad-creative`, `cold-email`, …) reads this file.
> Scope: **Verba only** (verba.run). LiquidPad / other Arc 2042 apps are out of scope.
> Auto-drafted from the codebase + live site (`verba.run`, `Sources/Verba/*`, `website/*`, `README.md`,
> `website/lib/competitors.ts`). No invented features — every claim traces to product or repo.

## Product Overview
**One-liner:** Speak it. Send it clean. — the most complete voice-to-text on the Mac.
**What it does:** Verba is a macOS **menu-bar dictation app**. Press a hotkey (default ⌃⌥Space or the Fn key),
talk for ten seconds or twenty minutes, and Verba transcribes you (on-device or cloud) and uses **Claude** to
restructure your rambling stream-of-consciousness into clean, formatted, on-brand text — then auto-pastes it exactly
where your cursor is. It also reads your screen (Context mode), takes hour-long structured Notes, translates live,
runs offline, and lets you **bring the AI account you already pay for**.
**Product category (the "shelf"):** AI voice dictation / voice-to-text for Mac — how people search: *"Mac dictation app,"
"Wispr Flow alternative," "local dictation Mac," "voice to text for coding."*
**Product type:** Native macOS app (Swift 6, Apple Silicon, macOS 14+), self-serve, subscription SaaS with a free trial.
Distributed as a notarized DMG via GitHub Releases (not the Mac App Store). iOS app + keyboard extension scaffolded, not shipped.
**Business model:** Freemium → **Pro $9.99/mo or $84/yr** (7-day trial on checkout; in-app a **33-dictation full-Pro
trial** before the paywall). **BYOK** — users bring their own OpenAI/Anthropic/OpenRouter keys, *or reuse an existing
Claude Code subscription with no key at all*, or run a fully local Ollama model. Verba makes **no billed API calls of
its own → zero inference COGS and very high gross margin (only payment-processing + light cloud-sync costs).** Built-in **referral loop** ("Free Month" per validated friend)
and a public **leaderboard** (streaks, words, time saved) drive virality. Stripe billing; Clerk auth; Convex sync.

## Target Audience
**Target "company" type:** N/A — this is **B2C / prosumer self-serve**. The buyer is an individual, not a committee.
Sweet spot: individual Mac power-users who type a lot and want to type less, and who care about privacy and cost.
**Decision-makers:** The user *is* the buyer (one-click self-serve checkout). No procurement, no seat negotiation.
**Primary use case:** Turn messy spoken thought into clean, ready-to-send/ship text anywhere on the Mac — especially
**(a) vibe coding** (a 20-minute voice ramble → a tidy spec/prompt for Claude Code or Cursor) and **(b) messaging/writing**
(Slack, Mail, Notion, docs) in your own voice.
**Jobs to be done:**
- "When I have a long, messy thought, help me **ship clean text without typing it all out.**"
- "When I'm coding with an AI agent, help me **dictate a precise prompt** instead of typing paragraphs."
- "When I dictate sensitive things, **keep my audio on my machine.**"
- "When I already pay for Claude, **don't make me pay a second AI markup.**"
**Specific scenarios:** drafting a PR description by voice in the terminal; turning a 40-min meeting ramble into structured
notes; replying to the email on screen ("reply, keep it short and friendly"); speaking French and sending English;
narrating a bug report into a clean ticket; journaling an hour of thoughts into an outline.

## Personas
*(B2C — audience archetypes rather than B2B buying roles.)*
| Persona | Cares about | Challenge (before Verba) | Value we promise |
|---|---|---|---|
| **The Claude Code native** (beachhead) — Mac dev who vibe-codes, already pays Anthropic | Speed, staying in flow, not paying twice for AI, terminal-native tools | Typing long specs/prompts is slow; cloud dictation uploads code context; other tools can't reuse the Claude sub | Speak the spec, get a clean Opus-grade prompt pasted into Cursor/Claude Code — **using the subscription you already have, no key, no markup** |
| **The Privacy-first professional** — lawyer, doctor, founder, journalist | Confidentiality, compliance, control | Cloud dictation tools upload every word; Superwhisper writes audio to disk; can't risk it | **On-device by default — your audio never leaves the Mac and is never uploaded; local history has an off switch + auto-prune; keys in the Keychain** |
| **The Multilingual knowledge worker** — EU/LatAm operator, support, comms | Sounding native in another language, fast | Switching tabs to translate; clunky multilingual dictation | **Translate mode** (speak your language, send theirs) + auto language detection, every time |
| **The Long-form thinker** — writer, PM, researcher, note-taker | Capturing and structuring long thoughts | Hour-long voice memos are unusable mush; meeting bots are overkill | **Notes** — talk up to an hour, get a clean structured document (9 formats, #hashtag filing, synced) |

## Problems & Pain Points
**Core problem:** Your best thinking happens out loud and messy, but everything you *send* has to be typed and clean.
The gap between "what I said" and "what I can ship" is friction — and the tools that close it either **can't actually
clean up your words** (Apple Dictation, MacWhisper) or **upload your private audio and charge you a markup on AI**
(Wispr Flow, Aqua, Willow).
**Why alternatives fall short:**
- Apple Dictation / pure transcribers → raw transcript, no restructuring, no modes.
- Cloud tools (Wispr Flow, Aqua, Willow) → audio always leaves your device; $12–17/mo; locked into their AI markup.
- Local tools (Superwhisper, VoiceInk) → either write audio to disk / store keys in plaintext, or leave the AI polish DIY.
- None let you **reuse the Claude/Claude Code subscription you already pay for.**
**What it costs them:** hours of typing; lost flow while coding; privacy exposure; a second AI bill on top of one they already have.
**Emotional tension:** "I think faster than I type." "I don't want my voice on someone's server." "Why am I paying twice for the same AI?"

## Competitive Landscape
**Direct (same solution, same problem):** Wispr Flow (cloud incumbent, $2B valuation), Superwhisper (local power-tool),
MacWhisper (indie transcriber), Aqua Voice (cloud AI-editing), Willow Voice (cloud style-matching), VoiceInk (open-source local).
→ Each falls short on at least one of Verba's four axes: *on-device-by-default · real AI restructuring · bring-your-own-AI ·
reuse-your-Claude-sub.* Mental model in the market: "cloud→Wispr, local→Superwhisper, transcription→MacWhisper" — **no
default for "local + AI restructuring + BYO-Claude," which is Verba.**
**Secondary (different solution, same problem):** Apple Dictation (free, no AI), Otter.ai (meeting notes, not type-anywhere),
just typing faster, generic LLM chat windows (copy-paste loop).
**Indirect (conflicting approach):** not dictating at all (keyboard + muscle memory); hiring a VA / assistant to clean up notes.

## Differentiation
**Key differentiators (in priority order):**
1. **Bring your own AI — including your Claude Code subscription, with no API key** *(category-of-one; verified `ClaudeCode.swift`)*. Anthropic key, OpenRouter, Claude Code sub, or local Ollama. Never a vendor markup.
2. **Private by default** — on-device Whisper/Parakeet, **your audio never leaves the Mac and is never uploaded** (cloud sync is text-only, never the audio); local history is on by default but has an off switch + auto-prune, and API keys live in the macOS Keychain. (Beats every cloud tool, which uploads every word, and Superwhisper, which stores API keys in plaintext. *Integrity note (verified, `History.swift`): by default Verba keeps audio in local history (`saveHistory` defaults on), so the accurate claim is "audio never leaves your Mac / local history with an off switch," never "nothing written to disk." Keep the site copy aligned, or default history off. See market-research §6.*)
3. **Does what others can't** — **Context mode** (reads your screen with vision, grounds the output) + **agentic actions** (Calendar events, Reminders, email drafts, with confirm) + **hour-long structured Notes** + **live Translate**. Most rivals only transcribe.
4. **Six modes, the right model each** — Flow (no AI), Polish, Intent, Translate, Context, Coding (Opus) — routed to Haiku/Sonnet/Opus so you pay for power only where it matters. Edit any prompt or build your own custom mode.
5. **It learns you** — auto-learns vocabulary from your edits, matches your writing tone per app, formats per app (markdown vs plain).
6. **Cheaper and honest** — $9.99/mo vs $12–17 for the cloud incumbents; the `/vs` pages openly state where rivals still win.
**How we do it differently:** the AI-restructuring layer (Claude + modes) is the *core*, not an add-on, and the entire
pipeline can run on the user's own hardware and their own AI account.
**Why customers choose us:** they get *more* (vision, notes, translate, agentic) for *less* ($9.99), keep their data on
their Mac, and stop paying a second markup on AI they already own.

## Objections
| Objection | Response |
|---|---|
| "I don't want to manage API keys." | You don't have to. If you have Claude Code installed, Verba uses your Claude subscription with **no key**. Or run a local Ollama model. Or just use the free trial — no card. |
| "Mac-only? I use Windows/phone too." | Honest answer: yes, Verba is the best **native macOS** option today. If you need Windows/mobile now, Wispr Flow wins there — we say so on our own compare pages. |
| "Is my data actually private?" | On-device mode transcribes locally; **your audio never leaves your Mac and is never uploaded** (sync is text-only). Local history has an off switch + auto-prune; API keys live in the macOS Keychain. Cloud tools upload every word. |
| "Why pay when Apple Dictation is free?" | Apple Dictation just transcribes. Verba turns rambling speech into clean, structured, formatted, ready-to-send text — modes, intent, per-app tone. |
| "Why not Wispr Flow?" | It uploads your audio, costs $15, and locks you into its AI markup. Verba is on-device, $9.99, and lets you bring the AI you already pay for. |
**Anti-persona (not a good fit):** Windows/Android-primary users; enterprises that need centralized admin/SSO/BAA *today*;
people who never dictate and love their keyboard; users who want zero setup and refuse to bring any AI account or trust an indie app.

## Switching Dynamics
**Push (away from the status quo):** typing long things is slow; voice memos are unusable mush; "my audio is on someone's
server"; "I'm paying twice for the same AI"; Apple Dictation gives raw, unstructured text.
**Pull (toward Verba):** does more (vision, notes, translate, agentic) + private by default + reuse your Claude/Claude Code
sub + $9.99 + learns your voice + one-press flow.
**Habit (keeps them stuck):** keyboard muscle memory; already half-using Apple Dictation or Wispr Flow; "good enough" inertia.
**Anxiety (worries about switching):** BYOK/first-run setup friction; Mac-only; trusting a small indie product with a daily
workflow; "will it actually be more accurate than what I have?"
→ *Counter the anxiety in onboarding:* zero-key Claude Code path, no-card free trial, instant offline Parakeet, and the honest /vs pages.

## Customer Language
**How they describe the problem (voice-of-customer phrasing to mirror):**
- "I think faster than I can type."
- "I just want to ramble and get a clean message out."
- "I don't want my voice/audio going to the cloud."
- "Why am I paying for another AI when I already pay for Claude?"
**How they describe the solution:**
- "Speak it, send it clean."
- "Turn my rambling into a tidy prompt for Claude Code."
- "It pastes right where my cursor is."
- "It runs on my Mac, offline."
**Words to use:** on-device, private, your AI, your Claude sub, no markup, bring your own, clean, modes, offline, Apple-Silicon, vibe coding, one press.
**Words to avoid:** "uploads to our servers," "cloud-only," "we train on your data," "unlimited cloud minutes," enterprise jargon, "transcription" used alone (Verba is *restructuring*, not just transcription).
**Glossary:**
| Term | Meaning |
|---|---|
| Reprompt / restructure | Claude rewriting the raw transcript into clean text per the active mode |
| Mode / profile | A Claude system prompt + which model + which apps it auto-matches (built-ins: Flow, Polish, Intent, Translate, Context, Coding; you can also build your own custom mode) |
| Context mode | Vision mode: screenshots the screen and grounds the output in what's on it |
| BYOK | Bring Your Own Key (Anthropic / OpenRouter) — or your Claude Code sub with no key, or local Ollama |
| On-device | Whisper / Parakeet transcription running locally, audio never leaving the Mac |

## Brand Voice
**Tone:** confident, candid, a little witty. Pro-user, never salesy. Apple-native taste (the site is "Liquid Glass," macOS-feeling).
**Style:** direct and concrete; show, don't boast; *radical honesty as a marketing weapon* — the `/vs` pages literally list where
competitors still beat Verba. Technical enough to earn a developer's trust, human enough for a writer.
**Personality (5 adjectives):** precise · private · witty · pro-user · unpretentious. (The product even ships 17 humor themes for
its loading lines — playful, never corporate.)

## Proof Points
**Metrics / facts (today):**
- Category validation: the incumbent Verba benchmarks against (**Wispr Flow**) is raising at a **$2B valuation** (May 2026).
- **6 modes**, **3 transcription engines** (OpenAI gpt-4o-transcribe, WhisperKit, NVIDIA Parakeet), **99+ languages** (Whisper) / 25 (Parakeet), **15 Translate targets**.
- **$9.99/mo vs $12–17** cloud incumbents; **zero inference COGS** (BYOK).
- On-device open models: OpenAI Whisper (MIT) + NVIDIA Parakeet TDT v3 (CC-BY-4.0), Core ML; **audio never uploaded** (history is local, off-switch + auto-prune).
- Built-in **gamification & retention layer** (`Gamification.swift`): XP, levels, achievements, daily goal, streak milestones, weekly league tiers — beyond the referral "Free Month" + leaderboard.
- Built-in growth mechanics: **referral "Free Month"** loop + public **leaderboard** (streaks, words, time saved).
**Customers / testimonials:** *Early-stage — no public logos or testimonials yet.* Be honest: current proof is **product depth +
category momentum**, not social proof. *First marketing job: manufacture credible early proof (reviews, creator demos, "speak-vs-type" benchmarks).*
**Value themes:**
| Theme | Proof |
|---|---|
| Private by default | On-device Whisper/Parakeet; audio never uploaded; local history off-switch; keys in Keychain |
| Bring your own AI | Claude Code sub (no key) / Anthropic / OpenRouter / local Ollama |
| Does more than transcribe | Context (vision), Notes (hour-long), Translate, agentic actions |
| Cheaper, honestly | $9.99 vs $12–17; transparent /vs comparison pages |

## Goals
**Business goal:** make Verba a **product-revenue business that sustains the founder off product (not consulting)** — concretely,
**€5,000–15,000/mo recurring** (≈ 600–2,000 paying subscribers at current pricing). This is the GTM north star for the package.
**Key conversion action:** **Download → activate (first dictation) → hit the 33-dictation paywall → start the 7-day Pro trial → convert to paid.**
Secondary actions: trigger a referral (Free Month), appear on the leaderboard (retention/virality).
**Current metrics:** pre-scale. Instrumentation live (Vercel Analytics on the site; Convex stats + leaderboard + gamification in-app). No public
MRR/user numbers yet. **Two known fixes before scaling spend** (both grounded, both ~1-day): (1) the site now standardises on
**33 dictations** (hero, bento, /compare, /vs — matching `Entitlement.swift` `freeTrialDictations = 33`), but the web "Try-It" demo
endpoint (`website/app/api/try/route.ts`) still nudges "free up to 10,000 words/month" — align that copy. (2) **privacy-claim accuracy:** audio is kept in local history by default (`History.swift`; `saveHistory` defaults on) — never *uploaded* (sync is text-only) but stored locally, so the claim must stay "audio never leaves your Mac / off switch," never "nothing written to disk" (or default history off).
