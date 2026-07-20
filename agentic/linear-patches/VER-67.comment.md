## Fix Verification Report (correctif proposé, en attente de vérification sur appareil)

**Ticket:** VER-67 — Feedback: un screenshot glissé dans la zone de texte colle le chemin au lieu de l'attacher
**Mode:** FIX
**Statut:** Correctif proposé, PAS encore vérifié en runtime (analyse statique). Un build macOS est requis pour valider (impossible dans l'environnement Linux headless de cette passe).

### Ce qui est demandé
> "lorsque l'on prend un screenshot et qu'on le glisse dans la zone de texte, ça colle le chemin, mais ça ne ajoute pas le screenshot [...] il faut que si un screenshot soit glissé n'importe où au niveau de l'interface de feedback ça l'ajoute comme si on avait fait add file et pas que ça colle le chemin"

### Cause racine
La zone de texte est un `TextEditor` SwiftUI (`FeedbackView.swift:124`). Un `TextEditor` s'appuie sur un `NSTextView` AppKit, qui est lui-meme une cible de drop enregistree pour les types fichier/image et qui, par defaut, insere le CHEMIN du fichier comme texte. Le panneau possede deja le bon handler (`FeedbackView.swift:291-294`, `.onDrop(of: [.fileURL, .image])`) qui attache les vrais octets de l'image (travail VER-14). Mais le `NSTextView` est une vue descendante posee au-dessus de ce `.onDrop`: AppKit lui livre donc en priorite tout drop tombant sur la zone de texte. Il avale le drop et colle le chemin, et le `.onDrop` du panneau ne se declenche jamais a cet endroit. C'est pourquoi le "drop n'importe ou" fonctionne partout sauf sur l'editeur.

### Ce que j'ai change (chirurgical, 1 fichier)
- `Sources/Verba/FeedbackView.swift:124` : remplacement du `TextEditor` par un petit `FeedbackTextEditor` (NSViewRepresentable), sur le meme modele que `MarkdownEditor.swift` et `ReviewView.swift` deja presents.
- Ajout de `NonDroppingTextView: NSTextView` qui surcharge `updateDragTypeRegistration()` pour appeler `unregisterDraggedTypes()`. Sans type de drag enregistre, les drops fichier/image traversent jusqu'au `.onDrop` du panneau (handleDrop puis attach), exactement comme "Add file". La geometrie (inset conteneur a zero + lineFragmentPadding 5pt + `.padding(editorInset)` externe) est conservee pour garder l'alignement du placeholder, et le Coordinator preserve le binding `$draft` (dictee, Improve with AI, reset a l'envoi restent fonctionnels).

### Verification
- Analyse statique uniquement. Le patch a ete valide avec `git apply --check` (s'applique proprement).
- NON verifie: build/run reels impossibles ici (pas de Xcode/macOS). A tester sur appareil, 3 cas: (1) glisser la vignette de capture macOS sur la zone de texte, (2) glisser un PNG du Finder sur la zone de texte, (3) glisser sur une zone vide du panneau (ne doit pas regresser). Attendu dans les 3 cas: l'image s'attache (apercu + "Screenshot attached"), aucun chemin colle.
- Compromis assume: un glisser-deposer de TEXTE inter-app dans la zone de feedback n'insere plus le texte (les drops ne sont plus captes par l'editeur). Juge acceptable et coherent avec la demande "tout drop attache l'image".

### Checklist d'auto-verification
- [x] Cause racine identifiee et citee (file:line)
- [x] Changement chirurgical, un seul fichier, trace au ticket
- [x] Patch s'applique proprement (git apply --check)
- [ ] Verifie en runtime sur appareil (A FAIRE: build macOS, non realisable dans cette passe)