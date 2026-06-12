import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { loadReadWriteCatalog, isReadOnly, type CatalogTool } from "@/lib/composio-rw";
import { plannerSystem } from "@/lib/planner-prompt";
import { rankByLexical, topMatches } from "@/lib/lexical";

export const runtime = "nodejs";

// VERBA GENIUS ACTION ASSISTANT — server-side agentic planner.
//
// POST { transcript, timezone?, locale?, shortcuts?, searchTargets?, disabled? }
//   -> { summary, classification, proposedWriteActions, clarification, announce, reads, ok }
//
// The relay is the only place that holds ANTHROPIC_API_KEY + COMPOSIO_API_KEY + the user's
// Composio entity (uid). It runs a two-phase loop on the company Anthropic key:
//   phase "plan"    — Claude classifies intent and may request READ-only Composio tools.
//   (auto-exec)     — the relay runs ONLY read-only tools (isReadOnly gate, fail-safe), capped.
//   phase "resolve" — Claude turns the read results into concrete proposedWriteActions.
// WRITE actions are NEVER executed here; they are returned for the app to confirm + run via
// the existing /api/composio/execute (composio) or local ActionExecutor (everything else).
//
// Mirrors reprompt/route.ts (direct Anthropic fetch, model allowlist) and execute/route.ts
// (requireUid auth + getComposio + cors) exactly — no new deps beyond @composio/core.

// claude-opus-4-8: 1M ctx, adaptive thinking. budget_tokens/temperature 400 on Opus 4.8, so
// neither is sent. Allowlist so a leaked token can't pick an arbitrary model.
const ALLOWED_MODELS = ["claude-opus-4-8"];
const PLANNER_MODEL = "claude-opus-4-8";
const MAX_READ_STEPS = 4; // hard cap on auto-run reads, matches the prompt's "Cap yourself at 4".

interface ReadStep {
  tool: string;
  args?: Record<string, unknown>;
}
interface ReadResult {
  tool: string;
  ok: boolean;
  data?: unknown;
  error?: string;
}
interface ProposedAction {
  kind?: string;
  label?: string;
  rationale?: string;
  action: Record<string, unknown>;
}
interface PlanJSON {
  summary?: string;
  classification?: string;
  needReads?: ReadStep[];
  proposedWriteActions?: ProposedAction[];
  clarification?: { question?: string; options?: { id?: string; label?: string }[] } | null;
  // When a chosen connected-app WRITE needs values the user didn't give (recipient, channel, …),
  // the planner asks for them with editable fields instead of guessing or failing.
  inputRequest?: {
    tool?: string;
    label?: string;
    prompt?: string;
    fields?: { key?: string; label?: string; placeholder?: string; value?: string; required?: boolean; multiline?: boolean }[];
  } | null;
  // An optional next step to offer after this action succeeds (e.g. "Invite people to the event?").
  followup?: { question?: string; intent?: string } | null;
  announce?: string;
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// --- Anthropic call: one completion, returns the parsed JSON object the planner emitted. ---
async function callPlanner(
  anthropicKey: string,
  system: string,
  messages: { role: "user" | "assistant"; content: string }[]
): Promise<{ ok: true; plan: PlanJSON } | { ok: false; status: number; error: string }> {
  let r: Response;
  try {
    r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: PLANNER_MODEL,
        max_tokens: 8000,
        system,
        messages,
      }),
    });
  } catch {
    return { ok: false, status: 502, error: "Planner request failed." };
  }
  const data = await r.json().catch(() => null);
  if (!r.ok) {
    return { ok: false, status: r.status, error: data?.error?.message ?? "Planner failed." };
  }
  const text: string = (data?.content ?? [])
    .filter((b: { type: string }) => b.type === "text")
    .map((b: { text: string }) => b.text)
    .join("")
    .trim();
  const plan = extractJSON(text);
  if (!plan) return { ok: false, status: 502, error: "Planner returned an unparseable plan." };
  return { ok: true, plan };
}

// Pull the first {...} object out of the reply (tolerates stray prose / a code fence).
function extractJSON(raw: string): PlanJSON | null {
  const s = raw.trim();
  const open = s.indexOf("{");
  const close = s.lastIndexOf("}");
  if (open < 0 || close < open) return null;
  try {
    return JSON.parse(s.slice(open, close + 1)) as PlanJSON;
  } catch {
    return null;
  }
}

// Build the {summary,classification,proposedWriteActions,clarification,announce} envelope the
// app expects. WRITE-only invariant is enforced here: any proposed action whose composio slug
// is read-only is dropped (a read should never be a "write to confirm"), and the loop never
// auto-executes a write.
function buildResponse(plan: PlanJSON, reads: ReadResult[]) {
  const proposed = (plan.proposedWriteActions ?? []).filter((p) => {
    const a = p?.action;
    if (!a || typeof a !== "object") return false;
    const type = String((a as Record<string, unknown>).type ?? (a as Record<string, unknown>).kind ?? "").toLowerCase();
    if (type === "composio" || type === "composio_tool" || type === "connected_app") {
      const slug = String((a as Record<string, unknown>).tool ?? (a as Record<string, unknown>).slug ?? "");
      // A read-only composio slug is never a confirmable write — drop it (fail-safe).
      if (isReadOnly(slug)) return false;
    }
    return true;
  });
  return {
    ok: true,
    summary: typeof plan.summary === "string" ? plan.summary : "",
    classification: typeof plan.classification === "string" ? plan.classification : "chat",
    proposedWriteActions: proposed,
    clarification: plan.clarification ?? null,
    inputRequest: plan.inputRequest ?? null,
    followup: plan.followup ?? null,
    announce: typeof plan.announce === "string" ? plan.announce : "",
    reads: reads.map((r) => ({ tool: r.tool, ok: r.ok, error: r.error })),
  };
}

// Composio's manual execution requires a CONCRETE toolkit version (it rejects calls with none:
// "Toolkit version not specified"). Resolve each tool's version by slug once, cache it per warm
// instance, and pass it on every read — same fix the /execute route uses for writes. Without this,
// EVERY auto-run read (Gmail fetch, Calendar list, Linear search, …) failed and the planner could
// never gather context.
const versionCache = new Map<string, string | undefined>();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function execTool(composio: any, slug: string, uid: string, args: Record<string, unknown>) {
  if (!versionCache.has(slug)) {
    let v: string | undefined;
    try {
      const raw = (await composio.tools.getRawComposioTools({ tools: [slug], limit: 1 })) as {
        slug: string;
        version?: string;
      }[];
      v = raw.find((t) => t.slug === slug)?.version ?? raw[0]?.version;
    } catch {
      v = undefined;
    }
    versionCache.set(slug, v);
  }
  const version = versionCache.get(slug);
  return composio.tools.execute(slug, { userId: uid, arguments: args, ...(version ? { version } : {}) });
}

export async function POST(req: NextRequest) {
  const anthropic = process.env.ANTHROPIC_API_KEY;
  if (!anthropic) {
    return NextResponse.json({ ok: false, error: "The action assistant isn't configured yet." }, { status: 503, headers: cors });
  }

  // Auth mirrors the relay: the verified token's uid IS the Composio entity.
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;
  const uid = auth.uid;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: {
    transcript?: string;
    timezone?: string;
    locale?: string;
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

  // Tolerate a Composio outage: an empty catalog still lets the planner do local Mac actions.
  let toolCatalog: CatalogTool[] = [];
  try {
    toolCatalog = await loadReadWriteCatalog(composio as never, uid, transcript);
  } catch {
    toolCatalog = [];
  }

  // Local, model-free retrieval (BM25): surface the actions most relevant to this request so JARVIS
  // finds the right tool fast — zero embeddings, zero tokens. Reorder the catalog (best matches
  // first) and pass the top matches to the prompt as an explicit shortlist.
  toolCatalog = rankByLexical(transcript, toolCatalog);
  const relevant = topMatches(transcript, toolCatalog, 10);
  // Full argument schemas for the most likely tools, so JARVIS emits exactly-valid arguments
  // (correct types, required fields, lists/objects as such) instead of guessing shapes.
  const relevantSet = new Set(relevant.length ? relevant : toolCatalog.slice(0, 8).map((t) => t.slug));
  const schemas = toolCatalog
    .filter((t) => relevantSet.has(t.slug) && t.schema)
    .map((t) => `${t.slug}(${t.schema})`);

  const ctxBase = {
    nowISO: new Date().toISOString(),
    timezone: typeof body.timezone === "string" && body.timezone ? body.timezone : "UTC",
    locale: typeof body.locale === "string" && body.locale ? body.locale : "en",
    toolCatalog,
    relevant,
    schemas,
    shortcuts: Array.isArray(body.shortcuts) ? body.shortcuts.filter((s) => typeof s === "string").slice(0, 120) : [],
    searchTargets: Array.isArray(body.searchTargets) ? body.searchTargets.filter((s) => typeof s === "string") : [],
    disabled: Array.isArray(body.disabled) ? body.disabled.filter((s) => typeof s === "string") : [],
  };

  const userMsg = `The user said:\n\n<command>\n${transcript}\n</command>`;

  // ---- PHASE 1: plan ----
  const plan1 = await callPlanner(anthropic, plannerSystem({ ...ctxBase, phase: "plan" }), [
    { role: "user", content: userMsg },
  ]);
  if (!plan1.ok) {
    return NextResponse.json({ ok: false, error: plan1.error }, { status: plan1.status, headers: cors });
  }

  let needReads = Array.isArray(plan1.plan.needReads) ? plan1.plan.needReads : [];
  // No reads requested → the plan is final (write actions or a clarification/chat).
  if (needReads.length === 0) {
    return NextResponse.json(buildResponse(plan1.plan, []), { headers: cors });
  }

  // ---- AUTO-EXEC: run ONLY read-only tools, capped. A non-read slug is refused, never run. ----
  needReads = needReads.slice(0, MAX_READ_STEPS);
  const reads: ReadResult[] = [];
  for (const step of needReads) {
    const slug = (step?.tool ?? "").trim();
    if (!slug) continue;
    if (!isReadOnly(slug)) {
      // Safety: the planner put a write in needReads. Refuse to auto-run it; record + skip.
      reads.push({ tool: slug, ok: false, error: "Refused: not a read-only tool." });
      continue;
    }
    try {
      const result = await execTool(composio, slug, uid, step.args ?? {});
      reads.push({ tool: slug, ok: true, data: result });
    } catch (e) {
      reads.push({ tool: slug, ok: false, error: e instanceof Error ? e.message : "Read failed." });
    }
  }

  // ---- PHASE 2: resolve — feed the read results back, ask for concrete write actions. ----
  const readBlock = reads
    .map((r) => `• ${r.tool}: ${r.ok ? JSON.stringify(r.data).slice(0, 6000) : `ERROR ${r.error}`}`)
    .join("\n");
  const resolveMsg = `${userMsg}\n\nREAD RESULTS (you requested these; use them to produce concrete proposedWriteActions, needReads MUST be []):\n${readBlock}`;

  const plan2 = await callPlanner(anthropic, plannerSystem({ ...ctxBase, phase: "resolve" }), [
    { role: "user", content: resolveMsg },
  ]);
  if (!plan2.ok) {
    // Degrade gracefully: return phase-1 summary so the user still gets feedback.
    return NextResponse.json(
      { ...buildResponse(plan1.plan, reads), error: plan2.error },
      { headers: cors }
    );
  }

  return NextResponse.json(buildResponse(plan2.plan, reads), { headers: cors });
}
