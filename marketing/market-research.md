# Verba — Market Research

> Deliverable 1 of the Verba GTM package · Skill: `/omg-market-research` (R-MARKETING, upstream-most)
> Scope: **Verba only** (verba.run). LiquidPad and other Arc 2042 apps are explicitly out of scope.
> Date: 2026-06-11 · **Last updated: 2026-06-12** (post-JARVIS: the voice → action wave, commits 5ae8804…ebcdcff) · Author: Oracle (OmegaOS)

## Method & honest caveats

- **Ground truth first.** Every product claim in this package is traced to `verba.run` (live) and the repo
  (`Sources/Verba/*.swift`, `website/`, `README.md`, `website/lib/competitors.ts`). No invented features.
- **Research path.** The `/omg-market-research` skill is built on the gooseworks B2B data API
  (company / decision-maker search). Those credentials are **absent** on this host, and that API is the wrong
  instrument anyway — Verba is a **self-serve B2C / prosumer Mac app**, not an enterprise account-based sale.
  So the market sizing here uses the skill's other allowed tools (live web search/fetch, June 2026) plus the
  competitor dataset already maintained in the repo. Sources are cited inline; this is directional market
  intelligence, not a paid analyst report.
- **Currency.** Verba prices in **USD** ($9.99/mo, $84/yr). The revenue target is in **EUR**. Conversions assume
  ~1.08 USD/EUR ($9.99 ≈ €9.2/mo; $84 ≈ €78/yr ≈ €6.5/mo effective).

---

## 1. The category & why now

Verba sits in **AI voice dictation for the desktop** — "speak, and clean text lands where your cursor is" — and, since
June 2026, has crossed into a second, nearly empty category: the **desktop voice agent** — "speak, and it *gets done*."
The JARVIS Action agent (commit 5ae8804) plans a dictated intent on-device, asks when ambiguous, and executes after the
user confirms — natively on the Mac and across **1,000+ connected apps** (Gmail, Slack, Notion, Linear, GitHub…) via a
Composio-backed relay (`Sources/Verba/ActionExecutor.swift`, `website/lib/composio-rw.ts`). No dictation competitor does
this (§2–3). Several things make this the right category at the right time:

**1. The money is pouring in.** Wispr (maker of **Wispr Flow**, the incumbent Verba benchmarks against) is in
talks to raise **~$260M at a ~$2B valuation** (May 2026, Menlo Ventures lead) — roughly **3× its $700M valuation
from six months earlier**, on $81M raised to date. Wispr Flow reports 270 Fortune 500 customers (Nvidia, Amazon)
and ships on Mac/Windows/iOS/Android. A $2B incumbent validates the category and creates a large, well-marketed
pool of users to peel off. [Bloomberg, The Tech Portal, Tracxn]

**2. The market is large and compounding.**
| Segment (2026) | Size 2026 | Forecast | CAGR | Source |
|---|---|---|---|---|
| AI speech-to-text **tools** | **$3.87B** | $16.42B (2035) | 17.4% | Precedence Research |
| Speech & voice recognition (broad) | $23.70B | $104B (2034) | 20.3% | Fortune Business Insights |
| Voice AI (broadest) | ~$22.5B | — | 34–35% | ringly.io / industry |
| AI transcription | $4.5B (2024) | $19.2B (2034) | ~16% | Sonix / industry |

The tightest relevant TAM — **AI speech-to-text *tools*** at **$3.87B in 2026, growing 17%/yr** — is the number
to anchor on. Verba needs a *rounding error* of it.

**3. A second tailwind unique to Verba: the Claude Code generation.** Verba's signature feature is *"use your
existing Claude Code / Claude subscription — no API key, no markup"* (verified: `Sources/Verba/ClaudeCode.swift`).
That ties Verba to the fastest-moving developer tool on the market:
- Claude Code is rated **"most loved" by 46%** of 15,000 developers (Pragmatic Engineer survey, Feb 2026), and
  **71% of developers who use AI agents use Claude Code as their primary tool**.
- **73% of engineering teams** now use AI coding tools daily (up from 41% in 2025).
- Claude Code is past a **$2.5B run rate**; it overtook Copilot and Cursor within 8 months of launch.
[gradually.ai, serpsculpt, Anthropic Economic Index]

Every one of those developers is a person who already pays Anthropic, already "vibe codes," and would rather speak
a 3-paragraph spec than type it. **Verba is the voice front-end for that exact population** — and no competitor
lets you reuse the Claude subscription you already bought. The JARVIS architecture deepens this tie: the user's own
Claude Code (or local model) **is the action planner** — Verba never burns a server-side key (commit d86685b).

**4. The "Jarvis" demand pocket is real and unserved on the Mac.** People have wanted a Jarvis-style assistant for a
decade; what they got was Siri. The agent wave (Claude Code, MCP-style tool ecosystems, Composio's 1,000+-app catalog)
finally makes "say it → it's done, with confirmation" technically credible — and the dictation incumbents haven't crossed
over: they all stop at text (the closest, TalkTastic, does Mac-local app-aware commands only — `website/lib/competitors.ts`).
Verba enters the "voice agent for the desktop" slot **before** a category leader exists.

---

## 2. Competitive landscape

The repo already maintains a verified competitor dataset (`website/lib/competitors.ts`, "facts verified mid-2026")
which powers the live `/vs/[slug]` SEO pages and — since commit ebcdcff — a rebuilt `/compare` page: an honest
**24-feature × 10-brand matrix** (`website/lib/compare-matrix.ts`, generated from a sourced 10-product audit, Verba
column highlighted, per-vendor sourcing notes). Synthesized and cross-checked against live web (June 2026), the field
splits into four tiers:

**Tier 1 — The cloud incumbent (the one to convert from)**
- **Wispr Flow** — $15/mo ($12 annual), cloud-only, cross-platform (Mac/Win/iOS/Android), very polished, SOC2/HIPAA
  for teams. **$2B valuation.** *Weakness Verba attacks:* audio always leaves the device; most expensive; no offline;
  no BYO-AI (you pay their markup forever).

**Tier 2 — Local-first Mac power-tools (the closest substitutes)**
- **Superwhisper** — $8.49/mo, $84.99/yr, **$249.99 lifetime**; local Whisper+Parakeet; 4.9/5 Product Hunt.
  *Weakness:* saves audio to disk by default; API keys in plaintext.
- **MacWhisper** — ~$69 lifetime (App Store from $6.99/mo); indie (GoodSnooze); **~1,900 Product Hunt reviews @ 4.8/5** — proof the indie
  Mac-dictation buyer exists in volume. *Weakness:* file-first transcription, not type-anywhere; AI cleanup is secondary.
- **VoiceInk** — open-source (GPLv3), $25–49 one-time; local Whisper+Parakeet; BYOK AI. *Weakness:* AI polish is DIY.

**Tier 3 — Cloud AI-editing challengers**
- **Aqua Voice** — ~$8/mo, cloud-only, proprietary "Avalon" model, strong natural-language editing. *Weakness:* cloud-only,
  1,000-word lifetime free cap.
- **Willow Voice** — $12–15/mo, cloud-default (offline is Pro-only), style-matching, SOC2/HIPAA.
- **TalkTastic** — cloud, app-aware AI actions (free during beta). *The closest thing to "actions" in the field — but
  Mac-local app commands only; it cannot execute across external apps (no Gmail/Slack/Linear/GitHub writes), has no
  confirm-gated agent loop, and no BYO-AI.*

**Tier 4 — Adjacent / not direct**
- **Apple Dictation** — free, built-in, on-device, but **zero AI cleanup** (the "good enough" anchor Verba must beat on quality).
- **Otter.ai** — $16.99/mo, meeting transcription, not type-anywhere dictation.

**The market's own mental model** (from 2026 comparison blogs): *"cloud → Wispr Flow; local → Superwhisper;
transcription → MacWhisper."* **There is no default answer for "local + real AI restructuring + bring-your-own-Claude."
That empty slot is Verba's.**

---

## 3. The white space Verba owns

No competitor occupies all four of Verba's axes at once:

| Axis | Wispr Flow | Superwhisper | MacWhisper | Aqua | **Verba** |
|---|---|---|---|---|---|
| On-device by default (audio never leaves Mac) | ✗ | ✓ (writes to disk) | ✓ | ✗ | **✓ (never uploaded; off-switch)** |
| First-class AI restructuring (modes, per-mode model) | ~ | ~ (prompt box) | ✗ | ✓ (cloud) | **✓ (Claude, 6 modes)** |
| **Bring your own AI account / no markup** | ✗ | partial | ✗ | ✗ | **✓ (unique)** |
| **Reuse your Claude Code subscription, no key** | ✗ | ✗ | ✗ | ✗ | **✓ (unique)** |
| **Voice → action: agent executes on 1,000+ connected apps (confirm-gated)** | ✗ | ✗ | ✗ | ✗ | **✓ (unique — JARVIS)** |
| **Action planning on-device (your AI plans, never a vendor key)** | ✗ | ✗ | ✗ | ✗ | **✓ (unique)** |
| Reads your screen (vision / Context mode) | ✗ | ✗ | ✗ | ✗ | **✓ (unique)** |
| Hour-long structured Notes | ✗ | ✗ | ~ (files) | ✗ | **✓** |
| Price | $15 | $8.49 | ~$69 once | $8 | **$9.99** |

**Three genuinely unique wedges** (no competitor has them): *bring-your-own-Claude (incl. the Claude Code subscription
with no API key)*, ***voice → action* (JARVIS: dictated intent → on-device plan → confirm → execute on 1,000+ connected
apps — schema-validated and auto-repaired per action, writes never auto-run; commits 5ae8804, 0bec783, 83da81b)*, and
*Context mode (voice + screen vision)*. Everything else (price, on-device, modes) is "best-in-class," but those three are
*category-of-one* — and the second one changes the product's shelf entirely: from "dictation that types" to "a voice agent
that does."

---

## 4. ICP & demand signals

**Primary beachhead — the "Claude Code native" Mac developer.**
Already pays Anthropic; lives in Cursor/terminal/Claude Code; vibe-codes; would rather speak a spec than type it;
privacy-aware; hates paying a vendor markup on top of the AI they already buy. *Verba's Coding mode (Opus 4.8) +
"use your Claude Code sub, no key" is built for this person.* JARVIS sharpens the pitch further: their Claude Code
install **is** the action planner — "the agent you already pay for now runs your Mac by voice." This segment is large,
concentrated (Reddit r/macapps, Hacker News, X dev community, Claude/Cursor Discords), fast-growing (73% of eng teams
on AI tools daily), and reachable without paid ads.

**New segment opened by JARVIS — the "voice-first operator."** Founders, PMs, and exec-without-an-EA types who live in
Gmail/Slack/Linear/Calendar and want spoken intents *executed*, not just typed: "create the issue," "send the invite,"
"draft the reply." Until now their options were Siri (can't touch real work tools) or nothing. Demand signal: the
decade-old "I want a real Jarvis" trope, the agent wave, and the fact that the closest dictation competitor (TalkTastic)
stops at Mac-local commands. Verba's confirm-gated agent + 1,000+ connected apps is the first credible product for them.

**Secondary segments (expansion, in order):**
1. **Privacy-conscious Mac professionals** — lawyers, doctors, journalists, founders who can't send audio to a vendor cloud.
   Verba's "audio never leaves your Mac, never uploaded" (cloud sync is text-only; local history has an off switch) beats every cloud tool; vs Superwhisper the edge is Keychain-stored keys (not plaintext) + an off switch, not disk storage (both keep local history by default).
2. **Multilingual knowledge workers** — Translate mode (speak FR, send EN) + auto language detection. Big in EU/LatAm.
   Now structurally backed: the entire UI ships localized — **998 strings translated into 14 languages** (commit b3dd02c)
   — so the international funnel isn't en-only past the landing page.
3. **Long-form thinkers / note-takers** — the Notes tab (hour-long voice → structured doc, #hashtag filing) is a
   standalone wedge vs Otter, without the meeting-bot baggage.

**Demand is proven, not hypothetical:** a $2B incumbent, an indie competitor with ~1,900 paying-tier reviews, an
active r/macapps comparison culture, and a structural shift to dictation ("4× faster than the keyboard" is the
category's own claim). The question for Verba is **distribution and conversion, not whether demand exists.**

---

## 5. Pricing reality in the category

| App | Monthly | Annual / one-time | Free tier |
|---|---|---|---|
| **Verba** | **$9.99** | **$84/yr** | 33-dictation full-Pro trial (see note) |
| Wispr Flow | $15 | $12/mo annual | 2,000 words/week |
| Willow | $12–15 | — | limited |
| Otter | $16.99 | $8.33/mo annual | 300 min/mo |
| Aqua | ~$8 | — | 1,000-word lifetime |
| Superwhisper | $8.49 | $84.99/yr · **$249.99 lifetime** | yes |
| MacWhisper | — | **~$69 lifetime / $6.99 mo** | small models free |
| VoiceInk | — | $25–49 once / free from source | open source |
| Apple Dictation | free | — | free |

**Read:** Verba is priced **below the cloud incumbents** ($9.99 vs $12–17) and **at parity with the local power-tools**,
while doing more than either. Two pricing gaps to discuss with the marketing co-founder (§ GTM strategy): (a) the
category has a strong **lifetime-deal** behaviour (Superwhisper $249.99, MacWhisper ~$69, VoiceInk one-time) that
Verba currently doesn't answer — a lifetime/founder tier could be a launch lever; (b) BYOK means Verba's gross margin
per user is very high (no inference COGS), so there's unusual room to discount, bundle, or run aggressive trials.

---

## 6. Risks & headwinds (be honest)

- **macOS-only.** Verba forfeits Windows/Android/iOS demand that Wispr Flow/Willow capture. The iOS app is scaffolded
  (`ios/`) but not shipped. Narrows the SAM — but sharpens positioning ("the best *native Mac* dictation app").
- **A $2B incumbent with a marketing budget.** Verba cannot out-spend Wispr Flow; it must out-*position* (privacy +
  BYO-Claude + does-more) and win the niches Wispr structurally can't (offline, no-markup, local).
- **BYOK onboarding friction.** "Bring your own AI key" is a power-user concept; the free tier and the "use your Claude
  Code sub with no key" path must make first-run effortless or casual users bounce.
- **Agent-trust headwind (new with JARVIS).** "A voice agent connected to my Gmail" triggers a legitimate fear reflex.
  Verba's architecture is the answer — reads-only auto-run, **every write confirm-gated** (fail-safe classifier,
  `composio-rw.ts`), planning on-device with the user's own AI (d86685b), per-app disconnect — but the *marketing* must
  lead with the control story or the feature scares more than it sells. Treat "it asks before it acts" as a headline, not a footnote.
- **Messaging-integrity gaps (fix before scaling spend) — two, both ~1-day; re-verified 2026-06-12, both still open.**
  **(a) Free-tier copy:** the site now
  standardises on *"33 dictations"* (hero, bento, `/compare`, `/vs` — matching the code: `Entitlement.swift` →
  `freeTrialDictations = 33`), but the web **"Try-It" demo** endpoint (`website/app/api/try/route.ts` lines 56/67) still nudges
  *"free up to 10,000 words/month."* Align that one file. **(b) Privacy-claim accuracy:** any *"never writes your audio to disk"* phrasing overstates it — local history (including audio) is **on by default** (`History.swift` copies the
  audio file locally; `Settings.swift` `saveHistory ?? true`). Audio is never *uploaded* (sync is text-only), but it **is**
  stored locally — soften the claim to "audio never leaves your Mac / local history with an off switch," or ship
  history-off-by-default. A competitor could call this out; a marketing co-founder's first-week fix.
- **Distribution outside the App Store.** Verba ships as a notarized DMG via GitHub Releases — full control and margin,
  but no App Store discovery surface. SEO + community + creators must carry top-of-funnel.

---

## 7. The path to €5–15k/mo — is the market big enough? (Yes, trivially.)

This is a **SOM-execution** question, not a TAM question. At Verba's pricing, the target maps to a tiny, concrete
subscriber count:

| Monthly target | All-monthly ($9.99≈€9.2) | All-annual ($84≈€6.5/mo) | Blended (~60% annual) |
|---|---|---|---|
| **€5,000 / mo** | ~545 subs | ~770 subs | **~660 paying subs** |
| **€10,000 / mo** | ~1,090 subs | ~1,540 subs | **~1,320 paying subs** |
| **€15,000 / mo** | ~1,630 subs | ~2,300 subs | **~1,975 paying subs** |

**~600 to ~2,000 paying subscribers.** For scale: MacWhisper alone shows ~1,900 paying-tier reviewers (a fraction of
its actual buyers); Wispr Flow is a $2B company; the AI-STT-tools TAM is $3.87B. Verba reaching 600–2,000 subs is
**well under 0.1% of the category** — it is a distribution-and-conversion problem, fully addressable by the GTM and
content engines that follow in this package. Because Verba carries **no inference COGS** (BYOK), this MRR is
near-pure contribution margin — far healthier unit economics than the cloud incumbents at the same price.

---

## Sources
- Wispr $2B raise — [Bloomberg](https://www.bloomberg.com/news/articles/2026-05-12/ai-dictation-startup-wispr-in-funding-talks-at-2-billion-value), [The Tech Portal](https://thetechportal.com/2026/05/12/ai-dictation-startup-wispr-could-secure-260mn-funding-at-2bn-valuation/), [Tracxn](https://tracxn.com/d/companies/wispr-flow/)
- Market size — [Precedence Research (AI STT tools)](https://www.precedenceresearch.com/ai-speech-to-text-tool-market), [Fortune Business Insights (speech & voice)](https://www.fortunebusinessinsights.com/industry-reports/speech-and-voice-recognition-market-101382), [ringly.io voice-AI stats](https://www.ringly.io/blog/voice-ai-statistics-2026), [Sonix transcription stats](https://sonix.ai/resources/automated-transcription-statistics/)
- Claude Code adoption — [gradually.ai](https://www.gradually.ai/en/claude-code-statistics/), [serpsculpt](https://serpsculpt.com/claude-code-usage-statistics/), [Anthropic Economic Index (Mar 2026)](https://www.anthropic.com/research/economic-index-march-2026-report)
- Competitor traction — [MacWhisper vs Superwhisper (jamesm.blog)](https://jamesm.blog/ai/mac-dictation-tools-comparison/), [spokenly](https://spokenly.app/blog/wispr-flow-vs-superwhisper-vs-macwhisper), [Medium / Ryan Shrott](https://medium.com/@ryanshrott/best-mac-dictation-apps-in-2026-dictaflow-wispr-flow-superwhisper-and-apple-dictation-compared-11911c671817)
- Product ground truth — repo: `Sources/Verba/ClaudeCode.swift`, `Entitlement.swift`, `website/lib/competitors.ts`, `website/app/page.tsx`, `README.md`; live `verba.run`
- JARVIS / voice → action ground truth — `Sources/Verba/ActionExecutor.swift`, `ActionAgentClient.swift`, `website/lib/composio-rw.ts`, `website/lib/compare-matrix.ts`; commits 5ae8804 (JARVIS, 1,000+ apps), 7452012 (secure relay + Connected-apps UI), d86685b + b428a1f (on-device sandboxed planner), 0bec783 + 83da81b (schema validation + auto-repair, 989 toolkits / 36,998 tools), e104b79 (stacked dictations), b3dd02c (i18n 14 languages), ebcdcff (/compare rebuild + SEO/GEO)
