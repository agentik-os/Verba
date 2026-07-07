## Partie 08. Pricing et monetisation

### Diagnostic

Verba fixe son prix aujourd'hui sur une logique proche du competitive (se situer dans la fourchette basse des apps de dictee du marche) plutot que sur la valeur reelle creee. Le signal le plus net est le chiffre lui meme : un revenu moyen par payeur d'environ 7,6 EUR par mois (calcule sur l'objectif de 100 payeurs pour ~760 EUR de MRR). Pour un produit qui protege des dictees sensibles, reutilise un abonnement Claude Code deja paye (cout d'inference quasi nul pour Verba) et agit dans plus de 1 000 apps connectees apres confirmation, ce chiffre est bas. Ce n'est pas un problème de demande, c'est un problème de capture : Verba laisse la quasi totalite de la valeur creee sur la table du client.

Trois goulots concrets ressortent du brief :
- **Packaging a un seul palier.** Il existe un plan gratuit (33 dictees, sans carte) puis un unique Pro (mensuel ou annuel avec essai de 7 jours). Il n'y a ni tier cible ni tier d'ancrage : rien ne rend le Pro evident face a une alternative plus chere.
- **Aucun levier de raret ni d'ancre haute encore publie.** Le palier Founder / Lifetime n'existe pas dans Stripe. C'est le levier le plus attendu du lancement (Product Hunt, ~28 juillet) et il manque.
- **Aucune boucle d'expansion visible.** Referral "Free Month" et leaderboard sont codes mais invisibles : la retention et l'expansion revenue qu'ils generent ne travaillent pas encore.

Point structurant, propre a Verba : le modele BYO-AI (l'utilisateur reutilise son propre abonnement Claude, la transcription tourne on-device) supprime quasiment tout le probleme classique de marge IA a l'usage. Verba n'a pas a se soucier d'un power-user qui explose sa marge en tokens : son cout marginal est proche de zero, contrairement a la quasi totalite des produits IA. C'est un avantage structurel qui change la reponse a "quel modele de monetisation" : au lieu d'arbitrer siege vs usage vs cap pour proteger une marge menacee, Verba peut se concentrer entierement sur la capture de valeur, sans jamais avoir besoin de plafonner un utilisateur genereux. Ce sous-tarifage n'est donc pas de la prudence economique, c'est une peur non justifiee par les couts, exactement le biais que la doctrine pointe comme l'erreur quasi universelle du fondateur solo.

### Cadre 1. Value-based pricing : ancrer le prix sur le Job-to-be-Done, jamais sur le cout

Le mecanisme : le client ne paie pas pour du logiciel, il paie pour un resultat dans sa journee. Trois moments concrets a chiffrer pour Verba :

- Le developpeur Claude Code qui dicte au lieu de taper : quelques minutes gagnees par session, plusieurs fois par jour, sans casser le flow.
- Le professionnel exigeant en confidentialite (avocat, medecin, fondateur) qui dicte une note sensible sans jamais l'envoyer sur un serveur tiers : la valeur ici n'est pas le temps, c'est le risque evite (une fuite, une clause de confidentialite rompue).
- L'operateur vocal qui dit une intention une seule fois ("reply to this email and say the proposal is ready Friday") et la voit executee apres confirmation : la relance qu'il repoussait depuis trois jours se fait dans le temps qu'il faut pour la dire.

Application chiffree : si une heure de temps de travail qualifie vaut, pour un ICP professionnel, de l'ordre de 40 a 80 EUR, et que Verba fait gagner ne serait ce que 20 a 30 minutes par semaine de friction d'ecriture et de relances non faites, la valeur hebdomadaire depasse largement 10 EUR. La regle de capture de la doctrine (10 a 30 % de la valeur creee) place la fourchette d'un abonnement mensuel bien au dessus des 7,6 EUR actuels, sans meme compter la valeur de la confidentialite (qui ne se traduit pas en heures mais en risque evite, et se paie cher chez les pros).

Prochaine action : recalculer, persona par persona (le developpeur Claude Code, le pro de la confidentialite, l'operateur vocal), la valeur hebdomadaire reelle et verifier que le prix du Pro capture bien 10 a 30 % de ce chiffre, pas moins.

### Cadre 2. Packaging : passer d'un seul palier a une architecture de choix a trois etages

Aujourd'hui Verba propose Free puis Pro : deux points, pas une architecture. La doctrine recommande trois paliers, avec un tier cible au milieu et un tier cher qui sert d'ancre. Voici la structure recommandee, construite a partir des personas du brief :

| Palier | Cible (JTBD) | Role dans l'architecture | Value metric propose |
|---|---|---|---|
| **Explore** (gratuit, 33 dictees, sans carte) | Tester le moment "il l'a fait" sans engagement | Porte d'entree, jamais un produit fini | Nombre de dictees |
| **Pro** (mensuel ou annuel, essai 7 jours) | Le developpeur Claude Code et l'operateur vocal au quotidien | **Le tier cible** : tous les modes, JARVIS, Voice Notes illimitees | Usage illimite, aucun plafond artificiel |
| **Studio / Power** (nouveau, a construire) | L'operateur vocal intensif et le multilingue qui vit dans JARVIS toute la journee | **Ancre haute** : rend le Pro evident et raisonnable en comparaison | Volume d'actions JARVIS par mois, ou nombre d'apps connectees actives |
| **Founder / Lifetime** (a construire, levier de lancement) | Les premiers croyants, avant preuve sociale | Ancre ponctuelle et FOMO de lancement, pas un palier permanent | Paiement unique, place limitee dans le temps |

Le tier Studio n'existe pas encore et n'a pas besoin d'un plafond de cout : puisque Verba ne paie pas l'inference (BYO-AI) ni la transcription (on-device), ce palier peut se permettre d'etre genereux sur l'usage et de vendre plutot de la profondeur (plus de langues d'interface, acces prioritaire aux nouvelles integrations JARVIS, Context mode etendu) que du volume brut. Cela evite le piege classique du "plus tu utilises, plus tu payes" qui frustre un power-user fidele.

Exemple de copy publiable pour la page de prix (a affiner, sans chiffre) :

> **Explore**: try the moment it clicks, free. No card.
> **Pro**: everything you need to think out loud and get it done, every day.
> **Studio**: for the people who live in Verba, deeper languages, earlier access to new connected apps, priority everything.

### Cadre 3. La value equation de Hormozi : le prix n'est jamais le probleme, l'offre l'est

Face a un prospect qui hesite, le reflexe naif est de baisser le prix. La doctrine (Hormozi) inverse : on augmente le numerateur de l'offre plutot que d'entamer le prix. Applique a Verba :

- **Amplifier le resultat reve** : ne pas vendre "de la dictee", vendre le moment ou la relance repoussee depuis trois jours part toute seule pendant que l'utilisateur boit son cafe. C'est deja le narratif du brief ("say it once, it is done"), il doit vivre dans la page de prix elle meme, pas seulement dans la hero copy.
- **Probabilite percue** : le Confirm visible avant chaque action JARVIS est lui meme un argument de prix. Ce n'est pas une fonctionnalite technique, c'est la garantie que rien ne part sans l'accord de l'utilisateur, ce qui reduit la peur de "l'IA qui fait n'importe quoi" et rend le prix plus facile a payer.
- **Delai** : l'essai de 7 jours au checkout et les 33 dictees gratuites raccourcissent deja le delai avant la premiere preuve de valeur. A muscler.
- **Effort** : Verba fonctionnant deja la ou l'utilisateur travaille (le curseur, l'app active), l'effort d'adoption est proche de zero. Ce point merite d'etre dit explicitement dans l'argumentaire de prix : "no new app to learn, no workflow to change."

Exemple de copy Founder tier qui applique la value equation sans jamais toucher au prix ni inventer de preuve :

> **Founder access.** One payment. Lifetime Pro, a Founder badge in the app, and first access to every new connected app JARVIS learns to use, before anyone else. Limited to the first cohort, then it closes for good.

Ce texte amplifie le resultat (acces a vie, avantage permanent), la probabilite (badge, statut confirme), et reduit implicitement le delai (acces immediat). Aucune fausse raret n'est inventee : la limite de cohorte doit etre reelle et honoree (fermeture effective une fois le nombre atteint), jamais un compteur factice.

### Cadre 4. Le prix comme signal de positionnement, et l'expansion qui ne coute rien

Le prix EST une declaration de categorie (Dunford). Verba se positionne comme le premier agent vocal prive credible sur Mac, pas comme une app de dictee jetable a quelques euros. Un prix aligne sur "Jarvis pour ton Mac" doit rester dans une gamme de confiance B2B/pro : privilegier des chiffres ronds plutot que du charm pricing (29 au lieu de 30) qui signale le bon plan grand public. Verba vise des professionnels et des developpeurs exigeants, pas un reflex d'achat impulsif a 4,99.

Le framing annuel merite d'etre muscle des maintenant : afficher le prix mensuel mais facturer l'annuel ("X/mo billed annually") supprime les onze decisions de reabonnement de l'annee et securise la tresorerie. C'est un levier gratuit, deja techniquement disponible (Pro existe en mensuel et annuel), qu'il suffit de mieux mettre en avant au moment du choix.

Sur l'expansion revenue : Verba n'a pas de sieges a vendre (produit solo, B2C self serve), donc le Net Revenue Retention classique du SaaS B2B ne s'applique pas telle quelle. Mais deux boucles deja codees jouent exactement ce role sans cout d'acquisition additionnel :

- Le **referral "Free Month"** reduit le churn effectif (un client qui parraine reste plus longtemps) et cree une expansion indirecte : chaque parrainage reussi vaut un mois de retention supplementaire, sans depense marketing.
- Le **leaderboard et la gamification** (100 niveaux) augmentent l'engagement, donc la probabilite de passer du mensuel a l'annuel, donc la retention brute qui alimente la marge.

Ces deux boucles sont codees mais invisibles dans le produit aujourd'hui : les rendre visibles est la premiere action de monetisation a cout zero, avant tout travail de prix. C'est aussi la passerelle naturelle vers la doctrine des partenariats et effets reseau qui suit ce chapitre.

### Ce qu'il faut tester (falsifiable, pas devine)

1. **Van Westendorp sur le Founder tier avant publication.** Envoyer les quatre questions classiques ("a quel prix cela devient trop cher / cher mais envisageable / bon marche / trop bon marche pour etre serieux") a 20 a 30 personnes deja engagees : la communaute X du fondateur, les premiers repondants Product Hunt, les early adopters du plan Explore. Croiser les courbes donne une fourchette acceptable avant le lancement du 28 juillet, plutot que de deviner un chiffre la veille.
2. **Lire le taux de refus au paywall.** Instrumenter la fin d'essai de 7 jours avec une micro enquete d'un clic a l'annulation ("Too expensive for what it does" comme option explicite). Un taux de refus autour de 20 a 30 % chez les prospects qualifies signale un prix a peu pres juste. Zero refus veut dire que le prix est encore trop bas.
3. **Augmenter le prix des nouveaux clients sur le Pro, grandfather les payeurs actuels.** Des que la boucle referral et leaderboard sont visibles et qu'un premier lot de preuve sociale existe (10 a 20 temoignages honnetes vises par le brief), tester une hausse sur les seules nouvelles inscriptions et observer le taux de refus avant de la generaliser.

### Recap operationnel

| Action | Palier concerne | Cout | Gain attendu |
|---|---|---|---|
| Recalculer la valeur JTBD par persona et verifier la capture 10-30 % | Pro | Zero | Justifie une hausse de prix documentee |
| Construire le tier Studio (ancre haute, sans plafond d'usage) | Nouveau palier | Faible (packaging, pas de dev IA) | Rend le Pro evident, capture les power-users |
| Publier le Founder / Lifetime avec Van Westendorp prealable | Nouveau palier | Faible | FOMO de lancement, ancre pour l'annuel |
| Rendre visibles referral et leaderboard | Tous paliers | Deja code | Retention et expansion a cout zero |
| Muscler le framing annuel a la page de prix | Pro | Zero | Moins de churn, meilleure tresorerie |
| Instrumenter le refus au paywall | Tous paliers | Faible | Lecture reelle du marche, pas une supposition |

Cette section route l'execution vers /mk-pricing-strategy pour transformer cette architecture en grille chiffree par palier, vers /offer-and-revenue-architect pour construire l'offre Founder en "grand slam" au sens Hormozi, et vers /mk-ab-test-setup pour monter le test de hausse de prix sur les nouveaux clients. Le chapitre suivant (partenariats et effets reseau) prend le relais des boucles referral et leaderboard une fois rendues visibles.
