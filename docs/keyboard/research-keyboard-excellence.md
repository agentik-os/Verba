# Recherche : faire du clavier iOS de verba un clavier custom d'excellence

> **Type** : rapport de recherche (état de l'art 2024-2026). Aucun code modifié.
> **Date** : 2026-07-16. Toutes les URLs citées ont été consultées le 2026-07-16.
> **Confiance** : `[CV]` = cross-validé (≥2 sources indépendantes) · `[SU]` = source unique · `[DATÉ]` = source >2 ans, à revalider sur iOS récent.
> **Point de départ** : `ios/VerbaKeyboard/KeyboardViewController.swift` (scaffold UIKit : barre de modes + bouton mic ouvrant l'app conteneur via `verba://record`, insertion du résultat via App Group `group.com.agentik.verba`). Douleur n°1 : pas de correcteur automatique, pas de frappe confortable.

---

## TL;DR (décisions clés)

1. **L'autocorrect est le vrai mur.** Apple ne fournit AUCUNE API d'autocorrection utilisable telle quelle dans une extension (UITextChecker retourne des suggestions non triées par probabilité sur iOS, UILexicon ne donne que contacts + raccourcis). Grammarly, SwiftKey et Fleksy y ont mis des équipes entières ; Fleksy en est mort. `[CV]`
2. **Le marché a tranché buy vs build** : en 2026, **KeyboardKit est le seul SDK clavier iOS commercial encore vivant** (Fleksy : site mort juin 2026 ; Typewise : pivoté ; Swype : mort 2018). Le tier **Pro Silver (150 $/mois, ~1 500 $/an)** couvre exactement les 3 briques dures de verba : autocorrect on-device multilingue, in-keyboard typing (reprompt dans le clavier), pattern dictation-bridge. `[CV]`
3. **Attention** : KeyboardKit v10 (sept. 2025) est passé **closed source** (binaire). La v9.9.0 reste MIT mais gelée et sans autocorrect. Plan B souverain : fork v9 + moteur SymSpell maison mono-langue.
4. Contraintes de plateforme non négociables : **~48-70 MB de RAM** (kill jetsam silencieux au-delà), **pas de micro** (même avec Full Access), **pas de sélection de texte**, pas de dessin hors des bounds du clavier, champs sécurisés repris par le clavier système. « Sans rien à envier au natif » = parité à ~95 % ; le reste est structurellement impossible. `[CV]`
5. Le feeling natif se gagne sur 6 détails : feedback visuel **au touch-down**, haptics/sons différenciés (Full Access requis), callouts de touches, delete continu accéléré, curseur spacebar, fond **translucide** (jamais opaque).

---

## 1. PRIORITÉ N°1 : correction automatique

### 1.1 Ce qu'Apple fournit (et pourquoi c'est insuffisant)

| API | Ce qu'elle fait | Limite bloquante | Confiance |
|---|---|---|---|
| **UITextChecker** | `rangeOfMisspelledWord` (détection), `guesses` (corrections), `completions` (complétion de mot partiel). Fonctionne en extension. | Sur iOS, `guesses` retourne les candidats **quasi alphabétiquement, pas par probabilité** (contrairement à macOS) : inutilisable seul pour l'autocorrect. Pas de correction contextuelle. Pas de next-word. Latence jamais publiée (à mesurer). | `[CV]` [doc Apple](https://developer.apple.com/documentation/uikit/uitextchecker), [NSHipster](https://nshipster.com/uitextchecker/) `[DATÉ 2016]`, [ansonl/ios-uitextchecker-autocorrect](https://github.com/ansonl/ios-uitextchecker-autocorrect) |
| **UILexicon** (`requestSupplementaryLexicon`) | Prénoms/noms des Contacts, raccourcis texte des Réglages, mots communs. Sans Full Access. | C'est un lexique brut, pas un moteur. Le guide Apple dit explicitement : *« there is no dedicated API »* pour l'autocorrect custom, *« providing them is a competitive advantage »*. | `[CV]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [doc](https://developer.apple.com/documentation/uikit/uiinputviewcontroller/requestsupplementarylexicon(completion:)), [Kodeco](https://www.kodeco.com/49-custom-keyboard-extensions-getting-started?page=3) |
| **NSSpellChecker** | N'existe pas sur iOS (AppKit/macOS uniquement). | | `[CV]` [doc Apple](https://developer.apple.com/documentation/appkit/nsspellchecker), [forums Apple 104045](https://developer.apple.com/forums/thread/104045) |
| **NaturalLanguage** (NLLanguageRecognizer, NLTagger, NLEmbedding) | Détection de langue utile pour router vers le bon dictionnaire en multilingue. | Pas de probabilité de frappe : périphérique, pas le cœur du moteur. | `[SU]` [NSHipster NLLanguageRecognizer](https://github.com/NSHipster/articles/blob/master/2018-08-06-nllanguagerecognizer.md) |
| **inlinePredictionType** (iOS 17) | Trait des champs texte pilotant les prédictions du **clavier système**. | **Pas consommable par un clavier tiers.** Un custom ne peut afficher AUCUNE suggestion inline près du curseur (restriction Apple documentée) : tout passe par la barre au-dessus du clavier. | `[CV]` [doc Apple](https://developer.apple.com/documentation/uikit/uitextinputtraits/inlinepredictiontype), [WWDC23](https://developer.apple.com/videos/play/wwdc2023/10281/), [Fleksy limitations](https://www.fleksy.com/blog/limitations-of-custom-keyboards-on-ios/) |
| **Foundation Models en extension** (iOS 26.1+) | KeyboardKit 10.3 (fév. 2026) livre du next-word on-device via Apple Foundation Models, DANS l'extension. iPhone 15 Pro+ requis. | Une seule source ; consommation mémoire imputée à l'extension non documentée. | `[SU]` [blog KeyboardKit 10.3](https://keyboardkit.com/blog/2026/02/13/keyboardkit-10-3) |

À noter : le clavier natif Apple utilise depuis iOS 17 un **transformer on-device** (~34 M paramètres, 6 blocs, vocab 15k, rétro-ingénierie de Jack Cook) : c'est la cible de qualité, et 34 M params en fp16 ≈ 68 MB, soit **au-dessus du budget mémoire d'une extension à lui seul**. `[CV]` [jackcook.com](https://jackcook.com/2023/09/08/predictive-text.html), [9to5Mac](https://9to5mac.com/2023/06/05/ios-17-iphone-autocorrect/)

### 1.2 État de l'art algorithmique (si moteur maison)

Architecture hybride 3 couches, convergence de toutes les sources (Gboard, FlorisBoard, littérature) :

1. **Couche lexicale : SymSpell** (Symmetric Delete, Wolf Garbe). Lookup **0,033 ms/mot** à distance d'édition 2 ; ~1 870× plus rapide que BK-tree. Dictionnaire fourni `frequency_dictionary_en_82_765.txt` (Google Books Ngram × SCOWL, ~80k mots, ~1-2 MB brut ; la structure précalculée coûte plus, levier = `prefixLength`). Port Swift existant mais jeune (16 stars) : [gdetari/SymSpellSwift](https://github.com/gdetari/SymSpellSwift), à auditer/forker. `[CV]` [wolfgarbe/SymSpell](https://github.com/wolfgarbe/SymSpell), [SeekStorm SymSpell vs BK-tree](https://seekstorm.com/blog/symspell-vs-bk-tree/)
2. **Couche spatiale (« fat finger »)** : distance d'édition pondérée par la proximité des touches. Gboard : modèle gaussien par touche (offsets personnalisés par utilisateur), combiné en score `−log P(mot) + α·distÉditionPondérée`, décodage FST + beam search. Aucun composant Apple ne fournit ça ; c'est CE qui fait la différence de qualité perçue. `[CV]` [Google Research blog 2017](https://research.google/blog/the-machine-intelligence-behind-gboard/), [arXiv 2209.11311](https://arxiv.org/pdf/2209.11311)
3. **Couche contexte** : n-grammes légers quantizés (bigrammes/trigrammes à la KenLM : trie bit-packé, quantization ~4 bits pour ~1 % de perte) pour le ranking contextuel + next-word. Gboard 2024 a remplacé le n-gram par un **LSTM 6,4 M params** au prix de +17-28 % de latence : le neural est un enrichissement, pas un prérequis. `[CV]` [KenLM](https://kheafield.com/code/kenlm/structures/), `[SU]` [arXiv 2410.15575](https://arxiv.org/html/2410.15575)

Leçon FlorisBoard (Android OSS) : leur moteur suggestions est passé de ~500 ms pire cas à ~0,5 ms best-case après 2 réécritures complètes (dont abandon de Kotlin pour du natif) ; les suggestions restent jugées faibles par leurs utilisateurs après des années. **Même sur Android, l'autocorrect crédible est le morceau le plus dur d'un clavier.** `[CV]` [PR #329](https://github.com/florisboard/florisboard/pull/329), [discussion #2197](https://github.com/florisboard/florisboard/discussions/2197). Le format de dictionnaire AOSP/HeliBoard (fréquence 8 bits + flags whitelist/offensive) est un bon modèle de schéma. `[CV]` [wiki HeliBoard](https://github.com/HeliBorg/HeliBoard/wiki/7.-Dictionaries)

### 1.3 UX de l'autocorrect à répliquer (comportement natif)

`[CV]` [Apple Support predictive text](https://support.apple.com/guide/iphone/use-predictive-text-iphd4ea90231/ios), [MacRumors iOS 17 keyboard](https://www.macrumors.com/guide/ios-17-keyboard/) :

- **Barre de 3 candidats** ; la saisie littérale apparaît **entre guillemets à gauche** (la taper = rejeter la correction) ; le candidat qui sera inséré est mis en évidence.
- **Commit implicite** sur espace / ponctuation / retour.
- **Rejet appris** : après quelques rejets du même mot, cesser de le corriger.
- **Undo post-commit** : iOS 17 souligne temporairement le mot corrigé (tap = menu de restauration). Le **backspace-undo à la Gboard** (backspace restaure l'original) est documenté comme supérieur au natif iOS (qui re-corrige même après suppression, comportement critiqué) : différenciateur UX facile pour verba. `[CV]` [mjtsai.com](https://mjtsai.com/blog/2020/12/17/ios-autocorrect-and-the-delete-key/)
- **App Review 4.4.1** : apprentissage de vocabulaire 100 % local = conforme ; toute télémétrie de frappe = motif de rejet classique. Le clavier doit rester fonctionnel sans Full Access et sans réseau. `[CV]` [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### 1.4 Recommandation autocorrect

**Voie 1 (recommandée) : KeyboardKit Pro Silver + trial de validation.** Autocorrect local on-device (~76-77 langues annoncées), next-word (Foundation Models iOS 26.1+ ou LLM distant), zéro personne-année de moteur. **Aucun benchmark indépendant de sa qualité n'existe** : le trial gratuit (sans CB) sur FR + EN en conditions réelles est le seul juge. `[CV sur l'offre, gap sur la qualité]` [keyboardkit.com/features/autocomplete](https://keyboardkit.com/features/autocomplete), [pricing](https://keyboardkit.com/pricing)

**Voie 2 (fallback souverain) : moteur maison minimal mono-langue** sur base SymSpell + pondération spatiale + bigrammes, UITextChecker en filet de validation, UILexicon injecté pour les noms propres. Viser : correction du dernier mot au commit (espace), pas de correction à chaque frappe tant que la latence de `guesses`/lookup n'est pas mesurée. C'est des semaines de travail pour UNE langue à qualité « correcte », pas native.

**Interdit** : bâtir l'autocorrect sur UITextChecker.guesses sans re-ranking (tri alphabétique = corrections absurdes), ou embarquer un LM >10-15 M params dans l'extension (jetsam).

---

## 2. Architecture de référence de l'extension

### 2.1 Lifecycle réel de UIInputViewController

- Extension = **process séparé**, communication avec l'app hôte par IPC via `textDocumentProxy`. `[CV]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [doc moderne](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards)
- `viewDidLoad` rejoué à chaque recréation du contrôleur (fréquent), mais **le process peut survivre à plusieurs apparitions** : mesure avril 2026 montrant +6-7 MB par switch aller-retour jusqu'au kill vers 70 MB → les fuites mémoire sont le bug n°1. `[SU récent]` [Itsuki, Medium 2026-04](https://medium.com/@itsuki.enjoy/swiftui-keyboard-extension-dont-use-keyboard-kit-eece34c21441), cohérent avec [KeyboardKit issue #141](https://github.com/KeyboardKit/KeyboardKit/issues/141)
- Quirks : `viewDidAppear` parfois non appelé ; `viewDidLayoutSubviews` déclenché à des hauteurs intermédiaires pendant l'animation. `[SU]` [forums Apple 738465](https://developer.apple.com/forums/thread/738465)
- Règles : `viewDidLoad` minimal (tout différer après le premier rendu), état durable dans l'App Group jamais en mémoire, instrumenter `deinit` (s'il n'est jamais appelé = rétention).

### 2.2 Budget mémoire et temps de lancement

- **Plafond mesuré : ~48-70 MB selon device/OS** (48 MB : crash documenté React Native ; ~60 MiB : mesure Grammarly 2024 ; 66 MB iPhone XS Max ; ~70 MB : docs KeyboardKit + mesure 2026). Le plafond n'est PAS documenté officiellement par Apple et a augmenté avec les générations. **Budget de travail recommandé : ≤40 MB en régime permanent, alarme à 50 MB.** `[CV]` [KeyboardKit Memory Management](https://docs.keyboardkit.com/documentation/keyboardkit/developer-memory-management/), [Grammarly 2024](https://www.grammarly.com/blog/engineering/deep-learning-swipe-typing/), [RN #31910](https://github.com/facebook/react-native/issues/31910)
- **Kill silencieux** (jetsam, priorité 8, pas de crash capturable) : le clavier « disparaît » sous les doigts, pire défaut de feeling possible. `[CV]` [doc jetsam Apple](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports)
- **Lancement : « well under one second »** exigé par Apple (watchdog tue au-delà). Optimisations : ≤6 frameworks non-système embarqués (leur chargement domine le cold start), travail différé. `[CV]` [Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html), [Use Your Loaf](https://useyourloaf.com/blog/slow-app-startup-times/)
- **Conséquence** : aucun modèle ML/ASR significatif dans l'extension. Tout le lourd (Whisper/Parakeet, Claude) vit dans l'app conteneur ; l'extension reste un client léger. Tester uniquement sur device physique (le simulateur ne reproduit pas jetsam).

### 2.3 UIKit vs SwiftUI dans l'extension

- KeyboardKit est SwiftUI (via UIHostingController). Piège n°1 documenté par KeyboardKit même : **rétention du contrôleur dans l'arbre SwiftUI** (obligation de `[weak self]`, fuites résiduelles « deep into the SwiftUI runtime »). `[CV]` [Getting Started KeyboardKit](https://raw.githubusercontent.com/KeyboardKit/KeyboardKit/master/Sources/KeyboardKit/KeyboardKit.docc/Essentials/Getting-Started-Article.md), [Itsuki 2026](https://medium.com/@itsuki.enjoy/swiftui-keyboard-extension-dont-use-keyboard-kit-eece34c21441)
- L'overhead SwiftUI s'est réduit mais dans un budget 60-70 MB et un chemin critique touche→glyphe, **UIKit reste le plus prévisible pour la grille de touches** ; SwiftUI acceptable pour les surfaces secondaires (barre de suggestions, panneau IA). `[CV sur l'overhead, arbitrage interprété]` [Jacob's Tech Tavern](https://blog.jacobstechtavern.com/p/swiftui-vs-uikit)
- Si KeyboardKit est retenu, ce choix est fait pour nous (SwiftUI) : discipline weak self + profiling Instruments obligatoires.

### 2.4 UITextDocumentProxy : capacités et pièges

- Capacités : `insertText`, `deleteBackward`, `adjustTextPosition(byCharacterOffset:)`, `setMarkedText`, lecture des traits (`keyboardType`, `returnKeyType`, `autocapitalizationType`). `[doc primaire]` [UITextDocumentProxy](https://developer.apple.com/documentation/uikit/uitextdocumentproxy)
- **Contexte tronqué** : `documentContextBeforeInput/AfterInput` coupent au paragraphe (le chiffre ~300 caractères circule mais n'est pas contractuel). Lecture du document entier = balayage du curseur par `adjustTextPosition` + concaténation, technique « best effort » fragile (c'est ce que fait KeyboardKit Pro « full document context »). **Directement pertinent pour le reprompting verba** : le clavier ne verra jamais tout le texte de façon garantie. `[CV troncature, SU chiffre]` [Proxy article KeyboardKit](https://raw.githubusercontent.com/KeyboardKit/KeyboardKit/master/Sources/KeyboardKit/KeyboardKit.docc/Features/Proxy-Article.md)
- Compter en `.utf16.count` pour `adjustTextPosition` (émojis). `[SU]` [R0uter's blog](https://www.logcg.com/en/archives/1987.html) `[DATÉ, API inchangée]`

### 2.5 Full Access : ce que ça débloque exactement

Source primaire : [Configuring open access](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard) + test empirique [Securing.pl](https://www.securing.pl/en/third-party-iphone-keyboards-vs-your-ios-application-security/) `[CV]` :

- **SANS Full Access** : clavier de base, UILexicon, et **App Group en LECTURE SEULE** (contradiction des vieilles docs résolue : la doc moderne dit « read-only access to the containing app's shared containers » ; l'écriture par l'extension exige Full Access).
  - **Impact direct sur le flux verba actuel** : `Verba.takePendingResult()` fait un `removeObject` (écriture) depuis l'extension. Sans Full Access ce nettoyage échouera ; le flux app→clavier doit être conçu pour marcher en lecture seule côté extension (ex. horodatage consommé, nettoyage par l'app).
- **AVEC Full Access** : réseau, App Group lecture/écriture, UIPasteboard, haptics/audio. **PAS le micro** (jamais, voir §6).
- Le prompt Full Access affiche l'avertissement anxiogène d'Apple (accès « à tout ce que vous tapez, y compris numéros de compte et de carte ») : friction d'onboarding réelle, aucun taux d'opt-in public. Le clavier DOIT rester fonctionnel sans (4.4.1).

### 2.6 Hauteur, iPad

- Largeur imposée, hauteur libre via Auto Layout **après le premier rendu** ; piège du conflit avec `UIView-Encapsulated-Layout-Height` pendant l'animation (flicker). `[CV]` [Configuring a custom keyboard interface](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface), [forums 738465](https://developer.apple.com/forums/thread/738465)
- iPad : ancrer le contenu au bottom, supporter docked / **floating** (largeur iPhone via size classes) / compact. `[CV]` [forums 89456](https://developer.apple.com/forums/thread/89456), [Apple Support](https://support.apple.com/en-us/102513)

---

## 3. Prédiction et barre de suggestions

- Standard : **3 candidats**, littéral entre guillemets à gauche, correction au centre (cf. §1.3). La barre sert aussi de **zone de débordement pour les callouts** de la rangée du haut (pattern Gboard/SwiftKey), ce qui résout la limite « pas de dessin au-dessus du clavier ».
- Next-word : n-grammes légers suffisent pour un v1 crédible ; neural = enrichissement (Gboard : +17-28 % latence pour un gain qualité modeste `[SU]` [arXiv 2410.15575](https://arxiv.org/html/2410.15575)). Apple avait d'ailleurs **retiré** le next-word on-device accessible aux tiers à partir d'iOS 16 (trou comblé seulement par Foundation Models iOS 26.1+). `[SU]` [KeyboardKit blog 2024-12](https://keyboardkit.com/blog/2024/12/03/next-word-prediction)
- Personnalisation : apprentissage local (fichier dans l'App Group) conforme App Review ; jamais de télémétrie de frappe.
- **Pour verba, la barre de suggestions est aussi l'emplacement naturel des modes IA** (Flow/Polish/...) : un seul élément d'UI au-dessus des touches, comme la toolbar KeyboardKit.

---

## 4. Ergonomie : le feeling natif, détail par détail

### 4.1 Key popups / callouts

- **Limite système absolue** : impossible de dessiner au-dessus du bord supérieur de la vue du clavier (*« It is not possible to display key artwork above the top edge »*). `[CV]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
- Solution de l'industrie : callouts dessinés DANS la vue (overlay zIndex), la rangée du haut débordant dans la barre de suggestions ; ou hauteur de clavier augmentée. KeyboardKit fournit input callouts + action callouts (accents au long press), localisés pour ~77 locales en Pro. `[CV]` [keyboardkit.com/features/callouts](https://keyboardkit.com/features/callouts)
- Verdict : ~95 % du feeling natif reproductible.

### 4.2 Haptics et son

- **Haptics : Full Access obligatoire** (règle de 2016 jamais levée, confirmée par l'écosystème 2026 ; le toggle haptique natif d'iOS 16 ne s'applique qu'au clavier first-party). iPhone uniquement. `UIImpactFeedbackGenerator(.light)` + **`prepare()` au touch-down** (sinon latence perceptible). `[CV]` [forums Apple 63493](https://developer.apple.com/forums/thread/63493) `[DATÉ mais confirmé]`, [keyboardkit.com/features/feedback](https://keyboardkit.com/features/feedback), [9to5Mac iOS 16](https://9to5mac.com/2022/09/13/ios-16-haptic-feedback-keyboard/)
- **Son** : `UIInputViewAudioFeedback` + `UIDevice.current.playInputClick()` ; sons différenciés du natif via `AudioServicesPlaySystemSound` : **1123** (caractère), **1155** (delete), **1156** (modificateurs), joués hors main thread. `[CV mécanisme, SU pour les IDs]` [doc Apple](https://developer.apple.com/documentation/uikit/uiinputviewaudiofeedback), [guide Shyngys](https://shyngys.com/ios-custom-keyboard-guide)
- **Ambiguïté à trancher par test device** : `playInputClick` sans Full Access (sources contradictoires ; traiter comme nécessitant Full Access par défaut).

### 4.3 Gestes

| Geste | Faisabilité | Implémentation | Sources |
|---|---|---|---|
| **Delete continu accéléré** (délai ~0,5 s → répétition ~0,1 s → suppression par mots après ~2-3 s) | Oui, 100 % à la main | Timer de repeat + palier de durée + suppression jusqu'au séparateur via `documentContextBeforeInput`. Valeurs à calibrer à l'oreille contre le natif (aucune spec publique). | `[CV]` [GestureButton (D. Saidi)](https://github.com/danielsaidi/GestureButton), [KeyboardKit gestures](https://keyboardkit.com/features/gestures) |
| **Curseur spacebar (trackpad)** | Partiel : déplacement OK, **sélection impossible** (API inexistante) | Pan sur espace → `adjustTextPosition` ; vélocité + seuil ~70 px + comptage UTF-16. | `[CV]` [R0uter's blog](https://www.logcg.com/en/archives/1987.html), [keyboardkit.com/features/gestures](https://keyboardkit.com/features/gestures) |
| **Swipe-to-type** | Oui mais projet ML entier (Grammarly : LSTM seq2seq 7,5 M params, 33 features/point, ~17 ms/geste sous 60 MiB) | **Hors scope v1.** | `[SU détails, CV faisabilité]` [Grammarly 2024](https://www.grammarly.com/blog/engineering/deep-learning-swipe-typing/) |
| **Double-tap shift = caps lock**, **double espace = ". "**, autocap | Oui, trivial | Réglages système équivalents illisibles depuis l'extension → fournir ses propres toggles. Autocap : lire `autocapitalizationType` + inspecter le contexte. | `[CV]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [docs Wispr Flow](https://docs.wisprflow.ai/articles/7453988911-set-up-the-flow-keyboard-on-iphone) |
| Long press accents | Oui | Action callout, ~0,5 s (cf. §4.1). | `[CV]` |

### 4.4 Layouts, multilinguisme, touches contextuelles

- Aucun layout fourni par le système : tout est à générer. KeyboardKit gratuit = QWERTY + layouts custom ; **AZERTY/QWERTZ/75 locales localisées = Pro**. `[CV]` [keyboardkit.com/features/layout](https://keyboardkit.com/features/layout/), [locales](https://keyboardkit.com/locales)
- Multi-langues : pratique dominante = **un seul target d'extension + switcher interne** (long press globe), `PrimaryLanguage = "mul"` dans l'Info.plist. `[CV]` [forums 92030](https://developer.apple.com/forums/thread/92030), [App Extension Keys](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AppExtensionKeys.html)
- **Exigences Apple** : répondre à `keyboardType` (email → « @ », URL → « .com », numberPad → pavé) et `returnKeyType` (label + couleur bleue des types action), relus à chaque `textDidChange`. Globe : conditionner à `needsInputModeSwitchKey` (false sur devices Face ID où le système affiche son propre globe). `[CV]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [needsInputModeSwitchKey](https://developer.apple.com/documentation/uikit/uiinputviewcontroller/needsinputmodeswitchkey) : le scaffold actuel a déjà le globe, mais non conditionné.

### 4.5 Apparence

- **Piège dark mode documenté** : impossible de distinguer « champ sombre en mode clair » (`keyboardAppearance = .dark`) du vrai dark mode système (l'extension reçoit `userInterfaceStyle == .dark` dans les deux cas). **Workaround de toute l'industrie : couleurs semi-transparentes** laissant transparaître le fond flou système ; un fond opaque « sonne faux » immédiatement. `[CV]` [KeyboardKit issues #305](https://github.com/KeyboardKit/KeyboardKit/issues/305) et [#285](https://github.com/KeyboardKit/KeyboardKit/issues/285)
- Dimensions : hauteur système 216 pt portrait (+ safe area), aucune spec Apple pour les touches ; valeurs décalquées par la communauté (touche ~33×43 pt sur écran 390 pt, gouttières ~6 pt, radius ~4,6-5 pt) à valider par superposition de captures sur devices cibles. `[SU communautaire]` [forums 90061](https://developer.apple.com/forums/thread/90061), [Figma iOS Keyboards](https://www.figma.com/community/file/768726574016795759/ios-keyboards)

### 4.6 Performance perçue

- **Feedback visuel au touch-down, jamais au touch-up** (le natif change l'état de la touche au contact). `[SU + principe]` [KeyboardKit issue #36](https://github.com/KeyboardKit/KeyboardKit/issues/36)
- Budgets : **<16 ms/frame (60 Hz)**, feedback par frappe **<20 ms** (contrainte produit Gboard), latence bout-en-bout <50 ms idéale. `[CV]` [Fleksy debugging](https://www.fleksy.com/blog/framework-specific-debugging-for-virtual-keyboards/), [arXiv 2410.15575](https://arxiv.org/html/2410.15575), [danluu.com](https://danluu.com/keyboard-latency/)
- Layout calculé en un passage (structure de données rendue d'un bloc), pas une contrainte Auto Layout par touche. `[SU]` [keyboardkit.com/features/layout](https://keyboardkit.com/features/layout/)
- Aucune mesure publiée sérieuse « natif vs custom » touche→glyphe : gap, à mesurer soi-même (méthode caméra haute vitesse).

---

## 5. Buy vs build

### 5.1 Découverte majeure : le paysage 2026

- **KeyboardKit v10 (sept. 2025) est closed source** (binaire, checksum dans Package.swift ; LICENSE : *« KeyboardKit... is closed-source »*). La **v9.9.0 est la dernière MIT**, gelée (iOS 15+, plus de fixes iOS 26+), et n'a jamais inclus l'autocomplete (déjà Pro). Aucun fork communautaire MIT n'a émergé. `[CV]` [LICENSE main](https://github.com/KeyboardKit/KeyboardKit/blob/master/LICENSE), [LICENSE 9.9.0](https://raw.githubusercontent.com/KeyboardKit/KeyboardKit/9.9.0/LICENSE), [annonce v10](https://danielsaidi.com/blog/2025/08/31/keyboardkit-10-developer-preview)
- **Fleksy SDK : mort** (site DNS hors ligne constaté le 2026-07-16 ; arrêt silencieux du développement courant 2025). **Typewise : pivoté** hors clavier (agents IA CRM). **Swype : mort 2018.** SwiftKey : plus d'offre SDK publique. `[CV]` [billet KeyboardKit 2026-06-08](https://keyboardkit.com/blog/2026/06/08/fleksy-shuts-down-their-website), [Wikipedia Typewise](https://en.wikipedia.org/wiki/Typewise), [MacRumors Swype](https://www.macrumors.com/2018/02/20/nuance-discontinues-swype/)
- **Aucun clavier iOS open source complet avec autocorrect fonctionnel n'existe** (FlorisBoard/HeliBoard = Android only ; Scribe-iOS = autocorrect WIP, pas un framework ; tasty-imitation-keyboard = abandonné ~2016). `[CV]`
- → **KeyboardKit est de facto le seul SDK clavier iOS commercial actif.** Force (mûr, seul survivant, très actif : 10.7.2 du 2026-07-09, 1,9k stars) et risque (mono-mainteneur Daniel Saidi/Kankoda, monopole de niche).

### 5.2 Pricing KeyboardKit Pro (page officielle, 2026-07-16) `[SU : source primaire]`

| Tier | Prix | Contenu clé pour verba |
|---|---|---|
| Gratuit (v10 binaire) | 0 $ | KeyboardView natif-like, layouts de base, callouts, gestes, feedback. **Pas d'autocorrect.** |
| Basic | 50 $/mois | Autocorrect **1 langue**. Sans AI Support ni in-keyboard typing. |
| **Silver** | **150 $/mois (~1 500 $/an en annuel, −17 %)** | Autocorrect **5 langues**, **AI Support**, **In-Keyboard Typing** (champ texte dans le clavier : reprompt), support email. **Le tier réaliste pour verba.** |
| Gold | 500 $/mois | 75+ langues, tout Pro, multiplateforme. |
| Business | Devis | Licence on-device (fichier), multi-apps, escrow. Obligatoire si >1 M$ de revenue app / >10 M$ société. |

Points de vigilance contractuels `[CV pages officielles]` : licence standard = **1 app** ; **validation de licence par appel réseau** (donc Full Access requis au lancement du clavier ; seul Business valide on-device) ; trial gratuit sans CB ; dictation Pro = pattern « ouvre l'app conteneur + audio bridge + retour best-effort » (exactement le flux verba actuel, en industrialisé, avec base de données d'apps hôtes pour le retour automatique).

### 5.3 Tableau de décision

| Option | Coût an 1 | Time-to-market | Qualité autocorrect | Risques |
|---|---|---|---|---|
| KK gratuit + autocorrect maison | 0 $ | Shell : semaines ; autocorrect crédible : **le mur** (personnes-années au niveau natif, jamais démontré en indie) | Plafonnée sans moteur maison sérieux | Maintenance perpétuelle, qualité = churn |
| KK v9 MIT (fork) | 0 $ | Semaines (shell) | Aucun (à construire) | Gelée, plus de fixes iOS 26+ ; seule option souveraine |
| **KK Pro Silver** | **~1 500 $** | **Le plus court** (autocorrect + layouts localisés + in-keyboard typing + dictation bridge fournis) | Annoncée bonne, **non benchmarkée indépendamment → trial obligatoire** | Binaire fermé, mono-mainteneur, validation réseau, clause 1 M$ |
| Build from scratch | 0 $ cash | Shell 1-2 mois ; autocorrect multilingue : personnes-années | Cf. §1 | Grammarly y a mis une équipe dédiée ; Fleksy en est mort |

Référence de crédibilité : **BossAI** (clavier IA voice-first, le comparable le plus direct de verba) tourne sur KeyboardKit en production. `[SU : showcase vendeur]` [keyboardkit.com](https://keyboardkit.com/)

---

## 6. Ce que le natif fait et qu'un custom ne PEUT PAS faire (cadrage « sans compromis »)

| Capacité native | Custom ? | Détail | Confiance |
|---|---|---|---|
| **Micro / dictée in-keyboard** | **NON, jamais** (même avec Full Access : la liste des capacités FA n'inclut pas le micro ; échecs AVAudioSession documentés) | Pattern universel = deep link vers l'app conteneur + App Group + retour best-effort vers l'app hôte (non garanti si app inconnue). Le flux verba actuel est LE pattern standard ; l'industrialisation (retour auto) est la marge de progrès. | `[CV fort]` [guide Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [forums 742601](https://developer.apple.com/forums/thread/742601), [KK Dictation](https://keyboardkit.com/features/dictation) |
| Saisie dans `secureTextEntry` (mots de passe) et `phonePad`/`namePhonePad` | NON | Le système **remplace temporairement** le custom par le clavier natif, puis le restaure. | `[CV]` doc Apple ×2 |
| Suggestions/autocorrect **inline près du curseur** | NON | *« A custom keyboard cannot offer inline autocorrection controls near the insertion point »* → tout passe par la barre. | `[CV]` guide Apple, [Fleksy](https://www.fleksy.com/blog/limitations-of-custom-keyboards-on-ios/) |
| **Sélection de texte** (trackpad 2 doigts), menu Couper/Copier/Coller | NON | Le proxy ne sait que déplacer/insérer/supprimer. | `[CV]` [Handling text interactions](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards) |
| Dessin **au-dessus des bounds** du clavier (key pop-out natif) | NON | Limite fenêtre système absolue. | `[CV]` guide Apple |
| Dictionnaire personnel complet + LM appris de l'utilisateur | NON | Seulement UILexicon (contacts + raccourcis + mots communs). | `[CV]` guide Apple |
| Être clavier **par défaut** / s'auto-activer | NON | Activation manuelle dans Réglages + switch par globe ; toute app peut bannir les claviers tiers (`shouldAllowExtensionPointIdentifier`, courant en banking). | `[CV]` [doc](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface) |
| Réglages clavier système (autocap, caps lock, « . » shortcut) | NON lisibles | Répliquer avec ses propres toggles. | `[CV]` guide Apple |
| Latence/process du natif | Structurellement supérieure | Le custom paie : cold start, IPC par frappe, priorité GPU réduite, jetsam ~70 MB. Compensable par la discipline §2/§4.6, pas annulable. | `[CV]` [Extension guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html) |
| Haptics sans Full Access | NON | Cf. §4.2. | `[CV]` |

Obligations App Review 4.4.1 : fonctionner sans réseau et sans Full Access, fournir le switch clavier suivant, pas de détournement de touches, collecte limitée au fonctionnement local. `[doc primaire]` [guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 7. Matrice finale des améliorations recommandées pour verba

Impact : ▲▲▲ fort / ▲▲ moyen / ▲ faible · Effort : € faible (jours) / €€ moyen (semaines) / €€€ fort (mois+) · Risque : technique/produit.

| # | Amélioration | Impact | Effort | Risque | Notes |
|---|---|---|---|---|---|
| 1 | **Adopter KeyboardKit (trial Pro Silver) comme base du clavier complet** : KeyboardView, layouts, callouts, gestes, feedback | ▲▲▲ | €€ | Moyen : binaire fermé, mono-mainteneur ; mitigé par trial + plan B fork v9 MIT | La décision structurante. Le scaffold actuel (61 lignes) est jetable sans regret. |
| 2 | **Autocorrect + suggestions via KK Pro Silver** (FR+EN d'abord), validé par 2 semaines de trial en conditions réelles | ▲▲▲ | € (intégration) | **Qualité non benchmarkée publiquement** : le trial est le juge ; fallback = voie 2 §1.4 | Douleur n°1. 150 $/mois. Silver inclut In-Keyboard Typing (reprompt) + AI Support. |
| 3 | **Barre de suggestions 3 candidats** (littéral entre guillemets à gauche, commit sur espace) + **backspace-undo à la Gboard** | ▲▲▲ | €€ | Faible | Le backspace-undo est un différenciateur documenté comme supérieur au natif iOS. |
| 4 | **Discipline mémoire + cold start** : budget ≤40 MB, ≤6 frameworks embarqués, viewDidLoad minimal, état dans l'App Group, profiling deinit/Instruments sur device | ▲▲▲ | € (continu) | Faible | Condition de survie : jetsam kill = clavier qui disparaît sous les doigts. |
| 5 | **Feedback touch-down** (visuel immédiat + `prepare()` haptique) + haptics `.light` + sons différenciés 1123/1155/1156 | ▲▲▲ | € | Faible ; Full Access requis pour haptics/son : prévoir l'état dégradé propre | Le cœur du « feeling natif ». |
| 6 | **Réviser le flux App Group pour marcher sans Full Access** : extension = lecture seule (le `removeObject` de `takePendingResult` échouera sans FA), nettoyage côté app | ▲▲▲ | € | Faible | Exigence App Review 4.4.1 + réalité technique §2.5. Bug latent du scaffold actuel. |
| 7 | Gestes : **delete continu accéléré** (mots après ~2-3 s), **curseur spacebar**, double-tap shift, double espace → point, autocap | ▲▲ | €€ | Faible (KK en fournit l'essentiel) | Sélection au spacebar : impossible, ne pas la promettre. |
| 8 | **keyboardType / returnKeyType adaptatifs** + globe conditionné à `needsInputModeSwitchKey` | ▲▲ | € | Faible | Exigé par Apple ; le scaffold actuel a un globe inconditionnel. |
| 9 | **Thème translucide clair/sombre** (jamais opaque, à cause du piège keyboardAppearance/dark mode) | ▲▲ | € | Faible | Workaround de toute l'industrie. |
| 10 | **Industrialiser le dictation-bridge** : retour automatique vers l'app hôte (host app detection à la KK Pro), états visuels d'attente dans le clavier | ▲▲ | €€ | Moyen : retour best-effort non garanti | Améliore LE flux cœur de verba ; le pattern actuel est déjà le bon. |
| 11 | Onboarding **Full Access** : écran d'explication, détection `hasFullAccess`, features dégradées visibles | ▲▲ | € | Faible | Le prompt Apple est anxiogène ; la confiance se gagne dans l'app conteneur. |
| 12 | Multilinguisme : switcher interne (`PrimaryLanguage = "mul"`), layouts localisés (Pro) | ▲ | € avec Pro / €€€ sans | Faible | Selon les marchés visés. |
| 13 | iPad : ancrage bottom, floating/compact | ▲ | €€ | Faible | Après l'iPhone. |
| 14 | Swipe-to-type | ▲ | €€€ (projet ML : LSTM 7,5 M params sous 60 MiB) | Élevé | **Hors scope v1.** À réévaluer après PMF. |
| 15 | Next-word neural via Foundation Models (iOS 26.1+, iPhone 15 Pro+) | ▲ | € (via KK 10.3) | Moyen : `[SU]`, mémoire non documentée | Enrichissement progressif, jamais une dépendance dure. |

**Séquence recommandée** : #1+#2 (trial 2 semaines, décision GO/NO-GO Pro Silver) → #4+#6 (fondations) → #3+#5+#7+#8+#9 (parité native) → #10+#11 (différenciation verba) → #12-#15.

---

## 8. Points non tranchés par les sources (à vérifier par instrumentation device)

1. Latence réelle de `UITextChecker.guesses`/`rangeOfMisspelledWord` (aucun chiffre publié nulle part).
2. Tri alphabétique des guesses iOS : source principale de 2016, à revalider sur iOS 18/26.
3. `playInputClick` sans Full Access (sources contradictoires).
4. Comportement haptics avec Full Access sur iOS 18/26 (jamais contractualisé par Apple).
5. Politique exacte de réutilisation du process de l'extension (logger le PID).
6. Chiffre exact de troncature de `documentContextBeforeInput` par type de champ.
7. Qualité réelle de l'autocorrect KeyboardKit Pro FR/EN (trial).
8. Empreinte mémoire des Foundation Models imputée à l'extension.

---

## Annexe : rappel des chiffres clés

| Métrique | Valeur | Source |
|---|---|---|
| Plafond mémoire extension | ~48-70 MB (device/OS) ; budget de travail ≤40 MB | KeyboardKit docs, Grammarly, RN #31910 `[CV]` |
| Lancement extension | « well under one second » (watchdog) | Apple `[primaire]` |
| Feedback par frappe | <20 ms (Gboard) ; <16 ms/frame | arXiv 2410.15575 `[SU]`, Fleksy `[CV]` |
| Lookup SymSpell 80k mots d=2 | 0,033 ms | wolfgarbe/SymSpell `[CV]` |
| LM du clavier natif iOS 17+ | transformer ~34 M params, vocab 15k | jackcook.com `[CV]` |
| KeyboardKit | v10.7.2 (2026-07-09), v10 closed source, v9.9.0 dernière MIT | GitHub `[CV]` |
| KK Pro Silver | 150 $/mois (~1 500 $/an), 5 langues, AI + in-keyboard typing | keyboardkit.com/pricing `[SU primaire]` |
| Swipe-to-type (Grammarly) | LSTM 7,5 M params, ~17 ms/geste, ~60 MiB | Grammarly Engineering 2024 `[SU]` |
