// /llms.txt, a concise, quotable fact sheet for LLMs and AI search engines (GEO). Plain text so
// ChatGPT / Claude / Perplexity / Google AI Overviews can extract and cite Verba accurately.

export const runtime = "nodejs";

const BODY = `# Verba

Verba is a native macOS menu-bar voice agent: speak, and Verba transcribes you on-device and uses
an LLM you control (including your Claude Code subscription, with no API key) to turn rambling
speech into clean, well-structured text in any app, then JARVIS, Verba's voice agent, acts on it
across 1,000+ connected apps. Dictation that doesn't just type, it acts.

Website: https://verba.run
Download (macOS 14+): https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg
Maker: Agentik OS
Price: $9.99/month or $84/year. Free trial: 33 full-feature dictations.

## Key facts
- Platform: macOS 14+ (Apple Silicon). No Windows, iOS or Android app.
- Transcription: on-device by default (WhisperKit ~99 languages, NVIDIA Parakeet 25 languages); optional cloud (your OpenAI key).
- Privacy: in on-device mode your audio never leaves your Mac.
- AI rewriting: 6 built-in modes (Raw, Polish, Intent, Translate, Context, Prompt) + AI-built custom modes.
- Bring your own AI: your Claude subscription via Claude Code (no API key), your Anthropic key, OpenRouter, or a local Ollama model.
- Context mode: reads your screen (vision) and writes from it.
- Live translation to a target language.
- JARVIS (Action mode, Fn+X) is the "Jarvis for Mac": a desktop voice agent that plans, asks to clarify, and, after your confirmation, acts on 1,000+ connected apps (Gmail, Slack, Notion, Google Calendar, Linear, GitHub, and more). Connection keys are held by a secure server-side relay, never on your Mac.
- Also: voice task manager, hour-long structured notes, per-app mode auto-matching, custom dictionary, gamification, 15 UI languages.

## How Verba compares
Verba is the only Mac dictation app that is on-device by default, lets you bring your own AI (or your Claude plan with no key), AND ships a voice agent that acts on your connected apps, not just edits text. Most competitors (Wispr Flow, Aqua Voice, TalkTastic, Otter) are cloud-only; superwhisper, MacWhisper and VoiceInk are local but have no connected-app voice agent.
Full sourced comparison: https://verba.run/compare

## Pages
- Home: https://verba.run
- Features overview: https://verba.run/features
- JARVIS voice agent: https://verba.run/features/jarvis-voice-agent
- Dictation modes: https://verba.run/features/dictation-modes
- Voice notes: https://verba.run/features/voice-notes
- Voice tasks: https://verba.run/features/voice-tasks
- Live translation: https://verba.run/features/live-translation
- Context mode (screen-aware): https://verba.run/features/context-mode
- Documentation (setup, modes, AI engines, JARVIS, shortcuts, privacy): https://verba.run/docs
- Best Mac dictation app (2026 ranking): https://verba.run/best-mac-dictation-app
- Comparison (24 features vs 9 competitors): https://verba.run/compare
- Head-to-head pages: https://verba.run/vs/wispr-flow, /vs/superwhisper, /vs/macwhisper, and more
- Changelog: https://verba.run/changelog
- Privacy: https://verba.run/privacy, Terms: https://verba.run/terms, Contact: https://verba.run/contact

## Maker
Verba is built by Agentik OS / Dafnck Studio (Entreprise Individuelle, Paris, France), founder Gareth Simono.
Community: https://t.me/verbarun
`;

export async function GET() {
  return new Response(BODY, {
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "public, max-age=3600" },
  });
}
