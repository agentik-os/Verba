## Partie 11. Mesure, retention et boucles qui composent

### Diagnostic : le seau fuit-il avant qu'on paie pour le remplir

Verba n'a, à ce jour, ni North Star Metric définie, ni courbe de rétention tracée, ni événement "aha" instrumenté. Le seul filtre existant est arithmétique et grossier : 33 dictations gratuites avant paywall, avec un objectif de conversion de 7% (environ 1 430 téléchargements pour 100 clients payants). C'est un seuil d'usage, pas un signal de valeur. On ne sait pas aujourd'hui si un utilisateur qui abandonne à la dictation 12 est parti parce qu'il n'a jamais vécu l'instant où sa parole ressort en texte propre, prêt à envoyer, ou parce qu'il a eu ce déclic et n'est simplement pas encore prêt à payer. Ce sont deux problèmes radicalement différents et sans instrumentation, ils sont invisibles l'un comme l'autre.

Bonne nouvelle : la philosophie budgétaire déjà écrite dans le playbook Verba (0 euro jusqu'à 100 clients, tout en organique ; retargeting payant seulement entre 100 et 500, une fois la conversion prouvée) respecte déjà, sans le nommer, l'ordre rétention avant acquisition payante. Le risque n'est donc pas de financer un canal payant prématurément, il n'existe pas encore. Le risque réel est de construire les quatre moteurs de croissance (build in public, boucle de partage, communauté, boucles produit) sans savoir laquelle des cohortes qu'ils amènent reste, et de découvrir à 500 clients qu'on a rempli un seau percé avec du travail gratuit au lieu d'argent, ce qui coûte tout autant en temps et en crédibilité de lancement.

**Verdict** : l'acquisition organique gratuite peut continuer en parallèle (elle ne coûte rien à interrompre), mais la définition de la NSM, l'instrumentation de l'événement aha et la première courbe de rétention par cohorte doivent être posées dès le Mois 1, avant le palier 100 vers 500, et surtout avant toute dépense en retargeting. C'est le seul gate qui manque au plan déjà écrit.

### Cadre 1 : une North Star Metric qui précède le revenu

Verba a un seul produit mais cinq jobs différents selon la persona (développeur Claude Code, professionnel de la confidentialité, opérateur voix-first, multilingue, penseur long-format). La tentation est de définir une NSM par job. C'est inutile ici : les cinq jobs convergent vers un seul comportement observable, celui qui fait la promesse du produit ("Speak it. Send it clean.") et maintenant celui de JARVIS ("dites-le une fois, c'est fait").

| Candidate | Nature | Verdict |
|---|---|---|
| Téléchargements du .dmg | Vanity | Rejeté : monte même si personne n'utilise le produit |
| Dictations lancées | Activité | Rejeté : peut doubler parce que l'utilisateur galère et recommence, pas parce qu'il progresse |
| Comptes créés | Vanity | Rejeté : ne dit rien de la valeur reçue |
| **Actions vocales abouties et utilisées, par utilisateur actif et par semaine** | Valeur reçue | **Retenu** |

La NSM retenue se définit ainsi : une dictation dont le texte propre a été effectivement collé, envoyé ou utilisé (pas simplement généré), plus une action JARVIS confirmée puis exécutée avec succès (l'email parti, le ticket Linear créé, la réunion posée). Elle passe le test de la doctrine : si ce chiffre double, l'utilisateur va objectivement mieux, il a dicté l'email sensible sans y repenser, le suivi qu'il repoussait depuis trois jours est parti pendant qu'il le disait. Elle précède le revenu (elle mesure l'usage réel avant le paiement) et elle ne peut pas grimper pendant que le client souffre, contrairement au nombre de dictations lancées.

Pilotage à deux étages pour Verba : le portefeuille (Verba aujourd'hui, futurs produits Station Partners demain) se pilote au MRR ; Verba se pilote à cette NSM unique, ventilée par mode (Raw, Polish, Intent, Coding, Translate, Context, Voice Notes, Voice Tasks) pour voir quel job tire vraiment l'usage.

### Cadre 2 : les quatre moteurs de Verba relus comme des growth loops (pas des funnels)

Le brief liste déjà quatre moteurs de croissance. Vus par la doctrine, trois d'entre eux sont des boucles authentiques (l'output d'un tour réamorce l'entrée du suivant) et un seul reste, pour l'instant, un entonnoir classique.

**1. Content loop (le plus fort chez Verba, encore incomplet).** Le founder build-in-public publie des chiffres bruts sur X, cela attire des développeurs Claude Code, une partie installe Verba, leur usage génère de la matière (clips, résultats, cas d'usage) qui nourrit le post suivant. C'est exactement la mécanique qui a porté Lovable de 0 à 100 M$ ARR en huit mois avec moins de 10% de dépense payante. Mais chez Lovable, Replit et Higgsfield, la boucle se referme par un artefact produit partageable : le badge "Built with Lovable", les 9M+ projets publics Replit, les clips Higgsfield générés par les utilisateurs eux-mêmes. Verba n'a pas encore cet artefact. C'est le chantier prioritaire du brief ("le build le plus prioritaire de Verba") et c'est aussi, vu par cette Partie, la pièce qui manque pour que la content loop compose au lieu de dépendre uniquement de la voix du founder.

Exemple de fin de clip à construire (copy publiable) :

> *"I said it. It did it."*
> *Made with Verba, verba.run*

**2. Viral / referral loop (codée, invisible).** Le parrainage "Free Month" et le leaderboard public existent déjà en code mais ne sont montrés nulle part dans le produit. Une boucle qui existe sans être visible n'a pas de facteur viral k, elle a un k de zéro par construction. Rendre le parrainage visible au moment exact où l'utilisateur vient de vivre son action aboutie (juste après qu'un email JARVIS soit parti, par exemple) est la façon la moins chère de faire décoller ce k. Même un k modeste de 0,5, rappelle la doctrine, réduit déjà fortement le coût d'acquisition, ce qui compte d'autant plus pour un solo dont le budget mensuel de croissance payante est de 10 à 15 euros par jour.

Exemple de microcopy à afficher juste après une action JARVIS confirmée (publiable) :

> *Done. Know someone drowning in follow-ups too? Send them Verba, you both get a free month.*

**3. Paid loop (correctement gelé pour l'instant).** Le budget prévoit du retargeting seulement après le palier 100, une fois la conversion prouvée. C'est exactement la discipline LTV/CAC de la doctrine. Avec un ARPU mixé d'environ 7,6 euros par mois et un coût d'inférence proche de zéro (le modèle BYO-AI réutilise l'abonnement Claude Code déjà payé par l'utilisateur), la marge brute par client est proche de 100%. Sur une durée de vie moyenne indicative de 12 mois, cela donne une LTV de l'ordre de 90 euros. Pour respecter la règle LTV/CAC ≈ 3 avec un payback de quelques mois, le CAC cible de la première vague de retargeting ne devrait pas dépasser environ 25 à 30 euros par client payant. C'est un chiffre à vérifier avec les vraies données de conversion du palier 100, jamais à deviner davantage.

**4. Communauté et lancements (Show HN, r/ClaudeAI, r/macapps, Product Hunt).** C'est le seul des quatre moteurs qui reste, par nature, un entonnoir à un coup : chaque lancement doit se repayer. Sa valeur n'est pas de composer seul mais d'alimenter les deux vraies boucles (matière pour le build-in-public, premiers utilisateurs pour amorcer le parrainage et le leaderboard).

### Cadre 3 : lire la courbe de rétention et lancer le test PMF avant le palier 500

Verba n'a pas encore de courbe de rétention. Il faut la première dès que les 100 premiers clients existent, et idéalement avant, sur les utilisateurs de la version gratuite. La lecture est binaire : une courbe qui s'effondre vers zéro sur J1/J7/J30 dit "pas encore de product-market fit, ne finance rien" ; une courbe qui se stabilise sur un plateau, même bas, dit "il existe un noyau pour qui ce produit est déjà vital, la hauteur du plateau est le vrai marché adressable".

Le test PMF de Sean Ellis complète la courbe par la voix du client. À poser au beachhead (les développeurs Claude Code déjà actifs), pas à l'ensemble de la base :

> *"How would you feel if you could no longer use Verba to turn your spoken thoughts into finished text and actions?"*
> Very disappointed / Somewhat disappointed / Not disappointed

Le seuil à viser est 40% ou plus de "very disappointed" chez les utilisateurs actifs du beachhead. En dessous, la bonne réaction n'est pas de pousser plus de trafic mais d'isoler qui sont les "very disappointed", quel job précis (coder à la voix, l'email sensible, le suivi qui part tout seul) leur fait dire ça, et de resserrer le produit et le message sur ce noyau avant d'élargir aux personas d'expansion.

### Cadre 4 : le churn précoce, chantier numéro un contre le seuil des 33 dictations

Avec un free-to-paid visé à 7%, la majorité des utilisateurs abandonnent avant la conversion. La question à trancher est : abandonnent-ils avant ou après avoir vécu l'action aboutie. Le tableau ci-dessous cadre les moments de fuite les plus probables du parcours Verba et la skill qui les traite.

| Moment de fuite | Job non résolu | Skill d'exécution |
|---|---|---|
| Avant la première dictation propre collée ou envoyée | N'a jamais vu que "ça marche vraiment" | /mk-onboarding-cro |
| Avant la première action JARVIS confirmée | N'a pas compris que le produit "fait", pas seulement "écrit" | /mk-onboarding-cro |
| Entre dictation 15 et 33 (fin du quota gratuit) | A eu le déclic mais pas encore vu la valeur composée sur la durée | /mk-churn-prevention |
| Pendant l'essai de 7 jours après paiement | Doute sur la valeur au prix mensuel | /mk-churn-prevention |
| Après le premier mois payé | Usage retombé, aucune nouvelle habitude installée | /retentionaudit + /mk-churn-prevention |

Le levier le plus rentable n'est pas un upsell sophistiqué, Verba n'a d'ailleurs qu'un seul palier payant pour l'instant (le Founder / Lifetime reste à construire). C'est de raccourcir au maximum le chemin vers l'instant où le produit "fait clic" : idéalement dans la première session, avant même d'épuiser les premières dictations gratuites. Concrètement, cela veut dire guider le tout premier usage vers une action JARVIS visible et confirmée (pas seulement une dictation simple), parce que c'est là que la promesse "dites-le une fois, c'est fait" devient tangible plutôt que théorique.

### Le stack de mesure minimal, sans dashboard qu'on ne regarde jamais

Verba n'a pas besoin d'un RevOps. Il a besoin de trois événements bien posés et d'un seul écran hebdomadaire.

| Élément | Ce qu'on pose |
|---|---|
| Analytics produit léger | PostHog ou équivalent : événement inscription, événement "aha" (première dictation propre utilisée ou première action JARVIS confirmée et exécutée), événement NSM (action vocale aboutie hebdomadaire) |
| Cohortes | Calculées nativement dès les events posés, lues par mois d'installation (avant lancement Product Hunt vs après) |
| Attribution | Un champ "comment as-tu connu Verba ?" à l'inscription, plus UTM sur chaque lien de clip, de post et de lien Show HN. Directionnel seulement : quel canal amène des clients qui restent, jamais une attribution multi-touch parfaite |
| Une vue hebdomadaire unique | NSM, rétention de la dernière cohorte, MRR, churn. Le seul écran à ouvrir chaque semaine pendant les 90 jours |

### Ce qu'il faut tester : trois hypothèses, notées ICE, sur l'activation avant l'acquisition

| # | Hypothèse (format "Parce que... je crois que... je le saurai si...") | Impact | Confidence | Ease | Score ICE |
|---|---|---|---|---|---|
| 1 | Parce qu'une majorité des utilisateurs gratuits n'atteignent jamais une action JARVIS confirmée dans leur première session, je crois qu'un onboarding qui met en scène une action JARVIS dès la première minute portera l'activation "aha" J1 significativement au-dessus du niveau actuel (à mesurer dès l'instrumentation posée). Je le saurai si le taux d'utilisateurs ayant vécu l'aha en J1 progresse d'un palier net sur deux cohortes consécutives. | 9 | 6 | 7 | 378 |
| 2 | Parce que la content loop dépend aujourd'hui uniquement de la voix du founder, je crois que livrer le format de clip "I said it, it did it" avec end-card "Made with Verba" générera des inscriptions attribuées à ce format dès la première semaine de diffusion. Je le saurai si l'UTM du clip capte un volume d'inscriptions mesurable et non nul sur 7 jours. | 8 | 5 | 4 | 160 |
| 3 | Parce que le parrainage et le leaderboard existent en code mais sont invisibles, je crois que les afficher juste après une action JARVIS aboutie fera passer le facteur viral k au-dessus de zéro. Je le saurai si un pourcentage mesurable des nouvelles inscriptions du mois porte un code de parrainage. | 7 | 7 | 8 | 392 |

Les trois hypothèses sont priorisées sur l'activation et la rétention, pas sur l'acquisition, en accord avec l'ordre de la doctrine. La troisième et la première arrivent en tête au score ICE : rendre le parrainage visible et fixer l'onboarding sont les deux chantiers à attaquer en premier, avant que la boucle de contenu ne prenne le relais en semaine 2.

### Le système qui compose, assemblé pour Verba

Les quatre pièces s'emboîtent dans l'ordre suivant. La NSM ("actions vocales abouties et utilisées par semaine") définit ce que veut dire progresser. La courbe de rétention par cohorte, lue en parallèle du test PMF Sean Ellis chez le beachhead développeur, dit si chaque client acquis s'accumule ou s'évapore. La content loop et la viral loop, une fois le clip de partage construit et le parrainage rendu visible, font que chaque utilisateur satisfait réamorce l'entrée du tour suivant au lieu d'exiger une nouvelle dépense. Et le rythme d'expérimentation, hypothèse par hypothèse, améliore chaque cohorte suivante plutôt que de deviner à l'aveugle. Le paid loop, correctement gelé jusqu'à preuve de LTV/CAC, ne fait qu'amplifier un système qui compose déjà tout seul, jamais le fabriquer.

**Résumé :** Definir la NSM, tracer la première courbe de retention et rendre visible le parrainage avant le palier 500, sans quoi Verba financerait de l'organique gratuit dans un seau dont personne ne connait la fuite.
