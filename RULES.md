# Verba — Règles projet (canon · à garder & vérifier)

> Fiche de référence **load-bearing** : un agent ou un humain qui reprend le projet lit ça en premier.
> À tenir à jour quand une règle change. L'état machine vit hors-repo dans `~/.omega/state/oracle-verba.*` (externe, non vérifiable depuis le projet) ; ce fichier-ci est la référence in-repo. **Ne pas supprimer.**

## Identité
- **Projet** : Verba — app macOS **menu-bar** de dictée. Parle, Verba transcrit puis utilise **Claude** pour restructurer ton flux de pensée en prompt/message propre (façon Wispr Flow, mais cleanup par LLM avec tes propres clés). Cas d'usage : **vibe coding** + **messaging**.
- **Owner** : Agentik / Dafnck Studio
- **Repo** : `github.com/agentik-os/Verba` · branche `main`
- **Forme** : app macOS (Swift) + site `website/` (Next.js + Convex). Le mobile (iOS + Android) vit dans un repo séparé : `github.com/agentik-os/VerbaMobile` (Expo/EAS).

## Stack
- App macOS : **Swift 6** (SwiftPM, `swift-tools-version:6.0`), cible **macOS 14+**, Xcode 26.
- Deps : **WhisperKit** + **FluidAudio** (transcription locale on-device), **Sparkle** (auto-updates).
- Transcription : **OpenAI** `gpt-4o-transcribe` (cloud) ou **local** (WhisperKit / Parakeet, offline).
- Reprompting : **Claude** (Sonnet par défaut ; Haiku / Opus sélectionnables).
- Site : **Next.js + Convex**, déploiement **Vercel** (`/website`).
- **BYOK** : clés OpenAI + Anthropic apportées par l'user (stockées dans le Keychain macOS) ; Verba ne fait aucun appel API propre.

## Intouchable (source de vérité)
- `Package.swift` / `Package.resolved` = contrat de dépendances. Ne pas casser les versions épinglées.
- Scripts de release : `bundle.sh`, `make-dmg.sh`, `sign-and-notarize.sh`, `release.sh`. Ne pas modifier sans raison.
- `LICENSE` : **propriétaire** © 2026 Agentik / Dafnck Studio. Pas open-source.

## Règles spécifiques (à respecter)
- **Propriétaire** : aucune redistribution du code / des binaires hors accord.
- **BYOK strict** : ne jamais introduire d'appel API facturé côté Verba ; clés via Keychain uniquement.
- **Local-first** : la transcription locale doit rester offline (pas de cloud forcé).
- Permissions macOS requises : **Microphone** + **Accessibilité** (auto-paste ⌘V, fallback presse-papiers).
- Déploiement web : **Vercel avec token explicite** (VPS headless, jamais de login interactif).

## R-CHANGELOG — Changelog auto à jour (obligatoire)
> Dès qu'une feature est **terminée et bien fonctionnelle** (buildée, vérifiée au runtime, shippée), son changelog est mis à jour **dans le même passage** — jamais « plus tard ». Une feature finie sans entrée de changelog n'est **pas** considérée comme done.

**Deux sources de vérité à synchroniser ensemble, toujours :**
1. **App** — `Sources/Verba/Changelog.swift` (montré dans **Settings ▸ Changelog**) : ajouter/mettre à jour l'entrée du jour avec la fourchette de versions, un titre, et les puces de ce qui a changé. Le plus récent en premier.
2. **Site** — `website/app/changelog/page.tsx` (`DAYS[]`, montré sur **verba.run/changelog**) : la **même** entrée, mêmes versions, même contenu.

**Procédure :** même version/fourchette des deux côtés · une puce par changement visible utilisateur · jamais de nom d'utilisateur ni d'info confidentielle (le changelog est public) · mettre aussi à jour les claims chiffrés du site (homepage : nb d'achievements, nb de niveaux, etc.) quand ils changent · déployer le site (`vercel --prod` depuis la racine du repo, root dir = `website`) et inclure le changelog dans la release de l'app.

**Définition de « fini » :** `swift build` clean **et** vérifié au runtime **et** release/déployé. Tant que ce n'est pas réuni, ne pas marquer done — mais dès que ça l'est, le changelog part avec.

## Objectif
- Produit commercial macOS payant (entitlement / free month / leaderboard présents dans les sources). Modèle économique chiffré : *à préciser*.
