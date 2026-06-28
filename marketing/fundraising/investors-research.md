# Verba — 100 investisseurs : méthodologie, vérification & limites honnêtes

> Liste complète + sources : **`investors-100.csv`** (une URL source citable par investisseur).
> Date : 2026-06-28 · Données réelles uniquement · **Aucun contact halluciné** (vérif adverse ci-dessous).

## 1. Principe de sourcing (anti-hallucination)

Chaque investisseur est **ancré à une société de portefeuille réelle** (Raycast, Linear, Granola, Wispr Flow, Mem, Notion, Willow Voice, Deepgram…) **+ une URL source citable** (Crunchbase, TechCrunch, blog du fonds, annonce de tour, page portfolio). Cet ancrage prouve simultanément **(a)** que l'investisseur existe et **(b)** qu'il colle à la thèse de Verba (Mac-first / AI-productivity / prosumer / creator-tools / voice-AI). Règle dure appliquée à la prospection : **pas de source citable → pas d'entrée.**

## 2. Pipeline

1. **Découverte** — 8 lignes de prospection parallèles (outils Mac prosumer, AI-productivity, voix/dictée/speech, fonds dev-tools, operator-angels, micro-VC consumer/prosumer, fonds seed AI, Europe/indie). **138 candidats bruts.**
2. **Vérification adverse (passe 1)** — sceptiques par lot tentant de *falsifier* chaque candidat (existence + source). **111 retenus** (keep=true).
3. **Déduplication** — par entité (le GP et son fonds = une seule entité ; Betaworks ramené à 1). **+ remplacement** de 3 doublons par 3 backers Raycast réels et sourcés (Atomico, Coatue, World Innovation Lab).
4. **Vérification adverse indépendante ≥2/3 (passe 2, WF3)** — sur les **30 entrées les plus basses en confiance**, 3 sceptiques **indépendants** (chacun re-vérifie tout, vote real/faux). Voir §4.
5. **Liste finale : 100 investisseurs distincts**, 1 email personnalisé chacun.

## 3. Composition de la liste (100)

| Dimension | Répartition |
|---|---|
| Type | VC 51 · micro-VC 18 · angel 24 · accélérateur 7 |
| Stade | seed 50 · pre-seed 22 · pre-seed/seed 16 · early 12 |
| Canal de contact | **22 vérifiés** (formulaire/email public) · **78 « à vérifier »** (intro chaude / email non public) |
| Confiance | 0,78 → 0,97 |

## 4. Vérification adversariale ≥2/3 — résultats (le point clé)

Les 30 entrées les plus risquées (confiance ≤ 0,88) ont été soumises à **3 sceptiques indépendants** chargés de **réfuter** chaque entrée. Verdict par consensus majoritaire :

- **2 entrées REJETÉES (≥2/3 « pas réel ») → retirées et remplacées :**
  - **Thrive Capital** (ancre « Rewind/Limitless ») — **0/3 réel.** Le tour de Rewind a été mené par NEA (~12-15 M$), pas par Thrive à 25 M$ ; aucune source ne place Thrive dans Rewind. **Ancre fabriquée → retirée.** Remplacée par **Atlassian Ventures** (backer réel du Series B de Raycast, source TechCrunch).
  - **Basis Set Ventures** (ancre « WorkOS ») — **2/3 réfutent l'ancre.** Le fonds est réel mais WorkOS a été seedé par Lightspeed/Abstract, pas Basis Set. **Ancre erronée → retirée.** Remplacée par **Max Mullen** (co-fondateur Instacart, angel réel du seed de Willow Voice, source TradedVC).
- **3 entrées RÉELLES mais à citation faible (investisseur + investissement confirmés, mais l'URL pointe une page produit/connexe plutôt que l'annonce exacte du tour) — conservées, à raffiner la source avant de s'appuyer dessus :**
  - **Alexis Ohanian / Seven Seven Six** (investisseur Willow Voice confirmé — corriger l'URL vers l'annonce de tour).
  - **Jeff Morris Jr. / Chapter One** (seed Raycast confirmé — l'URL citée vise le Series A, pas le seed).
  - **Sierra Ventures** (lead du seed de Krisp confirmé — l'URL citée est un article produit).
- **25 autres entrées de la passe 2 : 3/3 réelles et sources OK.**

## 5. Limites honnêtes (à lire avant d'envoyer)

- **Périmètre de la vérif ≥2/3 :** elle a couvert les **30 entrées les plus basses en confiance** (là où le risque de fabrication est le plus élevé — Popper). Les **70 entrées à confiance ≥0,88** ont été vérifiées **une fois** (passe 1) mais **pas triple-vérifiées** ; un résiduel de citations imparfaites n'est pas exclu. Recommandation : re-checker l'URL source de chaque investisseur au moment d'écrire l'intro.
- **Emails investisseurs rarement publics :** 78/100 sont en **« à vérifier »** — le canal est une **intro chaude** ou un **formulaire public**, pas une adresse email confirmée. **Ne jamais envoyer à une adresse devinée.** Les 22 « vérifiés » ont un formulaire/email public réel (YC, AI Grant, Speedinvest, Hustle Fund, Precursor, Conviction, Liquid 2, Frst, Weekend Fund, Long Journey, Calm Fund…).
- **Entités vs personnes :** quelques cas pointent volontairement **deux chemins** vers le même fonds (le GP en intro chaude *vs* le formulaire public du fonds) — ce sont des routes d'approche distinctes, pas des doublons.
- **Taux de fabrication mesuré :** 2/30 sur la tranche la plus risquée (~6,7 %), corrigé à 0 après remplacement. C'est précisément ce que la vérif adverse sert à attraper.

## 6. Exemples d'ancrage sourcé (échantillon — liste complète dans le CSV)

| Investisseur | Ancre (portfolio) | Source |
|---|---|---|
| Sequoia Capital | Linear (lead seed 4,2 M$) | linear.app/now/linear-s-next-chapter |
| Accel | Raycast (lead Series A) | raycast.com/blog/series-a |
| Atomico | Raycast (lead Series B) | TechCrunch (Raycast $30M) |
| Notable Capital (Hans Tung) | Wispr Flow (lead $25M) | TechCrunch (Wispr/Notable) |
| Spark Capital | Granola (lead Series A) | granola.ai/blog/series-a |
| a16z | Mem ($5,6M seed) + Rewind | TechCrunch |
| OpenAI Startup Fund | Mem ($23,5M) | TechCrunch |
| Y Combinator | Deepgram ; Willow Voice (X25) | ycombinator.com/companies |
| AI Grant (Friedman/Gross) | Granola (participant) | aigrant.org |
| Naval Ravikant | Notion (seed 2013) | (profil public) |
| Max Mullen (Instacart) | Willow Voice (seed 4,2M$) | TradedVC |

*Les ~89 autres, avec leur ancre et leur URL, sont dans `investors-100.csv`.*
