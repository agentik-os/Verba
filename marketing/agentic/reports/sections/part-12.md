## Partie 12. La sequence et le plan 90 jours

### Diagnostic : où Verba en est réellement dans la séquence

La séquence non négociable est Positionnement, Message, Un seul canal, Conversion, Mesure, Scaling. Chaque étape est le prérequis de la suivante et l'inverser détruit la valeur produite en amont. Où en est Verba, concrètement, aujourd'hui (3 juillet 2026, à 25 jours du lancement Product Hunt et Show HN visé fin juillet) ?

**Positionnement : écrit, pas encore éprouvé.** L'équipe a trouvé le rayon vide, "l'agent vocal privé pour Mac", et le narratif de lancement, "l'app de dictée Mac devenue agent vocal". C'est un vrai travail de catégorie au sens Ries et Trout. Mais ce positionnement n'a pas encore été confronté à la méthode Moesta : personne n'a reconstruit la timeline de décision de 5 à 8 utilisateurs réels pour vérifier que "privé, réutilise mon abonnement Claude, et agit" est bien le job pour lequel ils embauchent Verba, plutôt qu'une story qui sonne bien en interne.

**Message : partiel.** Les trois bénéfices (privé par défaut, pas de double facture, ça agit) existent et sont déjà traduits en langage client plutôt qu'en specs, c'est un bon point de départ. Mais ils ne sont pas encore déclinés par persona selon les niveaux de conscience de Schwartz, et la promesse en une phrase comprise en cinq secondes n'a pas été testée à l'oral face à un inconnu.

**Un seul canal : pas encore choisi, au contraire dispersé.** Le moteur de contenu quotidien publie déjà sur 16 comptes (X, LinkedIn, Instagram, TikTok, YouTube, Threads, Facebook, Pinterest, Telegram, Reddit, etc.) via l'automation omega-zernio. C'est une force de distribution, mais ce n'est pas une maîtrise de canal au sens de la doctrine : publier partout n'est pas la même chose que dominer un canal où l'on apprend, répond, et affine son jugement chaque semaine. Le risque est réel : disperser l'énergie de fondateur sur 16 fronts avant d'avoir un seul mécanisme prouvé.

**Conversion : le funnel existe, il n'est pas encore mesuré étape par étape.** 33 dictées gratuites dans l'app, puis Pro avec essai de 7 jours au paiement. Le taux de conversion visé (7 pour cent, environ 1 430 téléchargements pour 100 payants) est une hypothèse de calcul, pas une donnée observée.

**Mesure : les seuils existent, pas encore l'instrumentation.** La marge brute est déjà connue (BYO-AI, coût d'inférence quasi nul), et le blended de 7,6 euros par abonné et par mois donne un LTV de départ. Mais rien n'indique qu'un tableau de cinq métriques et trois événements de conversion tournent déjà en continu.

**Scaling : à raison, pas encore engagé.** La philosophie budgétaire de Verba (0 euro jusqu'à 100 clients, retargeting seulement une fois la conversion prouvée) est exactement la doctrine : ne jamais scaler ce qui n'est pas encore reproductible. C'est la partie la plus saine du plan actuel.

**Le diagnostic tient en une phrase : Verba essaie de sauter de Positionnement directement à Canal (16 comptes) et Scaling (lancement, growth loops), en économisant l'étape Message (validation verbale) et Conversion (mesure de la fuite réelle du funnel).** Ce n'est pas un problème de tactique, ni de manque de contenu ou de canaux, c'est un problème de séquence : le narratif est prêt avant d'avoir été confronté aux mots exacts de vrais utilisateurs, et la distribution tourne avant que la plus grosse fuite du funnel ne soit identifiée.

### Les trois frameworks qui collent à cette étape

**1. La méthode Moesta (Jobs-to-be-Done) pour valider le message avant de l'amplifier.** Mécanisme : la copy gagnante n'est jamais inventée, elle est transcrite. Application concrète pour Verba : interviewer 5 à 8 utilisateurs actuels (prioriser le beachhead, le développeur Claude Code-natif) en reconstruisant leur timeline : quel était le moment de bascule (un email en retard, un ticket Linear oublié, une note vocale jamais nettoyée), quelle solution utilisaient-ils avant (Notes vocales natives, Whisper local, rien), quelle anxiété freine encore l'adoption (la peur que "ça agisse tout seul"), quelle habitude fait de la résistance (taper au clavier reste l'inertie par défaut). Next action : router vers `/product-marketing-context` pour transcrire ces mots exacts dans `.agents/product-marketing.md`, avant toute nouvelle vague de contenu.

**2. Les niveaux de conscience de Schwartz pour décliner le message par persona, pas en un seul bloc.** Mécanisme : un inconnu non conscient du problème n'a pas besoin de la même phrase qu'un développeur déjà conscient de la solution "dictée Mac" qui ignore encore que Verba agit. Application : pour le beachhead développeur (conscient de la solution), le message peut nommer l'action directement. Pour les personas d'expansion (juriste, médecin, fondateur, journaliste, encore non conscients du problème "je perds du temps à taper"), le message doit d'abord nommer la douleur avant la solution. Next action : router vers `/mk-copywriting` pour écrire ces déclinaisons, une par persona, avant de les injecter dans le moteur de contenu quotidien.

**3. Le mécanisme "un canal dominé" appliqué à la distribution automatisée existante.** Mécanisme : chaque canal a sa propre courbe d'apprentissage, et la maîtrise vient de la répétition concentrée sur celui où le fondateur peut personnellement apprendre, répondre, s'engager, pas de l'étalement. Application pour Verba : le canal que le fondateur maîtrise personnellement chaque semaine est X (build-in-public, chiffres bruts, réponses aux commentaires), c'est le seul endroit où le jugement se construit en direct. Les 15 autres comptes du moteur automatisé ne sont pas des canaux "en cours d'apprentissage", ce sont des surfaces de republication d'un même insight (le mécanisme Andrew Chen déjà nommé dans la doctrine : un insight client devient un post, un thread, une légende, une vidéo). Cela résout la tension apparente entre "publier sur 16 comptes" et "dominer un seul canal" : la distribution automatisée n'est pas l'apprentissage, X l'est. Next action : router vers `/audience-growth-engine` pour le canal pivot, et laisser le moteur de contenu (déjà en place) faire le travail de republication.

### Le plan 90 jours de Verba, semaine par semaine

Le calendrier ci-dessous applique la structure mm-12 (mois 1 fondations, mois 2 canal et conversion, mois 3 mesure et premier scaling) à la structure déjà posée dans le brief Verba (0 vers 100, 100 vers 500, 500 vers 1 000 clients payants), en partant du 3 juillet 2026.

**Mois 1 (0 vers 100 clients) : fondations, avant le lancement**

| Semaine | Doctrine mm-12 | Objectif concret Verba | Skill exécutant |
|---|---|---|---|
| 1 | ICP et Jobs-to-be-Done | 5 à 8 interviews d'utilisateurs beta actuels (développeur Claude Code en priorité), transcrire les mots exacts, identifier push, pull, anxiété, habitude | `/product-marketing-context` |
| 2 | Positionnement | Confronter le canevas Dunford déjà écrit ("privé, réutilise votre Claude, et ça agit") aux mots réels collectés en semaine 1, ajuster si l'écart est grand | `/marketing-strategist` |
| 3 | Message et offre | Décliner la promesse en une phrase de cinq secondes par persona (beachhead d'abord), fixer la copy du "Founder tier" à construire | `/mk-copywriting` |
| 4 | Page, preuve, mesure de base | Réécrire verba.run autour du message validé, poser trois événements de conversion (téléchargement, activation, premier paiement), lancer Product Hunt et Show HN | `/mk-page-cro`, `/mk-analytics-tracking` |

**Mois 2 (100 vers 500 clients) : un canal dominé et la conversion**

| Semaine | Doctrine mm-12 | Objectif concret Verba | Skill exécutant |
|---|---|---|---|
| 5-6 | Production et rythme tenable 6 mois | Cadence X du fondateur (build-in-public, chiffres bruts) trois fois par semaine minimum, chaque insight republié en post, thread, légende, section de page par le moteur automatisé | `/audience-growth-engine`, `/social-content` |
| 7-8 | Conversion, une fuite à la fois | Mesurer visiteur, lead, activé, payant sur les données réelles du lancement, corriger la plus grosse fuite seule (probablement gratuit vers premier paiement), lancer le premier concours UGC hebdo | `/mk-page-cro`, `/creator-media-engine` |

**Mois 3 (500 vers 1 000 clients) : mesure comme système, premier scaling**

| Semaine | Doctrine mm-12 | Objectif concret Verba | Skill exécutant |
|---|---|---|---|
| 9 | Lire les chiffres comme un système | Calculer CAC réel (temps fondateur valorisé, puis euros dès le premier retargeting), LTV observé, délai de remboursement, sur cinq métriques maximum | `/mk-analytics-tracking` |
| 10-11 | Itérer sur une variable structurante | Tester une seule variable à la fois : l'accroche du canal pivot, l'offre Founder tier, ou le segment (élargir vers privacy pros et voice-first operators) | `/mk-ab-test-setup` |
| 12 | Premier scaling, prouvé seulement | Premier retargeting payant (10 à 15 euros par jour) uniquement sur la combinaison canal, message, offre dont l'économie est prouvée ; premier partenariat newsletter niche | `/marketing-strategist` |

Le plafond visé au-delà de ces 90 jours, 2 000 clients payants (environ 15 200 euros par mois), n'est pas un quatrième mois de la même intensité : c'est le cycle suivant, avec l'élargissement complet vers les personas d'expansion (multilingues, penseurs longue forme) une fois le canal pivot et l'offre Founder éprouvés.

### Les portes entre paliers (ne pas avancer sans le seuil)

| Palier | Seuil d'entrée | Ce qui doit être vrai avant d'avancer |
|---|---|---|
| 0 vers 100 | Lancement | Message validé verbalement (mois 1), page réécrite autour de ce message, trois événements de conversion posés |
| 100 vers 500 | Preuve de conversion | Un canal (X) tenu à un rythme soutenable depuis six semaines, la plus grosse fuite du funnel identifiée et corrigée une fois |
| 500 vers 1 000 | Économie unitaire connue | CAC, LTV et payback calculés sur données réelles, pas estimées ; premier retargeting seulement si le ratio est positif |
| 1 000 vers 2 000 | Système reproductible | Le cycle complet (message, canal, conversion, mesure) peut être rejoué sur un persona d'expansion sans réinventer le mécanisme |

### Ce qu'il faut tester en priorité

La variable structurante à tester en premier n'est pas un bouton ni une couleur : c'est **l'accroche du canal pivot**, la phrase que le fondateur poste sur X pour ouvrir chaque clip "je l'ai dit, c'est fait". Exemple à tester, en anglais, respectant Confirm visible et sans chiffre inventé :

> "I said 'file the bug and tell the team.' It showed me the exact steps first. I confirmed once. Thirty seconds later, done."

La fuite à mesurer en priorité est le passage gratuit vers premier paiement (33 dictées gratuites vers l'essai Pro de 7 jours), parce que c'est l'étape où l'hypothèse de 7 pour cent de conversion n'a encore jamais rencontré de vrai runtime. Le critère qui tranchera : si le taux observé sur les cent premiers payants est significativement sous 7 pour cent, la fuite prioritaire du mois 2 devient cette étape précise, avant tout nouveau canal ou toute nouvelle fonctionnalité de partage.

### La routine marketing hebdomadaire du fondateur Verba

Le moteur de contenu quotidien (verba-daily.ts, publication automatisée via omega-zernio après validation opérateur) libère du temps de production mais ne remplace jamais le jugement. La routine de 6 à 8 heures par semaine se répartit ainsi :

| Créneau | Durée | Contenu |
|---|---|---|
| Lundi matin | 1h | Lecture du tableau de cinq métriques (téléchargements, activation, conversion payante, nouveaux clients, la fuite du moment), décision d'UNE action de la semaine |
| 2 à 3 sessions | 3 à 4h | Production du canal pivot X en batch : chiffres bruts, réponses aux clients, un insight par session qui nourrira le moteur automatisé |
| Mardi et jeudi | 30 min | Distribution et conversation : répondre aux commentaires, DM, mentions Reddit, c'est ici que naît le prochain insight |
| Vendredi | 45 min | Une interview client (méthode Moesta) ou une itération de page ou d'offre |

### Garder, déléguer, automatiser, appliqué à Verba

| Catégorie | Ce qui s'y trouve chez Verba | Pourquoi |
|---|---|---|
| Garder (fondateur) | La voix du canal pivot X, la décision sur les cinq métriques, les interviews client, le calibrage du positionnement et de l'offre Founder tier | C'est le jugement, il ne se délègue pas avant l'expertise et reste l'avantage même après |
| Automatiser | Le moteur de contenu quotidien (image, légende, vidéo optionnelle sur calendrier 90 jours), la publication sur les 15 comptes secondaires, la mesure (dashboard, événements de conversion), les séquences d'onboarding et de relance | Travail répétitif et structuré, déjà codé, seule l'approbation opérateur (autonomie L0) reste manuelle |
| Déléguer plus tard | Montage vidéo avancé pour les clips UGC, réponses communautaires Reddit à volume élevé, gestion de l'affiliation une fois active | Seulement une fois que le fondateur sait reconnaître ce que "bon" veut dire sur chaque geste |

### Checklist de maîtrise, version Verba

Verba est **compétent** quand : la phrase de positionnement tient en une ligne testée sur de vrais inconnus, le CAC et le LTV sont des chiffres observés et non des hypothèses de calcul, le canal X ramène des clients de façon répétable sans dépendre d'un coup viral isolé, la page verba.run convertit au-dessus de zéro et l'équipe sait précisément pourquoi (quel bénéfice, quelle preuve, quelle objection levée).

Verba est **expert** quand : le mécanisme complet (message, canal, conversion, mesure) peut être rejoué sur un persona d'expansion (privacy pros, voice-first operators) en 90 jours sans réinventer le calendrier, le fondateur sent qu'une accroche du canal pivot est plate avant même de la tester, et le choix du prochain canal ou de la prochaine offre se fait par jugement calibré sur les vrais chiffres, jamais par mode ou par ce que fait un concurrent.

### La boucle

Ce plan de 90 jours n'est pas un one-shot. Une fois le cycle 0 vers 100 refermé, avec le message éprouvé et le canal pivot maîtrisé, il se rejoue sur le persona d'expansion suivant, avec les mêmes gabarits de page, le même processus d'interview, le même tableau de cinq métriques, mais un public neuf. La distribution mutualisée (l'audience X construite pour le beachhead développeur devient le canal de lancement de chaque persona suivant) est l'actif le plus durable de Verba, plus durable que n'importe quelle fonctionnalité du produit. `/marketing-master` reprend l'ensemble des douze parties de cette doctrine en une passe de vérification à chaque nouveau cycle.
