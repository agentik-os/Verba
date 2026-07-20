## Fix Verification Report (correctif proposé, non vérifié sur appareil)

**Ticket:** VER-64 , mode Intent: "transcription failed" et voix absente de l'historique
**Mode:** FIX
**Statut:** Correctif STATIQUE proposé. Non buildé ni testé (host Linux, pas de Xcode ni d'appareil ici).

### Ce qui est remonté
> "ça n'a pas fonctionné. Ça m'a mis un message transcription failed and je n'ai même pas eu mon voice dans l'historique. Une grosse friction utilisateur donc." (Parakeet local, app 0.9.93, macOS 26.3)

### Deux problèmes distincts
1. La transcription Parakeet a échoué (cause runtime, voir plus bas).
2. La friction majeure: l'enregistrement audio a été DÉTRUIT à l'échec, donc rien à récupérer ni à rejouer.

### Cause racine (problème 2, la perte de données, avec citations)
À l'échec, `runSession` appelle `self.purgeAudio(ctx.audioURL)` (Sources/Verba/AppDelegate.swift:1690), ce qui supprime le fichier audio temporaire, et `failSession` (AppDelegate.swift:1707) n'écrit jamais dans l'historique (`History.shared.add` n'est appelé que sur le chemin succès, AppDelegate.swift:1942). La voix est donc perdue définitivement. Le commentaire du code prétend "redo keeps lastAudioURL", mais `lastAudioURL` n'est mis à jour que dans `finish` (AppDelegate.swift:1798), jamais à l'échec: même le menu "Redo last in..." (AppDelegate.swift:2298) ne peut rien récupérer. L'invariant du code est violé.

### Ce que je change (chirurgical, 1 fichier)
- Sources/Verba/AppDelegate.swift, bloc catch de `runSession` (autour de 1690): on ne purge plus inconditionnellement. Échec bénin (silence, trop court, audio invalide): on purge (rien à récupérer). Vrai échec de transcription: on PRÉSERVE l'enregistrement comme source de redo (`lastAudioURL` + `lastAudioBundleID` + `lastAudioTarget`, exactement comme `finish`), pour que l'utilisateur relance le même audio via "Redo last in..." au lieu de tout redire.

### Sur le problème 1 (pourquoi Parakeet a échoué)
Cause exacte non déterminable en statique: erreur runtime FluidAudio/Parakeet (modèle en téléchargement, cache corrompu, ou échec de décodage). Elle est déjà loggée côté backend via `ErrorReporter.report` (AppDelegate.swift:1684) et `VerbaLog` (1683): tirer l'erreur réelle de la télémétrie pour cet utilisateur (ark2042 / qkj2oa1c). Note: `failSession` masque toute erreur non-Reprompt derrière un "Transcription failed" générique (AppDelegate.swift:1724-1725), donc l'utilisateur ne voit jamais la vraie raison.

### Statut de vérification (honnête)
STATIQUE UNIQUEMENT. Pas de build ni de run possible ici. Pas de capture avant/après, pas de gate d'audit 100/100, pas de vérification live. À builder et tester sur un Mac: provoquer un échec de transcription, confirmer que "Redo last in..." réapparaît et rejoue l'audio conservé.

### Décision produit en attente
Faut-il aussi faire apparaître les tentatives échouées dans l'Historique (formulation littérale de l'utilisateur) ? Cela demande du travail UI (HistoryView plus la sémantique d'une entrée sans texte) et sort du correctif chirurgical. À trancher par l'opérateur.

### Self-verification checklist
- [x] Cause racine du bug de perte de données identifiée et citée (file:line)
- [x] Correctif chirurgical, 1 seul fichier, chaque ligne tracée au ticket
- [ ] Build passé / live (IMPOSSIBLE ici, en attente de vérification sur Mac)
- [ ] Capture avant/après (IMPOSSIBLE ici)