---
project: Verba
layer: calendar/campaign
status: GO opérateur reçu 2026-07-03 (cadence 2/jour, TOUS réseaux). CENTRALISÉ vers la session `Marketing-machine` (hub) pour exécution : cette session-ci NE publie PAS (éviter double-post irréversible sur le profil Zernio unique).
created: 2026-07-03
source: Sources/Verba/Changelog.swift (SSOT features réelles) + verba.run/changelog
networks: via omega-zernio profil "verba" : 15 comptes actifs (twitter, linkedin, instagram, tiktok, youtube, facebook, threads, reddit, pinterest, telegram + ads)
règles: EN only, zéro em dash, zéro pricing chiffré en organique, claims exacts, Confirm visible si JARVIS, sendDocument pour review
---
# Campagne « It's shipped » : un post par feature du changelog

> Objectif : montrer que Verba livre vite et fort. Chaque feature réelle = 1 post (texte + visuel/vidéo), décliné par réseau, planifié via Zernio. Angle bénéfice (marketing-master), pas la technique.

## Features sélectionnées (marketables, 12 posts)

| # | Feature (changelog) | Bénéfice (le hook) | Preuve/UI à montrer |
|---|---|---|---|
| F1 | **JARVIS, voice agent 1,000+ apps** (0.7.8→0.9.4) | « Dis-le, c'est fait » sur mille apps, après ta confirmation | Carte JARVIS Confirm (site) |
| F2 | **Connected apps** (0.9.34) | Gmail, Slack, Notion, Linear… pilotés à la voix | Grille d'apps connectées (site) |
| F3 | **Prompt mode** (0.9.31/35) | Ta dictée brouillonne devient un prompt propre pour Cursor ou ton outil de code | Panneau Coding/Prompt |
| F4 | **Polish mode** (0.4.4) | Il suit tes auto-corrections, écrit la version finale, pas ton brouillon | Before/After texte |
| F5 | **Translate / 15 langues** (0.6.5, 0.9.32) | Parle dans ta langue, écris dans la leur, en direct | Chip langue sur la pill |
| F6 | **Features page** (0.9.38) | Allume chaque pouvoir un par un ; Verba grandit avec toi | Page Features Essentials/Advanced/Power |
| F7 | **On-device / Private AI** (0.9.4 relay) | Le plan tourne en privé, ton audio ne quitte jamais ton Mac | Panneau engine/local |
| F8 | **Your data, under your control** (0.2.1→0.3.8) | Off-switch historique, auto-delete 7/30/90j, efface tout définitivement | Panneau History controls |
| F9 | **Never lose your last word** (0.9.36) | Le micro reste ouvert un instant : le dernier mot est toujours capté | Pill recording |
| F10 | **Automatic engine self-heals** (0.9.33) | Si un modèle tombe, Verba bascule tout seul, jamais de dead-end | Feed failover |
| F11 | **Dictations stack** (0.9.4) | Enchaîne 10 dictées d'affilée, elles atterrissent toutes | Chips au-dessus de la pill |
| F12 | **A game you can win** (0.4.9, 1,000 levels) | 1 000 niveaux, badges, leaderboard privé : la dictée devient un jeu | Achievements/leaderboard |

## Copy par réseau (gabarit, adapté par feature)
- **twitter (X)** : hook 1 ligne + 2 lignes bénéfice + « → verba.run », ≤ 266 chars, visuel 1:1 ou vidéo 9:16.
- **linkedin** : angle « voici ce qu'on vient de shipper », 3-4 lignes pro + CTA, visuel 1:1/4:5.
- **instagram / tiktok / youtube (Shorts)** : vidéo 9:16 (démo UI + 1 phrase bénéfice + end card), légende courte + hashtags.
- **threads / facebook** : reprise X allégée.
- **reddit** : PAS de broadcast auto, étiquette communauté, à poster manuellement, angle « founder, voici la feature », un seul ask soft.
- **telegram** : annonce courte au canal t.me/verbarun.
- **pinterest** : visuel 2:3 + titre feature.

## Cadence de planification (proposée, à valider)
12 features sur ~2 semaines : 1 post/jour ouvré sur X + LinkedIn en priorité, déclinaison Shorts 2-3×/sem, le reste (threads/fb/telegram/pinterest) en écho. Créneaux : X 16:00 CEST, LinkedIn 10:00, Shorts 17:00.

## Statut de production
- [x] Features sélectionnées + bénéfices (ce doc)
- [ ] Visuels par feature (gabarit site-design HTML→PNG, multi-format 1:1/9:16/4:5/16:9, SAMPLES en cours)
- [ ] Vidéos courtes flagship (style site-design push-in, préféré opérateur)
- [ ] Copy réseau par feature
- [ ] Zernio dry-run tous réseaux
- [ ] **GO opérateur** → planification en masse
