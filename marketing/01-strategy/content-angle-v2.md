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

1. **Zéro angle pricing dans le contenu organique.** Pas de « $9.99 », pas de « stop paying twice », pas de cost-math. Le prix vit sur le site, pas dans le feed. (Le pilier BYO-Claude reste, mais raconté comme de l'ARCHITECTURE : « no API key, reuses your Claude Code session », jamais comme une facture.)
2. **Feature-led, ton "tech science avancée".** Chaque post part d'une feature réelle et de son ingénierie, avec les chiffres du produit. Le ton d'un lab notebook, pas d'une pub.
3. **Ciblé beachhead d'abord** (PDF volet 3) : le dev Claude Code-native sur Mac. On lui parle comme à un pair : specs, architecture, benchmarks, tradeoffs honnêtes.
4. **English only, zéro em dash, médias non compressés** (sendDocument), formats 1:1 / 16:9 pour les reviews.

## La matière première tech (extraite du PDF, volets 1 et 4 ; à vérifier produit avant publication)

- **On-device speech stack** : Whisper + Parakeet tournent en local sur Apple Silicon ; l'audio ne quitte jamais le Mac ; historique local avec off-switch ; clés dans le Keychain.
- **BYO-Claude architecture** : réutilise la session Claude Code, sans clé API ; 6 modes de restructuration routés vers le bon modèle (Haiku / Sonnet / Opus) ; fallback Ollama local possible.
- **JARVIS, agent confirm-gated** : le plan d'action est généré SUR l'appareil par ton propre Claude ; catalogue durci vérifié 989 toolkits / 36 998 outils / 100 % de couverture de schéma ; chaque action proposée est validée puis auto-réparée contre le vrai schéma JSON de l'outil ; le classifieur fail-safe traite tout ambigu comme une écriture et n'auto-exécute jamais une écriture ; lectures seules en auto, écritures toujours confirmées.
- **Context (vision d'écran)** : la sortie est ancrée dans ce qui est à l'écran.
- **Activation** : première dictée < 60 s, chemin zéro-clé.

## Les 5 angles de posts v2 (remplacent les posts J1 et suivants)

| # | Feature | Hook (EN, draft) | Visuel |
|---|---|---|---|
| A1 | Pipeline on-device | "Your voice is a tensor that never leaves your Mac. Here is the pipeline." | Schéma blueprint : mic → Whisper/Parakeet local → text, frontière device marquée |
| A2 | BYO-Claude, no key | "Verba has no API key field. It speaks to the Claude Code session you already run." | Diagramme session hand-off, terminal-style |
| A3 | Confirm-gated agent | "36,998 tools, zero unconfirmed writes. How we hardened the JARVIS action catalog." | Spec sheet : 989 toolkits, 100% schema coverage, fail-safe classifier |
| A4 | Schema auto-repair | "Every action is validated against the tool's real JSON schema, then self-repairs." | Flow : plan → validate → repair → confirm |
| A5 | Context screen vision | "Verba reads your screen so the text lands in your context, not in a vacuum." | Split : écran + sortie ancrée |

Règle d'or : un chiffre réel par post, une seule idée par post, l'étape Confirm visible dès qu'on montre JARVIS, claims privacy exacts, jamais « Composio ».

## Vidéo

La grammaire de montage de `03-visual-identity/video-direction.md` reste, mais le CONTENU des vidéos bascule sur ces angles tech (la démo canonique reste l'actif n°1). Toujours en pause tant que l'opérateur n'a pas validé.
