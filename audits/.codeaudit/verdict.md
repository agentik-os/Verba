# /codeaudit : commit 4c67951 (merge 9d75a20), fix du latch `.processing` + changelog 0.9.110

**Score : 89/100 (brut 256/285), Grade A.** Confiance : medium (statique verifie ligne a ligne + tsc runtime pour le site ; le build macOS n'est pas executable sur cette box Linux, donc zero preuve runtime du binaire).

Verdict : **le fix est correct, minimal et sur**. Les 4 questions de la mission sont tranchees, chacune avec preuve :

1. **Le else-if ne peut pas ecraser un etat legitime.** `.recording` est doublement protege : la branche est inatteignable pendant un enregistrement (gate `wasLatest` a :2020 + early return :2037) et elle teste explicitement `state == .processing`. `failSession` est synchrone `@MainActor`, aucune suspension entre la gate et la mutation. Les branches flash (`flashInfo` :2432, `flashError` :2459) remettent `.idle` de facon synchrone AVANT :2066 : le else-if est mort apres un flash, son `overlay.hide()` ne peut jamais tuer un flash visible. L'alerte silent-input est une fenetre separee (`alertWindow`, :3211), insensible a `overlay.hide()`.
2. **Aucun autre chemin n'orpheline `.processing`.** Les 8 ecrivains de `state = .processing` (:1907, :2067, :2174, :2196, :2221, :2308, :2329, :2905) sont chacun traces vers un chemin de reset (`finish` :2113 toutes branches, `failSession` post-fix, `cancelEverything` :1280 qui finit `state = .idle` :1341). `withTimeout` (Pipeline.swift:59) est single-resume ; le seul cancel des session tasks est :1309 (dans `cancelEverything`).
3. **Coherence overlay/statusLine OK.** `statusLine` n'est lu que sous `.processing` (:2608, :2618-2621) donc sa non-remise a zero est inoffensive ; les quips sont deja stoppes (:2038) ; `refreshUI` part via le `didSet` de `state` (:42).
4. **Changelogs valides et identiques.** 0.9.110 byte-for-byte identique entre Changelog.swift et page.tsx (diff = IDENTICAL), `tsc --noEmit` exit 0, structure Swift equilibree (pas de toolchain Swift sur cette box : verification structurelle), zero em/en dash, zero nom de techno interdit, ordre des versions et tag "Today" corrects, et le claim du changelog correspond aux vraies gates revivees (:1178 transform picker, :1475/:1479 mode picker).

## Findings (ranges par morsure)

| ID | Sev | Ou | Quoi |
|----|-----|-----|------|
| F1 | MEDIUM | Tests/ | Zero test sur la machine d'etats de dictee ; ce fix arrive sans test de regression. Suggestion : extraire la decision de transition en reducer pur testable sur Linux. |
| F2 | LOW | git | Merge 9d75a20 non pousse (local ahead 2) : le fix et le changelog n'existent que localement (L0). |
| F3 | LOW | :2073 | Le step-down est silencieux (aucun log) : une recidive d'orphelin serait invisible, comme le bug d'origine. |
| F4 | INFO | :2015 | `latestShowsOverlay` toujours `true` a son unique call site (:1976), parametre mort (pre-existant). |
| F5 | INFO | AppDelegate.swift | 3308 lignes, au-dela de l'alarme refactor (~2000) ; la surete de la machine d'etats repose sur du raisonnement manuel fichier entier (pre-existant). |
| F6 | INFO | .code/ | Les 5 "high" du gather = artefacts .vercel/output : falsifies, hors scope. |

Refutation adversariale : les 3 conclusions (C1 sur, C2 pas d'autre orphelin, C3 coherence UI) ont ete attaquees et TIENNENT ; la piste todo-capture (flash de `finishTodoCapture` coupe par le step-down) est un interleaving inatteignable (gates :624 et :329). Details, tests falsifiables (9, tous avec sortie reelle) et edge cases : `verdict.json`.

Mission read-only respectee : aucun fichier de Sources/ ni de code du site modifie (les entrees `website/.seo/*` du git status sont anterieures a la session).
