---
project: Verba
produced_by: utm-builder skill (.claude/skills/utm-builder/SKILL.md)
domain: verba.run
status: ready to use
note: No live GA4/Ads data was pulled or invented. This is a tagging convention and example URLs only.
---

# Verba, UTM Parameter Strategy & Tagging Convention

Practical UTM system for verba.run across every channel Verba actually runs: X/Twitter, LinkedIn, Reddit, YouTube, TikTok, Instagram, Product Hunt, email, and paid (Google Ads, Meta Ads). Built to match GA4's default channel grouping so nothing lands in "Unassigned."

## 1. The five parameters, Verba conventions

| Parameter | Required | Rule for Verba |
|---|---|---|
| `utm_source` | Yes | The platform, lowercase, no abbreviations: `x`, `linkedin`, `reddit`, `youtube`, `tiktok`, `instagram`, `producthunt`, `klaviyo` (or whichever ESP), `google`, `facebook` |
| `utm_medium` | Yes | The channel type, must match a GA4 channel-grouping pattern (see section 2): `organic-social`, `paid-social`, `email`, `cpc`, `video`, `referral` |
| `utm_campaign` | Yes | `theme-date` or `theme-quarter`, lowercase, hyphenated: `its-shipped-2026-07`, `launch-producthunt-2026-07` |
| `utm_term` | No | Paid search keyword only: `mac-dictation-app`, `voice-to-text-mac` |
| `utm_content` | No | Creative/post variant or placement: `hook-privacy`, `demo-jarvis`, `carousel-v2`, `bio-link` |

### Naming rules (non-negotiable)
1. Lowercase everything. `X` and `x` are different sources in GA4.
2. Hyphens only as separators. Never a space (becomes `%20`), never an underscore in source/medium/campaign.
3. No em dash or en dash anywhere in a UTM value. Hyphens in compound words only (`paid-social`, `its-shipped`).
4. Be specific, not clever: `paid-social`, not `ps`; `producthunt`, not `ph`.
5. Every campaign name carries a date or launch tag so quarters do not collide: `its-shipped-2026-07`, not `its-shipped`.
6. Never put UTMs on internal links (site nav, in-app links, verba.run linking to verba.run). It resets session attribution and inflates session counts.
7. Never put UTMs on pages you want indexed and ranked organically (blog posts, `/compare`, `/changelog` when reached via SEO). UTMs are for the link you post externally, not the canonical page itself.

## 2. GA4 default channel grouping, how Verba's mediums must map

GA4 assigns every session to a channel group based on `source` + `medium`. If `utm_medium` does not match one of these patterns, the session falls into **Unassigned**, invisible in standard reports.

| Verba channel | `utm_medium` to use | Lands in GA4 channel |
|---|---|---|
| X/Twitter (organic posts) | `organic-social` | Organic Social |
| X/Twitter (paid/promoted) | `paid-social` | Paid Social |
| LinkedIn (organic posts) | `organic-social` | Organic Social |
| LinkedIn Ads | `paid-social` | Paid Social |
| Reddit (u/VerbaRun posts, organic) | `organic-social` | Organic Social |
| Reddit Ads | `paid-social` | Paid Social |
| YouTube (organic video, description links) | `video` | Video |
| YouTube Ads | `paid-social` (or `video` if you want it split out, pick one and stay consistent) | Paid Social or Video |
| TikTok (organic) | `organic-social` | Organic Social |
| TikTok Ads | `paid-social` | Paid Social |
| Instagram (organic feed/reels/stories) | `organic-social` | Organic Social |
| Instagram Ads (Meta) | `paid-social` | Paid Social |
| Product Hunt (launch page, comments, maker profile) | `referral` | Referral |
| Email (newsletter, drip, changelog digest) | `email` | Email |
| Google Ads (Search) | `cpc` | Paid Search |
| Google Ads (Display) | `display` | Display |
| Meta Ads (Facebook/Instagram paid) | `paid-social` | Paid Social |

**Critical for Verba specifically:**
- Product Hunt is `referral`, not `organic-social`. It is not a social network in GA4's rulebook, it is a referring site. Tagging it `organic-social` silently misclassifies the whole launch day.
- Google Ads has auto-tagging (`gclid`). When gclid is present, GA4 ignores UTMs for attribution. Verba still tags Google Ads UTMs for CRM/Zernio/BigQuery cross-checks (see section 5), but do not rely on them as the GA4 source of truth.
- Meta Ads (Facebook/Instagram) does not auto-tag for GA4. Every Meta Ads link needs a manual or dynamic-parameter UTM or it shows up as `facebook.com / referral`, wrong and unattributable.

## 3. Example tagged URLs per channel

Base pages used: `https://verba.run`, `https://verba.run/changelog`, `https://verba.run/compare`. Swap the path for whichever page the post links to; keep the UTM block identical to the pattern shown.

### X/Twitter, organic
```
https://verba.run/?utm_source=x&utm_medium=organic-social&utm_campaign=its-shipped-2026-07&utm_content=hook-privacy
```

### X/Twitter, paid (promoted post)
```
https://verba.run/?utm_source=x&utm_medium=paid-social&utm_campaign=its-shipped-2026-07&utm_content=video-30s-v1
```

### LinkedIn, organic
```
https://verba.run/changelog?utm_source=linkedin&utm_medium=organic-social&utm_campaign=its-shipped-2026-07&utm_content=founder-post
```

### LinkedIn Ads
```
https://verba.run/?utm_source=linkedin&utm_medium=paid-social&utm_campaign=its-shipped-2026-07&utm_content={{CREATIVE_NAME}}
```
LinkedIn macros available: `{{CAMPAIGN_NAME}}`, `{{CAMPAIGN_ID}}`, `{{CREATIVE_NAME}}`, `{{CREATIVE_ID}}`.

### Reddit, organic (u/VerbaRun self-post)
```
https://verba.run/?utm_source=reddit&utm_medium=organic-social&utm_campaign=its-shipped-2026-07&utm_content=self-post-macapps
```

### Reddit Ads
```
https://verba.run/?utm_source=reddit&utm_medium=paid-social&utm_campaign=its-shipped-2026-07&utm_content=promoted-post-v1
```

### YouTube, organic (video description link)
```
https://verba.run/?utm_source=youtube&utm_medium=video&utm_campaign=its-shipped-2026-07&utm_content=demo-jarvis-description
```

### YouTube Ads
```
https://verba.run/?utm_source=youtube&utm_medium=paid-social&utm_campaign=its-shipped-2026-07&utm_content=preroll-15s
```

### TikTok, organic (bio link / link-in-bio tool)
```
https://verba.run/?utm_source=tiktok&utm_medium=organic-social&utm_campaign=its-shipped-2026-07&utm_content=bio-link
```

### TikTok Ads
```
https://verba.run/?utm_source=tiktok&utm_medium=paid-social&utm_campaign=its-shipped-2026-07&utm_content=spark-ad-v2
```

### Instagram, organic (link-in-bio, Stories link sticker)
```
https://verba.run/?utm_source=instagram&utm_medium=organic-social&utm_campaign=its-shipped-2026-07&utm_content=reel-link-sticker
```

### Instagram Ads (via Meta Ads Manager, dynamic parameters)
```
https://verba.run/?utm_source=facebook&utm_medium=paid-social&utm_campaign={{campaign.name}}&utm_content={{ad.name}}&utm_term={{adset.name}}
```
Meta dynamic parameters available: `{{campaign.name}}`, `{{campaign.id}}`, `{{adset.name}}`, `{{adset.id}}`, `{{ad.name}}`, `{{ad.id}}`, `{{placement}}`, `{{site_source_name}}`.

### Product Hunt (launch day, all links: tagline, maker comment, gallery)
```
https://verba.run/?utm_source=producthunt&utm_medium=referral&utm_campaign=launch-producthunt-2026-07&utm_content=launch-page
```

### Email (newsletter or changelog digest)
```
https://verba.run/changelog?utm_source=klaviyo&utm_medium=email&utm_campaign=its-shipped-2026-07&utm_content=digest-cta
```
Replace `klaviyo` with the actual ESP source if different (`mailchimp`, `resend`, `loops`).

### Paid, Google Ads (Search)
```
https://verba.run/compare?utm_source=google&utm_medium=cpc&utm_campaign=search-brand-2026-07&utm_term=mac-dictation-app&utm_content=ad-variant-1
```
Note: Google Ads auto-tagging (`gclid`) takes attribution priority in GA4 over these UTMs. Keep them anyway for CRM and cross-platform dashboards (see section 5).

### Paid, Google Ads (Display)
```
https://verba.run/?utm_source=google&utm_medium=display&utm_campaign=display-retarget-2026-07&utm_content=banner-v1
```

## 4. Verba campaign taxonomy examples

Use `theme-scope-date` for anything beyond the standing "its-shipped" burst:

| Campaign name | Use case |
|---|---|
| `its-shipped-2026-07` | The 12-feature changelog burst campaign, 2 posts/day, all networks |
| `launch-producthunt-2026-07` | Product Hunt launch day specifically |
| `search-brand-2026-07` | Google Ads brand-term search campaign |
| `display-retarget-2026-07` | Google Ads display retargeting |
| `compare-jarvis-2026-08` | Any campaign pointing at `/compare` or `/vs` pages |

## 5. Auto-tagging vs manual tagging, what applies to Verba

- **Google Ads (gclid):** auto-tags every click. If both gclid and UTMs are present, GA4 prioritizes gclid and ignores the UTMs for attribution. Verba should keep "Allow manual tagging to override auto-tagging" unchecked in GA4 unless there is a specific reason to prefer UTMs. Keep UTMs anyway for any CRM or BigQuery cross-check that cannot read gclid.
- **Meta Ads (Instagram/Facebook, fbclid):** GA4 does not parse `fbclid`. Without UTMs, this traffic shows up as `facebook.com / referral` or `l.facebook.com / referral`, unattributed to the actual campaign. UTMs are mandatory on every Meta Ads link.
- **LinkedIn Ads:** the Insight Tag tracks conversions but gives no click-level GA4 attribution. UTMs are mandatory on every LinkedIn Ads link.
- **Reddit, TikTok, YouTube Ads:** same rule as Meta and LinkedIn, no native GA4 parsing, UTMs are mandatory.
- **Product Hunt:** no ad platform involved, it is organic referral traffic, but it still needs UTMs or it will show as generic `producthunt.com / referral` without a campaign name to filter launch-day traffic by.

## 6. Common mistakes to avoid on Verba

1. **Inconsistent casing across networks.** `X` one day, `x` the next, creates two separate sources in GA4. Pick lowercase and never deviate.
2. **Tagging Product Hunt as `organic-social`.** It is `referral`. Getting this wrong misclassifies the entire launch day.
3. **UTMs on internal links.** Never add a UTM to a link inside verba.run pointing to another verba.run page (for example, a changelog post linking to `/pricing`). It resets the session's source and inflates session counts.
4. **Missing `utm_medium`.** A link with only `utm_source=reddit&utm_campaign=its-shipped-2026-07` falls into Unassigned. Always include the medium.
5. **Spaces or special characters in campaign names.** `utm_campaign=Its Shipped` becomes `Its%20Shipped` in the URL and reads as a broken value in reports. Use `its-shipped-2026-07`.
6. **UTMs on pages meant to rank organically.** Do not tag the canonical `/compare` or `/changelog` URL itself if it is the page you want Google to index; only tag the copy of the link you post externally.
7. **No date in the campaign name.** `utm_campaign=its-shipped` cannot be told apart from a future repeat of the same campaign next quarter. Always suffix with `-2026-07` or similar.
8. **Assuming Google Ads UTMs drive GA4 attribution.** They do not when gclid is present. Do not "debug" a Google Ads UTM mismatch in GA4, check gclid-based attribution instead.

## 7. Quick build formula (spreadsheet)

For a shared tagging sheet (columns: A = base URL, B = source, C = medium, D = campaign, E = term, F = content):
```
=A2&"?utm_source="&B2&"&utm_medium="&C2&"&utm_campaign="&D2&IF(E2<>"","&utm_term="&E2,"")&IF(F2<>"","&utm_content="&F2,"")
```

## 8. What this document does not do

No GA4 property or Google Ads account was queried for this deliverable. There is no live traffic-source data, no BigQuery validation run, and no existing UTM audit performed here. If Verba later connects GA4/BigQuery, the validation queries from the skill reference (unique source/medium combinations, inconsistent-naming finder, channel-grouping predictor, internal-UTM-pollution finder, missing-medium finder) are the next step to audit real, already-collected traffic against this convention.
