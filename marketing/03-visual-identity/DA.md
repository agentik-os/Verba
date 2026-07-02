---
project: Verba
layer: visual-identity
produced_by: brand-identity (/omg-brand-identity) + art-director-content-engine
inputs: [website/app/globals.css (charte embarquée "Black-craft, Apple-grade precision"), website/tailwind.config.ts, website/components/Brand.tsx, ../../.agents/product-marketing.md §Brand Voice]
status: filled
reconciles_with: la charte VIT déjà dans website/app/globals.css — ce DA la transcrit, ne la réinvente pas
---
# Direction Artistique (DA) — Verba

> **La loi visuelle que toute génération Higgsfield doit suivre.** Elle n'est PAS inventée ici : elle est **déjà codée**
> dans `website/app/globals.css` (en-tête : *« VERBA — Black-craft, Apple-grade precision »*) et `website/tailwind.config.ts`.
> Ce DA la transcrit fidèlement pour la machine marketing. En cas de doute, le CSS fait foi (R-CITE).

## Visual concept (1 ligne)
**« Black-craft, Apple-grade precision »** — un système monochrome quasi-noir qui *ressemble à l'app macOS native qu'il vend* : hiérarchie de matériaux (panel / card / glass), échelle typographique éditoriale, **un seul** accent signature, et une lumière intentionnelle et silencieuse — pas de blobs pastel.

## Mood / emotion
Précis · privé · calme · premium · pro-user · un brin malicieux (jamais corporate). La sensation : une fenêtre macOS sombre, mate, posée — la qualité vient du **vide, du type et de la retenue**, pas de l'ornement. Confiance discrète, pas de hype.

## Color palette (hex + rôles)
| Token | Hex | Rôle |
|---|---|---|
| `--bg` | **#050507** | Fond quasi-noir (défaut = DARK) |
| `--bg-2` | **#0a0a0d** | Bande de chapitre, fond secondaire |
| `--fg` | **#f4f4f6** | Texte / foreground principal |
| `--panel` | **#0c0c10** | Chrome produit opaque (look fenêtre macOS, **pas** frosted) |
| `--panel-2` | **#101015** | Panel secondaire |
| `--accent` | **#f4ede0** | **L'UNIQUE accent signature** — un blanc cassé chaud, utilisé **avec parcimonie** |
| `--rec` | **#ff5a4d** | **La seule couleur "vivante"** — le point d'enregistrement (rec dot). En light : **#e23b2e** |
| `indigo.brand` | **#6651F2** | Accent logo/gradient secondaire (legacy, à doser) |
| `teal.brand` | **#33B3D9** | Accent logo/gradient secondaire (legacy, à doser) |
| success | **#6ee7a8** / **#16a34a** | États de succès (rare) |
| Light mode | bg **#f6f6f7**, fg **#0a0a0c**, panel **#ffffff** | Variante claire (`[data-theme="light"]`) |
> **Discipline couleur :** monochrome quasi-noir + foreground cassé. Le **#ff5a4d (rec)** est la *seule* touche de couleur vive et vit « subliminalement dans chaque élévation » (les ombres de panel portent une trace de cette teinte). L'accent **#f4ede0** se compte sur les doigts d'une main par écran.

## Typography (display / body)
- **Famille :** `-apple-system, BlinkMacSystemFont, Inter, system-ui` — la stack **SF Pro** d'Apple (fallback Inter). Aucune fonte exotique.
- **Display (`.t-display`) :** `clamp(3.2rem, 7.5vw, 5.75rem)`, weight **600**, tracking **-0.035em**, line-height 0.98, features `cv01 ss01 ss02 kern`.
- **Statement / Anchor / Section :** weight 500–600, tracking serré (-0.022 à -0.03em).
- **Lead :** weight 400, `--fg-dim`, line-height 1.5.
- **Eyebrow :** 0.72rem, UPPERCASE, tracking **+0.18em**, `--faint` — **usage rare** (une poignée, pas 16).
- **Chiffres :** `tabular-nums` (`.tnum`).

## Composition & layout principles
- **Hiérarchie de matériaux :** `panel` (opaque, ombre profonde, hairline spéculaire en haut) > `card` (tinté plat, bord 1px, **NO blur**) > `glass`.
- **Le type porte le premium** : grandes respirations, marges généreuses, sections cadrées à gauche (`HeadLeft`) pour casser la boucle centrée.
- **Motif récurrent :** le **glyphe micro** dans un carré arrondi noir (`MicMark`, radius ≈ 0.26×taille) — la marque unique réutilisée partout, + `MotifRule` comme séparateur.
- **Lumière ambiante :** UN vignettage statique basse-opacité + UNE lueur douce en haut. **Pas** de blobs pastel dérivants.
- **Texture :** un soupçon de grain (feTurbulence, opacity ~.12) — texture, pas calque.

## Photography / illustration style
- **Produit-led / scène-led**, pas de mannequins stock. Sujets : Mac (MacBook Pro / iMac Apple Silicon) en lumière naturelle douce et mate ; la **menu-bar Verba** et l'**overlay/pill** à l'écran ; mains sur clavier qui *s'arrêtent* pendant qu'on parle ; environnements de dev sobres (terminal sombre, Cursor, Linear).
- **Traitement :** quasi-noir, contraste maîtrisé, grain léger, lumière directionnelle douce ; le **point rouge rec (#ff5a4d)** comme seul accent vif dans le cadre. Captures d'UI nettes sur fonds #050507.
- **Pas de :** néons saturés, dégradés arc-en-ciel, 3D plastique brillante, stock « business souriant », emoji-soup.

## Motion language (si vidéo)
- **Signature d'interaction : 150 ms ease-out partout** — `cubic-bezier(0, 0, 0.2, 1)` (`--ease-out`). Reveals adjacents 250 ms ; easing soft `cubic-bezier(0.33, 1, 0.68, 1)` (`--ease-out-soft`).
- Mouvement **discret et précis** : fondus courts, slides minimes, le rec dot qui pulse doucement. Jamais de bounce cartoon ni de transitions tape-à-l'œil. Démos JARVIS : montrer **toujours** l'étape de confirm à l'écran.

## Reference board
- La **homepage `verba.run`** elle-même (référence canonique vivante) + `verba.run/compare`.
- Goût : **Linear**, **Resend**, **Liveblocks** (cités dans `globals.css` comme repères d'easing/bordures) ; precision Apple (pages produit macOS).
- Anti-référence : pages SaaS pastel-blob génériques, dégradés AI par défaut.

## DO / DON'T (garde-fous anti-générique)
**DO**
- Fond quasi-noir #050507 ; foreground #f4f4f6 ; **un** accent (#f4ede0) par parcimonie ; le rec #ff5a4d comme seule couleur vive.
- Type SF Pro, grand, tracking serré, beaucoup de vide. Le motif MicMark comme signature.
- Captures d'UI réelles, lumière mate, grain léger. Toujours montrer le **confirm** dans les démos d'action.
- Respecter dark/light (`[data-theme]`).
**DON'T**
- ❌ Pas de blobs/dégradés pastel dérivants ni de dégradés arc-en-ciel.
- ❌ Pas de stock « équipe qui sourit », ni 3D plastique brillante, ni néons.
- ❌ Pas plus d'**une** couleur vive par visuel ; ne pas noyer l'accent #f4ede0.
- ❌ Pas de fontes décoratives hors SF Pro/Inter ; pas d'eyebrow partout.
- ❌ Ne **jamais** afficher « Composio » (nom public = JARVIS / connected apps) ; pas de feature inventée ; claim privacy exact.
