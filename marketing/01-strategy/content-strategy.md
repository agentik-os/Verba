---
project: Verba
layer: strategy
produced_by: content-strategy (/omg-content-strategy)
status: filled
reconciles_with: ../content-strategy.md (13 Ko riche) + ../content-juillet-2026/ (pack exécution juillet)
feeds: ../../04-publishing/calendar.json
---
# Content Strategy, Verba

> **Source riche = `../content-strategy.md`** (5 piliers détaillés, clusters hub→spoke, keyword map par étape) +
> **`../content-juillet-2026/`** (pack d'exécution juillet, ~42k mots, prêt-à-publier). Ce fichier consolide + alimente `04-publishing/calendar.json`.
> **Objectif du contenu :** capter la demande high-intent (searchable) ET créer la demande par 3 idées (shareable) :
> *« ta voix ne devrait pas quitter ton Mac », « arrête de payer deux fois l'IA que tu as déjà », « ta voix devrait* agir *».*

## Content pillars (les 5 sujets que Verba possède)
| # | Pilier | Possède | S/Sh | Lien produit |
|---|---|---|---|---|
| **P1** | **Voice-driven coding** (le wedge) | « dicter à ton agent IA de code / Cursor », vibe-coding vocal | Both | Coding mode + s'intègre à ton setup IA existant, en privé |
| **P2** | **Dictée privée on-device** | « local voice-to-text Mac », « mon app upload-t-elle mon audio ? » | Searchable | Modèles privés on-device, audio jamais uploadé, Keychain |
| **P3** | **Private AI / low-cost** | « garder mon IA privée sans rien changer à mon setup », « stop AI markups » | Shareable | Architecture privée : s'intègre à ton setup IA existant, coût marginal très faible |
| **P4** | **Best Mac dictation / comparatifs** | « Wispr alternative », « X vs Y », « best Mac dictation 2026 » | Searchable (BOFU) | `/compare` (24×10) + `/vs/[slug]`, **déjà bâti** |
| **P5** | **Voice → action / « Jarvis for Mac »** | « voice assistant that does things », « create Linear issue by voice » | Shareable + search émergent | JARVIS : plan on-device → confirm → exécute 1 000+ apps |
> Piliers **1, 3, 5 = catégorie-d'un** (aucun concurrent ne peut les écrire crédiblement), sur-indexer. P4 = actif shippé (**étendre, pas rebâtir**). P2 = base evergreen la plus large. P5 = marché de recherche le plus jeune, gagner par les démos, posséder le vocabulaire tôt.

## Topic clusters (searchable + shareable)
- **P1 hub :** « How to code by voice with AI (the 2026 setup) » → spokes : dictate prompts to your AI coding agent · voice-to-text for Cursor · 20-min ramble → clean PR · hands-free coding · *(shareable)* « I dictated for a week instead of typing ».
- **P2 hub :** « Private voice-to-text on the Mac: the complete guide » → does [Wispr/Otter/Aqua] upload your audio · offline dictation · dictation for lawyers/doctors/journalists · where apps store audio+keys (angle Superwhisper-disk).
- **P3 hub :** « Private AI, your terms: why paying a markup on dictation makes no sense » → *(shareable)* « Privacy shouldn't cost extra. Here's the math. » · extend your existing AI setup, privately, no extra step · run fully local, on-device only.
- **P4 :** étendre `/vs/[slug]` + `/compare` ; « best Mac dictation app 2026 ».
- **P5 hub :** « Jarvis for Mac: voice → action, explained » → démos (« create the Linear issue by voice ») · confirm-gated safety · 1 000+ connected apps.

## Channel mix & cadence (plateformes zernio, fréquence)
| Plateforme | Rôle | Cadence cible |
|---|---|---|
| **X/Twitter** | Build-in-public, démos JARVIS, hooks | ~4-6 / sem (quotidien en runway lancement) |
| **Reddit / HN / Lobsters** | Communautés dev/Mac (démo, jamais pitch) | 1-2 posts à fort signal / sem, étiquette stricte |
| **LinkedIn** | Privacy + opérateurs voice-first (après beachhead) | 2-3 / sem |
| **Blog/SEO (verba.run)** | Hubs + spokes composables (Engine A) | 1 hub ou 2 spokes / sem |
| **YouTube/Instagram/TikTok** | Démos before/after, « speak-vs-type », Translate | 1-2 short / sem |
| **Product Hunt** | Moment de lancement | 1 (28 juil 2026) |
> Détail jour-par-jour : `../content-juillet-2026/00-calendrier-editorial-juillet-2026.md` (runway T-4→T+8).

## Editorial calendar (→ 04-publishing/calendar.json)
≥10 stubs amorcés dans `../../04-publishing/calendar.json`, dérivés des 5 piliers + du pack juillet. `scheduledFor: null` (l'opérateur planifie après validation + connexion des comptes).

## Repurposing engine (1 hero → N derivatives)
**1 démo JARVIS de 60 s →** thread X (hook+steps) · Short YouTube/TikTok/Reels · post LinkedIn (angle opérateur) · post Reddit r/macapps (démo, pas pitch) · GIF pour `/compare` · section blog du hub P5 · email lifecycle. *(matrice 1-demo→~30-posts détaillée dans `../social-content.md` + `../content-juillet-2026/01-social-x-build-in-public.md`.)*

## KPIs per pillar
- **P1/P3 (catégorie-d'un) :** engagement + saves/shares (demande créée), trafic → essai.
- **P2 :** classements SEO sur requêtes privacy, trafic organique composé.
- **P4 :** position sur « X alternative » / « best Mac dictation », download→paid depuis `/vs` & `/compare` (BOFU).
- **P5 :** vues de démo, signups attribués aux démos, part de voix sur « Jarvis for Mac ».
- **Global :** download → activation (1re dictée) → paywall → trial → payant (le north-star funnel).
