# Verba — Calendrier éditorial · Juillet 2026

> **Colonne vertébrale du dossier `content-juillet-2026/`.** Ce fichier ordonne le mois jour par jour et renvoie, pour chaque pièce, au fichier compagnon où se trouve le copy détaillé (voir la légende §1).
> Construit à partir de : `../content-strategy.md` (§5 calendrier 90 j), `../launch-strategy.md` (§4 timeline T-4→T+8, §6 runbook), `../social-content.md` (cadence + 14 angles). Périmètre : **Verba uniquement** (verba.run).
> Méta/orchestration en **français** ; tout le contenu à publier est en **anglais** (cible dev/Mac anglophone), réutilisé **verbatim** des fichiers de stratégie.

---

## 0. Le narratif, les 3 piliers, la règle beachhead (à coller partout — ne rien changer)

**Le narratif unique de lancement** (titre PH, Show HN, thread X, posts Reddit, titre démo, objet email) :

> ### "The Mac dictation app that became a voice agent."

**Les 3 piliers** (les seuls messages qu'on répète — `../launch-strategy.md` §1) :
1. **Private by default** — your voice never leaves your Mac, never uploaded; even the action planning runs on-device with your own AI.
2. **Bring your own AI** — reuse your Claude Code subscription, no API key, no markup.
3. **It doesn't just type — it *does*** — JARVIS plans, asks when unsure, shows the action, executes **only on your confirm**, across 1,000+ connected apps + native Mac actions.

**L'actif héros (l'unité virale)** : la **démo JARVIS 60 s** — *"I dictate 'create the Linear issue for this bug and email the team a summary' — Verba plans it, shows me both actions, I hit confirm, done."* Chaque canal mène avec un clip de cette démo. **L'étape de confirmation n'est JAMAIS coupée — c'est ça, l'argument de confiance.**

**Règle dure — gagner les devs d'abord** (`../social-content.md` §cadence) : semaines 1-4 = angles dev-natifs P1/P3/P5 (angles 1, 4, 5, 6, 7, 14). On n'élargit aux angles privacy/multilingue/opérateur (3, 9, 10, 12) sur LinkedIn **qu'une fois le beachhead engagé**.

---

## 0bis. Garde-fous non négociables (avant de publier quoi que ce soit)

- **Lifetime / "Founder's Edition" $149 — N'EXISTE PAS encore dans Stripe** (seuls `$9.99/mo` et `$84/yr` sont live). C'est le **levier de lancement prévu**, à **construire et tester en T-4**. **[PRÉREQUIS : SKU Stripe à créer/tester]** — ne JAMAIS écrire le `$149 lifetime` comme déjà dispo sans cette mention, et **ne publier la ligne `$149 Founder's Edition` qu'APRÈS le feu vert du Go/No-Go (ven 24 juil) confirmant le SKU live + testé + entitlement honoré + `?ref` intact**.
- **Aucune fonctionnalité inventée.** Tout claim trace au SSOT. **iOS = scaffolded, pas livré → jamais mentionné.**
- **Noms publics : JARVIS / connected apps** — jamais le nom du fournisseur interne.
- **Jamais de write non confirmé dans une démo** — l'étape "confirm" reste dans chaque clip.
- **Claim privacy exact** : *"your audio never leaves your Mac — local history with an off switch"* — jamais "nothing written to disk".
- **Une seule histoire de free-tier** partout : **33 dictations** sans carte, puis 7 jours Pro. (Le dernier holdout "10,000 words" dans `api/try/route.ts` se ferme en T-4 — bloqueur #1.)
- **Cadence solo-founder** : ~1 post X/jour (rotation), ~1 post communauté/semaine, build-in-public 2×/semaine, Show HN sur le **vrai** milestone (28-29 juil). Pas de sur-publication ; week-ends légers.

---

## 1. Légende — les fichiers du dossier (où trouver le copy détaillé)

| Réf | Fichier | Contenu (copy prêt-à-poster) |
|---|---|---|
| **00** | `00-calendrier-editorial-juillet-2026.md` | **ce fichier** — le plan jour par jour |
| **01** | `01-social-x-...` | X : threads, single tweets, build-in-public notes, hooks (14 angles + swipe bank) |
| **02** | `02-social-communautes-...` | Reddit (r/macapps, r/ClaudeAI), Hacker News (Show HN), Lobsters, Discords + étiquette |
| **03** | `03-social-linkedin-...` | LinkedIn — segments Expand (privacy / notes / translate / opérateur), **fortnightly, après le beachhead** |
| **04** | `04-sequences-email-...` | Emails : teaser, launch email, "we launched", séquence onboarding |
| **05** | `05-creatifs-pub-...` | Pub payante (4 angles, RSA Google, feed, retargeting) — **OFF en juillet**, staged post-conversion |
| **06** | `06-launch-kit-...` | PH (tagline/desc/maker comment), Show HN (titre+body), Reddit posts, X launch thread, **runbook H-par-H**, checklist pré-lancement / gates |
| **07** | `07-partenariats-...` | Outreach : créateurs (seed licenses), newsletters, partenaires/bundles, podcasts, power-users + tier Founder/Lifetime |

> Renvois blog/SEO (posts fondation + `/vs` + `/compare`) → `../content-strategy.md` §5 + §2 (pas de fichier blog dédié dans ce dossier).

---

## 2. Vue hebdomadaire (runway T-4 → Launch)

| Semaine | Dates | Objectif | Livrables clés | Gate d'entrée |
|---|---|---|---|---|
| **T-4** | lun 29 juin – dim 5 juil | Fondations & correctif funnel (GTM Phase 0) | Fix `api/try` 10k-words (bloqueur #1) ; scrub claim privacy ; activation <60 s (zéro-clé Claude Code + Parakeet) ; 1re action confirmée à froid ; instrumentation funnel ; **[PRÉREQUIS] SKU Stripe Founder** | Doc de lancement approuvé ; date verrouillée |
| **T-3** | lun 6 – dim 12 juil | Assets & preuve | **Démo 60 s + 3-4 cutdowns** (Linear/Gmail/Slack/Calendar) ; 2 posts blog fondation [#1][#2] ; refresh 3 `/vs` + `/compare` ; seed 10-20 testeurs alpha (quotes) ; draft du kit de lancement | Correctifs funnel T-4 vérifiés live |
| **T-2** | lun 13 – dim 19 juil | Warm-up communautés & seeding créateurs | Cadence **build-in-public X** démarre ; seed 10-20 créateurs (license + clip) ; présence valeur-d'abord dans les communautés ; warm list Founder ; email teaser | Démo prête ; ≥10 quotes collectées |
| **T-1** | lun 20 – dim 26 juil | Répétition & scheduling | PH listing finalisé ; **PH schedulé 12:01 PT mar 28** ; tous les posts pré-écrits/schedulés (launch email, X thread, Show HN tenu, 2 Reddit tenus) ; warm list + créateurs notifiés ; **Go/No-Go ven 24** | PH listing en draft complet ; kit finalisé ; offre live & testée |
| **Launch** | lun 27 juil – dim 2 août | Lancement (PH → HN → Reddit) | T-1 teaser ; **mar 28 = PH 12:01 PT** ; **mer 29 = Show HN** ; **jeu 30 = Reddit r/macapps + r/ClaudeAI** ; ven 31 follow-up + email "we launched" + conversion Founder | Tous les gates §3 verts → **GO** |

*Suite après juillet (T+1→T+8) : voir §6.*

---

## 3. Calendrier jour par jour (1–31 juillet)

Légende canaux : **X** · **Reddit/HN/Lobsters/Discord** (communautés) · **Blog** · **Email** · **LinkedIn** · **BUILD** (chantier founder) · **JALON**.

### Semaine T-4 (tail) — mer 1 → dim 5 juil · *Fondations & correctif funnel*

**Chantiers founder (build/prep) — `→ 06` (gates pré-lancement) :**
- Fermer le gap copy `website/app/api/try/route.ts` "10,000 words" → aligner sur **33 dictations** ; deploy + vérifier live (**bloqueur #1**).
- Auditer chaque surface publique pour le claim privacy ; retirer tout "written to disk".
- Test activation à froid sur Mac propre : 1re dictation **<60 s** (zéro-clé Claude Code + fallback Parakeet).
- Test 1re action confirmée à froid (connecter 1 app → dicter → plan → confirm → exécute).
- Lever l'instrumentation funnel end-to-end (download → activate → action → paywall → trial → paid → referral).
- **[PRÉREQUIS : SKU Stripe à créer/tester]** Construire le **SKU Stripe Founder license** + achat test + entitlement honoré in-app + attribution `?ref` intacte. `→ 07` (économie du tier) / `→ 06` (gate).

| Date | Jour | Canal | Pièce (titre + 1 ligne) | Réf |
|---|---|---|---|---|
| 1 juil | mercredi | X | Hook one-liner — *"I think faster than I type. So I stopped typing."* (P1, présence légère) | `→ 01` |
| 2 juil | jeudi | X | Hook one-liner — *"Have Claude Code? You can dictate all day with no API key and no extra AI bill."* (P3) | `→ 01` |
| 3 juil | vendredi | X | Build-in-public note #seed — *"fixing the funnel before I launch"* (voix founder, honnête) | `→ 01` |
| 4 juil | samedi | — | *Léger / repos.* BUILD : test 1re action confirmée à froid | `→ 06` |
| 5 juil | dimanche | — | *Léger / repos.* BUILD : SKU Founder + instrumentation ; planifier T-3 | `→ 06`,`→ 07` |

### Semaine T-3 — lun 6 → dim 12 juil · *Assets & preuve*

**Chantiers founder :**
- **Enregistrer la démo canonique JARVIS 60 s** (speak-vs-type → action réelle, étape confirm visible) + **3-4 cutdowns 15 s** (Linear / Gmail / Slack / Calendar). `→ 01` (script Angle 1) / `→ 06` (galerie PH).
- Publier les 2 posts blog fondation + rafraîchir 3 `/vs` et vérifier la matrice `/compare` 24×10. `→ ../content-strategy.md` §5/§2.
- Démarrer le **seeding alpha** : confier le build à 10-20 testeurs de confiance ; demander une quote honnête d'une ligne + permission. `→ 07`.
- Drafter le **kit de lancement** (PH tagline/description/maker comment, HN titre+body, Reddit, X thread). `→ 06`.

| Date | Jour | Canal | Pièce (titre + 1 ligne) | Réf |
|---|---|---|---|---|
| 6 juil | lundi | X · BUILD | **Asset day** — enregistrer démo 60 s + cutdowns. X : build-in-public note *"recording the demo that launches in 3 weeks"* | `→ 01`,`→ 06` |
| 7 juil | mardi | Blog · X | Blog **[#2]** *"Use your Claude Code sub for dictation — no API key"*. X : Angle 4 single tweet (BYO-Claude, dev-natif) | `→ ../content-strategy.md`, `→ 01` |
| 8 juil | mercredi | **Communauté** · X | **r/ClaudeAI** PSA — *"you can use your existing Claude Code sub for Mac dictation — no API key, no extra cost"* (Angle 4 variant). X : cutdown 15 s (action Linear) | `→ 02`,`→ 01` |
| 9 juil | jeudi | Blog · X | Blog **[#1]** *"Best Mac dictation app 2026 (honest comparison)"* + refresh 3 `/vs`. X : Angle 5 thread *"I stopped typing prompts to Claude Code. I talk them now."* | `→ ../content-strategy.md`, `→ 01` |
| 10 juil | vendredi | X | Begin seeding alpha (collecte quotes). X : build-in-public note #2 *"how I built it paranoid"* (Angle 6, confiance) | `→ 07`,`→ 01` |
| 11 juil | samedi | — | *Léger.* Desk task : drafter le kit de lancement (PH/HN/Reddit/X thread) | `→ 06` |
| 12 juil | dimanche | — | *Léger / repos.* Collecter les quotes alpha ; planifier T-2 | `→ 07` |

### Semaine T-2 — lun 13 → dim 19 juil · *Warm-up communautés & seeding créateurs*

**Chantiers founder :**
- Démarrer la **cadence build-in-public X** : *"shipping a voice agent for the Mac, launching in 2 weeks"* — montrer la démo + l'étape confirm, inviter à suivre. `→ 01`.
- **Seed 10-20 créateurs** dev/Mac/productivité (Founder license + clip démo, pas d'ask payant). `→ 07` (Séquence A).
- Être présent dans les communautés beachhead **en apportant de la valeur, pas en pitchant** (r/macapps, r/ClaudeAI, Lobsters, Discords Cursor/Claude). `→ 02`.
- Aligner une **warm list** d'acheteurs Founder à convertir en heure 1. `→ 07`.
- Email teaser à la liste existante : *"something big from Verba in 2 weeks"*. `→ 04`.

| Date | Jour | Canal | Pièce (titre + 1 ligne) | Réf |
|---|---|---|---|---|
| 13 juil | lundi | X | **Build-in-public thread** (Angle 6, 7 tweets) — *"a Mac dictation app that became a voice agent… built it paranoid"* | `→ 01` |
| 14 juil | mardi | X | Seed créateurs (license + clip). X : cutdown 15 s (action Gmail) | `→ 07`,`→ 01` |
| 15 juil | mercredi | **Communauté** | **r/macapps** — Angle 7 thread *"Honest Verba vs Wispr Flow — including where Wispr beats us"* (mener avec la démo). Rester 2 h dans les commentaires | `→ 02` |
| 16 juil | jeudi | Email · X | **Email teaser** *"something big from Verba in 2 weeks"*. X : Angle 14 single tweet + clip 15 s (stacked dictations, dev-natif) | `→ 04`,`→ 01` |
| 17 juil | vendredi | Communauté · X | Présence valeur-d'abord (répondre aux Q dictée/voix sur r/macapps, r/ClaudeAI, Lobsters, Discords). X : hook one-liner / build-in-public note | `→ 02`,`→ 01` |
| 18 juil | samedi | — | *Léger.* Aligner la warm list Founder-license | `→ 07` |
| 19 juil | dimanche | — | *Léger / repos.* Relances créateurs ; planifier T-1 | `→ 07` |

### Semaine T-1 — lun 20 → dim 26 juil · *Répétition & scheduling*

**Chantiers founder :**
- Revue finale **PH listing** : tagline ≤60 chars, ordre galerie (video first → image confirm JARVIS → modes → /compare → privacy → pricing+Founder), topics, maker comment, offer. `→ 06`.
- **Scheduler le lancement PH pour 12:01 am PT mar 28 juil.** `→ 06`.
- Pré-écrire & scheduler : launch email, X launch thread, le post Show HN (tenu, pas publié), les 2 posts Reddit (tenus). `→ 04`,`→ 06`,`→ 01`,`→ 02`.
- Notifier warm list + créateurs (date/heure exactes ; demander un engagement **authentique**, jamais "upvote" — PH interdit la manipulation de votes). `→ 07`.
- **Go/No-Go (ven 24 juil)** : tous les gates §3 verts → GO. Inclut **SKU Founder live & testé** = condition pour publier la ligne `$149`. Smoke test final golden path à froid + action JARVIS confirmée. `→ 06`.

| Date | Jour | Canal | Pièce (titre + 1 ligne) | Réf |
|---|---|---|---|---|
| 20 juil | lundi | X | Revue finale PH listing. X : build-in-public note *"launching next week"* | `→ 06`,`→ 01` |
| 21 juil | mardi | X | Pré-écrire & scheduler launch email + X thread + Show HN (tenu) + 2 Reddit (tenus). X : cutdown 15 s (action Calendar) | `→ 04`,`→ 06`,`→ 01` |
| 22 juil | mercredi | **Communauté** | **Lobsters / Discord Cursor-Claude** — Angle 5 (speak-vs-type) en valeur-d'abord. Notifier warm list + créateurs (engagement authentique) | `→ 02`,`→ 07` |
| 23 juil | jeudi | X · JALON | **Scheduler PH 12:01 PT mar 28**. X : teaser démo flagship 60 s *"this is what launches Tuesday"* (Angle 1) | `→ 06`,`→ 01` |
| 24 juil | vendredi | **JALON — GO/NO-GO** | Tous les gates verts → GO. Confirmer couverture support jour-J. Smoke test final (golden path + action confirmée). X : build-in-public note | `→ 06`,`→ 01` |
| 25 juil | samedi | — | *Léger / repos avant launch week.* Hook one-liner optionnel | `→ 01` |
| 26 juil | dimanche | — | *Léger / repos.* Check final des assets ; pré-stage ; couché tôt | `→ 06` |

### Launch week — lun 27 → ven 31 juil · *PH → Show HN → Reddit*

| Date | Jour | Canal | Pièce (titre + 1 ligne) | Réf |
|---|---|---|---|---|
| 27 juil | lundi (T-1 day) | X | Check final assets ; pré-stage tous les posts ; nuit courte. **X teaser** *"tomorrow"* | `→ 01`,`→ 06` |
| **28 juil** | **mardi — T-0 LANCEMENT** | **PH · X · Email · all-day** | **Product Hunt live 12:01 am PT.** Maker first comment (12:01) ; X launch thread + pin (12:05) ; launch email (12:05) ; ping warm list (12:10) ; répondre à 100 % des commentaires ; cutdown 15 s à midi. **Runbook H-par-H → §4.** | `→ 06`,`→ 04`,`→ 01` |
| **29 juil** | **mercredi — T+1** | **Hacker News · X** | **Show HN live** (~13:00–16:00 UTC / matin PT). Titre : *"Show HN: Verba – Mac dictation that acts on what you say, using your own Claude"*. Répondre à chaque commentaire HN ; continuer les thank-yous PH | `→ 06`,`→ 02`,`→ 01` |
| **30 juil** | **jeudi — T+2** | **Reddit · X** | **r/macapps** *"I built a private Mac dictation app that can also act on what you say…"* puis **r/ClaudeAI** (qq h plus tard) *"Verba uses your Claude Code subscription to dictate and to run actions on your Mac — no API key"*. Mener avec la démo. X : launch recap | `→ 02`,`→ 01` |
| 31 juil | vendredi | **Email · X · LinkedIn (opt.)** | Follow-up avec tous ceux qui ont engagé ; **email "we launched"** à la liste complète ; convertir l'intérêt Founder-license. **(Optionnel)** 1er post LinkedIn Expand (privacy/notes) — *seulement si le beachhead est déjà engagé*, sinon tenir jusqu'en août | `→ 04`,`→ 07`,`→ 03` |

---

## 4. Jour-J — runbook heure par heure (mardi 28 juil · tous horaires PT, l'horloge de PH)

*Résumé. Détail complet + scripts dans `→ 06`. La journée PH court 12:01 am → 11:59 pm PT ; l'engagement des premières heures fixe le classement → traiter ça comme un événement toute la journée.*

| Heure (PT) | Action |
|---|---|
| **12:01 am** | PH listing live. Poster le **maker's first comment** immédiatement. |
| **12:05 am** | Poster le **X launch thread** ; l'épingler. Envoyer le **launch email** à toute la liste. |
| **12:10 am** | Pinger la **warm list + créateurs seedés** : *"we're live — would love your honest take"* (engagement authentique, jamais "upvote"). |
| **6:00 am** | Réveil / check ranking + commentaires. Répondre à **chaque** commentaire PH. Convertir les 1ers acheteurs **Founder-license** pour montrer la traction. |
| **6:00–9:00 am** | Pic trafic US-matin. Répondre en minutes partout. Re-partager le X thread avec un update de traction. |
| **9:00 am** | 1er pouls métriques. Update *"we're #X on PH"* sur X si le ranking est fort. |
| **12:00 pm** | Push midi : nouveau cutdown 15 s JARVIS sur X ; remercier les early supporters par leur nom ; répondre publiquement aux objections dures (agent-trust, Mac-only). |
| **3:00 pm** | EU endormie, US après-midi actif — continuer. Sortir l'angle *"you're paying twice for AI — the math"* si la conversation ralentit. |
| **6:00 pm** | Pouls du soir ; engager les browsers PH de fin de journée + les retardataires EU-soir. |
| **9:00 pm** | Dernier push avant minuit PT si en lice pour le top. Last call du jour sur le tier Founder. |
| **11:59 pm** | Clôture. Screenshot rank + stats finales. Préparer la liste de thank-you pour demain. |

**Tenu pour le lendemain (délibéré)** : Show HN (mer matin), r/macapps + r/ClaudeAI (jeu) — étalés pour que chaque spike ait toute l'attention.

**Métriques à surveiller** (`→ 06` / GTM §9) : rank/upvotes/comments PH, downloads DMG, sessions site, captures email · % download→1re dictation, time-to-first-dictation (<60 s), time-to-first-confirmed-action · paywall hits, trials 7 j, **ventes Founder-license**, checkouts monthly/annual · referral links, leaderboard shares · **garde-fou : taux d'erreur 1re dictation + 1re action JARVIS** (un first-run cassé le jour-J est le pire résultat).

---

## 5. Cadence & règles de publication (rappel opérationnel)

- **Rythme** : ~1 post X/jour (rotation : démo clip → build-in-public → hook one-liner → reply dans threads dev) ; build-in-public **2×/sem** ; **1 communauté/sem** (rotation r/macapps → r/ClaudeAI → Lobsters → Discord) ; **Show HN sur le vrai milestone** (28-29 juil) ; LinkedIn **fortnightly**, Expand seulement après le beachhead. Week-ends **légers** (repos + monitoring).
- **Timing** : X dev = **14:00–17:00 UTC** (matin US) + **~21:00 UTC**. Show HN = **13:00–16:00 UTC** en semaine. **Rester dans les commentaires les 2 premières heures** (signal de ranking + de confiance) — ne jamais poster une communauté puis disparaître.
- **Étiquette communautés** (`→ 02`) : mener avec la démo/le build, jamais le pitch ; se déclarer founder ; être honnête sur les limites (Mac-only, indie, pas de testimonials au début) ; un seul ask, soft ; jamais de faux (no iOS, no write non-confirmé, no nom de fournisseur interne).
- **Réutilisation** : la démo 60 s est l'actif parent → 1 séance d'enregistrement par mode = ~30 posts (matrice de repurposing, `../social-content.md`). Garder l'end-card *"Verba · verba.run · Mac · $9.99"*.
- **Pub payante (`→ 05`) = OFF en juillet.** Le payant est le **dernier** moteur, seulement **après que l'organique prouve la conversion** (activation <60 s + une seule histoire 33-dictations). Démarrage post-lancement en **retargeting** (visiteurs /compare + /vs), pas pendant le runway. Voir §6.

---

## 6. Et après juillet (T+1 → T+8 · août–sept)

*Le lancement est l'**ignition**, pas la destination. Détail dans `../launch-strategy.md` §4 (T+1→T+8) + §7 (compounding).*

- **T+1→T+2 (lun 3 → dim 16 août) — capter le spike dans les boucles owned :** flip ON des share prompts in-app (referral "Free Month", leaderboard *"I saved 14 hours"*, gamification — `→ 01` Angle 11) ; **séquence email onboarding** active pour chaque install (`→ 04`) ; post build-in-public *"what launch day looked like"* (vrais chiffres) ; relancer les créateurs seedés. **Premier post LinkedIn Expand** ici si pas fait le 31 (`→ 03`).
- **T+3→T+5 (lun 17 août → dim 6 sept) — contenu compounding + vague créateurs :** publier le set content-strategy semaines 5-8 — *"Dictate prompts to Claude Code / Cursor (hub)"* [#3], *"Wispr Flow alternatives that run offline"* [#4], *"You're paying twice for AI — the math"* [#5], *"I ran my morning by voice"* [#11] ; how-tos per-app JARVIS [#12] ; les démos créateurs sortent (le multiplicateur). **Démarrage pub payante (`→ 05`)** une fois un angle retargeting au CPA soutenable.
- **T+6→T+8 (lun 7 → dim 27 sept) — élargir & préparer Phase 2 :** séquençage segments Expand (Privacy-first pros → Voice-first operators, **messaging only**) sur LinkedIn (`→ 03`) ; trust explainer [#13] ; évaluer un **2e launch moment** ; décision retargeting payant sur visiteurs /compare.

---

**--- Resume :** `00-calendrier-editorial-juillet-2026.md` écrit — colonne vertébrale du dossier `content-juillet-2026/`. En-tête (narratif unique + 3 piliers + règle dev-beachhead + garde-fous Lifetime/no-feature-inventée) ; vue hebdo T-4→Launch (objectif + livrables + gate par semaine) ; calendrier **jour par jour 1-31 juillet** (date + jour FR + canal + pièce EN verbatim + renvoi fichier 01-07) ; jalons marqués (**mar 28 PH 12:01 PT**, **mer 29 Show HN**, **jeu 30 Reddit**) ; runbook heure-par-heure du jour-J (résumé, détail en `06`) ; cadence solo-founder + timing UTC ; suite T+1→T+8 (août-sept) avec pub payante `05` correctement **OFF en juillet**. Tier `$149` partout flaggé **[PRÉREQUIS SKU Stripe]** et conditionné au Go/No-Go du 24 juil.
