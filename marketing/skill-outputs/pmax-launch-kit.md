---
project: Verba
skill: pmax-launch-kit (/pmax-launch-kit)
source: https://verba.run (WebFetch + Playwright site snapshot), .agents/product-marketing.md (SSOT), marketing/00-context/audience-personas.md, marketing/06-branding/prompt-library/kill-list.md
status: build kit, ready to paste into Google Ads
note: pricing and stats below are sourced from the live site and SSOT (9.99 USD/mo, 84 USD/yr, 150 wpm speaking vs 40 wpm typing, 1,000+ connected apps, 15 translate targets). Anything not sourced is marked [to confirm]. No underlying-tech names, no "cloud", no BYO-AI mechanic anywhere below, per standing hard rules.
---

# Performance Max Launch Kit, Verba

## Campaign settings

- **Conversion goal:** primary = app download (DMG click, `https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg`). This is the highest-volume real action available today. Secondary, once pixel volume allows: Pro subscription start (9.99 USD/mo or 84 USD/yr). Recommendation: run campaign-specific goals scoped to Download first (account-default would blend in unrelated conversions from other campaigns); add the subscription event as a secondary (observation-only) goal once it has enough volume to bid on, then consider switching primary optimization to it since it is closer to revenue.
- **Bidding:** start on Maximize Conversions with no target CPA (per Performance Max best practice, a target throttles the algorithm before it has data). Once 30+ conversions a month are consistent, layer in Maximize Conversion Value with values assigned per action (Download = low value, trial start = mid value, paid subscribe = full 9.99 USD/mo or 84 USD/yr value) so PMax learns to chase the subscription, not just the download.
- **Budget:** target CPA is not established yet [to confirm once 2-4 weeks of data exist]. Rule of thumb: daily budget at least 10-15x the eventual target CPA so the campaign can exit the learning phase inside a normal cycle. Until a target CPA is set, start with a daily budget that can absorb at least 10-15 conversions a week; if that number is not yet known for Verba, start modestly and scale on signal rather than guessing a number.
- **New customer acquisition:** Verba has no repeat-purchase or account-overlap conflict today (self-serve, single seat, no enterprise procurement), so this setting matters less than on ecommerce. If Google Ads exposes it once the subscription conversion is wired up, prefer "bid higher for new customers" over "new customers only", the latter would exclude return visitors converting on a later session, a normal SaaS trial pattern.
- **Final URL expansion:** ON, with exclusions. Exclude `/docs`, `/changelog`, and `/compare` informational pages from expansion so PMax keeps sending clicks to `/` and the download action instead of drifting to thin content pages that will not convert.
- **Brand exclusions:** add a brand exclusion list at the account level with `verba`, `verba.run`, and close misspellings, so PMax does not spend on branded search Verba already wins organically for free. Do not target competitor brand names either, PMax runs on search themes, not keywords, and bidding on a competitor's trademark is a separate risk best handled deliberately in Search, not left to PMax auto-discovery.
- **Starter negative keyword list (account level):** windows, android, ios app, siri shortcut, alexa skill, google assistant app, dragon naturallyspeaking, dragon medical, otter ai, meeting transcription service, text to speech, voice changer, voice actor jobs, free crack, torrent.

---

## Asset Group 1, Private Mac Dictation

Targets the established shelf (dictation / voice-to-text for Mac). Covers the privacy-first pro, the multilingual knowledge worker, and the long-form thinker.

### Headlines (15, limit 30 characters)

| # | Headline | Chars |
|---|---|---|
| 1 | Speak It. Send It Clean. | 24 |
| 2 | Private Dictation for Mac | 25 |
| 3 | Your Voice Never Leaves Mac | 27 |
| 4 | On-Device Voice to Text | 23 |
| 5 | Free Forever, Unlimited | 23 |
| 6 | No Card. No Catch. Free. | 24 |
| 7 | Private AI. Zero Upload. | 24 |
| 8 | Dictation That Actually Works | 29 |
| 9 | 6 Modes. One Key. Done. | 23 |
| 10 | Translate As You Speak | 22 |
| 11 | Hour-Long Voice Notes | 21 |
| 12 | The Mac Dictation App | 21 |
| 13 | Reads Your Screen, Too | 22 |
| 14 | Download Verba Free | 19 |
| 15 | Built for Apple Silicon | 23 |

### Long headlines (5, limit 90 characters)

| # | Long headline | Chars |
|---|---|---|
| 1 | Verba dictates clean text on your Mac using private AI that never leaves your device. | 85 |
| 2 | Free forever for unlimited raw dictation, no card required, Pro unlocks every AI mode. | 87 |
| 3 | Six modes route each dictation to the right model: Polish, Intent, Coding, and more. | 85 |
| 4 | Speak an hour of rambling thought and get back a clean, structured document. | 76 |
| 5 | Speak your language, send theirs. Live translation across fifteen target languages. | 83 |

### Descriptions (1 short + 4 standard)

| # | Type | Description | Chars |
|---|---|---|---|
| 1 | Short (limit 60) | Private dictation for Mac. Free forever, no card. | 50 |
| 2 | Standard (limit 90) | Download free for unlimited raw dictation. Upgrade to Pro for every AI mode. | 76 |
| 3 | Standard (limit 90) | You speak about 150 words a minute. You type about 40. Use your voice. | 70 |
| 4 | Standard (limit 90) | On-device voice AI cleans up your words and reads what is on your screen. | 73 |
| 5 | Standard (limit 90) | Works inside Slack, Mail, Notion, VS Code, Terminal, and every app you use. | 75 |

**Business name:** Verba (5 chars)

**Calls to action:** Download, Get started free, Try Verba

### Search themes (25, no brand terms)

1. mac dictation app
2. voice to text mac
3. speech to text macos
4. private dictation app
5. on device dictation mac
6. offline dictation software
7. dictation app for developers
8. voice typing for mac
9. hands free typing mac
10. ai dictation cleanup tool
11. voice to text for coding
12. best mac dictation app 2026 *(informational, may pull comparison-shopper junk, monitor)*
13. dictation app that reads screen
14. long voice notes to text
15. voice memo transcription app
16. multilingual dictation app
17. live voice translation app
18. wispr flow alternative
19. superwhisper alternative
20. macwhisper alternative
21. private voice to text no upload
22. dictation app no subscription lock in *(broad phrasing, risk of junk, monitor)*
23. voice typing for writers
24. speak instead of type mac
25. mac menu bar dictation tool

### Audience signal

**Your data (best signal):** website visitors of `/compare`, `/best-mac-dictation-app`, and `/features/*` pages; a similar-audience seed built off the DMG download click once it has enough volume.
**Custom segment:** people who searched "Wispr Flow", "Superwhisper", "MacWhisper", "dictation app mac", "voice to text mac"; and people who recently visited wisprflow.ai, superwhisper.com, macwhisper.com.
**Interests and demographics (fallback only):** in-market for "Business Productivity Software"; affinity "Technology Early Adopters".

### Image shot list

- **Landscape (1.91:1):** Mac screen, crisp UI screenshot of the dictation panel mid-recording (waveform + "Listening" state), desk softly out of focus behind it, one warm accent highlight, natural window light.
- **Square (1:1):** tight crop on the mode switcher (Context, Coding, Intent pills) with the active pill highlighted, crisp UI, dark panel.
- **Portrait (4:5):** candid over-the-shoulder shot near a MacBook in a home office, hands resting near the keyboard not typing, natural uneven light, faint grain on the environment only (the UI stays sharp).
- **Landscape (1.91:1):** before/after split, left = a messy raw transcript, right = the same text cleaned and formatted, crisp UI comparison, no blur on either side.
- **Square (1:1):** the Verba menu-bar icon zoomed into a real macOS menu bar, everyday desktop context.
- **Portrait (4:5):** a translate-mode screenshot showing spoken language on one side and the sent language on the other, crisp UI, one accent color max.
- **Landscape (1.91:1):** the six-mode grid (Raw, Polish, Intent, Coding, Translate, Context) as a clean UI panel, dark background, hairline borders.
- **Logos:** 1:1 mic-mark icon on dark background; 4:1 wordmark lockup ("Verba" plus the mic glyph) on transparent or dark background.

### Video script outline (10s+ vertical)

- **Hook (0-2s):** cursor idle in an email draft, a caption types out a rambling spoken line ("reply and say we'll have it Friday"), mic waveform animates.
- **Value (2-6s):** cut to the same words appearing clean in the email body, the active mode badge visible, a calm push-in on the panel.
- **Proof (6-9s):** the word count ticks from raw to polished, screen briefly shows "6 modes, one key".
- **CTA (9-12s):** cut to the Download button on the real site, end card "Verba. Speak it. Send it clean." with the URL.

---

## Asset Group 2, JARVIS Voice Agent

Targets the emerging shelf (a voice agent that acts, not just transcribes). Covers the vibe-coder beachhead and the voice-first operator persona that JARVIS opens.

### Headlines (15, limit 30 characters)

| # | Headline | Chars |
|---|---|---|
| 1 | Speak It. JARVIS Does It. | 25 |
| 2 | Meet JARVIS for Mac | 19 |
| 3 | A Voice Agent That Asks First | 29 |
| 4 | Nothing Happens Without You | 27 |
| 5 | Acts on 1,000+ Connected Apps | 29 |
| 6 | Say It Once. It's Done. | 23 |
| 7 | Confirm Before It Acts | 22 |
| 8 | JARVIS Plans On Your Mac | 24 |
| 9 | Email, Slack, Linear, By Voice | 30 |
| 10 | Your Voice Now Takes Action | 27 |
| 11 | One Key. Every Connected App | 28 |
| 12 | Clear Your Inbox by Voice | 25 |
| 13 | Ask JARVIS. It Shows You First | 30 |
| 14 | Free to Download Today | 22 |
| 15 | Runs Right On Your Mac | 22 |

### Long headlines (5, limit 90 characters)

| # | Long headline | Chars |
|---|---|---|
| 1 | JARVIS plans your intent, shows you the steps, and waits for your confirm. | 74 |
| 2 | Say what you want done and JARVIS acts across Slack, Mail, Notion, and Linear. | 78 |
| 3 | It never writes, sends, or acts on anything until you tap confirm. | 66 |
| 4 | Connect over 1,000 apps in one tap and let JARVIS handle the busywork. | 71 |
| 5 | JARVIS asks a quick question when something is missing or unclear, then acts. | 77 |

### Descriptions (1 short + 4 standard)

| # | Type | Description | Chars |
|---|---|---|---|
| 1 | Short (limit 60) | JARVIS acts on your Mac, only after you confirm. | 48 |
| 2 | Standard (limit 90) | Download Verba free and connect JARVIS to Gmail, Slack, Linear, and more. | 73 |
| 3 | Standard (limit 90) | Built on a fail-safe design: reads are automatic, every write needs your confirm. | 81 |
| 4 | Standard (limit 90) | One sentence becomes a plan, a preview, and an action you approve. | 66 |
| 5 | Standard (limit 90) | From a rambling voice memo to a sent email in one confirm. | 58 |

**Business name:** Verba (5 chars)

**Calls to action:** Get started free, Try JARVIS, Download

### Search themes (25, no brand terms)

1. voice assistant that takes action
2. ai voice agent for mac
3. voice control mac apps
4. hands free email by voice
5. voice agent for gmail and slack
6. jarvis for mac
7. voice command mac automation
8. speak to send email mac
9. voice to task manager app
10. ai agent connects to my apps *(broad, some enterprise-intent junk risk, monitor)*
11. natural language voice automation
12. voice assistant for founders
13. mac productivity voice agent
14. control notion by voice
15. voice controlled task automation
16. ai personal assistant mac app *(broad, may pull Siri-intent junk, monitor)*
17. speak and it gets done app
18. voice agent with human confirmation
19. automate slack messages by voice
20. connect apps with voice commands
21. voice driven workflow automation mac
22. dictate and execute tasks mac
23. ai that acts on your behalf mac
24. voice to action productivity app
25. mac voice agent for founders

### Audience signal

**Your data (best signal):** visitors of `/features/jarvis-voice-agent` and `/changelog`; a similar-audience seed built off the DMG download click, filtered to sessions that viewed the JARVIS page.
**Custom segment:** people who searched "AI agent for my apps", "voice automation", "connect apps with AI"; visitors of workflow-automation sites and Product Hunt.
**Interests and demographics (fallback only):** in-market for "Business & Productivity Software"; affinity "Technology Enthusiasts / Early Adopters".

### Image shot list

- **Landscape (1.91:1):** crisp UI screenshot of the JARVIS action card mid-flow ("Email the team I'm running late", with Cancel and Confirm buttons visible), dark panel, one accent color on the Confirm button only.
- **Square (1:1):** tight crop on just the Confirm button and the app icon it will act on (for example Gmail), crisp, no blur.
- **Portrait (4:5):** the connected-apps grid (Slack, Gmail, Notion, Linear, Calendar icons around a central mic glyph), clean flat icon style matching the site.
- **Landscape (1.91:1):** before/after: left = a spoken caption ("create the issue, email the team"), right = the resulting confirm card with the two concrete actions listed.
- **Square (1:1):** the JARVIS listening state (pulsing rec dot, waveform) as a standalone crisp UI crop.
- **Portrait (4:5):** candid, environment-only shot (no posed stock person) of a MacBook open on a desk with the JARVIS panel faintly visible on screen, natural uneven light, grain on the desk and hands only, screen stays sharp.
- **Landscape (1.91:1):** a wide shot of the connected-app logo marquee from the site (Slack, Gmail, Notion, Linear, GitHub, Figma, and more) around the mic mark.
- **Logos:** 1:1 mic-mark icon on dark background; 4:1 wordmark lockup ("Verba" plus the mic glyph) on transparent or dark background.

### Video script outline (10s+ vertical)

- **Hook (0-2s):** a spoken caption appears over a still Mac screen: "reply and say we'll have it Friday, ask if they need a call."
- **Value (2-6s):** cut to the JARVIS confirm card sliding in, showing exactly what it will do and where.
- **Proof (6-9s):** cursor taps Confirm, a subtle checkmark appears, the target app icon (Gmail) lights up for a beat.
- **CTA (9-12s):** end card "Speak it. JARVIS does it." with the Download URL.

---

## What to do next (3 steps)

1. **Set up conversion tracking first.** Confirm the Download click and, if available, the Pro subscription start are both firing as conversions in Google Ads before spending a dollar, PMax cannot learn without a clean signal.
2. **Build the two asset groups above** in a single Performance Max campaign, paste the headlines, long headlines, and descriptions in as written (they are already inside every character limit), add the images and at least one 10s+ video from the shot lists, do not let Google auto-generate the video.
3. **Launch on Maximize Conversions with no target CPA, add the brand exclusion list, and let it run 2-4 weeks** before touching bids or adding a target CPA, PMax needs that window to leave the learning phase.
