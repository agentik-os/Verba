---
project: Verba
layer: 06-branding/templates
produced_by: marketing-machine-upgrade (spec §2.5 · hyperframes frame.md)
status: filled
role: >
 The hyperframes COMPOSITION DIRECTIVES for Verba, "frame.md directs the composition"
 (pacing / scale / dwell / motion), the counterpart to design.md's brand descriptor. Consumed by
 hyperframes animation adapters via data-start/data-duration + Remotion sequence props.
---
# frame.md, Verba composition directives

## Canvas & grid (see tokens.json.canvas)
- Master **1080x1920**. Recompose vers 1080x1350 / 1080x1440 / 1080x1080, **jamais de crop**.
- 4 colonnes (défaut) / 12 colonnes (>50 mots). Marges dures 60px gauche / 150px haut. Cadrage **à gauche** (HeadLeft).
- **Safe-zone 900x1400 verrouillée** + réserve caption **250px** en bas (calques non-exportables). Bandes plateforme : voir `tokens.canvas.safeZones`.

## Scale (hierarchy on the frame)
- **Un** élément dominant par frame (le titre OU le chiffre OU la carte d'action). Saut display→corps ≈ 2,4x.
- Une idée par écran, max 2 blocs de texte. L'argument lisible depuis les seuls titres.
- L'UI Verba (screenshot réel) occupe un panel `surface #0c0c10`, hairline borders, **NO blur**, nette.

## Pacing (short-form, spec §5.1)
- **Hook livré ≤2,5 s**, texte gros lisible en frame 1, **pas** de logo/intro « hey guys ».
- **Reset visuel toutes les 3-5 s** (framing / B-roll / zoom / changement de texte), encodé en beat grid.
- Structure inversée : payoff d'abord, méthode après.
- Longueur défaut 15-35 s ; +5-10 s en éducation ; 30-60 s en intention conversion.
- **Loop** l'ending (Shorts) : dernière frame → première.

## Dwell (hold times)
- Chaque bloc de texte tenu **≥2 s**. Sous-titre brûlé 4-7 mots. Cover ≤12 mots.
- L'étape **Confirm** (démos JARVIS) tenue assez pour être lue, c'est l'argument.
- Le rec-dot #ff5a4d pulse pendant toute la scène « live ».

## Motion (bind to tokens.json.motion)
- `enter` 150 ms `cubic-bezier(0,0,0.2,1)` · `revealAdjacent` 250 ms `cubic-bezier(0.33,1,0.68,1)`.
- Transitions autorisées : **fondu court · slide minime · match-cut**. Rien d'autre.
- **PROHIBÉ :** bounce, overshoot, dégradés animés, type étiré, motion-blur-comme-style, spin 3D (`tokens.motion.prohibited`).
- Reduced-motion : rec statique, reveals instantanés, hiérarchie préservée.

## Audio (spec §4.3, le son fait 50 % du reel)
- Toujours dirigé : `SFX:`, `Ambient noise:`, dialogue en `"..."` + `(no subtitles)`. Captions word-synced ajoutés en montage, jamais auto ni timés main.
- Ducking FFmpeg sidechain si musique (musique sous la voix).

## Export
- Double format depuis une seule compo : **9:16** (captions brûlés, safe-zone) + **16:9** (clean).
- Watermark MicMark blanc discret en coin (vidéo).

## Frame checklist (avant rendu)
- [ ] Éléments critiques dans 900x1400 · réserve 250px libre · bandes plateforme OK.
- [ ] Un seul accent vif (#f4ede0 OU rec-dot #ff5a4d) · UI nette · tokens seulement.
- [ ] Hook frame 1 · beat ≤5 s · loop (Shorts) · Confirm visible (JARVIS) · pas de « Composio ».
- [ ] Motion dans la whitelist · audio dirigé · double export prêt.
