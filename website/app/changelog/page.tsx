import Link from "next/link";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import ThemeToggle from "@/components/ThemeToggle";

import SiteFooter from "@/components/SiteFooter";
export const metadata: Metadata = {
  title: "Changelog, Verba AI Dictation for Mac",
  description:
    "Every Verba release since launch on June 5, 2026. Shipped in public, fast: 60+ releases in the first days, with dates and times.",
  alternates: { canonical: "/changelog" },
};

type Entry = { version?: string; time?: string; title: string; items: string[] };
type Day = { date: string; tag?: string; window?: string; summary: string; entries: Entry[] };

const DAYS: Day[] = [
  {
    date: "July 4, 2026",
    tag: "Today",
    summary: "A cleaner Features page and setup, clearer engine choices, and JARVIS reliable on any engine.",
    entries: [
      {
        version: "0.9.70",
        title: "Every AI feature works on every engine",
        items: [
          "Improve on feedback, and Context mode, no longer error when you run a local model. If your engine can't read a screenshot, Verba automatically works from your words instead of failing. We audited every AI feature so whatever engine you pick, it just works.",
        ],
      },
      {
        version: "0.9.69",
        title: "Latest cloud models available",
        items: [
          "When you use the cloud AI path (your Claude subscription or your own key), you can now pick the newest models, including Sonnet 5 and Opus 4.8. Fully local stays the private default.",
        ],
      },
      {
        version: "0.9.68",
        title: "Feedback fixes from you",
        items: [
          "Onboarding now says the right number of permissions, and the shortcut picker tells you exactly which key combos are valid and confirms your choice.",
          "The Feedback panel has a clear Take screenshot button plus a separate Add file button, and Context mode no longer names a specific AI when you use a different one.",
        ],
      },
      {
        version: "0.9.67",
        title: "Fix: no more duplicate widget",
        items: [
          "Dictation and JARVIS results showed in the centered widget AND cloned a second copy in the bottom-right. Removed the duplicate: the centered widget is the single source of truth. The bottom-right toast is now only for to-dos and notes captured in the background while you do something else.",
        ],
      },
      {
        version: "0.9.66",
        title: "Your local AI installs itself, with a progress bar",
        items: [
          "First run on Fully local now downloads both on-device models (speech + AI) automatically, with a visible progress bar during onboarding — so your first prompt, mode or JARVIS command just works, no manual setup. If you try before it\u2019s ready, you see a friendly \u201csetting up\u2026 NN%\u201d instead of an error. Raw dictation works instantly regardless.",
        ],
      },
      {
        version: "0.9.65",
        title: "See every background task, and results land where you started",
        items: [
          "Run things in parallel and watch them: a to-do being added, a note transcribing, a JARVIS action, all show as little live chips that tick green when done.",
          "Each dictation now delivers back to the app and field where you started it, so two dictations aimed at two different windows each land in the right place.",
        ],
      },
      {
        version: "0.9.64",
        title: "Full-screen to-do reminders",
        items: [
          "When a to-do reminder fires, Verba can now take over the whole screen with a large card showing what to do, a Mark-done button, and a Dismiss. It auto-closes after a few seconds, or stays until you close it manually. Configure it in Settings.",
        ],
      },
      {
        version: "0.9.63",
        title: "Everyone on the newer local model, auto-installed",
        items: [
          "Fresh installs auto-download the local transcription engine (Parakeet) and the local AI model (qwen3) during onboarding, no manual step. Anyone still on the older model is moved to qwen3 automatically, even across synced Macs.",
        ],
      },
      {
        version: "0.9.62",
        title: "Learn the shortcuts as you browse",
        items: [
          "Every tool and library page now shows its keyboard shortcuts at the bottom, with a one-tap button to change them in Settings. Discover and rebind shortcuts without hunting for them.",
        ],
      },
      {
        version: "0.9.61",
        title: "No more accidental mode picker, and bigger movable widgets",
        items: [
          "Holding Control+Option no longer pops the mode picker (it clashed with the new Control+Option X/Z/C widget shortcuts). Mode switching stays on Fn+Tab and Fn+1-9.",
          "The Actions and To-do widgets are now bigger and taller by default, the same size as each other, and you can drag them anywhere on screen.",
        ],
      },
      {
        version: "0.9.60",
        title: "JARVIS acts noticeably faster",
        items: [
          "The local model now stays warm in memory and JARVIS bounds its output and runs its lookups in parallel, so actions fire without the cold-start wait (a repeat call dropped from ~5s to ~0.2s on the model side).",
        ],
      },
      {
        version: "0.9.59",
        title: "Global widget shortcuts + faster, more reliable JARVIS",
        items: [
          "The Actions and To-do widgets no longer vanish when you click elsewhere, and you can open all three from anywhere: \u2303\u2325X Actions, \u2303\u2325Z To-dos, \u2303\u2325C Notes.",
          "Removed the confusing extra mode-picker shortcut (mode switching stays on Fn+Tab and Fn+1-9).",
          "JARVIS is faster and more reliable on the local model: it trims bulky app data before reasoning, so asks like \u201cwhat\u2019s my next event?\u201d work smoothly on-device.",
        ],
      },
      {
        version: "0.9.58",
        title: "Fully local by default, now on qwen3",
        items: [
          "Verba now runs fully offline on your Mac by default (Ollama), on the newer qwen3 model, and every AI feature — including JARVIS, transforms and tools — works on-device with nothing leaving your Mac.",
        ],
      },
      {
        version: "0.9.57",
        title: "Styles settings, redesigned",
        items: [
          "The Styles section in Settings now uses the same clean, single-column card layout as every other section, with an inline editor, instead of a cramped two-pane view.",
        ],
      },
      {
        version: "0.9.56",
        title: "Fix: number keys stopped working while Verba was open",
        items: [
          "Fixed a bad bug where the mode picker could stay armed after it closed, so Verba kept swallowing your number-key presses system-wide. Numbers type normally again.",
        ],
      },
      {
        version: "0.9.55",
        title: "Connecting an app never fails silently",
        items: [
          "Fixed the Connect button doing nothing for apps you'd already connected, and it now shows a clear message when an app can't be connected yet (a few, like X and Telegram, need their own credentials Composio doesn't provide).",
        ],
      },
      {
        version: "0.9.54",
        title: "Tidier settings",
        items: [
          "Your OpenAI transcription key now lives in Dictation, with the engine that uses it, and AI rewriting shows only the one key your chosen backend needs. Cleaner, less confusing.",
        ],
      },
      {
        version: "0.9.53",
        title: "Raw dictation is free forever",
        items: [
          "Raw dictation is now free forever and unlimited, no card, no trial clock. Press Fn and talk, as much as you want, for as long as you want.",
          "The Dictionary now has a clear Add button next to the word field, so you can add words with the mouse, not just the Enter key.",
          "Verba Pro ($9.99/mo) unlocks everything else: every AI mode (Polish, Translate, Prompt, Intent, Context), plus Notes, Tasks, JARVIS, custom modes and editable prompts.",
        ],
      },
      {
        version: "0.9.52",
        title: "Your AI engine, respected everywhere",
        items: [
          "Fully local now means fully local: Context mode no longer quietly used hosted Claude when you were signed in, it stays on your chosen engine (local models just can't read screenshots, so it says so).",
          "My API key now lets you pick the provider, OpenAI, Anthropic or OpenRouter, paste that key and choose a model. JARVIS and every mode use exactly the provider you picked.",
          "Your engine, model and provider choice now sync across your Macs (your API keys stay only in each Mac's Keychain).",
        ],
      },
      {
        version: "0.9.51",
        title: "Turn modes on and off, and group them",
        items: [
          "Each mode now has an on/off toggle in Modes, so if you keep dozens you can enable just the ones a workflow needs. Disabled modes are hidden from the picker but never deleted (Raw always stays).",
          "New mode groups: save your enabled modes as a group (Developer, Copywriting…) and activate the whole set in one tap.",
        ],
      },
      {
        version: "0.9.50",
        title: "Update button, feature shortcuts, and two fixes",
        items: [
          "The in-app 'New version available' button now actually opens the updater (it was opening behind the app on this menu-bar app).",
          "Open a feature on the Features page to see and change its keyboard shortcut(s), some features have more than one.",
          "JARVIS now shows your full spoken request without cutting it off, and the wishlist upvote button works (it was racing ahead of device registration).",
        ],
      },
      {
        version: "0.9.49",
        title: "A more polished Features page and setup",
        items: [
          "The Features page now uses clean Activate pills instead of system switches, marks your always-on Essentials, and each feature opens a bigger detail card. Setup now explains each AI engine, including exactly how the Claude option connects.",
          "We'll walk you through the refreshed setup once more so everyone sees the new experience. Your setup, shortcuts and data are unchanged.",
        ],
      },
      {
        version: "0.9.48",
        title: "JARVIS self-corrects, even on smaller models",
        items: [
          "JARVIS now reshapes a slightly-off plan from a smaller local model into a valid one instead of failing, so a composed request (send an email AND add a calendar event) runs its multiple actions reliably whatever engine you picked.",
        ],
      },
      {
        version: "0.9.47",
        title: "JARVIS runs on your engine, reliably",
        items: [
          "JARVIS plans on the exact engine you selected, your local model, your Claude plan, or your key, and now waits long enough for a local model to think (they run entirely on your Mac, so they're slower).",
          "Fixed the 'took too long' error: the connected-app reads on our relay had no time budget and were cut short. They now get the time they need.",
        ],
      },
    ],
  },
  {
    date: "July 3, 2026",
    summary: "Meet the new Verba: a Features page, a calmer first run, gentle discovery, and one model everywhere. Verba now grows with you.",
    entries: [
      {
        version: "0.9.46",
        title: "Fully local, ready out of the box",
        items: [
          "Fully local now installs its reprompting model automatically too, not just the engine, so on-device Polish, Translate and Prompt work with no manual setup. Raw dictation is instant regardless.",
        ],
      },
      {
        version: "0.9.45",
        title: "Local-first: open-source models by default",
        items: [
          "The setup now recommends Fully local first: open-source models run on your Mac and nothing ever leaves the device. Verba installs them for you, the on-device transcription model and the local reprompting engine.",
          "Clearer AI options: the API-key card is gone, and My Claude subscription now says to install the Claude CLI and run it once in Terminal to sign in.",
          "Sidebar groups (Tools, Library, Community) start collapsed, and you can join the Telegram community right from the end of setup. Fixed a hard-to-read success message.",
        ],
      },
      {
        version: "0.9.44",
        title: "Styles now in Settings",
        items: [
          "Your tone and format Styles are now a section in Settings, alongside everything else you tune.",
        ],
      },
      {
        version: "0.9.43",
        title: "A quick tour of what's new",
        items: [
          "We'll walk you through the refreshed 3-screen setup and the new Features page once, so you can see what changed. Your setup, shortcuts and data are all exactly as you left them.",
        ],
      },
      {
        version: "0.9.42",
        title: "See what a feature does before you turn it on",
        items: [
          "Tap any card on the Features page to open its detail: what it does, what it needs (a permission, a connection), and one button to turn it on or off.",
        ],
      },
      {
        version: "0.9.41",
        title: "One model, everywhere",
        items: [
          "Every mode now uses the single AI model you choose in Settings ▸ AI rewriting. No more per-mode model to manage, pick it once and it applies to Polish, Translate, Prompt, all of them.",
        ],
      },
      {
        version: "0.9.40",
        title: "Discover more, at your pace",
        items: [
          "As you use Verba, it can gently suggest a feature you haven't turned on yet, at most one a day, and always dismissable for good. No tours, no nagging.",
          "New Power User badge for turning on a feature from both Advanced and Power.",
        ],
      },
      {
        version: "0.9.39",
        title: "A calmer first run",
        items: [
          "New Macs now get a 3-screen setup, permissions, your AI engine, and a first live dictation, instead of a long tour. Sign-in is optional and no longer blocks you.",
          "A shortcut for a feature you haven't turned on stays inert, so nothing fires by accident. Your existing setup is unchanged.",
        ],
      },
      {
        version: "0.9.38",
        title: "Features: turn on Verba one power at a time",
        items: [
          "New Features page in the sidebar: see everything Verba can do, grouped as Essentials, Advanced and Power, and switch each capability on or off in one click.",
          "New Macs start with the four essentials (Raw, Polish, Translate, Prompt) and grow from there. Your existing setup is completely untouched, everything you had stays on.",
          "Turning a feature off only hides it, it never deletes your notes, tasks or history. In a hurry? One Enable everything button turns it all on.",
        ],
      },
    ],
  },
  {
    date: "July 2, 2026",
    summary: "Our community moves to Telegram.",
    entries: [
      {
        version: "0.9.37",
        title: "Community is now on Telegram",
        items: [
          "We've moved the community to Telegram. The Community link in the sidebar now opens our Telegram channel, t.me/verbarun. Come say hi.",
        ],
      },
    ],
  },
  {
    date: "July 1, 2026",
    summary:
      "Verba never loses your last word: it keeps listening for a brief silent moment after you stop, so the final word of your sentence is always caught.",
    entries: [
      {
        version: "0.9.36",
        title: "Never lose your last word",
        items: [
          "Verba now keeps the mic open for a brief, silent moment after you stop, so the last word of your sentence is always captured, even when you release the trigger a beat early. No more cut-off or wrong final words.",
        ],
      },
    ],
  },
  {
    date: "June 30, 2026",
    summary:
      "Coding and Prompt merge into one Prompt mode, Connected apps move into the sidebar, the Automatic engine now self-heals, you can pick your Translate language on the fly, and you can rename your imported transcripts.",
    entries: [
      {
        version: "0.9.35",
        title: "Coding and Prompt are now one mode: Prompt",
        items: [
          "Coding and Prompt did the same job — turn what you say into a clean, engineered prompt — so they're now a single Prompt mode.",
          "It auto-detects what you need: a precise coding-agent prompt (Cursor, Claude Code — every file path, function and error kept verbatim) or a general AI prompt (ChatGPT, Claude, an image generator — task, context, constraints, output format). Still on ⌃⌥5, still auto-activates in your editor and terminal.",
        ],
      },
      {
        version: "0.9.34",
        title: "Connected apps, front and center",
        items: [
          "Connected apps moved out of Settings and into the sidebar, under Library — connect Gmail, Slack, Notion and 1,000+ more, then act on them by voice with JARVIS. It's a real feature, so it now has a real home.",
        ],
      },
      {
        version: "0.9.33",
        title: "The Automatic engine never dead-ends",
        items: [
          "On the Automatic engine (Claude Code, else Verba), if a model or backend fails, is unavailable, or is rate-limited, Verba now automatically tries the next one until a dictation comes back — no more “Claude Code failed” dead-ends.",
          "Local transcription models: a Reinstall button to re-download a model if it ever gets corrupted or only partly downloaded. (Your model is still installed automatically in the background on first launch.)",
        ],
      },
      {
        version: "0.9.32",
        title: "Pick your Translate language inline",
        items: [
          "In Translate mode, a small language chip now sits right on the recording pill (and in the menu bar) — tap it to switch the output language without opening Settings.",
          "Your choice is remembered as the default, so the next dictation translates into the same language until you change it.",
        ],
      },
      {
        version: "0.9.31",
        title: "New mode: Prompt",
        items: [
          "Prompt mode turns rambling dictation into a clean, optimized AI prompt — task, context, constraints, and output format — ready to paste into ChatGPT, Claude, an image generator, anything.",
          "It's the general-purpose sibling of Coding mode. Pick it from your modes, or set it as a per-app default.",
        ],
      },
      {
        version: "0.9.30",
        title: "Rename imported transcripts",
        items: [
          "Open a saved transcript and click its name to rename it — handy when the file came in as something like “audio_2026.m4a”.",
          "Clear the name to fall back to the original file name. Your existing transcripts are untouched.",
        ],
      },
    ],
  },
  {
    date: "June 12, 2026",
    summary:
      "A calmer first run, a nested tag tree for filing, and the story in the app. The onboarding now teaches every shortcut, Action, Note, To-do, Transform and more, opens the app the moment you finish, and lets you keep your profile private. Notes and Tasks both get a proper nested tag tree for filing, the full changelog now lives right inside Settings, the level ladder climbs to 1,000, and every badge explains what it's for.",
    entries: [
      {
        version: "0.9.29",
        title: "Fixes that make recent updates actually work",
        items: [
          "⌘⌫ now really deletes the selected note (the shortcut wasn't firing before).",
          "The Intent note mode now reads the intent you speak at the start of the recording.",
          "Attaching only a screenshot to feedback (no typed text) now sends instead of doing nothing.",
        ],
      },
      {
        version: "0.9.28",
        title: "Flow is now Raw, plus more of your feedback",
        items: [
          "Flow mode is renamed Raw, the same verbatim, no-AI dictation, with a clearer name.",
          "Leaderboard: filter by All time, Year, Month, or Week.",
          "Notes: Intent now works by speaking your intent at the start of the recording, then your note, with an explanation up front instead of a separate text box.",
          "Feedback: one tidy action bar, Dictate and Attach screenshot now sit with the main buttons.",
          "Onboarding leads with the core mode first, the advanced modes come after.",
          "Faster first word: the mic re-arms right after a voice note so the next dictation starts instantly.",
        ],
      },
      {
        version: "0.9.27",
        title: "A batch of fixes from your feedback",
        items: [
          "Dictation no longer overwrites your clipboard: auto-paste now puts back whatever you had copied. (Copying every dictation is now an opt-in toggle.)",
          "Notes: press ⌘⌫ to delete the selected note.",
          "A “New version available” banner now shows in the sidebar the moment an update is ready, so you can update in one click.",
          "Dictionary: no more stray empty tile, and a quick “Added to dictionary” confirmation when you press Enter.",
          "Wishlist now shows the newest ideas first.",
          "Feedback: the screenshot you attach is now read by Improve-with-AI, and the button reads “Give feedback”.",
          "Onboarding: the success messages are larger and easier to read.",
        ],
      },
      {
        version: "0.9.26",
        title: "Reuse a tag you already have, in Tasks",
        items: [
          "When you add a tag to a project in Tasks, Verba now suggests the tags you've already used on your other projects right under the field, filtered as you type. Tap one to file the project under an existing tag in a single click, instead of retyping it and risking a near-duplicate, the picker stays open so you can add several in a row.",
        ],
      },
      {
        version: "0.9.25",
        title: "A human-copywriting pass, and a footer on every page",
        items: [
          "Rewrote verba.run to read like a person wrote it, not a model: we removed the em dashes (the punctuation readers and Google associate with AI-generated text) across every page, and tidied the prose that came with them.",
          "Every page now shares one consistent footer, with each link kept on a single line so nothing wraps awkwardly.",
          "The plan label in the app menu (Pro plan / Free trial) is now a quiet monochrome instead of bright green, so it matches the rest of the design.",
        ],
      },
      {
        version: "0.9.24",
        title: "No more “access data from other apps” prompt",
        items: [
          "Fixed: macOS kept popping up “Verba would like to access data from other apps” whenever you used Action mode. That was Verba reading your Shortcuts list (to match a spoken command to a real Shortcut) via the system tool. Verba now runs that helper with disclaimed responsibility, the access is attributed to macOS's own Shortcuts tool, which is already allowed, so the prompt no longer appears, even after an update.",
        ],
      },
      {
        version: "0.9.23",
        title: "Action mode (Fn+X) fixed",
        items: [
          "Fixed: Action mode (Fn+X / JARVIS) had stopped running commands after a recent change. The new “no preamble” instruction we added to clean up Translate output was leaking into JARVIS's planning and telling it to reply with plain text only, which suppressed the structured action it needs to actually do something. The guard is now kept out of the agent's path, and the command transcript is never altered when an action is detected, so Fn+X executes your commands again.",
        ],
      },
      {
        version: "0.9.22",
        title: "Compare badges with anyone",
        items: [
          "On another player's profile, you now see which of the badges you've earned too: a checkmark marks every badge you hold, even the ones they haven't, so you can see where you're ahead. A quick tally up top shows what you both have, what they have that you don't, and what you have that they don't.",
        ],
      },
      {
        version: "0.9.21",
        title: "Social profiles now show full Insights",
        items: [
          "Tap anyone on the leaderboard and you now see their analytics, not just their level and badges: words today, day streak, words this week, total words, dictations, words per minute, time saved, best day ever, and longest streak, the same Insights you see for yourself, now social.",
        ],
      },
      {
        version: "0.9.20",
        title: "Tasks: a tidy status dropdown",
        items: [
          "In Tasks, the status filter (All, Today, Upcoming, Done, Overdue) is now a clean dropdown instead of a row of chips that ran off the edge of the sidebar, pick a status from a proper menu with icons and a checkmark on the active one.",
        ],
      },
      {
        version: "0.9.18 → 0.9.19",
        title: "A cleaner first line, and a site you can navigate",
        items: [
          "Fixed for good: a stray first line in Translate and some modes, where the output opened with a preamble (“Here is the restructured transcript:”, “Voici la traduction :”) before your text. Verba now strips that line deterministically before anything is pasted, so it can never reach your clipboard again, your transcript lands directly, in every mode.",
          "verba.run is reorganized: a Features menu with a dedicated page for each capability, JARVIS, dictation modes, voice notes, voice tasks, live translation, and Context mode, plus a Resources menu, so the nav isn't a wall of links anymore.",
          "The landing page is shorter and faster to read: the deep feature walkthroughs moved to their own pages, so the home gets to the point and each feature has a focused page of its own.",
          "The new nav menus are now properly readable: the dropdown panels are solid instead of see-through, so the text behind them no longer bleeds through.",
        ],
      },
      {
        version: "0.9.17",
        title: "Docs, a Discord, and a site-wide SEO pass",
        items: [
          "Community moved to Discord: the Community link in the app (and on the site) now opens our Discord server, come say hi at discord.gg/7xfkfQN9AR.",
          "New documentation site at verba.run/docs: setup & permissions, every mode, the AI engines you control, JARVIS, Notes, Tasks, the full shortcut list, privacy, and troubleshooting, all in one place.",
          "A thorough SEO/GEO pass on verba.run: richer structured data (WebSite, breadcrumbs, founder/creator, full Offer), social-share images on every page, longer meta descriptions, a www→verba.run redirect, and the docs wired into the sitemap and llms.txt so search engines and AI assistants describe Verba accurately.",
        ],
      },
      {
        version: "0.9.16",
        title: "1,000 levels, and badges that explain themselves",
        items: [
          "The level ladder now climbs to 1,000, with a whole new run of titles past Legend: Voice Immortal, Ascendant, Celestial, Transcendent, Ethereal, Empyrean, Cosmic, Eternal, and at the very top, Voice Singularity.",
          "Every badge now shows what it's for, right under its name, including on someone else's profile from the leaderboard, so a name like “AI Whisperer” or “Burning the Midnight Oil” tells you exactly what earns it instead of leaving you guessing.",
        ],
      },
      {
        version: "0.9.14 → 0.9.15",
        title: "Tidy Tasks, and the changelog in the app",
        items: [
          "Tasks file like Notes now: your project tags collapse into a clean, nested sidebar tree, All Tasks and Untagged at the top, parent tags opening to their children with a count each. Click any tag to filter, including every project nested beneath it. No more flat wall of tag chips.",
          "New Settings ▸ Changelog: the whole release story, every version since launch, now lives inside the app, so you can see exactly what shipped without leaving Verba.",
        ],
      },
      {
        version: "0.9.5 → 0.9.13",
        title: "Onboarding that shows everything, and a tag tree for notes",
        items: [
          "Notes get one-tap mode actions: apply any mode to a note in a tap, including the custom modes you built yourself, now surfaced right alongside the built-in ones.",
          "Export a note: save it as a Markdown (.md) or plain-text file straight from the note toolbar.",
          "Wishlist now shows newest ideas first (within each vote tier), and long requests get a Show more so nothing is cut off or unclickable.",
          "Feedback is one tap now: Send runs Improve-with-AI for you, shows the tidied version to confirm or tweak, then sends, one button, no second step.",
          "Wishlist fix: shipped ideas keep their green “shipped” badge for good, it's saved with the wish now, so it survives behind the scenes changes.",
          "Dictionary auto-learn fixed: correct a name or brand in the text Verba just wrote and it now reliably learns the spelling, so it gets it right next time (punctuation no longer threw it off).",
          "More to unlock: \"Explore Verba\" now covers every shortcut too, push-to-talk, Fn+number, mode switching, pause, cancel, the to-do glance, chaining dictations, custom modes, your own AI engine, re-working history and file transcription, each badge naming the keys so it doubles as a cheat sheet. And a big batch of playful Special badges: thank your AI (Mind Your Manners → AI Whisperer), Ship It, Bug Hunter, Founder Mode, AI Native, Big Dreamer, Weekend Warrior, Burning the Midnight Oil, Globe Trotter across time zones, and more, all earned purely on-device from your own words and your Mac's clock.",
          "New \"Explore Verba\" achievements, a gamified tour of every feature and shortcut. As you try each one (a mode, a note, a tag, the Scratchpad, a task you check off, the dictionary, a connected app, a voice Action…) the matching badge ticks off, all the way to the Verba Explorer trophy. It sits first in Achievements so it doubles as a friendly way to learn the app.",
          "Notes Intent mode fixed: it no longer auto-formats with an empty instruction. After you record, the raw transcript stays put and the instruction field is focused, type how to shape the note, press Enter, and it applies.",
          "Feedback fixes from the in-app reports: Add-a-word in the Dictionary now confirms on Enter and jumps to a fresh word so you can add several in a row; the Notes Intent field scrolls when your instruction is long instead of truncating; and on AZERTY (and similar) layouts, Shift+number types a digit again instead of switching modes.",
          "Send Feedback now runs \"Improve with AI\" for you: tap Send, watch it structure your note, edit the result if you like, then Confirm to send or Cancel to go back.",
          "Lock a note with a password, and each note can have its own. Locked notes are encrypted on your Mac (AES-GCM, a separate key per note); without the password there's no way to read them. Open one, enter its password, and it unlocks just for this session.",
          "Every shortcut is now in Settings ▸ Shortcuts and every one is customizable, including new rebindable Pause/resume and Cancel shortcuts (the default ⌃ and Esc keep working too).",
          "Small thing: the recording pill dropped the little \"esc\" label next to the ×, the × still cancels and so does Esc, it just reads cleaner now.",
          "Achievements went big: 186 badges now, grouped into 10 ordered categories (Words Spoken, Dictations, Streaks, Dedication, Speed, Big Days, Time Saved, Airtime, Modes & Features, Special) with per-category progress, and a new Diamond tier for the extreme milestones, the word ladder climbs all the way to 1,000,000,000,000 words spoken.",
          "Notes get a nested tag tree: your #tags now file into a nested, collapsible sidebar with note counts, All Notes and Untagged at the top, parent tags opening to their children. Click any tag to filter, including every note nested beneath it.",
          "Onboarding now lists every shortcut, not just the basics: Action (Fn + X), Note (Fn + Z), To-do (Fn + T), today's to-dos (⌥ + Fn), Transform a selection (⌥ + X), switch style (Fn + ] / [), plus pause, switch and cancel, nothing hidden.",
          "Finishing onboarding now opens Verba straight away instead of leaving you to re-click the icon.",
          "Pick whether your profile is public: a new toggle keeps your name off the leaderboard while you still use it inside the app.",
          "Keep your text history without the audio: a new setting stores only the text of each dictation to save disk, while history, search and re-work stay fully available.",
          "Clearer first-run copy: your AI choice (local model, your OpenAI/Claude key, or a Claude plan) is shown at one level, modes no longer name a specific model, and a tip points you to the macOS Keyboard setting if the emoji popup ever shows.",
          "The whole onboarding and the new settings are translated into all 15 languages.",
        ],
      },
    ],
  },
  {
    date: "June 11, 2026",
    summary:
      "The day Action mode became a real assistant: speak any request, however you phrase it, and Verba works out what you mean, plans the steps and acts, always with your confirmation, in a calm, JARVIS-style feed. Connect 1,000+ apps to act on by voice, and the whole app now speaks 15 languages. Plus a calmer recording pill, your whole task tree at a glance, 100 levels with a lifetime reward, social profiles, and a security-hardening pass.",
    entries: [
      {
        version: "0.7.8 → 0.9.4",
        title: "Meet JARVIS, your voice agent for 1,000+ apps",
        items: [
          "Action mode is now a real assistant. Say what you want however it comes out, “remind me in 10 to grab the cake” or “I’m hungry, cake in ten minutes” land the same way, and Verba recovers the true intent, resolves the time, and shows exactly what it will do before doing it.",
          "It goes multi-step when a goal needs context: ask it to find a free hour tomorrow and it reads your calendar, finds the slot, and proposes the event, you just confirm. It reads to understand, but never makes a change without your okay.",
          "Everything plays out in a calm, JARVIS-style Action feed: a one-line summary, the proposed step, and a spoken confirmation when it’s done.",
          "The Connect-your-apps screen got a lighter, more minimal redesign, real app logos, a category filter, and one-tap disconnect.",
          "Connecting an app is now rock-solid: real logos load reliably, the status always reflects reality, and if you cancel or deny the sign-in the Connect button comes right back instead of hanging.",
          "Polish on the Action feed: the headline stays clean while the assistant thinks (your words are quoted underneath), it never spins forever on a request that stalls, and the app cards lay out cleanly at every width.",
          "Missing a detail? The assistant now asks for it. Say “send an email saying hello” without a recipient and it shows fill-in fields, recipient, subject, body, with what it already drafted pre-filled. Type the rest and send, straight from the feed.",
          "The assistant is now named JARVIS, and connects to 1,000+ apps. A new Connected apps section in Settings lets you search the full catalog, filter by category, and connect any of them with one tap.",
          "JARVIS asks a quick question when your request is ambiguous (a Google Meet, or just a calendar block?), and rebuilds spoken email addresses (“simono dot gareth at gmail dot com”) into the real thing, with an editable field to confirm when it's unsure.",
          "Time is now exact: “add an event in 10 minutes” lands at the right minute in your computer's own timezone, instead of drifting by hours.",
          "Tap any app to see everything you can do with it, every action, each with example phrases you can say to JARVIS (“Send an email to Marc about the demo”, “Post in the team channel that the demo is ready”). And JARVIS now knows the full action set of every app you've connected.",
          "The catalog now spans 1,000+ apps, and the comparison shows what's unique: Verba is the only dictation app with a voice agent that acts on your connected apps, not just edits text.",
          "The recording pill is smoother: the live waveform no longer re-renders the whole pill every frame, so it stays rock-steady while you talk. And a tip in Settings: name the app you want (“send a Slack message…”) and JARVIS picks the right one first try.",
          "The recording indicator stays put: the Done, info and mode-change flashes now sit at the exact same centered spot as the live Listening pill, instead of drifting as the width changes.",
          "Mode switches now stick: jump to a mode with Fn+1…9 (or the picker) and Verba stays on it for every next dictation until you change it. And the Fn+number chord no longer cuts the recording when you release Fn. JARVIS's on-device planner now runs fully sandboxed (no tools), so it always fetches your real data through Verba instead of improvising.",
          "Dictations now stack: start the next recording while the last is still processing, every in-flight dictation shows as its own little chip above the pill, so you can fire off 10 in a row and watch them all land. Onboarding now teaches this too.",
          "JARVIS now thinks on YOUR engine: planning runs on-device through your Claude subscription (Claude Code) or your local model, with your own keys as an option. Verba's servers only relay the connected-app calls, your requests never burn a shared cloud key, and JARVIS keeps working even offline-first setups.",
          "Connect almost anything: most apps authenticate with an API key, not a browser sign-in, so Connect now opens a small form asking for exactly the keys that app needs (and still opens the browser for the OAuth ones). After an action, JARVIS can suggest a smart next step (“Invite people to the event?”) and carry it out.",
        ],
      },
      {
        version: "0.7.5 → 0.7.7",
        title: "Connect your favorite apps, act by voice",
        items: [
          "Connect up to 50 of the most-used apps, Gmail, Slack, Notion, Google Calendar, Linear, GitHub and more, right from Settings ▸ Action.",
          "Action mode can then act on them by voice. It stays secure: the connection keys live on Verba’s servers and never touch your machine.",
        ],
      },
      {
        version: "0.6.5 → 0.7.4",
        title: "Verba now speaks your language",
        items: [
          "The entire app, sidebar, settings, every mode and every tool, now translates into 14 languages. Choose your language and the whole interface follows.",
        ],
      },
      {
        version: "0.6.2 → 0.6.4",
        title: "A recording pill that stays out of your way",
        items: [
          "Every state of the recording pill was reviewed and cleaned up: recording, paused, processing and done now read clearly, the pill is always centered on screen, and the paused state no longer looks broken.",
          "Your theme accent now flows everywhere it should: the recording dot, the done checkmark, the selected item in the main menu, and every to-do checkbox in the app and the glance.",
          "The progress bars in Achievements are now always visible, and the cards breathe with a little more room.",
        ],
      },
      {
        version: "0.5.8 → 0.6.1",
        title: "Your whole task tree, at a glance",
        items: [
          "The quick task glance now shows your projects, their tasks and their sub-tasks. Fold any project or task to focus.",
          "Add a task by voice straight from the glance with the new mic button, and check one off with a satisfying slide-out, with a one-tap undo if you ticked the wrong thing.",
          "A wider, calmer panel that always lands centered.",
        ],
      },
      {
        version: "0.5.3 → 0.5.7",
        title: "100 levels, more badges, and friends",
        items: [
          "Progression now runs to 100 levels with new titles all the way up to Voice Immortal, plus dozens of new badges to chase.",
          "Earn every badge and Verba Pro is yours for life: the Grand Slam.",
          "Profiles go social: tap anyone on the leaderboard to see their level, league and the badges they have earned, and share your own stats as a card.",
          "Reminders now appear even while Verba is the active app, and numbers you speak are written as digits.",
        ],
      },
      {
        version: "Under the hood",
        title: "Faster sync and a security pass",
        items: [
          "Cloud sync moved to a faster, EU-based backend.",
          "A thorough security and reliability hardening pass across the app, the sync layer and the website.",
        ],
      },
    ],
  },
  {
    date: "June 10, 2026",
    summary:
      "A privacy, security and craft day: history gets a real off switch and auto-delete, cloud data gets a delete-everything button, every sync request is authenticated per device, every dialog moves to the new glass design, and verba.run gets a full craft pass.",
    entries: [
      {
        version: "0.5.1 → 0.5.2",
        title: "Know every mode, and where you rank",
        items: [
          "Every mode now has a plain-language description of what it is for and how to use it. The built-ins ship with one, and any mode you build gets a friendly summary with one tap on Explain with AI.",
          "Your standing, live in Achievements: your leaderboard rank, the rival just ahead to catch, and the one just behind, alongside your level, weekly goal, league and records.",
          "Level ups now land with a spinning ray burst on top of the confetti.",
        ],
      },
      {
        version: "0.4.9 → 0.5.0",
        title: "Verba is now a game you can win",
        items: [
          "New Achievements section: your Level and XP, a daily words goal ring, your weekly League (Bronze to Diamond), and 24 badges to unlock as you dictate, switch modes, build streaks and save hours.",
          "Confetti and a reward card celebrate every achievement and level up, the moment you earn it.",
          "Your Customize look (app and widget) now syncs to your account, so a new Mac or a fresh sign-in restores it exactly.",
          "Plus a sweep of per-tool fixes across Notes, Tasks, Dictionary, Transforms, History, Modes and Settings.",
        ],
      },
      {
        version: "0.4.4 → 0.4.8",
        title: "A new Polish mode, numbers as digits, and a private leaderboard",
        items: [
          "New Polish mode (a default): it hears what you meant. When you talk and correct yourself, it follows your self-corrections to the final version, drops the parts you took back, and writes finished prose instead of a transcript of you thinking out loud.",
          "Numbers you say now come out as digits where it reads naturally: \"eighty five\" becomes 85, \"twenty percent\" becomes 20%, \"three thirty\" becomes 3:30.",
          "The leaderboard is private by design: it only ever shows a public handle, never a real name. Your handle is set during onboarding and a guard resets anything that looks like a real name to an anonymous alias.",
          "Every keyboard shortcut is rebindable, the ⌥X transform picker shows a live state, and the app window is fully glass with adjustable blur for both the app and its menus.",
        ],
      },
      {
        version: "0.3.7 → 0.3.8",
        title: "A window that feels like glass",
        items: [
          "The whole app window is now one piece of glass, and every page floats as an inset rounded card with breathing room on the edges, modern, not stuck to the window border.",
          "Escape now belongs to Verba while recording: it cancels your dictation without also closing something in the app behind it.",
          "And a sweep of smaller fixes across every screen, plus matching site copy.",
        ],
      },
      {
        version: "0.2.9 → 0.3.4",
        title: "Make it yours, plus a wave of fixes",
        items: [
          "From your feedback on Notes: the recording timer ticks again, the intent box grows to fit a long instruction, you can validate your intent (and see it's applied), and the note now actually follows the intent you set instead of ignoring it.",
          "From your feedback on Transforms: select text in any app and right-click → Services → “Transform with Verba” to run a transform without dictating, and the voice trigger keeps working too.",
          "New Customize settings: style the app and the macOS widget independently: glass material, blur, corner radius, accent color (monochrome by default, plus a palette or your own custom color), and one-tap presets. Liquid Glass, your way.",
          "Modes are reordered (Raw, Intent, Translate, Context, Coding on ⌃⌥1-5); create your own with the AI mode generator instead of editing a placeholder.",
          "From your feedback: Escape now cancels even while Verba is polishing; attaching a screenshot sends the real image (not a file path); a clear notice appears if you prompt with AI rewriting turned off; the feedback Dictate button shows a live, mic-reactive waveform; and Improve-with-AI now structures your report into Section / Issue / Expected.",
          "Send as much feedback as you want. The per-user limit is gone.",
        ],
      },
      {
        version: "0.2.6 → 0.2.8",
        title: "Consistent, monochrome, and it remembers you",
        items: [
          "Every tool in the Library now uses the same two-pane layout as Notes: a list with filter chips on the left, the editor on the right (Task Manager, Modes, Dictionary, Snippets, Style, Transforms, History, Recent Results).",
          "History matches Notes exactly now, and Insights gained a stack of new stats: this week vs last week, your most productive day, current vs longest streak, milestone progress, time saved, and your live leaderboard standing (rank and percentile).",
          "Pure black-and-white UI: selection is a quiet neutral highlight, never a heavy black block or a stray blue tint. Page titles are the exact same size on every screen.",
          "The Shortcuts settings are grouped into clear cards with real keycaps, so every trigger is easy to find.",
          "Your chosen username now sticks across restarts instead of resetting, and a fresh install starts in Raw (verbatim) mode.",
        ],
      },
      {
        version: "0.2.5",
        title: "Every screen, redesigned",
        items: [
          "Every page in the app now matches the new design language: big clear headers, glass cards, capsule filter chips instead of cramped segmented controls, and tidy aligned controls throughout (Notes, Task Manager, History, Modes, Insights, Home, and more).",
          "Settings is reorganized into seven clear sections (Account & Plan, Dictation, AI rewriting, Output, Shortcuts, Privacy & history, Updates) with a sidebar, so everything is easy to find.",
          "Manage your leaderboard identity right on the leaderboard: edit your alias and toggle your visibility without opening Settings.",
          "Fixed a handful of visual glitches from the redesign (a double-highlighted note row, overlapping controls in Settings) so every screen renders clean.",
        ],
      },
      {
        version: "0.2.4",
        title: "Once Pro, always Pro",
        items: [
          "Your subscription can no longer be downgraded by a wifi change, a flaky network, or a server hiccup: the only thing that ever revokes Pro is the server explicitly saying your subscription ended. Everything else keeps your current state and quietly re-checks later.",
          "After this week's security upgrade, already-signed-in Macs get a single friendly “Reconnect your account” prompt (one click, nothing else changes) instead of being asked to subscribe again.",
        ],
      },
      {
        version: "0.2.3",
        title: "Your leaderboard identity, managed on the leaderboard",
        items: [
          "Edit your public alias directly on the leaderboard page (with a shuffle button), and flip “Show me on the public leaderboard” right there. No more round-trip to Settings.",
          "Hiding yourself now shows a clear note on the board instead of your row just vanishing.",
          "The metric switcher (Total words, Words / min, Day streak, Time saved) is now a row of proper tag chips with icons, replacing the cramped segmented control.",
        ],
      },
      {
        version: "0.2.2",
        title: "Glass everywhere, and an app that behaves",
        items: [
          "Every dialog is redesigned in the new frosted glass style: action confirmations, the review panel, update and permission prompts, the trial screen, plus the Settings and History windows. Return and Escape work everywhere.",
          "Voice to-do capture finally works on US keyboards: the shortcut is now Fn+T (Fn+§ still works on European layouts), and Settings shows the right one for your keyboard.",
          "Verba is much lighter at launch: the on-device model now loads when you start recording (hidden behind your speaking time) and unloads after 10 minutes of inactivity.",
          "Edit-the-last-result by voice now works in Raw mode too, an update can no longer install itself in the middle of a dictation, errors stay visible in menu-bar-only mode, and temporary recordings are cleaned up automatically.",
          "Your custom modes and edited prompts now survive app updates.",
          "verba.run: a full design craft pass (motion, type, the works), and link previews you share now match the product.",
        ],
      },
      {
        version: "0.2.1",
        title: "Your data, under your control",
        items: [
          "New History controls in Settings: switch history off entirely (nothing written to disk, no audio copy, nothing synced) or auto-delete entries after 7, 30, or 90 days, on this Mac and in the cloud.",
          "Delete all my cloud data: one click removes your synced history, notes, stats, and leaderboard entry from our servers.",
          "Cloud sync hardened: every device now authenticates each request with its own secret, so only your Macs can read or write your data.",
          "The public leaderboard no longer carries any account identifier, only your alias and your numbers.",
          "Signed-in sessions are now token-verified end to end (AI reprompting, account, username, Pro status), and Pro keeps working through up to 72 hours offline instead of dropping the moment a check fails.",
          "Honest copy: verba.run now spells out exactly what stays on your Mac, what syncs when you sign in, and the new off switch, and the modes pages show every built-in mode.",
        ],
      },
    ],
  },
  {
    date: "June 9, 2026",
    summary:
      "A huge day, much of it straight from your feedback and wishlist: French that stays French, comments on every wishlist idea, a Context mode that really sees your screen, a redesigned site, hold-to-talk and reliable pause, mid-sentence mode switching, editable Note modes, layered writing Styles, smarter Transforms, a Transcripts library, and concurrent sessions.",
    entries: [
      {
        version: "0.1.96 → 0.2.0",
        title: "Straight from your feedback and wishlist",
        items: [
          "From the wishlist: dictate in French and drop in an English word, and Verba now keeps the whole thing French instead of flipping the output to English. Brand and loan words are kept exactly as you said them.",
          "From the wishlist: you can now discuss a wishlist item. Each card shows a discreet comment count; tap it to expand a thread, read what others think, and add your own. Every shipped idea keeps its “Developed” badge.",
          "From your feedback: Context mode now genuinely sees your screen again and acts on what's there, and when something does go wrong you get the real reason instead of a generic “transcription failed”.",
          "From your feedback: Action mode is clearer to trigger. A prompt tells you exactly how to run the command, with a focused confirmation before anything happens.",
          "The menu-bar shortcut cheat-sheet now updates the instant you change a shortcut in Settings.",
        ],
      },
      {
        version: "0.1.94 → 0.1.95",
        title: "A Task Manager widget, and a smarter Wishlist",
        items: [
          "New macOS widget: add Verba's Task Manager to Notification Center or your desktop and see today's tasks at a glance, in the native widget look.",
          "The Wishlist now shows a \u201cDeveloped\u201d badge once a request ships, and you can no longer upvote something that's already built.",
        ],
      },
      {
        version: "0.1.93",
        title: "See your parallel results, and a smarter feedback box",
        items: [
          "Multi-session is now visible: a Recent results panel (open from the menu bar) lists what processed in the background while you kept dictating, each with a Copy button.",
          "Action mode only needs Screen Recording when a command is actually about your screen.",
          "Feedback box: drag-drop a screenshot, an Improve-with-AI button, and a gentle sent confirmation.",
        ],
      },
      {
        version: "0.1.90 → 0.1.91",
        title: "Action mode, and a polished Task Manager",
        items: [
          "Feedback now lets you attach a screenshot, so a report comes with everything we need to fix it fast.",
          "New Action mode (Fn+X): speak a command and Verba does it. Create an event or reminder, draft an email, open an app, play music, send a message, or run any of your macOS Shortcuts, always with a confirmation first.",
          "Add to dictionary by voice: select text, say “add to dictionary”, and Verba keeps that exact spelling (great for brand names). It now survives the AI rewrite too.",
          "A modern calendar + time picker for deadlines (tasks and sub-tasks), replacing the old one.",
          "Feedback: dictate it with your voice, with the text field finally aligned.",
        ],
      },
      {
        version: "0.1.89",
        title: "A real username, never your real name",
        items: [
          "Pick a public username during onboarding (and change it anytime in Settings): it's the only thing shown on the leaderboard, never your real name or email.",
          "Your username is stored on your account and syncs across your Macs and the web.",
        ],
      },
      {
        version: "0.1.88",
        title: "Updates, right from the menu bar",
        items: [
          "When a new version is out, the menu-bar menu shows an “Install update” item and a small badge on the icon, one click to update and relaunch.",
          "A new Updates section in Settings: toggle automatic checking and automatic download & install, see your current version and last check, or check now.",
        ],
      },
      {
        version: "0.1.86 → 0.1.87",
        title: "Agentic actions, and switch mode with a tap",
        items: [
          "Agentic actions are real: turn on the Labs toggle, and in Context mode say “create an event tomorrow at 3pm”, “remind me to call the bank this afternoon”, or “draft a reply to this email”. Verba reads your screen, shows a confirmation, and on your OK creates the Calendar event, Reminder, or email draft.",
          "Switch mode hands-free with a single Option tap while you're recording. No need to stop or reach for a chord.",
        ],
      },
      {
        version: "0.1.85",
        title: "A redesigned site, and the controls fixed",
        items: [
          "New homepage: a signature hero that runs the live talk-to-clean-text demo, a monochrome macOS-grade look tied to the mic mark, real type hierarchy and varied layouts.",
          "Fixed Control pause so it never collides with other shortcuts, and made it reliable on every launch.",
          "Mid-recording mode switching is no longer ambiguous, with clear audio and visual feedback.",
          "Concurrent sessions hardened: a background session can no longer disturb the one you're recording, and an Esc-cancelled dictation never gets pasted.",
        ],
      },
      {
        version: "0.1.84",
        title: "Styles, Transforms, Transcripts library & concurrent sessions",
        items: [
          "Writing Styles: a tone/format layer on top of any mode, switch with Fn+[ / Fn+] or from the menu bar, add and edit your own (default “Normal” changes nothing).",
          "Transforms upgraded: select text and just say a short shortcut (“fix grammar”, “translate to English”) to run it in any app, with clearer wording (“Verbal Shortcut”).",
          "Transcripts library: imported transcripts are saved with tags and notes, history audio is exportable, and every transcript gets quick re-adapt actions + a voice intent.",
          "Run several at once: start a new dictation while a slow one is still processing; finished sessions wait in a list with a Copy button.",
          "Community → Feedback, a one-word “Add to Dictionary” from the review window, proper markdown on rich paste, and auto-paste that finds your field even across Spaces.",
        ],
      },
      {
        version: "0.1.83",
        title: "Hold-to-talk, pause, and mid-sentence mode switching",
        items: [
          "New Hold-to-talk style: hold the key to speak, release to send (alongside the press-to-lock style).",
          "Control reliably pauses and resumes a recording, every launch.",
          "Change mode while recording hands-free, long-press the key or click the mode on the overlay, without stopping.",
          "Notes record with the same on-screen widget (labelled “Note”, with pause / resume), and the note formats are now fully editable modes you can add, tweak and delete, plus an Intent mode.",
          "The Task Manager agent now builds real project ▸ task ▸ sub-task lists and generates them for you, “the shopping list for a chocolate cake in Cuisine” fills in the ingredients.",
          "Context (screen) mode simplified so it reliably sees your screen, and Dictionary gains a plain “add a word”.",
        ],
      },
      {
        version: "0.1.82",
        title: "Re-adapt any dictation, by voice",
        items: [
          "Every Recent card now expands to the full text (Show more / less) and opens an inline Adapt panel.",
          "One-click re-adapt through any mode (professional email, code, and more), or type a custom instruction.",
          "Or just press the mic and SAY how you want it changed, “make it a bug report”, and Verba transcribes and adapts it.",
          "The same Adapt panel now powers the History tab too.",
        ],
      },
      {
        version: "0.1.81",
        title: "Task Manager polish",
        items: [
          "Project tags sit cleanly inline on the title row (fixed a layout that clipped long task titles).",
          "A Keyboard Shortcuts cheat-sheet sits at the top of the menu-bar menu.",
        ],
      },
    ],
  },
  {
    date: "June 8, 2026",
    summary:
      "A full day of deep work: a complete Task Manager workspace with a generative AI agent, the franglais bug killed, instant capture, and dozens of rough edges sanded down.",
    entries: [
      {
        version: "0.1.68 → 0.1.80",
        title: "Task Manager grows up",
        items: [
          "To-dos is now the Task Manager, tucked under a new Tools section in the sidebar (Home · Insights · History, then Tools).",
          "A smarter AI agent that builds whole hierarchies from one request: “make a Cooking project, a Chocolate cake task, and the full shopping list” creates the project, the task, and a real ingredient list as sub-tasks.",
          "A clean, professional date & time picker with quick presets (Today 6pm, Tomorrow 9am, This weekend, Next week); sub-tasks can carry their own deadline now.",
          "Project tags moved inline onto the title row.",
          "⌥ + Fn pops a quick glance of today's tasks; a single Fn tap now stops a note or task voice capture.",
          "A Keyboard Shortcuts cheat-sheet right at the top of the menu-bar menu.",
        ],
      },
      {
        version: "0.1.67",
        title: "Task Manager, reimagined",
        items: [
          "A dedicated Task Manager workspace: projects ▸ tasks ▸ sub-tasks in clean accordion panels.",
          "Tags on projects with a filter bar, organize by Pro, Perso, Pense-bête, anything.",
          "A voice agent that turns a spoken request into a structured project, routed to the right list.",
          "Fn + § captures a task by voice from anywhere; a Capture by voice button in the app.",
        ],
      },
      {
        version: "0.1.66",
        title: "Reliability, speed & one language",
        items: [
          "Single-language output: no more franglais, the result is rewritten fully in the language you spoke, even in Raw.",
          "Instant capture: the recorder is pre-armed so it catches your very first word.",
          "Reliable cancel and a processing timeout, no more stuck spinners or force-quitting.",
          "Drag & drop into file transcription; WhatsApp .opus / Ogg voice notes now transcribe.",
          "History entries expand to full text, with one-tap adapt through any mode or a custom instruction.",
        ],
      },
      {
        version: "0.1.65",
        title: "Dictionary & Scratchpad",
        items: [
          "Add a word as a pure vocabulary hint (no replacement needed), with an Improve with AI button.",
          "Auto-learned terms are tagged so you can see what Verba picked up from your edits.",
          "Scratchpad transforms now actually run and surface errors instead of failing silently.",
          "Clear empty-state guidance across every section of the app.",
        ],
      },
      {
        version: "0.1.64",
        title: "Privacy on the leaderboard",
        items: [
          "Anonymous aliases by default, never your real name, with a shuffle and a one-line public reminder.",
          "An opt-out toggle to keep your profile off the leaderboard entirely.",
        ],
      },
      {
        version: "0.1.62 → 0.1.63",
        title: "Microphone, modes & layout",
        items: [
          "Pick your microphone source in a click, from the menu bar and the app.",
          "Fn + Tab to cycle modes, even mid-sentence; Fn + 1-6 to jump to a specific one.",
          "A taller default window and a customizable sidebar (show only the sections you use).",
        ],
      },
    ],
  },
  {
    date: "June 7, 2026",
    tag: "Polish & web",
    window: "23 public releases · 00:10 → 14:16",
    summary:
      "The macOS app stabilized across 23 public releases, and verba.run got a real craftsmanship pass.",
    entries: [
      {
        version: "website",
        time: "22:55",
        title: "A real Liquid Glass website",
        items: [
          "Redesigned verba.run with depth, specular edges and a native-macOS feel.",
          "Dropped every emoji for hand-built SVG icons; added a WebGL sound-wave hero.",
          "Wired Vercel Analytics.",
        ],
      },
      {
        version: "0.1.33 → 0.1.55",
        title: "Twenty-three releases in a day",
        items: [
          "Onboarding, entitlement sync, trial model and paywall tuning.",
          "The recording overlay, the Fn HUD suppression and the meter, refined release after release.",
          "Shipped continuously from 00:10 to 14:16.",
        ],
      },
    ],
  },
  {
    date: "June 6, 2026",
    tag: "It syncs, it learns",
    window: "24 public releases · 01:55 → 23:45",
    summary:
      "Verba grew a memory: cloud sync, a learning dictionary, offline reprompting and a real Dynamic Island.",
    entries: [
      {
        version: "0.1.1 → 0.1.32",
        title: "Sync, learning & local AI",
        items: [
          "Cloud history & stats sync, your Insights and totals follow your account across Macs.",
          "Auto-learning dictionary that remembers your corrections.",
          "File transcription and time-saved on the leaderboard.",
          "Local offline reprompting via Ollama (Qwen 2.5 7B), downloadable from Settings.",
          "A real Dynamic Island overlay; the iOS app scaffolded.",
          "Twenty-four public releases from 01:55 to 23:45.",
        ],
      },
    ],
  },
  {
    date: "June 5, 2026",
    tag: "Launch day",
    window: "first commit 14:07 · first release 21:20",
    summary:
      "Verba was born and shipped on the same day, native, on-device, and private from the first line.",
    entries: [
      {
        version: "0.1.0",
        time: "14:07",
        title: "Verba is born",
        items: [
          "Native Swift menu-bar dictation with Claude reprompting.",
          "Fn-key trigger, faithful reprompting, and modes: Coding, Intent, Raw, Custom.",
          "NVIDIA Parakeet on-device engine and a Claude Code (Max plan) backend.",
          "Sparkle auto-updates with a notarized release pipeline; full onboarding.",
          "Leaderboard (Convex), referral system, the verba.run landing site and Stripe billing.",
          "First public release at 21:20, the same day it began.",
        ],
      },
    ],
  },
];

const DOWNLOAD = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

export default function Changelog() {
  return (
    <main className="relative mx-auto max-w-4xl px-6 pb-28">
      <div className="aurora" />
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
        </div>
      </nav>

      <section className="py-14 text-center">
        <div className="mx-auto mb-6 w-fit rounded-full glass px-4 py-1.5 text-xs muted">
          Shipping in public, fast
        </div>
        <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-6xl">Changelog</h1>
        <p className="mx-auto mt-5 max-w-xl text-lg muted text-balance">
          Every release since launch, with dates and times. Verba went from first commit to a deep,
          polished app in days, and it keeps moving.
        </p>
        <div className="mx-auto mt-9 grid max-w-lg grid-cols-3 gap-3">
          {[
            ["June 5", "launched", "2026"],
            ["60+", "releases", "in days"],
            ["Daily", "shipping", "in public"],
          ].map(([big, label, sub]) => (
            <div key={label} className="glass rounded-2xl p-5">
              <div className="text-2xl font-semibold tracking-tight">{big}</div>
              <div className="mt-1 text-sm font-medium">{label}</div>
              <div className="text-xs muted">{sub}</div>
            </div>
          ))}
        </div>
      </section>

      <div className="relative mt-6 space-y-16">
        {DAYS.map((day) => (
          <section key={day.date}>
            <Reveal>
              <div className="flex flex-wrap items-baseline gap-x-4 gap-y-1">
                <h2 className="text-2xl font-semibold tracking-tight">{day.date}</h2>
                {day.tag && (
                  <span className="rounded-full bg-[var(--tint)] px-3 py-1 text-xs muted">{day.tag}</span>
                )}
                {day.window && <span className="text-xs muted">{day.window}</span>}
              </div>
              <p className="mt-2 max-w-2xl text-sm muted text-balance">{day.summary}</p>
            </Reveal>

            <div className="mt-6 space-y-4">
              {day.entries.map((e, i) => (
                <Reveal key={e.version + e.title} delay={i * 60}>
                  <div className="glass lift rounded-3xl p-6 sm:p-7">
                    <div className="flex flex-wrap items-center gap-3">
                      {e.version && (
                        <span className="rounded-full bg-[var(--fg)] px-2.5 py-1 font-mono text-xs font-semibold text-[var(--bg)]">
                          {e.version === "website" ? "web" : `v${e.version}`}
                        </span>
                      )}
                      <h3 className="text-lg font-medium">{e.title}</h3>
                      {e.time && <span className="ml-auto text-xs muted">{e.time}</span>}
                    </div>
                    <ul className="mt-4 space-y-2">
                      {e.items.map((it) => (
                        <li key={it} className="flex gap-3 text-sm leading-relaxed">
                          <span className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--fg)] opacity-50" />
                          <span className="muted">{it}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </Reveal>
              ))}
            </div>
          </section>
        ))}
      </div>

      <section className="mt-20 text-center">
        <div className="glass-strong rounded-3xl p-10">
          <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">Built in the open, every day.</h2>
          <p className="mx-auto mt-3 max-w-md muted text-balance">
            This is the pace we hold ourselves to. Download Verba and watch it get better under you.
          </p>
          <a href={DOWNLOAD} className="mt-7 inline-block rounded-full bg-[var(--fg)] px-7 py-3 font-medium text-[var(--bg)] hover:opacity-90">
            Download for macOS
          </a>
        </div>
      </section>
    <SiteFooter />
    </main>
  );
}
