import { NextResponse } from "next/server";

export const runtime = "nodejs";

// DEPRECATED / REMOVED: Verba's company-hosted AI rewriting endpoint.
//
// Product decision (2026-07): Verba never makes a billed AI call on your behalf. AI rewriting now
// runs ONLY on the user's own resources — their Claude Code subscription (local `claude` CLI, no
// key), their own API key (OpenAI / Anthropic / OpenRouter), or a fully-local Ollama model. There
// is no company-hosted / company-key backend anymore, so this route no longer proxies to any
// provider. It intentionally returns HTTP 410 Gone so any stale client fails fast with a clear
// message instead of silently hitting a dead path. (The Composio connected-apps relay, leaderboard,
// sync, feedback, and other endpoints are unaffected — those are unrelated to AI rewriting.)
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const GONE = {
  error:
    "Verba's hosted AI rewriting has been removed. Rewriting now runs on your own Claude Code plan, your own API key, or a fully-local model — configure it in Verba ▸ Settings ▸ AI rewriting.",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST() {
  return NextResponse.json(GONE, { status: 410, headers: cors });
}
