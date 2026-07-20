## Correctif propose (en attente de verification sur appareil)

Environnement d'analyse : hote Linux, sans Xcode ni Mac. Le correctif ci-dessous est un diagnostic statique + un patch chirurgical. Il N'A PAS ete construit ni teste sur un Mac. A valider en conditions reelles avant de marquer resolu.

### Ce qui etait demande
La feature du screenshot ("Deliver each dictation where you started it") ne se comporte pas comme decrit pendant les tests. Et retirer l'em-dash present dans le texte.

### Cause racine
La feature (reglage routeResultToOrigin, ON par defaut) est bien cablee : le toggle appelle bien le chemin de livraison, et quand l'app d'origine n'est plus au premier plan, `Output.paste(_:rich:target:)` (Paste.swift) tente de la ramener au premier plan puis de coller.

Le bug est dans la branche "origine plus au premier plan" (Paste.swift:273-281). Le code appelle `app.activate()` puis, sur un delai FIXE de 0.15s, restaure le focus et envoie Cmd-V, SANS jamais confirmer que l'app d'origine est reellement redevenue frontmost. Depuis une app de barre de menus (LSUIElement), reactiver une app en arriere-plan (surtout a travers un autre Space) prend souvent plus de 150ms. Le Cmd-V part donc pendant que l'app ou l'utilisateur s'est deplace (app B) est encore au premier plan : le texte atterrit dans la mauvaise app, ou nulle part. La promesse du texte d'aide ("le resultat attend dans Sessions au lieu d'aller dans la mauvaise app") n'etait honoree que si l'Accessibilite n'est pas accordee, jamais dans cette course d'activation.

### Le correctif
1. Paste.swift : remplacer le collage a delai fixe par un collage confirme et borne (`pasteWhenFrontmost`) : on attend (jusqu'a ~1.2s) que l'app d'origine soit reellement au premier plan avant de restaurer le focus et coller. Si elle ne revient jamais, on ne colle pas : le texte reste dans le presse-papier et attend dans Sessions, exactement le contrat annonce. La restauration optionnelle du presse-papier precedent (`scheduleRestore`) est deplacee pour ne se declencher qu'apres un collage reel, afin de ne jamais ecraser le texte dicte quand on renonce.
2. SettingsView.swift:1178 : em-dash retire du texte d'aide ("...you started in, so parallel dictations..."). La chaine n'est dans aucun .lproj, donc ce seul correctif code retire l'em-dash dans toutes les langues.

Fichiers touches : Sources/Verba/Paste.swift, Sources/Verba/SettingsView.swift

### Verification
- Statique : `git apply --check` passe proprement sur les deux hunks (patch applicable sur HEAD).
- Runtime : NON verifie (pas de Mac dans cet environnement). A tester sur appareil : dicter dans l'app A, passer a l'app B pendant le traitement, confirmer que le resultat atterrit bien dans le champ d'origine de A (et jamais dans B), et que si A a ete fermee le resultat attend dans Sessions.

### Limite connue a valider sur appareil
Le closure de livraison (AppDelegate deliver, ~1921-1933) met `session.autoPasted = true` de facon synchrone des que `Output.paste` renvoie true. Si l'activation ne gagne jamais la course, la Session peut donc etre marquee "auto-collee" alors que rien n'a ete colle (le texte reste sans danger dans le presse-papier et dans la liste Sessions). Reconcilier proprement ce flag demanderait de rendre la livraison asynchrone : hors du perimetre chirurgical de ce ticket, a arbitrer.