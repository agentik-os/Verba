# Verba — État d'avancement (recap)

> Recap **humain**, dérivé de `git log` + contenu du repo + `~/.omega/state/oracle-verba.*`.
> L'**état machine** que lisent les agents reste les fichiers dans `~/.omega/state/` — ce fichier ne les remplace pas, il les rend lisibles. Régénérable.
> Dernière synchro : 2026-06-07

## En un coup d'œil
- **Phase** : développement actif — app macOS fonctionnelle en cours, site web câblé.
- **Repo** : `github.com/agentik-os/Verba` @ `27fb6c9` (branche `main`). Quelques fichiers non suivis en cours (dont ce `PROGRESS.md` et `RULES.md`) — pas encore committés.
- **État machine** : suivi hors-repo dans `~/.omega/state/oracle-verba.*` (externe au projet, non vérifiable ici) — se référer à ces fichiers pour l'état réel des missions.

## Composants — état
| Composant | Rôle | État |
|---|---|---|
| App macOS (`Sources/Verba`) | menu-bar dictée + reprompt Claude | développée (~40 fichiers Swift : pipeline, transcription, overlay, settings, onboarding, leaderboard…) |
| `ios/` | variante iOS (App + clavier) | amorcé (`project.yml` + README + Shared/VerbaApp/VerbaKeyboard) |
| `website/` | site Next.js + Convex | câblé, build `.next` présent, lié à Vercel (`.vercel`) |
| Release | bundle / DMG / sign-notarize / Sparkle | scripts prêts (`bundle.sh`, `make-dmg.sh`, `sign-and-notarize.sh`, `release.sh`) |

## Fait récemment (git)
- `27fb6c9` — chore(repo) : ignore `.vercel` et `.env*` (artefacts Vercel CLI / wiring deploy VPS)
- `942359b` — top island sous la menu bar (clear notch), pill arrondi, niveau normal

## Prochaines étapes
- *À préciser* (pas de roadmap/`.planner` dans le repo). Pistes visibles : finaliser variante `ios/`, déploiement site Vercel, release signée/notarisée macOS.

## Docs clés
- Présentation produit : `README.md` (racine) + `ios/README.md`
- Contrat deps : `Package.swift` / `Package.resolved`
- Règles projet : `RULES.md`
- Licence : `LICENSE` (propriétaire)
