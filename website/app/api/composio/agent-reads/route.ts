import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { isReadOnly } from "@/lib/composio-rw";

export const runtime = "nodejs";

// POST { steps: [{ tool, args }] } -> { reads: [{tool, ok, error?}], block }
//
// Executes the READ-ONLY steps the on-device JARVIS planner requested, as the authenticated
// user. Mirrors the in-route auto-exec the server planner used: read-only gate (a write slug is
// refused, never run), hard cap, and the toolkit-version resolution Composio requires. `block`
// is the pre-formatted text the app feeds back to its local model for the resolve phase.

const MAX_READ_STEPS = 4;

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

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;
  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: { steps?: { tool?: string; args?: Record<string, unknown> }[] };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }

  const steps = (Array.isArray(body.steps) ? body.steps : []).slice(0, MAX_READ_STEPS);
  const reads: { tool: string; ok: boolean; data?: unknown; error?: string }[] = [];
  for (const step of steps) {
    const slug = (step?.tool ?? "").trim();
    if (!slug) continue;
    if (!isReadOnly(slug)) {
      reads.push({ tool: slug, ok: false, error: "Refused: not a read-only tool." });
      continue;
    }
    try {
      const result = await execTool(composio, slug, auth.uid, step.args ?? {});
      reads.push({ tool: slug, ok: true, data: result });
    } catch (e) {
      reads.push({ tool: slug, ok: false, error: e instanceof Error ? e.message : "Read failed." });
    }
  }

  const block = reads
    .map((r) => `• ${r.tool}: ${r.ok ? JSON.stringify(r.data).slice(0, 6000) : `ERROR ${r.error}`}`)
    .join("\n");

  return NextResponse.json(
    { ok: true, block, reads: reads.map((r) => ({ tool: r.tool, ok: r.ok, error: r.error })) },
    { headers: cors }
  );
}
