# Verba — Paid Ad Creative Library (Copy + Visual Briefs)

> **Deliverable 05** of the July 2026 content package · Ready-to-deploy paid-creative library.
> **Copy** is reproduced **verbatim** from `marketing/ad-creative.md` (the GTM SSOT). **Visual briefs** are the added value — art direction a designer or `higgsfield-generate` can execute.
> Reads: `marketing/ad-creative.md` · `.agents/product-marketing.md` (positioning) · `marketing/gtm-strategy.md` (§4 channels, §6 pricing). Visual tokens grounded in `website/app/opengraph-image.tsx` + `website/app/globals.css` + `website/components/Brand.tsx`.
> Scope: **Verba only** (verba.run). Date: **2026-06-28**. Author: Oracle (OmegaOS).
> Narrative spine (repeat everywhere): **"The Mac dictation app that became a voice agent."**

---

## 0. How to use this library — read before you spend a dollar (L2)

This is a **library, not a spend order.** Per `gtm-strategy.md` §4, **paid is the last engine, not the first**: *"Paid (only after organic proves conversion)."* Verba grows earned + owned first (comparison/use-case SEO, dev communities, creator demos). These ad sets are the **ready-to-run paid layer for the moment the organic funnel proves it converts** — not a license to skip Phase 0/1.

**Two preconditions before anything here goes live:**
1. **Activation works** — first dictation < 60s (zero-key Claude Code path + offline Parakeet), and the 33-dictation forced-value trial is intact. Paid clicks onto a leaky funnel just burn money faster.
2. **One true free-tier story** is live everywhere (33 dictations) — the landing page and the ad promise must say the same thing.

**Why paid is still viable early:** BYOK means **zero inference COGS**, so even a modest LTV at $9.99/mo supports paid acquisition once download→paid is proven (model: 7–10% on a forced-value trial). **Start paid as retargeting** (warm `/compare` + `/vs` visitors) before cold search — cheapest CPA first.

### Deploy sequence (maps to the July runway — do not reorder)
1. **Retargeting first (§4)** — the highest-ROI surface, warm intent. This is the **first paid surface to switch on**, realistically around **launch week (27 Jul–2 Aug)** and **T+1–2 (3–16 Aug)** once the spike fills the `/compare` + `/vs` audiences. Static creative first (cheap).
2. **Angle test (§6)** — run all four angles to the same warm audience at equal budget; let CPA name a winner.
3. **Layer the JARVIS demo video** (Angle 3) onto the highest-intent segment.
4. **Cold search RSAs (§2)** — graduate here **only after** a retargeting angle clears a CPA the $9.99 × retention LTV can support.

### Visual generation is a follow-up (R-VISUAL-ID)
Every brief below is **production-ready art direction**. The actual render goes through the Higgsfield pair — `higgsfield-soul-id` (train the Verba identity anchor **once**) → `higgsfield-generate --soul-id …` (produce each asset). **That step needs operator credentials** (paid plan + `higgsfield auth login`) and is **not runtime-verifiable here** — this document delivers the briefs; live generation is the operator's follow-up. Prompt scaffolds are in §9.

### Integrity rules baked into every line below — copy AND visuals (do not break)
- **No invented features.** Every claim traces to `product-marketing.md`.
- **Never claim Windows or iOS.** Verba is **native macOS only**; iOS is scaffolded, not shipped. When intent is cross-platform, the honest answer is "best on Mac."
- **Public vocabulary only:** *JARVIS*, *connected apps*, *voice agent*. Never an internal infra name in any ad.
- **Privacy claim stays exact:** "your audio never leaves your Mac / never uploaded" — never "nothing written to disk" (audio is kept in local history by default, with an off switch).
- **Never imply autonomous action.** JARVIS is **confirm-gated**: "it shows you the action, you confirm, it acts." **No creative may ever depict an unconfirmed write executing** — every action visual shows *shows the action → you confirm → it runs.*

### Guardrail — Founder's Edition / Lifetime is NOT an ad angle yet (L2)
The launch strategy *plans* a Founder's Edition / Lifetime ($149) as a launch lever, but **that SKU does not exist in Stripe** — only monthly ($9.99) and annual ($84/yr) are live. **No ad set in this library references Lifetime**, and none should until the SKU ships. **[PREREQUISITE: Stripe Lifetime SKU to create + test before 28 Jul]** — it is in the T-4 checklist. If a launch-week "Founder's Edition" creative is wanted, it is **net-new, gated on that prerequisite**, not part of this deployable set.

---

## 1. Brand visual system — the locked spec every brief inherits

One source of truth so every asset feels native to verba.run. Tokens are pulled from the live site, not invented.

### Palette (exact)
| Token | Hex | Use |
|---|---|---|
| Ground (near-black) | `#050507` | The canvas. Every creative sits on this. |
| Chapter band | `#0a0a0d` | Faint secondary ground for layered panels. |
| Panel / card | `#0c0c10` | Mic-mark fill, UI cards, mockup chrome. |
| Foreground | `#f4f4f6` | Primary text, mic glyph, primary-button fill. |
| Foreground dim | `rgba(244,244,246,0.45)` | **Two-tone headline line 2.** Also 0.62 / 0.78 for body. |
| **Rec-dot RED** | `#ff5a4d` | **The single accent. ONE per composition.** Anchor it to a live/REC/price beat. |
| Warm-cream accent | `#f4ede0` | Hairline / underline only, very sparingly. Never a fill. |
| Status tick (green) | `#6ee7a8` | **Compare checkmarks only (Angle 4).** Not a general accent. |
| Hairline | `rgba(255,255,255,0.10)` | Dividers, footer rule. |

**Top glow (signature):** `radial-gradient(900px 380px at 50% -12%, rgba(255,255,255,0.07), transparent 65%)` — a quiet light from above the frame. Present on every full-bleed creative.

### Typography
- **Headline:** neutral grotesque (Inter / SF Pro / Söhne-class), weight **700**, **very tight tracking (-0.035em)**, line-height ~1.02. **Two-tone rule:** line 1 solid `#f4f4f6`, line 2 at **45% opacity** — the signature move from the site hero and OG card.
- **Mono meta:** `SF Mono / ui-monospace`, **UPPERCASE**, wide tracking (**0.14–0.18em**), dimmed `~55%`. For captions, footers, status labels (e.g. `ON-DEVICE · NEVER UPLOADED`).
- **Eyebrow:** uppercase, tracking 0.18em, faint — a single short label, used sparingly.

### Marks
- **Mic mark:** near-black `#0c0c10` rounded square, corner radius ≈ **0.25× side**, **1px border `rgba(255,255,255,0.18)`**, centered white mic glyph. The glyph is the two-path SVG (capsule head + stand arc) from `Brand.tsx` — reuse it exactly, never redraw.
- **Wordmark:** "Verba", weight 600, tracking -0.02em.
- **rec-dot:** 12px circle `#ff5a4d`, optional 2s pulse. The only saturated color in the system.

### Formats (every angle ships all three)
| Ratio | Pixels | Surface |
|---|---|---|
| **1:1** | 1080×1080 | Reddit / X / IG feed (primary test unit) |
| **1.91:1** | 1200×630 | Link card / OG / landscape feed (matches the site OG exactly) |
| **9:16** | 1080×1920 | Story / Reels / vertical video (the JARVIS clip travels furthest here) |
| *(optional)* 4:5 | 1080×1350 | Highest-real-estate portrait feed crop |

**Mood (one line):** quiet, architectural, museum-caption restraint — generous negative space, Apple/Linear-tier. **One idea per frame.** Never loud, never stocky, never salesy.

---

## 2. The four angles — copy (verbatim) + visual brief

Each angle pairs the verbatim copy bank with a self-contained art-direction brief. Character counts in `[brackets]` are computed against the literal string — keep them for platform compliance.

---

### ANGLE 1 — Privacy: "your voice never leaves your Mac"

**Core promise:** on-device by default; audio never uploaded; local history has an off switch; keys in the Keychain — *even the action planner runs on your Mac.* **Target:** privacy-first professionals + the privacy-leaning developer. **Landing page:** `/privacy` (the proof page) or `/vs/wispr-flow` (cloud-upload contrast).

**Headlines (≥3):**
- "Your voice never leaves your Mac" [32]
- "Dictation that never uploads your audio" [39]
- "Private by default. On-device by design." [40]
- "On-device dictation for your Mac" [32]
- "No cloud. No upload. No audio on a server." [42]

**Primary text (≥2):**
- A: "Cloud dictation tools upload every word you say. Verba runs on your Mac — your audio never leaves the device and is never uploaded. On-device Whisper/Parakeet, local history with an off switch, keys in the macOS Keychain. Even the JARVIS action planner runs on your own AI, never our server." [291]
- B: "Lawyer, doctor, founder, journalist? Your words are confidential — so your dictation should be too. Verba transcribes on-device; your audio never leaves your Mac and is never uploaded. Speak freely; nothing goes to the cloud." [225]

**A/B pair (change = the threat framing):**
- A1 (loss-framed): "Stop uploading your voice to someone else's server." [51]
- A2 (gain-framed): "Keep every word you dictate on your own Mac." [44]

#### 🎨 Visual brief — Angle 1 "Containment"

- **Concept:** *containment.* The audio waveform stays **inside** the Mac and never crosses the device boundary. The whole frame says "nothing leaves."
- **Composition (1:1):** centered MacBook silhouette on `#050507` under the top glow. Inside the screen, a soft `#f4f4f6` waveform. A **dotted boundary** traces the device, labeled in mono `ON-DEVICE`. Outside the boundary = empty void (the point: nothing is out there). The **rec-dot** sits beside the `ON-DEVICE` label — its single job. Two-tone headline upper-left: **"Your voice"** (solid) / **"never leaves your Mac."** (45%).
- **Alt concept (more minimal):** a single upload-cloud icon with a hairline **strike-through**, mono caption `NO UPLOAD`, vast negative space. Restraint > illustration.
- **Palette / typo:** locked system. Red rec-dot is the **only** color, anchored to the on-device caption. Headline two-tone; footer in mono.
- **Overlay text:** headline "Your voice never leaves your Mac" [32]. Mono footer: `ON-DEVICE · NEVER UPLOADED · KEYS IN KEYCHAIN`.
- **1.91:1 (OG/landscape):** mirror `opengraph-image.tsx` — Mac on the right, headline stack left, hairline + rec-dot + mono footer. Feels native to the site link-card.
- **9:16 (story):** headline top → contained-waveform Mac centered → CTA pill bottom. rec-dot top-right as a quiet "private/live" status.
- **Scene / mockup honesty:** real macOS menu bar with the Verba mic glyph; a dictation HUD pill with a waveform; the network indicator shown as `—` (no connection needed). If you show history, show the **off switch** — never imply "nothing on disk."
- **CTA:** "Try free — your audio stays home." (button "Try free, no card.") → `/privacy`.

---

### ANGLE 2 — BYO-Claude: stop paying twice for the same AI

**Core promise:** bring your own AI — reuse the Claude Code subscription you already pay for, **no API key**, no markup; or Anthropic key, OpenRouter, or fully local Ollama. **Target:** the Claude Code-native developer (beachhead). **Landing page:** `/features` (BYOK + modes) or `/best-mac-dictation-app`; planned ideal = a "/for/claude-code" use-case page (not built yet).

**Headlines (≥3):**
- "Already pay for Claude? You're ready." [37]
- "Reuse your Claude Code sub. No API key." [39]
- "Stop paying twice for the same AI" [33]
- "Bring your own AI. No vendor markup." [36]
- "Your Claude subscription, now your voice." [41]

**Primary text (≥2):**
- A: "You already pay Anthropic. Why pay a second AI markup to a dictation app? Verba reuses your Claude Code subscription with no API key — speak your rambling thought, get a clean, Opus-grade result pasted where your cursor is. Or bring an Anthropic/OpenRouter key, or run fully local with Ollama. Zero markup, ever." [312]
- B: "Most dictation apps lock you into their AI and bill you for it. Verba doesn't. Reuse the Claude Code sub you already have — no key, no markup — or go fully local. The AI you pay for is the AI that cleans up your voice." [218]

**A/B pair (change = headline emphasis: cost vs setup-ease):**
- A1 (cost): "You're paying twice for AI. Here's the fix." [43]
- A2 (ease): "Have Claude Code? No key, no setup, just talk." [46]

#### 🎨 Visual brief — Angle 2 "No key"

- **Concept:** *reuse, no key.* The Claude sub you already pay for plugs **straight** into Verba — the key step is crossed out. Dev-native aesthetic (terminal / editor).
- **Composition (1:1):** stacked flow. Top: mono line `CLAUDE CODE SUB — ALREADY PAID`. A downward arrow into the **Verba mic mark**, with a small key icon **struck through** and a badge `NO API KEY`. Below, a faint `#0c0c10` editor panel (Cursor / Claude Code) where a clean spec lands. Two-tone headline: **"Already pay for Claude?"** (solid) / **"You're ready."** (45%).
- **The hero beat:** a single emphasized chip `$0 MARKUP` — let the **rec-dot** be its bullet. That is the one saturated mark.
- **Palette / typo:** locked system; lean on the editor dark-panel `#0c0c10` card. Keep red to the one `$0 MARKUP` / `NO KEY` spot. Mono for all UI labels (it *is* the dev voice).
- **Overlay text:** headline "Reuse your Claude Code sub. No API key." [39]. Mono footer: `BRING YOUR OWN AI · NO KEY · ZERO MARKUP`.
- **1.91:1:** left = headline + `NO KEY` badge; right = a clean editor window with a voice HUD pasting a finished spec at the cursor.
- **9:16:** headline top → vertical "sub → Verba (no key)" flow → editor receiving clean text → CTA pill.
- **Scene / mockup honesty:** show the **real** model picker — `Claude (your subscription)` / Anthropic key / OpenRouter / Ollama — with **no key field** on the Claude-sub path. Never imply a model or integration that doesn't ship.
- **CTA:** "Have Claude Code? Start free." → `/best-mac-dictation-app`.

---

### ANGLE 3 — Voice → action / JARVIS: "it doesn't just type, it does"

**Core promise:** JARVIS plans the steps, asks when unsure, shows you the action, and executes **only after you confirm** — across 1,000+ connected apps + native Mac actions; the plan is generated on-device by your own AI. **Target:** voice-first operators (founders/PMs) + developers. **Landing page:** `/features` (JARVIS section); planned ideal = a "Jarvis for Mac / voice actions" use-case page (not built yet).

**Headlines (≥3):**
- "It doesn't just type. It does." [30]
- "Say it once. It does it — after you confirm." [44]
- "Jarvis for your Mac, finally." [29]
- "Create the issue. Send the email. By voice." [43]
- "Your voice, now an action — on 1,000+ apps" [42]

**Primary text (≥2):**
- A: "Other dictation apps type. Verba acts. Say 'create a Linear issue for this bug and email the team a summary' — JARVIS plans the steps, asks if something's unclear, shows you exactly what it will do, and runs it only after you confirm. Native Mac actions plus 1,000+ connected apps (Gmail, Slack, Notion, Linear, GitHub). The plan is built on your Mac by your own AI." [366]
- B: "Stop narrating intent and then doing it by hand. Dictate 'schedule it, send it, file it' — Verba's voice agent shows you the action and waits for your confirm before it touches anything. It never auto-runs a write. Your Mac, by voice, on your terms." [249]

**A/B pair (change = abstract benefit vs concrete demo line):**
- A1 (concept): "A voice agent that actually does things." [40]
- A2 (concrete): "I said 'create the issue' — it did it." [38]

#### 🎨 Visual brief — Angle 3 "Say it → confirm → done" (the hero unit)

- **Concept:** *the confirm-gated action.* The whole story is the **confirm step** — that's the trust beat. **Guardrail: never depict an auto-run write.** Every frame shows *shows the action → you confirm → it runs.*
- **Composition (1:1):** a **command bubble** at top (mono: `"create a Linear issue for this bug and email the team"`), an arrow down into a **PLAN CARD** listing 2 steps with checkboxes, and a prominent **CONFIRM** button. Two-tone headline: **"It doesn't just type."** (solid) / **"It does."** (45%).
- **Color discipline:** the **CONFIRM** button is the `#f4f4f6`-fill / `#050507`-text primary style (never red — red must not read as "danger/recording" on the action). The **rec-dot** is reserved for the "listening" state only.
- **Proof row:** a quiet base row of monochrome app marks (Gmail, Slack, Notion, Linear, GitHub) with mono `1,000+ CONNECTED APPS`. On-device note: mono `PLANNED ON YOUR MAC`.
- **Palette / typo:** locked system; plan card on `#0c0c10`. Mono for the command + status; two-tone headline.
- **Overlay text:** "Say it once. It does it — after you confirm." [44] or "It doesn't just type. It does." [30].
- **1.91:1:** left headline; right = the plan-card → confirm sequence (works as a 3-frame mini-storyboard).
- **9:16 VIDEO (render this first — it travels furthest beyond the dictation niche):** 6–15s, silent-first with mono lower-third captions.
  - **Beat 1 (0–3s):** waveform + spoken command appears as text.
  - **Beat 2 (3–7s):** the PLAN CARD materializes — 2 steps, an "asks if something's unclear" clarifying line.
  - **Beat 3 (7–11s):** finger taps **CONFIRM** → a "Done" toast. **Never** show a step firing before the tap.
  - **End card:** mic mark + "It doesn't just type. It does." + `VERBA.RUN`.
- **Scene / mockup:** the Verba JARVIS overlay on a real Mac desktop; Linear + Gmail softly behind; the plan card front-and-center; confirm button hero.
- **CTA:** "Watch it act — after you confirm." → `/features` (JARVIS).

---

### ANGLE 4 — The honest Wispr Flow alternative ($9.99, does more, on-device)

**Core promise:** $9.99/mo vs $12–17 cloud incumbents, does *more* (vision, notes, translate, voice→action), runs on-device, and is honest about where rivals still win. **Target:** bottom-funnel comparison shoppers. **Landing page:** `/vs/wispr-flow` or `/compare` (the 24-feature × 10-brand honest matrix).

**Headlines (≥3):**
- "The honest Wispr Flow alternative" [33]
- "$9.99 a month. Does more. On-device." [36]
- "More than Wispr. Less than $10." [31]
- "Switch from Wispr Flow to Verba" [31]
- "Cheaper, private, and it acts on your words" [43]

**Primary text (≥2):**
- A: "Wispr Flow uploads your audio, costs ~$15, and at the end it just types. Verba is $9.99, runs on-device (your audio never leaves your Mac), reuses the Claude sub you already pay for, and can act on what you say after you confirm. See the honest side-by-side — we even list where Wispr still wins." [296]
- B: "Looking for a Wispr Flow alternative? Verba does more for less: $9.99/mo, on-device privacy, bring-your-own-AI, plus vision, hour-long notes, live translate, and a confirm-gated voice agent. Compare all 24 features across 10 apps — honestly." [241]

**A/B pair (change = price-lead vs capability-lead):**
- A1 (price): "Same job, $9.99. Your audio stays home." [39]
- A2 (capability): "It transcribes, restructures, and acts." [39]

#### 🎨 Visual brief — Angle 4 "Honest side-by-side"

- **Concept:** *the honest compare.* A two-column matrix excerpt — Verba vs Wispr Flow — that **includes a row where Wispr wins.** The honesty *is* the hook (mirrors the real `/compare` "we list where rivals still win").
- **Composition (1:1):** a clean 2-column compare card on `#0c0c10` (**Verba | Wispr Flow**) with ~5 rows:
  - On-device — Verba ✓ / Wispr ✗
  - Price — **$9.99** / ~$15
  - Reuse Claude sub — ✓ / ✗
  - Voice → action (confirm-gated) — ✓ / ✗
  - **One honest row Wispr wins** (e.g. a platform/maturity row) — ✗ / ✓
  - Two-tone headline above: **"More than Wispr."** (solid) / **"Less than $10."** (45%).
- **Color discipline:** checkmarks in the sanctioned **tick green `#6ee7a8`** (the only place it appears), crosses muted. The **rec-dot** anchors the `$9.99` price chip — the single saturated mark.
- **Palette / typo:** locked system; matrix labels in mono; price in the bold headline weight.
- **Overlay text:** "The honest Wispr Flow alternative" [33] or "$9.99 a month. Does more. On-device." [36].
- **1.91:1:** the compare strip horizontal; `$9.99` price callout right; honesty row kept visible.
- **9:16:** price hero top → vertical compare card → CTA bottom.
- **Scene / mockup:** a screenshot-style crop of the real `/compare` matrix zoomed to the Verba vs Wispr columns — including the row a rival wins. Honest by construction.
- **CTA:** "Compare honestly." → `/compare` or `/vs/wispr-flow`.

---

## 3. Google Search — Responsive Search Ads (RSA)

Bottom-funnel intent only. Three ad groups, each tightly themed to one query cluster and pinned to its angle. Each ad group ships **15 headlines (≤30 chars)** and **4 descriptions (≤90 chars)** — Google's RSA max. Counts in `[brackets]`. Pin brand/price headlines to position 1–2 sparingly; otherwise let Google optimize. Display path: `verba.run/Mac/Dictation`.

> **Visual note:** Search RSAs are text-only. For Display / Performance Max **companion assets**, reuse the matching angle brief from §2 at 1.91:1 (1200×628) and 1:1 (1200×1200). Ad Group A → Angle 4 brief; Ad Group B → Angle 1 brief (+ Angle 2 chip); Ad Group C → Angle 3 brief.

### Ad Group A — "Wispr Flow alternative" (intent: switchers) → Angle 4
**Landing page:** `/vs/wispr-flow`

**Headlines (15, ≤30):**
1. "Wispr Flow Alternative" [22]
2. "The Honest Wispr Alternative" [28]
3. "More Than Wispr, Under $10" [26]
4. "$9.99/mo, Not $15/mo" [20]
5. "On-Device, Not Cloud" [20]
6. "Your Audio Never Uploaded" [25]
7. "Switch From Wispr Flow" [22]
8. "Dictation That Also Acts" [24]
9. "Reuse Your Claude Sub" [21]
10. "Private Mac Dictation" [21]
11. "See the Honest Compare" [22]
12. "Speak It. Send It Clean." [24]
13. "Try Free, No Card" [17]
14. "Bring Your Own AI" [17]
15. "Does More Than Transcribe" [25]

**Descriptions (4, ≤90):**
1. "On-device, $9.99/mo, and it does more than type. The honest Wispr Flow alternative." [83]
2. "Your audio never leaves your Mac. Reuse your Claude sub, no markup. Try free, no card." [86]
3. "Compare 24 features across 10 apps — we list where rivals still win. See for yourself." [86]
4. "Not just dictation: vision, notes, translate, and a confirm-gated voice agent. $9.99." [85]

### Ad Group B — "Mac dictation app" / "private dictation Mac" (intent: category) → Angles 1 + 2
**Landing page:** `/best-mac-dictation-app`

**Headlines (15, ≤30):**
1. "Private Mac Dictation App" [25]
2. "On-Device Dictation, Mac" [24]
3. "Your Voice Stays on Your Mac" [28]
4. "Voice Never Leaves the Mac" [26]
5. "No Audio Upload, Ever" [21]
6. "Best Mac Dictation App" [22]
7. "Speak It. Send It Clean." [24]
8. "Reuse Your Claude Code Sub" [26]
9. "Bring Your Own AI, No Key" [25]
10. "Runs Offline on Your Mac" [24]
11. "$9.99/mo, Does More" [19]
12. "Clean Text, Not Raw Audio" [25]
13. "Built for Apple Silicon" [23]
14. "Try Free, No Card Needed" [24]
15. "Six Modes, One Hotkey" [21]

**Descriptions (4, ≤90):**
1. "On-device dictation for Mac. Your audio never leaves the device. Try free, no card." [83]
2. "Rambling speech in, clean ready-to-send text out. Six modes, one hotkey. $9.99/mo." [82]
3. "Reuse the Claude sub you already pay for — no API key, no markup. Or run fully local." [85]
4. "Private by default, runs offline, learns your voice. Best private dictation on the Mac." [87]

### Ad Group C — "Jarvis for Mac" / "voice agent" (intent: voice→action) → Angle 3
**Landing page:** `/features` (JARVIS section)

**Headlines (15, ≤30):**
1. "Jarvis for Your Mac" [19]
2. "A Voice Agent for the Mac" [25]
3. "It Doesn't Type. It Does." [25]
4. "Say It. Confirm. It's Done." [27]
5. "Control Your Apps by Voice" [26]
6. "Voice to Action on the Mac" [26]
7. "Create Issues by Voice" [22]
8. "Send Email by Voice" [19]
9. "Acts on 1,000+ Apps" [19]
10. "It Asks Before It Acts" [22]
11. "Plans on Your Mac, Not Ours" [27]
12. "Confirm-Gated Voice Agent" [25]
13. "Speak the Intent, Confirm" [25]
14. "Your Mac, by Voice" [18]
15. "Try Free, No Card" [17]

**Descriptions (4, ≤90):**
1. "Say 'create the issue, email the team.' It shows the action; you confirm; it runs." [82]
2. "A confirm-gated voice agent on 1,000+ connected apps plus native Mac actions. $9.99." [84]
3. "It never auto-runs a write. You see every action and approve it before anything happens." [88]
4. "The plan is built on your Mac by your own AI — never a server key. Try free, no card." [85]

---

## 4. Reddit / X feed ads (primary text + headline + CTA)

Feed ads run **after** community goodwill exists (`gtm-strategy.md` §4 Engine B) — lead with the demo idea, never a hard pitch. Each set: **primary text** + **headline** + **CTA**, paired to its §2 visual brief.

### Feed Ad 1 — Angle 1 (Privacy) · subreddits: r/macapps, r/privacy, r/apple
- **Primary text:** "Most dictation apps upload your voice to their servers. Verba runs on your Mac — your audio never leaves the device and is never uploaded. On-device Whisper/Parakeet, local history with an off switch, keys in the Keychain. Speak freely." [236]
- **Headline:** "Your voice never leaves your Mac" [32]
- **CTA:** Download · **Landing:** `/privacy` · **Visual:** Angle 1 "Containment" (1:1 feed; real screenshot/GIF for Reddit)

### Feed Ad 2 — Angle 2 (BYO-Claude) · subreddits: r/ClaudeAI, r/macapps; X dev audience
- **Primary text:** "If you already pay for Claude Code, you're paying for the AI — so why pay a dictation app a second markup? Verba reuses your Claude Code sub with no API key. Speak a 20-minute ramble, get a clean spec pasted into Cursor or Claude Code. Or run fully local with Ollama." [267]
- **Headline:** "Reuse your Claude Code sub. No API key." [39]
- **CTA:** Learn More · **Landing:** `/best-mac-dictation-app` · **Visual:** Angle 2 "No key" (1:1; editor-panel mockup)

### Feed Ad 3 — Angle 3 (JARVIS) · subreddits: r/productivity, r/ClaudeAI; X founder/agent audience
- **Primary text:** "I said: 'create a Linear issue for this bug and email the team a summary.' Verba planned both steps, showed me exactly what it would do, and ran them only after I hit confirm. It doesn't just type what you say — it does it, after you approve. 1,000+ connected apps, planned on your own Mac." [290]
- **Headline:** "It doesn't just type. It does." [30]
- **CTA:** Watch Demo · **Landing:** `/features` · **Visual:** Angle 3 "Say it → confirm → done" (9:16 + 1:1 VIDEO — the highest-traveling unit; lead the X variant with this clip)

### Feed Ad 4 — Angle 4 (Honest alternative) · subreddits: r/macapps, r/apple; X
- **Primary text:** "Looking for a Wispr Flow alternative? Verba is $9.99 (not ~$15), runs on-device so your audio never leaves your Mac, reuses the Claude sub you already pay for, and does more — vision, notes, translate, and a confirm-gated voice agent. We even publish where rivals still beat us. Compare honestly." [296]
- **Headline:** "The honest Wispr Flow alternative" [33]
- **CTA:** Compare · **Landing:** `/compare` · **Visual:** Angle 4 "Honest side-by-side" (1:1 compare card)

**Format note:** X handles ~1 image/video + short headline best; lead the X variant with the JARVIS clip (Angle 3) — it travels furthest beyond the dictation niche. Reddit rewards plain, non-salesy text and a real screenshot/GIF; keep the body conversational and **disclose it's a promoted post.**

---

## 5. Retargeting ads (/compare + /vs visitors — warm audience) — **switch this on FIRST**

Highest-ROI paid surface, warm intent, cheapest CPA. **Audience:** visited `/compare` or any `/vs/[slug]` but did not download. Mostly comparison-stage — close them on price + the one thing rivals can't match.

### Retarget Set 1 — "/compare" abandoners (saw the full matrix)
- **Headline A:** "Saw the comparison? $9.99 wins." [31]
- **Headline B:** "24 features. One does it all for $9.99." [39]
- **Primary text:** "You compared the matrix. Verba is the only one that's on-device, reuses your Claude sub, and acts on what you say — at $9.99. The trial is free and needs no card. Speak it, send it clean." [187]
- **CTA:** Download · **Landing:** `/best-mac-dictation-app`
- **Visual:** Angle 4 "Honest side-by-side" (static first). The viewer already saw the matrix — the static compare card is the cheap closer.

### Retarget Set 2 — "/vs/wispr-flow" abandoners (cloud-curious)
- **Headline A:** "Wispr uploads. Verba doesn't." [29]
- **Headline B:** "Same job, $9.99, audio stays home." [34]
- **Primary text:** "Still weighing Wispr Flow? It uploads your audio and costs ~$15. Verba is $9.99, on-device, reuses your Claude sub, and can act on what you say after you confirm. Try it free — no card." [185]
- **CTA:** Try Free · **Landing:** `/vs/wispr-flow`
- **Visual:** Angle 1 "Containment" (the upload-strike-through frame) — the cloud-curious need the privacy contrast.

### Retarget Set 3 — "/vs/superwhisper" abandoners (local-curious)
- **Headline A:** "Local, but it also restructures." [32]
- **Headline B:** "On-device AND clean, formatted text." [36]
- **Primary text:** "Like Superwhisper, Verba runs on your Mac — but the AI restructuring is the core, not DIY: rambling in, clean formatted text out, six modes, and a confirm-gated voice agent. Reuse your Claude sub, no key. $9.99." [211]
- **CTA:** Compare · **Landing:** `/vs/superwhisper`
- **Visual:** Angle 2 "No key" + a "rambling in → clean out" before/after strip (1:1).

**Retargeting note:** exclude existing trialists/customers (suppression audience). Cap frequency low (**≤3/week**) — warm audiences fatigue fast. Run **static first** (cheap), then layer the **JARVIS demo video** for the highest-intent segment.

---

## 6. Negative keywords (search campaign)

Protect spend and Quality Score by blocking off-intent, cross-platform, and free-seeker traffic. Match types noted.

**Cross-platform (we are macOS-only — never bid these):**
- `windows` (phrase), `pc` (phrase), `android` (phrase), `iphone` (phrase), `ios` (phrase), `ipad` (phrase), `linux` (phrase), `chromebook` (phrase), `web based` (phrase), `online dictation` (phrase)

**Free-only seekers (won't convert at $9.99):**
- `free` (broad, but keep "free trial" via exact-match positive), `crack` (phrase), `cracked` (phrase), `torrent` (phrase), `free download no subscription` (phrase), `open source` (phrase — VoiceInk-style intent)

**Wrong job / wrong product:**
- `transcription service` (phrase — human transcription), `transcribe audio file` (phrase — file upload, not live), `podcast transcription` (phrase), `meeting recorder` (phrase — Otter intent), `closed captions` (phrase), `subtitle` (phrase), `speech therapy` (phrase), `text to speech` (phrase — the inverse of our product), `voice changer` (phrase), `voice memo` (phrase), `audio to text converter` (phrase — batch file intent)

**Brand-confusion / off-topic:**
- `verba legal` (phrase), `verba volant` (phrase — Latin), `verba latin` (phrase), `iron man jarvis` (phrase), `marvel jarvis` (phrase), `jarvis ai chatbot` (phrase)

**Job seekers / careers:**
- `jobs` (phrase), `salary` (phrase), `hiring` (phrase), `career` (phrase)

> Keep `free trial`, `try free`, and `free download` workable as **exact-match positives** in the campaign while `free` sits broad-negative — the qualifier is what separates a trialist from a freeloader.

---

## 7. Creative testing order — what to test first

Test **one variable at a time**, biggest-lever first. Don't A/B headline fonts before you've found the winning angle. **Generate visuals only after the angle test names a winner — don't fund art for a losing message.**

**Test order (highest leverage → lowest):**
1. **Angle (message) first.** Run all four angles to the *same* warm retargeting audience at equal budget. The winning *value prop* matters 10× more than wording. Hypothesis: **Angle 2 (BYO-Claude)** wins the developer beachhead and **Angle 1 (Privacy)** wins the professional expand-segment — confirm before scaling either. Decide on CPA (cost per trial start), not CTR.
2. **Landing-page match.** For the winning angle, test the angle-matched page vs `/compare` (e.g. Angle 1 → `/privacy` vs `/compare`). Message match usually beats the generic matrix; verify.
3. **Headline within the winning angle.** Only now test the A/B headline pairs (e.g. Angle 4: price-lead "Same job, $9.99" vs capability-lead "It transcribes, restructures, and acts").
4. **Proof element.** Test whether adding a concrete number ("1,000+ apps," "33 free dictations") beats the plain benefit line.
5. **CTA verb.** "Try Free" vs "Download" vs "Compare" — smallest lever, test last.

**First live test (concrete):** retargeting only, Angles 1–4, $X/day split four ways, 7–10 days or until ≥1 statistically meaningful CPA gap. **Primary metric: cost per trial start** (the 7-day Pro trial / first dictation), *not* clicks. Kill the two worst angles, double the budget on the winner, then move to test #2. Only graduate to **cold search** (the §3 RSAs) once a retargeting angle clears a CPA that the $9.99 × retention LTV can support (BYOK = zero COGS widens that headroom).

**Guardrail:** never run a JARVIS creative that shows an *unconfirmed* write — the confirm step is the trust story. Every action clip must show "shows the action → you confirm → it runs."

---

## 8. Landing-page match (every ad set → a real, shipped page)

| Ad set | Angle | Landing page | Status |
|---|---|---|---|
| RSA Ad Group A (Wispr alt) | 4 | `/vs/wispr-flow` | Shipped |
| RSA Ad Group B (Mac dictation) | 1+2 | `/best-mac-dictation-app` | Shipped |
| RSA Ad Group C (Jarvis for Mac) | 3 | `/features` (JARVIS section) | Shipped (no dedicated voice-actions page yet) |
| Feed Ad 1 (Privacy) | 1 | `/privacy` | Shipped |
| Feed Ad 2 (BYO-Claude) | 2 | `/best-mac-dictation-app` | Shipped |
| Feed Ad 3 (JARVIS) | 3 | `/features` | Shipped |
| Feed Ad 4 (Honest alt) | 4 | `/compare` | Shipped (24×10 honest matrix) |
| Retarget Set 1 (/compare) | 4 | `/best-mac-dictation-app` | Shipped |
| Retarget Set 2 (/vs/wispr) | 4 | `/vs/wispr-flow` | Shipped |
| Retarget Set 3 (/vs/superwhisper) | 4 | `/vs/superwhisper` | Shipped |

**Honest gap (L2):** dedicated use-case pages ("dictation for coding," "Jarvis for Mac / control your apps by voice," "private dictation for lawyers") are **planned but not built yet.** Angles 2 and 3 would convert better against a message-matched use-case page than against `/features` / `/best-mac-dictation-app`. **Recommendation:** ship the "/for/claude-code" and "Jarvis for Mac" use-case pages (content-strategy Phase 1) *before* scaling Angle 2/3 paid spend. Until then, point those ads at the real shipped pages above — **never at a URL that doesn't exist.**

**Available `/vs/[slug]` pages (real, for future ad groups):** wispr-flow, superwhisper, macwhisper, aqua-voice, willow-voice, voiceink, apple-dictation, otter-ai, talktastic (`website/lib/competitors.ts`).

---

## 9. Production note — how to actually render these (R-VISUAL-ID)

This document is the **copy + art direction.** The render is a follow-up through the Higgsfield pair, in order — **operator credentials required** (paid plan + `higgsfield auth login`); live generation is **not runtime-verifiable here**.

1. **`higgsfield-soul-id` — once.** Train the Verba identity anchor from the locked §1 system (near-black ground, mic mark, two-tone headline, rec-dot, mono meta). Returns a reference `--soul-id` so every asset stays visually consistent.
2. **`higgsfield-generate --soul-id <id>` — per asset.** One generate per angle × format. **Only after §7 names a winning angle** — don't fund art for a losing message.

**Prompt scaffolds (feed each into `higgsfield-generate`, all on the §1 system):**
- **Angle 1:** "Near-black `#050507` ground, quiet top glow. Centered MacBook; a soft waveform stays *inside* a dotted `ON-DEVICE` boundary; empty void outside. One red `#ff5a4d` rec-dot beside the mono `ON-DEVICE` label. Two-tone headline 'Your voice / never leaves your Mac.' Mono footer `ON-DEVICE · NEVER UPLOADED · KEYS IN KEYCHAIN`. Quiet, architectural, Apple/Linear-tier. {1:1 | 1.91:1 | 9:16}."
- **Angle 2:** "Near-black ground. Dev/editor aesthetic; `CLAUDE CODE SUB — ALREADY PAID` flows into the Verba mic mark; a key icon struck through with a `NO API KEY` badge; one chip `$0 MARKUP` bulleted by the red rec-dot; faint `#0c0c10` editor panel receiving a clean spec. Two-tone headline 'Already pay for Claude? / You're ready.' Mono labels. {1:1 | 1.91:1 | 9:16}."
- **Angle 3 (video):** "Near-black ground. 3 beats: (1) waveform + spoken command text; (2) a plan card with 2 checkbox steps + an 'asks if unclear' line; (3) a finger taps a light `CONFIRM` button → 'Done' toast — never a step firing before the tap. Quiet app-mark row `1,000+ CONNECTED APPS`, mono `PLANNED ON YOUR MAC`. rec-dot = listening state only. Two-tone end card 'It doesn't just type. It does.' {9:16 | 1:1}, 6–15s, silent-first captions."
- **Angle 4:** "Near-black ground. A 2-column compare card (Verba | Wispr Flow) on `#0c0c10`: rows On-device, Price `$9.99` vs ~$15, Reuse Claude sub, Voice→action, plus one honest row Wispr wins. Checkmarks in tick-green `#6ee7a8`; the `$9.99` chip anchored by the red rec-dot. Two-tone headline 'More than Wispr. / Less than $10.' {1:1 | 1.91:1 | 9:16}."

**Guardrails for the renderer (non-negotiable):** macOS only (never show Windows/iOS chrome); JARVIS always confirm-gated (never an auto-run write); privacy claim exact ("never leaves your Mac / never uploaded," and if history shows, show the off switch); public vocabulary only (JARVIS / connected apps / voice agent); one red rec-dot per frame; no Lifetime / Founder's Edition reference (SKU not in Stripe yet).

---

*Resume (FR) : livré `marketing/content-juillet-2026/05-creatifs-pub.md` — la bibliothèque de créatifs pub prête à déployer. **Copy verbatim** de `ad-creative.md` : 4 angles (Privacy, BYO-Claude, JARVIS voix→action, alternative honnête à Wispr) avec headlines + primary texts + paires A/B, RSA Google (3 groupes × 15 titres ≤30 + 4 descriptions ≤90), pubs feed Reddit/X (4 sets), retargeting (/compare + /vs, 3 sets), mots-clés négatifs, ordre de test. **Valeur ajoutée** : un système visuel verrouillé (palette/typo/marques/formats tirés du site réel) + un brief d'art direction exécutable par angle (concept, compo, overlay, formats 1:1 / 1.91:1 / 9:16, scène/mockup, CTA) + scaffolds de prompts higgsfield. Cadrage : le payant démarre APRÈS que l'organique prouve la conversion ; le retargeting (/compare, /vs) est la 1ère surface à allumer ; la génération visuelle réelle via higgsfield (R-VISUAL-ID) est un suivi nécessitant les credentials opérateur. Garde-fous respectés : aucune feature inventée, jamais Windows/iOS, JARVIS confirm-gated, Lifetime exclu (SKU Stripe à créer/tester avant le 28 juil).*
