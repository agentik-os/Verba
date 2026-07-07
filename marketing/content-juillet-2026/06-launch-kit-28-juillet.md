# 06, Launch Kit, Semaine de lancement du 28 juillet 2026

> Livrable de contenu juillet 2026 · Verba (verba.run) · ICP beachhead : développeurs Mac Claude Code-native
> Source verbatim : `marketing/launch-strategy.md` (§2 levier Founder, §3 gates, §5 copy complet, §6 runbook heure-par-heure)
> Narratif unique répété partout : **"The Mac dictation app that became a voice agent."**
> Langue : copie à publier en **anglais** (audience anglophone dev/Mac) ; notes d'orchestration en français.
> Statut : **prêt à publier**, sauf la copie marquée du garde-fou ci-dessous, qui dépend d'un prérequis bloquant.

---

## 🚨 GARDE-FOU BLOQUANT, À LIRE AVANT DE PUBLIER QUOI QUE CE SOIT

Le **"Founder's Edition, $149 lifetime, first 200"** apparaît dans presque chaque bloc de copie ci-dessous (PH, maker
comment, Show HN, Reddit, X thread, email, runbook). **Il n'est PAS encore live dans Stripe**, aujourd'hui seuls les plans
**monthly ($9.99/mo)** et **annual ($84/yr)** existent. La stratégie le PRÉVOIT comme levier de lancement, rien de plus.

> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**

Règle d'application :
1. Cette ligne de garde-fou est répétée **à chaque occurrence** de l'offre Founder dans ce document.
2. Tant que le SKU n'est pas live + testé (entitlement honoré in-app + `?ref` intact), **chaque ligne "$149 lifetime / Founder's Edition" doit être RETIRÉE de la copie avant publication.** Ne jamais publier une offre non vendable.
3. C'est l'**item #1** du Go/No-Go ci-dessous (§1). Rouge sur cet item = soit on retire toutes les lignes Founder de la copie, soit on glisse le lancement (cf. §3 stratégie : "never launch on a leaky funnel").
4. Aucune feature non livrée n'est promise nulle part (iOS scaffoldé = **non marketé**). L'agent s'appelle **JARVIS / connected apps**, jamais un nom de fournisseur interne.

---

## 0. Séquençage de la semaine de lancement (vue d'ensemble)

Étalement délibéré : chaque canal a son pic, on ne fait pas tout collider le même jour (cf. §6 "staggered so each spike
gets full attention and you don't burn the audience in one collision").

| Date | Jour | Canal / Action | Fenêtre horaire |
|---|---|---|---|
| **Ven 24 juil** | Vendredi | **Go/No-Go review**, tous les gates §1 verts → GO ; un item funnel/activation/offer rouge → glisser d'une semaine |, |
| **Lun 27 juil** | Lundi (T-1 day) | Asset check final ; pré-staging de tous les posts ; teaser "tomorrow" sur X ; coucher tôt | soir |
| **Mar 28 juil** | Mardi (T-0) | **LAUNCH DAY, Product Hunt** (live 12:01am PT) + X launch thread + launch email, runbook §7 | 12:01am PT → 11:59pm PT |
| **Mer 29 juil** | Mercredi (T+1) | **Show HN** (tenu ~1 jour après PH pour ne pas split l'attention) + suivi PH (remerciements) | ~8-10am ET / matin PT |
| **Jeu 30 juil** | Jeudi (T+2) | **Reddit r/macapps puis r/ClaudeAI** (staggered de quelques heures) + recap de lancement sur X | r/ClaudeAI quelques h après r/macapps |
| **Ven 31 juil** | Vendredi | Follow-up de tous ceux qui ont engagé ; email "we launched" à la full list ; conversion des Founder warm | journée |
| **Week-end** | Sa/Di | Repos + monitoring léger ; brouillon du post "chiffres semaine 1" |, |

---

## 1. Go/No-Go, revue du **vendredi 24 juillet 2026**

> Ces gates sont **bloquants**. Un item rouge déplace la date de lancement, on ne lance jamais sur un funnel qui fuit
> (stratégie §3 / §8 Phase 0). Décision binaire le ven 24 juil : tous verts → **GO** pour mar 28 juil. Un item funnel /
> activation / offer rouge → **slip d'une semaine**.

### ✅ Item #1 (par directive de ce kit), Offre Founder

- [ ] **SKU Stripe "Founder's Edition" ($149 lifetime, first 200) construit + test purchase OK + entitlement honoré in-app + attribution `?ref` intacte.**
 > **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**
 > Si rouge le 24 juil : **retirer toutes les lignes "$149 lifetime / Founder's Edition" de la copie §2-§6** (lancer sans le levier) OU glisser d'une semaine. Ne jamais publier une offre non vendable.

> *Note d'honnêteté (L2) :* la stratégie désigne son **propre blocker funnel #1** comme le correctif copie `api/try` (ci-dessous). Les deux sont bloquants ; "item #1" ici est l'ordre imposé par ce kit, pas un reclassement de priorité produit.

### Funnel integrity (stratégie §3, les deux fixes re-vérifiés encore ouverts au 2026-06-12)

- [ ] **Free-tier copy gap CLOSED.** `website/app/api/try/route.ts` (lignes 56/67) pousse encore *"free up to 10,000 words/month"*, le reste du site standardise sur **33 dictations** (`Entitlement.swift` `freeTrialDictations = 33`). Aligner ce fichier sur l'histoire des 33 dictations. **C'est le blocker pré-lancement #1 de la stratégie**, un seul message free-tier vrai partout.
- [ ] **Privacy claim accurate everywhere.** Aucun "nothing written to disk". L'audio est gardé en **local history par défaut** (`History.swift`) mais **jamais uploadé** (sync text-only). Claim approuvé : *"your audio never leaves your Mac, local history with an off switch + auto-prune."* Scrubber la PH gallery, les captions de démo, le commentaire HN, la copie du site.

### Activation (le make-or-break, stratégie §3 / GTM §5 lever 1)

- [ ] **First successful dictation en < 60 secondes, sans carte, sans clé.** Le chemin zero-key Claude Code est le héros du first-run ("Have Claude Code? You're ready, no key") ; **Parakeet offline** est le fallback instant sans setup. Tester à froid sur un Mac clean.
- [ ] **First confirmed action path works cold**, connecter une app dans Settings ▸ Connected apps → dicter un "create/send/schedule" → voir le plan → confirmer → ça s'exécute. Second moment d'activation ; ne doit pas erreur le jour 1.

### Hero demo

- [ ] **Démo canonique 60-sec enregistrée, finissant sur une action JARVIS.** Opener speak-vs-type → une vraie dictée → finir sur *"…and when I say 'create the issue,' it does it"* avec le confirm step visible.
- [ ] **3-4 × cutdowns 15-sec** pour X / Reddit / PH : une par action JARVIS (Linear, Gmail, Slack, Calendar), "say it → confirm → done."

### Proof (fabriquer la première crédibilité, il n'y en a aucune encore)

- [ ] **10-20 reviews / quotes seedées** en main (Phase 0). Sources : testeurs internes, créateurs seedés, early users dev-community. Honnêtes, attribuées, spécifiques ("saved me from typing a 300-word spec"). Deviennent le social proof du first comment PH + les testimonials de la landing.
- [ ] **Une poignée de Founder-license buyers seedés** prêts à convertir dans la première heure (warm list) pour que l'offre montre de la traction au lancement, pas un cold ask à $149.
 > **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**

### Product Hunt assets

- [ ] Listing : name + **tagline ≤ 60 chars** (§2), description, topic tags (Mac, Developer Tools, Artificial Intelligence, Productivity).
- [ ] **Gallery** : 1ère image = le moment confirm JARVIS (le hook), puis speak-vs-type, les 6 modes, la matrice d'honnêteté `/compare`, le frame privacy/on-device, le pricing incl. tier Founder. **Vidéo en premier dans la gallery.** Ordre final : video → JARVIS confirm image → modes → /compare → privacy → pricing+Founder.
- [ ] **Maker's first comment** rédigé (§2), posté à 12:01am PT.
- [ ] **Hunter** sécurisé (self-hunt OK pour les dev tools ; un hunter crédible Mac/dev si joignable, mieux).
- [ ] PH "promo/offer" set : la Founder license + un code launch-day ou discount premier mois pour le monthly.
 > **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**

### Instrumentation (on ne scale pas ce qu'on ne voit pas, GTM §5)

- [ ] Funnel events live end-to-end : download → activate (first dictation) → first confirmed action → paywall → trial → paid → referral. Vercel Analytics sur le site ; Convex stats in-app. UTM/`?ref` sur chaque lien de lancement.

### Owned-channel readiness (ORB, owned first)

- [ ] Email capture live sur verba.run ; toute early list existante segmentée et prête.
- [ ] In-app : referral "Free Month", leaderboard partageable, gamification câblée à l'onboarding (GTM §7), *staged pour flip ON dans la fenêtre post-launch, pas avant* (ne pas splitter l'attention le jour J).

---

## 2. Le levier de lancement, Founder / Lifetime tier (rappel stratégie §2)

> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**

Framing de lancement (verbatim §2) : une **"Founder's Edition, first 200 / first 30 days"** capée et time-boxée. Scarcité +
l'histoire "support an indie building in public" que cette audience récompense. Prix **$149** (sous l'ancre Superwhisper
$249.99, au-dessus de MacWhisper $69, positionne Verba premium-but-fair). C'est l'offre spéciale PH, la ligne "and there's
a lifetime deal for HN" du Show HN, et l'urgence du X thread. **Gate avant lancement :** Stripe Founder SKU live + testé,
attribution `?ref` intacte, entitlement de licence honoré in-app. *(COGS d'inférence = zéro grâce au BYOK, même le planner
tourne sur l'IA de l'utilisateur, donc le lifetime ne porte aucun risque de coût récurrent : "unusually safe here".)*

---

## 3. Product Hunt, **mardi 28 juillet 2026** (live 12:01am PT)

Copie verbatim de la stratégie §5. Tagline = 47 chars (limite ≤ 60). Prête à coller dans le listing PH.

**Name:**
```
Verba
```

**Tagline (≤60 chars), 47 chars :**
```
The Mac dictation app that became a voice agent
```

**Alt taglines (de secours) :**
```
Speak it. Send it clean. Then watch it act, on your Mac  (56 chars)
Private Mac dictation that acts on what you say      (47 chars)
```

**Topic tags :** `Mac` · `Developer Tools` · `Artificial Intelligence` · `Productivity`

> ⚠️ **Le bloc Description ci-dessous contient la ligne Founder's Edition.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live au 28 juil, **RETIRER la dernière ligne (🚀 Founder's Edition…) avant de publier.**

**Description (PH listing body) :**
```
Verba is a macOS menu-bar dictation app, press a hotkey, talk, and it turns your rambling into clean, formatted text and pastes it exactly where your cursor is. Now it does more than type: JARVIS, Verba's voice agent, takes a spoken intent ("create the Linear issue and email the team a summary"), plans the steps on your Mac, shows you exactly what it'll do, and executes only after you confirm, across 1,000+ connected apps + native Mac actions.

• Private by default, your audio never leaves your Mac, never uploaded (local history has an off switch).
• Bring your own AI, reuse your Claude Code subscription with no API key, or Anthropic/OpenRouter/local Ollama. No markup.
• 6 modes, screen-vision Context mode, hour-long Notes, live Translate, 14-language UI.
• $9.99/mo or $84/yr, 33-dictation full-Pro trial, no card to start.

🚀 Founder's Edition for Product Hunt: a one-time $149 lifetime license, first 200 only.
```

> ⚠️ **Le Maker's first comment ci-dessous contient la ligne Founder's Edition.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer la phrase "$149 lifetime Founder's Edition (first 200)" avant de poster.**

**Maker's first comment (posté à 12:01am PT) :**
```
Hey Product Hunt 👋 I'm the founder of Verba.

It started as the Mac dictation app I wanted, on-device, reuses the Claude subscription I already pay for, no markup. Then I realized: if my own AI can clean up what I say, it can also act on it. So I built JARVIS, say "create the Linear issue for this bug and email the team," and Verba plans it, shows me both actions, and does them only after I confirm.

Two things I care about most: it's private (your voice never leaves your Mac) and it never acts without asking, every write is shown to you first. The demo above is one unedited take, confirm step included.

For PH today there's a $149 lifetime Founder's Edition (first 200). I'm here all day, ask me anything, and tell me what you'd want to do by voice.
```

---

## 4. Show HN, **mercredi 29 juillet 2026** (~8-10am ET / matin PT, meilleure fenêtre HN)

> Tenu délibérément ~1 jour après PH pour que les deux pics ne collident pas. HN punit le hype, récompense la candeur
> (`product-marketing.md` §Brand Voice "radical honesty"). Rester dans les commentaires les 2 premières heures, répondre à
> **chaque** commentaire.

**Title options (HN récompense les titres honnêtes, spécifiques, non-marketing) :**
```
Show HN: Verba, Mac dictation that acts on what you say, using your own Claude  (primary)
Show HN: A private Mac voice agent that reuses your Claude Code sub (no API key)
Show HN: I turned a Mac dictation app into a confirm-gated voice agent
```

> ⚠️ **Le body ci-dessous contient la ligne lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer la phrase "There's a $149 lifetime for anyone who wants it." avant de poster.**

**Show HN body (framing honnête) :**
```
Verba is a macOS dictation app I've been building. You press a hotkey, talk, and it restructures your speech into clean text wherever your cursor is. The part I want feedback on: it now acts. Say "create the Linear issue and email the team," and it plans the steps on-device using your own AI (your Claude Code subscription, an Anthropic/OpenRouter key, or local Ollama, never a key of mine), shows you the plan, and executes only after you confirm. 1,000+ connected apps + native Mac actions. Every write is confirm-gated; anything ambiguous is treated as a write and never auto-run.

Honest limitations: it's macOS-only today. It's BYO-AI, so first-run means connecting an AI account (the zero-key Claude Code path is the easy one). Audio stays on your Mac (local history, with an off switch), it's never uploaded.

$9.99/mo, 33-dictation free trial, no card. There's a $149 lifetime for anyone who wants it. I'd genuinely like to hear where the agent breaks and what you'd want to do by voice. Demo: [link]
```

---

## 5. Reddit, **jeudi 30 juillet 2026**

> Lead avec la démo, value-first, jamais un pitch (content-strategy §6). r/ClaudeAI posté **quelques heures après**
> r/macapps (stagger). Rappel : on a fourni de la valeur dans ces communautés ≥2 semaines AVANT de poster (T-2). PH/Reddit/HN
> interdisent la sollicitation de vote, demander uniquement de l'engagement **genuine**.

### r/macapps (poster jeu 30 juil)

**Title :**
```
I built a private Mac dictation app that can also *act* on what you say (JARVIS-style, but it asks before it does anything)
```

> ⚠️ **Le corps ci-dessous référence l'offre lifetime ($149).**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer la mention "$149 lifetime if you hate subscriptions".**

**Body (structure verbatim §5) :** court, la **démo GIF en premier**, les points privacy + BYO-AI, *"$9.99, 33 free
dictations, no card; $149 lifetime if you hate subscriptions,"* et un honnête *"Mac-only, here's our /compare page that lists
where rivals beat us."* Finir par **une question** pour inviter la discussion, pas un mur de CTA.

### r/ClaudeAI (poster jeu 30 juil, quelques heures après r/macapps)

**Title :**
```
Verba uses your Claude Code subscription to dictate *and* to run actions on your Mac, no API key
```

> ⚠️ **Le corps ci-dessous référence le lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer la mention "lifetime" du combo "free trial + lifetime".**

**Body (structure verbatim §5) :** lead avec l'angle **Claude-Code-as-planner** (le hook de ce sub) : *"your Claude Code
install is the action planner, the agent you already pay for now runs your Mac by voice, on-device."* Demo clip, emphase
confirm-gate, free trial + lifetime.

---

## 6. X / building-in-public, Launch thread (**mardi 28 juillet**, posté 12:05am PT, pin it)

> Timing rappel : pic dev X 14:00-17:00 UTC + ~21:00 UTC. Le thread part à 12:05am PT le jour J (runbook §7), puis re-share
> avec updates de traction le matin US.

> ⚠️ **Le tweet 6/ ci-dessous contient la ligne Founder's Edition.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **remplacer "And for launch: a $149 lifetime Founder's Edition, first 200." par la ligne free-trial seule.**

**Thread (6 tweets, verbatim §5) :**

```
1/ I shipped it: the Mac dictation app that became a voice agent. 🧵
I dictate "create the Linear issue for this bug and email the team a summary." Verba plans it, shows me both actions, I hit confirm, done. One unedited take 👇 [video]
```
```
2/ It started as dictation: talk, get clean text where your cursor is. On-device. Reuses the Claude sub I already pay for, no API key, no markup.
```
```
3/ Then: if my own AI can clean up what I say, it can act on it. So Action mode became JARVIS, 1,000+ connected apps + native Mac actions.
```
```
4/ The rule I won't break: it never acts without asking. Every write is shown first; ambiguous = treated as a write, never auto-run. The confirm step is the feature.
```
```
5/ Private by design: your voice never leaves your Mac; the plan is generated on your Mac by your own AI, not my server.
```
```
6/ $9.99/mo, 33 free dictations, no card. And for launch: a $149 lifetime Founder's Edition, first 200.
We're live on Product Hunt today, link below. Tell me what you'd want to do by voice. 👇
```

---

## 7. Launch email, **mardi 28 juillet** (envoyé 12:05am PT, full list)

> ⚠️ **Le hook ci-dessous référence l'offre Founder lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer "the Founder lifetime offer" du hook.**

**Subject :**
```
Verba can now do what you say (not just type it)
```

**Hook (verbatim §5) :** la narrative line *("The Mac dictation app that became a voice agent")* + la **démo GIF** + *"we're
on Product Hunt today"* + l'offre **Founder lifetime**.

---

## 8. Runbook heure-par-heure, **mardi 28 juillet 2026** (tous horaires PT, l'horloge de PH)

> Verbatim stratégie §6. PH days : **12:01am → 11:59pm PT**. L'engagement des premières heures fixe la trajectoire de
> ranking. **Traiter ça comme un événement toute la journée.** Couverture : Founder en primary, Helper sur monitoring/scheduling.

| Time (PT) | Action |
|---|---|
| **12:01am** | PH listing goes live. Post the **maker's first comment** immediately (§3). |
| **12:05am** | Post the **X launch thread**; pin it. Send the **launch email** to the full list. |
| **12:10am** | Personally ping the **warm list + seeded creators**: "we're live, would love your honest take" (ask for genuine engagement, never "upvote"; PH bans vote manipulation). |
| **6:00am** | Wake / check ranking & comments. Reply to **every** PH comment. Convert the first warm **Founder-license** buyers so the offer shows traction. |
| **6:00am-9:00am** | Peak US-morning traffic. Reply within minutes everywhere. Re-share the X thread with an early-traction update. |
| **9:00am** | First metrics pulse (see watch-list). Post a "we're #X on PH" update to X if ranking is strong. |
| **12:00pm** | Midday push: a fresh 15-sec JARVIS cutdown on X; thank early supporters by name; answer the hardest objections publicly (agent-trust, Mac-only). |
| **3:00pm** | EU is asleep, US afternoon active, keep replying. Drop the "you're paying twice for AI, the math" angle if conversation is slow. |
| **6:00pm** | Evening pulse; engage the late-day PH browsers and the EU-evening stragglers. |
| **9:00pm** | Final push before PT midnight if in contention for top spots. Last call on the Founder tier for the day. |
| **11:59pm** | Day closes. Screenshot final rank + stats. Draft thank-you list for tomorrow. |

> ⚠️ **Le runbook référence l'offre Founder (lignes 6:00am "convert Founder-license buyers" et 9:00pm "last call on the Founder tier").**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live le jour J, ces deux actions opérationnelles tombent (rien à vendre/convertir) ; garder le reste du runbook intact.

**Hold for tomorrow (délibéré) :** Show HN (Wed AM), r/macapps + r/ClaudeAI (Thu), staggered pour que chaque pic ait toute
l'attention et qu'on ne brûle pas l'audience dans une collision.

**First-24h engagement plan (verbatim §6) :**
- Répondre à **100% des commentaires** sur PH, puis HN/Reddit à mesure qu'ils sortent, de vraies réponses, pas des lignes canned.
- Rediriger chaque réponse vers verba.run pour **capturer l'email / démarrer le trial** (ORB : convertir l'attention louée en owned).
- Faire surface un vrai testimonial ou la matrice d'honnêteté `/compare` dès que quelqu'un doute de la profondeur.
- Logger chaque objection verbatim → devient FAQ + contenu (content-strategy §7 forum mining).

**Metrics to watch (live dashboard, GTM §9) :**
- **Top-of-funnel :** PH rank/upvotes/comments, DMG downloads (GitHub Releases), site sessions, email captures.
- **Activation :** % downloads → first dictation, **time-to-first-dictation** (target <60s), **time-to-first-confirmed-action**.
- **Monetization :** paywall hits, 7-day trial starts, **Founder-license sales**, monthly/annual checkouts.
- **Loop :** referral links generated, leaderboard shares.
- **Guardrail :** error rate on first dictation + first JARVIS action (un first-run cassé le jour du lancement est le pire outcome, le surveiller comme un faucon ; L1 runtime truth).

---

## 9. Réponses prêtes aux objections (pour les commentaires PH / HN / Reddit, stratégie §8)

> À copier-coller dans les threads. Lead with control, not capability.

- **"Un voice agent dans mon Gmail/Slack ? non merci" (agent-trust)** → *"It asks before it acts, every write is shown to
 you first, ambiguous is treated as a write and never auto-run, and the plan is generated on your Mac by your own AI, never
 a server key. Reads are capped/auto-run, writes are always confirm-gated, and you can disconnect any app in Settings."*
- **"Mac-only ?"** → *"Yes, it's the best native macOS option today. If you need Windows/mobile right now, Wispr Flow wins
 there, and we say so on our /compare page. We chose focus."* **Ne PAS promettre iOS ni donner de date** (iOS scaffoldé, non shippé).
- **"Why pay vs Apple Dictation / why not Wispr?"** → *"Apple just transcribes, no restructuring, no modes, no intent.
 Wispr uploads your audio, costs ~$15, locks you into its markup, and only types. Verba is on-device, $9.99, BYO-Claude, and
 it acts."*
- **"Vous écrivez l'audio sur le disque ?" (privacy)** → claim défendable et vrai (`History.swift`) : *"audio never leaves
 your Mac, local history with an off switch + auto-prune. Sync is text-only."*

---

## 10. Definition of done, un lancement réussi (grade contre ça, pas des vibes, R-RUBRIC)

- **Funnel clean** avant T-0 : copy gap `api/try` fermé, privacy claim exact, first dictation <60s, first confirmed action OK, tout vérifié live. *(Le lancement est invalide si ce n'est pas vrai.)*
- **Spike capturé dans les owned channels :** captures email + trial starts mesurables, pas juste des upvotes (discipline ORB).
- **Founder-license prouve le levier** *(si le SKU est live)* : le tier lifetime convertit l'acheteur anti-abonnement et front-load le cash.
- **Reviews/proof fabriqués :** le lancement produit la première vague de proof publique attribuée que Verba n'avait pas.
- **Loops allumés :** referral + leaderboard + gamification live in-app dans T+1 semaine.
- **Trajectoire vers GTM §8 Phase 1 :** download→paid tendant vers le modèle 7-10% ; premiers subs payants vers le milestone ~700 (≈€5k/mo).

Le lancement est **l'ignition**, pas la destination, il allume les trois moteurs qui compoundent (SEO+GEO, communauté,
créateurs) et les growth loops codées, puis se retire de leur chemin.

---

*Construit verbatim sur `marketing/launch-strategy.md` (§2, §3, §5, §6). Aucune feature inventée ; iOS non marketé ; l'agent
est JARVIS / connected apps. L'offre **Founder's Edition $149 lifetime n'est PAS live dans Stripe**, chaque occurrence est
balisée du prérequis bloquant ; à retirer de la copie tant que le SKU + entitlement + `?ref` ne sont pas testés.*

--- **Resume :** Kit de lancement complet écrit dans `marketing/content-juillet-2026/06-launch-kit-28-juillet.md`,
séquençage (PH mar 28, Show HN mer 29, Reddit jeu 30), Go/No-Go du ven 24 juil avec le SKU Founder en item #1, copie
verbatim prête à coller (Product Hunt name/tagline 47 chars/description/maker comment, Show HN titres+body, Reddit
r/macapps + r/ClaudeAI, X thread 6 tweets, launch email subject+hook), runbook heure-par-heure du mardi 28 juil (PT)
verbatim, réponses aux objections, et definition of done. Le tier "Founder's Edition $149 lifetime" est balisé du
prérequis bloquant Stripe en tête de fichier, en item #1 de la checklist, et à chacune de ses ~9 occurrences.*
