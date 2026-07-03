---
project: Verba
layer: 06-branding/prompt-library
produced_by: marketing-machine-upgrade (spec §4.1 6-block spec sheet · §2.4 pre-filled per brand)
status: filled
role: >
 Verba's recurring image shot types, each as a filled 6-block spec sheet bound to Verba tokens.
 Generate WITHOUT --soul-id (scene-led). Append kill-list.md §2 (KILL) to every prompt and §3
 (anti-generic) to every lensed shot. Routing: realistic UGC-style keyframes → Soul 2.0 (short,
 preset-led); readable text / feature grids / character-object tracking → Nano Banana Pro; brand-
 exact CGI color → Flux 2 (see flux-brand.json). Never send readable text to a video model.
---
# Image prompts, Higgsfield (Verba)

> Spec sheet = fiche technique, **pas** une phrase (spec §4). Front-load le sujet. `<200 tokens`. Phrasage positif.
> Tokens : bg #050507 · panel #0c0c10 · fg #f4f4f6 · accent #f4ede0 · rec #ff5a4d · SF Pro · matte · faint grain · MicMark.

---

## SHOT A, Product hero (macOS window, launch card) · Nano Banana Pro
*Pilier : Launch / P4. Slots calendrier : ph-launch-28jul, best-mac-dictation-compare.*

```
[SUBJECT: the Verba macOS menu-bar app, its overlay pill and a crisp real UI card, on a dark
 MacBook Pro screen; no people]
[FRAMING: straight-on product shot, 50mm equivalent, screen fills 4:5, eye-level, f/4]
[LIGHT: one soft directional key from upper-left, low-key matte, near-black room, quiet]
[ATMOSPHERE: palette near-black #050507 field / #0c0c10 macOS-window panel with hairline
 borders / #f4f4f6 crisp UI text; ONE #f4ede0 accent on a single key word; the #ff5a4d record
 dot lit; matte anodized aluminium; MicMark glyph in a black rounded square as a small watermark]
[TECHNIQUE: real screenshot compositing, sharp UI, faint fine grain on the aluminium only, 4:5]
KILL: (kill-list.md §2) + blurred/frosted UI, more than one bright color, the word "Composio"
```

## SHOT B, Founder desk, voice-driven coding · Soul 2.0 preset (short) OR Nano Banana Pro
*Pilier : P1 coding. Slots : dictate-to-claude-code, speak-vs-type.*

```
[preset: Street/Documentary daylight] a developer's hands paused mid-type on a MacBook Pro at a
sober night desk, a dark terminal + Cursor on screen, the small Verba pill overlay near the menu
bar, calm focus, the #ff5a4d record dot lit, no faces needed. near-black room, one soft key
light. no text. --no soul-id
```
*Si lensé sans preset → passer en spec-sheet 6-blocs et **append kill-list §3** (anti-generic : hands paused, pores on the hand in frame, Ricoh GR III, Kodak Gold 200 grain, slight tilt).*

## SHOT C, Private, on-device (closed loop) · Nano Banana Pro / Flux 2
*Pilier : P-A privacy. Slots : audio-never-leaves, private-by-default.*

```
[SUBJECT: a clean closed-loop diagram, an audio waveform contained INSIDE a drawn device
 boundary around a Mac, with a small lock/offline cue; no people]
[FRAMING: centered editorial diagram, flat-on, 1:1 or 4:5]
[LIGHT: flat even low-key, matte]
[ATMOSPHERE: near-black #050507 field; the waveform in #f4f4f6, the device boundary a hairline;
 the single #ff5a4d accent on the record dot; heavy whitespace; "audio never leaves your Mac"
 honesty cue in SF Pro, tight tracking]
[TECHNIQUE: crisp vector-clean render, faint grain on the field only, 1:1]
KILL: (kill-list.md §2) + any audio leaving the boundary, cloud icons, upload arrows
```

## SHOT D, Bring-your-own-AI cost-math (type-led) · Nano Banana Pro
*Pilier : P-B BYO-AI. Slots : pay-twice-math, reuse-claude-sub.*

```
[SUBJECT: a minimalist cost-math visual, one AI bill vs two, big tabular numbers "$9.99" vs
 "$12-17", a Claude-subscription badge reused (no key); no people]
[FRAMING: editorial type-led layout, left-aligned (HeadLeft), 1:1 or 16:9]
[LIGHT: flat editorial, even]
[ATMOSPHERE: near-black #050507; the numbers in #f4f4f6 tabular-nums; the ONE #f4ede0 accent on
 the "$9.99"; whitespace carries it; MicMark watermark]
[TECHNIQUE: clean typographic composition, no photo, faint grain, 1:1]
KILL: (kill-list.md §2) + more than one accent, decorative fonts, invented pricing
```

## SHOT E, JARVIS action feed (Confirm visible) · Nano Banana Pro
*Pilier : P-C voice→action. Slots : jarvis-demo-create-issue, 1000-connected-apps, voice-should-do.*

```
[SUBJECT: the JARVIS action feed on a Mac, a planned action card ("create Linear issue" /
 "email the summary") with a clearly visible Confirm button, connected-apps icons; no people]
[FRAMING: crop on the menu-bar overlay + action card, 9:16 (demo) or 16:9, f/4]
[LIGHT: matte, focused, one soft key]
[ATMOSPHERE: #0c0c10 macOS-window panel, hairline borders, NO blur; #f4f4f6 UI text; the ONE
 #ff5a4d accent as a live cue; the moment BEFORE Confirm, trust; MicMark watermark]
[TECHNIQUE: real UI screenshot, sharp, faint grain on chrome only, 9:16]
KILL: (kill-list.md §2) + hiding the Confirm step, the word "Composio", any invented connected app
```

## SHOT F, Honest /compare grid · Nano Banana Pro
*Pilier : P4 comparisons. Slot : best-mac-dictation-compare.*

```
[SUBJECT: a clean feature-comparison grid, Verba column subtly highlighted, with ONE row where a
 rival wins (radical honesty); no people]
[FRAMING: flat-on grid, 16:9 or 4:5, generous whitespace]
[LIGHT: even, crisp]
[ATMOSPHERE: #0c0c10 panel, hairline borders, no blur; #f4f4f6 text; the Verba column marked
 with the single #f4ede0 accent; #ff5a4d only on the record-dot glyph in the header]
[TECHNIQUE: crisp typographic grid, faint grain, 16:9]
KILL: (kill-list.md §2) + faking a clean sweep (a rival must win one row), more than one accent
```

---

### Usage
1. Choisir le shot (A-F) selon le pilier/slot (`03-visual-identity/higgsfield/shotlist.md`).
2. **Append `kill-list.md §2`** (KILL) à tout prompt · **`kill-list.md §3`** (anti-generic) à tout plan lensé.
3. **Sans `--soul-id`** (scene-led). Texte lisible → Nano Banana Pro/Flux, jamais un modèle vidéo.
4. Passer par la Pass-1 gate (safe-zones, tokens, kill-list scan) avant tout rendu.
