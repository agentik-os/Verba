---
project: Verba
layer: 06-branding/prompt-library
produced_by: marketing-machine-upgrade (spec §4.1 KILL block · §4.2 anti-generic · §6.2 kill-list scan)
status: filled
role: Verba's standing negatives + banned quality words + the anti-generic realism block. Every image/video prompt in this library appends the relevant section; the Pass-1 gate scans every prompt against this file (spec §6.2).
---
# Kill-list, Verba

## 1. Banned quality words (2026 AI signatures, spec §4.1)

Ne **jamais** écrire dans un prompt :
`8K`, `ultra-realistic`, `hyperrealistic`, `masterpiece`, `cinematic`, `golden hour`,
`Portra 400`, `Cinestill 800T`, `award-winning`, `trending on artstation`, `bokeh`,
`highly detailed`, `photorealistic render`, `octane`, `unreal engine`.

> Ces mots **lisent comme de l'IA** en 2026 (hedra.com, aivideobootcamp.com). Préférer la **factualité photographique** :
> gear réel + **une** logique de lumière physique + imperfection assumée.
> Stocks film autorisés : **Kodak Gold 200**, **Ektachrome**, **Ilford HP5**. Lumière : **flat overcast daylight** ou une source douce unique.

## 2. Verba standing negatives (le KILL block, à mettre dans chaque spec-sheet)

```
KILL: plastic/waxy skin, over-smoothing, oversaturation, stray text or watermark,
extra fingers, dead-even studio light, saturated neon, rainbow / pastel-blob
gradients, drifting AI blobs, glossy plastic 3D, smiling stock business people,
emoji soup, more than ONE bright color in frame, the #f4ede0 accent drowned by
other accents, decorative fonts outside SF Pro / Inter, eyebrows everywhere,
a blurred / frosted product UI (Verba UI must be crisp and real), the word
"Composio" anywhere, any invented feature, an inexact privacy claim
```

## 3. Anti-generic realism block (spec §4.2, append to any LENSED shot: Mac, hands, environment)

Verba n'a pas de Soul (scene-led) → **tout plan lensé** reçoit ce bloc :

```
candid, not posed, in-between moment, natural uneven ambient light, faint
grain, framing a little tilted, slight motion blur on one hand only if hands
are in frame, visible skin pores + subtle subsurface scattering on any hand
in frame, shot on Ricoh GR III or Canon AE-1, Kodak Gold 200 grain
```

> **Exception :** la **capture d'UI Verba reste nette et réelle** (screenshot), jamais grainée ni « générée ». Le grain vit sur l'environnement (bureau, Mac, mains), pas sur l'écran.

## 4. Verba-specific hard rules (non négociables, DA + product-marketing.md)

- **UN** accent vif max par cadre : `accent #f4ede0` sur un seul élément clé **OU** le `rec #ff5a4d` sur le point d'enregistrement, jamais les deux forts ensemble.
- **UI toujours nette**, mate, sur fond #050507 / panel #0c0c10, bordures hairline, **NO blur**.
- **Démos d'action JARVIS :** l'étape **Confirm** doit être visible (argument de confiance).
- **« Composio » n'apparaît JAMAIS**, les noms publics sont *JARVIS* et *connected apps*.
- **Pas de personnes stock**, pas d'avatar humain récurrent, pas de fondateur synthétique (scene-led + honnêteté L2).
- **Claim privacy exact :** « l'audio ne quitte jamais le Mac » / « on-device », jamais « uploads to our servers », « cloud-only », « we train on your data ».

## 5. Positive-phrasing note (spec §4)

Sur les modèles routés Higgsfield et **Flux 2** : **pas de prompt négatif**, phraser positivement (le KILL block reste un garde-fou de revue/gate, à ne pas coller tel quel dans un prompt Flux). Sur Soul 2.0 : prompts courts, preset-led, `no text`. `<200 tokens` sur les modèles routés Higgsfield.

## R-NODASH (RÈGLE DURE) — JAMAIS de tiret cadratin
JAMAIS de `—` (em-dash) ni `–` (en-dash) comme ponctuation, nulle part : copy, captions, texte sur image/vidéo, posts, briefs. Ça sonne IA. Remplacer par virgule / point / deux-points / parenthèses. Le trait dunion `-` des mots composés reste OK. Relire et stripper avant toute livraison.
