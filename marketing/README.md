# Verba, Go-to-Market Package

> **Intégration marketing-machine (2026-07-03) :** Verba est branché sur le moteur multi-marques de
> `/home/vibe/Station/Marketing` via l'adaptateur `projects/verba/` (config, BrandContext condensé, tokens,
> assets validés). CE repo reste le SSOT stratégie/identité/publication ; frontières de sessions et état
> opérateur-validé : `Station/Marketing/projects/verba/HANDOFF-MARKETING-MACHINE.md`. Règle n°1 partout :
> autonomy **L0**, aucun post publié sans GO opérateur.

> **Updated 2026-06-12, integrates the JARVIS/Composio wave.** Verba's category widened from "dictation + AI
> restructuring" to **voice → action**: the JARVIS Action agent executes confirmed actions across **1,000+ connected
> apps** (Gmail, Slack, Linear, GitHub…), with the action plan generated **on-device by the user's own AI**, never a
> server key. All six docs below were revised against the code (commits 5ae8804…ebcdcff: JARVIS + secure relay,
> on-device planner, schema validation + auto-repair, stacked dictations, i18n in 14 languages, rebuilt /compare + SEO/GEO).

The marketing / go-to-market package for **Verba** (verba.run), a macOS menu-bar dictation app that turns rambling
speech into clean, ship-ready text using the AI you already pay for, **and now acts on what you say** (dictate the
intent, confirm, done). Built for a prospective **marketing co-founder** to
understand the play and the path to **€5-15k/mo** in product revenue.

Produced by the OmegaOS marketing suite (R-MARKETING dependency order), **scoped to Verba only**. Every claim is grounded
in the live product and the repo, no invented features.

## Marketing machine, status board (numbered scaffold)
> Réconcilié 2026-06-30 : la **machine marketing numérotée** (`00-context → 04-publishing`) consolide les docs racine riches
> existants (ne les duplique pas) et ajoute la couche visuelle + publishing manquante. Le SSOT reste `../.agents/product-marketing.md`.

| Layer | Fichier | Statut | Note |
|---|---|---|---|
| 00-context | `product-marketing.md` · `market-research.md` · `competitors.md` · `audience-personas.md` | ✅ filled | Miroir consolidé du SSOT + market/concurrents/personas, cités |
| 01-strategy | `gtm-strategy.md` · `content-strategy.md` · `launch-strategy.md` | ✅ filled | Résumés exécutifs renvoyant aux docs racine (GTM/content/launch) |
| 02-copy | `copywriting.md` · `ad-creative.md` · `social-content.md` · `cold-email.md` | ✅ filled | Copy EN publiable (audience Mac/dev) + variantes FR |
| 03-visual-identity | `DA.md` · `higgsfield/system-prompt.md` · `preprompt.md` · `avatar-soul.md` · `shotlist.md` | ✅ filled | DA = transcription de `globals.css` "Black-craft" ; avatar = **non** (scene-led) ; 12 shots |
| 04-publishing | `zernio.md` · `calendar.json` | ✅ filled | Profil `verba` ; **12** stubs ; `scheduledFor: null`, **non connecté, non publié** |

**Docs racine riches (préservés, non clobbérés) :** `EXECUTIVE-SUMMARY.md`, `market-research.md`, `gtm-strategy.md`,
`content-strategy.md`, `launch-strategy.md`, `social-content.md`, `ad-creative.md`, `cold-email.md`,
`partnerships-distribution.md`, `Verba-Marketing-Strategy.pdf`, `content-juillet-2026/`, `fundraising/`.

## Read in this order
1. **[EXECUTIVE-SUMMARY.md](./EXECUTIVE-SUMMARY.md)**, *start here.* One page: the product, the market timing, the wedge,
  the GTM motion, and the subscriber math for €5-15k/mo.
2. **[market-research.md](./market-research.md)**, the real market: category size & heat ($2B incumbent, 17-35% CAGR), the
  9-competitor landscape, the white space Verba owns, ICP & demand signals, and the SOM math. *(skill: `/omg-market-research`)*
3. **[../.agents/product-marketing.md](../.agents/product-marketing.md)**, the positioning **single source of truth**:
  positioning, ICP, personas, differentiation, objections, customer language, brand voice. *Every other doc reads this.*
  *(skill: `/omg-product-marketing-context`)*
4. **[gtm-strategy.md](./gtm-strategy.md)**, the go-to-market strategy: positioning/category, segment sequencing, the three
  channel engines, the funnel & unit economics, pricing moves, growth loops, and the phased roadmap to €5-15k/mo.
  *(skill: `/omg-marketing-strategist`)*
5. **[content-strategy.md](./content-strategy.md)**, the content plan: 4 pillars, topic clusters, buyer-stage keyword map,
  priority-scored topics, and a 90-day editorial calendar mapped to the GTM phases. *(skill: `/omg-content-strategy`)*
6. **[launch-strategy.md](./launch-strategy.md)**, the week-by-week launch: the single narrative, T-4→T+8 timeline, a
  Product Hunt launch (28 Jul 2026) + Show HN + Reddit + X plays, hour-by-hour runbook, the Lifetime/Founder tier as the
  lever, risks. *(skill: `/omg-launch-strategy`)*
7. **[social-content.md](./social-content.md)**, 14 ready-to-post organic angles (X/HN/Reddit/LinkedIn) with full copy,
  a posting cadence, a one-demo→~30-posts repurposing matrix, and a hook swipe bank. *(skill: `/omg-social-content`)*
8. **[ad-creative.md](./ad-creative.md)**, paid creative (after organic proves conversion): 4 angles, Google RSA sets,
  Reddit/X feed ads, /compare + /vs retargeting, negative keywords, the angle-first test plan. *(skill: `/omg-ad-creative`)*
9. **[cold-email.md](./cold-email.md)**, outbound = relationship outreach (B2C, no enterprise prospecting): 5 sequences
  (creators, newsletters, partners/bundles, podcasts, power-users) + seed-license mechanics + anti-spam etiquette. *(skill: `/omg-cold-email`)*
10. **[partnerships-distribution.md](./partnerships-distribution.md)**, Setapp, bundles/lifetime, Mac integrations
  (Raycast, Alfred, indie-Mac media, Claude/Cursor community, MCP), creator/affiliate (Dub), and the App Store question,
  each a pursue/later/avoid verdict with cited sources, a target list, and a 90-day sequence.

**📄 Consolidated deliverable, [Verba-Marketing-Strategy.pdf](./Verba-Marketing-Strategy.pdf)**, the full strategy in
**French**, 14 parts, 45 pages (positioning, ICP/personas, the irresistible offer, channels, content/SEO/GEO, social, paid
+ outbound, pricing, partnerships, growth loops, the week-by-week launch, the 90-day roadmap). Rendered via the OmegaOS
pdfgen `doc` template; verified page-by-page; adversarially verified (2-of-3) against the SSOT.

## The play in three lines
- **Product:** the only Mac dictation app that's **private by default** *and* lets you **bring your own AI (reuse your Claude
 Code subscription, no key)**, and the only one that **acts**: the JARVIS voice agent plans on-device, you confirm, it
 executes across **1,000+ connected apps** (plus vision, hour-long notes, translate, stacked dictations).
- **Market:** a **$2B-validated**, 17-35%-CAGR category, and an empty "voice agent for the desktop" slot next to it;
 beachhead = the fast-growing **Claude Code developer** population (whose own sub is the action planner).
- **Path:** **~600-2,000 paying subscribers** ($9.99/mo, very high margin, BYOK) = €5-15k/mo, a distribution-and-conversion problem,
 not a market-existence one.

## Two quick fixes first
The site now standardises on **"33 dictations"** (matching the app), but the web Try-It demo endpoint (`api/try/route.ts`)
still nudges "10,000 words/month" *(re-verified 2026-06-12, still open)*, and the privacy copy should stay accurate, audio is kept in local history by default (`History.swift`),
so describe it as "never uploaded + off-switch," never "nothing written to disk." Two quick, high-credibility fixes before paid acquisition. *(Details in market-research §6 and gtm-strategy §5.)*

---
*Scope: Verba only, LiquidPad and other Arc 2042 apps are deliberately excluded. Generated 2026-06-11, updated 2026-06-12 (post-JARVIS) by oracle-Verba (OmegaOS).*
