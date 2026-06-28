# Verba — Paid Ad Creative

> Deliverable 5 of the Verba GTM package · Skill: `/omg-ad-creative` (R-MARKETING: paid copy; pairs with the visual half)
> Reads: `.agents/product-marketing.md` (positioning SSOT, Objections, Customer Language) + `marketing/gtm-strategy.md` (§4 channels, §6 pricing) + `marketing/content-strategy.md`. Scope: **Verba only** (verba.run).
> Date: 2026-06-27 · Author: Oracle (OmegaOS)

---

## 0. Honest framing — read this before you spend a dollar (L2)

Per `gtm-strategy.md` §4, **paid is the last engine, not the first**: *"Paid (only after organic proves conversion)."*
Verba's growth is earned + owned first (comparison/use-case SEO, dev communities, creator demos). **These ad sets are
the ready-to-run paid layer for the moment the organic funnel proves it converts** — they are not a license to skip
Phase 0/1. Two preconditions before any of this goes live:

1. **Activation works** — first dictation < 60s (zero-key Claude Code path + offline Parakeet), and the 33-dictation
   forced-value trial is intact. Paid clicks onto a leaky funnel just burn money faster.
2. **One true free-tier story** is live everywhere (33 dictations) — fix the last `api/try/route.ts` "10,000 words"
   holdout first (`gtm-strategy.md` §5), or the ad promise and the landing page contradict each other.

**Why paid is still viable early:** BYOK means **zero inference COGS** (`product-marketing.md` Proof Points), so even a
modest LTV at $9.99/mo supports paid acquisition once download→paid is proven (model: 7–10% on a forced-value trial,
`gtm-strategy.md` §5). Start paid as **retargeting** (warm /compare + /vs visitors) before cold search — cheapest CPA first.

**Integrity rules baked into every line below (do not break):**
- **No invented features.** Every claim traces to `product-marketing.md`.
- **Never claim Windows or iOS.** Verba is **native macOS only**; iOS is scaffolded, not shipped. When intent is
  cross-platform, the honest answer is "best on Mac" — see the Objections table.
- **Public vocabulary only:** *JARVIS*, *connected apps*, *voice agent*. Never the internal infra name in any ad.
- **Privacy claim stays exact:** "your audio never leaves your Mac / never uploaded" — never "nothing written to disk"
  (audio is kept in local history by default, with an off switch). `product-marketing.md` differentiator #2.
- **Never imply autonomous action.** JARVIS is **confirm-gated**: "it shows you the action, you confirm, it acts."

---

## 1. The four angles (one distinct value prop each)

Each angle below carries the platform-agnostic copy bank: **headlines** (short, ad-headline length), **primary-text**
variants (feed/social body), and **A/B pairs** (one variable changed per pair so the test is clean). Character counts
are shown in `[brackets]` and are computed against the literal string. Google Search RSA assembly is in §2; feed/social
formatting in §3; retargeting in §4.

---

### ANGLE 1 — Privacy: "your voice never leaves your Mac"

**Core promise:** on-device by default; audio never uploaded; local history has an off switch; keys in the Keychain —
*even the action planner runs on your Mac.* **Target:** privacy-first professionals + the privacy-leaning developer.
**Landing page:** `/privacy` (the proof page) or `/vs/wispr-flow` (cloud-upload contrast).

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

---

### ANGLE 2 — BYO-Claude: stop paying twice for the same AI

**Core promise:** bring your own AI — reuse the Claude Code subscription you already pay for, **no API key**, no markup;
or Anthropic key, OpenRouter, or fully local Ollama. **Target:** the Claude Code-native developer (beachhead).
**Landing page:** `/features` (BYOK + modes) or `/best-mac-dictation-app`; planned ideal = a "/for/claude-code" use-case page (not built yet — see §6).

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

---

### ANGLE 3 — Voice → action / JARVIS: "it doesn't just type, it does"

**Core promise:** JARVIS plans the steps, asks when unsure, shows you the action, and executes **only after you
confirm** — across 1,000+ connected apps + native Mac actions; the plan is generated on-device by your own AI.
**Target:** voice-first operators (founders/PMs) + developers. **Landing page:** `/features` (JARVIS section); planned ideal = a "Jarvis for Mac / voice actions" use-case page (not built yet — see §6).

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

---

### ANGLE 4 — The honest Wispr Flow alternative ($9.99, does more, on-device)

**Core promise:** $9.99/mo vs $12–17 cloud incumbents, does *more* (vision, notes, translate, voice→action), runs
on-device, and is honest about where rivals still win. **Target:** bottom-funnel comparison shoppers.
**Landing page:** `/vs/wispr-flow` or `/compare` (the 24-feature × 10-brand honest matrix).

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

---

## 2. Google Search — Responsive Search Ads (RSA)

Bottom-funnel intent only. Three ad groups, each tightly themed to one query cluster and pinned to its angle. Each ad
group ships **15 headlines (≤30 chars)** and **4 descriptions (≤90 chars)** — Google's RSA max — so the system can
assemble and rotate. Counts in `[brackets]`. Pin the brand/price headlines to position 1–2 sparingly; otherwise let
Google optimize. Display path suggestion: `verba.run/Mac/Dictation`.

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

## 3. Reddit / X feed ads (primary text + headline + CTA)

Feed ads run **after** community goodwill exists (`gtm-strategy.md` §4 Engine B) — lead with the demo idea, never a
hard pitch. Each set: **primary text** + **headline** + **CTA**. One per angle.

### Feed Ad 1 — Angle 1 (Privacy) · subreddits: r/macapps, r/privacy, r/apple
- **Primary text:** "Most dictation apps upload your voice to their servers. Verba runs on your Mac — your audio never leaves the device and is never uploaded. On-device Whisper/Parakeet, local history with an off switch, keys in the Keychain. Speak freely." [236]
- **Headline:** "Your voice never leaves your Mac" [32]
- **CTA:** Download · **Landing:** `/privacy`

### Feed Ad 2 — Angle 2 (BYO-Claude) · subreddits: r/ClaudeAI, r/macapps; X dev audience
- **Primary text:** "If you already pay for Claude Code, you're paying for the AI — so why pay a dictation app a second markup? Verba reuses your Claude Code sub with no API key. Speak a 20-minute ramble, get a clean spec pasted into Cursor or Claude Code. Or run fully local with Ollama." [267]
- **Headline:** "Reuse your Claude Code sub. No API key." [39]
- **CTA:** Learn More · **Landing:** `/best-mac-dictation-app`

### Feed Ad 3 — Angle 3 (JARVIS) · subreddits: r/productivity, r/ClaudeAI; X founder/agent audience
- **Primary text:** "I said: 'create a Linear issue for this bug and email the team a summary.' Verba planned both steps, showed me exactly what it would do, and ran them only after I hit confirm. It doesn't just type what you say — it does it, after you approve. 1,000+ connected apps, planned on your own Mac." [290]
- **Headline:** "It doesn't just type. It does." [30]
- **CTA:** Watch Demo · **Landing:** `/features`

### Feed Ad 4 — Angle 4 (Honest alternative) · subreddits: r/macapps, r/apple; X
- **Primary text:** "Looking for a Wispr Flow alternative? Verba is $9.99 (not ~$15), runs on-device so your audio never leaves your Mac, reuses the Claude sub you already pay for, and does more — vision, notes, translate, and a confirm-gated voice agent. We even publish where rivals still beat us. Compare honestly." [296]
- **Headline:** "The honest Wispr Flow alternative" [33]
- **CTA:** Compare · **Landing:** `/compare`

**Format note:** X handles ~1 image/video + short headline best; lead the X variant with the JARVIS clip (Angle 3) — it
travels furthest beyond the dictation niche (`gtm-strategy.md` §4 Engine C). Reddit rewards plain, non-salesy text and a
real screenshot/GIF; keep the body conversational and disclose it's a promoted post.

---

## 4. Retargeting ads (/compare + /vs visitors — warm audience)

Highest-ROI paid surface to switch on **first** (warm intent, cheapest CPA). Audience: visited `/compare` or any
`/vs/[slug]` but did not download. Mostly comparison-stage — close them on price + the one thing rivals can't match.

### Retarget Set 1 — "/compare" abandoners (saw the full matrix)
- **Headline A:** "Saw the comparison? $9.99 wins." [31]
- **Headline B:** "24 features. One does it all for $9.99." [39]
- **Primary text:** "You compared the matrix. Verba is the only one that's on-device, reuses your Claude sub, and acts on what you say — at $9.99. The trial is free and needs no card. Speak it, send it clean." [187]
- **CTA:** Download · **Landing:** `/best-mac-dictation-app`

### Retarget Set 2 — "/vs/wispr-flow" abandoners (cloud-curious)
- **Headline A:** "Wispr uploads. Verba doesn't." [29]
- **Headline B:** "Same job, $9.99, audio stays home." [34]
- **Primary text:** "Still weighing Wispr Flow? It uploads your audio and costs ~$15. Verba is $9.99, on-device, reuses your Claude sub, and can act on what you say after you confirm. Try it free — no card." [185]
- **CTA:** Try Free · **Landing:** `/vs/wispr-flow`

### Retarget Set 3 — "/vs/superwhisper" abandoners (local-curious)
- **Headline A:** "Local, but it also restructures." [32]
- **Headline B:** "On-device AND clean, formatted text." [36]
- **Primary text:** "Like Superwhisper, Verba runs on your Mac — but the AI restructuring is the core, not DIY: rambling in, clean formatted text out, six modes, and a confirm-gated voice agent. Reuse your Claude sub, no key. $9.99." [211]
- **CTA:** Compare · **Landing:** `/vs/superwhisper`

**Retargeting note:** exclude existing trialists/customers (suppression audience). Cap frequency low (≤3/week) — warm
audiences fatigue fast. Run static first (cheap), then layer the JARVIS demo video for the highest-intent segment.

---

## 5. Negative keywords (search campaign)

Protect spend and Quality Score by blocking off-intent, cross-platform, and free-seeker traffic. Match types noted.

**Cross-platform (we are macOS-only — never bid these):**
- `windows` (phrase), `pc` (phrase), `android` (phrase), `iphone` (phrase), `ios` (phrase), `ipad` (phrase),
  `linux` (phrase), `chromebook` (phrase), `web based` (phrase), `online dictation` (phrase)

**Free-only seekers (won't convert at $9.99):**
- `free` (broad, but keep "free trial" via exact-match positive), `crack` (phrase), `cracked` (phrase),
  `torrent` (phrase), `free download no subscription` (phrase), `open source` (phrase — VoiceInk-style intent)

**Wrong job / wrong product:**
- `transcription service` (phrase — human transcription), `transcribe audio file` (phrase — file upload, not live),
  `podcast transcription` (phrase), `meeting recorder` (phrase — Otter intent), `closed captions` (phrase),
  `subtitle` (phrase), `speech therapy` (phrase), `text to speech` (phrase — the inverse of our product),
  `voice changer` (phrase), `voice memo` (phrase), `audio to text converter` (phrase — batch file intent)

**Brand-confusion / off-topic:**
- `verba legal` (phrase), `verba volant` (phrase — Latin), `verba latin` (phrase), `iron man jarvis` (phrase),
  `marvel jarvis` (phrase), `jarvis ai chatbot` (phrase)

**Job seekers / careers:**
- `jobs` (phrase), `salary` (phrase), `hiring` (phrase), `career` (phrase)

> Keep `free trial`, `try free`, and `free download` workable as **exact-match positives** in the campaign while `free`
> sits broad-negative — the qualifier is what separates a trialist from a freeloader.

---

## 6. Creative testing note — what to test first

Test **one variable at a time**, biggest-lever first. Don't A/B headline fonts before you've found the winning angle.

**Test order (highest leverage → lowest):**
1. **Angle (message) first.** Run all four angles to the *same* warm retargeting audience at equal budget. The winning
   *value prop* matters 10× more than wording. Hypothesis: **Angle 2 (BYO-Claude)** wins the developer beachhead and
   **Angle 1 (Privacy)** wins the professional expand-segment — confirm before scaling either. Decide on CPA
   (cost per trial start), not CTR.
2. **Landing-page match.** For the winning angle, test the angle-matched page vs `/compare` (e.g. Angle 1 → `/privacy`
   vs `/compare`). Message match usually beats the generic matrix; verify.
3. **Headline within the winning angle.** Only now test the A/B headline pairs (e.g. Angle 4: price-lead "Same job,
   $9.99" vs capability-lead "It transcribes, restructures, and acts").
4. **Proof element.** Test whether adding a concrete number ("1,000+ apps," "33 free dictations") beats the plain
   benefit line.
5. **CTA verb.** "Try Free" vs "Download" vs "Compare" — smallest lever, test last.

**First live test (concrete):** retargeting only, Angles 1–4, $X/day split four ways, 7–10 days or until ≥1 statistically
meaningful CPA gap. **Primary metric: cost per trial start** (the 7-day Pro trial / first dictation), *not* clicks. Kill
the two worst angles, double the budget on the winner, then move to test #2. Only graduate to **cold search** (the §2
RSAs) once a retargeting angle clears a CPA that the $9.99 × retention LTV can support (BYOK = zero COGS widens that
headroom — `gtm-strategy.md` §5).

**Guardrail:** never run a JARVIS creative that shows an *unconfirmed* write — the confirm step is the trust story
(`content-strategy.md` §8). Every action clip must show "shows the action → you confirm → it runs."

---

## 7. Landing-page match (every ad set → a real, shipped page)

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

**Honest gap (L2):** `content-strategy.md` §2 plans dedicated use-case pages ("dictation for coding,"
"Jarvis for Mac / control your apps by voice," "private dictation for lawyers"). **These are not built yet.** Angle 2
and Angle 3 would convert better against a message-matched use-case page than against `/features`/`/best-mac-dictation-app`.
**Recommendation:** ship the "/for/claude-code" and "Jarvis for Mac" use-case pages (content-strategy Phase 1) *before*
scaling Angle 2/3 paid spend, so the ad promise and the landing message match. Until then, point those ads at the real
shipped pages above — never at a URL that doesn't exist.

**Available `/vs/[slug]` pages (real, for future ad groups):** wispr-flow, superwhisper, macwhisper, aqua-voice,
willow-voice, voiceink, apple-dictation, otter-ai, talktastic (`website/lib/competitors.ts`).

---

## 8. Pairing note — copy is half a creative (R-VISUAL-ID)

This document is the **copy** half. A full paid creative pairs each angle with a visual (the Higgsfield
`higgsfield-generate` step / Marketing Studio): Angle 1 → a Mac with a local "on-device" lock motif; Angle 2 → the
Claude-sub-reuse "no key" beat; Angle 3 → the JARVIS "say it → confirm → done" action clip (the highest-traveling unit);
Angle 4 → the honest side-by-side matrix. Generate visuals only after the §6 angle test names a winner — don't fund
art for a losing message.

---

*Resume (FR): livré `marketing/ad-creative.md` — 4 angles (Privacy, BYO-Claude, JARVIS voix→action, alternative honnête à Wispr), RSA Google (3 groupes × 15 titres ≤30 + 4 descriptions ≤90), pubs feed Reddit/X, retargeting /compare + /vs, mots-clés négatifs, plan de test (angle d'abord, métrique = coût par essai), et un mapping vers des pages réellement déployées. Cadre honnête L2 : le payant vient APRÈS que l'organique prouve la conversion ; aucune fonctionnalité inventée ; jamais Windows/iOS ; nom public JARVIS / connected apps.*
