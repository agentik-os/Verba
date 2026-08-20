# Verba, brief de l'agent dédié

Tu es l'agent dédié au projet **Verba**. Ce fichier est chargé automatiquement quand tu
travailles dans ce dossier : lis-le avant d'agir.

## Ce que c'est

Une app macOS **native**, dans la barre de menus : dictée. Tu parles, Verba transcrit, puis
un LLM (que l'utilisateur contrôle) transforme le flux de conscience en texte propre et
ordonné. **JARVIS**, l'agent vocal de Verba, peut ensuite agir sur ce texte à travers le
système. Ce n'est PAS une app web : c'est du Swift natif, packagé en `.app` puis `.dmg`.

## Stack et architecture (vérifié)

- **Swift** avec **SwiftPM** a la racine : `Package.swift` (swift-tools-version 6.0, cible macOS 14,
  langage en mode v5), `Package.resolved`. Deux executables : `Verba` (`Sources/Verba`) et
  `VerbaWidget` (`Sources/VerbaWidget`). Dependances resolues : WhisperKit 0.18.0, FluidAudio 0.15.1,
  Sparkle 2.9.2.
- **Il y a bien du npm dans ce repo**, mais uniquement dans `website/` : c'est un Next.js 15 + Convex +
  Clerk + Stripe (`website/package.json`, scripts `dev`, `build`, `start`, `lint`). La racine, elle,
  n'a pas de `package.json`.
- Le mobile n'est **pas** ici : il vit dans le repo `github.com/agentik-os/VerbaMobile`
  (Expo/EAS, builds cloud). `MOBILE_APP_PROMPT.md` est le prompt d'origine qui l'a lancé.
- `Localizations/` : les traductions (fichiers `.lproj`).
- `Sounds/`, `WhisperTokenizer/`, `AppIcon.icns` : les assets de l'app. Il n'y a PAS de dossier
  `Resources/` a la racine : `Contents/Resources` est fabrique au moment du bundle par `bundle.sh`.
- `website/` : le site et le backend (Next.js, `convex/`, routes `app/api/`). Deploye sur Vercel,
  projet `verba`, `rootDirectory` = `website`.
- `marketing/` : la machine marketing du projet (site, contenu, calendrier).
- `audits/`, `agentic/` : sorties d'agents, rapports, audits. Rien de "produit" ici.

## Build et distribution

- `swift build -c release` : compile.
- `VERSION=x.y.z ./bundle.sh` : construit le bundle `.app`. **VERSION est obligatoire**, le script
  echoue sans elle.
- `./make-dmg.sh` : produit `Verba.dmg`, mais exige que `Verba.app` existe deja.
- `./sign-and-notarize.sh` et `DEVID=... VERSION=... ./release.sh` : la vraie chaine de publication
  (signature, notarisation, appcast Sparkle, release vers le repo `agentik-os/Verba-releases`).
- L'app macOS ne se "lance" pas comme une app web : on la build et on ouvre le `.app`.
  Le site, lui, se lance normalement (`npm run dev` depuis `website/`).

## Le canon à lire

- **`RULES.md`** : la fiche load-bearing du projet. Elle prime sur ce fichier en cas de
  divergence. Ne la duplique pas ici, va la lire.
- **`PROGRESS.md`** : cense porter l'etat d'avancement, mis a jour chaque nuit par un job.
  **Actuellement casse** : le fichier ne contient qu'une erreur d'authentification 401 du job de nuit.
  Ne t'y fie pas tant qu'il n'a pas ete regenere.
- `WEBSITE-AUDIT-FIXES.md` : les correctifs du site issus de l'audit.

## Pièges (réels, constatés)

- **Pas de `package.json` a la racine** : c'est du SwiftPM. `npm install` n'a de sens que dans `website/`.
- Le repo distant est `github.com/agentik-os/Verba.git` : compte **agentik-os**, pas le
  compte git actif par défaut. Pour un push, force le bon credential
  (`gh auth token -u agentik-os`), sinon tu prends un 403 (R-FICHE).
- La partie marketing du projet a son propre moteur et un calendrier de publication. La
  publication passe par **Zernio** (R-ZERNIO), jamais par un uploader bricolé.
- Zéro tiret long (R-NODASH) dans tout ce qui est copy, marketing, ou texte visible.

## Ton scope

Le produit (Swift, macOS/iOS), son site, et sa machine marketing. Le reste part à Atlas.
