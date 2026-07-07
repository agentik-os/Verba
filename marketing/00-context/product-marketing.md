---
project: Verba
layer: context
produced_by: product-marketing-context (/omg-product-marketing-context)
inputs: [README.md, RULES.md, PROGRESS.md../../.agents/product-marketing.md, website/app/globals.css, website/lib/competitors.ts, website/tailwind.config.ts../market-research.md../gtm-strategy.md]
status: filled
reconciles_with: ../../.agents/product-marketing.md # SSOT canonique, ce fichier en est le miroir consolidé, jamais une contradiction
---
# Product Marketing Context, Verba

> **SSOT canonique = `../../.agents/product-marketing.md`** (22 Ko, à jour post-JARVIS, écrit par `/omg-product-marketing-context`).
> Ce fichier est le **miroir consolidé** dans la machine marketing : il distille le SSOT et n'introduit aucun claim nouveau.
> En cas de divergence, le `.agents/product-marketing.md` fait foi. Sources citées (R-CITE) : `README.md` (racine),
> `RULES.md`, `.agents/product-marketing.md`, `website/app/globals.css` (charte visuelle embarquée), `website/tailwind.config.ts`,
> `website/lib/competitors.ts`, `marketing/market-research.md`, `marketing/gtm-strategy.md`.

## One-liner
**« Speak it. Send it clean. »**, la dictée vocale la plus complète du Mac, et la seule qui **agit** sur ce que tu dis.
App macOS menu-bar : tu parles → Verba transcrit en privé sur ton Mac → **notre IA privée** restructure ton flux en texte propre collé là où est ton curseur → **JARVIS** (l'agent vocal) peut **exécuter** l'intention sur 1 000+ apps connectées, toujours après confirmation. *(source : `README.md`, `.agents/product-marketing.md` §Product Overview)*

## Category & positioning
- **Étagère 1 (établie) :** dictée vocale / voice-to-text IA pour Mac, recherches : *« Mac dictation app », « Wispr Flow alternative », « local dictation Mac », « voice to text for coding ».*
- **Étagère 2 (émergente, que Verba ouvre) :** l'**agent vocal de bureau**, *« Jarvis for Mac », « control apps by voice », « voice assistant that actually does things ».*
- **Position :** le seul outil Mac à la fois **privé par défaut** *et* **IA privée à très faible coût marginal (sans clé à gérer)** *et* qui **agit** (JARVIS). Mental model du marché : « envoie l'audio à ses serveurs→Wispr, local→Superwhisper, transcription→MacWhisper », **aucun défaut pour "local + restructuration IA + IA privée", c'est Verba.**

## ICP (ideal customer profile)
- **B2C / prosumer self-serve**, l'acheteur est un individu, pas un comité ; checkout en un clic, ni procurement ni négo de sièges.
- **Sweet spot :** power-users Mac qui tapent beaucoup et veulent taper moins, sensibles à la **vie privée** et au **coût de l'IA**.
- **Beachhead (tête de pont) :** le **développeur Mac qui vibe-code** avec des outils d'IA et a déjà une IA de confiance, cette IA devient le planificateur d'actions de JARVIS.

## Buyer personas (résumé, détail dans audience-personas.md)
1. **Le vibe-coder Mac** (beachhead), dev Mac, vibe-coder, a déjà une IA de confiance.
2. **Le pro privacy-first**, avocat, médecin, fondateur, journaliste.
3. **Le knowledge worker multilingue**, opérateur EU/LatAm, support, comms.
4. **Le penseur long-format**, écrivain, PM, chercheur, note-taker.
5. **L'opérateur voice-first** *(nouveau, ouvert par JARVIS)*, fondateur/PM vivant dans Gmail/Slack/Linear/Calendar.

## Core value proposition
Ta meilleure pensée sort à voix haute et en désordre, mais tout ce que tu **envoies** doit être tapé et propre. Verba comble cet écart **sans** (a) uploader ton audio privé ni (b) exposer tes données à un tiers, et désormais **agit** sur l'intention dictée. *Plus* pour *moins* : actions + vision + notes + traduction à **9,99 $** vs 12-17 $ chez les incumbents qui envoient l'audio à leurs serveurs.

## Differentiators / moat (ordre de priorité)
1. **IA privée, aucune donnée exposée, sans clé API à gérer** *(catégorie-d'un ; vérifié en interne)*.
2. **Privé par défaut**, nos modèles privés on-device, **l'audio ne quitte jamais le Mac et n'est jamais uploadé** (sync texte-only) ; clés dans le Keychain.
3. **Voice → action (JARVIS)** *(catégorie-d'un ; `ActionExecutor.swift`, commits 5ae8804, 7452012)*, le **plan est généré on-device par l'IA de l'user**, jamais une clé serveur (d86685b) ; classifier read/write fail-safe, **aucune écriture auto-exécutée**.
4. **Fait ce que les autres ne font pas**, Context (vision), Notes (1 h), Translate live.
5. **6 modes, le bon modèle à chaque fois** (Flow/Polish/Intent/Translate/Context/Coding) routés vers le modèle IA le plus adapté à chaque tâche.
6. **Ça t'apprend**, vocabulaire auto-appris, ton par app, format par app.
7. **Moins cher et honnête**, 9,99 $ + les pages `/vs` & `/compare` (24 features × 10 marques, `website/lib/compare-matrix.ts`) disent où les rivaux gagnent encore.

## Messaging pillars (3, l'ancre de tout le pack)
- **P-A · Privé par défaut**, *« ta voix ne devrait pas quitter ton Mac »* (même la planification d'action tourne on-device).
- **P-B · IA privée, coût minimal**, *« pas de marge cachée sur l'IA »* (modèles privés on-device, coût marginal très faible, jamais une clé API à gérer).
- **P-C · Voice → action (JARVIS)**, *« ta voix ne devrait pas juste écrire, elle devrait* agir *»* (plan → confirme → exécute, 1 000+ apps).
> Narratif maître du lancement : *« The Mac dictation app that became a voice agent. »*

## Proof / social proof
- Validation catégorie : l'incumbent benchmark (**Wispr Flow**) lève à **2 Md$** (mai 2026).
- **6 modes · 3 moteurs de transcription · 99+ langues · 15 cibles Translate.**
- **JARVIS : 989 toolkits / 36 998 outils, 100 % couverture schéma** (83da81b) ; écritures certifiées **5/5** en read-back adversarial (b428a1f).
- **Planification on-device** vérifiée avec la clé serveur épuisée (d86685b).
- **UI : 998 strings × 14 langues** (b3dd02c).
- **Pas de témoignages publics encore**, preuve actuelle = profondeur produit + momentum catégorie. *1er job marketing : fabriquer une preuve early crédible (reviews, démos créateurs, benchmarks "parler-vs-taper").*

## Pricing & monetization context
- **Freemium → Pro 9,99 $/mois ou 84 $/an** ; essai 7 j au checkout ; in-app **essai full-Pro de 33 dictées** avant le paywall (`Entitlement.swift` `freeTrialDictations = 33`).
- **Modèles privés on-device → coût d'inférence quasi nul**, marge brute très élevée (seuls coûts : paiement + sync légère).
- Boucles de croissance natives : **referral « Free Month »** + **leaderboard** public + **gamification** (100 niveaux).
- **Objectif business :** **5 000-15 000 €/mois** récurrents (≈ 600-2 000 abonnés payants), le north-star GTM.
- ⚠️ **Garde-fou honnêteté (L2) :** le tier **« Founder's / Lifetime 149 $ » n'existe PAS encore dans Stripe** (seuls monthly + annual sont live) ; c'est le **levier de lancement à construire/tester en T-4**, jamais à publier avant le Go/No-Go.

## Voice & tone
- **Ton :** confiant, franc, un brin malicieux. Pro-user, jamais vendeur. Goût Apple-natif (le site est « Black-craft, Apple-grade precision », `globals.css`).
- **Style :** direct et concret ; *l'honnêteté radicale comme arme marketing* (les pages `/vs` listent où les concurrents gagnent).
- **Personnalité (5 adjectifs) :** précis · privé · malicieux · pro-user · sans prétention.
- **Mots à utiliser :** on-device, privé, ton IA, IA privée, sans marge, sans exposition de données, propre, modes, offline, Apple-Silicon, vibe coding, one press, voice agent, JARVIS, connected apps, *it asks before it acts*, confirm.
- **Mots à éviter :** « uploads to our servers », « sends your audio to their servers », « we train on your data », « transcription » seul, et **« Composio » en public** (les noms publics sont *JARVIS* et *connected apps*, commit interne).

## Note de langue (réconciliation, L2)
Le **produit cible des devs/Mac users anglophones** : par décision canonique (`content-juillet-2026/README.md` §"contenu à publier en anglais"), **la copy publiable (ads, posts, hooks) reste en ANGLAIS**, réutilisée verbatim des docs racine. La **prose stratégique/contextuelle** (ce dossier numéroté, le `Verba-Marketing-Strategy.pdf`) est en **français** (produit détenu par Agentik/Dafnck, R-STYLE). Les fichiers `02-copy/*` donnent donc des exemples FR pour le marché francophone **et** renvoient au canon EN pour le marché anglophone, sans clobber.
