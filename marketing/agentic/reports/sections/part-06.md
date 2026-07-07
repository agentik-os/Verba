## Partie 06. Moteur de contenu, SEO et GEO

### Diagnostic : où Verba est invisible aujourd'hui

Verba a un moteur de distribution sociale (verba-daily.ts, une image de marque plus une légende par jour, publiées sur 16 comptes via omega-zernio) mais aucun moteur de découvrabilité. C'est une distinction critique : poster une image par jour sur X, LinkedIn ou TikTok construit de la présence, pas de l'autorité thématique. Rien de ce flux n'est indexable par Google ni citable par un LLM sous forme de réponse. À la date de ce rapport, trois étages saignent en même temps.

D'abord, zéro autorité thématique construite. Il n'existe pas de cluster de contenu autour de la catégorie que Verba tente de créer, à savoir « l'agent vocal privé pour Mac ». Pas de page pilier, pas de pages support, pas de maillage. Ensuite, zéro présence GEO mesurée. Personne ne sait aujourd'hui si ChatGPT ou Perplexity citent Verba, ou même le mentionnent, quand un utilisateur pose une question du type « quelle app de dictation Mac garde mes données privées ». Enfin, le levier le plus documenté du plan de croissance, la SEO et GEO de comparaison (moteur D : les pages `/vs` et `/compare`, environ 24 concurrents multipliés par 10 personas), est planifié mais pas construit. C'est l'étage qui saigne le plus, précisément parce que c'est celui qui a le meilleur rapport effort/impact pour Verba : la catégorie est encore vide (personne ne possède « privé + réutilise ton abonnement Claude + agit »), donc chaque comparaison bien faite peut devenir la réponse de référence, pour Google comme pour un LLM.

Un point positif à ne pas perdre : Verba a déjà, sans le savoir, la matière première d'un contenu non réplicable par l'IA. Le fondateur construit en public, les chiffres réels existent (paliers de 100 à 2 000 abonnés payants, marge quasi nulle en coûts d'inférence grâce au BYO-AI), et le produit a une mécanique différenciante testable (JARVIS planifie, montre, puis agit seulement après confirmation). C'est exactement le type de perspective vécue que la doctrine identifie comme le seul avantage qui résiste à la commoditisation du contenu généré par IA. Le chantier n'est donc pas de produire plus, il est de transformer ce qui existe déjà en un système qui compose : cluster, intention, citation, distribution.

### Cadre 1 : le cluster de comparaison comme page pilier de catégorie

Verba ne peut pas gagner un mot-clé large comme « dictation app mac » frontalement : Wispr Flow (valorisé autour de 2 milliards de dollars en 2026), Superwhisper et MacWhisper occupent déjà ce terrain. La bonne porte d'entrée n'est pas le mot-clé large, c'est le cluster de comparaison, parce qu'il combine trois choses à la fois : une intention commerciale forte (l'utilisateur compare avant d'acheter), une concurrence de contenu plus faible sur les combinaisons précises, et un angle que Verba est seul à pouvoir tenir honnêtement, la confidentialité totale plus l'action.

**Mécanisme.** Le cluster se construit en une page pilier de catégorie et des pages support de comparaison, chacune répondant à une intention précise : un utilisateur qui tape « Verba vs Wispr Flow » n'a pas la même intention que celui qui tape « meilleure app de dictation pour développeur Mac ». Chaque page support doit répondre exactement à cette intention-là, pas à une version générique recyclée d'un gabarit.

**Application concrète.** Le plan indique 24 comparateurs multipliés par 10 personas, soit 240 combinaisons possibles. Les construire toutes en même temps et de façon identique serait l'erreur exacte que la doctrine met en garde : du contenu IA générique sans angle, qui se noie dans la commodity et ne sera cité par personne. La bonne séquence est un déploiement par vagues, priorisé par intention et par persona, chaque page portant une preuve testée à la main, pas un tableau de features copié.

| Vague | Combinaison prioritaire | Pourquoi | Angle propriétaire (non copiable) |
|---|---|---|---|
| Semaine 1 à 2 | Verba vs Wispr Flow, persona développeur Claude Code | Le concurrent le plus cité, le persona du beachhead | Test réel : latence, confidentialité, réutilisation de l'abonnement Claude déjà payé |
| Semaine 3 à 4 | Verba vs Superwhisper, persona pro de la confidentialité (avocat, médecin) | Superwhisper est le repère « local » actuel | Test réel de ce qui reste réellement local (voix ET planification d'action) chez chacun |
| Semaine 5 à 6 | Verba vs MacWhisper, persona preneur de notes long format | MacWhisper est perçu comme l'outil transcription pure | Test réel sur une heure de mémo vocal transformée en document propre |
| Semaine 7 à 8 | Verba vs Otter.ai / Dragon, persona opérateur vocal (fondateur, PM) | Comparateurs legacy cloud, angle action | Démonstration réelle : dire une intention, JARVIS planifie, l'utilisateur confirme, l'action se fait |
| Mois 3 | Élargir aux 20 comparateurs restants, personas multilingues et YMYL | Une fois le format prouvé | Réutiliser le gabarit de test, jamais le gabarit de texte |

Chaque page de comparaison doit rester structurée pour l'extraction : une définition nette en tête de section, un tableau de faits vérifiés, jamais de claim inventé sur un concurrent (gate d'honnêteté). Exemple de titre publiable :

> H1: **"Verba vs Wispr Flow: the one that keeps your voice on your Mac"**
> Meta description: **"Both turn speech into clean text. Only one never sends your voice, or the plan of what it's about to do, off your machine. Here is the honest side-by-side."**

### Cadre 2 : SEO par intention, longue traîne et confiance (E-E-A-T)

Verba ne doit pas viser des requêtes larges et verrouillées comme « voice assistant » ou « speech to text app ». La doctrine est claire : cent requêtes longue traîne dominées battent une requête phare jamais atteinte. Le travail commence donc par cartographier l'intention réelle derrière chaque requête, persona par persona, puisque le job à accomplir change à chaque profil.

| Persona | Intention derrière la recherche | Exemple de requête longue traîne | Format qui répond |
|---|---|---|---|
| Développeur Claude Code | Informationnelle, gagner du temps en codant | "voice input for Claude Code on Mac" | Page support technique + démo courte |
| Pro de la confidentialité (avocat, médecin) | Commerciale, lever le doute sur la confidentialité | "dictation app that never uploads my voice mac" | Page support confiance, avec preuve technique honnête |
| Opérateur vocal (fondateur, PM) | Transactionnelle, résoudre une corvée précise | "app that files a Linear issue by voice" | Page support cas d'usage, avec le pas Confirm visible |
| Multilingue | Informationnelle, capacité linguistique | "dictate in French get clean English text mac" | Page support fonctionnalité |
| Preneur de notes long format | Informationnelle, gain de temps sur la prise de notes | "turn a one hour voice memo into a clean document" | Page support cas d'usage |

Sur la confiance, Verba n'est pas à proprement parler YMYL (santé, argent, sécurité au sens strict), mais deux de ses personas d'expansion, l'avocat et le médecin, dictent des contenus sensibles. Le standard de confiance à appliquer est donc le même que pour un sujet YMYL adjacent : un auteur identifié (le fondateur, avec une bio réelle, pas anonyme), des sources datées, et surtout aucune affirmation de sécurité qui ne soit pas vraie et vérifiable. C'est un point non négociable : la confidentialité est la promesse centrale de Verba, donc la moindre approximation sur ce terrain détruit l'actif de confiance que le contenu est censé construire.

Exemple de paragraphe qui tient la promesse sans survendre :

> "Verba processes your voice on your Mac. When you ask it to act, JARVIS plans the steps first and shows you exactly what it's about to do, nothing runs until you confirm. Nothing here has been independently audited yet, that is on our roadmap, but the architecture keeps your voice and the action plan on-device by design."

### Cadre 3 : GEO, être la source citée plutôt que seulement classée

Une partie croissante des recherches se termine sans clic : l'utilisateur demande directement à ChatGPT ou Perplexity, ou lit l'AI Overview de Google. Pour une catégorie que Verba est en train de créer (« agent vocal privé pour Mac »), c'est une opportunité rare, presque personne ne détient cette réponse aujourd'hui. Le premier réflexe doit être de mesurer, pas de produire à l'aveugle.

**Test à lancer dès cette semaine.** Poser à ChatGPT et à Perplexity les cinq questions suivantes, noter qui est cité, et recommencer chaque semaine :

1. "What is the most private dictation app for Mac?"
2. "Is there a voice app for Mac that can also take actions, not just transcribe?"
3. "What's a good alternative to Wispr Flow that keeps data local?"
4. "Can I use my Claude subscription for voice dictation on Mac?"
5. "Best voice app for developers using Claude Code on Mac"

Les leviers concrets, une fois la mesure en place : des unités de texte extractibles (une réponse directe en une à deux phrases, en tête de section, avant tout développement), le balisage schema (SoftwareApplication pour Verba lui-même, FAQPage sur chaque page support, Author sur la bio du fondateur, Organization sur la page à propos), et surtout la présence off-site. Les LLM lisent Reddit, Hacker News, les comparatifs tiers et de plus en plus YouTube, bien plus que le blog d'un site inconnu. C'est précisément ce que le moteur C du plan de croissance couvre déjà (Show HN, r/ClaudeAI, r/macapps, Product Hunt) : chaque réponse utile et honnête postée là-bas est, du point de vue GEO, une variable SEO à part entière, pas un simple canal d'acquisition.

Exemple de réponse Reddit qui sert la fois la communauté et le GEO, jamais promotionnelle en façade :

> "If privacy is the blocker, worth knowing that not every dictation app is cloud-only anymore. I've been testing Verba, it keeps the voice processing on-device and even the planning step for actions happens locally before anything runs, you confirm before it does anything. Not affiliated, just answering the actual question."

### Cadre 4 : distribution 1 vers N, et le moat de la construction en public

Le moteur automatisé de Verba (verba-daily.ts) produit déjà une image et une légende par jour sur 16 comptes. C'est un moteur de présence, pas encore un moteur de distribution d'autorité, parce qu'il ne repose sur aucune pièce mère. La correction n'est pas de remplacer ce moteur, c'est de lui donner une source : chaque semaine, une pièce mère dense (une page de comparaison testée à la main, une étude de cas chiffrée, une leçon réelle du lancement) devient le point de départ, et le contenu quotidien existant en devient une déclinaison parmi d'autres, pas une fin en soi.

| Pièce mère de la semaine | Déclinaison X (thread) | Déclinaison LinkedIn | Déclinaison vidéo courte (share-clip) | Déclinaison newsletter | Déclinaison communauté |
|---|---|---|---|---|---|
| Verba vs Wispr Flow (test réel) | Fil qui résume les 3 différences testées | Post avec l'angle personnel du fondateur sur pourquoi ce test | Clip "I said it, it did it" filmé pendant le test | Récit de comment le test a été mené | Réponse honnête sur r/macapps si le sujet remonte |

La règle de proportion de la doctrine s'applique directement ici : 20 % du temps sur la production de la pièce mère, 80 % sur sa redistribution et son recyclage en formats. Le piège à éviter explicitement pour Verba : publier une excellente comparaison, puis retourner au flux quotidien d'images sans jamais relier les deux. Une pièce non distribuée n'existe pas, quelle que soit sa qualité.

Le levier le plus rentable reste la construction en public du fondateur, déjà identifiée comme moteur A du plan. Les chiffres réels, les 100 premiers abonnés payants, la marge quasi nulle en coûts d'inférence grâce au BYO-AI, les paliers de 100 à 2 000, sont par nature un contenu qu'aucune IA générique ne peut produire à la place de Verba. C'est la matière première la moins chère et la plus différenciante du portefeuille de contenu, et elle alimente en même temps le GEO (données propriétaires citables), le SEO (E-E-A-T, un auteur réel avec des chiffres réels) et la distribution (X est déjà la plateforme principale identifiée pour le beachhead développeur).

Exemple de post de construction en public, sobre et honnête :

> "Verba hit its first paying users this week. No ads spent. What's working: developers who already pay for Claude Code get JARVIS as a planner for free, that reuse is the whole unlock. What's not working yet: nobody outside our own circle has tried the share-clip format. Building that next."

### Ce qu'il faut tester

Trois hypothèses falsifiables et bornées, à lancer en parallèle dès cette semaine, sans attendre que l'une soit terminée pour démarrer l'autre.

1. **Cluster de comparaison, vague 1.** Publier la page Verba vs Wispr Flow persona développeur avant la fin des deux prochaines semaines, avec au moins une donnée testée à la main. Mesure : position Google sur la requête exacte et présence dans les réponses ChatGPT/Perplexity à J+30.
2. **Présence GEO de départ.** Poser les cinq questions listées ci-dessus chaque semaine pendant un mois, consigner qui est cité. Mesure : Verba apparaît dans au moins une des cinq réponses à J+30, contre zéro aujourd'hui.
3. **Ratio 20/80 sur une pièce mère.** Choisir une semaine, produire une seule pièce mère et la décliner en cinq formats avant de produire quoi que ce soit d'autre. Mesure : le temps réellement passé en distribution dépasse 80 % du temps total consacré à cette pièce.
