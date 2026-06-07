# Verba — État d'avancement (recap)

> Recap **humain**, dérivé de `git log` + contenu du repo + `~/.omega/state/oracle-verba.*`.
> L'**état machine** que lisent les agents reste les fichiers dans `~/.omega/state/` — ce fichier ne les remplace pas, il les rend lisibles. Régénérable.
> Dernière synchro : 2026-06-07

## En un coup d'œil
- **Phase** : développement actif — app macOS fonctionnelle en cours, site web câblé & déployable depuis le VPS.
- **Repo** : `github.com/agentik-os/Verba` @ `e610222` (branche `main`). Arbo rangée aujourd'hui (`docs/` + `agentic/`, docs périmées corrigées, dotfolders junk retirés). Un seul fichier non suivi : `website/bun.lock`.
- **État machine** : suivi hors-repo dans `~/.omega/state/oracle-verba.*` (externe au projet, non vérifiable ici) — se référer à ces fichiers pour l'état réel des missions.

## Composants — état
| Composant | Rôle | État |
|---|---|---|
| App macOS (`Sources/Verba`) | menu-bar dictée + reprompt Claude | développée (~40 fichiers Swift : pipeline, transcription, overlay, settings, onboarding, leaderboard…) |
| `ios/` | variante iOS (App + clavier) | amorcé (`project.yml` + README + Shared/VerbaApp/VerbaKeyboard) |
| `website/` | site Next.js + Convex | câblé, lié à Vercel (projet `verba`), **déployable depuis le VPS** (recette prebuilt vérifiée) |
| Release | bundle / DMG / sign-notarize / Sparkle | scripts prêts (`bundle.sh`, `make-dmg.sh`, `sign-and-notarize.sh`, `release.sh`) |

## Fait récemment (git)
- `e610222` — chore(tidy+docs) : rangement `docs/` + `agentic/`, correction de docs périmées, suppression de dotfolders junk (PROGRESS.md, README.md, RULES.md)
- `27fb6c9` — chore(repo) : ignore `.vercel` et `.env*` (artefacts Vercel CLI / wiring deploy VPS)
- `942359b` — top island sous la menu bar (clear notch), pill arrondi, niveau normal

## Prochaines étapes
- **Décision opérateur** : fixer `rootDirectory=website` sur le projet Vercel **ou** désactiver les builds prod auto-git → stoppe l'ERROR de prod à chaque push sur `main` (les builds remote git sont cassés en amont ; l'opérateur ship en prebuilt depuis le Mac).
- Compléter le groupe `verba` (manquent `CONVEX_TEAM_TOKEN`/`CONVEX_TEAM_SLUG`/`GITHUB_TOKEN`) ; `STRIPE_WEBHOOK_SECRET` absent de l'env prod (webhook = no-op ack by design).
- Décider du sort de `website/bun.lock` non suivi (commit ou ignore, pour la parité de lockfile).
- Pistes produit : finaliser la variante `ios/`, release signée/notarisée macOS, chiffrer le modèle économique.

## Docs clés
- Présentation produit : `README.md` (racine) + `ios/README.md`
- Contrat deps : `Package.swift` / `Package.resolved`
- Règles projet : `RULES.md`
- Tracking/junk agent : `agentic/` · doc humaine : `docs/`
- Licence : `LICENSE` (propriétaire)

## Journal
- 2026-06-07 — Rangement de l'arborescence du repo (commit `e610222`) : doc humaine regroupée dans `docs/`, tracking agent dans `agentic/`, docs périmées corrigées et dotfolders junk supprimés ; reste `website/bun.lock` non suivi.
