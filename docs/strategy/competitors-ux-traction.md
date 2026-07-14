# Concurrents de Verba : UX perçue, reviews et traction

> **Date de l'étude** : 2026-07-14
> **Périmètre** : Wispr Flow, Superwhisper, MacWhisper, VoiceInk, Aqua Voice, Willow Voice, Otter.ai, plus les acteurs sérieux découverts en route (Monologue, Typeless, Handy, Spokenly, Talon).
> **Méthode** : agrégation de reviews (App Store, Product Hunt, G2, Trustpilot, Reddit, Hacker News, presse), croisement des chiffres de traction (Crunchbase, TechCrunch, LinkedIn, communiqués). ~50 recherches et fetches, via 3 agents de recherche parallèles.

## Avertissements méthodologiques

1. **Pollution SEO concurrente** : une grande partie des « reviews 2026 » indexées (Voibe, Spokenly, Weesper, MetaWhisp, Embertype, Snailtext, OpenWhispr, LumeVoice...) est publiée par des concurrents directs qui se classent eux-mêmes n°1. Ces sources ne sont utilisées ici que pour des faits recoupables (notes de stores publiques, incidents datés, citations attribuées), et sont signalées comme « source concurrente ».
2. **Revendiqué vs vérifié** : chaque chiffre est marqué. « Vérifié » = confirmé par ≥2 sources indépendantes ou constat direct (fetch de la page). « Revendiqué » = chiffre de l'entreprise repris sans audit tiers. « Estimé » = agrégateur à méthodologie opaque (Getlatka, etc.).
3. **Limites d'accès** : Trustpilot, Medium, BBB et Product Hunt bloquent le scraping direct (403) ; certains verbatims passent par des sources secondaires. Les recherches Reddit directes étaient mal indexées : les verbatims communautaires viennent surtout de Hacker News (IDs de commentaires vérifiables) et d'un comparatif Substack indépendant.
4. Aucune des apps desktop concurrentes n'est distribuée sur le **Mac** App Store (sauf MacWhisper) : les notes « App Store » citées sont celles des apps iOS.

---

## 1. Wispr Flow (wisprflow.ai) : le leader financé, en déficit de confiance

### UX perçue

**Notes** :
- iOS App Store : **4,8/5 sur ~8 500+ notes** (vérifié). Mais dégradation récente : les 500 derniers avis (déc. 2025 → mai 2026) moyennent **4,14/5**, la tranche d'avril 2026 tombe à **3,77/5** ; pricing mentionné dans 38 % des avis récents ([analyse Filip Konecny, 2026-03-25](https://filipkonecny.com/2026/03/25/wispr-flow-ratings/), source unique pour le détail des tranches).
- **Trustpilot : 2,7/5** ([trustpilot.com/review/wisprflow.ai](https://www.trustpilot.com/review/wisprflow.ai)), anormalement bas pour un leader de catégorie.
- G2 : 4,5/5 mais ~6 avis (non significatif).
- Product Hunt : launch Windows **751 upvotes, #1 du jour** ([fiche PH](https://www.producthunt.com/products/wisprflow)).

**Top 3 adoré** :
1. Le « cleanup » IA subtil qui garde la voix de l'utilisateur (fillers supprimés sans réécriture) : LE différenciateur cité partout.
2. Polish et onboarding : « ça marche tout de suite, partout » (toutes apps, tous champs).
3. Multilingue / code-switching, et l'usage dominant : prompter les LLM à la voix.

**Top 3 détesté** :
1. **Fiabilité en dégradation** : 75+ incidents recensés entre déc. 2025 et juin 2026 (status page publique + StatusGator), dont un incident de capacité de ~6 jours (27 mai au 8 juin 2026), pannes d'auth, crashes au démarrage. Pattern récurrent dit « day-two drop » : excellent pendant le trial de 14 jours, inconsistant après paiement ([log des pannes, source concurrente s'appuyant sur la status page Wispr](https://www.getvoibe.com/resources/is-wispr-flow-reliable/)).
2. **Privacy / cloud-only** : incident viral fin 2025 : un utilisateur analysant le trafic réseau découvre que l'app uploadait des **captures d'écran de la fenêtre active toutes les quelques secondes** vers une infra IA tierce ; Wispr a d'abord banni l'utilisateur, puis le CTO s'est excusé publiquement, training passé en opt-in + Privacy Mode zéro rétention ajouté (cross-validé 3+ sources : [Embertype](https://embertype.com/blog/the-day-wispr-flow-banned-a-user/), [ModelPiper](https://modelpiper.com/blog/wispr-flow-privacy-incident), [eesel](https://www.eesel.ai/blog/wispr-flow-review)). S'ajoute le **scandale Delve (mars 2026)** : leur SOC 2 / ISO 27001 émis via Delve, accusé d'avoir fabriqué 494 rapports de compliance ([Inc.](https://www.inc.com/ben-sherry/the-delve-scandal-a-y-combinator-darling-just-got-hit-with-a-bombshell-fraud-accusation/91320652)) ; Wispr a réagi en commandant un nouvel audit A-LIGN ([billet officiel](https://wisprflow.ai/post/new-independent-audit)).
3. **Prix et ressources** : 15 $/mois (144 $/an), pas de lifetime ; consommation rapportée ~800 MB RAM et ~8 % CPU au repos (benchmarks Reddit relayés par sources concurrentes, à re-vérifier) ; freezes d'apps cibles sous Windows.

**Fiabilité perçue** : précision saluée, mais dépendance cloud totale = latence variable et pannes récurrentes à l'échelle. C'est la plainte n°1 des avis récents.

**Citations** :
- « regular outages... dictation takes ages to show » (avis App Store iOS, juin 2026, via log de fiabilité)
- « working 60% of the time » une fois abonné (Trustpilot, ~début 2026)
- « trying to rewrite what I say » au lieu de transcrire (avis App Store, mai 2026)
- Billet « [Why I Cancelled My Wispr Flow Subscription](https://medium.com/@ryanshrott/why-i-cancelled-my-wispr-flow-subscription-and-what-im-using-instead-d783433f4411) » (Medium, ~fév. 2026), qui a alimenté un thread Reddit « Wispr Flow Trust Gap ».

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Series A | 30 M$ (juin 2025, Menlo Ventures, NEA, 8VC) | Vérifié | [TechCrunch 2025-06-24](https://techcrunch.com/2025/06/24/wispr-flow-raises-30m-from-menlo-ventures-for-its-ai-powered-dictation-app/) |
| Extension A | 25 M$ (nov. 2025) ; **total levé 81 M$, valo 700 M$** | Vérifié | [TechCrunch 2025-11-20](https://techcrunch.com/2025/11/20/as-its-voice-dectation-app-takes-off-wispr-secures-25m-from-notable-capital/), [PRNewswire](https://www.prnewswire.com/news-releases/wispr-raises-25m-to-build-its-voice-operating-system-302621858.html) |
| Round en discussion | ~260 M$ à ~2 Md$ de valo (mai 2026) | **Rumeur, non confirmé** | [The Tech Portal 2026-05-12](https://thetechportal.com/2026/05/12/ai-dictation-startup-wispr-could-secure-260mn-funding-at-2bn-valuation/) |
| Croissance | 40 % MoM, 100x YoY users, 125 clients entreprise/semaine | Revendiqué | PRNewswire, [Product Growth teardown](https://www.productgrowth.blog/p/wispr-flow-growth-teardown) |
| Téléchargements | 2,5 M ; 270 sociétés du Fortune 500 | Revendiqué | [AI CERTs](https://www.aicerts.ai/news/wispr-flows-2b-voice-ai-funding-push/) |
| ARR | ~10 M$ | Estimé, source unique | [Getlatka](https://getlatka.com/companies/wisprflow.ai) |
| Effectifs | 93-94 (juin 2026), 36 postes ouverts | Vérifié (LinkedIn/LeadIQ) | [LeadIQ](https://leadiq.com/c/wispr-flow/616736d2990e636b3e733ded) |
| Communauté | Slack actif, changelog très fréquent, status page incident.io | Vérifié | [roadmap.wisprflow.ai/changelog](https://roadmap.wisprflow.ai/changelog) |

---

## 2. Superwhisper (superwhisper.com) : la référence power user, bootstrappée

Éditeur : SuperUltra, Inc. (Toronto), fondateur Neil Chudleigh (ex PartnerStack). Lancé juillet 2023.

### UX perçue

**Notes** : pas sur le Mac App Store (distribution directe). Product Hunt : launch macOS 234 upvotes, launch iOS 237, reviews PH **4,9/5 sur ~20 avis** (volume faible). Note iOS App Store « 4,4/5, 762 notes » : source unique concurrente, non recoupée.

**Top 3 adoré** :
1. Précision + rapidité perçues comme la référence de la catégorie sur Mac ; endorsements très visibles (Karpathy, Pieter Levels, Guillermo Rauch, confirmés par le [Globe and Mail](https://www.theglobeandmail.com/business/article-toronto-ai-startup-superwhisper-dictation-app/)).
2. Profondeur des « modes » : capture du texte sélectionné, du presse-papiers et du **contexte applicatif via les API d'accessibilité**, prompts IA illimités, deep links ([comparatif Substack indépendant, 2025-09-15](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac)).
3. Flexibilité local/cloud (Whisper et Parakeet on-device, BYOK cloud) + vrai free tier ; intégration Claude Code appréciée ([HN 2026](https://news.ycombinator.com/item?id=47936169)).

**Top 3 détesté** :
1. Prix le plus élevé de la catégorie hors Wispr (8,49 $/mois ou **249,99 $ lifetime**) ; grief de « double facturation » : licence + coûts API cloud non bornés en BYOK (sources concurrentes convergentes, prudence).
2. Support lent, feedback communautaire ignoré : « support's often slow, and thoughtful feedback from the community keeps getting brushed aside » ([Substack, sept. 2025](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac)) ; refontes d'UI qui cassent les workflows sans retour arrière.
3. Fiabilité inégale hors du cœur macOS : app iOS qui perd des enregistrements, port Windows mi-2026 jugé brut ; correctifs « memory leaks, speed improvements » listés au [changelog officiel](https://superwhisper.com/changelog) en 2025.

**Citations** :
- « Are there any better than Superwhisper? Because I haven't found any. » ([HN, avr. 2026](https://news.ycombinator.com/item?id=47669052))
- « macwhisper is overkill, superwhisper too clever, and handy too buggy. » ([HN, fév. 2026](https://news.ycombinator.com/item?id=47042753))
- « Superwhisper is great. It's closed source, however. » ([HN, août 2025](https://news.ycombinator.com/item?id=44768494))
- « I liked Superwhisper but switched to Willow as it was a big difference. » ([HN, juil. 2026](https://news.ycombinator.com/item?id=47896991))

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding | Aucun, bootstrapped | Vérifié presse (interview) | [Globe and Mail 2026-05-12](https://www.theglobeandmail.com/business/article-toronto-ai-startup-superwhisper-dictation-app/) |
| Revenus | « 7 chiffres USD/an, croissance rapide » | Revendiqué (fondateur), source unique | Globe and Mail |
| Effectifs | 6 salariés + 5 contractors (avr. 2026) ; 1re embauche août 2025 | Vérifié presse | Globe and Mail |
| Utilisateurs | « Centaines de milliers de WAU » ; employés Meta, OpenAI, Coinbase | Revendiqué | Globe and Mail + site |
| Releases | Quasi hebdomadaires (v2.16.2 → v2.16.4 entre le 6 et le 13 juil. 2026) | Vérifié | [changelog](https://superwhisper.com/changelog) |
| Divers | macOS + iOS + Windows, SOC 2 Type II, roadmap publique | Vérifié (site) | superwhisper.com |

---

## 3. MacWhisper (Jordi Bruin / Good Snooze) : le spécialiste transcription, dictée secondaire

Dev solo (Amsterdam, 20+ apps indie). Positionnement : **d'abord transcription de fichiers** (réunions, podcasts, batch, diarisation) ; la dictée système temps réel existe mais reste secondaire. Concurrent indirect de Verba sur la dictée, direct sur la transcription.

### UX perçue

**Notes** :
- **Mac App Store** (app « Whisper Transcription ») : **3,8/5, 151 notes** (store US, vérifié par fetch le 2026-07-14). Un « 4,3/5 sur 1 100 notes » circule (source concurrente, non recoupé).
- Gumroad : >4,5/5, 2 200+ reviews (source unique agrégateur).
- Product Hunt : 4,8/5, ~1 886 ratings ([page PH](https://www.producthunt.com/products/macwhisper/reviews), non re-vérifié, PH bloque le fetch).

**Top 3 adoré** :
1. Qualité de transcription locale excellente (Parakeet v3, Whisper Large V3 Turbo) : « the quality is excellent » (simonw, [HN 2026-07-03](https://news.ycombinator.com/item?id=48778745)).
2. Privacy totale (« never phones home ») + achat unique €59 lifetime, perçu comme l'anti-Wispr Flow.
3. Polish d'app Mac native : batch, diarisation, exports propres.

**Top 3 détesté** :
1. Fiabilité en baisse perçue en 2026 : « a buggy mess now » ; la récupération après crash **perd l'audio enregistré** : « Macwhisper is incredibly bad at [crash recovery]... taking the recorded audio with them » ([HN 2026-06-14](https://news.ycombinator.com/item?id=48533220)).
2. Pricing Pro jugé premium et confus sur le MAS (IAP de 6,99 $ à 89,99 $ + abonnements « Assistant ») : « MacWhisper Pro option is crazy... priced with a premium » ([HN 2026-06-14](https://news.ycombinator.com/item?id=48529911)).
3. Dictée temps réel basique face à Superwhisper/VoiceInk (pas de modes IA contextuels) ; consommation disque des WAV ; CPU idle élevé (corrigé en v14.1 selon les [release notes](https://macwhisper-site.vercel.app/release_notes.html)).

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding | Aucun (indie) | Recoupé (2 sources secondaires) | [benable](https://benable.com/passive_income/jordi-bruin-the-indie-developer-building-passive-income) |
| Effectifs | Dev solo | Vérifié | Multiples |
| Téléchargements | 250 000+ (mai 2024) ; « ~300 000 copies » (2025) | Revendiqué par le dev | [Tweet Jordi Bruin 2024-05](https://x.com/jordibruin/status/1796547707194216579) |
| Revenus | « 1,9 M$ » (agrégateur Gumroad non officiel) | **Douteux, source unique** | [profitable.app](https://profitable.app/gumroad) |
| Releases | Soutenues (v13.23 → v14.1 mi-2026) | Vérifié (versions) | [release notes](https://macwhisper-site.vercel.app/release_notes.html) |
| Communauté | Pas de Discord trouvé ; X actif (@jordibruin) | Non trouvé (Discord) | [X](https://x.com/jordibruin) |

---

## 4. VoiceInk (tryvoiceink.com) : l'open-source lifetime, solo dev

Dev solo : Prakash Joshi Pax (« Beingpax »). Open-sourcé février 2025, GPL v3.

### UX perçue

**Notes** : absent du Mac App Store et de Product Hunt (launch non trouvé). « 4.9 average rating » : revendiqué par le site lui-même, source unique.

**Top 3 adoré** :
1. Rapport valeur/prix : ~80 % des fonctions de Superwhisper pour **25-49 $ lifetime**, ou gratuit en compilant soi-même ; positionnement explicite « The best open-source alternative to Superwhisper & Wispr Flow » ([GitHub](https://github.com/Beingpax/VoiceInk)).
2. Qualité locale : « It's like night and day comparing Apple's to VoiceInk » ([HN 2026-05-19](https://news.ycombinator.com/item?id=48195801)) ; « flawless for all the languages » ([HN](https://news.ycombinator.com/item?id=44226097)).
3. Dev réactif et transparent ; réglages avancés, reprocessing de l'historique, Power Modes par app ([Substack sept. 2025](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac)).

**Top 3 détesté** :
1. **Contexte limité : screenshot + OCR** au lieu des API d'accessibilité, « very limiting compared to Superwhisper's full text access » (Substack).
2. Friction de workflow : enregistrement et changement de mode couplés, max 10 raccourcis, terminologie confuse, courbe d'apprentissage technique.
3. Risque de pérennité : « lifetime updates » adossé à un solo dev ; le repo **n'accepte pas les pull requests** (vérifié sur le README le 2026-07-14), open-source sans communauté de contribution ; exige macOS 14.4+.

**Nuance** : une partie des mentions HN positives provient d'un même commentateur récurrent ; sentiment globalement positif mais échantillon plus mince que les autres.

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding | Aucun (solo, licences) | Vérifié | GitHub / site |
| GitHub | **5 500 stars, 788 forks** (2026-07-14) | Vérifié (fetch) | [GitHub](https://github.com/Beingpax/VoiceInk) |
| Téléchargements | 200 000+ ; « 5 696+ users » (≈ licences ?) | Revendiqué, source unique | [tryvoiceink.com](https://tryvoiceink.com) |
| Pricing | 25 $ / 39 $ / 49 $ / 159 $ (Startup 10 Macs), lifetime | Vérifié (fetch) | tryvoiceink.com |
| Releases | Soutenues : v1.79 (mai 2026), v2.0 en beta (juin 2026, refonte Modes) | Vérifié | [GitHub releases](https://github.com/Beingpax/VoiceInk/releases) |
| Revenus | Non trouvé | Non trouvé | - |

---

## 5. Aqua Voice (withaqua.com / aquavoice.com, YC W24) : le produit-culte des devs, micro-traction

### UX perçue

**Notes** :
- Product Hunt : **505 upvotes, #2 Product of the Day** (avril 2025), 5,0/5 sur 14 avis ([fiche PH](https://www.producthunt.com/products/aqua)).
- Show HN « Aqua Voice 2 » : 140 points, 83 commentaires ([thread](https://news.ycombinator.com/item?id=43634005)).
- iOS App Store : 4,38/5 sur 52 notes (app lancée avril 2026) ([App Store](https://apps.apple.com/us/app/aqua-voice-ai-voice-keyboard/id6759074969)).
- Presse très favorable : 9to5Mac deux fois ([2025-08-15](https://9to5mac.com/2025/08/15/aqua-voice-shows-just-how-good-mac-dictation-could-be-if-apple-just-tried/) : « shows just how good Mac dictation could be » ; [2026-04-17](https://9to5mac.com/2026/04/17/aqua-voice-the-best-dictation-app-ive-ever-used-is-now-available-on-iphone/) : « the best dictation app I've ever used »).
- G2/Trustpilot : non trouvés. Reddit : couverture mince.

**Top 3 adoré** :
1. **Latence** : démarrage <50 ms, insertion ~1 s, l'argument central du launch, confirmé sur HN.
2. **Précision sur vocabulaire technique/code** : modèle propriétaire Avalon, revendiqué 97,4 % sur les termes clés d'AISpeak-10 vs 65,1 % pour Whisper Large v3, #1 des modèles propriétaires sur le leaderboard OpenASR ([blog Avalon](https://aquavoice.com/blog/introducing-avalon), classement vérifiable publiquement).
3. « Ça marche partout », terminal et Cursor compris ; plébiscité par les devs et la communauté accessibilité (dyslexie).

**Top 3 détesté** :
1. **Cloud-only, aucun mode local à aucun tier** : LA critique dominante du thread HN. Pas d'architecture local-first ; la politique ne précise pas si les transcripts entraînent Avalon.
2. **Free tier famélique : 1 000 mots à vie** (~8 minutes de parole), pas par mois (sources concurrentes cohérentes entre elles).
3. Commandes d'édition vocale laborieuses ; abonnement obligatoire (8 $/mois annualisé), pas de lifetime.

**Citations (HN, avril 2025, [thread](https://news.ycombinator.com/item?id=43634005))** :
- « C'est ce qu'Apple Intelligence pourrait être... tellement meilleur » (idk1, traduit)
- « Pas de confidentialité, pas de local = non-starter » (fxtentacle, traduit)
- « J'ai abandonné Dragon pour Windows... ne gâchez pas ça » (rickydroll, ex-utilisateur Dragon, traduit)

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding | **500 K$ pre-seed** (fév. 2024, YC W24 + Pioneer Fund, 1517 Fund) ; aucun round ultérieur trouvé | Vérifié | [Crunchbase](https://www.crunchbase.com/organization/aqua-voice), [YC](https://www.ycombinator.com/companies/aqua-voice) |
| ARR | ~330-450 K$ | Estimé, sources faibles divergentes | [Getlatka](https://getlatka.com/companies/withaqua.com), [Extruct](https://www.extruct.ai/hub/withaqua-com-funding/) |
| Conversion | 42 % des essayeurs deviennent payants | Revendiqué, source unique | [AI Market Watch](https://www.ai-market-watch.com/news/aqua-voice-a-y-combinator-backed-voice-ai-startup-reports-over-half-its-users-ar-2tib98) |
| Géographie | >50 % des utilisateurs au Japon (input japonais + agents IA) | Revendiqué, source unique | AI Market Watch |
| Effectifs | 3-5 personnes | Estimé, sources divergentes | Getlatka, Crunchbase |
| Communauté | Discord actif, changelog régulier, API Avalon pour devs | Vérifié | [changelog](https://aquavoice.com/changelog) |

---

## 6. Willow Voice (willowvoice.com, YC X25) : le challenger jeune

Fondateurs : Allan Guo et Lawrence Liu, dropouts Stanford, YC printemps 2025.

### UX perçue

**Notes** :
- iOS App Store : **~4,6/5 sur 579-730 notes** selon source/date ([App Store](https://apps.apple.com/us/app/willow-dictation-ai-keyboard/id6753057525)).
- Product Hunt : 149 upvotes, Product of the Day (mars 2025) ; c'était leur **7e launch PH** (stratégie de launchs répétés) ([fiche PH](https://www.producthunt.com/products/willow-voice)).
- G2/Trustpilot : non trouvés. Reddit : présence très mince, confirme la faible notoriété.

**Top 3 adoré** :
1. Précision supérieure à la dictée Apple (« 3x more accurate », revendiqué) ; « crushes other voice text apps in terms of speed and accuracy » (avis App Store).
2. Différenciateur produit : **dicter puis éditer immédiatement au clavier dans la même interface**, salué par [TechCrunch 2025-11-12](https://techcrunch.com/2025/11/12/willows-voice-keyboard-lets-you-type-across-all-your-ios-apps-and-actually-edit-what-you-said/) ; 100+ langues ; **mode offline optionnel Mac/iOS** (rare chez les acteurs financés).
3. Réactivité de l'équipe au feedback (communauté Slack).

**Top 3 détesté** :
1. Clavier iOS « clunky » : ~100 px plus haut que le natif, aller-retours vers l'écran Willow.
2. Demande d'**enregistrement audio en arrière-plan** même clavier fermé : perçu comme un problème privacy + batterie (avis App Store).
3. Prix au niveau de Wispr (15 $/mois) sans la notoriété ni l'écosystème. Point positif : free tier récurrent 2 000 mots/semaine, plus généreux qu'Aqua.

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding | Seed 4,2 à 5 M$ (sources divergentes) ; BoxGroup, YC, Burst + angels Dharmesh Shah, Alexis Ohanian, Max Mullen | Montant non confirmé ; investisseurs cross-validés | [Menlo Times](https://www.menlotimes.com/post/ai-powered-voice-dictation-platform-willow-raised-4-2-million-to-build-voice-first-interfaces), [Tracxn](https://tracxn.com/d/companies/willow-voice/__FbkAwtYS8DBDtRXD83OlzGR7ESaR4Jvz_3NbizDvCYQ) |
| Croissance | 50 % MoM users ; clients revendiqués Uber, Heidi Health | Revendiqué (repris sans vérif tierce) | [TechBuzz](https://www.techbuzz.ai/articles/y-combinator-s-willow-launches-ai-voice-keyboard-for-ios) |
| ARR | ~550 K$ | Estimé, source unique | [Getlatka](https://getlatka.com/companies/willowvoice.com) |
| Effectifs | Très réduit (2 fondateurs + premières embauches) | Non confirmé | Crunchbase/Tracxn |
| Communauté | Slack, changelog public actif | Vérifié | [changelog](https://feedback.willowvoice.com/changelog) |

---

## 7. Otter.ai : le géant adjacent (réunions), contre-modèle UX

### UX perçue

**Notes** : Trustpilot **~3,8/5** (486 avis) ; G2 ~4,1-4,3/5 (~290 avis) ; plaintes BBB actives (facturation).

**Top 3 adoré** :
1. Gain de temps massif sur les notes de réunion : résumés, action items, timestamps par intervenant.
2. Intégrations auto Zoom/Teams/Meet : l'agent rejoint et transcrit sans intervention.
3. Transcription temps réel anglais jugée bonne, recherche dans l'historique, sync multi-device.

**Top 3 détesté** (dark patterns documentés) :
1. **Annulation/facturation : grief n°1 Trustpilot.** « Charged $88 for a cancelled subscription », « it is a nightmare to cancel Otter », pas de support téléphonique, politique no-refund ([Trustpilot](https://www.trustpilot.com/review/otter.ai), [BBB](https://www.bbb.org/us/ca/mountain-view/profile/computer-software/otterai-1216-1647445/complaints)).
2. **Agent intrusif, jusqu'au contentieux** : le Notetaker scanne le calendrier et rejoint automatiquement des réunions jamais destinées à être enregistrées ([Bitdefender 2025](https://www.bitdefender.com/en-us/blog/hotforsecurity/otter-ai-keeps-joining-your-meetings-uninvited-heres-how-to-make-it-stop)) ; **class action fédérale (août 2025)** : enregistrements « deceptively and surreptitiously » utilisés pour l'entraînement ([NPR 2025-08-15](https://www.npr.org/2025/08/15/g-s1-83087/otter-ai-transcription-class-action-lawsuit)).
3. **Spam email aux contacts** : invitations et résumés envoyés aux collègues sans déclencheur explicite ([Beaver AI 2025](https://beaverai.app/blog/otter-ai-emailing-colleagues-without-permission/)). Bonus : « shrinkflation » du free (300 min/mois, 30 min/conversation).

**Fiabilité perçue** : correcte en anglais US propre ; dégradation nette avec accents, bruit, conversations superposées ; diarisation faible.

### Traction

| Métrique | Valeur | Statut | Source |
|---|---|---|---|
| Funding total | ~70 M$ (Series B 50 M$ fév. 2021, rien depuis) | Vérifié | [Crunchbase](https://www.crunchbase.com/organization/aisense-inc), [Sacra](https://sacra.com/c/otter/) |
| Valorisation | 243,5 M$ (Series B 2021) ; rien de plus récent public | Source unique | [Wellfound](https://wellfound.com/company/otter-ai/funding) |
| ARR | **100 M$ (mars 2025)**, vs 81 M$ fin 2024 | Revendiqué + estimation Sacra convergente | [Communiqué Otter 2025-12-22](https://otter.ai/blog/otter-ai-caps-transformational-2025-with-100m-arr-milestone-industry-first-ai-meeting-agents-and-global-enterprise-expansion), [Sacra](https://sacra.com/c/otter/) |
| Utilisateurs | 25 M+ (2025) ; « over 35 million » (déc. 2025) | Revendiqué | Sacra, communiqué |
| Effectifs | ~200-290 (fourchette selon source) | Incertain | Communiqué, GetLatka, RocketReach |

**Lecture** : très efficient en capital (100 M$ ARR sur 70 M$ levés) mais croissance construite sur des dark patterns qui coûtent aujourd'hui une class action et un Trustpilot à 3,8. Contre-modèle exploitable : consentement explicite, annulation simple, zéro spam.

---

## 8. Acteurs découverts en route

### Monologue (monologue.to, par Every)
Dictée Mac « context-aware » (vocabulaire, apps ouvertes, style), créée par Naveen Naidu, lancée par le studio/média Every (Dan Shipper). ~10 $/mois. Product of the Day PH (sept. 2025, 267 upvotes), launch iOS fév. 2026 (275 upvotes). Distribution médiatique puissante via Every. NB : la piste « créateur de CleanShot X » n'est pas confirmée ; homonyme distinct [monologue.run](https://www.monologue.run/) (Whisper 100 % on-device, achat unique). [PH](https://www.producthunt.com/products/monologue-2), [Every](https://every.to/on-every/introducing-monologue-effortless-voice-dictation).

### Typeless (typeless.com)
Dictée IA cloud, équipe Stanford, lancée nov. 2025. La couverture plateformes la plus large (macOS, Windows, iOS, Android). Free tier généreux (4 000-8 000 mots/semaine), Pro 12 $/mois annuel (30 $/mois mensuel, le plus cher de la catégorie). Cleanup jugé parmi les meilleurs, mais **cloud-only, pas de BYOK** : angle d'attaque évident pour du local-first. Funding non public. [typeless.com](https://www.typeless.com/about).

### Handy (github.com/cjpais/Handy)
STT gratuit, open source (MIT), 100 % offline (Whisper/Parakeet/Moonshine), Tauri/Rust, Mac + Windows + Linux. **23 000+ stars GitHub (mai 2026)**, front page HN. Le standard open source de facto et le **plancher gratuit** contre lequel toute app payante local-first sera comparée. Qualité perçue inégale (« handy too buggy », HN fév. 2026). [GitHub](https://github.com/cjpais/handy).

### Spokenly (spokenly.app)
Dictée hybride Mac/iPhone/Windows d'un indé. Modèles locaux gratuits illimités + BYOK sans surcharge ; Pro 9,99 $/mois pour le cloud managé. Différenciateur : **serveur MCP intégré**. Forte machine SEO (blog de comparatifs biaisés). Pas de funding trouvé. [spokenly.app](https://spokenly.app/).

### Talon (talonvoice.com)
Voice computing complet (voix + bruit + eye tracking) pour devs et accessibilité RSI. Gratuit + Patreon ~25 $/mois. Catégorie adjacente, mais chevauche la promesse « contrôler son Mac à la voix ». Communauté de niche fidèle. [talonvoice.com](https://talonvoice.com/).

### Menace native Apple (macOS Tahoe 26, sept. 2025)
Nouvelles API SpeechAnalyzer/SpeechTranscriber **55 % plus rapides que Whisper** (34 min de vidéo transcrites en 45 s), on-device sur Neural Engine. La dictée native devient « a strong option » pour l'usage casual : la barre monte pour toute app payante, la valeur se déplace vers le contexte, le formatting IA et l'agentique. [MacRumors 2025-06-18](https://www.macrumors.com/2025/06/18/apple-transcription-api-faster-than-whisper/).

### Longue traîne (non retenue)
Voibe, Voicy, DictaFlow, LumeVoice, Mumble, VoiceDash, OpenWhispr, Weesper, Dictato, MetaWhisp... Quasi tous pratiquent le SEO de comparatifs croisés en se citant n°1. Aucune traction indépendante trouvée. À traiter comme du bruit marketing, pas comme des concurrents.

---

## 9. Synthèse

### Classement de traction estimé (revenus/échelle, marché dictée + adjacent)

| Rang | Acteur | Signal principal | Nature |
|---|---|---|---|
| 1 | **Otter.ai** | 100 M$ ARR (2025), 25-35 M users revendiqués | Adjacent (réunions), pas dictée système |
| 2 | **Wispr Flow** | 81 M$ levés, valo 700 M$, ~10 M$ ARR est., 2,5 M downloads revendiqués, 94 employés | Leader dictée cloud, hypercroissance |
| 3 | **Superwhisper** | Bootstrappé, revenus 7 chiffres revendiqués, centaines de milliers de WAU revendiqués, 11 personnes | Référence power user Mac |
| 4 | **MacWhisper** | ~250-300 K copies revendiquées, solo dev rentable | Spécialiste transcription |
| 5 | **VoiceInk** | 5,5 K stars GitHub, 200 K+ downloads revendiqués, solo dev | Challenger open-source lifetime |
| 6 | **Willow Voice** | Seed ~4-5 M$, ~550 K$ ARR est., 50 % MoM revendiqué | Challenger financé jeune |
| 7 | **Aqua Voice** | 500 K$ pre-seed, ~330-450 K$ ARR est., 3-5 personnes | Produit-culte, micro-traction |
| hors classement | Handy (23 K stars, gratuit), Typeless, Monologue, Spokenly, Talon | Traction financière inconnue ou nulle | Pression sur le plancher gratuit |

Lecture structurelle : le marché se divise en trois blocs. **Cloud financé** (Wispr, Typeless, Monologue), **local payant** (Superwhisper, VoiceInk, MacWhisper), **local gratuit** (Handy, Spokenly free, dictée native Tahoe). Personne dans le paysage étudié ne combine **local-first + agent vocal multi-étapes** : la fenêtre de Verba est réelle mais la catégorie est à faible barrière d'entrée, donc la vitesse d'exécution et la confiance feront la différence.

### Les 5 frictions UX du marché exploitables par Verba

1. **Le déficit de confiance du cloud.** Le leader s'est fait prendre à uploader des screenshots à l'insu des utilisateurs, puis a vu ses certifications compromises par le scandale Delve ; Aqua est « non-starter » pour une partie de HN faute de mode local ; Otter est sous class action pour enregistrement à l'insu ; Willow demande le micro en arrière-plan. **Angle Verba** : local-first vérifiable (trafic réseau observable, pas de compte requis), en faire une preuve, pas un slogan.

2. **La fiabilité cloud à l'échelle (le « day-two drop »).** 75+ incidents Wispr en 6 mois, un de ~6 jours ; apps excellentes en trial, inconsistantes après paiement ; MacWhisper perd l'audio en crash recovery, Superwhisper iOS perd des enregistrements. **Angle Verba** : fiabilité offline + garantie « zéro enregistrement perdu » (persistance locale immédiate de l'audio), argument de rétention mesurable.

3. **Le rejet du modèle abonnement.** Pricing = plainte transverse n°1 : 38 % des avis iOS récents de Wispr, 15 $/mois sans lifetime chez Wispr et Willow, free tier d'Aqua limité à 1 000 mots à vie, « double facturation » reprochée à Superwhisper. Le succès des lifetime (Superwhisper 249 $, VoiceInk 25-49 $, MacWhisper €59) prouve la demande. **Angle Verba** : BYO-AI = coût marginal transparent chez le provider de l'utilisateur, sans marge cachée sur l'inférence ; une option lifetime/licence perpétuelle adresse directement la friction documentée.

4. **Le contexte applicatif superficiel.** LE critère qui sépare les power users : Superwhisper gagne grâce aux API d'accessibilité (texte sélectionné, presse-papiers, app active), VoiceInk est critiqué pour son OCR de screenshots, la dictée native Tahoe n'a aucun contexte. **Angle Verba** : contexte profond par accessibility API + le cran au-dessus que personne n'a : l'agent (JARVIS) qui ne se contente pas de formater mais agit en multi-étapes sur 1000+ apps. Post-Tahoe, la transcription brute est commoditisée ; le contexte et l'action sont la valeur défendable.

5. **Le consentement bafoué et la friction commerciale (contre-modèle Otter).** Auto-join des réunions, spam des contacts, annulation labyrinthique, shrinkflation du free : les dark patterns du géant de la catégorie adjacente sont documentés jusqu'au tribunal et plombent son Trustpilot (3,8) comme celui de Wispr (2,7). **Angle Verba** : consentement explicite partout, annulation en un clic, free tier honnête et stable. Sur un marché où les deux plus gros acteurs ont un Trustpilot médiocre, la réputation compte se construit vite et vaut de l'acquisition organique (Reddit/HN sont prescripteurs dans cette catégorie).

### Risques à garder en tête

- **Apple commoditise la transcription** (Tahoe, sept. 2025) : ne jamais vendre la précision brute comme différenciateur durable.
- **Handy à 23 K stars** fixe le plancher gratuit du local : Verba doit justifier son prix par le contexte, l'agent et le polish, pas par le STT.
- **Wispr à 81 M$ levés** peut acheter sa sortie de crise de confiance (nouvel audit déjà commandé) ; la fenêtre « confiance » ne restera pas ouverte indéfiniment.
- Plusieurs chiffres clés de ce rapport sont revendiqués ou estimés source unique (marqués comme tels) : ne pas les réutiliser dans de la copy publique sans re-vérification.
