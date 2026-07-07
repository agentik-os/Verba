---
project: Verba
layer: strategy/content-angle
status: draft-for-operator-validation
created: 2026-07-02
supersedes: l'angle des posts J1 (cost-math / pricing), rejeté par l'opérateur (satisfaction 3/100)
source: Verba-Marketing-Strategy.pdf (volets 1, 3, 4, 6) + règles opérateur du 2026-07-02
---
# Angle contenu v2 : feature-led, deep-tech, beachhead-first

## Ce qui change (décision opérateur, 2026-07-02)

1. **Zéro angle pricing dans le contenu organique.** Pas de « $9.99 », pas de cost-math. Le prix vit sur le site, pas dans le feed. (Le pilier privacy reste, mais raconté comme de l'ARCHITECTURE : « private by design, tes mots restent privés et en sécurité sur ton Mac », jamais comme une facture.)
2. **Feature-led, ton "tech science avancée".** Chaque post part d'une feature réelle et de son ingénierie, avec les chiffres du produit. Le ton d'un lab notebook, pas d'une pub.
3. **Ciblé beachhead d'abord** (PDF volet 3) : le dev qui code avec un agent IA en CLI sur Mac. On lui parle comme à un pair : specs, architecture, benchmarks, tradeoffs honnêtes.
4. **English only, zéro em dash, médias non compressés** (sendDocument), formats 1:1 / 16:9 pour les reviews.

## La matière première tech (extraite du PDF, volets 1 et 4 ; à vérifier produit avant publication)

- **On-device speech stack** : des modèles privés tournent en local sur Apple Silicon ; l'audio ne quitte jamais le Mac ; historique local avec off-switch ; clés dans le Keychain.
- **Architecture privée** : prolonge ton setup IA existant sans y ajouter quoi que ce soit ; 6 modes de restructuration routés vers le bon modèle selon la tâche ; option 100 % locale possible.
- **JARVIS, agent confirm-gated** : le plan d'action est généré SUR l'appareil, en privé ; catalogue durci vérifié 989 toolkits / 36 998 outils / 100 % de couverture de schéma ; chaque action proposée est validée puis auto-réparée contre le vrai schéma JSON de l'outil ; le classifieur fail-safe traite tout ambigu comme une écriture et n'auto-exécute jamais une écriture ; lectures seules en auto, écritures toujours confirmées.
- **Context (vision d'écran)** : la sortie est ancrée dans ce qui est à l'écran.
- **Activation** : première dictée < 60 s, chemin zéro-clé.

## Les 5 angles de posts v2 (remplacent les posts J1 et suivants)

| # | Feature | Hook (EN, draft) | Visuel |
|---|---|---|---|
| A1 | Pipeline on-device | "Your voice is a tensor that never leaves your Mac. Here is the pipeline." | Schéma blueprint : mic → modèle privé on-device → text, frontière device marquée |
| A2 | Private by design | "Verba never asks where your data should go. There is only one place: your Mac." | Diagramme architecture privée, terminal-style |
| A3 | Confirm-gated agent | "36,998 tools, zero unconfirmed writes. How we hardened the JARVIS action catalog." | Spec sheet : 989 toolkits, 100% schema coverage, fail-safe classifier |
| A4 | Schema auto-repair | "Every action is validated against the tool's real JSON schema, then self-repairs." | Flow : plan → validate → repair → confirm |
| A5 | Context screen vision | "Verba reads your screen so the text lands in your context, not in a vacuum." | Split : écran + sortie ancrée |

Règle d'or : un chiffre réel par post, une seule idée par post, l'étape Confirm visible dès qu'on montre JARVIS, claims privacy exacts, jamais « Composio ».

## Vidéo

La grammaire de montage de `03-visual-identity/video-direction.md` reste, mais le CONTENU des vidéos bascule sur ces angles tech (la démo canonique reste l'actif n°1). Toujours en pause tant que l'opérateur n'a pas validé.
