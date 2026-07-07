## Partie 09. Partenariats, boucles de referral et effets de reseau

### Diagnostic : ou en est Verba par rapport a la distribution des autres

Verba n'a pas d'audience propre construite. La presence build in public sur X vient tout juste de demarrer, il n'y a pas encore de temoignage public, et le canal principal reste le produit lui meme. En revanche l'ICP est net et nommable, ce qui change tout : le beachhead est le developpeur Mac deja abonne a Claude Code, une population qui se rassemble deja dans des lieux precis (Hacker News, r/ClaudeAI, r/macapps, Product Hunt, les communautes autour de Cursor, Lovable, Replit). C'est exactement le cas d'usage central de cette doctrine : le produit est pret, l'acces a l'attention ne l'est pas.

Sur le plan produit, Verba est structurellement mono joueur au coeur (une personne dicte, une personne recoit du texte propre), mais la couche JARVIS cree un potentiel multi joueur : dire une intention, voir le plan, confirmer, et l'action se propage dans des applications partagees avec d'autres personnes (un message envoye a un collegue, un ticket cree pour une equipe, un evenement pose sur un calendrier partage). Ce n'est pas une viralite intrinseque au sens plein (le produit ne requiert pas un second utilisateur pour fonctionner), mais chaque action JARVIS confirmee laisse une trace visible par d'autres, ce qui est la matiere premiere d'une boucle bien concue.

L'ACV qui calibre toute recompense est faible et la marge est tres haute : Verba reutilise l'abonnement Claude Code que l'utilisateur paie deja, donc le cout d'inference marginal est proche de zero. Concretement cela veut dire qu'offrir un mois gratuit a un parrain et a son filleul coute a peu pres rien en cout variable, seulement le manque a gagner sur un abonnement qui n'aurait de toute facon pas existe sans le referral. C'est une situation ideale pour une recompense genereuse en devise produit, sans avoir a raisonner en cash.

Deux mecaniques de boucle existent deja dans le code (referral Mois Gratuit, classement public, gamification a 100 niveaux) mais restent invisibles dans le produit et dans la communication. C'est le point de depart le plus rentable : avant de chercher de nouveaux partenaires, rendre visible ce qui tourne deja.

### Cadre 1 : la carte des partenariats appliquee a Verba

Sur les sept formes de partenariat de la doctrine, quatre sont pertinentes maintenant pour un solo sans budget, une est a construire plus tard, et deux sont a ecarter pour l'instant.

| Forme | Pertinence pour Verba maintenant | Pourquoi |
|---|---|---|
| Co-marketing | Haute, a lancer ce mois ci | Cout quasi nul, ouvre la relation avant de demander plus |
| Audience empruntee (podcasts, newsletters, createurs) | Haute, canal prioritaire | L'ICP exact (dev Mac / Claude Code) est deja concentre dans un petit nombre de lieux identifiables |
| Referral entre utilisateurs | Haute, deja code, a rendre visible | Cout marginal proche de zero grace au BYO AI, ACV faible donc recompense en produit plus efficace qu'en cash |
| Bundles avec produits Mac non concurrents | Moyenne, a tester au palier 500 a 1000 | Meme ICP (utilisateurs Mac de productivite), aucune cannibalisation |
| Integrations / marketplaces | Moyenne, dependante de la roadmap JARVIS | JARVIS se connecte a des applications tierces (les "connected apps") ; une presence dans leurs annuaires d'integrations est une distribution embedded, mais suppose une relation technique a batir |
| Agences et consultants | Basse pour l'instant | Cible B2B avec deploiement chez des clients ; lourd a structurer pour un produit self serve grand public, a garder pour l'expansion vers les pros (juriste, medecin) |
| Channel partners / revendeurs | Basse | Modele self serve, pas de cycle de vente B2B a ce stade |

La regle d'or de la doctrine s'applique directement : une newsletter de 3 000 lecteurs tous developpeurs Claude Code convertira mieux qu'une chaine generaliste de 100 000 abonnes en marketing grand public. Chaque partenariat se juge a l'alignement, jamais a la taille brute.

Sequence recommandee pour ne pas demander le mariage au premier message : commencer par un co-marketing reversible (un guide court co-signe, une mention croisee), prouver la valeur par des chiffres reels (clics, inscriptions attribuees), puis proposer quelque chose de plus engageant (une integration, un bundle). La reciprocite de Cialdini s'applique litteralement ici : donner d'abord un asset utile a l'audience du partenaire, avant de demander quoi que ce soit.

Exemple de premier message give first vers une newsletter developpeur (a executer via cold-email) :

> Subject: A 90-second clip your readers might actually use
>
> Hi [name], long time reader. I built a menu-bar app that turns rambling speech into clean text on a Mac, and it now plans and confirms actions across connected apps too. No pitch here, just a 90-second clip showing "say it, confirm it, it is done" that your readers into Claude Code might find genuinely useful. Happy to send it over, no strings, use it or not.

### Cadre 2 : boucles de croissance, l'artefact partageable avant le coefficient

La difference structurante de la doctrine s'applique tres directement au manque le plus documente dans le brief : Verba a un referral et un classement, mais pas encore l'artefact que Cursor, Lovable et Replit ont tous construit, un objet partageable qui, expose, ramene un nouvel utilisateur. C'est la brique la plus haut levier a construire, avant tout partenariat externe.

Le mecanisme a concevoir : un clip court "je l'ai dit, c'est fait" (parler une intention, montrer le plan, montrer la confirmation, montrer le resultat dans l'application cible) se termine par une carte de fin "Made with Verba" avec un lien. C'est exactement le "Built with Lovable" et le "Made with Replit" cites dans le brief, adaptes au format voix de Verba. Chaque utilisateur qui partage son propre moment de productivite devient un canal de distribution qui ne coute rien en media, et qui porte un signal de confiance humain qu'aucun contenu genere ne porte.

Copy possible pour la carte de fin (aucune interface a l'ecran dans la video, uniquement la carte statique) :

> "I said it. It got done. Made with Verba. verba.run"

Le coefficient viral k donne la grille de lecture honnete pour calibrer les attentes, sans promettre une viralite magique. Applique aux chiffres reels du brief : pour atteindre 100 clients payants il faut environ 1 430 telechargements a un taux de conversion de 7 pour cent. Si le referral et le clip partageable atteignent ensemble un k de 0,4 (un utilisateur invite en moyenne des amis dont 0,4 se convertissent en nouvel utilisateur actif), alors chaque cohorte de 100 payants en genere environ 40 supplementaires par le bouche a oreille produit, puis environ 16 sur la generation suivante. Cela ne rend jamais Verba viral au sens propre (k plus grand que 1), mais cela divise mecaniquement le cout d'acquisition necessaire pour franchir les paliers 100 vers 500 puis 500 vers 1 000. C'est la bonne cible a annoncer en interne : pas "devenir viral", mais "faire baisser le CAC de x40 pour cent grace au produit lui meme".

Sur la recompense elle meme, le modele Dropbox reste la reference et colle parfaitement au profil de marge de Verba : recompense en devise produit (du temps d'usage, pas du cash), instantanee, et a double face (le parrain et le filleul gagnent tous les deux). Le referral "Mois Gratuit" deja code respecte deja ce principe sur le papier ; le travail restant est de le rendre visible au moment ou la valeur percue est maximale, c'est a dire juste apres la premiere action JARVIS confirmee avec succes, pas en pied de page ou dans un menu que personne n'ouvre.

| Element de la boucle referral | Etat actuel | Ce qu'il faut faire |
|---|---|---|
| Recompense | Mois gratuit, deja code | Confirmer qu'elle est double face (parrain ET filleul) |
| Devise de la recompense | Produit (temps d'usage) | Garder, ne jamais basculer en cash |
| Moment de rappel | Invisible aujourd'hui | Le placer juste apres la premiere action JARVIS reussie et confirmee |
| Mesure | Non instrumentee publiquement dans le brief | Suivre le k reel par cohorte de telechargement |
| Classement public | Code, invisible | L'afficher comme preuve sociale et comme rappel recurrent de la boucle |

### Cadre 3 : la communaute comme moat, sans sacrifier la portee

Le noyau de defendabilite de Verba, ce sont les "monks" au sens de Cursor : les developpeurs Claude Code natifs qui utilisent Verba plusieurs fois par jour et pour qui le produit resout un vrai probleme (penser a voix haute, ne pas payer une deuxieme facture d'intelligence, ne pas taper ce qu'on peut dire). Ce noyau merite un espace dedie (un canal Discord ou une liste restreinte), non pas pour la taille, mais parce qu'une communaute qui appartient a Verba ne se copie pas : un concurrent peut cloner le produit en un sprint, il ne peut pas cloner les relations.

La nuance de Byron Sharp s'applique de facon precise a la feuille de route du brief : servir ce noyau pour la defendabilite (feedback, temoignages honnetes, ambassadeurs naturels) tout en cherchant en parallele la penetration large que portent les lancements (Product Hunt, Show HN) et le contenu quotidien distribue sur 16 comptes connectes. L'un ne remplace pas l'autre. Un noyau etroit mais profond defend Verba contre la copie ; une presence large fait que le nom remonte au bon moment, quand un developpeur cherche justement "dictee Mac" ou "agent vocal Claude Code". Les deux mouvements sont deja prevus dans le plan a 90 jours du brief (mois 1 lancement large, engagement noyau en continu) : cette doctrine confirme qu'il ne faut pas arbitrer l'un contre l'autre, ni romantiser le petit cercle au point de negliger la portee.

### Cadre 4 : audience empruntee et la bascule 2026 vers l'ecosysteme lisible par les machines

Sans audience propre, le raccourci le plus rapide reste d'emprunter celle des autres. Pour Verba, la carte des audiences adjacentes tient en trois familles : les lieux ou le developpeur Claude Code se rassemble deja (Hacker News, r/ClaudeAI, Lobsters, les newsletters IA type Ben's Bites ou equivalent developpeur), les chaines et podcasts productivite Mac qui couvrent deja les concurrents indirects, et les communautes adjacentes aux outils cites dans le playbook de croissance (Cursor, Lovable, Replit partagent une bonne partie du meme public technique). La regle reste la meme que pour les partenariats : apporter d'abord une valeur a leur audience (un angle, une donnee, une demonstration honnete de "je l'ai dit, c'est fait"), la mention du produit venant en consequence et non en objet du message.

Le build in public deja engage sur X est lui meme un canal d'audience empruntee a part entiere : partager des chiffres bruts (telechargements, taux de conversion reel, paliers atteints ou rates) rend le fondateur pitchable aupres d'autres createurs, exactement comme Osika pour Lovable ou Masad pour Replit. C'est un actif qui se construit tous les jours, pas un coup ponctuel.

Deux bascules 2026 a integrer dans ce meme mouvement, sans les traiter comme un chantier a part : la recherche se resout de plus en plus a l'interieur des IA (reponses generatives, zero clic vers le site), donc etre cite par un tiers de confiance (une newsletter, une communaute, un annuaire d'integrations) devient un facteur de visibilite dans ces reponses, pas seulement un canal de trafic direct. Et les agents IA qui recommandent des outils a leurs utilisateurs s'appuient sur des integrations officielles et des sources structurees : etre present et bien balise dans l'ecosysteme des "connected apps" devient une condition pour etre recommande aussi par les machines, pas seulement par les humains.

### Erreurs a eviter pour Verba specifiquement

- Signer un co-marketing avec une chaine ou une newsletter generaliste seduite par un gros chiffre d'audience alors que l'alignement ICP est faible : zero conversion, temps perdu sur un produit qui n'a pas de budget a gaspiller.
- Laisser le referral "Mois Gratuit" invisible en pensant qu'il tourne tout seul : sans rappel au moment de la valeur percue maximale, un referral ne s'active jamais.
- Miser tout sur une seule mention de createur volatile plutot que de construire en parallele le canal detenu (communaute noyau, artefact partageable) qui survit apres le pic initial.
- Traiter chaque partenariat comme une transaction unique plutot qu'une relation a entretenir, alors que Verba n'a justement pas encore les moyens de remplacer une relation par du budget.

### Ce qu'il faut tester

- Le clip partageable "Made with Verba" genere t il un k mesurable superieur a zero une fois mis en place et pousse dans le flux produit apres chaque action JARVIS reussie.
- Le rappel du referral juste apres la premiere confirmation JARVIS reussie augmente le taux d'invitation envoyee par rapport a la position actuelle invisible.
- Au moins un co-marketing give first vers une newsletter ou un podcast Claude Code convertit un nombre de leads qualifies superieur a zero, mesurable par lien attribue.
- Le classement public rendu visible augmente la retention ou le partage organique par rapport a une version ou il reste cache.

### Routage vers les skills d'execution

Cette doctrine decide le pourquoi et le quoi ; l'execution se fait ailleurs. Installer et instrumenter la boucle referral (recompense double face, rappel dans le flux, mesure du k) releve de `/mk-referral-program`. Construire une audience propre en parallele de l'audience empruntee, pour ne pas dependre d'un seul canal volatile, releve de `/audience-growth-engine`. Decrocher les placements audience empruntee (podcasts, newsletters, createurs) avec un angle de valeur releve de `/creator-media-engine`. Les premiers messages give first vers les cibles de co-marketing relevent de `/cold-email`. La posture de build in public et d'autorite qui rend le fondateur pitchable aupres des createurs releve de `/thought-leadership-architect`. La bascule GEO et la lisibilite par les IA acheteuses relevent de `/mk-ai-seo` et `/mk-schema-markup`. Le cadrage global de ces choix dans la strategie de croissance releve de `/marketing-strategist`.

--- **Resume :** Verba n'a pas encore d'audience propre mais son ICP est net et deja concentre dans des lieux identifiables ; le plus haut levier immediat est de rendre visibles les boucles deja codees (referral en devise produit, classement) et de construire l'artefact partageable qui manque encore (le clip "je l'ai dit, c'est fait" avec sa carte Made with Verba), tout en cultivant un noyau de developpeurs Claude Code comme moat relationnel sans sacrifier la portee large des lancements, et en empruntant les audiences deja alignees avant d'investir le moindre euro en media paye.
