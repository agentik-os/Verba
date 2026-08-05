import { NextRequest, NextResponse } from "next/server";
import { cors, friendlyToolError, getComposio, notConfigured, requireUid, toolFailed, type ToolResult } from "../_lib";
import { isReadOnly, resolveToolMeta } from "@/lib/composio-rw";

export const runtime = "nodejs";
// JARVIS planning (2-phase Opus + Composio reads) + reprompting can run tens of seconds;
// without this Vercel kills the function at its default timeout → the app shows "took too long".
export const maxDuration = 300;

// POST { steps: [{ tool, args }] } -> { reads: [{tool, ok, error?}], block }
//
// Executes the READ-ONLY steps the on-device JARVIS planner requested, as the authenticated
// user. Mirrors the in-route auto-exec the server planner used: read-only gate (a write slug is
// refused, never run), hard cap, and the toolkit-version resolution Composio requires. `block`
// is the pre-formatted text the app feeds back to its local model for the resolve phase.

const MAX_READ_STEPS = 4;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function execTool(composio: any, slug: string, uid: string, args: Record<string, unknown>) {
  const { version } = await resolveToolMeta(composio, slug);
  return (await composio.tools.execute(slug, {
    userId: uid,
    arguments: args,
    ...(version ? { version } : {}),
  })) as ToolResult;
}

// Raw tool payloads are enormous (a calendar list repeats etag/htmlLink/iCalUID/creator/organizer/
// reminders on EVERY event; Gmail carries full MIME payloads). Feeding that to a LOCAL model (qwen3)
// for the resolve phase blew past its context and made simple asks ("what's my next event?") error.
// Compact structurally BEFORE stringifying: drop known-noise keys, cap list length, clip long strings.
// This keeps the meaningful fields (summary, start, end, subject, from, snippet, id) and makes the
// resolve phase both far faster and reliable on-device.
const NOISE_KEYS = new Set([
  "etag", "htmlLink", "iCalUID", "kind", "sequence", "updated", "created", "creator", "organizer",
  "reminders", "originalStartTime", "self", "accessRole", "defaultReminders", "nextPageToken",
  "nextSyncToken", "logId", "display_url", "eventType", "recurringEventId", "conferenceData",
  "extendedProperties", "hangoutLink", "colorId", "visibility", "transparency", "guestsCanModify",
  "guestsCanInviteOthers", "guestsCanSeeOtherGuests", "privateCopy", "locked", "source", "gadget",
  "anyoneCanAddSelf", "attendeesOmitted", "endTimeUnspecified", "attachments", "labelIds", "threadId",
  "historyId", "internalDate", "payload", "sizeEstimate", "raw", "note", "timeZone",
]);
const MAX_ITEMS = 30;
const MAX_STR = 500;
function compact(v: unknown): unknown {
  if (v === null || v === undefined) return undefined;
  if (typeof v === "string") return v.length > MAX_STR ? v.slice(0, MAX_STR) + "…" : v;
  if (typeof v !== "object") return v;
  if (Array.isArray(v)) {
    const out: unknown[] = v.slice(0, MAX_ITEMS).map(compact).filter((x) => x !== undefined);
    if (v.length > MAX_ITEMS) out.push(`…(+${v.length - MAX_ITEMS} more, not shown)`);
    return out;
  }
  const o: Record<string, unknown> = {};
  for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
    if (NOISE_KEYS.has(k)) continue;
    const c = compact(val);
    if (c === undefined || c === "" || (Array.isArray(c) && c.length === 0)) continue;
    o[k] = c;
  }
  return o;
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
  // SPEED: run the read steps CONCURRENTLY, not one-after-another. A multi-read plan ("check my
  // calendar AND my unread emails") used to wait for each round-trip in series; now total latency is
  // the slowest single read, not the sum. Order is preserved for the resolve block.
  const reads: { tool: string; ok: boolean; data?: unknown; error?: string }[] = await Promise.all(
    steps.map(async (step) => {
      const slug = (step?.tool ?? "").trim();
      if (!slug) return { tool: "", ok: false, error: "Empty tool." };
      if (!isReadOnly(slug)) return { tool: slug, ok: false, error: "Refused: not a read-only tool." };
      try {
        const result = await execTool(composio, slug, auth.uid, step.args ?? {});
        // A failed read RESOLVES with { successful:false, error } — it does not throw. Treating it
        // as data fed `{"data":{},"error":"invalid_grant","successful":false}` to the on-device
        // model under a prompt that says "list ONLY items present in the read block", so an auth
        // failure came back to the user as a confident "you have no unread emails".
        if (toolFailed(result)) {
          return { tool: slug, ok: false, error: friendlyToolError(result.error, slug) };
        }
        return { tool: slug, ok: true, data: result };
      } catch (e) {
        return { tool: slug, ok: false, error: friendlyToolError(e instanceof Error ? e.message : null, slug) };
      }
    }),
  );

  // Render each read result, capped — but NEVER cut mid-record silently (that seeds hallucinated
  // entries from dangling JSON). When over budget, truncate and append an explicit marker so the
  // resolve model knows the data is incomplete and must not invent the rest.
  const PER_READ = 9000;
  const block = reads
    .map((r) => {
      if (!r.ok) return `• ${r.tool}: ERROR ${r.error}`;
      const full = JSON.stringify(compact(r.data));
      if (full.length <= PER_READ) return `• ${r.tool}: ${full}`;
      return `• ${r.tool}: ${full.slice(0, PER_READ)}\n  …[TRUNCATED — the data above is incomplete; do NOT infer or invent any items beyond what is fully shown]`;
    })
    .join("\n");

  return NextResponse.json(
    { ok: true, block, reads: reads.map((r) => ({ tool: r.tool, ok: r.ok, error: r.error })) },
    { headers: cors }
  );
}
