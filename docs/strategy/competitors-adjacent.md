# Étude concurrentielle : concurrents adjacents et menaces de plateforme

> **Projet** : Verba (verba.run), dictée macOS native menu-bar, local-first, BYO-AI, réécriture LLM par modes, + JARVIS (agent vocal multi-étapes sur 1000+ apps connectées).
> **Date** : 2026-07-14 · **Méthode** : WebSearch/WebFetch, sources primaires privilégiées, faits < 12 mois autant que possible, cross-validation ≥ 2 sources ou mention « source unique ».
> **Portée** : écosystème ADJACENT uniquement. Les concurrents directs (apps de dictée Mac : Wispr Flow, Superwhisper, VoiceInk, MacWhisper...) sont traités dans un rapport séparé ; Wispr Flow n'apparaît ici que sous l'angle de sa convergence agentic.
> **Échelle de menace** : Faible / Moyenne / Élevée, évaluée sur le recouvrement fonctionnel réel avec Verba (dictée at-cursor + modes LLM) et JARVIS (voix → action multi-apps), pondéré par la distribution et la trajectoire.

---

## Volet 1 : Dictée historique et accessibilité

### 1.1 Dragon (Nuance / Microsoft)

**Capacités et plateformes.** Dragon reste la référence historique de la reconnaissance vocale professionnelle (juridique, médical, administratif), avec vocabulaires spécialisés et commandes vocales. Mais le produit desktop grand public est **Windows-only et en fin de vie active** :

- **Dragon pour Mac : abandonné depuis le 22 octobre 2018.** Confirmation officielle Nuance ([Dragon Professional for Mac 6: End of life](https://nuance.custhelp.com/app/answers/detail/a_id/27843/~/dragon-professional-for-mac-6:-end-of-life,-end-of-support-dates), page support Nuance) ; corroboré par les pages produit Amazon marquées « Discontinued » et par la presse spécialisée ([Dictation Daddy, 2025-2026](https://www.dictationdaddy.com/blog/dragon-dictate-mac-os-x)). Il n'existe **aucun Dragon natif sur Mac à aucun prix**.
- **Dragon Professional (Windows) : ~699 $** licence perpétuelle, prix stable depuis 2023, soit environ +133 % vs le tarif historique de 299 $ ([Voibe, vérifié avril 2026](https://www.getvoibe.com/resources/dragon-pricing/) ; [Spokenly, 2026](https://spokenly.app/blog/dragon-dictation-pricing) : 2 sources concordantes). Le gel du développement desktop coïncide avec le rachat de Nuance par Microsoft (mars 2022, ~19,7 Md$).
- **Dragon Anywhere (mobile iOS/Android, 14,99 $/mois ou 149,99 $/an) : retiré de la vente au 1er juillet 2026**, nouveaux abonnements et renouvellements impossibles (avis de discontinuation affichés sur l'[App Store](https://apps.apple.com/us/app/dragon-anywhere/id1024652126) et [Google Play](https://play.google.com/store/apps/details?id=com.nuance.dragonanywhere&hl=en_US) : 2 sources).

**Trajectoire (< 12 mois).** Microsoft concentre tout l'actif Dragon sur la santé : **Dragon Copilot**, annoncé le 3 mars 2025, fusionne Dragon Medical One et DAX (ambient AI) en « premier assistant vocal IA unifié pour le clinique » ([communiqué Microsoft, 03/03/2025](https://news.microsoft.com/source/2025/03/03/microsoft-dragon-copilot-provides-the-healthcare-industrys-first-unified-voice-ai-assistant-that-enables-clinicians-to-streamline-clinical-documentation-surface-information-and-automate-task/) ; [Fierce Healthcare](https://www.fiercehealthcare.com/ai-and-machine-learning/microsoft-debuts-dragon-copilot-ai-clinical-assistant-nurses-expands-access) : 2 sources). Chiffres d'échelle revendiqués : 600+ organisations de santé, 3 M de conversations ambient/mois (communiqué Microsoft, source primaire). GA États-Unis/Canada en mai 2025, puis UK/Allemagne/France/Pays-Bas. En mai 2026, l'offre historique « Physician Practice » atteint la fin de commercialisation au profit de la marque Dragon Copilot (source unique : synthèse de recherche sur les pages Microsoft Marketplace).

**Base utilisateurs.** Historiquement des millions de licences desktop (juristes, médecins, accessibilité), mais aucun chiffre consumer récent publié ; la base Mac est orpheline depuis 2018 et la base mobile le devient en 2026.

**Menace pour Verba : FAIBLE (et opportunité nette).**
- Aucune présence macOS, aucun retour annoncé ; le consumer/prosumer est délaissé au profit du médical B2B.
- La discontinuation de Dragon Anywhere (juillet 2026) libère un segment de dictée professionnelle mobile/desktop qui cherche activement un remplaçant : les blogs d'alternatives Dragon 2026 pullulent, preuve d'une demande orpheline ([Voicy](https://usevoicy.com/blog/best-dragon-alternatives-2026), [Dictation Daddy](https://www.dictationdaddy.com/blog/dragon-dictation-alternative)).
- Seul risque résiduel : Microsoft ramenant la techno Dragon dans Windows/Office grand public via Copilot (voir volet 2), mais pas sur Mac.

### 1.2 Talon Voice

**Capacités et plateformes.** Contrôle total de l'ordinateur à la voix, bruits et regard (eye tracking) : dictée, clic, scroll, fenêtres, et surtout **voice coding** (référence absolue pour les développeurs avec RSI). Multi-plateforme (macOS, Windows, Linux), moteur de reconnaissance **on-device propriétaire, 100 % offline, sans abonnement pour la reconnaissance** ([talonvoice.com](https://talonvoice.com/), source primaire).

**Pricing et base.** Version publique gratuite ; beta privée réservée aux soutiens Patreon (paliers à partir de ~5 $/mois, accès beta autour de 15-25 $/mois selon les pages Patreon et le wiki communautaire ; source unique de qualité moyenne, chiffre exact non confirmé). Le Patreon finance un développeur unique à plein temps. Pas de chiffres publics de base utilisateurs ; communauté active mais de niche (accessibilité + voice coding).

**Trajectoire (< 12 mois).** Projet vivant et activement développé : beta 0.4.0 publiée le 16 décembre 2025 avec nouveau moteur on-device et reconnaissance 4-10× plus rapide (modèle Conformer b108) ([changelog beta officiel, 16/12/2025](https://talonvoice.com/update/qyO6k0Y0jHOeI94q51eTKV/Talon-115-0.4.0-1046-ac6a.html), source primaire ; [talon.wiki](https://talon.wiki/Help/beta_talon/)).

**Menace pour Verba : FAIBLE.**
- Cible orthogonale : commandes structurées et grammaires apprises (courbe d'apprentissage raide), pas de dictée naturelle réécrite par LLM, pas de modes, pas d'agent connecté à des services.
- Un développeur unique, pas de force de frappe commerciale.
- À surveiller comme **référence UX du voice computing offline** et comme standard de fait chez les développeurs accessibilité : si JARVIS vise un jour le voice coding ou l'accessibilité profonde, Talon est l'étalon (et la communauté à convaincre).

---

## Volet 2 : Menaces de plateforme (OS natif)

### 2.1 Apple : dictée macOS + Apple Intelligence / Siri AI

**Dictée native (état actuel).** macOS Tahoe (26), sorti le 15 septembre 2025, apporte la plus grosse mise à jour de la reconnaissance vocale Apple depuis des années : dictée on-device sur Apple Silicon (rapide, privée, offline pour les langues supportées), apprentissage local du vocabulaire. Les nouvelles APIs **SpeechAnalyzer / SpeechTranscriber** sont mesurées ~55 % plus rapides que Whisper d'OpenAI (benchmarks septembre 2025 ; sources secondaires convergentes : [Weesper, 10/2025](https://weesperneonflow.ai/en/blog/2025-10-27-voice-dictation-macos-tahoe-native-features-third-party-apps-2025/), [AI Dictation](https://aidictation.com/blog/macos-speech-to-text) ; le chiffre 55 % provient d'un benchmark tiers unique repris en chaîne, à considérer comme ordre de grandeur). Ces APIs sont aussi une **aubaine** : les apps tierces (dont Verba) peuvent s'appuyer dessus gratuitement.

**Siri AI (WWDC 2026, 8 juin 2026).** L'annonce plateforme la plus importante de l'année pour Verba :

- Nouveau Siri « profondément plus intelligent » : compréhension du contexte personnel, recherche cross-apps, réponses avec accès Internet, questions sur le contenu à l'écran, et « encore plus d'actions systemwide dans les apps » ([Apple Newsroom, 06/2026](https://www.apple.com/newsroom/2026/06/apple-unveils-next-generation-of-apple-intelligence-siri-ai-and-more/), source primaire).
- **App Intents devient l'unique voie d'intégration Siri pour les apps tierces** (SiriKit officiellement déprécié) : Siri peut exécuter des actions directement dans les apps tierces, y compris des tâches multi-étapes conversationnelles ([TechCrunch, 09/06/2026](https://techcrunch.com/2026/06/09/wwdc-2026-everything-announced-on-siri-ai-os-27-apple-intelligence-and-more/) ; [CNBC live, 08/06/2026](https://www.cnbc.com/2026/06/08/apple-wwdc-2026-live-updates.html) : 2 sources).
- App Siri autonome avec conversations persistantes synchronisées iCloud ([The Gadgeteer, 08/06/2026](https://the-gadgeteer.com/2026/06/08/apple-siri-ai-overhaul-unveiled-at-wwdc-2026-with-standalone-app/)).
- Intégré à iPhone, iPad, **Mac**, Watch, Vision Pro ; requiert macOS 27 ; **disponibilité automne 2026, beta anglais d'abord, pas de lancement initial dans l'UE** (pour iOS/iPadOS/watchOS) ni en Chine (Apple Newsroom, source primaire).

**Jusqu'où l'OS cannibalise-t-il ?**
- **Dictée brute : cannibalisation réelle et déjà effective** pour l'usage casual. La dictée Tahoe est « good enough », gratuite, offline. La presse spécialisée conclut toutefois que les pros (vocabulaire technique, formatage, réécriture) restent sur du tiers ([Weesper, 10/2025](https://weesperneonflow.ai/en/blog/2025-10-27-voice-dictation-macos-tahoe-native-features-third-party-apps-2025/), [machow2, 2026](https://machow2.com/best-dictation-software-mac/)).
- **Réécriture par modes : non couverte.** Apple Intelligence propose des Writing Tools génériques (proofread/rewrite) mais rien d'équivalent aux modes personnalisés, au BYO-AI, ni au contrôle du modèle.
- **Territoire JARVIS : c'est ici que la menace est la plus sérieuse.** Siri AI + App Intents est exactement « voix → action multi-apps », gratuit, au niveau OS. Limites structurelles : (1) dépend de l'adoption d'App Intents par chaque développeur d'app, là où JARVIS passe par des intégrations de services web (1000+) ; (2) exécution Apple historiquement lente et prudente (le Siri contextuel promis à la WWDC 2024 a glissé de ~2 ans) ; (3) automne 2026 au plus tôt, hors UE au lancement sur une partie des plateformes.

**Menace : ÉLEVÉE à horizon 12-24 mois** (moyenne aujourd'hui). Élevée sur JARVIS-dans-l'écosystème-Apple et sur l'entrée de gamme dictée ; faible sur la dictée pro à modes et le BYO-AI. C'est la menace de plateforme n°1 pour Verba puisqu'elle vit sur le même OS.

### 2.2 Windows : Voice Access, Fluid Dictation, « Hey Copilot » et Copilot Actions

**État actuel.**
- **Fluid Dictation** (2025, Copilot+ PCs) : dictée avec correction automatique de grammaire/ponctuation/mots de remplissage en temps réel, propulsée par des SLMs **on-device**, vocabulaire personnalisé, activée par défaut ([Microsoft Support](https://support.microsoft.com/en-us/accessibility/windows/voice-access/fluid-dictation), source primaire ; [Windows Experience Blog, récap accessibilité 2025, 03/12/2025](https://blogs.windows.com/windowsexperience/2025/12/03/2025-a-year-in-recap-windows-accessibility/)). C'est fonctionnellement un « Wispr-like » natif gratuit, limité aux locales anglaises et au hardware Copilot+.
- **Voice Access** : commandes en langage plus naturel (variantes multiples comprises), sur Copilot+ PCs (même source primaire Microsoft).
- **« Hey Copilot » + Copilot Voice** : wake word opt-in déployé aux Insiders le 14 mai 2025 ([Windows Insider Blog](https://blogs.windows.com/windows-insider/2025/05/14/copilot-on-windows-hey-copilot-begins-rolling-out-to-windows-insiders/), source primaire), généralisé lors de la vague d'octobre 2025 « making every Windows 11 PC an AI PC » ([Windows Experience Blog, 16/10/2025](https://blogs.windows.com/windowsexperience/2025/10/16/making-every-windows-11-pc-an-ai-pc/) ; [VentureBeat](https://venturebeat.com/ai/microsoft-launches-hey-copilot-voice-assistant-and-autonomous-agents-for-all) : 2 sources). Détection locale, traitement cloud.
- **Copilot Actions** : agent expérimental opt-in qui voit l'écran et exécute des tâches décrites en langage naturel dans les apps desktop et web, sous permissions ([Windows Experience Blog, 16/10/2025](https://blogs.windows.com/windowsexperience/2025/10/16/making-every-windows-11-pc-an-ai-pc/) ; [The Register, 16/10/2025](https://www.theregister.com/2025/10/16/microsoft_copilot_updates/) : 2 sources).

**Menace : MOYENNE (indirecte).** Verba est macOS-only : Windows ne cannibalise rien aujourd'hui. Mais : (1) Microsoft démontre que « voix + agent » devient une couche OS standard, ce qui ancre l'attente d'un équivalent gratuit chez tous les utilisateurs ; (2) si Verba envisage un jour un portage Windows, l'espace y est déjà plus densément occupé par l'OS que sur Mac ; (3) la dictée on-device Fluid Dictation plafonne le prix acceptable d'une dictée simple.

### 2.3 Android / Google : Gboard voice typing + Gemini

**État actuel et trajectoire.**
- Gboard « Assistant voice typing » devient « Advanced features » sur Pixel (avril 2025), avec UI repensée façon Gemini ([9to5Google, 09/04/2025](https://9to5google.com/2025/04/09/gboard-advanced-voice-typing-pixel/), [Android Police](https://www.androidpolice.com/gboards-new-voice-typing-ui/)).
- **« Rambler »** (annoncé le 12 mai 2026 avec « Gemini Intelligence ») : dictée propulsée par Gemini qui gère auto-corrections, répétitions, hésitations et « ums », et le code-switching multilingue dans une même phrase ; sortie été 2026 sur Pixel 10 et Galaxy S26 (exécution locale) ([9to5Google, 12/05/2026](https://9to5google.com/2026/05/12/gemini-intelligence-announcement/) ; [TechCrunch, 12/05/2026](https://techcrunch.com/2026/05/12/google-adds-gemini-powered-dictation-to-gboard-which-could-be-bad-news-for-dictation-startups/) : 2 sources). Le titre TechCrunch dit tout : « could be bad news for dictation startups ».
- Proofreading/rephrasing on-device via Gemini Nano v2 sur Pixel 9+ ([support Google](https://support.google.com/gboard/answer/11197787?hl=en), source primaire).

**Menace : FAIBLE-MOYENNE (signal, pas contact).** Aucun recouvrement direct (mobile Android vs desktop Mac). Mais Rambler est la démonstration la plus aboutie de la thèse « l'OS absorbe la dictée intelligente » : transcription + nettoyage LLM gratuits, on-device, par défaut dans le clavier. Si Apple réplique (probable, cf. Writing Tools + SpeechAnalyzer), la dictée simple sur Mac devient une commodité totale ; la valeur défendable se déplace vers les modes, le contexte pro et l'action (JARVIS).

---

## Volet 3 : Transcription et notes vocales (où s'arrête leur périmètre vs dictée at-cursor)

### 3.1 Otter.ai

**Capacités.** Transcription de réunions en temps réel (bot qui rejoint Zoom/Meet/Teams), résumés automatiques, action items, chat sur le corpus, et depuis 2025 des **« Meeting Agents »** spécialisés (Sales Agent : insights, e-mails de suivi, push Salesforce/HubSpot) ([otter.ai](https://otter.ai/), source primaire).

**Pricing.** Basic gratuit (300 min/mois), Pro 8,33 $/mois (annuel, 1 200 min), Business 19,99 $/user/mois (annuel), Enterprise sur devis ([otter.ai/pricing](https://otter.ai/pricing), source primaire ; [Sonix](https://sonix.ai/resources/otter-ai-pricing/) : 2 sources). Signal de pression sur les marges : Otter a réduit le plan Pro de 6 000 à 1 200 minutes sans baisser le prix ([tl;dv, 04/2026](https://tldv.io/blog/otter-pricing/), source unique).

**Périmètre vs Verba.** Otter vit **dans la réunion** : audio de call, corpus de transcripts, workflow post-meeting. Il ne s'installe pas au curseur, ne dicte pas dans n'importe quelle app, ne réécrit pas au fil de la frappe. **Menace : FAIBLE.** Convergence improbable : sa trajectoire va vers les agents de réunion B2B, pas vers l'input system-wide.

### 3.2 Granola

**Capacités et plateformes.** Notetaker « sans bot » : capture l'audio système du Mac, fusionne vos notes brutes avec la transcription pour produire des notes augmentées. iOS depuis avril 2025, **Windows depuis juin 2025** ([TechCrunch, 14/05/2025](https://techcrunch.com/2025/05/14/ai-note-taking-app-granola-raises-43m-at-250m-valuation-launches-collaborative-features/) ; [Nubia/recaps 2026](https://nubiapage.com/granola-ai-review-in-2026-windows-android-founder-funding-ai/)).

**Trajectoire capitalistique, la vraie info.** Series B de 43 M$ à 250 M$ de valo (mai 2025, NFDG), puis **Series C de 125 M$ à 1,5 Md$ de valorisation le 25 mars 2026** (Index Ventures), avec un repositionnement explicite : de « meeting notetaker » vers **« enterprise AI app » qui transforme les réunions en mémoire/contexte d'entreprise** ([TechCrunch, 25/03/2026](https://techcrunch.com/2026/03/25/granola-raises-125m-hits-1-5b-valuation-as-it-expands-from-meeting-notetaker-to-enterprise-ai-app/) ; [Bloomberg, 25/03/2026](https://www.bloomberg.com/news/articles/2026-03-25/ai-notetaker-granola-hits-1-5-billion-value-in-125-million-funding) : 2 sources). ×6 de valo en 10 mois.

**Périmètre vs Verba.** Même ADN Mac-native et discret que Verba, mais orienté capture passive de réunions, pas input actif at-cursor. **Menace : MOYENNE.** Pas de recouvrement produit aujourd'hui, mais (1) un war chest de 168 M$ levés en un an, (2) une expansion revendiquée au-delà des meetings (« contexte d'entreprise »), (3) une base d'utilisateurs Mac prosumer identique à la cible Verba. Une feature « dictée/commande vocale Granola » serait une extension naturelle de leur position.

### 3.3 Notion AI Meeting Notes (et suites bureautiques)

**Capacités.** Depuis mai 2025, Notion intègre nativement la transcription de réunions : capture de l'audio système sans bot, résumé + action items sur une page Notion, identification des locuteurs ; version navigateur (micro seul) depuis novembre 2025, transcription en arrière-plan sur mobile depuis janvier 2026 ([TechCrunch, 13/05/2025](https://techcrunch.com/2025/05/13/notion-takes-on-ai-notetakers-like-granola-with-its-own-transcription-feature/) ; [Notion Help Center](https://www.notion.com/help/ai-meeting-notes) et [notes de release](https://www.notion.com/releases), sources primaires).

**Périmètre vs Verba.** La voix de Notion s'arrête aux frontières de Notion : c'est de la capture de réunion dans un workspace, pas de la dictée universelle. **Menace : FAIBLE-MOYENNE.** Le risque est générique : chaque suite (Notion, Google Workspace, Microsoft 365, Slack) internalise « la voix dans son silo », réduisant les occasions d'usage d'un outil transversal chez les utilisateurs mono-suite. Mais c'est précisément la fragmentation que Verba (at-cursor, toutes apps) résout.

**Conclusion du volet 3.** La catégorie transcription/notes converge vers : capture passive de réunions + agents post-meeting + « mémoire d'entreprise ». Personne n'y fait de la dictée at-cursor system-wide. La frontière est nette aujourd'hui ; le seul acteur avec les moyens et l'ADN desktop pour la franchir est Granola.

---

## Volet 4 : Agents vocaux et voice-first computing émergents (le territoire JARVIS)

### 4.1 OpenAI : ChatGPT desktop, Agent mode, ChatGPT Work, GPT-Realtime-2

**Capacités actuelles sur Mac.**
- L'app macOS « Work with Apps » lit et édite le contenu d'apps tierces (IDEs, terminaux, Notes), y compris pendant l'Advanced Voice Mode ([OpenAI Help Center](https://help.openai.com/en/articles/10119604-work-with-apps-on-macos), source primaire ; [VentureBeat](https://venturebeat.com/ai/chatgpt-adds-more-pc-and-mac-app-integrations-getting-closer-to-piloting-your-computer)).
- **ChatGPT Agent est disponible dans l'app Mac** (abonnés Plus) : « ChatGPT qui pense et agit, choisissant dans une boîte à outils de skills agentic pour accomplir des tâches sur son propre ordinateur » ([TechRadar](https://www.techradar.com/ai-platforms-assistants/chatgpt/your-mac-just-got-smarter-openai-has-added-chatgpt-agent-to-its-mac-app) ; [Yahoo Tech](https://tech.yahoo.com/ai/articles/chatgpt-agent-lands-mac-now-153413850.html) : 2 sources).
- **ChatGPT Work (9 juillet 2026)** : agent avec Codex intégré qui « accomplit des tâches sur web, mobile et desktop en utilisant les informations de vos apps », multi-étapes, planifiable, accès aux fichiers locaux et aux applications ; app desktop unifiée Mac/Windows ; lancé pour Pro/Enterprise/Edu puis Plus/Business ; propulsé par GPT-5.6 ([MacRumors, 09/07/2026](https://www.macrumors.com/2026/07/09/openai-chatgpt-work/), source secondaire proche de l'annonce ; source unique détaillée à ce jour, annonce très récente).
- **Voix** : le mode vocal a été retiré de l'app macOS au 15 janvier 2026 (maintenu sur web, iOS, Android, Windows) ([9to5Mac, 19/12/2025](https://9to5mac.com/2025/12/19/chatgpt-voice-mode-retiring-on-macos-app/)). En parallèle, OpenAI a lancé en mai 2026 **GPT-Realtime-2**, premier modèle vocal « GPT-5-class reasoning » capable d'appeler des outils pendant que l'utilisateur parle ([AssemblyAI, 2026](https://www.assemblyai.com/blog/voice-ai-in-2026-series-1), source unique), et GPT-Live pour la conversation naturelle (MacRumors, ibid.).

**Menace : ÉLEVÉE.** OpenAI assemble une à une les briques de JARVIS : agent desktop multi-apps (Work), raisonnement vocal temps réel avec tool-calling (Realtime-2), distribution de centaines de millions d'utilisateurs. Le retrait de la voix de l'app macOS montre que voix-desktop n'est pas encore leur priorité produit, c'est la fenêtre de Verba. Mais la convergence « je parle, ChatGPT agit sur mon Mac » est une question de trimestres, pas d'années. Contre-arguments structurels pour Verba : cloud-only, pas at-cursor, pas local-first, générique plutôt que spécialisé dictée pro.

### 4.2 Anthropic : Claude Cowork

**Capacités.** Research preview lancée le 12 janvier 2026 : « computer agent » desktop pour non-développeurs qui ouvre des apps, navigue, remplit des feuilles de calcul ([CNBC, 24/03/2026](https://www.cnbc.com/2026/03/24/anthropic-claude-ai-agent-use-computer-finish-tasks.html) ; [Aragon Research](https://aragonresearch.com/anthropic-claude-cowork/) : 2 sources). Depuis le 7 juillet 2026 : extension web + mobile (beta, plan Max), avec **sessions distantes hébergées** qui continuent à travailler appareil éteint, tâches planifiées, et « Dispatch » (assigner des tâches à l'agent depuis le téléphone) ([Fingerlakes1, 09/07/2026](https://www.fingerlakes1.com/2026/07/09/claude-cowork-ai-agent-launches-as-anthropic-expands-ai-assistant-to-cloud-and-mobile/) ; [NBC News](https://www.nbcnews.com/tech/tech-news/anthropic-will-make-claude-cowork-available-users-cloud-rcna353218) : 2 sources).

**Menace : MOYENNE-ÉLEVÉE.** Recouvrement direct avec la promesse JARVIS (tâches multi-étapes cross-apps) mais **pas voice-first** : l'interface est texte/chat d'abord. Le danger est différent : Cowork banalise l'idée d'agent desktop et fixe les attentes de fiabilité. Si Anthropic ajoute une couche vocale, le recouvrement devient frontal. À noter : Verba en BYO-AI peut aussi consommer les modèles Claude, la relation est autant fournisseur que concurrent.

### 4.3 VoiceOS (WakoAI, YC X25)

**Capacités.** Le concurrent adjacent le plus proche du couple Verba+JARVIS : assistant vocal **Mac et Windows** combinant dictée contextuelle, commandes cross-apps, Q&A sur l'écran, édition de texte, et un **agent mode avec intégrations OAuth (Gmail, Calendar, Slack) qui enchaîne des commandes multi-apps** ([voiceos.com](https://www.voiceos.com/), source primaire ; [MakerStack review 2026](https://makerstack.co/reviews/voiceos-review/)). Positionnement revendiqué : « thought-to-action software », un « Voice Operating System » ([blog VoiceOS, 05/2026](https://www.voiceos.com/blog/voice-operating-system-thought-to-action)).

**Pricing.** Gratuit jusqu'à 100 utilisations/semaine ; Pro 12 $/mois (annuel) illimité ; Enterprise custom (MakerStack + pages produit : 2 sources). Backing : Y Combinator batch X25, fondateurs ex-voice AI ([Crunchbase](https://www.crunchbase.com/organization/voiceos)).

**Menace : ÉLEVÉE.** Recouvrement quasi total du positionnement (dictée + agent vocal desktop), pricing agressif, vélocité startup YC. Différenciateurs restants de Verba : local-first/BYO-AI (VoiceOS est cloud), modes de réécriture personnalisés, profondeur d'intégrations (1000+ vs 3 OAuth citées), ancrage menu-bar Mac natif. C'est l'acteur à monitorer en continu (releases, intégrations, traction Product Hunt/X).

### 4.4 Fazm et la vague open-source

**Capacités.** Agent vocal open-source, **local-first, macOS** : toolbar flottante, push-to-talk, exécution d'actions réelles à l'écran ([fazm.ai](https://fazm.ai/blog/best-ai-agents-desktop-automation-2026), source primaire ; source unique). **Menace : FAIBLE-MOYENNE.** Traction inconnue, mais l'existence d'un équivalent open-source gratuit sur le créneau exact « voix → action locale sur Mac » (1) valide la catégorie, (2) érode le pricing power sur les features de base, comme MacWhisper/VoiceInk l'ont fait pour la dictée Whisper.

### 4.5 Wispr Flow (angle convergence uniquement)

Concurrent direct sur la dictée (traité ailleurs), mais sa trajectoire capitalistique en fait une menace adjacente sur le territoire JARVIS : 81 M$ levés au total avec l'ambition affichée de « construire le Voice OS » ([wisprflow.ai/new-funding](https://wisprflow.ai/new-funding), source primaire), puis **discussions pour ~260 M$ à ~2 Md$ de valorisation (mai 2026)** ([AI CERTs News](https://www.aicerts.ai/news/wispr-flows-2b-voice-ai-funding-push/), [Weesper, 19/05/2026](https://weesperneonflow.ai/en/blog/2026-05-19-wispr-flow-2-billion-valuation-voice-ai-market-2026/) : 2 sources secondaires, tour non confirmé officiellement). Un « command mode » existe déjà. **Menace : ÉLEVÉE** : c'est l'acteur financé pour transformer la dictée en couche d'action vocale universelle, exactement la thèse JARVIS, avec 12-18 mois de runway médiatique et commercial d'avance. Faiblesse exploitable : cloud-centric (pas local-first, pas BYO-AI).

### 4.6 Signaux de marché transverses

- Google « Antigravity 2.0 » (I/O 2026) : plateforme agent-first avec app desktop et **voix native via les modèles audio Gemini** (source unique : [blog VoiceOS](https://www.voiceos.com/blog/voice-operating-system-thought-to-action), à re-vérifier sur sources primaires Google).
- Marché de la reconnaissance vocale : 18,39 Md$ (2025) → 61,71 Md$ projetés (2031), CAGR 22,4 % ([AssemblyAI, 2026](https://www.assemblyai.com/blog/voice-ai-in-2026-series-1), source unique).
- a16z classe les voice agents parmi ses thèses d'investissement majeures ([a16z, 2025](https://a16z.com/ai-voice-agents-2025-update/)), essentiellement B2B téléphonie, mais le débordement vers le consumer desktop a commencé (YC X25 : VoiceOS).

---

## Synthèse

### Les 3 menaces structurelles

**1. L'OS absorbe la dictée « good enough » (horizon : maintenant → 12 mois).**
Apple (Tahoe on-device, SpeechAnalyzer), Microsoft (Fluid Dictation on-device) et Google (Gboard Rambler avec nettoyage Gemini local, été 2026) rendent la dictée simple gratuite, privée et par défaut. TechCrunch le formule frontalement : « bad news for dictation startups ». Conséquence : la dictée brute ne peut plus être la proposition de valeur ; elle est le pied dans la porte. La valeur défendable de Verba est au-dessus : modes de réécriture personnalisés, BYO-AI, vocabulaire pro, at-cursor partout, et l'action (JARVIS).

**2. Les géants IA transforment le desktop en surface agentic, et finiront par y brancher la voix (horizon : 6-18 mois).**
ChatGPT Work (07/2026), Claude Cowork (01-07/2026), Copilot Actions (10/2025) et Siri AI + App Intents (automne 2026) attaquent tous « je décris une tâche, l'ordinateur l'exécute ». Aucun n'est encore voice-first sur le desktop (OpenAI a même retiré la voix de son app Mac), mais les briques vocales existent (GPT-Realtime-2, GPT-Live, Gemini audio). Le jour où l'un d'eux soude voix temps réel + agent desktop, JARVIS affronte un produit gratuit ou inclus dans un abonnement existant, avec une distribution incomparable. C'est la menace existentielle de moyen terme sur JARVIS pris isolément.

**3. La convergence dictée → action des startups financées (horizon : déjà en cours).**
Wispr Flow (~2 Md$ de valo en discussion, ambition « Voice OS »), VoiceOS (YC, agent mode cross-apps à 12 $/mois), Fazm (open-source local) : la catégorie « thought-to-action » se structure en ce moment même. La course se joue sur trois axes : profondeur d'intégrations, fiabilité d'exécution, et confiance (local/cloud). Verba part avec un vrai atout différenciant (local-first + BYO-AI + 1000+ intégrations) mais sans le capital des deux premiers.

### Fenêtres d'opportunité

1. **Les orphelins Dragon (immédiat, très qualifié).** Dragon Mac mort depuis 2018, Dragon Anywhere retiré au 1er juillet 2026, Dragon Professional à 699 $ Windows-only : les professionnels de la dictée (juridique, médical hors hôpital, accessibilité) cherchent une maison sur Mac. Contenu SEO « Dragon alternative Mac », vocabulaires spécialisés et commandes de correction vocale seraient les crochets naturels ; c'est un segment qui paie déjà 15 $/mois ou 699 $ sans sourciller.
2. **Local-first + BYO-AI comme fossé (durable).** Siri AI est privé mais fermé et lent à s'ouvrir ; ChatGPT/Copilot/Wispr/VoiceOS sont cloud. Verba est le seul récit « vos données ne quittent pas votre Mac, votre clé, votre modèle », décisif pour juristes, médecins, finance, UE (d'autant que Siri AI n'arrive pas dans l'UE au lancement sur une partie des plateformes).
3. **Les modes de réécriture personnalisés, angle mort universel.** Ni les OS (Writing Tools génériques), ni les notetakers (résumé de réunion), ni les agents (exécution de tâches) ne font « ma voix brute → mon texte, dans mon style, selon le contexte de l'app ». C'est le cœur défendable de Verba ; il faut le creuser (modes par app, par destinataire, par langue) plus vite qu'Apple n'élargit Writing Tools.
4. **Fenêtre JARVIS : 12-24 mois pour prendre la profondeur avant les plateformes.** Siri AI dépendra de l'adoption App Intents app par app ; Copilot Actions et Cowork sont lents, prudents, cloud. JARVIS peut gagner sur la largeur immédiate (1000+ services web dès aujourd'hui), la latence voix locale, et les workflows composés spécifiques aux power users Mac. L'objectif stratégique : être déjà « l'agent vocal des pros Mac » avec des workflows installés (coûts de changement) quand les plateformes livreront leur version générique.
5. **Accessibilité (adjacence Talon).** Un JARVIS fiable à la voix est aussi une techno d'assistance. Le segment RSI/handicap moteur est mal servi entre Talon (puissant mais austère) et les dictées simples ; c'est un marché à la fois éthique, fidèle et prescripteur.

### Tableau récapitulatif des menaces

| Acteur | Territoire | Menace | Justification en une ligne |
|---|---|---|---|
| Dragon/Nuance (Microsoft) | Dictée pro | **Faible** | Mac abandonné (2018), mobile retiré (07/2026), pivot santé B2B ; réservoir d'utilisateurs orphelins |
| Talon Voice | Accessibilité / voice coding | **Faible** | Niche experte orthogonale, 1 dev, pas de LLM rewriting ni d'agent connecté |
| Apple (dictée Tahoe) | Dictée casual | **Moyenne** | Good enough gratuit on-device ; épargne le pro (modes, vocabulaire, at-cursor riche) |
| Apple (Siri AI, macOS 27) | Voix → action | **Élevée (12-24 mois)** | Multi-étapes + App Intents au niveau OS, gratuit ; limité par l'adoption dev et l'exécution Apple |
| Microsoft (Fluid Dictation, Hey Copilot, Actions) | Dictée + agent Windows | **Moyenne (indirecte)** | Pas sur Mac ; fixe les attentes « voix+agent gratuit dans l'OS » et bouche un futur portage |
| Google (Gboard Rambler) | Dictée mobile | **Faible-moyenne** | Mobile only, mais démontre la commoditisation de la dictée nettoyée par LLM |
| Otter.ai | Meetings | **Faible** | Enfermé dans la réunion, trajectoire agents B2B, jamais at-cursor |
| Granola | Meetings → contexte entreprise | **Moyenne** | 1,5 Md$ de valo, ADN Mac prosumer identique, expansion au-delà des meetings financée |
| Notion AI Meeting Notes | Voix dans le silo Notion | **Faible-moyenne** | Capture de réunion in-workspace ; risque générique des suites qui internalisent la voix |
| OpenAI (ChatGPT Work, Agent, Realtime-2) | Agent desktop + voix | **Élevée** | Toutes les briques de JARVIS existent chez eux ; il ne manque que la soudure voix-desktop |
| Anthropic (Claude Cowork) | Agent desktop | **Moyenne-élevée** | Frontal sur l'agentic multi-apps mais pas voice-first ; aussi fournisseur BYO-AI de Verba |
| VoiceOS (WakoAI) | Dictée + agent vocal Mac/Win | **Élevée** | Recouvrement quasi total, YC, 12 $/mois ; cloud-only = angle d'attaque pour Verba |
| Fazm (open-source) | Agent vocal local Mac | **Faible-moyenne** | Valide la catégorie et pèse sur les prix ; traction inconnue |
| Wispr Flow (angle agentic) | « Voice OS » | **Élevée** | ~2 Md$ en discussion pour exécuter la thèse JARVIS à grande échelle ; cloud-centric |

---

*Rapport produit le 2026-07-14 (worker Telos). Les faits marqués « source unique » ou « non confirmé » sont à re-vérifier avant toute décision engageante ; les annonces de juillet 2026 (ChatGPT Work, Cowork web/mobile) sont très récentes et leur périmètre réel reste à observer en usage.*
