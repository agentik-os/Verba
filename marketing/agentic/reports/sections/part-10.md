## Partie 10. Vendre, founder-led et product-led

### Diagnostic : le prix impose le PLG, mais le fondateur vend quand même au début

Premier calcul, celui qui tranche tout le reste. Verba est vendu en freemium (33 dictées gratuites sans carte) puis en abonnement Pro mensuel ou annuel, avec un essai de 7 jours au paiement. La valeur moyenne visée est d'environ 7,6 euros par abonné et par mois, soit un ACV (annual contract value) d'environ 91 euros par an. Même en comptant large sur un plan annuel à prix plein, on reste très loin sous le seuil de 2 000 euros par an où un commercial devient mathématiquement finançable.

| Repère | Valeur Verba | Seuil doctrine | Conclusion |
|---|---|---|---|
| ACV moyen visé | ~91 EUR/an (7,6 EUR/mo blended) | sous ~2 000 EUR/an | PLG obligatoire |
| Complexité d'achat | un seul utilisateur, carte bancaire, aucune procurement | faible | pas de cycle de décision multi-personnes |
| Palier client visé | 100 puis 500 puis 1 000 puis 2 000 payants | volume, pas valeur unitaire | le produit doit vendre seul, à l'échelle |

Verba n'a pas le choix du moteur : c'est le produit qui doit vendre, pas un humain au téléphone. Le signup flow, l'onboarding et le moment où l'utilisateur touche vraiment la valeur sont l'équipe commerciale de Verba. C'est déjà largement la doctrine derrière le plan en 90 jours du brief (funnel, share-clip, preuve, growth loops).

Mais la doctrine est claire sur un deuxième point que le plan actuel ne couvre pas encore explicitement : même un produit PLG se vend d'abord à la main. Le fondateur doit faire du founder-led sales sur les tout premiers clients, pas pour encaisser du revenu (le produit s'en charge), mais pour apprendre le langage exact que les gens utilisent pour décrire leur problème, matériau brut de tout le reste du marketing. Le brief le confirme en creux : il n'existe encore aucun témoignage public, et la fabrication de preuve honnête (10 à 20 citations réelles) est identifiée comme le premier chantier marketing. Ce chantier ne se fait pas par un formulaire NPS automatisé, il se fait par des conversations.

**Le vrai point de blocage** n'est donc pas le choix du moteur (déjà tranché par le prix), il est en amont et en aval du signup : personne n'a encore formellement identifié le aha moment de Verba, l'onboarding actuel ne pousse pas explicitement vers cette action précise, et les boucles de croissance déjà codées (parrainage, classement) restent invisibles faute de séquences de relance comportementales qui les activent. L'intérêt existe (calendrier de contenu, personas définis, positionnement clair), le revenu n'a pas encore de mécanisme d'onboarding qui le capture systématiquement.

### Les cadres retenus

Quatre cadres collent au blocage diagnostiqué : Jobs-to-be-Done pour cadrer chaque persona sur le bon déclencheur, aha moment et time-to-value pour reconstruire l'onboarding, feel-felt-found pour désamorcer les objections réelles de Verba, et le follow-up comportemental pour activer ce qui est déjà codé mais dort.

#### 1. Jobs-to-be-Done : le déclencheur avant la fonctionnalité

Chaque persona du brief est déjà écrit en langage JTBD (« le job qu'il embauche Verba pour faire »). Le travail restant est de transformer ça en questions de discovery réelles, posées à de vrais utilisateurs, pas en personas figés sur une slide.

| Persona | Job à accomplir | Question JTBD à poser | Déclencheur probable (compelling event) |
|---|---|---|---|
| Développeur Mac déjà sur Claude Code | Penser à voix haute, coder plus vite, mains libres | « La dernière fois que vous avez tapé un prompt long au clavier, qu'est-ce qui s'est passé dans votre journée ce jour-là ? » | Fatigue de taper des prompts longs, RSI, envie de coder en marchant |
| Pro exposé à des données sensibles (avocat, médecin, fondateur, journaliste) | Dicter du contenu sensible sans que ça sorte de la machine | « Qu'est-ce qui vous empêche aujourd'hui de dicter vos notes les plus sensibles ? » | Une fuite ou une inquiétude récente sur un outil cloud |
| Fondateur/PM vivant dans Gmail, Slack, Calendar | Dire une intention une fois, la voir exécutée | « La dernière relance ou le dernier ticket que vous avez remis à demain, qu'est-ce qui l'a empêché de partir tout de suite ? » | Une tâche administrative reportée trois fois de suite |
| Travailleur multilingue | Penser dans sa langue, écrire dans celle de son interlocuteur | « Comment vous faites aujourd'hui pour écrire un email pro dans une langue qui n'est pas la vôtre ? » | Un email important à envoyer dans une langue non maîtrisée |
| Preneur de notes long-format | Parler une heure, récupérer un document propre | « Quand vous avez besoin de réfléchir à voix haute pendant longtemps, qu'est-ce que vous faites du résultat aujourd'hui ? » | Une réunion ou un brainstorm à retranscrire après coup |

Le point clé : on ne pitche jamais dans ces conversations. On pose la question, on note les mots exacts, et le mot « pourquoi maintenant » compte plus que le reste, il révèle si l'intérêt est réel ou poli.

#### 2. Aha moment et time-to-value : reconstruire l'onboarding comme équipe commerciale

Verba a en réalité deux aha moments candidats, pas un, parce que le produit a deux couches de valeur.

| Couche | Aha moment candidat | Comment le mesurer | Friction actuelle à couper |
|---|---|---|---|
| Dictée | La première fois que le texte sort assez propre pour être envoyé sans une seule correction | Première dictée collée sans édition manuelle | Rien ne guide vers un cas d'usage précis dès l'ouverture, l'utilisateur tâtonne sur le mode à choisir (Raw, Polish, Intent...) |
| JARVIS (l'agent) | La première action réellement exécutée dans une autre app après confirmation, un email envoyé, un ticket créé | Premier « Confirm » validé sur une action Intent | Personne n'est explicitement invité à essayer une action JARVIS pendant les 33 dictées gratuites, l'utilisateur peut consommer tout son quota en dictée simple sans jamais voir la vraie différenciation |

Le deuxième aha moment est le plus important des deux : c'est celui qui n'existe chez aucun concurrent de dictée cloud ou locale. Un utilisateur qui n'a jamais vu JARVIS planifier puis exécuter une action après son accord n'a en fait jamais vu ce qui rend Verba différent, même s'il a dicté cent fois.

Redesign concret de l'onboarding, dans l'esprit « moins de douze cases, une seule action » :
- À la première ouverture, un seul écran de démonstration guidée propose de dire une phrase type dans une app de test (« reply to this email and say the proposal is ready Friday »), montre le plan que JARVIS construit, affiche le bouton Confirm bien visible, puis exécute. Zéro configuration avant cette démonstration.
- Le compteur de 33 dictées gratuites reste, mais l'app pousse activement vers ce moment JARVIS plutôt que de laisser l'utilisateur épuiser son quota sur de la simple retranscription.
- Chaque champ de compte différé après ce moment : email de confirmation, préférences de langue, connexion aux apps tierces, tout ce qui n'est pas strictement nécessaire pour dire la première phrase et voir l'action se faire.

Objectif de time-to-value : sous 5 minutes entre l'ouverture de l'app et le premier « Confirm » validé, au même ordre de grandeur que le wow moment de Cursor cité dans le playbook de croissance du brief.

#### 3. Feel-felt-found : les objections réelles de Verba, pas des objections génériques

En PLG B2C sans procurement, l'objection « autorité » (« je dois en parler à mon service achats ») disparaît presque entièrement, elle ne concerne qu'un futur palier équipe hors scope actuel. Les quatre objections qui comptent vraiment pour Verba :

| Objection | Ce qu'elle veut vraiment dire | Réponse feel-felt-found (copy publiable, EN) |
|---|---|---|
| Prix (« encore un abonnement ») | Perçoit un coût qui s'ajoute à ceux déjà payés | "I get it, another subscription feels like a lot. A lot of developers felt the same until they noticed Verba reuses the Claude subscription they already pay for. No second bill for the intelligence, just the app." |
| Confiance / vie privée (« ma voix part où ? ») | Peur que le contenu sensible soit enregistré ou envoyé ailleurs | "That worry is fair, most voice apps do send audio to a server. Early users felt exactly that hesitation, until they saw the processing happen fully on their own Mac, with nothing uploaded." |
| Confiance / contrôle (« l'agent va faire quoi tout seul sur mon ordinateur ? ») | Peur de perdre le contrôle d'une action automatisée | "Makes sense to want to stay in control. Other users asked the same question before trying it, then found that JARVIS always shows the plan first and waits for a Confirm before doing anything." |
| Besoin (« j'ai déjà la dictée native ») | Ne voit pas encore le saut de valeur au-delà de la dictée simple | "Fair, native dictation does the basics. People who compared them side by side found the difference the moment they asked Verba to actually finish a task, not just type it." |

Ces quatre réponses respectent la règle d'honnêteté : elles décrivent un mécanisme réel (traitement local, étape Confirm visible, réutilisation de l'abonnement Claude), aucune ne s'appuie sur un chiffre ou une citation qui n'existe pas encore. Une fois les 10 à 20 témoignages honnêtes collectés (chantier déjà identifié dans le brief), chaque « d'autres ont ressenti la même chose » pourra s'ancrer sur une vraie citation nommée plutôt qu'une formule générique.

#### 4. La fortune est dans le follow-up : activer ce qui dort déjà

Le brief signale que le parrainage (« Free Month ») et le classement public sont codés mais invisibles. C'est très exactement le symptôme d'un produit PLG sans séquence comportementale : le mécanisme existe, personne ne le déclenche au bon moment.

| Déclencheur comportemental | Objectif de la séquence | Exemple de sujet d'email (EN) |
|---|---|---|
| Inscrit, mais n'a pas atteint l'aha moment JARVIS sous 48h | Ramener vers la première action confirmée | "One sentence, one action: try it now" |
| A atteint l'aha moment, quota de dictées gratuites presque épuisé, pas d'upgrade | Montrer la valeur au moment exact où la limite se fait sentir | "You've been getting things done, here's what changes with Pro" |
| A utilisé Verba plusieurs fois, n'a jamais invité personne ni regardé le classement | Activer la boucle de parrainage déjà codée | "Give a friend a free month, on us" |
| A vu le classement une fois, n'y est jamais revenu | Réactiver la mécanique de jeu (100 niveaux) sans en faire une notification vide | "You're a few dictations from your next level" |

Le principe qui compte plus que le contenu de chaque email : le déclenchement est comportemental (une action non faite dans une fenêtre de temps précise), jamais un simple compte à rebours calendaire. Trois à cinq relances espacées, chacune apportant une vraie raison plutôt qu'un rappel vide, battent une seule relance générique. Ces séquences sont un chantier de mk-email-sequence et mk-onboarding-cro, pas une automatisation à écrire une fois pour toutes tant que le aha moment n'a pas été validé par de vraies données d'usage.

### Ce que le fondateur doit faire à la main, cette semaine

Le PLG ne dispense pas de founder-led sales, il en déplace l'objectif : apprendre, pas encaisser. Concrètement pour Verba :
- Bloquer 15 à 20 conversations avec les premiers utilisateurs du beachhead (développeurs Claude Code déjà actifs), en DM ou en appel court, en interdiction de pitch, uniquement les questions JTBD du tableau ci-dessus. Noter les mots exacts, ils deviendront les titres d'accroche et les hooks de contenu.
- Transformer 10 à 20 de ces conversations en témoignages honnêtes nommés (avec accord explicite), le chantier de preuve déjà identifié comme prioritaire dans le brief.
- Ne pas coder la séquence de relance comportementale avant d'avoir vu, à la main, au moins une dizaine d'utilisateurs passer réellement par le moment JARVIS. Un process automatisé sur un aha moment jamais vérifié fige une hypothèse fausse à grande échelle.

### Ce qu'il faut tester

Hypothèse falsifiable numéro un : si le premier aha moment mesuré est bien « premier Confirm JARVIS validé » et que l'onboarding est reconstruit pour y amener l'utilisateur en moins de 5 minutes, le taux de conversion gratuit vers payant doit se rapprocher du repère du plan (environ 7 %), contre un taux aujourd'hui non mesuré faute d'instrumentation sur ce moment précis. Si, après redesign, le taux ne bouge pas alors que le time-to-value a bien baissé, l'hypothèse du aha moment est fausse et il faut retourner en discovery plutôt que de continuer à optimiser l'onboarding autour du mauvais moment.

Hypothèse falsifiable numéro deux : la séquence « inscrit mais pas d'aha en 48h » fait remonter une part mesurable des utilisateurs restés bloqués sur la dictée simple vers une action JARVIS confirmée. Si le taux de réactivation reste proche de zéro après trois envois, le problème n'est pas le rappel mais l'onboarding lui même, et c'est là qu'il faut recreuser.

--- **Resume :** L'ACV de Verba impose le PLG sans discussion possible, mais le fondateur doit quand même vendre à la main ses tout premiers utilisateurs pour apprendre leur langage et fabriquer la preuve honnête qui manque. Le vrai chantier est de nommer le aha moment JARVIS, reconstruire l'onboarding pour y amener en moins de 5 minutes, répondre aux quatre objections réelles avec honnêteté, et activer par des relances comportementales le parrainage et le classement déjà codés mais dormants.
