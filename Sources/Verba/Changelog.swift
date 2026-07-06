import Foundation

// The release story, shown in Settings ▸ Changelog and mirrored on verba.run/changelog
// (keep both in sync, see the verba-site-changelog-sync rule). Content is editorial release
// notes, kept in English like the achievement copy (NOT L()-wrapped); only the surrounding
// Settings chrome is localized.

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String        // "0.9.14", "website", "Under the hood", …
    let title: String
    let items: [String]
    var time: String? = nil

    /// The little pill label: numeric versions read "v0.9.14", "website" reads "web", and
    /// editorial buckets ("Under the hood") show verbatim.
    var badge: String {
        if version == "website" { return "web" }
        if let f = version.first, f.isNumber { return "v\(version)" }
        return version
    }
}

struct ChangelogDay: Identifiable {
    let id = UUID()
    let date: String
    var tag: String? = nil
    var window: String? = nil
    let summary: String
    let entries: [ChangelogEntry]
}

enum Changelog {
    static let days: [ChangelogDay] = [
        ChangelogDay(
            date: "July 4, 2026", tag: "Today",
            summary: "A cleaner Features page and setup, clearer engine choices, and JARVIS reliable on any engine.",
            entries: [
                ChangelogEntry(version: "0.9.58",
                    title: "Fully local by default, now on qwen3",
                    items: [
                        "Verba now runs fully offline on your Mac by default (Ollama), on the newer qwen3 model, and every AI feature — including JARVIS, transforms and tools — works on-device with nothing leaving your Mac.",
                    ]),
                ChangelogEntry(version: "0.9.57",
                    title: "Styles settings, redesigned",
                    items: [
                        "The Styles section in Settings now uses the same clean, single-column card layout as every other section, with an inline editor, instead of a cramped two-pane view.",
                    ]),
                ChangelogEntry(version: "0.9.56",
                    title: "Fix: number keys stopped working while Verba was open",
                    items: [
                        "Fixed a bad bug where the mode picker could stay armed after it closed, so Verba kept swallowing your number-key presses system-wide. Numbers type normally again.",
                    ]),
                ChangelogEntry(version: "0.9.55",
                    title: "Connecting an app never fails silently",
                    items: [
                        "Fixed the Connect button doing nothing for apps you'd already connected, and it now shows a clear message when an app can't be connected yet (a few, like X and Telegram, need their own credentials Composio doesn't provide).",
                    ]),
                ChangelogEntry(version: "0.9.54",
                    title: "Tidier settings",
                    items: [
                        "Your OpenAI transcription key now lives in Dictation, with the engine that uses it, and AI rewriting shows only the one key your chosen backend needs. Cleaner, less confusing.",
                    ]),
                ChangelogEntry(version: "0.9.53",
                    title: "Raw dictation is free forever",
                    items: [
                        "Raw dictation is now free forever and unlimited, no card, no trial clock. Press Fn and talk, as much as you want, for as long as you want.",
                        "The Dictionary now has a clear Add button next to the word field, so you can add words with the mouse, not just the Enter key.",
                        "Verba Pro ($9.99/mo) unlocks everything else: every AI mode (Polish, Translate, Prompt, Intent, Context), plus Notes, Tasks, JARVIS, custom modes and editable prompts.",
                    ]),
                ChangelogEntry(version: "0.9.52",
                    title: "Your AI engine, respected everywhere",
                    items: [
                        "Fully local now means fully local: Context mode no longer quietly used hosted Claude when you were signed in, it stays on your chosen engine (local models just can't read screenshots, so it says so).",
                        "My API key now lets you pick the provider, OpenAI, Anthropic or OpenRouter, paste that key and choose a model. JARVIS and every mode use exactly the provider you picked.",
                        "Your engine, model and provider choice now sync across your Macs (your API keys stay only in each Mac's Keychain).",
                    ]),
                ChangelogEntry(version: "0.9.51",
                    title: "Turn modes on and off, and group them",
                    items: [
                        "Each mode now has an on/off toggle in Modes, so if you keep dozens you can enable just the ones a workflow needs. Disabled modes are hidden from the picker but never deleted (Raw always stays).",
                        "New mode groups: save your enabled modes as a group (Developer, Copywriting…) and activate the whole set in one tap.",
                    ]),
                ChangelogEntry(version: "0.9.50",
                    title: "Update button, feature shortcuts, and two fixes",
                    items: [
                        "The in-app 'New version available' button now actually opens the updater (it was opening behind the app on this menu-bar app).",
                        "Open a feature on the Features page to see and change its keyboard shortcut(s), some features have more than one.",
                        "JARVIS now shows your full spoken request without cutting it off, and the wishlist upvote button works (it was racing ahead of device registration).",
                    ]),
                ChangelogEntry(version: "0.9.49",
                    title: "A more polished Features page and setup",
                    items: [
                        "The Features page now uses clean Activate pills instead of system switches, marks your always-on Essentials, and each feature opens a bigger detail card. Setup now explains each AI engine, including exactly how the Claude option connects.",
                        "We'll walk you through the refreshed setup once more so everyone sees the new experience. Your setup, shortcuts and data are unchanged.",
                    ]),
                ChangelogEntry(version: "0.9.48",
                    title: "JARVIS self-corrects, even on smaller models",
                    items: [
                        "JARVIS now reshapes a slightly-off plan from a smaller local model into a valid one instead of failing, so a composed request (send an email AND add a calendar event) runs its multiple actions reliably whatever engine you picked.",
                    ]),
                ChangelogEntry(version: "0.9.47",
                    title: "JARVIS runs on your engine, reliably",
                    items: [
                        "JARVIS plans on the exact engine you selected, your local model, your Claude plan, or your key, and now waits long enough for a local model to think (they run entirely on your Mac, so they're slower).",
                        "Fixed the 'took too long' error: the connected-app reads on our relay had no time budget and were cut short. They now get the time they need.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 3, 2026", tag: nil,
            summary: "Meet the new Verba: a Features page, a calmer first run, gentle discovery, and one model everywhere. Verba now grows with you.",
            entries: [
                ChangelogEntry(version: "0.9.46",
                    title: "Fully local, ready out of the box",
                    items: [
                        "Fully local now installs its reprompting model automatically too, not just the engine, so on-device Polish, Translate and Prompt work with no manual setup. Raw dictation is instant regardless.",
                    ]),
                ChangelogEntry(version: "0.9.45",
                    title: "Local-first: open-source models by default",
                    items: [
                        "The setup now recommends Fully local first: open-source models run on your Mac and nothing ever leaves the device. Verba installs them for you, the on-device transcription model and the local reprompting engine.",
                        "Clearer AI options: the API-key card is gone, and My Claude subscription now says to install the Claude CLI and run it once in Terminal to sign in.",
                        "Sidebar groups (Tools, Library, Community) start collapsed, and you can join the Telegram community right from the end of setup. Fixed a hard-to-read success message.",
                    ]),
                ChangelogEntry(version: "0.9.44",
                    title: "Styles now in Settings",
                    items: [
                        "Your tone and format Styles are now a section in Settings, alongside everything else you tune.",
                    ]),
                ChangelogEntry(version: "0.9.43",
                    title: "A quick tour of what's new",
                    items: [
                        "We'll walk you through the refreshed 3-screen setup and the new Features page once, so you can see what changed. Your setup, shortcuts and data are all exactly as you left them.",
                    ]),
                ChangelogEntry(version: "0.9.42",
                    title: "See what a feature does before you turn it on",
                    items: [
                        "Tap any card on the Features page to open its detail: what it does, what it needs (a permission, a connection), and one button to turn it on or off.",
                    ]),
                ChangelogEntry(version: "0.9.41",
                    title: "One model, everywhere",
                    items: [
                        "Every mode now uses the single AI model you choose in Settings ▸ AI rewriting. No more per-mode model to manage, pick it once and it applies to Polish, Translate, Prompt, all of them.",
                    ]),
                ChangelogEntry(version: "0.9.40",
                    title: "Discover more, at your pace",
                    items: [
                        "As you use Verba, it can gently suggest a feature you haven't turned on yet, at most one a day, and always dismissable for good. No tours, no nagging.",
                        "New Power User badge for turning on a feature from both Advanced and Power.",
                    ]),
                ChangelogEntry(version: "0.9.39",
                    title: "A calmer first run",
                    items: [
                        "New Macs now get a 3-screen setup, permissions, your AI engine, and a first live dictation, instead of a long tour. Sign-in is optional and no longer blocks you.",
                        "A shortcut for a feature you haven't turned on stays inert, so nothing fires by accident. Your existing setup is unchanged.",
                    ]),
                ChangelogEntry(version: "0.9.38",
                    title: "Features: turn on Verba one power at a time",
                    items: [
                        "New Features page in the sidebar: see everything Verba can do, grouped as Essentials, Advanced and Power, and switch each capability on or off in one click.",
                        "New Macs start with the four essentials (Raw, Polish, Translate, Prompt) and grow from there. Your existing setup is completely untouched, everything you had stays on.",
                        "Turning a feature off only hides it, it never deletes your notes, tasks or history. In a hurry? One Enable everything button turns it all on.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 2, 2026",
            summary: "Our community moves to Telegram.",
            entries: [
                ChangelogEntry(version: "0.9.37",
                    title: "Community is now on Telegram",
                    items: [
                        "We've moved the community to Telegram. The Community link in the sidebar now opens our Telegram channel, t.me/verbarun. Come say hi.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 1, 2026",
            summary: "Verba never loses your last word: it keeps listening for a brief silent moment after you stop, so the final word of your sentence is always caught.",
            entries: [
                ChangelogEntry(version: "0.9.36",
                    title: "Never lose your last word",
                    items: [
                        "Verba now keeps the mic open for a brief, silent moment after you stop, so the last word of your sentence is always captured, even when you release the trigger a beat early. No more cut-off or wrong final words.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 30, 2026",
            summary: "Coding and Prompt merge into one Prompt mode, Connected apps move into the sidebar, the Automatic engine now self-heals, you can pick your Translate language on the fly, and you can rename your imported transcripts.",
            entries: [
                ChangelogEntry(version: "0.9.35",
                    title: "Coding and Prompt are now one mode: Prompt",
                    items: [
                        "Coding and Prompt did the same job — turn what you say into a clean, engineered prompt — so they're now a single Prompt mode.",
                        "It auto-detects what you need: a precise coding-agent prompt (Cursor, Claude Code — every file path, function and error kept verbatim) or a general AI prompt (ChatGPT, Claude, an image generator — task, context, constraints, output format). Still on ⌃⌥5, still auto-activates in your editor and terminal.",
                    ]),
                ChangelogEntry(version: "0.9.34",
                    title: "Connected apps, front and center",
                    items: [
                        "Connected apps moved out of Settings and into the sidebar, under Library — connect Gmail, Slack, Notion and 1,000+ more, then act on them by voice with JARVIS. It's a real feature, so it now has a real home.",
                    ]),
                ChangelogEntry(version: "0.9.33",
                    title: "The Automatic engine never dead-ends",
                    items: [
                        "On the Automatic engine (Claude Code, else Verba), if a model or backend fails, is unavailable, or is rate-limited, Verba now automatically tries the next one until a dictation comes back — no more “Claude Code failed” dead-ends.",
                        "Local transcription models: a Reinstall button to re-download a model if it ever gets corrupted or only partly downloaded. (Your model is still installed automatically in the background on first launch.)",
                    ]),
                ChangelogEntry(version: "0.9.32",
                    title: "Pick your Translate language inline",
                    items: [
                        "In Translate mode, a small language chip now sits right on the recording pill (and in the menu bar) — tap it to switch the output language without opening Settings.",
                        "Your choice is remembered as the default, so the next dictation translates into the same language until you change it.",
                    ]),
                ChangelogEntry(version: "0.9.31",
                    title: "New mode: Prompt",
                    items: [
                        "Prompt mode turns rambling dictation into a clean, optimized AI prompt — task, context, constraints, and output format — ready to paste into ChatGPT, Claude, an image generator, anything.",
                        "It's the general-purpose sibling of Coding mode. Pick it from your modes, or set it as a per-app default.",
                    ]),
                ChangelogEntry(version: "0.9.30",
                    title: "Rename imported transcripts",
                    items: [
                        "Open a saved transcript and click its name to rename it — handy when the file came in as something like “audio_2026.m4a”.",
                        "Clear the name to fall back to the original file name. Your existing transcripts are untouched.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 12, 2026",
            summary: "A calmer first run, a nested tag tree for filing, and the story in the app. Onboarding now teaches every shortcut, opens the app the moment you finish, and lets you keep your profile private. Notes and Tasks both get a proper nested tag tree for filing, you can lock individual notes, the full changelog lives right inside Settings, the level ladder now climbs to 1,000, and every badge explains what it's for.",
            entries: [
                ChangelogEntry(version: "0.9.29",
                    title: "Fixes that make recent updates actually work",
                    items: [
                        "⌘⌫ now really deletes the selected note (the shortcut wasn't firing before).",
                        "The Intent note mode now reads the intent you speak at the start of the recording.",
                        "Attaching only a screenshot to feedback (no typed text) now sends instead of doing nothing.",
                    ]),
                ChangelogEntry(version: "0.9.28",
                    title: "Flow is now Raw, plus more of your feedback",
                    items: [
                        "Flow mode is renamed Raw, the same verbatim, no-AI dictation, with a clearer name.",
                        "Leaderboard: filter by All time, Year, Month, or Week.",
                        "Notes: Intent now works by speaking your intent at the start of the recording, then your note, with an explanation up front instead of a separate text box.",
                        "Feedback: one tidy action bar, Dictate and Attach screenshot now sit with the main buttons.",
                        "Onboarding leads with the core mode first, the advanced modes come after.",
                        "Faster first word: the mic re-arms right after a voice note so the next dictation starts instantly.",
                    ]),
                ChangelogEntry(version: "0.9.27",
                    title: "A batch of fixes from your feedback",
                    items: [
                        "Dictation no longer overwrites your clipboard: auto-paste now puts back whatever you had copied. (Copying every dictation is now an opt-in toggle.)",
                        "Notes: press ⌘⌫ to delete the selected note.",
                        "A \"New version available\" banner now shows in the sidebar the moment an update is ready, so you can update in one click.",
                        "Dictionary: no more stray empty tile, and a quick \"Added to dictionary\" confirmation when you press Enter.",
                        "Wishlist now shows the newest ideas first.",
                        "Feedback: the screenshot you attach is now read by Improve-with-AI, and the button reads \"Give feedback\".",
                        "Onboarding: the success messages are larger and easier to read.",
                    ]),
                ChangelogEntry(version: "0.9.26",
                    title: "Reuse a tag you already have, in Tasks",
                    items: [
                        "When you add a tag to a project in Tasks, Verba now suggests the tags you've already used on your other projects right under the field, filtered as you type. Tap one to file the project under an existing tag in a single click, instead of retyping it and risking a near-duplicate, the picker stays open so you can add several in a row.",
                    ]),
                ChangelogEntry(version: "0.9.25",
                    title: "A human-copywriting pass, and a footer on every page",
                    items: [
                        "Rewrote verba.run to read like a person wrote it, not a model: we removed the em dashes (the punctuation readers and Google associate with AI-generated text) across every page, and tidied the prose that came with them.",
                        "Every page now shares one consistent footer, with each link kept on a single line so nothing wraps awkwardly.",
                        "The plan label in the app menu (Pro plan / Free trial) is now a quiet monochrome instead of bright green, so it matches the rest of the design.",
                    ]),
                ChangelogEntry(version: "0.9.24",
                    title: "No more \"access data from other apps\" prompt",
                    items: [
                        "Fixed: macOS kept popping up \"Verba would like to access data from other apps\" whenever you used Action mode. That was Verba reading your Shortcuts list (to match a spoken command to a real Shortcut) via the system tool. Verba now runs that helper with disclaimed responsibility, the access is attributed to macOS's own Shortcuts tool, which is already allowed, so the prompt no longer appears, even after an update.",
                    ]),
                ChangelogEntry(version: "0.9.23",
                    title: "Action mode (Fn+X) fixed",
                    items: [
                        "Fixed: Action mode (Fn+X / JARVIS) had stopped running commands after a recent change. The new \"no preamble\" instruction we added to clean up Translate output was leaking into JARVIS's planning and telling it to reply with plain text only, which suppressed the structured action it needs to actually do something. The guard is now kept out of the agent's path, and the command transcript is never altered when an action is detected, so Fn+X executes your commands again.",
                    ]),
                ChangelogEntry(version: "0.9.22",
                    title: "Compare badges with anyone",
                    items: [
                        "On another player's profile, you now see which of the badges you've earned too: a checkmark marks every badge you hold, even the ones they haven't, so you can see where you're ahead. A quick tally up top shows what you both have, what they have that you don't, and what you have that they don't.",
                    ]),
                ChangelogEntry(version: "0.9.21",
                    title: "Social profiles now show full Insights",
                    items: [
                        "Tap anyone on the leaderboard and you now see their analytics, not just their level and badges: words today, day streak, words this week, total words, dictations, words per minute, time saved, best day ever, and longest streak, the same Insights you see for yourself, now social.",
                    ]),
                ChangelogEntry(version: "0.9.20",
                    title: "Tasks: a tidy status dropdown",
                    items: [
                        "In Tasks, the status filter (All, Today, Upcoming, Done, Overdue) is now a clean dropdown instead of a row of chips that ran off the edge of the sidebar, pick a status from a proper menu with icons and a checkmark on the active one.",
                    ]),
                ChangelogEntry(version: "0.9.18 → 0.9.19",
                    title: "A cleaner first line, and a site you can navigate",
                    items: [
                        "Fixed for good: a stray first line in Translate and some modes, where the output opened with a preamble (\"Here is the restructured transcript:\", \"Voici la traduction :\") before your text. Verba now strips that line deterministically before anything is pasted, so it can never reach your clipboard again, your transcript lands directly, in every mode.",
                        "verba.run is reorganized: a Features menu with a dedicated page for each capability, JARVIS, dictation modes, voice notes, voice tasks, live translation, and Context mode, plus a Resources menu, so the nav isn't a wall of links anymore.",
                        "The landing page is shorter and faster to read: the deep feature walkthroughs moved to their own pages, so the home gets to the point and each feature has a focused page of its own.",
                        "The new nav menus are now properly readable: the dropdown panels are solid instead of see-through, so the text behind them no longer bleeds through.",
                    ]),
                ChangelogEntry(version: "0.9.17",
                    title: "Docs, a Discord, and a site-wide SEO pass",
                    items: [
                        "Community moved to Discord: the Community link in the app (and on the site) now opens our Discord server, come say hi at discord.gg/7xfkfQN9AR.",
                        "New documentation site at verba.run/docs: setup & permissions, every mode, the AI engines you control, JARVIS, Notes, Tasks, the full shortcut list, privacy, and troubleshooting, all in one place.",
                        "A thorough SEO/GEO pass on verba.run: richer structured data (WebSite, breadcrumbs, founder/creator, full Offer), social-share images on every page, longer meta descriptions, a www→verba.run redirect, and the docs wired into the sitemap and llms.txt so search engines and AI assistants describe Verba accurately.",
                    ]),
                ChangelogEntry(version: "0.9.16",
                    title: "1,000 levels, and badges that explain themselves",
                    items: [
                        "The level ladder now climbs to 1,000, with a whole new run of titles past Legend: Voice Immortal, Ascendant, Celestial, Transcendent, Ethereal, Empyrean, Cosmic, Eternal, and at the very top, Voice Singularity.",
                        "Every badge now shows what it's for, right under its name, including on someone else's profile from the leaderboard, so a name like “AI Whisperer” or “Burning the Midnight Oil” tells you exactly what earns it instead of leaving you guessing.",
                    ]),
                ChangelogEntry(version: "0.9.14 → 0.9.15",
                    title: "Tidy Tasks, and the changelog in the app",
                    items: [
                        "Tasks file like Notes now: your project tags collapse into a clean, nested sidebar tree, All Tasks and Untagged at the top, parent tags opening to their children with a count each. Click any tag to filter, including every project nested beneath it. No more flat wall of tag chips.",
                        "New Settings ▸ Changelog: the whole release story, every version since launch, now lives inside the app, so you can see exactly what shipped without leaving Verba.",
                    ]),
                ChangelogEntry(version: "0.9.5 → 0.9.13",
                    title: "Onboarding that shows everything, and a tag tree for notes",
                    items: [
                        "Notes get one-tap mode actions: apply any mode to a note in a tap, including the custom modes you built yourself, now surfaced right alongside the built-in ones.",
                        "Export a note: save it as a Markdown (.md) or plain-text file straight from the note toolbar.",
                        "Wishlist now shows newest ideas first (within each vote tier), and long requests get a Show more so nothing is cut off or unclickable.",
                        "Feedback is one tap now: Send runs Improve-with-AI for you, shows the tidied version to confirm or tweak, then sends, one button, no second step.",
                        "Wishlist fix: shipped ideas keep their green “shipped” badge for good, it's saved with the wish now, so it survives behind-the-scenes changes.",
                        "Dictionary auto-learn fixed: correct a name or brand in the text Verba just wrote and it now reliably learns the spelling, so it gets it right next time (punctuation no longer threw it off).",
                        "More to unlock: “Explore Verba” now covers every shortcut too, push-to-talk, Fn+number, mode switching, pause, cancel, the to-do glance, chaining dictations, custom modes, your own AI engine, re-working history and file transcription, each badge naming the keys so it doubles as a cheat sheet. Plus a big batch of playful Special badges, all earned purely on-device from your own words and your Mac's clock.",
                        "New “Explore Verba” achievements, a gamified tour of every feature and shortcut. As you try each one (a mode, a note, a tag, the Scratchpad, a task you check off, the dictionary, a connected app, a voice Action…) the matching badge ticks off, all the way to the Verba Explorer trophy. It sits first in Achievements so it doubles as a friendly way to learn the app.",
                        "Notes Intent mode fixed: it no longer auto-formats with an empty instruction. After you record, the raw transcript stays put and the instruction field is focused, type how to shape the note, press Enter, and it applies.",
                        "Feedback fixes from the in-app reports: Add-a-word in the Dictionary confirms on Enter and jumps to a fresh word so you can add several in a row; the Notes Intent field scrolls when your instruction is long; and on AZERTY (and similar) layouts, Shift+number types a digit again instead of switching modes.",
                        "Lock a note with a password, and each note can have its own. Locked notes are encrypted on your Mac (AES-GCM, a separate key per note); without the password there's no way to read them. Open one, enter its password, and it unlocks just for this session.",
                        "Every shortcut is now in Settings ▸ Shortcuts and every one is customizable, including new rebindable Pause/resume and Cancel shortcuts (the default ⌃ and Esc keep working too).",
                        "Small thing: the recording pill dropped the little “esc” label next to the ×, the × still cancels and so does Esc, it just reads cleaner now.",
                        "Achievements went big: 186+ badges, grouped into 10 ordered categories (Words Spoken, Dictations, Streaks, Dedication, Speed, Big Days, Time Saved, Airtime, Modes & Features, Special) with per-category progress, and a new Diamond tier for the extreme milestones, the word ladder climbs all the way to 1,000,000,000,000 words spoken.",
                        "Notes get a nested tag tree: your #tags now file into a collapsible sidebar with note counts, All Notes and Untagged at the top, parent tags opening to their children. Click any tag to filter, including every note nested beneath it.",
                        "Onboarding now lists every shortcut, not just the basics: Action (Fn + X), Note (Fn + Z), To-do (Fn + T), today's to-dos (⌥ + Fn), Transform a selection (⌥ + X), switch style (Fn + ] / [), plus pause, switch and cancel, nothing hidden.",
                        "Finishing onboarding now opens Verba straight away instead of leaving you to re-click the icon.",
                        "Pick whether your profile is public: a new toggle keeps your name off the leaderboard while you still use it inside the app.",
                        "Keep your text history without the audio: a new setting stores only the text of each dictation to save disk, while history, search and re-work stay fully available.",
                        "The whole onboarding and the new settings are translated into all 15 languages.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 11, 2026",
            summary: "The day Action mode became a real assistant: speak any request, however you phrase it, and Verba works out what you mean, plans the steps and acts, always with your confirmation, in a calm, JARVIS-style feed. Connect 1,000+ apps to act on by voice, and the whole app now speaks 15 languages. Plus a calmer recording pill, your whole task tree at a glance, 100 levels with a lifetime reward, social profiles, and a security-hardening pass.",
            entries: [
                ChangelogEntry(version: "0.7.8 → 0.9.4",
                    title: "Meet JARVIS, your voice agent for 1,000+ apps",
                    items: [
                        "Action mode is now a real assistant. Say what you want however it comes out, “remind me in 10 to grab the cake” or “I'm hungry, cake in ten minutes” land the same way, and Verba recovers the true intent, resolves the time, and shows exactly what it will do before doing it.",
                        "It goes multi-step when a goal needs context: ask it to find a free hour tomorrow and it reads your calendar, finds the slot, and proposes the event, you just confirm. It reads to understand, but never makes a change without your okay.",
                        "Everything plays out in a calm, JARVIS-style Action feed: a one-line summary, the proposed step, and a spoken confirmation when it's done.",
                        "The assistant is now named JARVIS, and connects to 1,000+ apps. A new Connected apps section in Settings lets you search the full catalog, filter by category, and connect any of them with one tap.",
                        "Missing a detail? The assistant now asks for it. Say “send an email saying hello” without a recipient and it shows fill-in fields with what it already drafted pre-filled. Type the rest and send, straight from the feed.",
                        "Time is now exact: “add an event in 10 minutes” lands at the right minute in your computer's own timezone, instead of drifting by hours.",
                        "Tap any app to see everything you can do with it, each with example phrases you can say to JARVIS. And JARVIS now knows the full action set of every app you've connected.",
                        "The catalog now spans 1,000+ apps, and the comparison shows what's unique: Verba is the only dictation app with a voice agent that acts on your connected apps, not just edits text.",
                        "Dictations now stack: start the next recording while the last is still processing, every in-flight dictation shows as its own little chip above the pill, so you can fire off 10 in a row and watch them all land.",
                        "JARVIS now thinks on YOUR engine: planning runs on-device through your Claude subscription (Claude Code) or your local model, with your own keys as an option. Verba's servers only relay the connected-app calls, your requests never burn a shared cloud key.",
                        "Connect almost anything: most apps authenticate with an API key, not a browser sign-in, so Connect opens a small form asking for exactly the keys that app needs (and still opens the browser for the OAuth ones).",
                    ]),
                ChangelogEntry(version: "0.7.5 → 0.7.7",
                    title: "Connect your favorite apps, act by voice",
                    items: [
                        "Connect up to 50 of the most-used apps, Gmail, Slack, Notion, Google Calendar, Linear, GitHub and more, right from Settings ▸ Action.",
                        "Action mode can then act on them by voice. It stays secure: the connection keys live on Verba's servers and never touch your machine.",
                    ]),
                ChangelogEntry(version: "0.6.5 → 0.7.4",
                    title: "Verba now speaks your language",
                    items: [
                        "The entire app, sidebar, settings, every mode and every tool, now translates into 14 languages. Choose your language and the whole interface follows.",
                    ]),
                ChangelogEntry(version: "0.5.3 → 0.6.4",
                    title: "100 levels, a task tree at a glance, and a cleaner pill",
                    items: [
                        "Progression runs to 100 levels with new titles all the way up to Voice Immortal, plus dozens of new badges. Earn every badge and Verba Pro is yours for life: the Grand Slam.",
                        "The quick task glance shows your projects, their tasks and their sub-tasks; add a task by voice from the glance, and check one off with a satisfying slide-out and one-tap undo.",
                        "Profiles go social: tap anyone on the leaderboard to see their level, league and badges, and share your own stats as a card.",
                        "Every state of the recording pill was cleaned up, recording, paused, processing and done all read clearly, and the pill is always centered on screen.",
                    ]),
                ChangelogEntry(version: "Under the hood",
                    title: "Faster sync and a security pass",
                    items: [
                        "Cloud sync moved to a faster, EU-based backend.",
                        "A thorough security and reliability hardening pass across the app, the sync layer and the website.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 10, 2026",
            summary: "A privacy, security and craft day: history gets a real off switch and auto-delete, cloud data gets a delete-everything button, every sync request is authenticated per device, every dialog moves to the new glass design, and verba.run gets a full craft pass.",
            entries: [
                ChangelogEntry(version: "0.4.9 → 0.5.2",
                    title: "Verba is now a game you can win",
                    items: [
                        "New Achievements section: your Level and XP, a daily words goal ring, your weekly League (Bronze to Diamond), and badges to unlock as you dictate, switch modes, build streaks and save hours.",
                        "Confetti and a reward card celebrate every achievement and level up, the moment you earn it.",
                        "Every mode now has a plain-language description; any mode you build gets a friendly summary with one tap on Explain with AI.",
                        "Your standing, live in Achievements: your leaderboard rank, the rival just ahead to catch, and the one just behind.",
                        "Your Customize look (app and widget) now syncs to your account, so a new Mac restores it exactly.",
                    ]),
                ChangelogEntry(version: "0.4.4 → 0.4.8",
                    title: "A new Polish mode, numbers as digits, and a private leaderboard",
                    items: [
                        "New Polish mode (a default): it hears what you meant. When you talk and correct yourself, it follows your self-corrections to the final version and writes finished prose instead of a transcript of you thinking out loud.",
                        "Numbers you say come out as digits where it reads naturally: “eighty five” becomes 85, “twenty percent” becomes 20%, “three thirty” becomes 3:30.",
                        "The leaderboard is private by design: it only ever shows a public handle, never a real name.",
                        "Every keyboard shortcut is rebindable, and the app window is fully glass with adjustable blur.",
                    ]),
                ChangelogEntry(version: "0.2.1 → 0.3.8",
                    title: "Your data, under your control",
                    items: [
                        "New History controls: switch history off entirely (nothing written to disk, no audio copy, nothing synced) or auto-delete entries after 7, 30, or 90 days, on this Mac and in the cloud.",
                        "Delete all my cloud data: one click removes your synced history, notes, stats, and leaderboard entry from our servers.",
                        "Cloud sync hardened: every device authenticates each request with its own secret, so only your Macs can read or write your data.",
                        "The whole app window is now one piece of glass, and every page floats as an inset rounded card with breathing room.",
                        "Every dialog is redesigned in the new frosted glass style; Return and Escape work everywhere.",
                        "Once Pro, always Pro: the only thing that revokes Pro is the server explicitly saying your subscription ended, never a flaky network.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 9, 2026",
            summary: "A huge day, much of it straight from your feedback and wishlist: French that stays French, comments on every wishlist idea, a Context mode that really sees your screen, a redesigned site, hold-to-talk and reliable pause, mid-sentence mode switching, editable Note modes, layered writing Styles, smarter Transforms, a Transcripts library, and concurrent sessions.",
            entries: [
                ChangelogEntry(version: "0.1.96 → 0.2.0",
                    title: "Straight from your feedback and wishlist",
                    items: [
                        "From the wishlist: dictate in French and drop in an English word, and Verba keeps the whole thing French instead of flipping the output to English. Brand and loan words are kept exactly as you said them.",
                        "From the wishlist: you can now discuss a wishlist item. Each card shows a comment count; tap it to expand a thread, read what others think, and add your own.",
                        "From your feedback: Context mode now genuinely sees your screen again and acts on what's there, and when something goes wrong you get the real reason.",
                    ]),
                ChangelogEntry(version: "0.1.90 → 0.1.95",
                    title: "Action mode, a widget, and a smarter Wishlist",
                    items: [
                        "New Action mode (Fn+X): speak a command and Verba does it, create an event or reminder, draft an email, open an app, play music, send a message, or run any of your macOS Shortcuts, always with a confirmation first.",
                        "New macOS widget: add Verba's Task Manager to Notification Center or your desktop and see today's tasks at a glance.",
                        "Multi-session is now visible: a Recent results panel lists what processed in the background while you kept dictating, each with a Copy button.",
                        "Add to dictionary by voice: select text, say “add to dictionary”, and Verba keeps that exact spelling.",
                    ]),
                ChangelogEntry(version: "0.1.81 → 0.1.89",
                    title: "Styles, Transforms, a Transcripts library & concurrent sessions",
                    items: [
                        "New Hold-to-talk style: hold the key to speak, release to send.",
                        "Writing Styles: a tone/format layer on top of any mode, switch with Fn+[ / Fn+], add and edit your own.",
                        "Transforms upgraded: select text and say a short shortcut (“fix grammar”, “translate to English”) to run it in any app.",
                        "Transcripts library: imported transcripts saved with tags and notes, with quick re-adapt actions and a voice intent.",
                        "Pick a public username during onboarding, it's the only thing shown on the leaderboard, never your real name.",
                        "Change mode while recording hands-free, long-press the key or click the mode on the overlay, without stopping.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 8, 2026",
            summary: "A full day of deep work: a complete Task Manager workspace with a generative AI agent, the franglais bug killed, instant capture, and dozens of rough edges sanded down.",
            entries: [
                ChangelogEntry(version: "0.1.67 → 0.1.80",
                    title: "Task Manager grows up",
                    items: [
                        "To-dos is now the Task Manager: projects ▸ tasks ▸ sub-tasks in clean accordion panels, tucked under a new Tools section.",
                        "A smarter AI agent that builds whole hierarchies from one request: “make a Cooking project, a Chocolate cake task, and the full shopping list” creates the project, the task, and a real ingredient list as sub-tasks.",
                        "A clean date & time picker with quick presets; sub-tasks can carry their own deadline.",
                        "⌥ + Fn pops a quick glance of today's tasks; a single Fn tap stops a note or task voice capture.",
                        "Tags on projects with a filter bar, organize by Pro, Perso, Pense-bête, anything.",
                    ]),
                ChangelogEntry(version: "0.1.62 → 0.1.66",
                    title: "Reliability, speed & one language",
                    items: [
                        "Single-language output: no more franglais, the result is rewritten fully in the language you spoke, even in Raw.",
                        "Instant capture: the recorder is pre-armed so it catches your very first word.",
                        "Reliable cancel and a processing timeout, no more stuck spinners or force-quitting.",
                        "Drag & drop into file transcription; WhatsApp .opus / Ogg voice notes now transcribe.",
                        "Add a word as a pure vocabulary hint, with an Improve with AI button; auto-learned terms are tagged.",
                        "Pick your microphone source in a click; Fn + Tab to cycle modes, even mid-sentence.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 7, 2026", tag: "Polish & web", window: "23 public releases · 00:10 → 14:16",
            summary: "The macOS app stabilized across 23 public releases, and verba.run got a real craftsmanship pass.",
            entries: [
                ChangelogEntry(version: "website",
                    title: "A real Liquid Glass website",
                    items: [
                        "Redesigned verba.run with depth, specular edges and a native-macOS feel.",
                        "Dropped every emoji for hand-built SVG icons; added a WebGL sound-wave hero.",
                        "Wired Vercel Analytics.",
                    ], time: "22:55"),
                ChangelogEntry(version: "0.1.33 → 0.1.55",
                    title: "Twenty-three releases in a day",
                    items: [
                        "Onboarding, entitlement sync, trial model and paywall tuning.",
                        "The recording overlay, the Fn HUD suppression and the meter, refined release after release.",
                        "Shipped continuously from 00:10 to 14:16.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 6, 2026", tag: "It syncs, it learns", window: "24 public releases · 01:55 → 23:45",
            summary: "Verba grew a memory: cloud sync, a learning dictionary, offline reprompting and a real Dynamic Island.",
            entries: [
                ChangelogEntry(version: "0.1.1 → 0.1.32",
                    title: "Sync, learning & local AI",
                    items: [
                        "Cloud history & stats sync, your Insights and totals follow your account across Macs.",
                        "Auto-learning dictionary that remembers your corrections.",
                        "File transcription and time-saved on the leaderboard.",
                        "Local offline reprompting via Ollama (Qwen 2.5 7B), downloadable from Settings.",
                        "A real Dynamic Island overlay; the iOS app scaffolded.",
                        "Twenty-four public releases from 01:55 to 23:45.",
                    ]),
            ]),
        ChangelogDay(
            date: "June 5, 2026", tag: "Launch day", window: "first commit 14:07 · first release 21:20",
            summary: "Verba was born and shipped on the same day, native, on-device, and private from the first line.",
            entries: [
                ChangelogEntry(version: "0.1.0",
                    title: "Verba is born",
                    items: [
                        "Native Swift menu-bar dictation with Claude reprompting.",
                        "Fn-key trigger, faithful reprompting, and modes: Coding, Intent, Raw, Custom.",
                        "NVIDIA Parakeet on-device engine and a Claude Code (Max plan) backend.",
                        "Sparkle auto-updates with a notarized release pipeline; full onboarding.",
                        "Leaderboard (Convex), referral system, the verba.run landing site and Stripe billing.",
                        "First public release at 21:20, the same day it began.",
                    ], time: "14:07"),
            ]),
    ]
}
