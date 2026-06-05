// Competitor dataset for the comparison pages. Facts verified mid-2026.
// Verba's positioning: native macOS, local-first transcription, BYO-AI-account
// (Claude Code / OpenRouter / keys), Claude restructuring, $9.99/mo.

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
  priceNote: "or $84/year · free tier 10,000 words/mo",
  platforms: "macOS (Apple Silicon)",
  transcription: "On-device Whisper / Parakeet (or cloud, optional)",
  onDevice: "yes" as const,
  aiEditing: "Claude restructuring, per-mode models, intent mode, voice commands",
  privacy: "Local-first: audio never leaves your Mac, nothing saved to disk, keys in Keychain",
};

export const onDeviceLabel = (v: "yes" | "no" | "partial") =>
  v === "yes" ? "Yes" : v === "partial" ? "Partial" : "No";

export const competitors: Competitor[] = [
  {
    slug: "wispr-flow",
    name: "Wispr Flow",
    tagline: "The cloud incumbent everyone compares to — polished, but it uploads everything.",
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
      "Cloud-only — your voice always leaves your device",
      "$15/mo, the most expensive in the category",
      "Free tier capped at 2,000 words/week",
      "No offline mode at all",
    ],
    verbaWins: [
      "Verba transcribes on-device by default — your audio never leaves your Mac, even offline.",
      "$9.99/mo vs $15/mo, and a far roomier 10,000 words/month free tier.",
      "Bring your own AI account (Claude Code / your keys) — heavy users don't subsidize a vendor's GPU bill.",
      "Per-mode models: Opus for coding prompts, Haiku for quick polish — you control cost and quality.",
    ],
    theirEdge: [
      "True cross-platform: Windows, iOS and Android apps today (Verba is macOS-only).",
      "Mobile dictation and cross-device sync are more mature.",
    ],
  },
  {
    slug: "superwhisper",
    name: "Superwhisper",
    tagline: "Local-capable and loved — but it writes your audio to disk by default.",
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
      "Verba never writes your audio to disk and stores keys in the macOS Keychain.",
      "First-class Claude restructuring with per-mode model routing, not just a prompt box.",
      "Intent mode: say how you want the rest handled and Verba does exactly that.",
      "Native menu-bar app tuned for instant Fn-key dictation and auto-paste.",
    ],
    theirEdge: [
      "Windows and iOS apps; a lifetime purchase option.",
      "Longer track record with on-device model management.",
    ],
  },
  {
    slug: "macwhisper",
    name: "MacWhisper",
    tagline: "A great local transcription utility — but it's file-first, not type-anywhere.",
    platforms: "macOS (+ iOS sibling app)",
    price: "~$69 lifetime",
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
      "Verba is built for the speak → polished → pasted-where-your-cursor-is flow, not file transcription.",
      "Claude restructuring with modes and intent is the core, not an add-on.",
      "Auto-paste, voice-command formatting, and per-app mode matching out of the box.",
    ],
    theirEdge: [
      "Best-in-class for batch transcribing existing audio/video files.",
      "One-time pricing appeals if you don't want a subscription.",
    ],
  },
  {
    slug: "aqua-voice",
    name: "Aqua Voice",
    tagline: "Sharp natural-language editing — at the cost of being cloud-only.",
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
      "On-device transcription keeps your audio private and works offline.",
      "Bring your own model: route modes to Haiku, Sonnet or Opus as you like.",
      "10,000 free words every month, not a one-time 1,000-word trial.",
    ],
    theirEdge: [
      "Aqua's proprietary Avalon model is very accurate.",
      "Cross-platform (Windows, iOS) today.",
    ],
  },
  {
    slug: "willow-voice",
    name: "Willow Voice",
    tagline: "Style-matching done well — but offline is locked behind Pro and it's cloud by default.",
    platforms: "Mac, Windows, iOS, Android",
    price: "$12–15/mo",
    transcription: "Cloud (default)",
    onDevice: "partial",
    aiEditing: "AI Mode style-matching (tone per app/recipient), custom vocab",
    privacy: "Cloud-first by default; SOC 2 + HIPAA; offline is opt-in and Pro-only.",
    strengths: [
      "Good per-app / per-recipient style matching",
      "Cross-platform incl. mobile",
      "SOC 2 + HIPAA",
    ],
    weaknesses: [
      "Cloud by default; offline only on Pro",
      "$12–15/mo",
      "Custom vocab but no per-mode model control",
    ],
    verbaWins: [
      "On-device is the default in Verba, not a paid upgrade.",
      "Cheaper at $9.99/mo with a 10,000-word free tier.",
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
    tagline: "Open-source and private — but you're on your own for the AI-writing polish.",
    platforms: "macOS",
    price: "$25–49 one-time",
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
      "Verba's Claude restructuring, intent mode and per-mode models are first-class and tuned.",
      "Polished native UX with auto-paste, voice commands and three indicator styles.",
      "Managed account, sync and a 7-day Pro trial — no build-from-source needed.",
    ],
    theirEdge: [
      "Truly free and open source if you build it yourself.",
      "One-time purchase, no recurring cost.",
    ],
  },
  {
    slug: "apple-dictation",
    name: "Apple Dictation",
    tagline: "Free and built in — but there's no AI cleanup at all.",
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
      "No AI restructuring — raw transcript only",
      "No modes, no formatting commands, no intent",
      "Punctuation and ordering are left to you",
    ],
    verbaWins: [
      "Verba turns rambling speech into clean, structured, ready-to-send text — Apple Dictation just transcribes.",
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
      "Verba dictates into whatever app your cursor is in — Otter is for recording meetings.",
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
