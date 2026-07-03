---
project: Verba
layer: 06-branding/prompt-library
produced_by: marketing-machine-upgrade (spec §4.5 avatar scene brief · §3.3 avatar edit grammar)
status: filled-conditional
role: >
 HeyGen avatar scene briefs, DORMANT for Verba. Verba is scene-led with NO recurring human
 avatar (avatar-persona.md / avatar-soul.md), so no talking-head series exists today. This file
 documents HOW HeyGen would plug in IF a founder series is activated in Phase 2, so the pipeline
 is ready without inventing social proof now (honesty L2).
---
# Avatar scene briefs, HeyGen (Verba), **DORMANT / conditional**

## Statut : pas de talking-head aujourd'hui

`heygen_avatar_id: null` · `hasRecurringAvatar: false` (voir `tokens.json.avatar` + `avatar-persona.md`).
Verba est **scene-led / product-led**. Il n'y a **pas** de porte-parole humain, donc **aucune scène HeyGen n'est produite
maintenant**. Ce fichier existe pour que le pipeline soit **prêt** si l'opérateur active un jour une série fondateur (Phase 2),
sans fabriquer de preuve sociale qu'on n'a pas encore.

## Ce qui joue le rôle du « talking-head » aujourd'hui

Pour les explainers, Verba utilise la grammaire **sans visage** : screen-recording de l'app réelle (via `website-to-hyperframes`),
b-roll produit (`video-higgsfield.md`), et VO off. C'est le format lo-fi > polish recommandé pour les marques (spec §5.1),
et il colle à la loi « pas de personnes stock ».

---

## SI activé plus tard, pré-requis (NON fait maintenant)

1. **Décision explicite de l'opérateur** de lancer une série fondateur (Phase 2, voir brief conditionnel dans `avatar-persona.md`).
2. Entraîner l'identité depuis le **vrai fondateur** (Agentik/Dafnck), pas un visage synthétique (honnêteté L2).
  - `higgsfield-soul-id` pour les stills identitaires → remplir `soul_id`.
  - **HeyGen Avatar V** pour le talking-head → remplir `heygen_avatar_id` ici + dans `tokens.json.avatar`.
3. Renseigner la voix : ton *précis · privé · malicieux · pro-user · sans prétention* (les 5 adjectifs de marque).

## Brief-type HeyGen (à remplir seulement après activation, spec §4.5)

```
scene: [n] layout: [fullscreen | pip-corner | graphic-only]
avatar: [heygen_avatar_id, VIDE tant que non activé]
line: "[une respiration, ≤8s, depuis un beat du script scriptwriter]"
tone: précis, franc, un brin malicieux, pro-user
background: [brand template #050507/#0c0c10 OR screen-record de l'app Verba réelle]
wardrobe: sobre, matte, palette tokens.color (pas de couleur vive sur la personne)
captions: depuis les word-timings de l'API HeyGen, style Hormozi, 9:16 seulement, dans la bande safe-zone
```

## Grammaire de montage 3-layouts (spec §3.3, quand la série existera)

Alterner par scène pour simuler le pacing d'un monteur :
1. **Fullscreen avatar** (adresse directe), le fondateur parle.
2. **PiP coin** de l'avatar par-dessus un screen-record de l'app Verba / un graphic animé.
3. **Graphic-only + VO**, l'UI Verba ou le cost-math, la voix off dessus.

Plus : ducking FFmpeg sidechain (musique sous la voix) · musique/SFX par contexte de scène · double export 9:16 (captions brûlés) / 16:9 (clean) depuis une seule compo · captions depuis les word-timings HeyGen, **jamais** timés à la main.

> **Garde-fou :** tant que ce fichier reste *dormant*, aucune scène avatar n'entre dans le calendrier. L'identité de Verba reste le produit + MicMark + rec-dot.
