import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured } from "../_lib";
import PHRASES from "@/lib/action-phrases.json";

export const runtime = "nodejs";

// GET /api/composio/actions?toolkit=GMAIL
//   -> { toolkit, actions: [{ slug, name, description, phrases:[...] }] }
//
// The actions a connected app exposes, each with example phrases the user can SPEAK to JARVIS to
// trigger it. Public (catalog metadata, no user data). Phrases come from the pre-generated dataset
// (lib/action-phrases.json) when present; otherwise they're generated once with a fast model and
// cached in-memory. Covers all ~600 apps — the popular ones are pre-baked, the long tail is lazy.

const PHRASE_MAP = PHRASES as Record<string, { slug: string; phrases: string[] }[]>;

// Rank actions so the high-value ones (send/reply/create/fetch) lead, matching the planner catalog.
function actionPriority(slug: string): number {
  const s = (slug ?? "").toUpperCase();
  if (/(?:^|_)(SEND|REPLY|FORWARD)(?:_|$)/.test(s)) return 100;
  if (/(?:^|_)(CREATE|ADD|POST|UPDATE|EDIT|MODIFY|SET|INVITE|SHARE|UPLOAD|ASSIGN|RSVP|SCHEDULE)(?:_|$)/.test(s)) return 80;
  if (/(?:^|_)(FETCH|SEARCH|LIST|GET|FIND|RETRIEVE|READ|QUERY)(?:_|$)/.test(s)) return 60;
  if (/(?:^|_)(DELETE|REMOVE|TRASH|ARCHIVE|REVOKE|BATCH)(?:_|$)/.test(s)) return 10;
  return 30;
}

interface RawTool { slug: string; name?: string; description?: string }
interface ActionOut { slug: string; name: string; description: string; phrases: string[] }

// In-memory cache of lazily-generated phrases, keyed by toolkit (per warm server instance).
const liveCache = new Map<string, Record<string, string[]>>();

async function rankedActions(composio: ReturnType<typeof getComposio>, toolkit: string): Promise<RawTool[]> {
  const raw = (await composio!.tools.getRawComposioTools({ toolkits: [toolkit], limit: 50 } as never)) as RawTool[];
  return [...raw]
    .sort((a, b) => actionPriority(b.slug) - actionPriority(a.slug))
    .slice(0, 24)
    .map((t) => ({ slug: t.slug, name: t.name ?? t.slug, description: (t.description ?? "").replace(/\n/g, " ").slice(0, 160) }));
}

// One fast model call to draft 1-2 spoken phrases per action. Best-effort: returns {} on any error.
async function generatePhrases(toolkit: string, actions: RawTool[]): Promise<Record<string, string[]>> {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) return {};
  const list = actions.map((a) => `${a.slug}: ${a.description}`).join("\n");
  const system =
    "You write example VOICE COMMANDS a user speaks to JARVIS to trigger a connected-app action. " +
    "For each action slug, return 1-2 short, natural, imperative English phrases a real person would say, specific to what the action does. " +
    'Reply with ONLY a JSON object mapping slug -> array of phrases, no prose, no code fence.';
  try {
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01" },
      body: JSON.stringify({
        model: "claude-haiku-4-5",
        max_tokens: 4000,
        system,
        messages: [{ role: "user", content: `App ${toolkit}. Actions:\n${list}` }],
      }),
    });
    if (!r.ok) return {};
    const data = await r.json();
    const text = (data?.content?.[0]?.text ?? "").trim().replace(/^```json?/, "").replace(/```$/, "");
    const parsed = JSON.parse(text) as Record<string, unknown>;
    const out: Record<string, string[]> = {};
    for (const [k, v] of Object.entries(parsed)) {
      if (Array.isArray(v)) out[k] = v.filter((x) => typeof x === "string").slice(0, 2);
    }
    return out;
  } catch {
    return {};
  }
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const toolkit = (new URL(req.url).searchParams.get("toolkit") ?? "").toUpperCase().trim();
  if (!toolkit) return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });

  const composio = getComposio();
  if (!composio) return notConfigured();

  let actions: RawTool[];
  try {
    actions = await rankedActions(composio, toolkit);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to list actions.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
  if (!actions.length) return NextResponse.json({ toolkit, actions: [] }, { headers: cors });

  // Phrase source: seed from the pre-generated dataset + the in-memory cache, then LIVE-GENERATE
  // any action still missing phrases so EVERY shown action always has example phrases — the dataset
  // only covers part of each app, so without this gap-fill most actions showed a bare description.
  const phraseBySlug: Record<string, string[]> = {};
  for (const a of PHRASE_MAP[toolkit] ?? []) {
    if (a.phrases?.length) phraseBySlug[a.slug] = a.phrases;
  }
  const cached = liveCache.get(toolkit) ?? {};
  for (const [k, v] of Object.entries(cached)) {
    if (v?.length && !phraseBySlug[k]?.length) phraseBySlug[k] = v;
  }
  const missing = actions.filter((a) => !(phraseBySlug[a.slug]?.length));
  if (missing.length) {
    const gen = await generatePhrases(toolkit, missing);
    for (const [k, v] of Object.entries(gen)) if (v?.length) phraseBySlug[k] = v;
    liveCache.set(toolkit, { ...cached, ...gen });
  }

  const out: ActionOut[] = actions.map((a) => ({
    slug: a.slug,
    name: a.name ?? a.slug,
    description: a.description ?? "",
    phrases: phraseBySlug[a.slug] ?? [],
  }));
  return NextResponse.json({ toolkit, actions: out }, { headers: cors });
}
