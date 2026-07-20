## Rapport de diagnostic (correctif propose, verification on-device en attente)

**Ticket:** VER-68 : Feedback, "Improve with AI" renvoie toujours une erreur
**Mode:** FIX
**Statut:** Diagnostic termine, correctif propose. Non verifiable en runtime ici (CI Linux, pas de Xcode ni d'appareil macOS) : ce correctif reste a builder et tester sur un Mac avant merge.

### Ce qui est demande
> "J'ai toujours une erreur lorsque je clique sur Improve with AI. Je suis avec Parakeet et je suis en modele local donc probablement Queen mais c'est etrange car je ne me souviens pas l'avoir telecharge ou avoir vu une barre de download au tout debut... il faut diagnostiquer et fixer le probleme."

### Le modele local est-il present ? Presque certainement NON
Le backend de reecriture de cet utilisateur (Parakeet + mode Automatique par defaut) se resout vers le modele on-device qwen3:8b ("Qwen"), car il n'a ni le CLI Claude Code ni de cle API (Settings.swift:147-150, Settings.swift:885). Ce modele (~5 Go via Ollama) n'est vraisemblablement pas installe : la barre de telechargement visible n'apparait que dans l'onboarding "Fully local" (OnboardingView:300) et dans les Reglages, jamais depuis le panneau Feedback. Le declenchement silencieux au lancement (AppDelegate.swift:462-463) perd sa progression. D'ou "je n'ai jamais vu de barre de download".

### Cause racine
"Improve with AI" depend strictement de ce modele local : improveWithAI, puis Reprompter.reprompt, puis LocalLLM.chat (FeedbackView.swift:486-572, Reprompter.swift:125-126). Modele absent ou serveur non demarre : LocalLLM.chat leve LLMError.settingUp / notRunning / notDownloaded (LocalLLM.swift:349-396). Le catch de improveWithAI (FeedbackView.swift:565-569) aplatit cet etat transitoire de "telechargement en cours" en une erreur rouge avec triangle d'alerte (FeedbackView.swift:180-183), sans progression ni action possible. Chaque clic ressemble donc a une erreur permanente. Ce n'est PAS le bug d'installation moteur de la v0.9.73 (Changelog.swift:104-109) : la 0.9.95 embarque deja ce correctif.

### Correctif propose
- FeedbackView.swift (catch de improveWithAI) : distinguer les etats "AI on-device pas encore prete" (settingUp / notDownloaded / notRunning) d'une vraie erreur backend. Pour ces etats, (re)declencher le setup local idempotent (LocalSetupProgress.shared.start()) pour que le telechargement demarre reellement depuis cette surface, et afficher un message clair et non alarmant qui rappelle que "Give feedback" envoie sans IA.
- Ajout d'un petit helper statique isLocalSetupPending(_:).

### Avant / Apres
| | Avant | Apres |
|---|---|---|
| Etat | Erreur rouge + triangle a chaque clic, aucune progression, aucune issue | Message clair "votre IA on-device se prepare (NN%)", le telechargement demarre/reprend, l'envoi reste possible via Give feedback |

### Limite honnete
Ce correctif ne rend pas Improve instantanement fonctionnel : le modele de ~5 Go doit finir de se telecharger. Il transforme une erreur repetitive et opaque en un etat clair et actionnable, et amorce reellement le telechargement. Le choix d'aller plus loin (afficher une vraie barre de progression ou un bouton "Configurer l'IA" dans le panneau Feedback) est une decision produit/design a trancher par l'operateur.

### Verification (en attente, on-device)
- [ ] Build SwiftPM sur Mac (impossible ici : hote Linux, pas de Xcode)
- [ ] Reproduire : Parakeet + Automatique, sans qwen3:8b installe, taper Improve with AI ; verifier le nouveau message et que le pull Ollama demarre
- [ ] Confirmer qu'une vraie erreur backend (mauvaise cle API) affiche toujours l'erreur detaillee