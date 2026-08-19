import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { loadReadWriteCatalog, type CatalogTool } from "@/lib/composio-rw";
import { plannerSystem } from "@/lib/planner-prompt";
import { rankByLexical, topMatches } from "@/lib/lexical";

export const runtime = "nodejs";
// This is the JARVIS hot path: EVERY utterance calls it, and loadReadWriteCatalog does one
// connectedAccounts.list plus up to two Composio calls per connected toolkit, in series. Ten
// connected apps on a cold cache is ~21 serial round-trips, far past Vercel's 10-15s default,
// which surfaced as "took too long" with no explanation. /agent carries the same guard for the
// same workload; this route was the only one on that path without it.
export const maxDuration = 60;

// POST { transcript, timezone?, locale?, nowISO?, shortcuts?, searchTargets?, disabled?,
//        capabilities? }
//   -> { systemPlan, systemResolve, schemas: { slug: inputParameters } }
//
// `capabilities` is the opt-in twin of `disabled`: extra action kinds THIS client executes itself,
// which the planner may therefore propose. The phone WILL declare ["create_task"] because it owns
// Verba's to-do list (VerbaMobile src/lib/jarvis.ts pushes to the same Convex `tasks` table the Mac
// reads); the Mac has no executor for that kind and must never be offered it. No client sends the
// field yet — the phone posts transcript/timezone/locale/nowISO/disabled here today
// (jarvis.ts runPlanByok) and appends the same contract text client-side instead.
//
// The field is read per REQUEST and not assumed from the route because this endpoint is the SHARED
// one: it is the Mac's ONLY planner path (Sources/Verba/ActionAgentClient.swift:333, which posts
// transcript/timezone/locale/nowISO/shortcuts/searchTargets/disabled and nothing else) and the
// phone's BYOK fallback. A client that does not send the field gets undefined, and plannerSystem
// emits the exact prompt it emits today.
//
// TODO(cross-repo) — this alone does NOT ship the feature, and the gap is deliberate scope, not an
// oversight. The phone's PRIMARY path is /api/composio/agent (jarvis.ts runPlan; that route is
// phone-exclusive, the macOS app never posts to it), and it does not read `capabilities`, so a
// healthy relay still cannot propose a to-do. Closing it takes the same two lines there plus the
// mobile declaring the capability on both posts and dropping its client-side append.
//
// The ON-DEVICE JARVIS planner's context: this route builds the full planner prompts (connected
// toolkit catalog + argument schemas + lexical shortlist) but makes NO model call — the Mac runs
// the planning LLM itself (the user's Claude Code subscription or their local model), so the
// server NEVER spends the owner's Anthropic API credits. The relay keeps only what must stay
// server-side: COMPOSIO_API_KEY and the user's entity.

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;
  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: {
    transcript?: string;
    timezone?: string;
    locale?: string;
    nowISO?: string;
    shortcuts?: string[];
    searchTargets?: string[];
    disabled?: string[];
    capabilities?: string[];
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }
  const transcript = (body.transcript ?? "").trim();
  if (!transcript) {
    return NextResponse.json({ ok: false, error: "Nothing to act on." }, { status: 400, headers: cors });
  }

  let toolCatalog: CatalogTool[] = [];
  try {
    toolCatalog = await loadReadWriteCatalog(composio as never, auth.uid, transcript);
  } catch {
    toolCatalog = []; // Composio outage → local Mac actions still plan fine
  }

  toolCatalog = rankByLexical(transcript, toolCatalog);
  const relevant = topMatches(transcript, toolCatalog, 10);
  const relevantSet = new Set(relevant.length ? relevant : toolCatalog.slice(0, 8).map((t) => t.slug));
  const schemaLines = toolCatalog.filter((t) => relevantSet.has(t.slug) && t.schema).map((t) => `${t.slug}(${t.schema})`);
  // Raw input schemas for client-side validation + repair of the proposed arguments.
  const schemas: Record<string, unknown> = {};
  for (const t of toolCatalog) if (relevantSet.has(t.slug) && t.ip) schemas[t.slug] = t.ip;

  const ctxBase = {
    nowISO: typeof body.nowISO === "string" && body.nowISO ? body.nowISO : new Date().toISOString(),
    timezone: typeof body.timezone === "string" && body.timezone ? body.timezone : "UTC",
    locale: typeof body.locale === "string" && body.locale ? body.locale : "en",
    toolCatalog,
    relevant,
    schemas: schemaLines,
    shortcuts: Array.isArray(body.shortcuts) ? body.shortcuts.filter((s) => typeof s === "string").slice(0, 120) : [],
    searchTargets: Array.isArray(body.searchTargets) ? body.searchTargets.filter((s) => typeof s === "string") : [],
    disabled: Array.isArray(body.disabled) ? body.disabled.filter((s) => typeof s === "string") : [],
    // Same string-only filter as the fields above, and capped like `shortcuts` is: the list is a
    // fixed vocabulary of a handful of names, so anything longer is a mistake or a probe, and
    // plannerSystem builds a Set from it once per phase. Left undefined rather than [] when the
    // client sent nothing, so an old build that never declares anything is indistinguishable from
    // the Mac. Unknown names are dropped by plannerSystem, the layer that owns what each one means.
    capabilities: Array.isArray(body.capabilities)
      ? body.capabilities.filter((s) => typeof s === "string").slice(0, 32)
      : undefined,
  };

  return NextResponse.json(
    {
      ok: true,
      systemPlan: plannerSystem({ ...ctxBase, phase: "plan" }),
      systemResolve: plannerSystem({ ...ctxBase, phase: "resolve" }),
      schemas,
    },
    { headers: cors }
  );
}
