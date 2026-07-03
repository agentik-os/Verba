---
project: Verba
layer: 06-branding
produced_by: marketing-machine-upgrade (docs/marketing-machine-upgrade-research.md §2)
status: filled
role: >
 The compiled, machine-readable social brand system for Verba. Every content skill
 (social-content, ad_designer, scriptwriter, creator-media-engine, higgsfield-generate)
 reads THIS + tokens.json before producing anything, same SSOT contract as
 .agents/product-marketing.md. Derived from 03-visual-identity/DA.md (the input DA) and
 website/app/globals.css (canon, R-CITE). 03-visual-identity = input; 06-branding = the system.
language: prose FR (French product, R-STYLE) · tokens.json + machine files universal
---

# SOCIAL BRAND BOOK, Verba

> **« Black-craft, Apple-grade precision. »** Un système monochrome quasi-noir qui *ressemble à l'app macOS
> native qu'il vend* : hiérarchie de matériaux, échelle typo éditoriale, **un seul** accent signature,
> et le point rouge `rec` comme seule couleur vivante. Le premium vient du **vide, du type et de la retenue**,
> pas de l'ornement. La cohérence est **imposée par les fichiers**, pas par la mémoire du designer
> (spec §1.1 : *consistency is ENFORCED BY THE FILES*). Ce livre + `tokens.json` sont cette loi.

**Slogan produit :** *« Speak it. Send it clean. »*, narratif de lancement : *« The Mac dictation app that became a voice agent. »*

---

## 1. Master canvas + grille

*(spec §2.1.1)*

- **Master de design : `1080x1920` (9:16).** Toute autre taille est **recomposée, jamais recadrée** :
 `1080x1350` (4:5, feed IG / carrousel / LinkedIn PDF), `1080x1440` (3:4), `1080x1080` (1:1, cover center-safe, X).
- **Grille :** 4 colonnes pour ~80 % des contenus ; 12 colonnes pour les slides très texte (>50 mots).
- **Marges dures :** ~60px du bord gauche, ~150px du haut. Les sections sont **cadrées à gauche** (`HeadLeft`)
 pour casser la boucle centrée, c'est le tic de compo de Verba (DA §Composition).
- **Le type porte la page :** grandes respirations, marges généreuses, une seule idée par écran.

## 2. Safe zones (valeurs pixel 2026)

*(spec §2.1.2, expédiées comme **calques verrouillés, non-exportables** dans chaque template `templates/`)*

- **Zone universelle :** `900x1400` centrée sur `1080x1920`. Tout élément critique (titre, chiffre, CTA, le Confirm de JARVIS) vit dedans.
- **Meta (Stories/Reels unifiés, mars 2026) :** hors du **top 14 % (270px)**, du **bottom 20 % Stories / 35 % Reels (670px)**, et **6 % des côtés**.
- **TikTok :** zone utile `900x1492`, **108px haut, 320px bas, 60px gauche, 120px droite** (barre d'action).
- **Placements payants :** réservent **50-80px de plus en bas**, le CTA ne descend jamais dedans.
- **Règle :** les erreurs de safe-zone *« s'arrêtent effectivement de se produire »* quand la zone est un calque verrouillé, pas une intention.

## 3. Réserve de sous-titres IA

*(spec §2.1.3)*

- Auto-captions **par défaut activés** sur TikTok / Reels / Shorts : réservent **80px (≤10 mots) à 250px (≤40 mots)**.
- **Bande de réserve Verba = 250px en bas**, au-dessus de la safe-zone basse. Aucun texte de marque ne s'y pose.
- **Max de texte à l'écran par format :** hook/cover ≤ **12 mots** (~0,7 s de lecture) ; sous-titre brûlé **4-7 mots par plan**, tenu ≥2 s, contraste élevé.
- **Continuité contextuelle :** l'audio, le texte à l'écran et le caption partagent les **mêmes mots-clés sémantiques** (`on-device`, `Confirm`, `Claude`, `voice agent`).

## 4. Échelle typographique (mobile-first)

*(spec §2.1.4, voir `tokens.json.type`)*

- **2 familles max**, toutes deux de la stack Apple : **SF Pro Display** (titres) + **SF Pro Text** (corps), fallback **Inter**. Zéro fonte décorative (DA DON'T).
- **Display :** weight **600**, tracking **-0.035em**, line-height **0.98**, features `cv01 ss01 ss02 kern`. Sur le master 1080, une ligne display fait ~96-180px.
- **Statement :** 500, -0.03em. **Anchor/Section :** 600, -0.028 à -0.022em. **Lead :** 400, `--fg-dim`, LH 1.5.
- **Saut réel display→corps ≈ 2,4x** (pas des paliers 1,2x). Test du plissement des yeux à bout de bras : le titre doit rester lisible.
- **Eyebrow :** UPPERCASE, +0.18em, `--faint`, **usage rare** (une poignée, jamais 16).
- **Chiffres :** `tabular-nums` partout (prix 9,99 $, « 989 toolkits », « 99+ langues »).

## 5. Rôles couleur par ratio (comme tokens)

*(spec §2.1.5, **60/30/10**, jamais de hex brut dans les templates, seulement des tokens nommés)*

| Rôle | Ratio | Token(s) | Usage |
|---|---|---|---|
| **Dominant neutre** | ~60 % | `bg #050507`, `bg2 #0a0a0d` | Le fond quasi-noir, partout |
| **Secondaire (chrome)** | ~30 % | `surface #0c0c10`, `surface2 #101015`, bordures hairline | Panels look-fenêtre-macOS, cartes plates |
| **Accent signature** | ~10 % | `accent #f4ede0` | **UN** élément clé par cadre (le chiffre, le mot pivot) |
| **La seule couleur vive** | ponctuel | `rec #ff5a4d` | Le point d'enregistrement / le moment « live », **jamais** deux accents forts dans le même cadre |
| Succès (rare) | ponctuel | `success #6ee7a8` | États validés seulement |

- **Contraste WCAG AA 4.5:1** sur tout texte (fg #f4f4f6 sur bg #050507 est largement au-dessus).
- **Discipline (doctrine Monogram de l'opérateur) :** chrome gris + **UN** accent signature. Le `#ff5a4d` vit *« subliminalement dans chaque élévation »* (les ombres de panel portent une trace de la teinte).
- **Light mode** (`[data-theme="light"]`) : bg `#f6f6f7`, fg `#0a0a0c`, accent `#1a1410`, rec `#e23b2e`.

## 6. Motion tokens

*(spec §2.1.6, voir `tokens.json.motion`, consommés par hyperframes via `frame.md`)*

- **`enter` :** 150 ms `cubic-bezier(0,0,0.2,1)`, **LA** signature d'interaction (`--ease-out` / `--dur-fast`, 150ms *everywhere*).
- **`revealAdjacent` :** 250 ms `cubic-bezier(0.33,1,0.68,1)` (`--ease-out-soft`).
- **`recPulse` :** le point rec #ff5a4d respire doucement (1600 ms, boucle), **la seule motion signature**.
- **Logo intro :** MicMark en fondu qui se pose, 250 ms, **sans bounce**.
- **Whitelist de transitions :** fondu court · slide minime · match-cut.
- **PROHIBÉ (à la Klarna) :** bounce / overshoot cartoon, dégradés animés, type étiré, motion-blur-comme-style, blobs pastel dérivants, dégradés arc-en-ciel, transitions tape-à-l'œil, spin 3D plastique.
- **Reduced-motion :** point rec statique (pas de pulse), reveals instantanés, hiérarchie préservée.
- Démos d'action JARVIS : montrer **toujours** l'étape **Confirm** à l'écran (argument de confiance).

## 7. Registre de templates

*(spec §2.1.7, pointeurs vers `templates/` ; calques verrouillés vs slots éditables)*

| Template | Fichier | Calques VERROUILLÉS | Slots ÉDITABLES |
|---|---|---|---|
| Descripteur marque (vidéo) | `templates/design.md` | palette, type, matériaux, motion | scène, sujet |
| Directives de compo | `templates/frame.md` | grille, safe-zones, pacing, dwell | plan, beat |
| 6 archétypes de slide | `templates/stills/README.md` | logo, safe-zone, grille, rôles couleur | headline, image/UI, CTA |

- **Changer un token dans `tokens.json` propage partout**, un non-designer produit un post on-brand en ~10 min.
- Les slots éditables sont : **headline, capture UI réelle, chiffre, CTA**. Tout le reste est verrouillé.

## 8. Spec logo (MicMark)

*(spec §2.1.8, source : `website/components/Brand.tsx`)*

- **Marque :** le **glyphe micro dans un carré arrondi noir** (`MicMark`, radius ≈ 0,26 × taille). Réutilisé partout, la signature gratuite et infiniment reproductible.
- **Clear space :** une **X-height** sur les 4 côtés. Taille mini : ≥64px en post, ≥40px en overlay vidéo.
- **Avatars/profils :** MicMark **icon-only**. **Bannières :** lockup horizontal (MicMark + wordmark *Verba* SF Pro 600).
- **Watermark vidéo :** MicMark **blanc uniquement**, coin, discret.
- **Séparateur :** `MotifRule` (fine règle portant la marque).
- **Fonds approuvés :** `#050507`, `#0a0a0d`, `#0c0c10`, `#f6f6f7` (light). Jamais sur un fond saturé ou une photo chargée.
- **DON'T :** ne pas étirer, ne pas re-colorer le glyphe, ne pas poser sur néon/dégradé, ne pas noyer sous d'autres accents.

## 9. Avatar / persona

*(spec §2.1.9, détail dans `avatar-persona.md`)*

- **Verba n'a PAS d'avatar humain récurrent.** Décision **scene-led / product-led** (`03-visual-identity/higgsfield/avatar-soul.md`) : l'identité est portée par le **produit réel (Mac + UI Verba)**, le **motif MicMark** et le **rec-dot #ff5a4d**, pas un visage.
- **Pas de `soul_id`, pas de `heygen_avatar_id`.** Générer **sans `--soul-id`**.
- Un porte-parole n'est reconsidéré qu'en Phase 2 (vague UGC/créateurs), et alors depuis le **vrai fondateur** (honnêteté L2), jamais un visage synthétique. Voir le brief conditionnel dans `avatar-persona.md`.

## 10. Gouvernance

*(spec §2.1.10 + §6)*

**Brief d'une page (avant toute génération) :**
1. **Un message** (un seul pilier : P-A privé / P-B BYO-AI / P-C voice→action).
2. **Un proof point** (ex. « l'audio ne quitte jamais ton Mac », « réutilise ton abo Claude », « 989 toolkits »).
3. **Insight d'audience** (le persona visé, beachhead Claude Code par défaut).
4. **2-3 top performers passés** (tirés de `pattern-ledger.md`).

**Pré-flight QA (Pass 1, déterministe, spec §6.2) :**
- [ ] Safe-zones respectées (éléments critiques dans 900x1400 ; bandes plateforme OK).
- [ ] Contraste AA 4.5:1 ; type mini (display ≥ échelle, corps ≥ palier lead).
- [ ] Réserve caption 250px libre ; texte brûlé 4-7 mots, tenu ≥2 s.
- [ ] Conformité tokens (seuls `tokens.json` ; accent **10 % max**, un seul par cadre ; rec = rec-dot uniquement).
- [ ] Scan `kill-list.md` sur chaque prompt (aucun mot banni ; négatifs standing présents).
- [ ] Vidéo : hook en frame 1, beat grid ≤5 s, loop (Shorts), double export 9:16+16:9, captions word-synced.
- [ ] JARVIS : l'étape **Confirm** est visible ; **« Composio » n'apparaît jamais** ; claim privacy exact.

**Pass 2, Taste + marque (adversarial, R-VERIFY) :** `taste-and-aesthetic-director` + `art-director-soul` sur l'artefact **rendu** (screenshot/MP4, pas le code, L1) : anti-kitsch, hiérarchie, « une agence à 150 k$ shipperait-elle ça ? », cohérence de feed vs les 9 derniers posts. Le « done » d'un délégué n'est jamais le verdict.

**Pass 3, Approbation opérateur** avant publication (04-publishing). Modèles/prompts/sources approuvés stockés avec l'asset (audit).

**Boucle de performance (spec §6.2 + `pattern-ledger.md`) :** les métriques reviennent contre le rubric, hook rate ≥75 %, complétion ≥65-70 %, sends-per-reach (IG), swipe-completion >60 % (carrousels), SLA de réponse 1re heure (Reddit). **Un pattern gagnant est PROMU** dans `templates/`/`prompt-library/` ; **un pattern qui échoue 2 fois est retiré.** Un gagnant → post de suivi sous 48 h.

---

### Fichiers frères
`tokens.json` (le pont machine) · `design-guidelines.md` (grille/safe/type/logo, DO/DON'T) · `avatar-persona.md` (scene-led) · `prompt-library/*` (templates pré-remplis Verba) · `templates/*` (code, pas canevas) · `pattern-ledger.md` (le ledger win/lose).
