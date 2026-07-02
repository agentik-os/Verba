---
project: Verba
layer: visual-identity/quality-standard
status: v1, appliqué à TOUTE génération à partir du 2026-07-02
gate: la barre opérateur = "indiscernable d'un vrai tournage Sony Alpha" ; en dessous, on ne montre même pas
---
# Standard qualité de génération, la « marketing machine »

> Règle : AUCUN contenu (image, vidéo, audio) ne sort de la machine sans passer ce standard.
> Historique : satisfaction opérateur 3/100 (angle pricing + compression), 11/100 (UGC ok mais rendu « IA 2020 »).
> La cible est le photoréalisme 2026/2027, pas le « joli pour de l'IA ».

## 1. Vidéo UGC (talking humans)

**Modèles, du meilleur au fallback :**
1. `veo3_1` avec `--model veo-3-1-preview --quality ultra` (JAMAIS le défaut veo-3-1-fast/basic : c'est lui qui donne le rendu « IA 2020 »). Dialogue + lip-sync natifs. 48 crédits/8 s : la qualité coûte, on paie.
2. `seedance_2_0` `--resolution 1080p+ --bitrate_mode high --generate_audio true` (alternative look).
3. `kling3_0 --mode 4k --sound on` (alternative look).
Bake-off sur le même prompt quand on définit un nouveau format récurrent ; l'opérateur tranche.

**Bloc réalisme à préfixer à CHAQUE prompt vidéo (le « Sony Alpha block ») :**
"Ultra-photorealistic UGC footage, indistinguishable from a real video shot on a Sony A7S III with a 35mm f/1.4 lens: shallow depth of field, natural window light, true-to-life skin texture with visible pores and imperfections, individual hair strands, natural color grade, faint sensor grain, subtle handheld micro-shake, imperfect casual framing. Documentary realism, not stylized, not cinematic lighting."

**Bloc audio naturel :** dialogue écrit AVEC hésitations (« So... », « honestly? »), un petit rire, room tone, mouth sounds, no music. Jamais une phrase marketing lue.

**Interdits durs :** écran/interface d'ordinateur visible (MacBook fermé ou dos caméra, main sur la touche Fn ok) ; captions/text overlays générés par le modèle (le texte se pose AU MONTAGE) ; visages « beauty filter » ; lumière studio publicitaire.

## 2. Images (designs statiques)

- Direction validée par l'opérateur (2026-07-02) : blueprint deep-tech noir #050507, hairlines, monospace, un seul accent rouge. On continue cette lancée.
- Feature-led, zéro pricing, un chiffre réel max par visuel, chiffres vérifiés produit.
- **Déclinaison systématique 4 formats** : 9:16 (Shorts/Reels/TikTok), 4:5 (Instagram), 1:1 (X), 16:9 (X/YouTube), en image-to-image depuis le master validé, texte identique lettre à lettre.
- Les assets texte-lourds finaux passent en rendu code (SVG/HTML → PNG) pour zéro typo.

## 3. Contrôle qualité AVANT tout envoi/publication (checklist obligatoire)

1. Vidéo : extraire 3 frames (`ffmpeg select`), zoomer sur visages, mains, objets. Rejeter si : doigts/dents anormaux, UI visible, texte généré, artefacts.
2. Écouter l'audio (ou vérifier la piste) : voix naturelle, pas de robotisme ; sinon re-générer ou re-dubber.
3. Images : relire CHAQUE mot (les modèles cassent les lettres, cf. « M ıac », « AUDIO INPUTT »).
4. Garde-fous copy : anglais, zéro em dash, claims exacts, pas de Composio, pas de $149 avant Go/No-Go, Confirm visible si JARVIS agit.
5. Envoi opérateur : TOUJOURS `sendDocument` (jamais sendPhoto/sendVideo, ça compresse).
6. Un asset rejeté par la checklist ne part JAMAIS « quand même » ; on régénère (max 3 tentatives, puis on escalade à l'opérateur).

## 4. Boucle d'amélioration

Chaque retour opérateur (note /100 + verbatim) est consigné en mémoire projet et ce standard est amendé. Version actuelle calibrée sur les retours du 2026-07-02 (3/100 → 11/100). Objectif : > 80/100.
