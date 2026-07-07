## Partie 07. Publicite payante, le multiplicateur (apres la preuve)

Cette section applique la doctrine mm-07 (Paid Ads & Paid Acquisition) a la situation reelle de Verba, telle que decrite dans le brief de contexte : un produit pre-lancement, un playbook de croissance organique explicite (Cursor, Lovable, Replit, Higgsfield), et une philosophie budgetaire deja ecrite noir sur blanc dans le plan 90 jours (0 euro jusqu'a 100 clients, puis 10 a 15 euros par jour en retargeting seulement, puis sponsoring newsletter et affiliation). Le rôle de cette section n'est pas d'inventer une strategie paid parallele : c'est de verifier que cette philosophie est la bonne, de lui donner un mecanisme chiffre, et d'ecrire a l'avance les regles de decision pour le jour ou le robinet s'ouvre.

### Diagnostic : Verba est-il prêt pour le paid ?

La doctrine pose trois preconditions non negociables avant le premier euro de prospection payante. Voici où en est Verba sur chacune, a la lecture du brief.

| Precondition | Etat reel chez Verba | Verdict |
|---|---|---|
| Retention prouvee (cohortes qui ne fuient pas) | Produit en phase de lancement (mois 1, objectif 0 vers 100 clients payants). Aucune cohorte payante encore observee sur plusieurs mois. La preuve sociale elle meme reste a construire (0 temoignage public a ce jour). | Non prouvee. A tracer des les premiers clients. |
| Offre et page qui convertissent deja du trafic gratuit | Freemium avec 33 dictations gratuites sans carte bancaire, essai de 7 jours au paiement. Le funnel cible 1 430 telechargements pour 100 payants, soit un taux de conversion implicite de 7 pourcent. Ce chiffre est un objectif de lancement, pas encore une conversion mesuree en production. | Pas encore verifiee a l'echelle. A confirmer au lancement (fin juillet). |
| Mecanisme de monetisation et marge connus | Ici Verba a un avantage structurel rare : le modele BYO AI (Bring Your Own AI, reutilisation de l'abonnement Claude Code que le client paie deja) rend le cout d'inference quasi nul. Marge brute tres elevee, ARPU mensuel blended connu (environ 7,6 euros). | Connue et excellente. Le point fort du dossier. |

**Verdict global : pas pret pour une campagne de prospection froide (cold) classique aujourd'hui.** Et c'est exactement ce que le plan 90 jours de Verba fait deja bien : zero euro de paid pour atteindre les 100 premiers clients, cent pourcent organique (build in public, share-clip loop, Product Hunt, Show HN, communautes de developpeurs). Cette section ne contredit pas ce choix, elle le confirme avec le mecanisme de la doctrine et pose les seuils chiffres pour la suite : quand et comment ouvrir le robinet a la palier 100 vers 500, puis 500 vers 1 000.

Ce que le paid pourra amplifier, une fois la preuve faite, ce n'est donc pas un vide : c'est un canal organique deja identifie (le clip "j'ai dit, c'est fait") et une marge deja exceptionnelle. Le mecanisme est prometteur. Il n'est simplement pas encore temps de le nourrir a l'argent.

### Les quatre nombres de Verba (unit economics)

La doctrine est claire : le paid se pilote sur quatre chiffres, jamais sur un dashboard de plateforme. Voici le gabarit applique a Verba, avec les valeurs connues du brief et les hypotheses de travail clairement marquees comme telles (a verifier des les premieres cohortes reelles, jamais a presenter comme preuve).

| Metrique | Formule | Valeur Verba | Statut |
|---|---|---|---|
| ARPU mensuel blended | revenu mensuel moyen par client | 7,6 euros | Connu (brief) |
| Marge brute | (revenu, cout d'inference et de plateforme) / revenu | environ 90 pourcent (BYO AI, cout d'inference quasi nul) | Hypothese de travail, a affiner avec la comptabilite reelle |
| Churn mensuel | clients perdus / clients actifs | non mesure encore | A mesurer des les premieres cohortes payantes |
| LTV (en marge) | (ARPU x marge) / churn | si churn hypothetique 5 pourcent par mois : (7,6 x 0,90) / 0,05 = environ 137 euros | Illustratif, a recalculer sur donnees reelles |
| CAC max pour ratio 3:1 | LTV / 3 | environ 46 euros | Plafond theorique, pas une cible a viser |
| CAC max pour payback 3 mois | marge mensuelle x 3 | 6,84 x 3 = environ 20,5 euros | **Le vrai plafond a respecter en solo autofinance** |

Le point le plus important de ce tableau, fidele a la doctrine : pour un projet autofinance comme Verba, le **payback compte plus que le ratio LTV:CAC**. Un ratio 3:1 sur trois ans ne sert a rien si la tresorerie s'assèche avant. Avec les hypotheses ci-dessus, le plafond operationnel a respecter des le premier euro de paid est donc environ **20 euros de CAC**, pas 46. Cette marge de securite protege Verba d'un scaling premature sur des hypotheses de churn optimistes.

Consequence directe pour le budget de la palier 100 vers 500 (10 a 15 euros par jour, soit 300 a 450 euros par mois deja prevu dans le plan) : ce budget doit produire environ 15 a 22 nouveaux clients payants par mois pour rester sous le plafond de 20 euros de CAC. C'est un chiffre falsifiable a verifier des le premier mois de retargeting, pas une esperance vague.

### Le creatif comme ciblage, applique aux personas Verba

Depuis la perte de signal post-iOS 14, l'algorithme cible mieux que n'importe quel reglage manuel. Ce qui reste entre les mains de Verba, c'est le creatif : l'angle, le hook, le format. Et Verba a deja, dans son brief, l'ingredient le plus rare en 2026 : un format de creatif natif qui n'a **pas besoin d'etre invente pour la pub**, il existe deja comme boucle organique. Le clip "j'ai dit, c'est fait" (voice-to-action, carton de fin "Made with Verba") est exactement la definition de la doctrine pour un UGC gagnant : ca ne ressemble pas a une pub, donc ca ne declenche pas la defense anti-pub.

La regle de la doctrine pour un solo : ne jamais produire un creatif publicitaire dedie avant d'avoir un gagnant organique a amplifier. Pour Verba, la sequence correcte est : le clip existe et performe en organique (X, TikTok, Instagram) avant meme d'envisager un euro de boost dessus. C'est le mecanisme "output is the ad" du playbook Cursor et Higgsfield transpose au paid : on ne cree pas un nouveau format pour la pub, on amplifie celui qui marche deja.

Cinq angles a tester en priorite, mappes sur les niveaux de conscience de Schwartz et les personas du brief :

| Persona | Niveau de conscience | Angle | Exemple de hook (EN, publiable) |
|---|---|---|---|
| Developpeur Claude Code natif | Product-aware (connait deja l'IA, cherche l'outil) | Il utilise deja Claude Code, alors pourquoi payer une deuxieme IA pour dicter | "I stopped paying for a second AI subscription just to talk to my Mac." |
| Pro privacy-first (avocat, medecin, fondateur) | Problem-aware (sait que le cloud est un risque, cherche une solution) | Dicter sans que rien ne quitte la machine | "I dictate client notes on my Mac and none of it ever leaves the machine." |
| Operateur voice-first (fondateur, PM) | Solution-aware (connait la dictee, ne connait pas encore l'agent) | Le dire une fois suffit, ca part deja fait | "I said reply and confirm the meeting. I glanced. It was done before I put my phone down." |
| Pro multilingue | Most-aware (cherche precisement cette fonction) | Penser dans sa langue, ecrire dans celle du destinataire | "I think in French. My emails go out in perfect English." |
| Penseur long-format / preneur de notes | Unaware a problem-aware (ne sait pas qu'une heure de parole peut devenir un document propre) | Une heure de monologue devient un document lisible | "I rambled for an hour into my Mac. I got back a clean, organized document." |

Chaque angle respecte la regle Confirm visible : aucune description d'action n'omet l'etape ou l'utilisateur valide avant execution ("you confirm", "I glanced"). Aucun de ces exemples ne mentionne de prix ni ne cite une preuve qui n'existe pas encore (pas de "des milliers d'utilisateurs" tant que la preuve sociale n'est pas construite).

Le protocole de test reste celui de la doctrine : 5 a 10 variantes en parallele une fois le budget retargeting ouvert, on tue vite les perdants, on double sur le gagnant, jamais de jugement avant environ 50 conversions par variante. A un budget de 300 a 450 euros par mois et un CAC cible autour de 20 euros, atteindre 50 conversions sur une seule variante prendra plusieurs mois : la lecture doit donc se faire sur l'ensemble du portefeuille de creatifs, pas variante par variante, tant que le volume est faible. C'est une contrainte reelle de petit budget que la doctrine anticipe (300 a 500 euros par mois minimum pour sortir de l'apprentissage) et qu'il faut ecrire dans le plan avant de lancer, pas decouvrir en cours de route.

### Structure de campagne par palier

Verba n'a pas besoin d'une architecture de campagne complexe. Une structure simple, alignee sur les trois paliers deja ecrits dans le plan 90 jours.

| Palier clients | Budget mensuel | Plateforme | Objectif de campagne | Format creatif |
|---|---|---|---|---|
| 0 vers 100 | 0 euro (100 pourcent organique) | Aucune plateforme payante | Sans objet | Clips organiques, build in public, Show HN, Product Hunt |
| 100 vers 500 | 300 a 450 euros (10 a 15 euros par jour) | Meta, retargeting seulement | Conversion (essai demarre ou abonnement), jamais trafic ou vues | Reprise des clips "Made with Verba" les plus performants en organique, un seul ad set large, 5 a 8 variantes |
| 500 vers 1 000 | Sponsoring newsletter niche et affiliation (montant variable, hors media buying classique) | Newsletters privacy tech, productivite, developpeurs | Notoriete qualifiee et trafic direct vers la page, mesure en nouveaux payants attribues au code affilie | Copy ecrite specifique par newsletter, angle privacy-first ou voice-first selon l'audience |
| 1 000 vers 2 000 (plafond cible) | A envisager seulement si le ratio et le payback restent sains sur la palier precedente | Extension prudente vers Google Search sur intention haute ("wispr flow alternative", "mac dictation privacy") | Capture de l'intention de recherche generee par les pages de comparaison SEO deja prevues (/vs, /compare) | Search classique, groupes d'annonces serres, negatifs agressifs |

Deux precisions fideles a la doctrine. D'abord, le retargeting de la palier 2 est **volontairement petit et cadre** : la doctrine previent que le ROAS de retargeting est souvent une illusion, beaucoup des gens touches (visiteurs de verba.run, utilisateurs des 33 dictations gratuites qui n'ont pas encore paye) auraient converti sans la pub. Ne pas se laisser hypnotiser par un ROAS spectaculaire sur ce segment : le vrai test est un on/off. Ensuite, la palier 4 (Search) reste conditionnelle et n'est pas une extension automatique : elle ne s'active que si le mecanisme reste positif sur les paliers precedentes, exactement la logique de "paliers de +20 a 30 pourcent tous les 3 a 4 jours" de la doctrine, jamais un doublement brutal.

### Attribution honnete : ce que Verba doit regarder, pas le dashboard

Verba est un produit Mac distribue en .dmg, avec un funnel qui traverse le site web, l'app locale, et Stripe pour le paiement. C'est un terrain d'attribution particulierement flou : pas de tracking mobile iOS a subir, mais un parcours web vers app vers paiement ou le pixel publicitaire ne voit qu'une fraction du chemin. La regle de la doctrine s'applique integralement : ignorer le ROAS affiche par la plateforme publicitaire, piloter sur trois reflexes.

- **Le CAC blended.** Depense pub totale divisee par le total de nouveaux clients payants (toutes sources confondues, Stripe fait foi). C'est ce chiffre, croise avec la croissance reelle du MRR, qui dit si le paid fonctionne, pas le tableau de bord Meta.
- **Le test on/off.** Avec un budget aussi petit (300 a 450 euros par mois), ce test est facile a executer et peu couteux a manquer : couper le retargeting deux semaines des la palier 2 et observer si le rythme de nouveaux payants change. Si rien ne bouge, le budget retargeting n'etait pas incrementale, il finançait des conversions qui seraient arrivees par l'organique de toute façon.
- **Un MMM artisanal.** Un tableur mensuel simple : depense par canal (retargeting, sponsoring newsletter, affiliation) contre nouveaux clients payants du mois. Sur trois a quatre mois, les correlations se voient a l'oeil nu, suffisant pour un solo.

### Les erreurs a ne pas commettre chez Verba

- **Lancer du paid avant les premiers 100 clients et leurs cohortes.** Le seau perce de la doctrine : sans retention prouvee, aucun CAC ne sera rentable, quel que soit le budget.
- **Produire un creatif publicitaire dedie plutot que d'amplifier le clip organique qui marche deja.** Verba a la chance rare d'avoir deja identifie son format UGC natif (le clip "Made with Verba") ; l'erreur serait de le court-circuiter avec un tournage corporate classique.
- **Juger le retargeting sur son ROAS plateforme.** Deja le piege le plus courant de la doctrine, et le plus tentant a la palier 2 puisque le ROAS de retargeting semble toujours excellent.
- **Se precipiter vers Google Search ou les paliers superieures avant que le payback de la palier precedente soit verifie sous les 20 euros de CAC cible.**
- **Confondre revenu et marge dans le calcul de LTV.** Le brief donne un ARPU blended de 7,6 euros : c'est un revenu, pas une marge. Toujours multiplier par le pourcentage de marge brute reelle avant de calculer un ratio.

### Prochaines actions falsifiables

1. Des les 20 a 30 premiers clients payants, tracer les cohortes mensuelles (combien restent au mois 1, 2, 3) pour verifier la precondition de retention avant tout euro de paid.
2. Instrumenter le Stripe et le funnel pour calculer un CAC blended et un ARPU reel des le premier mois, plutot qu'une estimation.
3. A l'ouverture de la palier 100 vers 500, ecrire a l'avance le seuil de kill (par exemple : tuer toute variante au dessus de 25 euros de CAC apres 30 conversions, dans l'attente du seuil ideal de 50) et le seuil de scale (doubler le budget par paliers de 20 a 30 pourcent, jamais d'un coup).
4. Preparer 5 a 8 variantes de retargeting a partir des clips organiques les plus performants, pas de tournage dedie.
5. Ne considerer Google Search sur intention haute qu'une fois la palier 500 vers 1 000 validee sur son propre payback, et seulement en s'appuyant sur les pages de comparaison SEO deja prevues dans le plan de contenu.
