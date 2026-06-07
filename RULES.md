# Verba — Règles projet (canon · à garder & vérifier)

> Fiche de référence **load-bearing** : un agent ou un humain qui reprend le projet lit ça en premier.
> À tenir à jour quand une règle change. L'état machine vit hors-repo dans `~/.omega/state/oracle-verba.*` (externe, non vérifiable depuis le projet) ; ce fichier-ci est la référence in-repo. **Ne pas supprimer.**

## Identité
- **Projet** : Verba — app macOS **menu-bar** de dictée. Parle, Verba transcrit puis utilise **Claude** pour restructurer ton flux de pensée en prompt/message propre (façon Wispr Flow, mais cleanup par LLM avec tes propres clés). Cas d'usage : **vibe coding** + **messaging**.
- **Owner** : Agentik / Dafnck Studio
- **Repo** : `github.com/agentik-os/Verba` · branche `main`
- **Forme** : app macOS (Swift) + dossier `ios/` + site `website/` (Next.js + Convex).

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

## Objectif
- Produit commercial macOS payant (entitlement / free month / leaderboard présents dans les sources). Modèle économique chiffré : *à préciser*.
