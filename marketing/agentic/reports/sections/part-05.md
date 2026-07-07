## Partie 05. Funnel et canaux, du premier contact au client

Avant de choisir un canal, il faut diagnostiquer la machine telle qu'elle existe aujourd'hui. Verba a un message clair (Partie 04), une offre freemium honnête (33 dictées gratuites, aucune carte requise) et un objectif chiffré en paliers de clients plutôt qu'en revenu abstrait : 100 payants (environ 760 EUR/mois), puis 500 (environ 3 800 EUR/mois), puis 1 000 (environ 7 600 EUR/mois), plafond visé 2 000 (environ 15 200 EUR/mois). Ce qui manque encore, c'est l'architecture qui fait descendre un inconnu depuis la découverte jusqu'à l'abonnement, puis le transforme en source du client suivant. C'est l'objet de cette Partie.

### Diagnostic : où saigne le système aujourd'hui

Verba n'a pas encore de trafic réel à grande échelle : le diagnostic n'est donc pas "où fuit le seau" au sens strict d'un produit déjà en croissance, mais "où fuira le seau si on ouvre le robinet sans préparer les étages en aval". C'est le cas le plus favorable pour appliquer la doctrine AARRR : corriger l'entonnoir avant de payer pour le remplir.

| Étage AARRR | État constaté | Lecture |
|---|---|---|
| Acquisition | Encore à zéro (pré-lancement), objectif 1 430 téléchargements pour atteindre 100 payants | Le canal n'est pas le problème actuel : c'est le sujet du mois 1 |
| Activation | Non mesurée : pas de tunnel "premier wow" formalisé sur les 33 dictées gratuites | Risque numéro un. Un utilisateur qui n'atteint pas un résultat propre dans sa première minute ne reviendra pas |
| Rétention | Non mesurée, pas encore de cohortes | À instrumenter dès le lancement, avant tout achat média |
| Referral | Boucles codées (parrainage "Free Month", classement public) mais invisibles dans le produit | Actif dormant : un mécanisme de croissance déjà construit et non exploité |
| Revenue | Conversion cible 7 % gratuit vers payant, marge quasi totale (aucun coût d'inférence, l'IA est celle que l'utilisateur paie déjà) | Économie très saine si l'activation tient |

**Le vrai goulot n'est pas l'acquisition, c'est l'activation.** Verba peut se permettre de dépenser 0 EUR en publicité pour les 100 premiers clients (philosophie budgétaire assumée), précisément parce que la priorité n'est pas de remplir le haut de l'entonnoir mais de garantir que les 33 dictées gratuites livrent le "aha moment" à tous les coups : parler dans le micro et voir un texte propre, prêt à envoyer, apparaître là où était le curseur. Tant que ce moment n'est pas fiabilisé et mesuré, verser du trafic dessus revient à payer pour accélérer la fuite, exactement l'erreur que la doctrine nomme.

Classification Owned / Earned / Paid actuelle : 100 % du plan des mois 1 à 2 repose sur de l'Owned (build-in-public du fondateur, la boucle de partage de clip, la liste email à construire) et de l'Earned (Product Hunt, Show HN, communautés). La dépendance au Paid est nulle jusqu'au palier 500, puis limitée à du retargeting à 10-15 EUR/jour une fois la conversion prouvée. C'est la trajectoire saine que décrit la doctrine : le payant n'arrive qu'après que l'actif possédé existe, jamais à sa place.

### Le funnel TOFU/MOFU/BOFU appliqué aux personas Verba

Chaque persona de Verba entre dans le funnel avec un niveau de conscience différent, et l'erreur la plus chère serait d'envoyer tout le monde vers la même page d'accueil demandant un essai. Le tableau ci-dessous applique les cinq niveaux de conscience d'Eugene Schwartz à chaque segment.

| Persona | TOFU (inconscient du problème) | MOFU (compare des solutions) | BOFU (prêt, lève le dernier frein) |
|---|---|---|---|
| Développeur Claude Code | Ne réalise pas qu'il tape deux fois ce qu'il vient de penser à voix haute en travaillant | Compare les apps de dictée Mac (cloud vs local vs Verba) | Veut la preuve que ça marche avec l'abonnement Claude Code qu'il paie déjà |
| Pro privacy-first (avocat, médecin, fondateur) | Ne sait pas qu'une alternative locale existe à la dictée cloud qu'il évite par prudence | Cherche "confidentiel" et "sur mon Mac uniquement" | Veut la certitude que rien ne quitte la machine avant de dicter une note sensible |
| Opérateur voix-first (fondateur, PM) | Sait qu'il perd du temps sur les suivis, ne sait pas qu'un agent vocal peut les exécuter | Compare "juste transcrire" contre "transcrire et agir" | Veut voir l'étape Confirm avant de laisser un agent toucher à sa messagerie |
| Travailleur multilingue | Ne sait pas qu'un outil peut penser dans sa langue et écrire dans une autre | Compare les outils de traduction en direct vs dictée classique | Veut vérifier la fidélité de traduction sur son propre jargon |
| Preneur de notes long-format | Ne sait pas qu'une heure de parole peut devenir un document propre sans reprise manuelle | Compare avec les outils de transcription de réunion classiques | Veut voir un exemple avant/après sur un vrai monologue d'une heure |

Exemple de copy TOFU pour le développeur (article ou thread, lecteur froid, aucune vente) :

> "You already think out loud when you code. The bug is that half of it never makes it into the terminal."

Exemple de copy MOFU pour le pro privacy-first (comparatif, lecteur qui compare) :

> "Cloud dictation sends your words to a server before you've even finished the sentence. Verba doesn't. Your voice, and even the planning of what it should do next, stay on your Mac."

Exemple de copy BOFU (page de conversion, lecteur chaud, le seul moment où on demande l'action) :

> "Try it free. 33 dictations, no card. If it doesn't save you a rewrite in the first five minutes, it wasn't worth your time."

Le principe à ne jamais violer : aucune de ces trois accroches n'est interchangeable. Envoyer le thread TOFU du développeur directement vers "Start your trial" serait demander en mariage au premier rendez-vous.

### AARRR, le funnel pirate, appliqué à Verba

| Étage | Question | Mécanisme Verba | Action prioritaire |
|---|---|---|---|
| Acquisition | Comment on te trouve | Build-in-public, Product Hunt, Show HN, comparaisons SEO/GEO | Mois 1 : lancement, pas de budget payant |
| Activation | Premier succès réel | Les 33 dictées gratuites doivent produire un texte propre, envoyé, dès la première minute | Instrumenter un événement "premier texte propre livré" avant tout autre chantier |
| Rétention | Reviennent-ils | Usage quotidien du mode Raw/Polish, Voice Notes pour les longs formats | Suivre la cohorte à 7 jours et 30 jours dès le lancement |
| Referral | En parlent-ils | Parrainage "Free Month" et classement public déjà codés mais invisibles | Rendre visibles ces deux mécanismes dans le produit avant le palier 500 |
| Revenue | Paient-ils, montent-ils en gamme | Conversion gratuit vers payant ciblée à 7 %, marge quasi totale | Founder tier à durée limitée comme levier de lancement, jamais de fausse rareté sur sa disponibilité réelle |

### Owned / Earned / Paid : qui possède le robinet

Verba part avec zéro liste email, zéro audience acquise, mais un canal de diffusion déjà construit : 16 comptes organiques connectés (X @verba_run, LinkedIn, Instagram, TikTok, YouTube, Threads, Facebook, Pinterest, Telegram, Reddit u/VerbaRun, entre autres) alimentés par un moteur de contenu quotidien qui génère image et légende à partir d'un calendrier de 90 jours. C'est un actif Owned rare pour un stade aussi précoce, à condition qu'il serve à construire une vraie relation et pas seulement à publier dans le vide.

**La priorité numéro un du trimestre : la liste email.** La doctrine est explicite, c'est l'actif Owned le plus sous-coté : personne ne peut la retirer à Verba, contrairement à un algorithme de plateforme. Le lead magnet le plus aligné sur le problème TOFU de l'ICP développeur : un guide court "5 phrases vocales qui remplacent un raccourci clavier" capturé en échange d'une adresse email, distribué depuis le contenu organique existant.

Calcul de dépendance : au lancement, 0 % du trafic prévu vient du payant (budget 0 EUR jusqu'à 100 clients). C'est l'inverse du problème que la doctrine met en garde : ici il n'y a pas de sur-dépendance au payant à corriger, il y a un actif Owned à construire avant que le payant n'entre en jeu au palier 100-500, en position d'amplificateur d'un moteur déjà validé, jamais en remplacement.

### Le test de product-channel fit, produit par produit

Verba est un produit unique mais avec cinq segments dont l'ACV effectif, la fréquence d'usage et la viralité naturelle diffèrent. Appliquer le principe de Brian Balfour : on ne choisit pas un canal par mode, on découvre celui que l'usage réel impose.

| Segment | Prix moyen perçu | Fréquence d'usage | Viralité naturelle | Canal structurellement viable |
|---|---|---|---|---|
| Développeur Claude Code | Faible, marge quasi totale (pas de double facture IA) | Quotidienne, intégrée au flux de travail | Forte : partage naturel de clips "j'ai dit, ça l'a fait" dans les communautés dev | Communauté (Show HN, r/ClaudeAI), build-in-public, boucle de partage |
| Pro privacy-first | Faible à moyen | Quotidienne à hebdomadaire selon le métier | Faible spontanément, mais forte crédibilité si un pair recommande | Contenu ciblé (confidentialité), earned via presse spécialisée, bouche-à-oreille professionnel |
| Opérateur voix-first | Faible | Quotidienne, multi-app | Moyenne : dépend de la mise en avant du résultat concret (email envoyé, ticket créé) | Comparaisons SEO/GEO ("dictée qui agit"), démonstrations courtes |
| Multilingue | Faible | Variable | Moyenne, forte dans les communautés de migrants professionnels | Contenu ciblé par langue, communautés locales |
| Preneur de notes long-format | Faible | Hebdomadaire | Faible spontanément | Contenu avant/après, SEO sur "transcription réunion propre" |

Le produit est le même, à un prix d'entrée faible pour tous les segments : cela élimine structurellement l'outbound et le paid lourd comme canaux de démarrage, un ACV aussi bas ne supporte pas un coût d'acquisition commercial humain. Le fit naturel de Verba est le contenu à coût marginal quasi nul, la communauté et la boucle de partage, exactement la lecture que fait déjà le playbook de croissance calqué sur Cursor, Lovable, Replit et Higgsfield.

### Le Bullseye : trois canaux à tester, un actif Owned à installer en premier

Suivant Gabriel Weinberg, l'anneau du milieu ne sert pas à trouver le canal parfait du premier coup mais à mesurer, à coût borné, lequel a un vrai potentiel avant d'y mettre tout le poids.

| Candidat | Test borné | Critère de succès chiffré | Fenêtre |
|---|---|---|---|
| Boucle de partage "I said it, it did it" (clip de fin avec mention "Made with Verba") | 20 à 50 créateurs semés avec licence à vie gratuite, un défi hebdomadaire de clips | Au moins 5 clips organiques repartagés sans sollicitation directe en semaine 4 | 6 semaines (canal composé) |
| Communauté et lancement (Show HN, r/ClaudeAI, r/macapps, Product Hunt) | Un lancement coordonné fin juillet, réponses actives du fondateur dans les fils pendant 48h | Top 5 Product Hunt du jour ou fil Show HN au-delà de 50 points | Fenêtre de lancement unique, jugée sur ce pic puis relais organique à 4 semaines |
| Comparaisons SEO/GEO (pages /vs et /compare, 24 concurrents x 10 variantes) | Publication des 20 premières pages, suivi des citations dans les réponses IA (ChatGPT, Perplexity, AI Overviews) | Trafic organique mesurable ou première citation IA détectée en semaine 8 | 3 à 6 mois (canal composé, ne pas juger avant) |

Actif Owned numéro un à installer cette semaine, avant tout le reste : la capture email via le lead magnet aligné sur le problème TOFU du développeur. Tout le trafic généré par les trois candidats ci-dessus doit remplir ce réservoir, pas seulement passer devant un bouton d'essai.

### Le growth loop, pas le growth hack

Le playbook cité (Cursor, Lovable, Replit, Higgsfield) ne décrit pas des astuces isolées mais des boucles structurelles où chaque utilisateur en amène un autre : le badge "Built with Lovable", les clips de vibe-coding de Replit, les 3 milliards d'impressions générées par les vidéos des utilisateurs de Higgsfield. Verba a déjà deux mécanismes de ce type codés (parrainage "Free Month", classement public à 100 niveaux) mais invisibles dans le produit, et il lui manque le mécanisme le plus prioritaire selon le brief : la boucle de partage de clip elle-même. C'est un loop, pas un hack, parce qu'il est intégré au produit et se reproduit sans intervention du fondateur à chaque nouvel utilisateur qui filme son propre "j'ai dit, ça l'a fait".

Deux erreurs à éviter explicitement pour Verba :

**Ne pas copier le canal visible de Wispr Flow.** Wispr Flow lève à une valorisation proche de 2 milliards de dollars et peut se permettre du payant massif après des années de funnel rodé et une LTV prouvée. Copier ce canal au même stade que Verba, sans budget ni funnel équivalents, brûlerait du cash pour un résultat invisible. Le canal de démarrage de Verba n'est pas celui que montre un concurrent mature.

**Ne pas abandonner les canaux composés avant la fenêtre honnête.** Le SEO/GEO et la communauté sont plats pendant des mois avant de décoller. La fenêtre fixée ci-dessus (3 à 6 mois pour les comparaisons, 6 semaines pour la boucle de partage) doit être respectée jusqu'au bout avant tout jugement, y compris si les premières semaines semblent silencieuses.

### Routage vers l'exécution

Cette Partie décide l'architecture, elle ne l'exécute pas. Les prochaines étapes se répartissent ainsi :

- **/mk-lead-magnets** pour concevoir le lead magnet email du développeur Claude Code (l'actif Owned numéro un).
- **/content-strategy** puis **/social-content** pour transformer le calendrier de 90 jours en piliers de contenu par persona et produire pour les 16 comptes connectés.
- **/mk-ai-seo** pour les pages de comparaison /vs et /compare, avec l'objectif explicite d'être cité par les moteurs génératifs, pas seulement de ranker.
- **/audience-growth-engine** pour construire la mécanique de la boucle de partage de clip et la rendre visible.
- **/mk-referral-program** pour sortir de dormance le parrainage "Free Month" et le classement public une fois la rétention validée.
- **/market-funnel** pour architecturer étape par étape le funnel TOFU/MOFU/BOFU une fois cette doctrine validée en interne.
- **/ads-strategy** puis **/mk-paid-ads** uniquement à partir du palier 100 vers 500, quand la conversion sera prouvée et le retargeting à 10-15 EUR/jour justifié par des données, jamais avant.

À chaque étape, la même règle : l'étape Confirm reste toujours visible dans toute description d'action de JARVIS, et aucune preuve sociale ou rareté n'est fabriquée. Les premiers témoignages restent à construire honnêtement (10 à 20 citations réelles, démonstrations par des créateurs) avant d'apparaître dans une seule ligne de copy.
