---
project: Verba
layer: visual-identity/higgsfield
produced_by: higgsfield-generate (per-shot layer)
status: filled
---
# Higgsfield PRE-PROMPT template, Verba

> Template par-génération. Combine SYSTEM (`system-prompt.md`) + ce PRE-PROMPT + les variables de shot.
> Reste fidèle au DA (`../DA.md`). Aucune génération live en setup (R-VISUAL-ID).

## Template
```
{SYSTEM}
Subject: {subject}
Scene/context: {scene}
Format: {aspect_ratio} for {platform}
Action/emotion: {action}
Lighting: {lighting}
--- on-brand constraints from DA: palette #050507 bg / #f4f4f6 fg / one #f4ede0 accent / one #ff5a4d rec-dot only; SF Pro type, tight tracking, heavy whitespace; matte; faint grain; mic-mark motif; {extra}
```

## Variable presets (par pilier de contenu, depuis content-strategy.md)

### P1 · Voice-driven coding
- `subject`: a developer's hands paused mid-type on a MacBook Pro, dark terminal + Cursor on screen
- `scene`: sober night desk, the Verba pill overlay near the menu bar, a clean prompt being pasted into Claude Code
- `aspect_ratio`: 16:9 (X/blog) · 9:16 (Reels/TikTok)
- `action`: speaking a spec, calm focus · `lighting`: soft directional, matte, near-black room
- `extra`: rec-red dot lit; no faces needed

### P2 · Private, on-device dictation
- `subject`: a closed-loop diagram or a Mac with a small lock/offline cue, audio waveform that stays on-device
- `scene`: clean #050507 field, the waveform NOT leaving a drawn device boundary
- `aspect_ratio`: 1:1 · 4:5 (Instagram) · `action`: stillness, security · `lighting`: low-key matte
- `extra`: single #ff5a4d accent on the rec dot; "audio never leaves your Mac" honesty cue

### P3 · Bring-your-own-AI / no markup
- `subject`: a minimalist cost-math visual, one AI bill vs two, or a Claude-sub badge reused
- `scene`: editorial type-led layout, big tabular numbers, whitespace
- `aspect_ratio`: 1:1 · 16:9 · `action`: clarity, the "aha" of the math · `lighting`: flat editorial
- `extra`: type carries it; accent #f4ede0 on the key number only

### P4 · Best Mac dictation / comparisons
- `subject`: the honest /compare matrix vibe, a clean feature grid, Verba column subtly highlighted
- `scene`: macOS-window panel #0c0c10, hairline borders, no blur
- `aspect_ratio`: 16:9 · 4:5 · `action`: confident transparency · `lighting`: even, crisp
- `extra`: show a row where a rival wins (radical honesty); rec-dot accent

### P5 · Voice → action / "Jarvis for Mac"
- `subject`: the JARVIS action feed on a Mac, a planned action card with a visible Confirm button
- `scene`: menu-bar overlay, "create Linear issue" / "email the summary" step shown, connected-apps icons
- `aspect_ratio`: 9:16 (demo) · 16:9 · `action`: the moment before confirm, trust · `lighting`: matte, focused
- `extra`: the Confirm step MUST be visible (trust argument); never show "Composio"; one rec-red accent
