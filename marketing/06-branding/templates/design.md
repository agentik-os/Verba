---
project: Verba
layer: 06-branding/templates
produced_by: marketing-machine-upgrade (spec §2.5 · hyperframes design.md)
status: filled
role: >
 The hyperframes BRAND DESCRIPTOR for Verba, "design.md describes the brand, frame.md directs
 the composition" (github.com/heygen-com/hyperframes, hyperframes.dev/design). Consumed by
 hyperframes animation adapters + Remotion composition props. Values are bound to tokens.json.
---
# design.md, Verba brand descriptor (tokens → video)

## Brand
**Verba, « Black-craft, Apple-grade precision ».** Un système monochrome quasi-noir qui ressemble à l'app macOS
native qu'il vend. Le premium vient du vide, du type et de la retenue. `tokens.json` fait foi.

## Palette (roles, not raw hex in comps)
```
bg    #050507  (dominant ~60%, the near-black field)
bg2    #0a0a0d  (faint chapter band)
surface  #0c0c10  (chrome ~30%, macOS-window panel, opaque, NO blur)
surface2 #101015  (secondary panel)
text   #f4f4f6  (foreground)
textMuted rgba(244,244,246,0.56)
accent  #f4ede0  (~10%, ONE key element per frame, warm off-white)
rec    #ff5a4d  (the one live color, record dot ONLY; never a second loud accent)
```
Light mode via `[data-theme="light"]` : bg #f6f6f7 / text #0a0a0c / accent #1a1410 / rec #e23b2e.

## Type
- **Display :** SF Pro Display (Inter fallback), weight 600, tracking -0.035em, LH 0.98, features `cv01 ss01 ss02 kern`.
- **Body/Lead :** SF Pro Text, 400, LH 1.5, `--fg-dim`.
- **Numbers :** `tabular-nums` everywhere (prices, counts, "989 toolkits", "99+ langues").
- **2 familles max.** Aucune fonte décorative.

## Material hierarchy
`panel` (opaque near-black chrome, hairline specular top edge, real cast shadow, hero only) > `card` (flat tinted, 1px border, **NO blur**) > `glass` (nav + live-demo overlay only).

## Light & texture
- Une source douce directionnelle, low-key matte, pièce quasi-noire. UN vignettage bas + UNE lueur douce en haut. **Pas** de blobs pastel dérivants.
- Grain : un soupçon (feTurbulence ~0.12), texture, jamais un calque. UI toujours nette.

## Motion (see tokens.json.motion)
- Signature : **150 ms ease-out `cubic-bezier(0,0,0.2,1)`** partout. Reveals adjacents 250 ms `cubic-bezier(0.33,1,0.68,1)`.
- Le **rec-dot #ff5a4d** respire doucement (1600 ms loop), la seule motion signature.
- **PROHIBÉ :** bounce, overshoot cartoon, dégradés animés, type étiré, motion-blur-comme-style, spin 3D, transitions tape-à-l'œil.
- Reduced-motion : rec statique, reveals instantanés.

## Recurring signatures
- **MicMark** (glyphe micro dans carré arrondi noir, radius ~0,26×) comme watermark/intro/outro. **MotifRule** comme séparateur.
- Le **rec-dot #ff5a4d** comme unique cue « live ».
- Démos d'action : l'étape **Confirm** toujours à l'écran. **Jamais** « Composio ».

## Voice (for on-screen copy)
Précis · privé · malicieux · pro-user · sans prétention. Direct, honnête, jamais vendeur. Mots : on-device, privé, ton abo Claude, sans marge, propre, voice agent, JARVIS, connected apps, *it asks before it acts*, Confirm.
