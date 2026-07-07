# Verba Marketing, ETAT DE VERITE (2026-07-03, soir)

> Carte unique de "qui est canonique" apres nettoyage. Lis ceci en premier. But: que demain soit sans ambiguite.

## RESOLUTION (fix tout, 2026-07-03 23:45)
- **Executeur unique = le hub Marketing-machine.** Preuve: il pousse activement sur origin (mon local est en retard de **11 commits**), c'est le proprietaire actif du repo. **Mon pipeline reste parke** (cron retire). Zero risque de double-post sur le profil zernio unique. Coherence atteinte.
- **Contenu de demain = campagne "It's shipped" du hub** (active, GO operateur recu). Mon **calendrier 90j EN** reste la proposition a challenger (artefact `verba-calendar-90d-validate.html`).
- **Git: NE PAS committer/pousser depuis cette session.** Local en retard de 11 + WIP concurrent = clobber garanti. Le hub (proprietaire actif) reconcilie. Pour resync mon local quand c'est calme: `git stash && git pull --ff-only`.
- **Corruption `product-marketing.md`** (`.md..` separateurs avales par la transform anti-tiret): tres probablement deja corrigee sur origin (hub +11). Ne pas toucher le local divergent, faire le pull.

---

## 1. Incoherence majeure trouvee et neutralisee: DEUX pipelines de publication

Deux sessions ont construit une automation Verba en parallele, sur le **meme profil zernio unique** (16 comptes). Publier depuis les deux = double-post irreversible.

- **Pipeline A (hub Marketing-machine), DESIGNE executeur.** `05-calendar/changelog-campaign.md` (GO operateur recu 2026-07-03) dit noir sur blanc: execution **centralisee vers la session Marketing-machine**, les sessions du repo NE publient PAS. Contenu: campagne **"It's shipped"**, 12 posts (1 par feature reelle du changelog), 2/jour, tous reseaux, angle benefice.
- **Pipeline B (mon moteur repo), MIS EN PAUSE.** `04-publishing/daily-engine/verba-daily.ts` + cron `verba-daily-cron.sh`. Contenu: calendrier **90 jours anglais** (`05-calendar/calendar-90d-en.json`, 94 posts). 

**Action faite:** j'ai **retire mon cron** (`OMEGA-CRON-VERBA-DAILY-v1`) pour respecter la regle "un seul executeur" et supprimer tout risque de double-post. Le moteur + le wrapper restent sur disque (parkes, restaurables en 1 ligne, voir le haut de `~/.omega/bin/verba-daily-cron.sh`). Mon cron etait de toute facon DESARME (ne publiait pas).

## 2. ALERTE a confirmer (sinon rien ne publie demain)
L'executeur designe (hub) n'est **pas actif localement**: `station-daemon.service` = inactive / not-found. Le hub planifie peut-etre via Convex (`engine/convex-app/convex/crons.ts`), mais ce n'est **pas verifie**. **Il faut confirmer que le hub va reellement publier demain**, sinon la campagne ne part pas. C'est le domaine de la session Marketing-machine (R-SCOPE), pas le mien.

## 3. Decision operateur en attente: QUEL contenu demain ?
Deux plans de contenu coexistent, il faut en choisir un (ou les combiner):
- **"It's shipped" (12 features)** = burst de lancement, montre la velocite, tie a des features reelles. Deja GO.
- **Calendrier 90 jours EN (94 posts)** = drumbeat de fond, piliers, sur 3 mois.
Recommandation: le hub execute; burst "It's shipped" en premier (semaine de lancement), puis le 90 jours EN prend le relais comme fond. A trancher.

## 4. SSOT (source de verite par sujet)
| Sujet | Fichier canonique | Note |
|---|---|---|
| Strategie complete | `agentic/reports/verba-strategy-complete.html` + `Verba-Strategie-Marketing-Complete.pdf` (82 p.) | Remplace l'ancien `Verba-Marketing-Strategy.pdf` (45 p., a archiver) |
| Plan 90 jours | `agentic/reports/verba-90day-growth-plan.html` (+ PDF) | Oriente solution |
| Positionnement | `00-context/product-marketing.md` (miroir de `.agents/product-marketing.md`) | En cours de transform anti-dash par la session hub, voir 6 |
| Calendrier auto | `05-calendar/calendar-90d-en.json` (EN) | `calendar-90d.json` (FR) = ancienne version, a archiver |
| Campagne lancement | `05-calendar/changelog-campaign.md` | Pilote par le hub |
| Reddit | `reddit-strategy.md` + `reddit-calendar.json` | AUTO = profil u/VerbaRun uniquement; subs communautaires = HUMAIN |
| Visuels | `06-branding/` + `03-visual-identity/` | Session branding (concurrente) |

## 5. Regle Reddit (importante)
Le SEUL surface Reddit automatisable sans ban = le **profil u/VerbaRun** (self-posts, aucune regle de sub). Tous les subreddits communautaires (r/macapps once/30j, r/ClaudeAI, r/vibecoding, r/cursor...) = **manuels, valeur d'abord, cadence par sub**. Doctrine anti-ban complete + calendrier 90 jours dans `reddit-strategy.md`.

## 6. Depot pas propre a committer maintenant
La session hub fait tourner une **transformation anti-tiret (R-NODASH)** sur les docs numerotes (00-context, 01-strategy, 02-copy, 03-visual-identity), non committee, avec quelques degats collateraux (ex: `PROGRESS.md../../.agents` dans un frontmatter yaml, un separateur ", " avale). **Ne pas committer / git add -A tant que la session hub n'a pas fini** (risque de clobber le WIP concurrent). Laisser le hub finir + corriger sa propre transform.

## 7. Details a nettoyer (mineurs, non bloquants)
- Date J1: le plan 90j dit "7 juil", l'auto disait "4 juil". Sans objet tant que le contenu de demain n'est pas tranche (point 3).
- Quelques `visualPrompt` du calendrier EN citent un prix ("9,99", "149 $"): non publie (le moteur genere l'image depuis `content-packs.ts`, pas depuis ces prompts), mais a scrubber si un jour on genere depuis le calendrier.
- Intermediaires: `05-calendar/en/month*.json` et `agentic/reports/sections/*` = sources d'assemblage, gardees pour reproductibilite.
