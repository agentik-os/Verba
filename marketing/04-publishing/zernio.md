---
project: Verba
layer: publishing
tool: omega-zernio (tools/zernio/cli.ts) → https://zernio.com/api/v1
profile_slug: verba
status: filled
note: NO auto-connect/auto-publish en setup. Connexion OAuth = étape opérateur. Le CLI omega-zernio est installé (~/.local/bin/omega-zernio).
---
# Publishing, Verba (zernio)

> Un profil zernio par projet (`verba`). Les comptes se connectent via OAuth (étape opérateur). **Aucune connexion ni
> publication automatique en setup.** Le CLI `omega-zernio` est présent (`~/.local/bin/omega-zernio`, source `tools/zernio/cli.ts`).

## Target platforms (priorité, depuis content-strategy.md)
**Prioritaires (le beachhead vit là) :**
- **twitter** (X), canal #1 : build-in-public, démos JARVIS, threads.
- **linkedin**, privacy + opérateurs voice-first (après beachhead).
- **youtube**, démos longues / Shorts (speak-vs-type, JARVIS).
- **instagram** + **tiktok**, Shorts/Reels (démos before/after, Translate).

**Secondaires / earned (pas via zernio API, étiquette manuelle stricte) :**
- **reddit** (r/macapps, r/ClaudeAI, r/LocalLLaMA), démo, jamais pitch ; à poster **à la main** (étiquette communauté).
- Hacker News / Lobsters, hors zernio, manuel.
- **threads**, **bluesky**, optionnels (overflow X).
- **facebook**, **pinterest**, **snapchat**, **telegram**, **discord**, **whatsapp**, **googlebusiness**, non prioritaires pour ce ICP B2C dev/Mac.

## Connect commands (lancées par l'opérateur, ouvre l'authUrl hébergé)
```bash
omega-zernio connect verba twitter
omega-zernio connect verba linkedin
omega-zernio connect verba youtube
omega-zernio connect verba instagram
omega-zernio connect verba tiktok
omega-zernio accounts verba    # vérifier isActive
```

## Publish (APRÈS validation du contenu + comptes connectés, NE PAS publier en setup)
```bash
# Toujours --dry-run d'abord
omega-zernio post verba --text "…" --platforms twitter,linkedin --media ./asset.png --dry-run
# Puis planifier (l'opérateur choisit la date après validation)
omega-zernio post verba --text "…" --platforms twitter --schedule 2026-07-28T07:01:00Z
```

## Cadence (depuis content-strategy.md)
| Plateforme | Cadence | Pic runway lancement (juil 2026) |
|---|---|---|
| twitter | 4-6 / sem | quotidien (build-in-public T-4→T+8) |
| linkedin | 2-3 / sem | 3 / sem |
| youtube/tiktok/instagram | 1-2 Shorts / sem | démo JARVIS + speak-vs-type avant le 28 juil |
| reddit (manuel) | 1-2 posts à fort signal / sem | r/macapps + r/ClaudeAI le 30 juil (T+2) |

> File de publication amorcée dans `calendar.json` (≥10 stubs, `scheduledFor: null`). L'opérateur planifie après validation.
