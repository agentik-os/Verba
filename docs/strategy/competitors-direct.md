# Étude concurrentielle : concurrents directs de Verba

> **Périmètre** : outils de dictée IA / voice-to-text de productivité, desktop en priorité (macOS d'abord), avec réécriture IA. Hors scope : outils de transcription de réunions (Otter, Granola), TTS, assistants vocaux grand public (Siri, Alexa).
> **Méthode** : sites officiels + pages pricing + presse tech + profils funding, consultés le **2026-07-14**. Chaque fait est sourcé (URL). Les faits importants sont cross-validés sur au moins 2 sources ; sinon marqués `[source unique]`.
> **Biais à connaître** : une grande partie des comparatifs "Best dictation apps 2026" trouvables en ligne (Voibe, Spokenly, Voicy, Weesper, BossAI, SpeakMac, LumeVoice...) sont publiés **par des concurrents eux-mêmes** (content marketing SEO). Ils sont utiles pour les prix et features factuels, mais leurs verdicts sont intéressés. Les sources neutres utilisées ici : TechCrunch, The Globe and Mail, Crunchbase/Tracxn, GitHub, sites officiels.

---

## 1. Résumé exécutif

Le marché de la dictée IA desktop a explosé entre 2023 et 2026. Il se structure en **trois blocs** :

1. **Le bloc cloud financé par le VC** : Wispr Flow (leader, en discussion pour lever ~260 M$ à ~2 Md$ de valorisation), Aqua Voice (YC W24), Willow Voice (YC X25), Typeless (StartX), Monologue (Every). Modèle : abonnement 8 à 15 $/mois, free tier limité en mots, STT + réécriture LLM côté serveur, cross-platform agressif (Mac, Windows, iOS, Android). Positionnement mainstream "4x faster than typing".
2. **Le bloc local-first indie** : Superwhisper (Toronto, bootstrapped, le plus mûr), VoiceInk (open source GPL v3, lifetime 25 à 49 $), MacWhisper (Good Snooze, transcription de fichiers d'abord). Modèle : licence lifetime ou abonnement modéré, Whisper/Parakeet on-device, BYO API keys. C'est le bloc architecturalement le plus proche de Verba.
3. **La frange gratuite/open source** : Spokenly (gratuit, local + BYOK, MCP), Handy, OpenWhispr. Pression déflationniste : la dictée locale brute est en voie de commoditisation.

**Constats clés pour Verba** :

- **Personne ne combine local-first + BYO-AI + agent vocal multi-applications.** Le concept JARVIS (exécution de commandes multi-étapes sur 1000+ apps avec OAuth, clarification, confirmation) n'a **aucun équivalent direct** chez les concurrents étudiés. Ce qui s'en rapproche le plus : le Command Mode de Wispr Flow (édition vocale du texte sélectionné, <1000 mots, pas d'action externe), le voice editing d'Aqua, et l'intégration MCP de Spokenly (pilotage d'agents de code, pas d'apps SaaS).
- **Le combo "modes de réécriture éditables + BYO-AI" n'existe qu'à moitié ailleurs** : Superwhisper et VoiceInk ont modes custom + BYOK, mais leurs LLM sont une liste fermée de providers ; Wispr/Willow/Aqua sont fermés (aucun BYOK).
- **Le contexte écran (équivalent du mode Context de Verba) devient un standard** : Super Mode (Superwhisper), contexte écran (Aqua, VoiceInk, Monologue, Wispr en partie). Ce n'est plus un différenciateur seul.
- **Pricing** : deux régimes bien installés. Abonnement cloud 12-15 $/mois (144 $/an) avec free tier ~2000 mots/semaine, ou lifetime local 25 $ (VoiceInk) à 849 $ (Superwhisper, après une hausse de 240 % en 2026). Un lifetime Verba entre 39 et 79 $ serait dans la norme du bloc local ; un abonnement au-dessus de 15 $/mois serait hors marché sans le justifier par l'agent.
- **Risques principaux** : (a) la puissance de feu marketing de Wispr Flow (~2 Md$ de valo en discussion, 50-94 employés) qui définit la catégorie dans l'esprit du public ; (b) la commoditisation par l'open source gratuit ; (c) un sherlocking Apple (amélioration de la dictée système via Apple Intelligence).

---

## 2. Wispr Flow : le leader financé, cloud-only

### (a) Identité
- Société : **Wispr** (produit Wispr Flow), San Francisco. Fondateurs : **Tanay Kothari (CEO)** et **Sahaj Garg (CTO)** ([Crunchbase](https://www.crunchbase.com/organization/wispr-ai), [Tracxn](https://tracxn.com/d/companies/wispr-flow/__XTPty9fIPUjngX0uMeYcKZnHJVG4WCoPwSamLLI2QjE), consultés 2026-07-14). À l'origine startup d'interface neurale portable, pivotée vers le logiciel de dictée `[source unique : mémoire de marché, non re-vérifié]`.
- Funding : ~**81 M$ levés** sur 5 tours ([Tracxn](https://tracxn.com/d/companies/wispr-flow/__XTPty9fIPUjngX0uMeYcKZnHJVG4WCoPwSamLLI2QjE/funding-and-investors)) ; valorisation **700 M$** (Series B 2026, [Premier Alts](https://www.premieralts.com/companies/wispr-flow/valuation)) ; en discussion en mai 2026 pour **~260 M$ à ~2 Md$** de valorisation, mené par Menlo Ventures ([The Tech Portal, 2026-05-12](https://thetechportal.com/2026/05/12/ai-dictation-startup-wispr-could-secure-260mn-funding-at-2bn-valuation/)).
- Effectif : ~50 à 94 personnes selon les sources ([Getlatka](https://getlatka.com/companies/wisprflow.ai), Tracxn), en croissance rapide.

### (b) Architecture technique
- **Cloud-only** : l'audio part sur les serveurs Wispr pour STT + réécriture LLM. Aucun mode local, connexion internet obligatoire ([eesel](https://www.eesel.ai/blog/wispr-flow-review), [Voibe](https://www.getvoibe.com/resources/wispr-flow-review/), cross-validé). Modèles STT/LLM propriétaires côté serveur, non documentés publiquement.
- Le contexte écran est envoyé au cloud avec l'audio ([Saner.ai](https://www.saner.ai/blogs/best-wispr-flow-alternatives)) `[source unique]`.
- **Incident privacy documenté** : les données de dictée servaient à l'entraînement par défaut ; après backlash communautaire, excuses publiques du CTO et passage en opt-in désactivé par défaut ([ModelPiper](https://modelpiper.com/blog/wispr-flow-privacy-incident)) `[source unique pour le déroulé ; la doc officielle confirme le mécanisme actuel : sans Privacy Mode, les données "may be used to train"]` ([wisprflow.ai/privacy](https://wisprflow.ai/privacy)).
- Compliance : HIPAA-ready tous plans, SOC 2 Type II + ISO 27001 sur Enterprise, Privacy Mode = zéro rétention, opt-in en Pro, forcé en Enterprise ([wisprflow.ai/pricing](https://wisprflow.ai/pricing), [docs](https://docs.wisprflow.ai/articles/3467817258-security-and-compliance-faq)).
- Plateformes : **macOS, Windows, iPhone, Android** ([wisprflow.ai](https://wisprflow.ai/)) : la couverture la plus large du marché avec Typeless.

### (c) Features
- Dictée system-wide, nettoyage IA : suppression des fillers, ponctuation, capitalisation, structuration en listes ("first, second, third"), **ton adapté par application** (Slack casual vs email formel) ([spokenly review](https://spokenly.app/blog/wispr-flow-review), site officiel).
- **Command Mode** (payant) : sélectionner du texte, parler une instruction ("make this shorter", "translate to French", "turn into bullets"), le texte est remplacé. Limité à **1000 mots** de sélection, édition locale uniquement ; sans sélection, ouvre Perplexity dans le navigateur avec la question ([docs officielles](https://docs.wisprflow.ai/articles/4816967992-how-to-use-command-mode)). **Ce n'est pas un agent** : aucune action hors du champ texte.
- Dictionnaire personnel, 100+ langues, styles ("formal", "casual", "very casual") ([TechCrunch, 2026-05-02](https://techcrunch.com/2026/05/02/the-best-ai-powered-dictation-apps-of-2025/)).

### (d) Pricing ([wisprflow.ai/pricing](https://wisprflow.ai/pricing), consulté 2026-07-14)
| Plan | Prix | Limites |
|---|---|---|
| Basic (free) | 0 $ | 2000 mots/sem (Mac/Win), 1000/sem (iPhone), illimité Android |
| Pro | 15 $/mois, ou 12 $/mois en annuel (144 $/an) | Illimité, Command Mode, essai 14 j |
| Enterprise | Sur devis (24 $/user/mois selon [Voibe](https://www.getvoibe.com/resources/wispr-flow-pricing/) `[source unique]`) | SOC 2, SSO/SAML, HIPAA forcé |
| Étudiants | 3 mois gratuits + 50 % off (site officiel) | |

Pas de lifetime.

### (e) Positionnement & ICP
"Effortless voice dictation", "4x faster than typing". ICP : knowledge workers mainstream, cadres, utilisateurs intensifs de ChatGPT/e-mail, équipes (offre Teams/Enterprise). C'est la marque qui définit la catégorie auprès du grand public tech.

### (f) Forces / faiblesses vs Verba
- **Forces** : notoriété et budget marketing sans commune mesure ; polish produit ; cross-platform complet ; free tier viral ; compliance entreprise.
- **Faiblesses exploitables** : cloud-only (dealbreaker pour juristes, santé, devs sécurité) ; historique de confiance entaché (entraînement par défaut) ; aucun BYO-AI ; Command Mode limité au texte, pas d'agent ; abonnement à vie (LTV extraite en continu, audience sensible au lifetime disponible).
- **Menace** : avec ~2 Md$ de valo, Wispr peut copier n'importe quelle feature visible (y compris un agent) et l'écraser en distribution. La défense de Verba est structurelle : local-first + BYO-AI sont contraires à leur modèle économique (leur valo repose sur les données et l'abonnement).

---

## 3. Superwhisper : le concurrent architectural le plus proche

### (a) Identité
- Société : **SuperUltra, Inc.**, Toronto, **bootstrapped**. Fondateur solo : **Neil Chudleigh** (ex-cofondateur PartnerStack, YC S15). App lancée **juillet 2023** ([The Globe and Mail](https://www.theglobeandmail.com/business/article-toronto-ai-startup-superwhisper-dictation-app/), [Crunchbase](https://www.crunchbase.com/person/neil-chudleigh), cross-validé). Le footer du site mentionne "Backed by API Capital" ([superwhisper.com](https://superwhisper.com/)), à réconcilier avec le narratif bootstrapped `[à surveiller]`.

### (b) Architecture technique
- **Local-first avec option cloud** : modèles Whisper locaux (Tiny → Large-v3 Turbo) on-device sur Apple Silicon, aucune connexion requise pour transcrire ([spokenly](https://spokenly.app/blog/superwhisper-review), site officiel, cross-validé).
- Réécriture LLM : choix parmi **GPT-5, Claude Haiku, Llama, Grok, Gemini, Ministral** + **BYO API keys** en Pro ([superwhisper.com](https://superwhisper.com/), consulté 2026-07-14).
- Plateformes : **macOS, Windows, iOS** (Windows ajouté en 2025-2026).
- SOC 2 Type II, HIPAA (site officiel).

### (c) Features
- **Modes** : Voice, Message, Email prédéfinis + **modes custom** (prompt libre définissant format et style) : l'équivalent le plus direct des modes Verba.
- **Super Mode** : adaptation au contenu de l'écran (équivalent du mode Context de Verba) ([superwhisper.com](https://superwhisper.com/)).
- Push-to-talk, raccourcis par app, activation par application, vocabulaire/abréviations custom, auto-paste presse-papiers.
- Transcription de fichiers audio/vidéo, enregistrement de réunions + notes automatiques, traduction, 100+ langues.

### (d) Pricing
| Plan | Prix | Contenu |
|---|---|---|
| Free | 0 $ | Petits modèles locaux illimités, dictée partout, 100+ langues, meeting recording |
| Pro | ~8,49 $/mois ou 84,99 $/an ([spokenly pricing](https://spokenly.app/blog/superwhisper-pricing), juin 2026 ; la homepage affiche "8 $/mois") | Modèles cloud + gros modèles locaux illimités, BYOK, transcription fichiers, traduction |
| **Lifetime** | **849 $** (site officiel consulté 2026-07-14) | ⚠️ Était à **249,99 $** jusqu'à ~mi-2026 : hausse de 240 % documentée ([Weesper blog](https://weesperneonflow.ai/en/blog/2026-06-02-superwhisper-pricing-plans-lifetime-2026/), sources de juin 2026 encore à 249,99 $) |
| Étudiants | -40 % | |

### (e) Positionnement & ICP
Mac-native, privacy, personnalisation profonde. ICP : power users Mac, devs, professions sensibles à la confidentialité. Le produit "sérieux" du bloc local.

### (f) Forces / faiblesses vs Verba
- **Forces** : 3 ans de maturité produit ; base installée et bouche-à-oreille solides ; feature set très large (fichiers, meetings) ; multi-LLM + BYOK ; SOC 2.
- **Faiblesses** : hausse brutale du lifetime à 849 $ = fenêtre ouverte pour un lifetime raisonnable ; UX réputée dense/complexe pour les nouveaux venus ; pas d'agent ni de commandes d'action ; BYO-AI limité à une liste de providers (pas de backend arbitraire).
- **Lecture** : c'est le concurrent à battre feature-à-feature sur le cœur dictée+modes. Verba doit être au niveau sur les modes custom et gagner sur JARVIS, la simplicité, et l'ouverture réelle du BYO-AI.

---

## 4. MacWhisper : l'outil de transcription qui fait aussi de la dictée

### (a) Identité
- Développeur : **Jordi Bruin / Good Snooze**, Pays-Bas, indie ([macwhisper.com](https://macwhisper.com/), consulté 2026-07-14). 4,5 étoiles / 2264 avis sur Gumroad ([Gumroad](https://goodsnooze.gumroad.com/l/macwhisper)).

### (b) Architecture technique
- 100 % local pour le STT : **Whisper + Nvidia Parakeet** on-device. Réécriture IA : local via **Ollama / LM Studio** ou cloud BYOK (**OpenAI, Anthropic, Groq, xAI, Azure, Deepseek, Google, OpenRouter**) ([macwhisper.com](https://macwhisper.com/)). macOS uniquement.

### (c) Features
- Cœur du produit : **transcription de fichiers** (drag & drop, batch, watch folders, YouTube, podcasts, diarisation, export SRT/VTT/.docx/.pdf, enregistrement de réunions Zoom/Teams/Webex/Discord).
- Dictée system-wide temps réel incluse (remplace la dictée Apple), nettoyage des fillers, prompts IA custom, mais **la dictée n'est pas le focus produit** ([Voibe](https://www.getvoibe.com/resources/macwhisper-pricing/), [daveswift.com](https://daveswift.com/macwhisper/), cross-validé).
- 100+ langues.

### (d) Pricing
- Free tier permanent ; **Pro : 64 € one-time** lifetime updates (site officiel 2026-07-14 ; des sources de début 2026 citent 59 € : hausse légère probable).
- Version Mac App Store "Whisper Transcription" : 6,99 $/mois, 29,99 $/an ou 99,99 $ lifetime ([Voibe](https://www.getvoibe.com/resources/macwhisper-pricing/)) `[source unique]`.

### (e) Positionnement & ICP
Journalistes, podcasteurs, chercheurs, monteurs : quiconque transcrit des fichiers. La dictée est un bonus.

### (f) Forces / faiblesses vs Verba
- **Forces** : marque indie Mac très respectée, prix lifetime bas, BYOK très large.
- **Faiblesses** : dictée temps réel secondaire (pas de modes de réécriture par app poussés, pas de contexte écran, pas d'agent) ; macOS only.
- **Lecture** : concurrence frontale faible sur l'usage quotidien de dictée ; référence de prix pour le lifetime local. Ne pas essayer de le concurrencer sur la transcription de fichiers (hors cœur Verba).

---

## 5. VoiceInk : le jumeau open source, lifetime à 25 $

### (a) Identité
- Développeur indie : **Prakash Joshi Pax** (GitHub Beingpax). Lancé début 2025, **open source GPL v3 depuis février 2025**, 4700+ stars ([GitHub](https://github.com/beingpax/VoiceInk), [Voibe review](https://www.getvoibe.com/resources/voiceink-review/), cross-validé). Se présente explicitement comme "the best open-source alternative to Superwhisper & Wispr Flow".

### (b) Architecture technique
- **Local par défaut** (whisper.cpp, Neural Engine), la voix ne quitte jamais la machine ; **cloud optionnel uniquement pour l'enhancement du texte** transcrit, BYOK ([tryvoiceink.com](https://tryvoiceink.com/), consulté 2026-07-14).
- macOS 14.4+, **Apple Silicon requis**. App iOS présente sur l'App Store ([App Store](https://apps.apple.com/us/app/voiceink-ai-dictation/id6751431158)) `[source unique, périmètre iOS non détaillé]`.

### (c) Features
- Modes d'enhancement IA : **Polish, Email, Chat, Post** + prompts custom.
- **Contexte écran + presse-papiers** ; **changement de mode automatique selon l'app/le site détecté** (équivalent d'un "Power Mode"), directement comparable aux modes par app de Verba.
- Dictionnaire personnel + remplacements de texte, push-to-talk, hotkeys configurables, multi-langues, 100 % offline possible.

### (d) Pricing (one-time, lifetime updates, garantie 14 j ; site officiel 2026-07-14)
| Tier | Prix | Macs |
|---|---|---|
| Solo | 25 $ | 1 |
| Personal | 39 $ | 2 |
| Extended | 49 $ | 3 |
| Startup | 159 $ | 10 |
| Build from source | 0 $ | — |

### (e) Positionnement & ICP
Anti-abonnement, privacy, open source. ICP : devs, bricoleurs, utilisateurs Hacker News, tous ceux que Wispr agace.

### (f) Forces / faiblesses vs Verba
- **Forces** : prix plancher du marché ; confiance maximale (code auditable) ; philosophie identique à Verba (local, BYOK, modes par app, contexte écran) ; communauté GitHub active.
- **Faiblesses** : mono-développeur (bus factor, rythme) ; pas d'agent ni d'actions ; pas de Windows ; distribution limitée au bouche-à-oreille tech.
- **Lecture** : c'est l'ancre de prix du segment de Verba. Un lifetime Verba se positionnera forcément par rapport aux 25-49 $ de VoiceInk ; la valeur incrémentale doit être portée par JARVIS et le polish. Surveiller son évolution : open source + momentum GitHub = capable d'absorber vite des features.

---

## 6. Aqua Voice : la vitesse et le modèle STT propriétaire

### (a) Identité
- **Aqua Voice, Inc.**, San Francisco, **YC W24**. Fondée 2023 par **Finn Brown (CEO)** et **Jack McIntire (CTO)**, rencontrés à Harvard, rejoints par Pablo Peniche (produit/growth) ([aquavoice.com/team](https://aquavoice.com/team), [YC](https://www.ycombinator.com/companies/aqua-voice), cross-validé).
- Funding : ~500 k$ pre-seed (YC, Pioneer Fund, 1517 Fund, Assembly Capital) ; ~330 k$ ARR en septembre 2025 ([Tracxn](https://tracxn.com/d/companies/aqua-voice/__JFA4kMg-cpbXLPswkAZyNuC2JPbjeQazgi41iF_F7kM), [Getlatka](https://getlatka.com/companies/withaqua.com)). Nettement moins financé que Wispr/Willow.

### (b) Architecture technique
- **Cloud**, avec un différenciateur : modèle STT **propriétaire "Avalon"** (revendique 97,3 % de précision sur AISpeak, 49 langues), benchmarké contre Whisper/NVIDIA/AssemblyAI ([aquavoice.com](https://aquavoice.com/), consulté 2026-07-14). Vend aussi son STT **en API** à des tiers ([TechCrunch](https://techcrunch.com/2026/05/02/the-best-ai-powered-dictation-apps-of-2025/)).
- **Dictée en streaming** : le texte apparaît et se raffine pendant qu'on parle (grammaire corrigée en temps réel). Latence = argument n°1.
- Plateformes : Mac, iOS (récent) ; Windows listé par des sources tierces ([WebCatalog](https://webcatalog.io/en/apps/aqua-voice)) `[divergence : le site officiel ne met en avant que Mac + iOS]`.

### (c) Features
- Contexte écran (y compris syntaxe de code et terminologie technique), voice editing, adaptation de style par contexte, instructions custom, dictionnaire (5 entrées en free, 800 en Pro).

### (d) Pricing (site officiel 2026-07-14)
| Tier | Prix | Limites |
|---|---|---|
| Starter (free) | 0 $ | 1000 mots/mois, 5 entrées de dictionnaire |
| Pro | 8 $/mois (facturé annuellement, 96 $/an ; pas de remise annuelle) | Illimité, Avalon, 800 entrées, instructions custom |
| Team | 12 $/user/mois | Réglages org, privacy forcée |
| Enterprise | Custom | SSO/SAML, zéro rétention |
| Étudiants | -70 % sur l'annuel ([spokenly](https://spokenly.app/blog/aqua-voice-review)) `[source unique]` | |

### (e) Positionnement & ICP
"Frontier Voice Input", 5x plus rapide que le clavier, latence minimale. ICP : devs et power users pressés ; second marché : les apps tierces via l'API STT.

### (f) Forces / faiblesses vs Verba
- **Forces** : la meilleure expérience de latence perçue du marché (streaming) ; stack STT propriétaire = maîtrise du coût et de la qualité ; prix agressif (8 $/mois).
- **Faiblesses** : cloud-only, pas de BYOK, pas d'agent ; traction financière modeste (~330 k$ ARR fin 2025) ; dictionnaire bridé en free.
- **Lecture** : le benchmark UX de la latence. Verba (local, streaming partiel selon backend) doit soigner le temps voix→texte perçu, c'est le seul terrain où Aqua fait la course en tête.

---

## 7. Willow Voice : le challenger YC cross-platform

### (a) Identité
- **Willow**, San Francisco, **YC X25** (printemps 2025 ; l'équipe était initialement en YC été 2024 sur un projet santé, pivot + changement de cofondateurs). Fondateurs : **Allan Guo (CEO)** et **Lawrence Liu (CTO)**, dropouts de Stanford. 7 employés. **4,5 M$ levés** (Box Group, YC, Burst Capital + angels : Alexis Ohanian, Dharmesh Shah, Tomer London, Max Mullen...) ([TechCrunch, 2025-11-12](https://techcrunch.com/2025/11/12/willows-voice-keyboard-lets-you-type-across-all-your-ios-apps-and-actually-edit-what-you-said/), [YC](https://www.ycombinator.com/companies/willow), cross-validé).

### (b) Architecture technique
- **Cloud** : modèles maison nommés commercialement "Frontier Mini" (free) et "Frontier Pro" (payant), nature exacte non documentée ([willowvoice.com/pricing](https://willowvoice.com/pricing), consulté 2026-07-14). **Mode offline optionnel sur Mac et iOS** ([Voibe](https://www.getvoibe.com/resources/willow-voice-review/)) `[source unique]`.
- Plateformes : **Mac, Windows, iOS** (clavier iOS avec édition vocale, lancé nov. 2025), **Android "coming soon"** (page pricing officielle ; certaines sources tierces disent Android déjà dispo ; retenir le site officiel).

### (c) Features
- Auto-formatting, correction grammaticale, suppression des fillers, **mémoire du style d'écriture** de l'utilisateur, adaptation du ton par application, dictionnaire, 100+ langues.
- **Scribe** : transformation de notes vocales en messages structurés (20 usages/semaine en free, illimité en Pro).
- Clavier iOS avec **édition vocale du texte dicté** (différenciateur mobile mis en avant par TechCrunch).

### (d) Pricing (site officiel 2026-07-14)
| Plan | Prix | Limites |
|---|---|---|
| Basic (free) | 0 $ | Modèle faible illimité, 2000 mots/sem sur le modèle fort selon sources tierces, 20 Scribe/sem |
| Individual Pro | 15 $/mois (12 $/mois annuel = 144 $/an) | Modèle Frontier Pro illimité, mémoire de style |
| Team Pro | 12 $/seat (10 $ annuel), min 3 sièges | Admin, personnalisation d'équipe |
| Enterprise | Custom | SOC 2, HIPAA, zéro rétention |
| Réductions | Étudiants, éducateurs, nonprofits, vétérans | |

Nota : la structure du free tier diverge selon les sources (site : "unlimited weaker model" ; tierces : cap 2000 mots/sem). Les deux peuvent coexister (cap sur le bon modèle).

### (e) Positionnement & ICP
Copie assez frontale du positionnement Wispr ("voice is your new keyboard", 4x productivité) avec un angle mobile-first iOS. ICP : professionnels e-mail/docs/prompting, équipes.

### (f) Forces / faiblesses vs Verba
- **Forces** : vélocité YC + angels de renom ; clavier iOS avec édition vocale (pertinent vs l'app iOS Verba en cours) ; pricing team agressif.
- **Faiblesses** : différenciation faible vs Wispr (même pricing, mêmes promesses, moins de moyens) ; cloud, pas de BYOK, pas d'agent ; 7 personnes.
- **Lecture** : à surveiller surtout pour l'iOS keyboard UX, qui préfigure ce que l'app iOS de Verba devra égaler.

---

## 8. Acteurs secondaires et signaux de marché

### Monologue (Every Media Inc.)
- App de dictée de **Every** (média/studio produit), lancée le **23 septembre 2025** ([every.to](https://every.to/on-every/introducing-monologue-effortless-voice-dictation), [monologue.to](https://www.monologue.to/)). Mac + iOS.
- Différenciateur : **option de modèle local on-device** (rare dans le bloc cloud) + ton personnalisé par app ([TechCrunch](https://techcrunch.com/2026/05/02/the-best-ai-powered-dictation-apps-of-2025/)).
- Pricing : free 1000 mots/mois ; 10 $/mois early-bird (15 $ ensuite) ou ~100 $/an ; inclus dans l'abonnement Every à 30 $/mois (TechCrunch + [Voibe](https://www.getvoibe.com/resources/monologue-review/) ; le total exact du free tier diverge entre sources). Pas de lifetime.
- Menace modérée : distribution via l'audience du média Every, produit soigné, mais équipe non dédiée à 100 %.

### Typeless
- Équipe issue de Stanford (opérée via Simply CA LLC, Palo Alto, adossée à **StartX**), lancée **novembre 2025** ([spokenly review](https://spokenly.app/blog/typeless-review), [typeless.com](https://www.typeless.com/)) `[identité : source unique]`.
- **Mac, Windows, iOS, Android** (un des rares avec Android natif). Commandes vocales d'édition sur texte sélectionné ("make this shorter").
- Pricing : **free 8000 mots/semaine** (le free tier le plus généreux du bloc cloud), Pro 30 $/mois en mensuel ou 12 $/mois en annuel (144 $/an), essai Pro 30 j.
- Signal : la guerre du free tier est lancée (8000 mots/sem vs 2000 chez Wispr/Willow).

### Spokenly
- **Gratuit**, Mac/iPhone/Windows : modèles locaux Whisper + Parakeet sans limite, BYOK cloud sans markup, diarisation, transcription de fichiers, clavier iOS, et **intégration MCP avec les agents de code (Claude Code, Cursor)** ([spokenly.app](https://spokenly.app/), consulté 2026-07-14). Développeur non identifié publiquement.
- Machine à content marketing (des dizaines de comparatifs SEO "X vs Spokenly").
- Signal double : (1) commoditisation du cœur dictée locale ; (2) **premier pas du marché vers "voix → agent"** via MCP, même si limité aux outils de code. C'est le signal faible le plus proche de JARVIS observé chez les concurrents.

### Open source gratuit : Handy, OpenWhispr
- **Handy** (cjpais) : offline, push-to-talk, Whisper/Parakeet, Mac/Windows/Linux, verbatim brut, gratuit ([GitHub](https://github.com/cjpais/Handy), passé sur HN).
- **OpenWhispr** : local Parakeet/Whisper + BYOK, cross-platform, mentionne "agents" et meetings ([GitHub](https://github.com/OpenWhispr/openwhispr), [openwhispr.com](https://openwhispr.com/)).
- Signal : le STT local brut vaut 0 $. La valeur défendable est au-dessus (réécriture, modes, contexte, actions).

### Micro-apps SEO (à ne pas surestimer)
Voibe, Voicy, Weesper Neon Flow, BossAI, SpeakMac, LumeVoice, Embertype, TAWK, MetaWhisp, Dictaflow, Mumble, Utter, Voicescriber... Des dizaines de petites apps dont la stratégie principale est le comparison-SEO. Individuellement négligeables ; collectivement, elles saturent les SERP "best dictation app" : enjeu SEO réel pour verba.run.

### Baseline & incumbents
- **Dictée Apple** (gratuite, intégrée) : le vrai concurrent par défaut de tout le marché ; qualité de formatage faible, pas de réécriture. Risque de sherlocking via Apple Intelligence à horizon 1-2 ans.
- **Dragon (Microsoft/Nuance)** : incumbent legacy Windows/médical, cher, en perte de vitesse sur le desktop grand public. Non pertinent sur macOS moderne.
- **Talon Voice** : niche accessibilité/coding vocal, adjacent, pas un concurrent direct.

---

## 9. Tableau récapitulatif (consulté 2026-07-14)

| | **Wispr Flow** | **Superwhisper** | **MacWhisper** | **VoiceInk** | **Aqua Voice** | **Willow** | **Monologue** | **Typeless** | **Spokenly** | **Verba (réf.)** |
|---|---|---|---|---|---|---|---|---|---|---|
| Société | VC ~81 M$, valo ~2 Md$ en disc. | Indie bootstrapped (Toronto) | Indie (NL) | Indie open source | YC W24, 500 k$ | YC X25, 4,5 M$ | Every Media | StartX | Inconnu | Indie |
| STT | Cloud propriétaire | Whisper local + cloud | Whisper/Parakeet local | Whisper local (whisper.cpp) | Cloud propriétaire (Avalon) | Cloud ("Frontier") | Cloud + option locale | Cloud | Whisper/Parakeet local + BYOK | Local-first |
| Local / offline | Non | **Oui** | **Oui** | **Oui (100 %)** | Non | Partiel (option Mac/iOS) | Option on-device | Non | **Oui** | **Oui** |
| BYO-AI (clés/backends) | Non | Providers listés + BYOK | BYOK large + Ollama/LM Studio | BYOK | Non | Non | Non | Non | BYOK | **Backend libre** |
| Modes de réécriture custom | Styles limités | **Oui (prompts custom)** | Prompts custom | **Oui (Polish/Email/Chat/Post + custom)** | Instructions custom | Ton par app | Ton par app | Limité | AI Instructions | **Oui, éditables** |
| Contexte écran | Oui (cloud) | **Oui (Super Mode)** | Non | **Oui (+ clipboard)** | **Oui (+ code)** | Oui (app-aware) | Oui | n.d. | Non | **Oui (Context/vision)** |
| Édition vocale / commandes | Command Mode (texte, <1000 mots) | Non | Non | Non | Voice editing (texte) | Édition vocale iOS | Non | Commandes d'édition (texte) | Non | — |
| **Agent multi-apps (type JARVIS)** | **Non** | **Non** | **Non** | **Non** | **Non** | **Non** | **Non** | **Non** | Non (MCP code only) | **Oui (1000+ apps)** |
| Dictionnaire perso | Oui | Oui | n.d. | Oui + remplacements | 5 free / 800 Pro | Oui | n.d. | n.d. | Oui | Oui |
| Langues | 100+ | 100+ | 100+ | Multi | 49 | 100+ | n.d. | n.d. | 100+ | Selon backend |
| Plateformes | Mac/Win/iOS/Android | Mac/Win/iOS | Mac | Mac (iOS listé) | Mac/iOS (+Win selon sources) | Mac/Win/iOS (Android soon) | Mac/iOS | Mac/Win/iOS/Android | Mac/Win/iOS | Mac (iOS en cours) |
| Free tier | 2000 mots/sem | Modèles locaux illimités | Oui | Build from source | 1000 mots/mois | Modèle faible illimité | 1000 mots/mois | **8000 mots/sem** | **Tout gratuit** | — |
| Prix payant | 12-15 $/mois | ~8,49 $/mois ou 84,99 $/an | — | — | 8 $/mois (annuel) | 12-15 $/mois | 10-15 $/mois | 12 $/mois (annuel) | — | — |
| Lifetime | Non | **849 $** (ex-249,99 $) | **64 €** | **25-49 $** | Non | Non | Non | Non | — | — |
| Compliance | HIPAA-ready, SOC 2 (Ent.) | SOC 2 II, HIPAA | — | — | ZDR (Ent.) | SOC 2, HIPAA (Ent.) | — | — | — | — |

---

## 10. Synthèse stratégique pour Verba

1. **Le différenciateur défendable est JARVIS.** Aucun concurrent direct n'exécute d'actions multi-étapes hors du champ texte. Le marché converge vers "dictée + réécriture + un peu d'édition vocale" ; l'agent vocal d'action est un espace vide. Le seul signal faible adjacent est le MCP de Spokenly (agents de code). Communiquer Verba comme "dictée + agent", pas comme "une dictée de plus".
2. **Sur le cœur dictée, la parité avec Superwhisper/VoiceInk est le ticket d'entrée** : modes custom, contexte écran, dictionnaire, push-to-talk, offline. Tout y est déjà chez eux ; Verba ne gagnera pas sur ces features seules.
3. **Fenêtres de pricing** : la hausse du lifetime Superwhisper (249,99 → 849 $) laisse un boulevard entre 49 $ (VoiceInk) et 849 $. Un lifetime Verba raisonnable capte les déçus de l'abonnement ET les déçus de la hausse Superwhisper. Le free tier du bloc cloud (2000 mots/sem) est l'ancre mentale du gratuit ; Typeless attaque déjà à 8000 mots/sem.
4. **La privacy est un argument qui convertit**, prouvé par l'incident Wispr (backlash, apologie publique du CTO). Local-first + BYO-AI = "vos données ne financent le modèle de personne". C'est aussi la seule défense structurelle contre Wispr : ils ne peuvent pas suivre sans casser leur modèle.
5. **iOS** : Wispr, Willow (clavier avec édition vocale), Superwhisper, Aqua, Monologue, Typeless, Spokenly y sont déjà. L'app iOS Verba arrive sur un terrain occupé ; le levier différenciant y sera JARVIS mobile et la continuité Mac↔iPhone, pas la dictée seule.
6. **SEO** : les SERP de la catégorie sont saturées de comparatifs publiés par les concurrents. Prévoir des pages "Verba vs X" factuelles, sinon ce sont leurs pages qui définiront Verba.
7. **Veille à maintenir** (le marché bouge par trimestre) : levée Wispr à 2 Md$ (confirmation et usage des fonds), roadmap "agent" éventuelle chez Wispr/Aqua, vitesse d'absorption de features par VoiceInk (open source), sherlocking Apple (WWDC), consolidation des micro-apps.

---

*Rapport rédigé le 2026-07-14. Toutes les URLs citées ont été consultées à cette date. Les mentions `[source unique]` signalent les faits non cross-validés ; les divergences de prix constatées entre sources sont explicitées dans le corps du texte.*
