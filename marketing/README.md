# Verba — Go-to-Market Package

The marketing / go-to-market package for **Verba** (verba.run) — a macOS menu-bar dictation app that turns rambling
speech into clean, ship-ready text using the AI you already pay for. Built for a prospective **marketing co-founder** to
understand the play and the path to **€5–15k/mo** in product revenue.

Produced by the OmegaOS marketing suite (R-MARKETING dependency order), **scoped to Verba only**. Every claim is grounded
in the live product and the repo — no invented features.

## Read in this order
1. **[EXECUTIVE-SUMMARY.md](./EXECUTIVE-SUMMARY.md)** — *start here.* One page: the product, the market timing, the wedge,
   the GTM motion, and the subscriber math for €5–15k/mo.
2. **[market-research.md](./market-research.md)** — the real market: category size & heat ($2B incumbent, 17–35% CAGR), the
   9-competitor landscape, the white space Verba owns, ICP & demand signals, and the SOM math. *(skill: `/omg-market-research`)*
3. **[../.agents/product-marketing.md](../.agents/product-marketing.md)** — the positioning **single source of truth**:
   positioning, ICP, personas, differentiation, objections, customer language, brand voice. *Every other doc reads this.*
   *(skill: `/omg-product-marketing-context`)*
4. **[gtm-strategy.md](./gtm-strategy.md)** — the go-to-market strategy: positioning/category, segment sequencing, the three
   channel engines, the funnel & unit economics, pricing moves, growth loops, and the phased roadmap to €5–15k/mo.
   *(skill: `/omg-marketing-strategist`)*
5. **[content-strategy.md](./content-strategy.md)** — the content plan: 4 pillars, topic clusters, buyer-stage keyword map,
   priority-scored topics, and a 90-day editorial calendar mapped to the GTM phases. *(skill: `/omg-content-strategy`)*

## The play in three lines
- **Product:** the only Mac dictation app that's **private by default** *and* lets you **bring your own AI (reuse your Claude
  Code subscription, no key)** — and does more than transcribe (vision, hour-long notes, translate, agentic actions).
- **Market:** a **$2B-validated**, 17–35%-CAGR category; beachhead = the fast-growing **Claude Code developer** population.
- **Path:** **~600–2,000 paying subscribers** ($9.99/mo, very high margin — BYOK) = €5–15k/mo — a distribution-and-conversion problem,
  not a market-existence one.

## Two quick fixes first
The site now standardises on **"33 dictations"** (matching the app), but the web Try-It demo endpoint (`api/try/route.ts`)
still nudges "10,000 words/month," and the privacy copy should stay accurate — audio is kept in local history by default (`History.swift`),
so describe it as "never uploaded + off-switch," never "nothing written to disk." Two quick, high-credibility fixes before paid acquisition. *(Details in market-research §6 and gtm-strategy §5.)*

---
*Scope: Verba only — LiquidPad and other Arc 2042 apps are deliberately excluded. Generated 2026-06-11 by oracle-Verba (OmegaOS).*
