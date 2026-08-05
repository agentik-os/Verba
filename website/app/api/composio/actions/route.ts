import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { fetchToolkitTools, toolPriority } from "@/lib/composio-rw";
import PHRASES from "@/lib/action-phrases.json";

export const runtime = "nodejs";
// A cold toolkit does a Composio fetch plus a phrase-generation call; the platform default would
// kill it mid-generation and the app would show a bare HTTP 504.
export const maxDuration = 60;

// GET /api/composio/actions?toolkit=GMAIL
//   -> { toolkit, actions: [{ slug, name, description, phrases:[...] }] }
//
// The actions a connected app exposes, each with example phrases the user can SPEAK to JARVIS to
// trigger it. Phrases come from the pre-generated dataset (lib/action-phrases.json) when present;
// otherwise they're generated once with a fast model and cached in-memory. Covers all ~600 apps —
// the popular ones are pre-baked, the long tail is lazy.
//
// AUTHENTICATED, despite being catalog metadata that leaks nothing. It spends the OWNER's
// COMPOSIO_API_KEY and ANTHROPIC_API_KEY on every cold toolkit, `/apps` publishes all ~989 slugs
// to drive it, and CORS is `*` — so an unauthenticated version was a bill anyone could run up from
// any web page, and a way to trip the shared Composio rate limit that /execute depends on. The
// macOS app is always signed in before it can open an app's action list.

const PHRASE_MAP = PHRASES as Record<string, { slug: string; phrases: string[] }[]>;

const MAX_ACTIONS = 60;
// Cap what one request may ask the model to write. Requesting 60 at once routinely exceeded the
// token budget and came back partial, and the partial slugs then re-triggered a full generation on
// every later request (see NEGATIVE CACHING below).
const MAX_GENERATED_PER_REQUEST = 25;

interface RawTool { slug: string; name?: string; description?: string }
interface ActionOut { slug: string; name: string; description: string; phrases: string[] }

// In-memory cache of lazily-generated phrases, keyed by toolkit (per warm server instance).
const liveCache = new Map<string, Record<string, string[]>>();
// NEGATIVE CACHING: slugs we already asked the model about and got nothing back for. Without this,
// any slug the model omitted (or every slug when the call failed) stayed "missing" forever and paid
// for a fresh Anthropic call on every single request to this toolkit, permanently.
const generationTried = new Map<string, Set<string>>();

async function rankedActions(composio: NonNullable<ReturnType<typeof getComposio>>, toolkit: string): Promise<RawTool[]> {
  // Shared with the planner catalog: same ranking, and the same 10-minute per-toolkit cache, so
  // browsing apps no longer issues an uncached Composio call per view.
  const raw = await fetchToolkitTools(composio as never, toolkit);
  return [...raw]
    .sort((a, b) => toolPriority(b.slug) - toolPriority(a.slug))
    .slice(0, MAX_ACTIONS)
    .map((t) => ({
      slug: t.slug,
      name: (t as { name?: string }).name ?? t.slug,
      description: (t.description ?? "").replace(/\n/g, " ").slice(0, 160),
    }));
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
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

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
  const tried = generationTried.get(toolkit) ?? new Set<string>();
  // Only ask about slugs we have neither phrases nor a previous attempt for, and only a bounded
  // number of them per request.
  const missing = actions
    .filter((a) => !(phraseBySlug[a.slug]?.length) && !tried.has(a.slug))
    .slice(0, MAX_GENERATED_PER_REQUEST);
  if (missing.length) {
    const gen = await generatePhrases(toolkit, missing);
    for (const [k, v] of Object.entries(gen)) if (v?.length) phraseBySlug[k] = v;
    liveCache.set(toolkit, { ...cached, ...gen });
    // Mark every slug we ASKED about, not just the ones that came back, so an omission or a failed
    // call costs one generation instead of one per request forever.
    for (const a of missing) tried.add(a.slug);
    generationTried.set(toolkit, tried);
  }

  const out: ActionOut[] = actions.map((a) => ({
    slug: a.slug,
    name: a.name ?? a.slug,
    description: a.description ?? "",
    phrases: phraseBySlug[a.slug] ?? [],
  }));
  return NextResponse.json({ toolkit, actions: out }, { headers: cors });
}
