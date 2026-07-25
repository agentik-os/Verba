// /llms.txt, a concise, quotable fact sheet for LLMs and AI search engines (GEO). Plain text so
// ChatGPT / Claude / Perplexity / Google AI Overviews can extract and cite Verba accurately.

import { convexCall } from "@/lib/convex";

export const runtime = "nodejs";

// The blog section is generated from Convex, so an article published through the Outrank webhook
// becomes citable by AI engines within one revalidation window instead of at the next deploy.
export const revalidate = 300;

const HEAD = `# Verba

Verba is a native macOS menu-bar voice agent: speak, and Verba transcribes you on-device, privately,
turning rambling speech into clean, well-structured text in any app, then JARVIS, Verba's voice agent,
acts on it across 1,000+ connected apps. Dictation that doesn't just type, it acts.

Website: https://verba.run
Download (macOS 14+): https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg
Maker: Agentik OS
Price: Raw dictation is free forever (unlimited, no card). Pro is $9.99/month or $84/year, or a one-time $149 lifetime (Founder's Edition). Paid AI features include a 7-day trial.

## Key facts
- Platform: macOS 14+ (Apple Silicon). No Windows, iOS or Android app.
- Transcription: on-device by default, private, covering roughly 99 languages, with an optional faster mode for 25 European languages.
- Privacy: in on-device mode your audio never leaves your Mac.
- AI rewriting: 6 built-in modes (Raw, Polish, Intent, Translate, Context, Prompt) + AI-built custom modes.
- Private by design: everything runs on your Mac by default, and you can choose which AI engine powers the rewriting, always under your control.
- Context mode: reads your screen (vision) and writes from it.
- Live translation to a target language.
- JARVIS (Action mode, Fn+X) is the "Jarvis for Mac": a desktop voice agent that plans, asks to clarify, and, after your confirmation, acts on 1,000+ connected apps (Gmail, Slack, Notion, Google Calendar, Linear, GitHub, and more). Connection keys are held by a secure server-side relay, never on your Mac.
- Also: voice task manager, hour-long structured notes, per-app mode auto-matching, custom dictionary, gamification, 15 UI languages.

## How Verba compares
Verba is the only Mac dictation app that is on-device by default, keeps your data private, AND ships a voice agent that acts on your connected apps, not just edits text. Most competitors (Wispr Flow, Aqua Voice, TalkTastic, Otter) send your audio to their servers; superwhisper, MacWhisper and VoiceInk are local but have no connected-app voice agent.
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
- Blog (guides and deep dives): https://verba.run/blog
- Changelog: https://verba.run/changelog
- Privacy: https://verba.run/privacy, Terms: https://verba.run/terms, Contact: https://verba.run/contact
`;

const TAIL = `## Maker
Verba is built by Agentik OS / Dafnck Studio (Entreprise Individuelle, Paris, France), founder Gareth Simono.
Community: https://t.me/verbarun
`;

type Post = {
  slug: string;
  title: string;
  metaDescription: string | null;
  createdAt: string;
};

/** Every live article, one quotable line each, so an AI engine can cite the exact URL. */
async function blogSection(): Promise<string> {
  let posts: Post[] = [];
  try {
    posts = await convexCall<Post[]>("query", "blog:list", {});
  } catch {
    return "";
  }
  if (posts.length === 0) return "";
  const lines = posts.map((p) => {
    const date = (p.createdAt ?? "").slice(0, 10);
    const desc = p.metaDescription ? ` ${p.metaDescription}` : "";
    return `- ${p.title} (${date}): https://verba.run/blog/${p.slug}.${desc}`;
  });
  return `## Blog articles\n${lines.join("\n")}\n\n`;
}

export async function GET() {
  const body = `${HEAD}\n${await blogSection()}${TAIL}`;
  return new Response(body, {
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "public, max-age=3600" },
  });
}
