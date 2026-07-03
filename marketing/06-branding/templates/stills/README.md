---
project: Verba
layer: 06-branding/templates/stills
produced_by: marketing-machine-upgrade (spec §2.5 · §5.2 · 6 Remotion <Still> archetypes)
status: filled
role: >
 The 6 mandatory Remotion <Still> archetypes described for Verba, Cover/Hook, Big-Stat, Step,
 Quote, Chart, CTA. Rendered via renderStill / `npx remotion still --props` for data-driven
 batches (fallback: Playwright-screenshot of HyperFrames-style HTML at 1080x1350, R-TEST). All 6
 share the locked layers (logo, safe-zone, grid, color roles from tokens.json) and expose only
 editable slots (headline, image/UI, stat, CTA). Change a token → propagates to all 6.
---
# Remotion <Still> archetypes, Verba

> Master **1080x1920**, feed/carousel **1080x1350 (4:5)**, cover **1080x1080 center-safe**. Recompose, never crop.
> **Calques verrouillés** (tous les archétypes) : MicMark (coin), safe-zone 900x1400, grille 4-col, rôles couleur `tokens.json`.
> **Slots éditables** : headline · image/UI · stat · CTA. Grain faint sur le fond, UI toujours nette.
> Anti-générique : type = héros, oversized headline + minimal support, dé-stériliser avec un soupçon de grain (spec §5.2). Un message, un CTA.

---

## 1. Cover / Hook (`<CoverStill>`)
- **But :** l'audition de 2 secondes (carrousel/reel). Curiosity gap + outcome mesurable, ≤12 mots.
- **Compo :** headline display SF Pro 600 sur `bg #050507`, cadrée à gauche (HeadLeft), énorme, tracking serré. ONE mot pivot en `accent #f4ede0`. Le rec-dot #ff5a4d en petit cue. Air généreux. Swipe cue discret (« → »).
- **Slots :** `{headline}` (ex. « The Mac dictation app that became a voice agent »), `{swipeCue}`.
- **Exemples Verba :** « Speak it. Send it clean. » · « 3 shifts that cut my typing in half ».

## 2. Big-Stat (`<BigStatStill>`)
- **But :** un chiffre qui claque (preuve / cost-math BYO-AI).
- **Compo :** un **grand nombre `tabular-nums`** centré-gauche en `text #f4f4f6`, le chiffre pivot en `accent #f4ede0`, label muet en dessous. `bg #050507`, whitespace massif.
- **Slots :** `{stat}` (ex. « $9.99 », « 989 toolkits », « 99+ languages », « 0 audio uploaded »), `{label}`.
- **Règle :** un seul accent · honnêteté (chiffres réels de product-marketing.md, jamais inventés).

## 3. Step (`<StepStill>`)
- **But :** une étape d'un tutoriel / du flow JARVIS (une action par slide).
- **Compo :** un panel `surface #0c0c10` (look fenêtre macOS, hairline, NO blur) portant une **capture UI réelle** ou l'étape ; badge d'étape (3/10) en `tabular-nums`. Pour JARVIS : l'étape **Confirm visible**.
- **Slots :** `{stepIndex}`, `{stepTitle}`, `{uiScreenshot}`.
- **Exemples :** « 1 · Parle » → « 2 · Verba nettoie » → « 3 · Confirme » → « 4 · C'est fait ». Jamais « Composio ».

## 4. Quote (`<QuoteStill>`)
- **But :** une phrase de marque / un principe (pas de faux témoignage tant que la preuve n'existe pas, L2).
- **Compo :** `t-statement` SF Pro 500, tracking -0.03em, sur `bg #050507`, cadrée à gauche, beaucoup de vide. MotifRule séparateur. Attribution sobre (Verba / un principe), jamais un client fictif.
- **Slots :** `{quote}`, `{attribution}`.
- **Exemples :** « Ta voix ne devrait pas quitter ton Mac. » · « It asks before it acts. »

## 5. Chart (`<ChartStill>`)
- **But :** une data-viz simple (compare honnête, speak-vs-type, cost-math).
- **Compo :** graphe minimal sur `surface #0c0c10`, hairline borders, `text #f4f4f6` ; la série Verba marquée du **seul** `accent #f4ede0` ; pour /compare, montrer **une ligne où un rival gagne** (honnêteté radicale). `tabular-nums`.
- **Slots :** `{chartData}`, `{caption}`.
- **Exemples :** barres « speak » vs « type » · grille /compare 24 features.

## 6. CTA (`<CtaStill>`)
- **But :** slide de clôture (+ micro-CTA « save this » en milieu de deck).
- **Compo :** une ligne d'action claire SF Pro 600 sur `bg #050507`, le CTA en `accent #f4ede0` ou dans un bouton `surface` ; MicMark lockup ; URL `verba.run`. Un seul CTA.
- **Slots :** `{ctaLine}`, `{url}`.
- **Exemples :** « Speak it. Send it clean → verba.run » · « Try 33 free dictations ».

---

## Production (spec §2.5 · §5.2)
- Rendu : `npx remotion still --props='{...}'` par post → slides 4:5 + cover 1:1 center-safe → carrousel IG / assemblage PDF LinkedIn (7-10 slides). Fallback : Playwright-screenshot d'un HTML HyperFrames à 1080x1350 (R-TEST : Playwright CLI via Bash, jamais un MCP browser).
- **Locked vs editable** appliqués par le composant, pas par convention. Changer un token dans `tokens.json` → propage aux 6 archétypes.
- Passer la Pass-1 gate (safe-zones, contraste AA, réserve caption, tokens, kill-list scan) avant export.
- Continuité carrousel : panorama sans couture / bleed bord droit / progress markers (3/10) ; mini-payoff slide 2-3, gros payoff slide 8+ ; toujours finir sur CTA + « save this » à mi-deck.
