// Competitor dataset for the comparison pages. Facts verified mid-2026.
// Verba's positioning: native macOS, local-first transcription, BYO-AI-account
// (your Claude / OpenRouter / local model), AI restructuring, $9.99/mo.
//
// Single source of truth: the homepage CompareTable and the /compare and /vs
// pages all read prices and cells from here, so they can never drift apart.

export type Cell = { v: string; good?: boolean; bad?: boolean };

export type Competitor = {
  slug: string;
  name: string;
  tagline: string;
  platforms: string;
  price: string;
  priceNote?: string;
  transcription: string;
  onDevice: "yes" | "no" | "partial";
  aiEditing: string;
  privacy: string;
  strengths: string[];
  weaknesses: string[];
  // Why Verba wins, shown on the dedicated /vs page.
  verbaWins: string[];
  // Two or three places the competitor still has an edge (honesty builds trust).
  theirEdge: string[];
};

export const VERBA = {
  name: "Verba",
  price: "$9.99/mo",
  priceNote: "or $84/year · $149 one-time lifetime · unlimited raw dictation free forever",
  platforms: "macOS (Apple Silicon)",
  transcription: "On-device Whisper / Parakeet (or cloud, optional)",
  onDevice: "yes" as const,
  aiEditing: "Six built-in modes (Raw, Polish, Intent, Translate, Context, Prompt) plus AI-built custom modes, per-mode Claude models, voice commands",
  privacy: "On-device transcription keeps audio on your Mac. Text history is local, synced only when signed in, with an off switch and retention controls. Keys in Keychain.",
};

export const onDeviceLabel = (v: "yes" | "no" | "partial") =>
  v === "yes" ? "Yes" : v === "partial" ? "Partial" : "No";

export const competitors: Competitor[] = [
  {
    slug: "wispr-flow",
    name: "Wispr Flow",
    tagline: "The cloud incumbent everyone compares to, polished, but it uploads everything.",
    platforms: "Mac, Windows, iOS, Android",
    price: "$15/mo",
    priceNote: "$12/mo annual · free 2,000 words/week",
    transcription: "Cloud only",
    onDevice: "no",
    aiEditing: "Command Mode, auto-formatting, filler removal, self-correction",
    privacy: "Audio uploaded to the cloud on every dictation. Zero-retention mode exists but is OFF by default.",
    strengths: [
      "Very polished cross-platform experience (Mac, Windows, mobile)",
      "Strong AI formatting and command mode",
      "SOC 2 / ISO 27001 / HIPAA available for teams",
    ],
    weaknesses: [
      "Cloud-only, your voice always leaves your device",
      "$15/mo, the most expensive in the category",
      "Free tier capped at 2,000 words/week",
      "No offline mode at all",
    ],
    verbaWins: [
      "JARVIS: Verba doesn't just write text, it acts across 1,000+ apps (send the email, create the event), and always after you confirm. Wispr Flow only types.",
      "Private and acts and confirms: on-device transcription, real agentic actions, and a confirm-before-run gate. No rival holds all three.",
      "Verba transcribes on-device by default, so your audio stays on your Mac, even offline.",
      "$9.99/mo vs $15/mo, raw dictation is free forever and unlimited, no card, and a 7-day Pro trial unlocks every AI feature.",
      "Bring your own AI account (Claude Code / your keys), heavy users don't subsidize a vendor's GPU bill.",
    ],
    theirEdge: [
      "True cross-platform: Windows, iOS and Android apps today (Verba is macOS-only).",
      "Mobile dictation and cross-device sync are more mature.",
    ],
  },
  {
    slug: "talktastic",
    name: "TalkTastic",
    tagline: "AI dictation for Mac power users, free while it's in beta.",
    platforms: "macOS",
    price: "Free (beta)",
    priceNote: "no paid tier yet",
    transcription: "On-device Whisper; cloud for AI actions",
    onDevice: "partial",
    aiEditing: "AI rewriting, app-aware actions and commands",
    privacy: "Transcription runs on-device; AI actions are processed in the cloud.",
    strengths: [
      "Slick Mac-native dictation experience",
      "App-aware AI actions",
      "Free during the beta",
    ],
    weaknesses: [
      "Still in beta, feature set is evolving and there's no verified paid tier",
      "AI actions are processed in the cloud",
      "macOS-only",
    ],
    verbaWins: [
      "JARVIS: Verba plans and acts across 1,000+ apps, and always waits for your confirmation. Private, acts, and confirms, together.",
      "On-device transcription by default, and you can run the AI rewrite fully locally too.",
      "Bring your own AI account (Claude Code / keys), no vendor lock-in when the beta ends.",
      "A shipping, paid product with a stable roadmap: raw dictation free forever, Pro from $9.99/mo, or $149 lifetime.",
    ],
    theirEdge: [
      "Free while in beta.",
      "Mature app-aware action library and polished command set.",
    ],
  },
  {
    slug: "superwhisper",
    name: "Superwhisper",
    tagline: "Local-capable and loved, but it writes your audio to disk by default.",
    platforms: "macOS, Windows, iOS",
    price: "$8.49/mo",
    priceNote: "$84.99/yr · $249.99 lifetime",
    transcription: "Local Whisper + Parakeet; cloud optional",
    onDevice: "yes",
    aiEditing: "Custom prompt modes, bring-your-own cloud LLMs",
    privacy: "Local-first, but saves audio recordings to disk by default and stores API keys in plaintext.",
    strengths: [
      "Mature on-device transcription (Whisper + Parakeet)",
      "Lifetime option ($249.99)",
      "Custom prompt modes",
    ],
    weaknesses: [
      "Saves your audio to disk by default, with no easy opt-out",
      "API keys stored in plaintext",
      "Requires Input Monitoring permission",
    ],
    verbaWins: [
      "JARVIS acts across 1,000+ apps by voice (send the email, create the event) and always waits for your confirmation. superwhisper only writes text.",
      "Private, acts, and confirms, together: on-device transcription, real agentic actions, and a confirm-before-run gate no rival matches.",
      "Verba never stores your audio recordings; text history is local with an off switch and retention controls, and keys live in the macOS Keychain.",
      "First-class AI restructuring (your Claude plan / your own API key / a fully local model) with per-mode model routing, not just a prompt box.",
      "Verba also has a $149 one-time lifetime, plus raw dictation free forever.",
    ],
    theirEdge: [
      "Windows and iOS apps today (Verba is macOS-only).",
      "Longer track record with on-device model management.",
    ],
  },
  {
    slug: "macwhisper",
    name: "MacWhisper",
    tagline: "A great local transcription utility, but it's file-first, not type-anywhere.",
    platforms: "macOS (+ iOS sibling app)",
    price: "€59 / $99 lifetime",
    priceNote: "Gumroad Pro · App Store from $6.99/mo",
    transcription: "Local Whisper (whisper.cpp)",
    onDevice: "yes",
    aiEditing: "AI provider integrations, summaries (Pro)",
    privacy: "Fully local transcription, no cloud upload. Strong privacy.",
    strengths: [
      "Excellent for transcribing audio/video files",
      "Fully local, strong privacy",
      "One-time purchase option",
    ],
    weaknesses: [
      "Built around files/transcripts, not seamless type-anywhere dictation",
      "AI cleanup is secondary to transcription",
      "Less focused on the speak-and-paste workflow",
    ],
    verbaWins: [
      "Verba does the whole loop: live speak → polished → pasted-where-your-cursor-is dictation, agent actions, AND drag-drop transcription of audio/video files.",
      "AI restructuring (your Claude plan / your own API key / a fully local model) with modes and intent is the core, not an add-on.",
      "Auto-paste, voice-command formatting, and per-app mode matching out of the box.",
      "Verba also offers a $149 one-time lifetime, so a no-subscription option isn't MacWhisper's alone.",
    ],
    theirEdge: [
      "Specialized and best-in-class for batch transcribing large existing audio/video files.",
      "Cheaper one-time price if all you need is file transcription.",
    ],
  },
  {
    slug: "aqua-voice",
    name: "Aqua Voice",
    tagline: "Sharp natural-language editing, at the cost of being cloud-only.",
    platforms: "Mac, Windows, iOS",
    price: "~$8/mo",
    priceNote: "free 1,000-word lifetime cap",
    transcription: "Cloud (proprietary 'Avalon' model)",
    onDevice: "no",
    aiEditing: "Strong: natural-language editing, context/app-aware tone",
    privacy: "Cloud-first, no offline mode.",
    strengths: [
      "Excellent natural-language editing ('make a list', 'rephrase')",
      "Context- and app-aware tone",
      "Proprietary high-accuracy model",
    ],
    weaknesses: [
      "Cloud-only, no offline option",
      "Free tier is a tiny 1,000-word lifetime cap",
      "Your audio always leaves your device",
    ],
    verbaWins: [
      "JARVIS acts across 1,000+ apps by voice and always confirms first. Private, acts, and confirms, together. Aqua only edits text.",
      "On-device transcription keeps your audio private and works offline.",
      "Bring your own model: route each mode to the model you like.",
      "Raw dictation is free forever and unlimited, no card, with a 7-day Pro trial for every AI feature.",
    ],
    theirEdge: [
      "Aqua's proprietary Avalon model is very accurate.",
      "Cross-platform (Windows, iOS) today.",
    ],
  },
  {
    slug: "willow-voice",
    name: "Willow Voice",
    tagline: "Style-matching done well, but offline is opt-in and it's cloud by default.",
    platforms: "Mac, Windows, iOS, Android",
    price: "$12-15/mo",
    transcription: "Cloud (default)",
    onDevice: "partial",
    aiEditing: "AI Mode style-matching (tone per app/recipient), custom vocab",
    privacy: "Cloud-first by default; SOC 2 + HIPAA; offline is opt-in.",
    strengths: [
      "Good per-app / per-recipient style matching",
      "Cross-platform incl. mobile",
      "SOC 2 + HIPAA",
    ],
    weaknesses: [
      "Cloud by default; offline is opt-in",
      "$12-15/mo",
      "Custom vocab but no per-mode model control",
    ],
    verbaWins: [
      "JARVIS acts across 1,000+ apps by voice and always confirms first. Private, acts, and confirms, together. Willow only writes text.",
      "On-device is the default in Verba, not an opt-in.",
      "Cheaper at $9.99/mo, with raw dictation free forever and unlimited (no card) plus a 7-day Pro trial.",
      "Per-mode Claude models + intent mode give finer control than style presets.",
    ],
    theirEdge: [
      "Native mobile apps and cross-device sync.",
      "Enterprise compliance posture.",
    ],
  },
  {
    slug: "voiceink",
    name: "VoiceInk",
    tagline: "Open-source and private, but you're on your own for the AI-writing polish.",
    platforms: "macOS",
    price: "$25-49 one-time",
    priceNote: "free if built from source (GPLv3)",
    transcription: "Local Whisper + Parakeet",
    onDevice: "yes",
    aiEditing: "Power Mode (per-app config), personal dictionary, BYOK AI",
    privacy: "Fully local, open source. Very strong privacy.",
    strengths: [
      "Open source (GPLv3), fully local",
      "One-time price, no subscription",
      "Per-app power modes and personal dictionary",
    ],
    weaknesses: [
      "AI restructuring is BYOK and less polished out of the box",
      "macOS-only, community-driven support",
      "No managed sync / account",
    ],
    verbaWins: [
      "JARVIS acts across 1,000+ apps by voice and always confirms first. Private, acts, and confirms, together, none of which VoiceInk does.",
      "Verba's AI restructuring (your Claude plan / your own API key / a fully local model), intent mode and per-mode models are first-class and tuned.",
      "Polished native UX with auto-paste, voice commands and three indicator styles.",
      "Managed account and sync, no build-from-source needed. Raw dictation free forever, or a $149 one-time lifetime if you'd rather not subscribe.",
    ],
    theirEdge: [
      "Truly free and open source if you build it yourself.",
      "Cheaper one-time purchase ($25-49) if all you need is local dictation.",
    ],
  },
  {
    slug: "apple-dictation",
    name: "Apple Dictation",
    tagline: "Free and built in, but there's no AI cleanup at all.",
    platforms: "macOS, iOS (built-in)",
    price: "Free",
    transcription: "On-device (Apple Silicon) for many languages",
    onDevice: "yes",
    aiEditing: "None (basic punctuation only)",
    privacy: "On-device by default on modern hardware, but no HIPAA/BAA and some scenarios use Apple servers.",
    strengths: [
      "Free and built into macOS",
      "On-device for many languages",
      "Zero setup",
    ],
    weaknesses: [
      "No AI restructuring, raw transcript only",
      "No modes, no formatting commands, no intent",
      "Punctuation and ordering are left to you",
    ],
    verbaWins: [
      "Verba turns rambling speech into clean, structured, ready-to-send text, Apple Dictation just transcribes.",
      "Modes, intent, voice-command formatting and per-app routing.",
      "Still on-device and private, with the AI layer Apple doesn't offer.",
    ],
    theirEdge: [
      "Free and pre-installed.",
      "Deep OS integration across Apple devices.",
    ],
  },
  {
    slug: "otter-ai",
    name: "Otter.ai",
    tagline: "Built for meeting notes, not for typing into the app you're in.",
    platforms: "Web, iOS, Android, Mac",
    price: "$16.99/mo",
    priceNote: "free 300 min/mo · $8.33 annual",
    transcription: "Cloud",
    onDevice: "no",
    aiEditing: "Meeting summaries and AI chat (meeting-focused)",
    privacy: "Cloud upload; enterprise security on higher tiers.",
    strengths: [
      "Excellent meeting transcription and summaries",
      "Collaboration features",
      "Cross-platform",
    ],
    weaknesses: [
      "Not a type-anywhere dictation tool",
      "Cloud-only, $16.99/mo",
      "Overkill for quick dictation into apps",
    ],
    verbaWins: [
      "Verba dictates into whatever app your cursor is in, Otter is for recording meetings.",
      "On-device and private; no upload of your speech.",
      "Far cheaper for individual dictation.",
    ],
    theirEdge: [
      "Purpose-built for multi-speaker meetings and shared notes.",
      "Team collaboration workflows.",
    ],
  },
];

export const getCompetitor = (slug: string) => competitors.find((c) => c.slug === slug);

// --- Homepage head-to-head table (single source of truth) ---------------------
// The homepage CompareTable reads its columns and cells from here so prices and
// claims can never contradict the competitor records above. Prices are pulled
// straight from each competitor's `price` field; everything else is explicit.
type Cmp = boolean | string;

const priceOf = (slug: string) => getCompetitor(slug)?.price ?? "";

export const homeCompareCols = ["Verba", "Wispr Flow", "superwhisper", "Aqua"] as const;

// Rows: [label, [Verba, Wispr Flow, superwhisper, Aqua]]
export const homeCompareRows: [string, Cmp[]][] = [
  ["Dictate in any app", [true, true, true, true]],
  ["Runs fully offline", [true, false, true, false]],
  ["On-device, audio never uploaded", [true, false, true, false]],
  ["Bring your own AI key / no markup", [true, false, false, false]],
  ["Use Claude Code sub, no key", [true, false, false, false]],
  ["Reads your screen (vision)", [true, false, false, false]],
  ["Hour-long structured notes", [true, false, false, false]],
  ["Voice Task Manager (projects, sub-tasks, generated lists)", [true, false, false, false]],
  ["JARVIS voice agent, acts on 1,000+ apps", [true, false, false, false]],
  ["Send email / Slack / create events by voice", [true, false, false, false]],
  ["Asks to clarify & fills missing details", [true, false, false, false]],
  // 'limited': cloud-only command/editing modes can translate on request, but
  // there is no dedicated set-a-target-language Translate mode like Verba's.
  ["Live translation mode", [true, "limited", false, "limited"]],
  ["Agentic actions (email, Slack, calendar, 1,000+ apps)", [true, false, false, false]],
  ["Auto-learn your vocabulary & tone", [true, "partial", false, false]],
  ["Free tier", ["Unlimited raw, free forever", "limited", "trial", "limited"]],
  // Prices come straight from the competitor records so the table can't drift.
  ["Price / month", [VERBA.price.replace("/mo", ""), priceOf("wispr-flow").replace("/mo", ""), priceOf("superwhisper").replace("/mo", ""), priceOf("aqua-voice").replace("/mo", "")]],
];
