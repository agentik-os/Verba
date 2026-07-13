import { NextRequest, NextResponse } from "next/server";
import { convexBump, convexCall } from "@/lib/convex";

export const runtime = "nodejs";

// Receives AUTOMATIC error/crash reports from the macOS app and files DEDUPED Linear issues in the
// Verba team's Feedback project. One issue per distinct error signature: the first occurrence creates
// it; later occurrences bump a Convex counter and only add a Linear comment when a NEW app version
// hits the same error (so we can see whether a shipped fix actually stopped it). The LINEAR_API_KEY is
// read server-side only — the app never holds it. Rate-limited globally so a crash-loop can't flood.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const LINEAR_URL = "https://api.linear.app/graphql";
const TEAM_ID = "16e9d4a0-b7ca-4463-ab8a-a024a4049ba1";
const PROJECT_ID = "02a68254-e055-49c0-8d91-4e97af001e83";
const BACKLOG_STATE_ID = "fb9524bf-9b3c-433a-ac87-49069f7523f1";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

type Body = {
  kind?: string;       // "error" | "crash"
  message?: string;    // already sanitized client-side; we clamp + re-sanitize defensively
  signature?: string;  // stable hash from the client; we recompute-guard length
  version?: string;
  os?: string;
  context?: Record<string, string>;
  uid?: string;
};

async function linear<T>(key: string, query: string, variables: Record<string, unknown>): Promise<T> {
  const r = await fetch(LINEAR_URL, {
    method: "POST",
    headers: { Authorization: key, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await r.json();
  if (!r.ok || json.errors) {
    throw new Error(json?.errors?.[0]?.message ?? `Linear request failed (${r.status})`);
  }
  return json.data as T;
}

// Defensive server-side redaction (the client already sanitizes): strip home paths + emails so no
// PII reaches Linear even if a future client forgets to.
function sanitize(s: string): string {
  return s
    .replace(/\/Users\/[^/\s]+/g, "/Users/~")
    .replace(/[\w.+-]+@[\w-]+\.[\w.-]+/g, "<email>")
    .slice(0, 3000);
}

export async function POST(req: NextRequest) {
  const key = process.env.LINEAR_API_KEY;
  if (!key) return NextResponse.json({ ok: false, error: "not configured" }, { status: 503, headers: cors });

  let body: Body;
  try { body = (await req.json()) as Body; } catch { return NextResponse.json({ ok: false }, { status: 400, headers: cors }); }

  const message = sanitize((body.message ?? "").trim());
  const signature = (body.signature ?? "").trim().slice(0, 128);
  const kind = (body.kind ?? "error").slice(0, 16);
  if (!message || !signature) {
    return NextResponse.json({ ok: false, error: "message and signature required" }, { status: 400, headers: cors });
  }

  // Global rate limit: cap total auto-reports/day so a widespread crash-loop can't flood Linear/Convex.
  const day = new Date().toISOString().slice(0, 10);
  const ok = await convexBump(`diag:global:${day}`, 5000, true /* fail-open: never lose a real crash to a limiter blip */);
  if (!ok) return NextResponse.json({ ok: true, throttled: true }, { headers: cors });

  const context = body.context ? JSON.stringify(body.context).slice(0, 1500) : undefined;

  // 1) Durable, deduped Convex record FIRST (so a Linear outage never loses the signal).
  let rec: { isNew: boolean; seenNewVersion: boolean; count: number; linearId: string | null };
  try {
    rec = await convexCall("mutation", "diagnostics:record", {
      serverKey: process.env.APP_TOKEN_SECRET,
      signature, kind, message, version: body.version, os: body.os, context, uid: body.uid,
    });
  } catch (e) {
    return NextResponse.json({ ok: false, error: "record failed" }, { status: 502, headers: cors });
  }

  // 2) Linear: create the issue on first sight; comment on a version-regression; stay silent otherwise.
  try {
    if (rec.isNew) {
      const emoji = kind === "crash" ? "💥" : "🐛";
      const title = `${emoji} [auto] ${message.split("\n")[0].slice(0, 120)}`;
      const description =
        `**Automatic ${kind} report** from the Verba macOS app.\n\n` +
        "```\n" + message + "\n```\n\n" +
        `**Signature:** \`${signature}\`\n` +
        `**First seen:** ${body.version ? `v${body.version}` : "?"} · ${body.os ?? "?"}\n` +
        (context ? `**Context:** \`${context}\`\n` : "") +
        `\n_This issue auto-updates: repeats bump a counter, and a comment is added when a new app version still hits it._`;
      const data = await linear<{ issueCreate: { success: boolean; issue: { id: string; url: string } | null } }>(
        key,
        `mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success issue { id url } } }`,
        { i: { teamId: TEAM_ID, projectId: PROJECT_ID, stateId: BACKLOG_STATE_ID, title, description, priority: kind === "crash" ? 1 : 3 } }
      );
      const issue = data.issueCreate?.issue;
      if (issue) {
        await convexCall("mutation", "diagnostics:attachLinear", {
          serverKey: process.env.APP_TOKEN_SECRET, signature, linearId: issue.id, linearUrl: issue.url,
        }).catch(() => {});
        return NextResponse.json({ ok: true, url: issue.url, created: true }, { headers: cors });
      }
    } else if (rec.seenNewVersion && rec.linearId) {
      await linear(
        key,
        `mutation($i:CommentCreateInput!){ commentCreate(input:$i){ success } }`,
        { i: { issueId: rec.linearId, body: `⚠️ Still occurring in **v${body.version ?? "?"}** (${body.os ?? "?"}). Total reports: ${rec.count}.` } }
      );
    }
  } catch {
    // Linear failed but Convex has it durably — report success so the client never retries a flood.
    return NextResponse.json({ ok: true, recorded: true }, { headers: cors });
  }

  return NextResponse.json({ ok: true, count: rec.count }, { headers: cors });
}
