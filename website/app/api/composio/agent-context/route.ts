import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { loadReadWriteCatalog, type CatalogTool } from "@/lib/composio-rw";
import { plannerSystem } from "@/lib/planner-prompt";
import { rankByLexical, topMatches } from "@/lib/lexical";

export const runtime = "nodejs";

// POST { transcript, timezone?, locale?, nowISO?, shortcuts?, searchTargets?, disabled? }
//   -> { systemPlan, systemResolve, schemas: { slug: inputParameters } }
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
