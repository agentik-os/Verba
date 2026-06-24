// Feature pages, content authored once here, rendered by app/features/[slug]/page.tsx and the
// /features hub. Keeping it as data (like lib/competitors) means one consistent layout for every
// feature page and one place to add the next one. Each page targets a distinct keyword cluster.

export type FeatureSection = { h2: string; body: string; bullets?: string[] };
export type FeatureFaq = { q: string; a: string };
export type Feature = {
  slug: string;
  navLabel: string;
  eyebrow: string;
  h1: string;
  metaTitle: string;
  metaDescription: string;
  lead: string;
  sections: FeatureSection[];
  faq: FeatureFaq[];
};

export const FEATURES: Feature[] = [
  {
    "slug": "jarvis-voice-agent",
    "navLabel": "JARVIS",
    "eyebrow": "JARVIS",
    "h1": "JARVIS: The Voice Agent for Mac That Acts on Your Apps",
    "metaTitle": "JARVIS Voice Agent for Mac, Verba",
    "metaDescription": "JARVIS is a voice agent for Mac that acts across 1,000+ apps like Gmail, Slack, and Notion. It plans, shows the steps, and only acts after you confirm.",
    "lead": "Most voice assistants on a Mac stop at a search box or a half-baked reminder. JARVIS, Verba's Action mode, is a real voice agent that plans the work, shows you exactly what it intends to do, and reaches into more than 1,000 connected apps to actually do it. You speak, it proposes, you confirm, it acts. No app left open, no copy-paste, no guessing what it ran.",
    "sections": [
      {
        "h2": "A voice assistant that acts on your apps, not just answers",
        "body": "JARVIS is built for getting things done across the tools you already live in. Hit Fn+X, say what you want in plain language, and it figures out which apps and actions the request needs, then carries them out for you. It is wired into 1,000+ apps through Composio, so the same spoken request can touch your inbox, your calendar, your project tracker, and your team chat in one go.",
        "bullets": [
          "Trigger Action mode anywhere with Fn+X, no app to switch to",
          "Acts across Gmail, Slack, Notion, Google Calendar, Linear, GitHub, and 1,000+ more",
          "Connected via Composio so coverage grows without a Verba update",
          "One spoken request can chain actions across several apps",
          "Works system-wide, wherever your cursor is"
        ]
      },
      {
        "h2": "Plan first, confirm, then act",
        "body": "JARVIS never fires off actions blindly. It plans the request, asks you to clarify when something is ambiguous, and lays out exactly what it is about to do before touching anything. Nothing happens until you confirm. That confirm-before-act loop is the whole point: you get the speed of an agent with the safety of a human in the loop, so an emailed draft or a created calendar event is always something you actually approved.",
        "bullets": [
          "Plans the steps and shows them before running",
          "Asks clarifying questions instead of guessing",
          "Acts only after you confirm",
          "You see every action it will take, in plain language"
        ]
      },
      {
        "h2": "Runs on the AI you control, with keys that stay server-side",
        "body": "The planning brain behind JARVIS is your own AI engine, the same bring-your-own setup the rest of Verba uses: your Claude subscription through Claude Code with no API key, your Anthropic key, OpenRouter, or a local model. Verba never makes a billed AI call on your behalf. And the credentials that connect your apps never land on your Mac. App connection keys are held server-side through Composio, so your laptop holds the conversation, not your Slack or Gmail tokens.",
        "bullets": [
          "Planning runs on your own AI engine, strictly bring-your-own",
          "Verba never makes a billed call for you",
          "App connection keys stay server-side, never on the Mac",
          "AI keys you do store live in the macOS Keychain"
        ]
      },
      {
        "h2": "From one sentence to a finished task",
        "body": "The strength of a voice agent is collapsing a multi-step chore into a single spoken sentence. Tell JARVIS to find the thread from your manager and draft a reply, to file a Linear issue from what you just described, or to put a block on your calendar and ping the team about it. It assembles the plan across the right apps, shows you the moves, and once you confirm, it does the work while you keep talking, typing, or thinking about the next thing."
      }
    ],
    "faq": [
      {
        "q": "What is JARVIS in Verba?",
        "a": "JARVIS is Verba's Action mode, a voice agent for Mac that you trigger with Fn+X. You speak a request, it plans the steps, shows you what it will do, and acts across more than 1,000 connected apps only after you confirm."
      },
      {
        "q": "Which apps can the voice agent act on?",
        "a": "JARVIS connects to over 1,000 apps through Composio, including Gmail, Slack, Notion, Google Calendar, Linear, and GitHub. One spoken request can chain actions across several of them at once."
      },
      {
        "q": "Does JARVIS act without asking me first?",
        "a": "No. JARVIS plans the request, asks clarifying questions when something is ambiguous, and shows exactly what it intends to do. It only acts after you confirm, so every action is one you approved."
      },
      {
        "q": "What AI runs JARVIS, and do I need an API key?",
        "a": "The planning runs on your own AI engine: your Claude subscription via Claude Code with no key, your Anthropic key, OpenRouter, or a local Ollama model. Verba is strictly bring-your-own-AI and never makes a billed call for you."
      },
      {
        "q": "Where are my app connection keys stored?",
        "a": "App connection keys stay server-side through Composio and never land on your Mac. Any AI keys you choose to store live in the macOS Keychain."
      }
    ]
  },
  {
    "slug": "dictation-modes",
    "navLabel": "Modes",
    "eyebrow": "DICTATION MODES",
    "h1": "AI Dictation Modes for Mac: Voice to Clean Text, Your Way",
    "metaTitle": "AI Dictation Modes for Mac, Verba",
    "metaDescription": "Verba's AI dictation modes turn voice into clean text on your Mac: Raw, Polish, Intent, Coding, plus custom modes and styles. Switch with Fn+1..9. BYO AI.",
    "lead": "Raw transcription is a solved problem. What you actually want is voice that lands as clean, finished text in whatever app you're in, formatted the way that moment needs it. Verba does that with dictation modes: pick Raw for verbatim, Polish to clean up your speech, Intent to write to an instruction, or Coding for code, then layer a style on top. Switch with Fn+1..9, and the AI cleanup runs on a model you control, never a billed call we make for you.",
    "sections": [
      {
        "h2": "What an AI dictation mode actually does",
        "body": "A mode is a recipe for turning your voice into text. It decides whether Verba transcribes you verbatim or sends the transcript through an AI cleanup pass, and it tells that AI what kind of output you want: a tidy sentence, a Slack reply, a commit message, a code snippet. Transcription happens on-device first (WhisperKit or NVIDIA Parakeet), so your audio never has to leave your Mac, and only the cleanup step touches the AI engine you've chosen. The result pastes straight into the app where your cursor is, system-wide. You're never copy-pasting out of a separate window.",
        "bullets": [
          "Transcribe on-device, then optionally clean up with AI you control",
          "Output is tailored per mode: verbatim, polished prose, an instruction's answer, or code",
          "Pastes at your cursor in any app, no separate window",
          "Cleanup runs on your Claude plan, your key, OpenRouter, or local Ollama"
        ]
      },
      {
        "h2": "The four core modes: Raw, Polish, Intent, Coding",
        "body": "Verba ships six built-in modes; these four are the ones you'll live in. Raw is pure speech-to-text with no AI, the fastest path when you just want your exact words down. Polish reads your transcript and resolves the way people really talk, the self-corrections, the false starts, the 'no wait, make that', and writes the version you meant. Intent treats your speech as a command and writes the thing you asked for, so you can say 'reply to this saying I'll be ten minutes late, keep it casual' and get the message, not a transcript of the request. Coding is tuned for code and technical text, preserving symbols, identifiers and structure instead of prose-ifying them.",
        "bullets": [
          "Raw: verbatim, no AI, instant",
          "Polish: resolves filler and self-corrections into clean prose",
          "Intent: write to an instruction, not a transcript of it",
          "Coding: keeps symbols, identifiers and structure intact",
          "(Plus Translate and Context, covered on their own pages)"
        ]
      },
      {
        "h2": "Custom modes and styles you build by talking",
        "body": "The six built-ins are a starting point, not a ceiling. You can have Verba build a custom mode for any recurring job, a standup-update mode, a customer-reply mode, a code-review-comment mode, with its own instructions and AI engine. On top of any mode you can layer a style: a lightweight modifier that shifts tone, length or format without changing the mode itself. Want the same Polish output but more concise, or more formal? Toggle a style. Modes change what gets written; styles change how it reads, and the two compose.",
        "bullets": [
          "Build custom modes for the jobs you repeat",
          "Styles layer on top of any mode to shift tone, length or format",
          "Modes and styles compose, so one mode covers many situations",
          "Each mode can route to a different AI engine you choose"
        ]
      },
      {
        "h2": "Switching modes and styles without breaking flow",
        "body": "The whole point is to never leave the keyboard. Fn+1 through Fn+9 jump straight to a mode, so going from dictating an email to dictating code is one keystroke. Fn+] and Fn+[ cycle styles on top of whatever mode you're in. Because switching is instant and lives under your fingers, you end up using the right mode for each task instead of forcing one generic setting to do everything, which is what makes the output feel finished rather than 'transcribed and then fixed by hand.'",
        "bullets": [
          "Fn+1..9 jumps directly to a mode",
          "Fn+] / Fn+[ cycles styles on top",
          "Instant, keyboard-only, system-wide",
          "Right mode per task instead of one generic setting"
        ]
      },
      {
        "h2": "You control the AI behind every mode",
        "body": "Verba is strictly bring-your-own-AI: it never makes a billed AI call on your behalf. Every mode that uses cleanup runs on an engine you pick, your Claude subscription through Claude Code with no key at all, your own Anthropic or OpenRouter key, or a fully local Ollama model so nothing leaves your Mac. Keys live in the macOS Keychain. That means a mode isn't just a prompt; it's a prompt plus the engine you trust to run it, and you can mix them, Polish on local Ollama, Intent on your Claude plan, whatever fits the work and your privacy bar.",
        "bullets": [
          "No markup, no billed-by-us calls, ever",
          "Your Claude plan (no key), Anthropic, OpenRouter, or local Ollama",
          "Keys stored in the macOS Keychain",
          "Run fully offline cleanup with a local model"
        ]
      }
    ],
    "faq": [
      {
        "q": "What are AI dictation modes in Verba?",
        "a": "Dictation modes are presets that turn your voice into the kind of text you want. Verba ships six built-in modes, including Raw (verbatim, no AI), Polish (cleans up filler and self-corrections), Intent (writes to a spoken instruction), and Coding (preserves code and symbols). You can also build custom modes and layer styles on top."
      },
      {
        "q": "What's the difference between Raw and Polish mode?",
        "a": "Raw is pure speech-to-text with no AI, giving you your exact words instantly. Polish runs your transcript through an AI cleanup pass that resolves false starts, filler, and self-corrections, writing the clean version you actually meant to say."
      },
      {
        "q": "How do I switch between dictation modes on Mac?",
        "a": "Press Fn+1 through Fn+9 to jump straight to a mode, and Fn+] or Fn+[ to cycle styles on top of the current mode. Switching is instant and keyboard-only, so you can move from dictating an email to dictating code without leaving the keyboard."
      },
      {
        "q": "Can I create my own custom dictation modes?",
        "a": "Yes. Verba can build a custom mode for any recurring task, with its own instructions and a choice of which AI engine runs it. You can also apply styles, lightweight modifiers that change tone, length, or format, on top of any built-in or custom mode."
      },
      {
        "q": "Which AI runs the dictation cleanup, and is it private?",
        "a": "You control it. Verba is bring-your-own-AI and never makes a billed call for you. Cleanup runs on your Claude subscription via Claude Code (no key), your Anthropic or OpenRouter key, or a fully local Ollama model. Transcription is on-device by default, so with a local model your voice and text never leave your Mac."
      }
    ]
  },
  {
    "slug": "voice-notes",
    "navLabel": "Voice Notes",
    "eyebrow": "NOTES",
    "h1": "Voice Notes App for Mac: Talk an Hour, Get a Clean Doc",
    "metaTitle": "Voice Notes App for Mac, Verba",
    "metaDescription": "Verba is a voice notes app for Mac. Dictate notes up to an hour, get a clean structured document, nest #tags, lock with a password, export .md or .txt.",
    "lead": "Open Verba, hit record, and just talk. You can ramble for up to an hour, and Verba turns the whole thing into a clean, structured document instead of a wall of raw transcript. It is the voice notes app for Mac that organizes what you said: choose a format, watch it render in Markdown, nest your hashtags into a tidy tree, and lock anything sensitive behind its own password.",
    "sections": [
      {
        "h2": "Dictate notes up to an hour, structured automatically",
        "body": "Most dictation tools hand you a paragraph blob. Verba is built for long-form thinking: record up to a full hour, then pick the shape you want and let your AI engine do the formatting. The transcription runs on-device (WhisperKit across roughly 99 languages, or NVIDIA Parakeet for 25), so your audio never leaves the Mac in on-device mode, and the cleanup runs on AI you control, never a billed call from us.",
        "bullets": [
          "Record up to 60 minutes per note",
          "On-device transcription, audio stays on your Mac",
          "Nine output formats so the structure matches your intent",
          "Markdown rendered inline, not raw text"
        ]
      },
      {
        "h2": "Nine note formats for whatever you just said",
        "body": "The same spoken brain-dump can become very different documents, so Verba lets you choose. Capture a messy idea and turn it into a clean outline, summarize a long thought, write up a meeting, draft an email, or spin a spoken list into a real to-do list. You speak once; the format decides how it lands on the page.",
        "bullets": [
          "Clean note and Brain-dump to outline",
          "Summary and Meeting notes",
          "Journal and Email",
          "Code task, To-do list, and Article outline"
        ]
      },
      {
        "h2": "Hashtag tags that nest into a Bear-style tree",
        "body": "Say a #hashtag while you talk and Verba files it for you. Tags nest into a Bear-style tree in the sidebar, so #work/clients/acme rolls up cleanly under #work, and you can browse months of voice notes by topic instead of scrolling. It is organization you do by speaking, with zero manual filing afterward."
      },
      {
        "h2": "Lock notes with a password and export anywhere",
        "body": "Some notes are private. Lock any individual note behind its own password, secured with AES-GCM and a per-note key, so a single locked entry stays sealed even on a shared device. When you want your words elsewhere, export to .md or .txt and drop them straight into Obsidian, a repo, an email, or anywhere Markdown lives. Your notes are yours to take.",
        "bullets": [
          "Per-note password, AES-GCM with a per-note key",
          "Export as Markdown (.md) or plain text (.txt)",
          "Text-only storage option, no audio kept",
          "Per-device authenticated sync across your Macs"
        ]
      }
    ],
    "faq": [
      {
        "q": "What is the best voice notes app for Mac?",
        "a": "Verba is a native macOS menu-bar voice notes app that lets you dictate notes up to an hour and get back a clean, structured document. Transcription runs on-device, and you choose from nine formats like meeting notes, summary, and outline."
      },
      {
        "q": "How long can a single voice note be in Verba?",
        "a": "You can record up to a full hour in one Verba voice note. It then transforms the entire recording into a structured document in the format you pick, rather than a raw transcript."
      },
      {
        "q": "Does Verba keep my audio when I dictate notes?",
        "a": "No. In on-device mode your audio never leaves the Mac, and Verba can store text only with no audio retained. You can also auto-delete history on a 7, 30, or 90 day schedule."
      },
      {
        "q": "Can I organize and lock voice notes in Verba?",
        "a": "Yes. Spoken #hashtags nest into a Bear-style tag tree for browsing by topic, and you can lock any individual note behind its own password using AES-GCM encryption with a per-note key."
      },
      {
        "q": "Can I export my voice notes out of Verba?",
        "a": "Yes. Every note exports to Markdown (.md) or plain text (.txt), so you can move it into Obsidian, a code repo, an email, or any other Markdown-friendly tool."
      }
    ]
  },
  {
    "slug": "voice-tasks",
    "navLabel": "Voice Tasks",
    "eyebrow": "TASKS",
    "h1": "Voice Task Manager for Mac: Add Tasks by Speaking",
    "metaTitle": "Voice Task Manager for Mac, Verba",
    "metaDescription": "Add tasks by voice on your Mac. Speak one request and Verba builds a project, tasks, and sub-tasks. Nested tags, an ⌥+Fn glance, fully BYO AI.",
    "lead": "Most task apps make you stop, click into a project, type a title, set a list, and indent sub-items by hand. Verba is a voice task manager for Mac that skips all of that: say what you need done and an AI agent turns one spoken request into a project with tasks and sub-tasks, already organized. It is the same menu-bar app you dictate with, so capturing work is never more than a hotkey away.",
    "sections": [
      {
        "h2": "Add tasks by voice, no typing",
        "body": "Press the hotkey, talk, done. Verba listens to a natural sentence and writes the task for you, system-wide, without opening a separate app or breaking your flow. Because transcription runs on-device with WhisperKit or Parakeet, your spoken to-dos never leave the Mac in on-device mode. Say a quick reminder or rattle off everything on your mind, and it lands as clean, ready-to-action items.",
        "bullets": [
          "Capture a task from anywhere with a single hotkey",
          "On-device transcription, around 99 languages with WhisperKit",
          "Speak one item or a full braindump in one go",
          "No form-filling, no manual list selection"
        ]
      },
      {
        "h2": "One request becomes a project, tasks, and sub-tasks",
        "body": "This is what sets Verba apart from a plain voice-to-text reminder. An AI agent reads your request and builds real structure: a project at the top, tasks beneath it, and sub-tasks under those, scoped from a single spoken brief. Say plan the product launch and you get a launch project with tasks for landing page, email, and announcement, each broken into the steps that get them done, instead of one flat line you still have to organize.",
        "bullets": [
          "Project to tasks to sub-tasks, built automatically",
          "Structure inferred from one natural-language request",
          "The agent does the breakdown, you just review",
          "Reorganize later by voice or by hand"
        ]
      },
      {
        "h2": "Nested tags and a one-glance view of today",
        "body": "Tags work like they do in Verba Notes: add a #hashtag and your tasks nest into a Bear-style tree, so personal, work, and side-project items stay sorted without rigid folders. When you need a fast pulse on the day, hit ⌥+Fn for a glance of today's tasks, no window-hunting, no context switch. Drill into a project when you want detail, or stay at the glance when you just need to know what's next.",
        "bullets": [
          "#hashtag tags that nest into a clean tree",
          "⌥+Fn for an instant glance of today's tasks",
          "Same tag system as Notes, so it feels familiar",
          "Filter and group without heavyweight project setup"
        ]
      },
      {
        "h2": "Runs on AI you control",
        "body": "The planning agent that breaks your request into a hierarchy runs on AI you choose, not a meter Verba bills you for. Point it at your Claude subscription through Claude Code with no key, your own Anthropic key, OpenRouter, or a fully local Ollama model. It is strictly bring-your-own-AI: Verba never makes a billed AI call on your behalf, and your keys live in the macOS Keychain. Want everything local? Pair on-device transcription with a local Ollama model and the whole flow stays on your machine."
      }
    ],
    "faq": [
      {
        "q": "Is Verba a voice task manager for Mac?",
        "a": "Yes. Verba is a native macOS menu-bar app that lets you add tasks by voice. You speak a request and an AI agent builds a project with tasks and sub-tasks, then organizes them with nested tags. It runs on macOS 14 or later on Apple Silicon."
      },
      {
        "q": "How do I add a task by voice in Verba?",
        "a": "Press the Verba hotkey, speak your task, and stop. Verba transcribes on-device and an AI agent turns what you said into structured tasks. There is no typing, no form, and no need to open a separate task window."
      },
      {
        "q": "Can Verba break one spoken request into sub-tasks?",
        "a": "Yes. From a single spoken request, Verba's agent builds a hierarchy: a project at the top, tasks beneath it, and sub-tasks under those. It infers the breakdown from your natural-language brief so you only review and adjust."
      },
      {
        "q": "Does Verba bill me for the AI that organizes my tasks?",
        "a": "No. Verba is strictly bring-your-own-AI and never makes a billed AI call for you. The planning agent runs on your Claude subscription via Claude Code, your Anthropic key, OpenRouter, or a local Ollama model, with keys stored in the macOS Keychain."
      },
      {
        "q": "How do I see today's tasks quickly?",
        "a": "Press ⌥+Fn for an instant glance of today's tasks, without hunting for a window. Tasks also nest under #hashtag tags into a Bear-style tree, so you can group work, personal, and project items without rigid folders."
      }
    ]
  },
  {
    "slug": "live-translation",
    "navLabel": "Live Translation",
    "eyebrow": "TRANSLATE MODE",
    "h1": "Live Voice Translation on Mac: Speak Any Language, It Writes Yours",
    "metaTitle": "Live Voice Translation on Mac, Verba",
    "metaDescription": "Dictate in another language on your Mac. Speak any of ~99 languages, Verba writes your target language and pastes it into any app. Pick a target once, talk.",
    "lead": "Verba's Translate mode turns your voice into finished text in the language you need. Pick a target language once, then speak whatever language is easiest for you, and Verba writes clean, native-sounding text right where your cursor is. It is live voice translation built into the Mac you already use, not another browser tab or app to switch into.",
    "sections": [
      {
        "h2": "Pick a target language once, then just talk",
        "body": "Translate mode flips the usual problem on its head. Instead of typing in a language you know and translating after, you speak in whatever language comes naturally and Verba writes the target. Set your target language one time in the mode, then dictate. You can talk in Spanish and get English in a Slack message, ramble in Tagalog and get a polished French email, or mix as you go. Verba transcribes your speech across roughly 99 languages on-device first, then rewrites it into your chosen target on the AI engine you control.",
        "bullets": [
          "Choose from 15 target languages to write into",
          "Speak any of ~99 recognized input languages",
          "Set the target once per mode, no per-sentence fiddling",
          "Switch to Translate with Fn plus its number, then start talking"
        ]
      },
      {
        "h2": "It translates the meaning, not word for word",
        "body": "Machine translation that goes phrase by phrase produces text that reads like a robot wrote it. Verba's Translate mode rewrites for intent, so the output sounds like a native speaker actually composed it. It preserves your tone, whether you were casual or formal, and protects the things literal translation usually mangles: proper names stay spelled correctly, numbers and dates stay intact, and code or technical terms pass through untouched instead of getting helpfully mistranslated.",
        "bullets": [
          "Keeps your tone, formal or casual",
          "Preserves proper names exactly as said",
          "Leaves numbers, dates, and code alone",
          "Reads like native text, not a phrasebook"
        ]
      },
      {
        "h2": "Where your voice and your translation actually run",
        "body": "Two stages, two clear privacy boundaries. The first stage, turning your speech into text, runs on-device with WhisperKit or NVIDIA Parakeet, so in on-device mode your audio never leaves the Mac. The second stage, rewriting that text into your target language, runs on the AI engine you bring: your Claude subscription through Claude Code with no key, your own Anthropic or OpenRouter key, or a fully local Ollama model. Verba never makes a billed AI call on your behalf. If you want the whole pipeline to stay on your machine, pair on-device transcription with a local Ollama model."
      },
      {
        "h2": "Pastes the translation straight into any app",
        "body": "The translated text lands wherever your cursor is, system-wide. There is no copy step, no intermediate window, no switching to a dedicated translation site and back. Reply to a customer in their language inside your email client, drop a translated note into Notion, answer a Slack thread in English while you think in Portuguese. Because Translate is a mode like the others, you switch into it with Fn plus a number and back out the same way, so live translation is one keystroke away in the middle of any workflow."
      },
      {
        "h2": "Built for people who think in one language and write in another",
        "body": "If your day involves more than one language, typing is the bottleneck. You know what you want to say, but composing it correctly in the other language is slow and second-guessed. Translate mode removes that friction: you speak the thought once and get correct, natural target-language text immediately. It is made for bilingual professionals, support and sales teams who answer in customers' languages, developers writing English commit messages from a non-English first language, and anyone tired of pasting between a translator and their real app."
      }
    ],
    "faq": [
      {
        "q": "How do I dictate in another language on my Mac with Verba?",
        "a": "Switch to Translate mode with Fn plus its number, then speak. Verba transcribes your speech in any of about 99 languages and writes it into the target language you set, pasting the result wherever your cursor is."
      },
      {
        "q": "Which languages can Verba translate my voice into?",
        "a": "Translate mode writes into 15 target languages. You can speak in any of roughly 99 languages that Verba's on-device transcription recognizes, and it will produce text in the one target you chose."
      },
      {
        "q": "Does my audio leave my Mac during live translation?",
        "a": "In on-device mode, no. Speech-to-text runs locally with WhisperKit or NVIDIA Parakeet, so audio never leaves the Mac. The rewrite into your target language runs on the AI engine you control, which can also be a fully local Ollama model."
      },
      {
        "q": "Does Verba translate word for word or by meaning?",
        "a": "By meaning. It rewrites for intent so the output reads like a native speaker wrote it, preserving your tone while keeping proper names, numbers, dates, and code intact."
      },
      {
        "q": "Can I use live translation inside other apps?",
        "a": "Yes. Translate mode pastes the target-language text wherever your cursor is, system-wide, so you can reply in email, Slack, Notion, or any app without switching to a separate translation tool."
      }
    ]
  },
  {
    "slug": "context-mode",
    "navLabel": "Context mode",
    "eyebrow": "CONTEXT MODE",
    "h1": "Screen-Aware Dictation for Mac: Reply to What You See by Voice",
    "metaTitle": "Context Mode: Screen-Aware Dictation Mac, Verba",
    "metaDescription": "Verba Context mode reads your Mac screen with a vision model and writes from it. Reply to the email or form on screen by voice, no copy-paste, no context.",
    "lead": "Most dictation hears your words but is blind to your screen, so you end up narrating context it should already see. Verba's Context mode (Fn+X) takes a screenshot, reads it with a vision model you control, and writes from what is actually in front of you. Say \"reply to this email\" or \"summarize this thread\" and Verba does it from the pixels, then pastes into the cursor.",
    "sections": [
      {
        "h2": "Screen-aware dictation that reads your Mac, not just your voice",
        "body": "Context mode is the only Verba mode that looks before it writes. When you trigger it, Verba captures your current screen, sends that image to a vision-capable model on the AI engine you chose, and uses what it sees as the source material for your spoken instruction. That means you can stop describing the email, the error, or the table on screen and just point at it with your voice. The result is pasted wherever your cursor sits, in any app.",
        "bullets": [
          "Captures the screen, then writes from it with a vision model",
          "Trigger with Fn+X, like every other Verba mode",
          "Say the instruction, not the context: \"reply to this\", \"explain this error\"",
          "Pastes the finished text into whatever app holds the cursor",
          "Runs on your own AI: Claude subscription, Anthropic key, OpenRouter, or local Ollama vision model"
        ]
      },
      {
        "h2": "Reply to what is on screen by voice",
        "body": "The everyday win is replying to things you can see but would rather not retype. Open an email and say \"reply, politely decline, suggest next week instead\" and Context mode reads the message, drafts the reply in your voice, and drops it in the compose box. Point it at a Slack thread, a support ticket, a code review comment, or a form, and it writes from the real content on screen instead of a vague mental summary you have to dictate first.",
        "bullets": [
          "Email replies that already know what the sender wrote",
          "Answers to a Slack or chat thread you have open",
          "Filling a form or field based on the data shown around it",
          "Explaining or rewriting an error, log, or stack trace on screen",
          "Summarizing a long article or document you are looking at"
        ]
      },
      {
        "h2": "What Context mode needs to see your screen",
        "body": "Because it reads pixels, Context mode has two requirements the verbatim modes do not. First, macOS Screen Recording permission, which Verba requests so it can capture the screenshot it sends to the model. Second, a vision-capable model on your AI engine, since a text-only model cannot read an image. Both Claude (via your subscription or Anthropic key) and many OpenRouter and Ollama models support vision; pick one of those for Context. Once granted, the screenshot goes only to the engine you configured for rewriting.",
        "bullets": [
          "Requires macOS Screen Recording permission to capture the screen",
          "Requires a vision-capable model on your chosen AI engine",
          "Works with Claude, Anthropic, OpenRouter, or a local vision model",
          "Bring-your-own-AI: Verba never makes a billed call on your behalf"
        ]
      },
      {
        "h2": "How Context mode differs from Verba's other modes",
        "body": "Raw and Polish only transcribe and clean what you say. Intent writes to an instruction but knows nothing about your screen. Translate converts language, and JARVIS (Fn+X's cousin, Action mode) takes real actions across connected apps after you confirm. Context sits between dictation and agent: it does not act on your behalf or touch other apps, it simply reads the screen and writes from it. If you want screen-aware writing without an agent doing anything, Context is the mode. Switch to it with Fn+1..9 like any other, and layer a style with Fn+]/[ if you want a particular tone."
      }
    ],
    "faq": [
      {
        "q": "What is Context mode in Verba?",
        "a": "Context mode is Verba's screen-aware dictation mode for Mac. When you trigger it with Fn+X, Verba screenshots your screen, reads it with a vision model on the AI engine you control, and writes from what it sees, then pastes the result into your cursor."
      },
      {
        "q": "Can Verba reply to an email by voice based on what is on screen?",
        "a": "Yes. With Context mode active, open the email and say something like \"reply and politely decline.\" Verba reads the message on screen with a vision model and drafts the reply for you, pasting it into the compose field. You never have to dictate what the email said."
      },
      {
        "q": "What permissions does Context mode need on macOS?",
        "a": "Context mode needs macOS Screen Recording permission so Verba can capture the screenshot it sends to the model, plus a vision-capable model on your chosen AI engine. Without a vision model, a text-only engine cannot read the image."
      },
      {
        "q": "Does my screen get sent to the cloud in Context mode?",
        "a": "The screenshot is sent only to the AI engine you configured for rewriting, which can be your Claude subscription, your Anthropic key, OpenRouter, or a fully local Ollama vision model. If you pick a local model, the image never leaves your Mac. Verba is bring-your-own-AI and never makes a billed call for you."
      },
      {
        "q": "How is Context mode different from JARVIS?",
        "a": "Context mode reads your screen and writes text from it, but it does not take actions in other apps. JARVIS (Action mode) plans and, after you confirm, acts across 1,000+ connected apps. Use Context for screen-aware writing and JARVIS when you want an agent to actually do something."
      }
    ]
  }
];

export function getFeature(slug: string): Feature | undefined {
  return FEATURES.find((f) => f.slug === slug);
}

// Top-nav "Features" dropdown.
export const FEATURE_NAV: { href: string; label: string; desc?: string }[] = [
  {
    "href": "/features/jarvis-voice-agent",
    "label": "JARVIS",
    "desc": "Voice agent for 1,000+ apps"
  },
  {
    "href": "/features/dictation-modes",
    "label": "Modes",
    "desc": "Raw, Polish, Intent, Coding"
  },
  {
    "href": "/features/voice-notes",
    "label": "Voice Notes",
    "desc": "Talk an hour, get a clean doc"
  },
  {
    "href": "/features/voice-tasks",
    "label": "Voice Tasks",
    "desc": "Build tasks by speaking"
  },
  {
    "href": "/features/live-translation",
    "label": "Live Translation",
    "desc": "Speak any language, write yours"
  },
  {
    "href": "/features/context-mode",
    "label": "Context mode",
    "desc": "Dictate from what's on screen"
  }
];

// Top-nav "Resources" dropdown.
export const RESOURCE_NAV: { href: string; label: string; desc?: string }[] = [
  { href: "/docs", label: "Documentation", desc: "Setup, modes, shortcuts, privacy" },
  { href: "/compare", label: "Compare", desc: "Verba vs every Mac dictation app" },
  { href: "/best-mac-dictation-app", label: "Best Mac dictation app", desc: "The 2026 ranking" },
  { href: "/changelog", label: "Changelog", desc: "Every release, shipped in public" },
  { href: "https://discord.gg/7xfkfQN9AR", label: "Community (Discord)", desc: "Join the Verba Discord" },
];
