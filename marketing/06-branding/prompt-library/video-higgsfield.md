---
project: Verba
layer: 06-branding/prompt-library
produced_by: marketing-machine-upgrade (spec §4.3 video · §3.1 routing)
status: filled
role: >
 Verba's recurring video shot types, Veo 3.1 / Seedance 2.0 / Kling 3.0 + image-to-video delta
 templates, bound to Verba tokens. Scene-led, no --soul-id. Directed not described (spec §4.3):
 subject noun byte-identical at every timestamp; characters get fixed labels not pronouns; audio
 ALWAYS directed (dialogue in quotes + "(no subtitles)", SFX:, Ambient noise:), never auto.
 Routing (spec §3.1): b-roll → Kling 3.0 (cheap); UGC-style → Seedance 2.0; hero + native audio
 → Veo 3.1. Never text-to-video cold, keyframe first (image-higgsfield.md), then i2v.
---
# Video prompts, Higgsfield (Verba)

> Tokens : matte near-black #050507 · panel #0c0c10 · fg #f4f4f6 · accent #f4ede0 · rec #ff5a4d · SF Pro · faint grain · MicMark.
> Motion signature = 150 ms ease-out, discret et précis (DA §Motion). **Interdit :** bounce, overshoot, dégradés animés, motion-blur-comme-style. Le son fait 50 % du reel.

---

## V1, Speak → plan → Confirm → done (JARVIS demo) · Veo 3.1 timeline
*Pilier P-C. Slots : voice-should-do, jarvis-demo-create-issue. 9:16, hook en frame 1.*

```
[00:00-00:02] Macro on a MacBook Pro menu bar, the Verba pill glows, the #ff5a4d record dot
 pulses once. On-screen text (SF Pro, tight): "Speak it."
[00:02-00:04] Same Mac screen, the JARVIS action card slides up: "create Linear issue,
 ship v2 onboarding". SFX: soft single UI tick.
[00:04-00:06] Push-in on the visible Confirm button, cursor hovering. Emotion: trust, the
 moment before acting. Ambient: quiet room tone.
[00:06-00:08] The card resolves to "Done", MicMark watermark settles. SFX: one gentle confirm chime.
matte near-black #050507, #0c0c10 panels hairline borders NO blur, one soft key light, faint
grain on chrome only, 9:16, 8s. (no subtitles, captions added in montage)
```
*Confirm **doit** être visible · jamais « Composio ».*

## V2, Speak-vs-type split (voice-driven coding) · Seedance 2.0 timeline
*Pilier P1. Slots : speak-vs-type, dictate-to-claude-code. 9:16.*

```
[00:00-00:02] Split frame: left = a developer's hands typing slowly on a MacBook Pro; right =
 the same hands PAUSED, the Verba pill listening, terminal + Cursor on screen. On-screen: "type"
 vs "speak".
[00:02-00:04] Right side fills a clean prompt into Claude Code, fast; left side still typing.
 SFX: soft keystrokes fading under one voice-note whoosh.
[00:04-00:06] Right side "done", left side mid-sentence. Emotion: the speed gap lands.
matte near-black room, one soft directional key, #ff5a4d record dot lit, faint grain, 9:16, 6s.
(no subtitles). Ambient: quiet night desk.
```
*Sujet « the same hands » **byte-identical** aux deux timestamps (spec §4.3).*

## V3, On-device privacy loop · Kling 3.0 (b-roll) OR i2v from SHOT C keyframe
*Pilier P-A. Slots : audio-never-leaves, private-by-default. 1:1 / 4:5 loop.*

```
Shot 1, flat-on, an audio waveform breathes INSIDE a drawn device boundary around a Mac; a
small lock cue holds. The waveform never crosses the boundary. Camera static, freezing on the
lock. matte #050507 field, waveform in #f4f4f6, ONE #ff5a4d accent on the record dot, heavy
whitespace, faint grain. SFX: a low private room drone, one soft click on the lock. seamless
loop, cyclic motion, 4s, 1:1. (no subtitles)
```

## V4, Cost-math reveal (BYO-AI) · Seedance 2.0 (type-led motion)
*Pilier P-B. Slot : pay-twice-video. 9:16.*

```
[00:00-00:02] Big tabular numbers appear left-aligned: "$12-17/mo" (rivals). On-screen: "pay twice?"
[00:02-00:04] The number is struck; "$9.99" rises in, the ONE #f4ede0 accent on it; a Claude-sub
 badge reused (no key). SFX: one clean type-set snap.
[00:04-00:05] MicMark settles. Ambient: none, silence sells the math.
matte #050507, #f4f4f6 tabular-nums, whitespace, faint grain, 9:16, 5s. (no subtitles)
```

## V5, Image-to-video delta (any keyframe → motion) · template
*Utiliser pour animer une image de `image-higgsfield.md`. Ne jamais redécrire la frame (spec §4.3).*

```
[start_image: <SHOT_x keyframe>] Camera: slow dolly-in, then hard stop (150ms ease-out feel).
Motion: the #ff5a4d record dot pulses gently; a light sweep grazes the matte aluminium; UI stays
razor-sharp and still. Physics: realistic, restrained. Audio: low room drone + one soft UI tick
on the final beat. 9:16, 5s. (no subtitles)
```
*Loops : start = end image + `seamless loop, cyclic motion, 3-6s`.*

---

### Doctrine (spec §3.2 · §4.3)
- **Keyframe d'abord** (`image-higgsfield.md`), puis i2v, **jamais** text-to-video à froid.
- Sujet-nom **byte-identical** à chaque timestamp (Seedance) ; labels de personnage fixes, jamais de pronoms (Kling, mais Verba n'a pas de personnage humain, donc l'« acteur » est le Mac/l'UI).
- **Audio toujours dirigé** : `SFX:`, `Ambient noise:`, dialogue en `"..."` + `(no subtitles)`. Captions ajoutés en montage (word-synced), jamais auto.
- **Beat grid ≤5 s** de reset visuel · hook en frame 1 · loop pour Shorts · double export 9:16 (captions brûlés) + 16:9 (clean).
- Sans `--soul-id`. Append `kill-list.md §3` à tout plan lensé (mains, bureau).
