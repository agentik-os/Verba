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
            date: "August 6, 2026", tag: "Today",
            summary: "A dictation can no longer record forever, an input that sends no sound now names itself and Verba steps off it on its own, a recording that fails leaves a trace, your dictation stays in the language you speak, and your connected apps stop working from an old list.",
            entries: [
                ChangelogEntry(version: "0.9.106",
                    title: "A dictation can no longer record forever",
                    items: [
                        "With tap to start, tap again to send, a recording whose second tap never landed simply kept going, silently, holding your microphone. A recording now ends on its own after 10 minutes, and what you said is sent to be transcribed rather than thrown away.",
                        "While that recording was still running, every new dictation was refused, so Verba looked completely deaf until the old recording was finally ended. A recording that runs long now closes itself, and the next dictation starts normally.",
                        "If you do try to dictate while a recording is already running, Verba now tells you what is happening and how to end it: press your trigger again to send it, or Esc to cancel. It used to flash a two second “Couldn't start recording” that explained nothing.",
                    ]),
                ChangelogEntry(version: "0.9.105",
                    title: "Verba steps off a microphone that sends nothing, on its own",
                    items: [
                        "If the microphone Verba is recording from sends no sound at all, Verba now switches by itself to your Mac’s built-in microphone for the next dictation, and tells you it did. A dictation that would have come back empty a second time comes back with your words instead.",
                        "This only happens when you have not picked a microphone yourself and Verba was simply following your system default, and only after a recording that heard nothing. If you did choose a microphone, Verba never overrules you.",
                        "It stops as soon as sound comes through again, so an input that went quiet only for a moment goes back to being used normally.",
                        "When something does go wrong with a recording, Verba now writes down what happened: which microphone it used, whether any sound arrived, how long the input took to deliver its first sound, and how much was recorded. Until now a failed dictation left almost no trace, which made this kind of problem very hard to track down. Nothing about what you said is written down, only facts about the audio device.",
                    ]),
                ChangelogEntry(version: "0.9.104",
                    title: "A silent input device now tells you it is the one at fault",
                    items: [
                        "When Verba records and not one sound ever reaches it, it now says so and names the input it recorded from, instead of flashing a generic “Didn't catch that” that told you nothing. The message explains that this device is sending no audio, and a button opens System Settings ▸ Sound ▸ Input so you can pick a working microphone and watch its level meter move.",
                        "This happens when the selected input announces a microphone but never sends any. A Bluetooth speaker is the usual culprit: the moment it connects it becomes your system default input, and every dictation quietly produces an empty recording.",
                        "A dictation where sound did reach Verba but no words were recognised keeps the short “Didn't catch that” message it always had.",
                    ]),
                ChangelogEntry(version: "0.9.103",
                    title: "Connected apps keep up with what you just connected",
                    items: [
                        "Connecting an app, disconnecting one or switching to another account left Action mode working from the list of tools it had loaded earlier. The app showed as connected while your voice commands still could not reach it, sometimes until you quit and reopened Verba. That list is now refreshed the moment a connection changes, and signing out clears the previous account's connections instead of leaving them on screen.",
                        "When two refreshes happened to run at the same time, the slower one could finish last and put the older list back. The newer answer now wins.",
                    ]),
                ChangelogEntry(version: "0.9.102",
                    title: "Your dictation stays in the language you speak",
                    items: [
                        "A dictation in your language could come back partly, or entirely, in another one. Verba was letting the engine guess the language again on every few seconds of audio, so a single dictation could switch languages halfway through. It now transcribes in the language you have set, everywhere you dictate: the main shortcut, notes, to-do capture, file transcription, the Adapt panel and feedback.",
                        "Auto-detect is still there if you switch languages often. Leave the language unset and Verba keeps detecting it for you.",
                    ]),
            ]),
        ChangelogDay(
            date: "August 5, 2026",
            summary: "The microphone stops going dead until you relaunch, updates reach you again, and Verba stops pretending a failed update check went fine.",
            entries: [
                ChangelogEntry(version: "0.9.101",
                    title: "The microphone no longer goes dead until you relaunch",
                    items: [
                        "Once a recording had stopped on its own, every later attempt to dictate was refused, in every mode, until you quit and reopened Verba. That could happen after an audio glitch, a change of audio device, a microphone unplugged, a headset powered off or a switch to your AirPods. Verba now throws the dead recording away and starts a new one normally.",
                        "A dictation you had paused is no longer thrown away when something else tries to start a recording.",
                        "If you have refused microphone access, macOS never asks you again, so the message Verba flashed was a dead end you could not act on. It now opens the Microphone settings pane so you can grant access right there.",
                        "When the Fn key needs a permission Verba could not detect, it now names what to grant instead of silently doing nothing.",
                        "A microphone you had chosen that is no longer connected now falls back to your system default input instead of being treated as an error.",
                        "A shortcut that starts nothing now tells you why, instead of looking like a broken microphone.",
                    ]),
                ChangelogEntry(version: "0.9.100",
                    title: "Updates reach you again",
                    items: [
                        "If you have been sitting on 0.9.97 wondering why nothing new ever arrived, here is why: 0.9.98 and 0.9.99 were written but never came out as an installable build, so no copy of Verba was ever offered them. 0.9.100 is the first release to actually reach you since 0.9.97, and it brings everything those two were meant to bring.",
                        "Verba could advertise a version that no longer exists. The last version it had ever seen stayed pinned in the menu bar and in the update prompt even after a later check found nothing, so you could be invited to install a release that had been pulled. That version is now cleared the moment a check comes back empty, and a build that matches the one you are already running is never offered to you as an update.",
                        "A failed update check used to look exactly like a successful one. Being offline, a release feed that does not answer, a download whose signature does not verify: none of them said anything, and Settings kept showing a reassuring “last checked” time for a check that never got anywhere. Failures are now recorded, and “last checked” only moves when the check really completed.",
                        "Your auto-update preference is applied from the very first check. Verba used to start looking for updates a moment before it had finished reading that setting, so the first check after a launch could ignore it.",
                        "The version Verba reports in Settings, feedback and error reports now falls back to the build number instead of showing “0” when the display version is missing.",
                    ]),
                ChangelogEntry(version: "Under the hood",
                    title: "A release can no longer strand you on an old version",
                    items: [
                        "The release pipeline now refuses to publish anything that is not strictly newer than what is already out, and it checks the shape of the version number before a build even starts. A lower or oddly shaped version is exactly what freezes everyone silently: every installed copy compares it against what it already runs, finds nothing newer, and reports that you are up to date, forever.",
                        "A live release is never deleted to make room for a retry. The old publish step removed the existing release first, which threw away a release people were downloading and opened a window where both the update feed and the download button pointed at nothing. New releases are now staged out of sight and only become visible once every file is attached.",
                        "After publishing, the pipeline downloads the update feed and the installer from the public addresses your copy of Verba and the website actually use, and fails the release if one of them is missing or points at the wrong build. A missing signing secret now stops the run in seconds instead of forty minutes later, after a full build and notarization.",
                        "The update path now has its own test suite: that 0.9.99 is read as older than 0.9.100, that every entry in the feed carries its signature and size, and that an update installs the newest version rather than an intermediate one.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 26, 2026",
            summary: "Your lists keep their order, long dictations survive, and the local model answers fast again.",
            entries: [
                ChangelogEntry(version: "0.9.99",
                    title: "Your transforms stop reshuffling every time you open Verba",
                    items: [
                        "The transform picker (Option + X) came back in a different order at almost every launch, so the 1 to 9 numbering you had learned never held. Your modes, styles, snippets and dictionary entries were shuffled the same way. Verba was rebuilding those lists from your synced account in an order that changed at each start, then saving the shuffle over the old one. They now keep the order you put them in, and anything you added on another device lands at the end of the list instead of somewhere in the middle.",
                        "Tasks you just ticked no longer jump around in the widget while they fade out.",
                    ]),
                ChangelogEntry(version: "0.9.98",
                    title: "Dictate for an hour: it no longer gives up or comes back short",
                    items: [
                        "A dictation longer than a few minutes could fail outright or come back shortened. There was a hard 3-minute ceiling on the whole transcribe-plus-rewrite step, so a long recording was cancelled while it was still working normally. The ceiling now follows how long you actually spoke.",
                        "The local model also never saw more than about 3000 words of a long transcript, and could only write back about 750 words, so the rest was quietly dropped. Both limits now follow the length of what you said, which is why long dictations used to read like a summary.",
                        "On your own API key, a very long dictation could stop mid-sentence. Measured on a 21000-word transcript, the last quarter was missing; the budget is now sized to the transcript.",
                        "The local model is quick again. It is now loaded while you are still speaking instead of after you stop, so you no longer wait for it to wake up. And on qwen3 it was silently writing a hidden block of reasoning before every answer, which was thrown away after you had already waited for it; that is switched off.",
                        "A tap of the key that records nothing no longer files a bug report for itself.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 13, 2026",
            summary: "The “access data from other apps” pop-up is gone for good, and no more false Fn-permission nags.",
            entries: [
                ChangelogEntry(version: "0.9.93",
                    title: "The “access data from other apps” pop-up is truly gone",
                    items: [
                        "Fixed for real: the macOS “Verba would like to access data from other apps” pop-up that kept appearing on every launch. The on-device speech model was stored in a shared “FluidAudio” folder that macOS treats as another app’s data; Verba now keeps it in its own space and moves any existing copy over automatically. Verified: no prompt on launch.",
                        "Also fixed the “Verba needs permission to use the Fn key” alert that could keep nagging even after you granted it — Verba now trusts the Accessibility permission it actually uses instead of a second one that reads stale until you relaunch.",
                    ]),
                ChangelogEntry(version: "0.9.91",
                    title: "No more false “Verba needs Fn permission” prompts",
                    items: [
                        "Fixed the annoying “Verba needs permission to use the Fn key” alert that kept appearing even though you’d already granted it (it could show up after an update). Verba now checks whether the permission is actually granted before ever asking, and silently re-arms the Fn key instead of nagging.",
                    ]),
                ChangelogEntry(version: "0.9.90",
                    title: "Stop mixed-language transcripts — pin your language",
                    items: [
                        "Fixed transcripts that mixed French and English (or any two languages) even when you spoke only one. Settings ▸ Dictation ▸ Language now has a simple “Spoken language” picker: choose your language (e.g. French) and transcription stays 100% in it, in every mode including Raw. Leave it on Auto-detect only if you switch languages often.",
                    ]),
                ChangelogEntry(version: "0.9.89",
                    title: "Verba now fixes itself faster",
                    items: [
                        "Verba now automatically reports errors and crashes (sanitized — only the error text with paths/emails removed, your app version, and macOS, never your dictations or any content) so recurring problems get spotted and fixed without you having to report them. You can turn this off in Settings ▸ Privacy & history ▸ Diagnostics.",
                    ]),
                ChangelogEntry(version: "0.9.88",
                    title: "Action mode & AI rewriting now work on the local model",
                    items: [
                        "Fixed the big one: with the fully-local model, Action mode (and AI rewriting) could silently do nothing — stuck on “Setting up your local AI… 77%”. A secondary speech-model download (e.g. after picking Turbo) was wrongly holding the whole AI hostage. Now the local AI runs as soon as its own model is ready, regardless of any speech-model download. Action mode works on every backend — Claude, your own key, and fully local.",
                    ]),
                ChangelogEntry(version: "0.9.87",
                    title: "Turbo that actually loads, clearer Modes, faster transcription",
                    items: [
                        "Fixed Whisper Turbo failing to load (“Error in reading the MIL network”). It now uses the device-optimised Turbo build — smaller (≈ 0.6 GB), faster, and it loads and transcribes reliably. If you’d downloaded the old one, Verba cleans it up automatically.",
                        "Modes tab, clearer: your in-use mode is marked “Current”, and every mode has a simple show/hide switch — hide a mode from the picker without deleting it, and bring it back anytime.",
                        "Transcription is a bit faster on-device (we skip work dictation never uses), with identical accuracy.",
                    ]),
                ChangelogEntry(version: "0.9.86",
                    title: "Whisper unstuck + a faster Turbo model, instant dictation, reliable feedback",
                    items: [
                        "Fixed Whisper getting stuck on “Activating…” forever — it now loads reliably and offline, with no permission pop-up.",
                        "New: choose your Whisper model. Large v3 is the most accurate; the new Turbo is several times faster and lighter (≈ 1 GB), nearly as accurate — great for everyday dictation. The choice is labelled so you pick knowingly.",
                        "First dictation is instant again: Verba now warms your on-device model at launch, so raw dictation no longer stalls the first time (or after idle).",
                        "Feedback always sends now. “Give feedback” submits your message directly — it no longer depends on an AI step that could fail. “Improve with AI” is an optional polish button that never blocks sending.",
                        "Under the hood: safer formatted-paste, transcript-history rescue on corruption, and several reliability fixes from a deep code audit.",
                    ]),
                ChangelogEntry(version: "0.9.85",
                    title: "The “access data from other apps” pop-up is gone",
                    items: [
                        "Fixed for good: the macOS “Verba would like to access data from other apps” pop-up that kept appearing (often right after you took a screenshot). It came from how Verba rendered formatted text for pasting — now done natively, so Verba never touches your clipboard or other apps’ data to format text. No more prompt, and rich paste is faster too.",
                    ]),
                ChangelogEntry(version: "0.9.84",
                    title: "Your local model is safer, and setup can’t get stuck",
                    items: [
                        "On-device models now live in Verba’s own space instead of your Documents folder, so they’re never touched by iCloud and load reliably.",
                        "If a local model ever fails to load, Verba repairs it without deleting your copy, and never wipes a working model when you’re offline.",
                        "Setup can no longer get stuck: you can always finish onboarding even if a background download is still going or hit a snag.",
                        "Plus smaller reliability fixes to actions and feedback.",
                    ]),
            ]),
        ChangelogDay(
            date: "July 4, 2026", tag: nil,
            summary: "A cleaner Features page and setup, clearer engine choices, and JARVIS reliable on any engine.",
            entries: [
                ChangelogEntry(version: "0.9.74",
                    title: "You'll know when an update is ready",
                    items: [
                        "When a new version is available, Verba now shows a clear popup so you never miss it, with a one-tap Update now that installs in seconds and relaunches. It only asks once per version.",
                    ]),
                ChangelogEntry(version: "0.9.73",
                    title: "Fix: the local model now installs",
                    items: [
                        "Fixed a bad bug where installing the local AI engine failed for everyone who didn't already have it: the download source moved, and a security check wrongly rejected the engine. Both are fixed and verified, so Fully local now sets itself up automatically (or from the Set up button) and runs 100% offline.",
                    ]),
                ChangelogEntry(version: "0.9.72",
                    title: "Subscription restore, local setup errors, and Raw always free",
                    items: [
                        "Already subscribed but Verba shows Free? Settings, Account, enter your checkout email and Verify, it now restores your subscription even if you signed into the app with a different email.",
                        "The local engine Set up button now tells you what went wrong if it can't install, instead of doing nothing, with a Retry and a manual install link.",
                        "When your free trial ends you get a clear note, and you can always keep dictating in Raw, which is free forever for everyone.",
                    ]),
                ChangelogEntry(version: "0.9.71",
                    title: "Your AI, your keys, always",
                    items: [
                        "AI rewriting now runs only on what you choose: your Claude Code plan (no key), your own API key, or a fully local model. Verba never makes a billed AI call on your behalf. Simpler, more private, and honest.",
                    ]),
                ChangelogEntry(version: "0.9.70",
                    title: "Every AI feature works on every engine",
                    items: [
                        "Improve on feedback, and Context mode, no longer error when you run a local model. If your engine can't read a screenshot, Verba automatically works from your words instead of failing. We audited every AI feature so whatever engine you pick, it just works.",
                    ]),
                ChangelogEntry(version: "0.9.69",
                    title: "Latest cloud models available",
                    items: [
                        "When you use the cloud AI path (your Claude subscription or your own key), you can now pick the newest models, including Sonnet 5 and Opus 4.8. Fully local stays the private default.",
                    ]),
                ChangelogEntry(version: "0.9.68",
                    title: "Feedback fixes from you",
                    items: [
                        "Onboarding now says the right number of permissions, and the shortcut picker tells you exactly which key combos are valid and confirms your choice.",
                        "The Feedback panel has a clear Take screenshot button plus a separate Add file button, and Context mode no longer names a specific AI when you use a different one.",
                    ]),
                ChangelogEntry(version: "0.9.67",
                    title: "Fix: no more duplicate widget",
                    items: [
                        "Dictation and JARVIS results showed in the centered widget AND cloned a second copy in the bottom-right. Removed the duplicate: the centered widget is the single source of truth. The bottom-right toast is now only for to-dos and notes captured in the background while you do something else.",
                    ]),
                ChangelogEntry(version: "0.9.66",
                    title: "Your local AI installs itself, with a progress bar",
                    items: [
                        "First run on Fully local now downloads both on-device models (speech + AI) automatically, with a visible progress bar during onboarding — so your first prompt, mode or JARVIS command just works, no manual setup. If you try before it's ready, you see a friendly \"setting up… NN%\" instead of an error. Raw dictation works instantly regardless.",
                    ]),
                ChangelogEntry(version: "0.9.65",
                    title: "See every background task, and results land where you started",
                    items: [
                        "Run things in parallel and watch them: a to-do being added, a note transcribing, a JARVIS action, all show as little live chips that tick green when done.",
                        "Each dictation now delivers back to the app and field where you started it, so two dictations aimed at two different windows each land in the right place.",
                    ]),
                ChangelogEntry(version: "0.9.64",
                    title: "Full-screen to-do reminders",
                    items: [
                        "When a to-do reminder fires, Verba can now take over the whole screen with a large card showing what to do, a Mark-done button, and a Dismiss. It auto-closes after a few seconds, or stays until you close it manually. Configure it in Settings.",
                    ]),
                ChangelogEntry(version: "0.9.63",
                    title: "Everyone on the newer local model, auto-installed",
                    items: [
                        "Fresh installs auto-download the local transcription engine (Parakeet) and the local AI model (qwen3) during onboarding, no manual step. Anyone still on the older model is moved to qwen3 automatically, even across synced Macs.",
                    ]),
                ChangelogEntry(version: "0.9.62",
                    title: "Learn the shortcuts as you browse",
                    items: [
                        "Every tool and library page now shows its keyboard shortcuts at the bottom, with a one-tap button to change them in Settings. Discover and rebind shortcuts without hunting for them.",
                    ]),
                ChangelogEntry(version: "0.9.61",
                    title: "No more accidental mode picker, and bigger movable widgets",
                    items: [
                        "Holding Control+Option no longer pops the mode picker (it clashed with the new Control+Option X/Z/C widget shortcuts). Mode switching stays on Fn+Tab and Fn+1-9.",
                        "The Actions and To-do widgets are now bigger and taller by default, the same size as each other, and you can drag them anywhere on screen.",
                    ]),
                ChangelogEntry(version: "0.9.60",
                    title: "JARVIS acts noticeably faster",
                    items: [
                        "The local model now stays warm in memory and JARVIS bounds its output and runs its lookups in parallel, so actions fire without the cold-start wait (a repeat call dropped from ~5s to ~0.2s on the model side).",
                    ]),
                ChangelogEntry(version: "0.9.59",
                    title: "Global widget shortcuts + faster, more reliable JARVIS",
                    items: [
                        "The Actions and To-do widgets no longer vanish when you click elsewhere, and you can open all three from anywhere: ⌃⌥X Actions, ⌃⌥Z To-dos, ⌃⌥C Notes.",
                        "Removed the confusing extra mode-picker shortcut (mode switching stays on Fn+Tab and Fn+1-9).",
                        "JARVIS is faster and more reliable on the local model: it now trims bulky app data before reasoning, so asks like your next event work smoothly on-device.",
                    ]),
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
