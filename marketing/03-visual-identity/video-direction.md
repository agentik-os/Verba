---
project: Verba
layer: visual-identity/video
status: draft-for-operator-validation
created: 2026-07-02
language: meta FR, tout copy publiable en ANGLAIS (règle opérateur 2026-07-02)
gate: RIEN ne se publie ni ne s'automatise tant que l'opérateur n'a pas validé cette direction (phase études/recherche)
---
# Direction vidéo Verba, refonte complète (v2)

## 1. Post-mortem de l'existant (rejeté par l'opérateur, 2026-07-02)

Ce qui ne va pas dans les vidéos actuelles :
- **Aucun montage.** Un seul plan continu, pas de cuts, pas de rythme.
- **Pas de "vidéo".** Un screen-recording brut plein écran, sans cadrage, sans mise en scène.
- **Pas d'histoire.** L'impression de voir "quelqu'un qui parle à son ordinateur en appuyant sur la touche FN". Zéro hook, zéro payoff.
- **Pas de branding.** Ni palette, ni typographie, ni son, ni end card.

Verdict : à refondre de zéro. Ce document définit la nouvelle grammaire.

## 2. La nouvelle grammaire de montage (règles non négociables)

1. **Hook < 1.5 s** : texte kinétique plein cadre + motion, jamais un plan d'ordinateur pour ouvrir.
2. **Un cut toutes les 1.5 à 2.5 s.** Jamais plus de 3 s sur le même plan.
3. **Jamais de screen-recording brut plein écran** : toujours recadré dans un mockup device sur fond #050507, avec des punch-in 110 à 130 % synchronisés sur les beats.
4. **Captions kinétiques** SF Pro bold sur chaque parole ou action, mot à mot, off-white #f4f4f6, un seul accent rouge rec-dot #ff5a4d par frame.
5. **Sound design obligatoire** : music bed + whoosh sur les cuts + clics UI + un "ding" sur le payoff. Le silence de l'existant est interdit.
6. **Pas de talking head par défaut.** La star est l'écran et la voix, pas le visage.
7. **L'étape Confirm est TOUJOURS visible** quand JARVIS agit (argument de confiance).
8. **End card systématique** (1.5 s) : wordmark VERBA + verba.run.
9. **Tout texte à l'écran en anglais.** Zéro tiret cadratin dans le copy.
10. **Claims exacts** : "audio never leaves your Mac", "off switch", jamais "$149 Founder" avant Go/No-Go, jamais "Composio" (dire JARVIS / connected apps), jamais iOS.

## 3. Storyboard, démo canonique JARVIS 30 s (master 16:9 + vertical 9:16)

| # | t | Plan | Texte à l'écran (EN) | Son | Source |
|---|---|---|---|---|---|
| 1 | 0.0-1.5 | Titre kinétique plein cadre sur #050507, waveform pulse derrière | "You talk. Your Mac does it." | Hit musical + whoosh | AI (Higgsfield) |
| 2 | 1.5-4.5 | Mockup MacBook, pill Verba en menu bar, waveform live, captions mot à mot | "Create a Linear issue for the login bug and assign it to me" | Voix + music bed | Screen-rec opérateur |
| 3 | 4.5-7.0 | Punch-in 120 % : la transcription apparaît, propre, instantanée | "On-device transcription. Audio never leaves your Mac." | Clics doux | Screen-rec |
| 4 | 7.0-10.0 | Cut : la plan card JARVIS s'affiche (action planifiée, champs remplis) | "JARVIS plans the action" | Whoosh court | Screen-rec |
| 5 | 10.0-13.0 | Punch-in sur le bouton **Confirm**, curseur clique | "You stay in control. Always confirm." | Clic franc | Screen-rec |
| 6 | 13.0-18.0 | Cuts rapides (3 plans) : Linear s'ouvre, l'issue existe, assignée | "Done. Real issue. Real app." | Ding payoff | Screen-rec |
| 7 | 18.0-24.0 | Split speak-vs-type : à gauche frappe lente, à droite Verba termine | "Typing: 74 words/min. Speaking: 160." | Music monte | AI + screen-rec |
| 8 | 24.0-28.5 | Récap 3 beats texte : privé, ton abonnement Claude, 1000+ apps | "Private by design. Your Claude sub. 1,000+ connected apps." | Music bed | AI |
| 9 | 28.5-30.0 | End card : MicMark + wordmark + CTA | "VERBA. verba.run" | Résolution musicale | AI |

**Cutdowns 15 s** (un par app : Linear, Gmail, Slack, Calendar) : plans 1, 2, 4, 5, 6, 9 uniquement, même grammaire.

## 4. Pipeline de production (qui fait quoi)

- **Opérateur (1 session, ~1 h)** : enregistre les screen-recordings bruts par plan (QuickTime/OBS, 60 fps, écran propre, dark mode), en suivant la table ci-dessus. Pas besoin de jouer : juste exécuter le flow une fois proprement.
- **IA (moi)** : title cards, end cards, b-roll (Higgsfield), et le copy des captions.
- **Montage** : template réutilisable (CapCut/DaVinci au début ; cible = template programmatique Remotion/hyperframes pour que chaque vidéo sorte brandée automatiquement). Le template EST l'automatisation : une fois validé, chaque nouvelle démo = screen-recs bruts en entrée, vidéo montée en sortie.
- **Validation** : chaque master + cutdown part à l'opérateur AVANT toute publication. Rien ne s'automatise tant que la partie vidéo n'est pas validée.

## 5. Assets de validation joints (générés le 2026-07-02)

- Keyframe hook 9:16 (plan 1), keyframe Confirm 9:16 (plan 5), end card 9:16 (plan 9).
- 1 clip vidéo test IA (motion style, 5 s) pour valider le rendu mouvement/branding.
- Envoyés à l'opérateur sur Telegram pour GO / retours.
