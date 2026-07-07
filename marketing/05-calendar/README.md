---
project: Verba
layer: calendar
status: to-fill
---
# Calendrier prévisionnel, Verba

> Ton plan opérationnel quotidien. Objectif : savoir **chaque jour quoi faire en 30 min, 2 h**.
> 1 à 3 posts/jour. Chaque item est taggé **AUTO** ou **MANUEL**.

## Les 2 modes
- **AUTO** 🤖, je génère le texte + le visuel et je poste via `omega-zernio post verba …` (aucune action de ta part). C'est le gros du volume.
- **MANUEL** 🙋, nécessite un humain : vidéo/selfie fondateur, prise de parole perso, réponse à des commentaires/DM, validation avant envoi. C'est là que passe ton temps.

## Ton budget 30 min, 2 h / jour
Tu ne fais QUE les items **MANUEL** du jour + l'engagement. Le reste part tout seul.
Regarde `calendar-14d.md` → colonne MODE. Fais les 🙋, ignore les 🤖 (ils se publient).

## Fichiers
- `calendar-14d.md`, le plan 14 jours (dates, plateformes, textes complets, mode, temps estimé).
- `calendar.json`, version machine (alimente le poster auto / zernio).
- `daily-human-tasks.md`, les rituels humains récurrents (engagement, veille, DM).

## Mise en route de l'AUTO
Connecte les comptes (`omega-zernio connect verba <platform>`), puis les items AUTO peuvent être postés/programmés. Voir `04-publishing/zernio.md`.
