# Verba Marketing HQ (source)

Self-contained multi-page marketing dashboard, deployed to Vercel (agentik-os account).

- Live: https://verba-hq.vercel.app  (soft gate passphrase `verba2026`)
- `index.html` = the bilingual EN/FR command dashboard (hub).
- `strategy/ marketing-os/ calendar/ playbook/ reddit/ plan/ content/` = deep-dive pages, linked from the hub's Library tab and served at `/strategy`, `/calendar`, etc.

All pages share one top bar (`Verba. Marketing HQ` + `Back to hub`) and the same design tokens. Confidential tech (in/out models) is never named in any page (see marketing/06-branding/prompt-library/kill-list.md, section R-SECRET-TECH).

Deploy: `vercel deploy --prod --yes --scope <agentik-os team> --token=$VERCEL_TOKEN` from this folder.
