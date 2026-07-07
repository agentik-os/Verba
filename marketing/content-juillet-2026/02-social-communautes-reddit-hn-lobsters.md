# 02, Communautés, Reddit · Hacker News · Lobsters · Discord (juillet 2026)

> Livrable de contenu juillet 2026 · Verba (verba.run) · ICP beachhead : **développeurs Mac Claude Code-native**
> Sources verbatim : `marketing/social-content.md` (angles, étiquette communautaire §B, hook bank) · `marketing/launch-strategy.md` (§4 timeline T-2, §5 copy Show HN + Reddit, §6 engagement premières 24 h)
> Narratif unique répété partout : **"The Mac dictation app that became a voice agent."**
> Langue : **toute la copie à publier est en anglais** (audience anglophone dev/Mac) ; les notes d'orchestration sont en français.
> Scope de ce fichier : (A) **warm-up T-2** value-first (lun 13 → dim 19 juil) + (B) **kit communautés de lancement**, Show HN (mer 29 juil) et Reddit r/macapps + r/ClaudeAI (jeu 30 juil), **bodies écrits en entier**.
> Voisin (ne pas dupliquer) : `06-launch-kit-28-juillet.md` couvre le jour J PH-centré (Product Hunt, X thread, email, runbook). **Ici** = la couche communautés : le warm-up qui précède + les **corps Reddit complets** (le 06 ne porte que le brief). Le Show HN apparaît dans les deux, verbatim de la même source, pas de conflit (fichiers disjoints, R-SCOPE).

---

## 🚨 GARDE-FOU BLOQUANT, À LIRE AVANT DE PUBLIER LE KIT DE LANCEMENT (§B)

Le **"$149 lifetime / Founder's Edition"** apparaît dans la copie de lancement verbatim (Show HN, Reddit). **Il n'est PAS encore live dans Stripe**, aujourd'hui seuls **monthly ($9.99/mo)** et **annual ($84/yr)** existent. La stratégie le PRÉVOIT comme levier, rien de plus.

> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**

Règle d'application (identique au fichier 06, pour cohérence du dossier) :
1. Cette ligne de garde-fou est répétée **à chaque occurrence** de l'offre Founder ci-dessous.
2. Tant que le SKU n'est pas live + testé (entitlement honoré in-app + `?ref` intact), **chaque phrase "$149 lifetime / Founder's Edition" doit être RETIRÉE de la copie avant publication.** Ne jamais publier une offre non vendable.
3. Le **warm-up (§A) ne mentionne ni prix, ni lifetime, ni produit**, il est value-first et n'est donc pas concerné par ce garde-fou.
4. Aucune feature non livrée n'est promise nulle part. **iOS est scaffoldé = non marketé** (zéro mention iPhone/iPad). L'agent s'appelle **JARVIS / connected apps**, jamais un nom de fournisseur interne. Aucune démo ne montre un write non confirmé.

---

## 0. Protocole d'engagement, s'applique à CHAQUE post de ce fichier

> Distillé verbatim de `social-content.md` §"Community-posting etiquette" + §"Timing" et de `launch-strategy.md` §6 "First-24h engagement plan". Ces canaux punissent le marketing et récompensent l'utilité. Non négociable.

1. **Lead with the demo or the build story, never the pitch.** Open with the artifact ("I dictated one sentence and it created the issue" + the clip), not "Introducing Verba, the #1…". Let the artifact earn the click.
2. **Disclose you're the founder.** "I built this" is trust; pretending to be a neutral user is the fastest way to get torched. (Pure value posts that name no product and drop no link need no disclosure, but the moment the product comes up, disclose.)
3. **Be honest about limits, unprompted.** Mac-only. Indie. Early, no testimonials yet. Naming the weakness (the way the `/compare` page does) is *why* this crowd believes the strengths.
4. **Stay in the comments for the first 2 hours.** This is a ranking **and** a trust signal. Answer every technical question precisely; thank the critics. Never post a thread and ghost it.
5. **Never fake it.** No invented features, no iOS claims, no unconfirmed-write demo, never the internal vendor name, only **JARVIS / connected apps**. The confirm step stays in every clip, it *is* the trust story.
6. **One ask, soft.** A single link at the end (launch posts only). No "upvote pls", no DMs, no reposting the same thing across five subs the same hour. PH/Reddit/HN ban vote solicitation, ask only for **genuine** engagement.
7. **Capture rented attention into owned.** Direct replies back to verba.run to start the trial / capture the email; log every objection verbatim → it becomes FAQ + content.

**Timing reference (UTC):** dev audiences engage **14:00-17:00 UTC** (US morning) and **~21:00 UTC**. Show HN best window: **weekday 13:00-16:00 UTC** (≈ 8-10am ET / morning PT). Reddit launches: US morning-midday UTC, staggered.

---

# SECTION A, WARM-UP T-2 (lun 13 → dim 19 juil), value-first, ZÉRO pitch

> Mappe `launch-strategy.md` §4 T-2 : *"Be present in the beachhead communities now, providing value, not pitching … answer dictation/voice questions on r/macapps, r/ClaudeAI, Lobsters, Cursor/Claude Discords."* Objectif : être un contributeur utile et reconnu **2 semaines avant** de poster quoi que ce soit de promotionnel, pour que le lancement atterrisse chaud.
>
> **Règle d'or du warm-up :** aucun de ces posts ne nomme Verba, ne met de lien, ni de prix. Ce sont de la **vraie valeur** (savoir, workflow, discussion technique). Le produit ne se mentionne qu'**en réponse**, si quelqu'un demande, via les *reply templates* (§A.5), toujours avec disclosure fondateur, jamais de lien non sollicité.

### A.0, Calendrier du warm-up (rotation des 4 canaux)

| Date | Jour | Canal | Heure (UTC) | Heure locale | Format |
|---|---|---|---|---|---|
| **13 juil** | Lundi | r/macapps | **15:00 UTC** | 11:00 ET / 08:00 PT | Post valeur (privacy how-to) |
| **14 juil** | Mardi | r/ClaudeAI | **15:00 UTC** | 11:00 ET / 08:00 PT | Post valeur (workflow voice→prompt) |
| **15 juil** | Mercredi | Lobsters | **16:00 UTC** | 12:00 ET / 09:00 PT | Discussion technique ("ask") |
| **16 juil** | Jeudi | Cursor / Claude Discord | **21:00 UTC** | 17:00 ET / 14:00 PT · soir EU | Tip drop + Q&A |
| **17-19 juil** | Ven-Dim | Les 4 canaux | fenêtres ci-dessus |, | **Reply-sweep** (pas de nouveau post, voir §A.5) |

> **Note cadence (FR) :** `social-content.md` recommande **1 community post/semaine** en régime de croisière. Quatre posts originaux dans la semaine T-2 est volontairement plus dense (un par canal, pour amorcer), mais on **ne dépasse pas** un post original par canal, et le reste de la semaine (ven-dim) est de la **participation pure** (réponses), pas de nouveaux posts. Poster les 4 le même jour ou répéter le même post sur plusieurs subs = pattern "campagne" que ces communautés sanctionnent. On étale.

---

### A.1, r/macapps · lundi 13 juillet · 15:00 UTC

**Type :** text post, value-first. Aucun produit, aucun lien.

**Title :**
```
PSA: how to actually check whether your Mac dictation app is uploading your audio
```

**Body :**
```
Most of us dictate sensitive stuff, client notes, half-formed ideas, code, into a menu-bar app we never audited. A few ways to actually verify where your audio goes, regardless of what the marketing says:

1. Watch the network. Little Snitch or LuLu (free) will show the app's outbound connections while you dictate. On-device transcription is basically silent network-wise during a dictation; if audio is leaving, you'll see the traffic.

2. Read the policy for the word "audio" specifically. Plenty of apps say "we don't sell your data" while still uploading your audio to their servers for processing. Different claim. Look for whether transcription happens on-device or in the cloud.

3. Distinguish cloud SYNC from audio UPLOAD. An app can sync your text/history across devices without ever uploading the raw audio. "Syncs to the cloud" doesn't automatically mean "your voice is on someone's server."

4. Check what's stored locally. ~/Library/Application Support and ~/Library/Containers. A local history is fine if there's an off switch + a prune; the question is whether a copy ALSO goes somewhere.

Not trying to scare anyone off cloud tools, they're often more accurate and totally fine for most use. Just: if you dictate anything you wouldn't paste into a random website, know which bucket your app is in.

Curious what everyone here uses, and whether on-device matters to you or accuracy wins every time?
```

**Engagement (FR) :** rester 2 h+ dans les commentaires. Répondre à chaque "what do you use?" avec **R1** (§A.5), disclosure fondateur, **aucun lien** sauf si on le demande explicitement. But : crédibilité sur l'axe privacy (P2), pas une vente.

---

### A.2, r/ClaudeAI · mardi 14 juillet · 15:00 UTC

**Type :** text post, value-first. Workflow réutilisable par n'importe qui. Aucun produit, aucun lien.

**Title :**
```
I stopped typing long prompts to Claude Code and started dictating them, here's the workflow
```

**Body :**
```
I think faster than I type, and my Claude Code prompts were paying for it, I'd reason out a detailed spec in my head, then type a lossy "ugh, good enough" version and lose half the nuance. Switched to dictating them. Sharing the workflow because it changed my flow more than I expected:

1. Ramble first, structure later. Hit a dictation hotkey and just talk through what I want for 60-90s, context, constraints, the edge cases I actually care about. Pure stream of consciousness, no editing while talking.

2. Let an LLM restructure the ramble into a prompt. Raw speech is messy. I pass the transcript through Claude with a "turn this into a tidy, structured implementation prompt, keep every constraint" instruction. The nuance I'd have dropped while typing survives.

3. Paste it where the cursor is, terminal or editor, and go.

Two things that made it click: (a) using a model that's genuinely good at the restructure step (Opus-grade for the cleanup, not just raw transcription), and (b) getting transcription latency low enough that it doesn't break flow, if I'm waiting on a spinner, I lose the thread.

The model was never my bottleneck. The keyboard was.

Anyone else dictating to Claude Code / Cursor? What's your setup, and how do you handle the cleanup step?
```

**Engagement (FR) :** rester 2 h+. Si on demande "which app / are you building this?", répondre avec **R3** + disclosure fondateur ("launching later this month"), **lien seulement si demandé**. Angle P1/P3 montré comme workflow générique, pas comme feature produit.

---

### A.3, Lobsters · mercredi 15 juillet · 16:00 UTC

> **Note opérationnelle (FR) :** Lobsters est invite-only et sanctionne durement l'auto-promo. Ce post est une **vraie question technique** (tag `ask` + `programming`/`practices`), zéro produit, zéro lien, il partage un design et invite la critique. Si le compte fondateur n'a pas le karma/l'invite, **rabattre ce contenu en commentaire** sur un thread agent/LLM existant, ou **doubler sur les Discords** (§A.4) à la place. Ne jamais forcer un post promo sur Lobsters.

**Type :** "ask" / discussion technique. Aucun produit, aucun lien.

**Title :**
```
Ask: how are you making "the LLM performs an action" features safe enough to trust on your own accounts?
```

**Body :**
```
I've been building a feature where an LLM takes a natural-language intent and performs actions across real APIs (email, issue trackers, calendars). The capability is the easy part; making it safe enough that I'd run it on my OWN Gmail is the hard part. The design I've landed on, and where I'd genuinely like critique:

- Read vs write split. Read-only steps (look something up) can auto-run; anything that writes (send/create/delete) stops and shows the user the exact action before executing.

- Fail-safe on ambiguity. When the classifier can't decide whether a step reads or writes, it treats it as a WRITE and asks. Over-confirm beats under-confirm.

- Schema-validate + auto-repair the proposed action against the real tool schema BEFORE showing the confirm prompt, so "confirm" means confirming something that will actually execute, not a hallucinated payload.

- Keep the planner off my servers. The plan is generated by the user's own model/credentials, not a key I hold, so I'm not a custodian of their intents and there's no central honeypot of "what everyone is trying to do."

Open questions I'm chewing on:
- Granularity: per-action confirm vs per-plan confirm? Per-action is safer but risks banner-blindness.
- Classifying read/write for genuinely ambiguous endpoints (a "search" that also writes a log, a "draft" that some APIs auto-send).
- How do you keep the confirm step meaningful instead of muscle-memory "yes"?

How have others approached this? Especially curious about prod experiences, not just demos.
```

**Engagement (FR) :** Lobsters = **technique uniquement**. Répondre sur le fond, jamais nommer le produit sauf si on le demande explicitement, et même là : factuel, **aucun lien**. C'est un investissement de crédibilité (Angles 6 + 13 de social-content), pas une acquisition.

---

### A.4, Cursor / Claude Discord · jeudi 16 juillet · 21:00 UTC

> **Note (FR) :** poster dans un canal pertinent (#workflows / #showcase / #general) d'un Discord Cursor ou Claude/Anthropic, en respectant les règles du serveur (certains ont un canal dédié self-promo, s'il existe, le tip générique ci-dessous reste OK en #general car il ne pitche rien). Discord = conversationnel et court.

**Type :** message valeur + Q&A. Aucun produit, aucun lien.

**Message :**
```
Tip if you type long prompts to Claude Code / Cursor all day: try dictating them instead.

I ramble the spec out loud for ~60-90s (context + constraints + the edge cases), then run the transcript through Claude with a "restructure this into a clean implementation prompt, keep every constraint" step, paste it where my cursor is, and go. Way less friction than typing, and you keep the nuance you'd normally drop into "good enough."

Two things that matter: a model that's actually good at the restructure step (not just transcription), and low enough latency that it doesn't break flow.

Anyone else here dictating their prompts? What's your setup for the cleanup step?
```

**Engagement (FR) :** rester actif dans le fil le soir (audience US aprèm + EU soir). Disclosure fondateur si on demande l'outil, via **R3** ; lien seulement sur demande. Répondre aux questions setup des autres = la vraie valeur.

---

### A.5, Ven 17 → Dim 19 juil : reply-sweep (pas de nouveau post) + REPLY TEMPLATES

> Le cœur de la directive T-2 est **"answer dictation/voice questions"**. Ven-dim : pas de nouveau post original, on **balaie les communautés et on répond** aux questions ouvertes (r/macapps, r/ClaudeAI, Discords ; Lobsters sur les threads agent/LLM). Templates ci-dessous = valeur d'abord, disclosure fondateur honnête quand le produit surgit, **jamais de lien non sollicité**.

**R1, "Best Mac dictation app?" (r/macapps / Discord) :**
```
Honestly depends on what you optimize for:
- Apple Dictation, free, fine for short bursts, no restructuring or formatting.
- MacWhisper / VoiceInk, strong local/Whisper-based options, one-time pricing.
- Superwhisper, polished, lots of modes.
- Wispr Flow, cross-platform (Windows + mobile too) and very fast; note it uploads your audio to the cloud.

The two axes I'd actually decide on: (1) does transcription run on-device or upload your audio? and (2) does it just transcribe, or restructure your ramble into clean text? Pick for your privacy bar + how messy your speech tends to be.
```
> *Si on demande "lequel TU utilises / tu construis un truc ?" :* `Full disclosure, I'm building one in this space, launching later this month, so take me with a grain of salt. Happy to share the link if you actually want it.` (lien **uniquement** s'ils disent oui.)

**R2, privacy / "does X upload my audio?" :**
```
Good instinct to ask of anything you dictate into. Two checks: (1) does transcription happen on-device or on their servers? Read the policy for the word "audio" specifically, not just "we don't sell data." (2) Does any cloud sync upload the audio itself, or only the resulting text? You can verify either with Little Snitch / LuLu, watch outbound traffic while you dictate. On-device tools are basically silent network-wise during a dictation.
```

**R3, "can I use my Claude sub for this / for dictation?" :**
```
Yes, and it's the part people don't realize. If you have Claude Code installed, some tools can reuse that subscription directly for the AI step (the cleanup/restructure), no API key to paste, no separate AI bill stacked on top. You're not double-paying for inference you already cover with your sub. Worth checking whether a given app supports that zero-key Claude Code path vs requiring you to paste an Anthropic API key.
```
> *Disclosure fondateur si on demande l'outil ; lien sur demande seulement.*

**R4, agent safety / confirm-gating (Lobsters / Discord / r/ClaudeAI, technique) :**
```
The pattern that made me comfortable running this on my own accounts: split steps into read vs write. Read-only steps can auto-run; anything that writes (send/create/delete) stops and shows you the exact action before executing. When the classifier can't tell which it is, fail-safe to "write" and ask, over-confirm beats under-confirm. Validate the proposed action against the real tool schema before the confirm prompt, so you're confirming something that'll actually execute, not a hallucinated payload. And keep the planner on the user's own model/credentials so you're not a custodian of their intents.
```

**Engagement warm-up, récap (FR) :** value-first toujours ; disclosure dès que le produit surgit ; **aucun lien non sollicité** ; rester dans les fils ; ne pas spammer le même message sur plusieurs subs. On gagne le droit de poster le kit de lancement (§B) en étant utile ici d'abord.

---

# SECTION B, KIT COMMUNAUTÉS DE LANCEMENT

> Étalé volontairement après le pic Product Hunt (mar 28 juil, voir `06-launch-kit-28-juillet.md`) pour que chaque canal ait toute l'attention et qu'on ne brûle pas l'audience dans une collision (`launch-strategy.md` §6). **Show HN = mer 29 juil. Reddit = jeu 30 juil.** Lead with the demo, jamais un pitch. Garde-fou Lifetime actif sur toute cette section.

---

### B.1, Show HN · mercredi 29 juillet · 13:00 UTC (09:00 ET / 06:00 PT)

> Fenêtre HN optimale (`launch-strategy.md` §5 : "~8-10am ET / morning PT" ; `social-content.md` : "weekday 13:00-16:00 UTC"). 13:00 UTC = l'intersection des deux. HN punit le hype, récompense la candeur, **rester dans les commentaires les 2 premières heures, répondre à CHAQUE commentaire**, réponses réelles et techniques. Le fondateur est le premier commentaire après le post.
>
> **Mécanique HN :** champ URL du "Show HN" = le lien démo / verba.run ; le texte ci-dessous = le corps du post. (Le même Show HN figure dans le fichier 06, verbatim de la même source, pas de conflit.)

**Title options (HN récompense les titres honnêtes, spécifiques, non-marketing, primary en premier) :**
```
Show HN: Verba, Mac dictation that acts on what you say, using your own Claude
Show HN: A private Mac voice agent that reuses your Claude Code sub (no API key)
Show HN: I turned a Mac dictation app into a confirm-gated voice agent
```

> ⚠️ **Le body ci-dessous contient la ligne lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live le 29 juil, **retirer la phrase "There's a $149 lifetime for anyone who wants it." avant de poster** (le reste du body reste publiable tel quel).

**Show HN body (verbatim `launch-strategy.md` §5) :**
```
Verba is a macOS dictation app I've been building. You press a hotkey, talk, and it restructures your speech into clean text wherever your cursor is. The part I want feedback on: it now acts. Say "create the Linear issue and email the team," and it plans the steps on-device using your own AI (your Claude Code subscription, an Anthropic/OpenRouter key, or local Ollama, never a key of mine), shows you the plan, and executes only after you confirm. 1,000+ connected apps + native Mac actions. Every write is confirm-gated; anything ambiguous is treated as a write and never auto-run.

Honest limitations: it's macOS-only today. It's BYO-AI, so first-run means connecting an AI account (the zero-key Claude Code path is the easy one). Audio stays on your Mac (local history, with an off switch), it's never uploaded.

$9.99/mo, 33-dictation free trial, no card. There's a $149 lifetime for anyone who wants it. I'd genuinely like to hear where the agent breaks and what you'd want to do by voice. Demo: [link]
```

**Engagement (FR) :** remplacer `[link]` par l'URL démo verba.run (avec `?ref`/UTM). Le fondateur poste **immédiatement** un premier commentaire d'ouverture si besoin et reste 2 h+ : répondre à 100 % des commentaires, réponses techniques précises, lead avec la démo, **honnêteté sur les limites** (Mac-only, indie, pas de testimonials publics encore). Demander uniquement de l'engagement genuine, HN/Reddit bannissent la sollicitation de vote. Logger chaque objection → FAQ + contenu.

---

### B.2, Reddit r/macapps · jeudi 30 juillet · 14:00 UTC (10:00 ET / 07:00 PT)

> Lead avec la **démo GIF en premier**, value-first, jamais un pitch (`content-strategy` §6). r/ClaudeAI suit **quelques heures après** (§B.3, stagger). Le corps ci-dessous est **écrit en entier** à partir du brief `launch-strategy.md` §5 (le fichier 06 ne porte que le brief), en réutilisant verbatim les formulations SSOT de `social-content.md` (Angle 3 privacy, Angle 4 BYO-AI, Angle 7 honest comparison, le confirm-gate).

**Type de post :** image/video post, **attacher le cutdown JARVIS** ("say it → confirm → done" : dicter *"create the Linear issue for this bug and email the team a summary"* → le plan apparaît → confirm → les deux actions s'exécutent) comme média principal. Le texte ci-dessous = le corps.

**Title (verbatim `launch-strategy.md` §5) :**
```
I built a private Mac dictation app that can also *act* on what you say (JARVIS-style, but it asks before it does anything)
```

> ⚠️ **Le body ci-dessous contient la ligne lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **supprimer la phrase "Prefer a one-time deal? There's a $149 lifetime if you hate subscriptions." avant de poster.**

**Body :**
```
[Demo GIF is the first thing in the post, the JARVIS cutdown above.]

Hi r/macapps, I'm the founder, so grain of salt, but I've tried to keep this honest.

Verba started as the Mac menu-bar dictation app I wanted: press a hotkey, talk, get clean formatted text pasted exactly where your cursor is. Two things I cared about from day one:

• Private by default, transcription runs on-device; your audio never leaves your Mac, never uploaded. Sync is text-only. Local history has an off switch.
• Bring your own AI, reuse your Claude Code subscription with no API key (or an Anthropic/OpenRouter key, or local Ollama). No second AI markup stacked on top of the subscription you already pay for.

Then it grew a voice agent, JARVIS: say "create the Linear issue and email the team a summary," and it plans the steps, shows you exactly what it'll do, and executes only after you confirm, across 1,000+ connected apps + native Mac actions. The plan is generated on your Mac by your own AI, not a server key of mine. Every write is confirm-gated; anything ambiguous is treated as a write and never auto-run. (That confirm step is in the GIF, it's the whole point.)

Honest about where it loses: it's Mac-only today. If you need Windows or mobile right now, Wispr Flow wins there, and we say so on our own /compare page (24 features × 10 apps, including where rivals beat us): verba.run/compare. No public testimonials yet either, it's early and indie.

Pricing: $9.99/mo or $84/yr, 33-dictation full-Pro trial, no card to start. Prefer a one-time deal? There's a $149 lifetime if you hate subscriptions.

Genuine question: what would you actually want to do by voice on your Mac? The agent's range is the part I most want to pressure-test.
```

**Engagement (FR) :** la **démo GIF d'abord**, jamais le pitch ; disclosure fondateur en clair (déjà dans le corps) ; honnêteté sur Mac-only + absence de testimonials ; finir sur une **question** (pas un mur de CTA) ; un seul lien (`/compare`). Rester 2 h+ dans les commentaires, répondre à chaque question technique, rediriger vers verba.run pour démarrer le trial.

---

### B.3, Reddit r/ClaudeAI · jeudi 30 juillet · 17:00 UTC (13:00 ET / 10:00 PT)

> Posté **3 h après r/macapps** (stagger volontaire). Hook propre à ce sub : **Claude-Code-as-planner** ("the agent you already pay for now runs your Mac by voice"). Corps **écrit en entier** à partir du brief `launch-strategy.md` §5, réutilisant verbatim `social-content.md` Angle 4 (no-key) + Angle 1/6 (plan on-device, confirm) + Angle 2 (no markup).

**Type de post :** image/video post, même cutdown JARVIS en média. Texte ci-dessous = corps.

**Title (verbatim `launch-strategy.md` §5) :**
```
Verba uses your Claude Code subscription to dictate *and* to run actions on your Mac, no API key
```

> ⚠️ **Le body ci-dessous contient la mention lifetime.**
> **[PRÉREQUIS BLOQUANT : créer + tester le SKU Stripe Founder + entitlement in-app + attribution `?ref` AVANT le 28 juil, pas encore live]**, si non-live, **retirer la phrase "There's also a $149 one-time lifetime if you prefer." avant de poster.**

**Body :**
```
[Demo clip first, dictate "create the Linear issue for this bug and email the team a summary" → the plan appears → confirm → both actions execute.]

Founder here, so grain of salt. The bit I think this sub will care about: your Claude Code install becomes the action planner.

If you have Claude Code, Verba reuses that subscription directly, no API key to paste, no separate AI bill. Press a hotkey, talk, and it restructures your speech into clean text wherever your cursor is, using the Claude sub you already pay for. On-device transcription by default, so your audio never leaves the Mac.

Then it goes further: say "create the Linear issue for this bug and email the team a summary," and JARVIS plans the steps on your Mac, with your own Claude, not a server key of mine, shows you exactly what it'll do, and executes only after you confirm. 1,000+ connected apps + native Mac actions. Every write is confirm-gated; anything ambiguous is treated as a write and never auto-run. The agent you already pay for now runs your Mac by voice, on-device.

$9.99/mo or $84/yr, 33-dictation free trial, no card. There's also a $149 one-time lifetime if you prefer. Mac-only today, honest /compare matrix (where rivals beat us included) at verba.run/compare.

What would you want your Claude sub to actually DO by voice? That's the part I most want to hear.
```

**Engagement (FR) :** lead avec le clip + l'angle Claude-Code-as-planner ; emphase sur le **confirm-gate** (rassure l'objection "un agent dans mon Gmail ?") ; disclosure fondateur ; honnêteté Mac-only ; finir sur une question. Rester 2 h+, répondre précisément aux questions techniques (zero-key path, on-device planning, schema-validation). Pour l'objection agent-trust, réutiliser **R4** (§A.5) + les réponses objections du fichier 06 §9.

---

## Cross-références & scope (FR)

- **X / building-in-public thread** (lancement + cadence T-2 "shipping a voice agent, launching in 2 weeks") → **hors de ce fichier** (canal X), couvert dans le livrable X / `06-launch-kit-28-juillet.md` §6. Ne pas dupliquer.
- **Product Hunt, launch email, runbook heure-par-heure** → `06-launch-kit-28-juillet.md`.
- **Ce fichier (02)** = la couche **communautés** : warm-up T-2 (§A, unique à ce fichier) + bodies Reddit complets (§B.2/B.3, le 06 n'a que le brief) + Show HN verbatim (partagé, sans conflit).
- **Garde-fou Lifetime** : appliqué identiquement au fichier 06, chaque occurrence de l'offre Founder est balisée du prérequis bloquant Stripe ; à retirer de la copie tant que le SKU + entitlement + `?ref` ne sont pas live + testés.

## Traceability note (R-CITE)

Tout trace au SSOT. **Verbatim :** les 3 titres Show HN + le body Show HN (`launch-strategy.md` §5, l.250-263) ; les 2 titres Reddit (l.267, l.274). **Écrit à partir du brief §5** (bodies Reddit l.269-277), en réutilisant les formulations SSOT de `social-content.md` : on-device / audio never leaves the Mac / sync text-only / local history off switch (Angle 3, l.69-78) ; reuse your Claude Code subscription with no API key / no markup (Angle 4 + Angle 2, l.90-97, l.49-60) ; honest "/compare lists where rivals beat us" + Wispr cross-platform wins (Angle 7, l.150-161) ; confirm-gated / ambiguous = write / plan on your Mac (Angles 1, 6, 13, l.25, l.126-141, l.264). Le warm-up (§A) et les reply templates dérivent des angles 2/3/4/5/6/13 + de l'étiquette §B de `social-content.md`, et de la directive T-2 de `launch-strategy.md` §4 (l.144-153). Timings : `social-content.md` §Timing + `launch-strategy.md` §5/§6. **Aucune feature inventée ; iOS exclu (scaffoldé, non shippé) ; agent = JARVIS / connected apps (nom interne nulle part) ; aucune démo de write non confirmé ; le tier $149 lifetime balisé "prérequis Stripe à créer/tester" partout où il apparaît.**

--- **Resume :** Fichier communautés écrit dans `marketing/content-juillet-2026/02-social-communautes-reddit-hn-lobsters.md`, (A) warm-up T-2 value-first daté/timé en UTC (r/macapps lun 13, r/ClaudeAI mar 14, Lobsters mer 15, Discord jeu 16, puis reply-sweep ven-dim) avec 4 posts originaux sans pitch + 4 reply templates ; (B) kit de lancement communautés : Show HN (mer 29 juil, titres + body verbatim) et Reddit r/macapps + r/ClaudeAI (jeu 30 juil, titres verbatim + **bodies écrits en entier** depuis le brief). Chaque post : date + canal + heure UTC + titre + body + règles d'engagement (rester 2 h, honnêteté, lead with demo). Garde-fou Lifetime balisé à chaque occurrence ; zéro feature inventée ; JARVIS / connected apps ; iOS exclu. Voisin 06 respecté (R-SCOPE), cross-référencé, non modifié.
