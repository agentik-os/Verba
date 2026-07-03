---
project: Verba
layer: 06-branding
produced_by: marketing-machine-upgrade (spec §2 design-guidelines.md)
status: filled
role: The human-readable grid / safe-zone / type / logo / DO-DON'T reference. Machine values live in tokens.json; this file explains how to apply them on a Verba canvas.
---
# Design Guidelines, Verba

> **Loi :** « Black-craft, Apple-grade precision ». Le premium vient du vide, du type et de la retenue.
> Toute valeur numérique fait foi depuis `tokens.json` (SSOT). En cas de doute, `website/app/globals.css` fait foi (R-CITE).

## 1. Grille & composition

- **Master `1080x1920`.** Recompose vers 4:5 / 3:4 / 1:1, **jamais de crop** (spec §2.1.1).
- **4 colonnes** pour ~80 % des visuels ; **12 colonnes** dès qu'un slide dépasse 50 mots.
- **Marges dures :** 60px gauche, 150px haut. Cadrage **à gauche** par défaut (`HeadLeft`), casse la boucle centrée générique.
- **Une idée par écran.** Max 2 blocs de texte par slide. L'argument doit être lisible depuis les seuls titres.
- **Hiérarchie de matériaux** (DA §Composition) : `panel` (opaque, ombre profonde, hairline spéculaire haut, look fenêtre macOS, réservé au héros) > `card` (tinté plat, bord 1px, **NO blur**) > `glass` (nav + overlay live-demo seulement).

## 2. Safe zones (calques verrouillés, spec §2.1.2)

| Plateforme | Zone utile | Bandes à éviter |
|---|---|---|
| Universel | `900x1400` centré | tout le reste |
| Meta (Stories/Reels, mars 2026) |, | top 14 % (270px) · bottom 20 % Stories / 35 % Reels (670px) · côtés 6 % |
| TikTok | `900x1492` | 108px haut · 320px bas · 60px gauche · **120px droite (barre d'action)** |
| Payant |, | +50-80px en bas |

- **Réserve caption IA : 250px en bas**, laissée vide au-dessus de la safe-zone basse (auto-captions plateforme).
- Titre, chiffre-clé, CTA et **l'étape Confirm de JARVIS** vivent **toujours** dans la zone universelle.

## 3. Échelle typographique (spec §2.1.4 · `tokens.json.type`)

- **2 familles :** SF Pro Display (titres) + SF Pro Text (corps), fallback Inter. **Rien d'autre.**
- **Display** 600 / -0.035em / LH 0.98 · **Statement** 500 / -0.03em · **Anchor/Section** 600 / -0.028→-0.022em · **Lead** 400 / `--fg-dim` / LH 1.5.
- **Saut display→corps ≈ 2,4x.** Cover ≤12 mots (~0,7 s). Sous-titre brûlé 4-7 mots/plan.
- **Eyebrow** UPPERCASE +0.18em `--faint`, **rare**. **Chiffres** en `tabular-nums`.

## 4. Couleur (60/30/10 · spec §2.1.5)

- **60 %** neutre quasi-noir (`bg #050507` / `bg2 #0a0a0d`) · **30 %** chrome (`surface #0c0c10` / `surface2 #101015`, bordures hairline) · **10 %** accent `#f4ede0` (un seul élément clé/cadre).
- **`rec #ff5a4d` = la seule couleur vive**, réservée au point d'enregistrement / au moment live. **Jamais deux accents forts dans un cadre.**
- WCAG AA 4.5:1 sur tout texte. Light mode via `[data-theme="light"]` (accent `#1a1410`, rec `#e23b2e`).

## 5. Logo MicMark (spec §2.1.8)

- Glyphe micro dans carré arrondi noir (radius ~0,26×). Clear space = 1 X-height. Mini ≥64px post / ≥40px overlay.
- Avatar = icon-only. Bannière = lockup horizontal. Watermark vidéo = MicMark blanc, coin, discret.
- Fonds approuvés seulement : `#050507 / #0a0a0d / #0c0c10 / #f6f6f7`.

## 6. DO / DON'T (garde-fous anti-générique, DA §DO/DON'T)

**DO**
- Fond quasi-noir #050507, fg #f4f4f6, **un** accent #f4ede0 par parcimonie, rec #ff5a4d comme seule couleur vive.
- Type SF Pro grand, tracking serré, beaucoup de vide. MicMark comme signature. `tabular-nums` sur les chiffres.
- Captures d'UI **réelles**, lumière mate, grain léger. Toujours montrer le **Confirm** dans les démos d'action.
- Respecter dark/light. Recomposer, ne jamais cropper.

**DON'T**
- ❌ Blobs/dégradés pastel dérivants, dégradés arc-en-ciel, dégradés AI par défaut.
- ❌ Stock « équipe qui sourit », 3D plastique brillante, néons saturés, emoji-soup.
- ❌ Plus d'**une** couleur vive par visuel ; noyer l'accent #f4ede0.
- ❌ Fontes décoratives hors SF Pro/Inter ; eyebrow partout.
- ❌ Afficher **« Composio »** (noms publics = *JARVIS* / *connected apps*). Feature inventée. Claim privacy inexact.
- ❌ Motion : bounce, overshoot cartoon, dégradés animés, motion-blur-comme-style, spin 3D (voir `tokens.json.motion.prohibited`).
