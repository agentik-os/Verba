# Deliverability check, verba.run (real run 2026-07-07)

Skill: `deliverability-check`. Ran live against real DNS (dig). No account needed.

## Findings (real records observed)

| Check | Result | Verdict |
|---|---|---|
| MX (apex verba.run) | none | Apex cannot receive mail. Replies to `@verba.run` bounce. Sending is unaffected. |
| SPF (apex) | none | Expected: apex is not the Return-Path. |
| SPF (send.verba.run) | `v=spf1 include:amazonses.com ~all` | Correct for the Resend send subdomain (Return-Path). |
| DKIM (resend._domainkey.verba.run) | present (RSA public key) | Signing is in place, aligned to the apex From. |
| DMARC (_dmarc.verba.run) | `v=DMARC1; p=none;` | Present but monitoring only, no enforcement. |
| BIMI | none | Optional, not set. |
| MTA-STS | none | Optional, not set. |

## Prioritized fix order

1. **DMARC policy is `p=none`** (highest impact). It only monitors, it does not stop spoofing. Move to enforcement in steps:
   - add reporting: `v=DMARC1; p=none; rua=mailto:dmarc@verba.run;` (collect 1 to 2 weeks of aggregate reports),
   - then `p=quarantine; pct=25` and ramp `pct` to 100,
   - then `p=reject`. Only after confirming SPF+DKIM pass for all legitimate senders (Resend).
2. **No apex MX** (medium). If you want to receive replies at `@verba.run`, add MX records (any inbox provider). Today replies route to `verba.run@agentik-os.com`, so this is optional but worth a decision.
3. **BIMI** (low, brand): once DMARC is at `quarantine`/`reject`, add a BIMI record + VMC to show the Verba logo in inboxes.

## Note
These are DNS records on verba.run, managed at the registrar (dns-parking / Hostinger nameservers), so the changes are made in that DNS panel, not from here.
