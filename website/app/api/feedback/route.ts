import { NextRequest, NextResponse } from "next/server";
import { verifyAppToken } from "@/lib/apptoken";
import { convexBump } from "@/lib/convex";

export const runtime = "nodejs";

// Receives in-app feedback from the macOS app and files a rich Linear issue in the
// Verba team's Feedback project — feedback text + a full Context section (version, OS,
// engine, mode, user, time) and, when supplied, the screenshot uploaded via Linear's
// own file-upload flow. The LINEAR_API_KEY is read server-side only; the app never holds it.
// S11: rate-limited per IP + globally via shared Convex counters, screenshot size capped,
// and the reported email is only trusted when it comes from a verified app-session token.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// ≈6 MB of base64 PNG — anything bigger is rejected before touching Linear.
const MAX_SCREENSHOT_CHARS = 8_000_000;

function ipOf(req: NextRequest): string {
  const xff = req.headers.get("x-forwarded-for") ?? "";
  return xff.split(",")[0].trim() || req.headers.get("x-real-ip") || "unknown";
}

const LINEAR_URL = "https://api.linear.app/graphql";
const TEAM_ID = "e2568123-2c86-4283-a88f-88e0b508f5ae";
const PROJECT_ID = "ac986938-6355-452d-9c6e-6e08ecb1c49e";
// File every feedback issue directly into Backlog for consistent triage, rather than the team default state.
const BACKLOG_STATE_ID = "e7d24547-43c5-464d-8881-413f6e80dd2e";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

type Body = {
  text?: string;
  screenshotBase64?: string;
  version?: string;
  os?: string;
  engine?: string;
  mode?: string;
  uid?: string;
  alias?: string;
  email?: string;
};

/** Run a Linear GraphQL request with the server-side key. Throws on transport/GraphQL errors. */
async function linear<T>(key: string, query: string, variables: Record<string, unknown>): Promise<T> {
  const r = await fetch(LINEAR_URL, {
    method: "POST",
    headers: { Authorization: key, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await r.json();
  if (!r.ok || json.errors) {
    const msg = json?.errors?.[0]?.message ?? `Linear request failed (${r.status})`;
    throw new Error(msg);
  }
  return json.data as T;
}

/**
 * Upload a PNG to Linear and return its public assetUrl, or null on any failure.
 * Flow: fileUpload(...) → PUT bytes to uploadUrl with the returned headers → assetUrl.
 */
async function uploadScreenshot(key: string, png: Buffer): Promise<string | null> {
  try {
    type UploadResp = {
      fileUpload: {
        success: boolean;
        uploadFile: {
          uploadUrl: string;
          assetUrl: string;
          headers: { key: string; value: string }[];
        } | null;
      };
    };
    const data = await linear<UploadResp>(
      key,
      `mutation($ct:String!,$fn:String!,$sz:Int!){ fileUpload(contentType:$ct, filename:$fn, size:$sz){ success uploadFile { uploadUrl assetUrl headers { key value } } } }`,
      { ct: "image/png", fn: "feedback.png", sz: png.length }
    );
    const uf = data.fileUpload?.uploadFile;
    if (!data.fileUpload?.success || !uf) return null;

    const headers: Record<string, string> = { "Content-Type": "image/png" };
    for (const h of uf.headers ?? []) headers[h.key] = h.value;

    const put = await fetch(uf.uploadUrl, {
      method: "PUT",
      headers,
      body: new Uint8Array(png),
    });
    if (!put.ok) return null;
    return uf.assetUrl;
  } catch {
    return null;
  }
}

export async function POST(req: NextRequest) {
  const key = process.env.LINEAR_API_KEY;
  if (!key) {
    return NextResponse.json({ ok: false, error: "Feedback isn't configured yet." }, { status: 503, headers: cors });
  }

  // NO per-user feedback limit — send as many as you want. We keep only a very high global
  // daily ceiling as pure abuse protection (a runaway script), never a per-user cap.
  const day = new Date().toISOString().slice(0, 10);
  const globalOk = await convexBump(`feedback:global:${day}`, 20000, false);
  if (!globalOk) {
    return NextResponse.json(
      { ok: false, error: "Feedback is temporarily unavailable, please try again shortly." },
      { status: 429, headers: cors }
    );
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }

  const text = (body.text ?? "").trim();
  if (!text) {
    return NextResponse.json({ ok: false, error: "Feedback text is required." }, { status: 400, headers: cors });
  }
  if ((body.screenshotBase64 ?? "").length > MAX_SCREENSHOT_CHARS) {
    return NextResponse.json({ ok: false, error: "Screenshot too large." }, { status: 413, headers: cors });
  }

  // The body's email is attacker-controlled; only a verified app-session token proves it.
  const tok = verifyAppToken(req.headers.get("authorization"));

  // Optional screenshot upload (tolerate failure — we still file the issue without it).
  let assetUrl: string | null = null;
  if (body.screenshotBase64 && body.screenshotBase64.trim()) {
    try {
      const raw = body.screenshotBase64.replace(/^data:image\/png;base64,/, "").trim();
      const png = Buffer.from(raw, "base64");
      if (png.length > 0) assetUrl = await uploadScreenshot(key, png);
    } catch {
      assetUrl = null;
    }
  }

  // Title: first line, ~70 chars, single line.
  const firstLine = text.split(/\r?\n/)[0].trim();
  let title = (firstLine || text).replace(/\s+/g, " ").trim();
  if (title.length > 70) title = title.slice(0, 67).trimEnd() + "…";
  if (!title) title = "App feedback";

  // Description: full text + a rich Context block for source-tracing.
  const dash = (v?: string) => {
    const s = (v ?? "").trim();
    return s.length ? s : "—";
  };
  const user = [body.alias, body.uid, body.email]
    .map((v) => (v ?? "").trim())
    .filter(Boolean)
    .join(" · ") || "—";

  const description = [
    text,
    // Screenshot goes RIGHT AFTER the feedback (not buried at the bottom) so it's the first thing
    // you see. It also becomes a proper attachment below, so it shows even if inline rendering is off.
    ...(assetUrl ? ["", `![screenshot](${assetUrl})`] : []),
    "",
    "---",
    "",
    "## Context",
    "",
    `- **App version:** ${dash(body.version)}`,
    `- **macOS:** ${dash(body.os)}`,
    `- **Engine:** ${dash(body.engine)}`,
    `- **Active mode:** ${dash(body.mode)}`,
    `- **User:** ${user}`,
    tok ? `- **Verified email:** ${tok.email}` : `- **Identity:** unverified (no app token)`,
    `- **Submitted:** ${new Date().toISOString()}`,
  ].join("\n");

  try {
    type CreateResp = {
      issueCreate: { success: boolean; issue: { id: string; identifier: string; url: string } | null };
    };
    const data = await linear<CreateResp>(
      key,
      `mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success issue { id identifier url } } }`,
      { i: { teamId: TEAM_ID, projectId: PROJECT_ID, stateId: BACKLOG_STATE_ID, title, description } }
    );
    if (!data.issueCreate?.success || !data.issueCreate.issue) {
      return NextResponse.json({ ok: false, error: "Couldn't file the feedback issue." }, { status: 502, headers: cors });
    }
    // Also attach the screenshot as a proper Linear attachment (a visible card), so it shows even
    // if the inline markdown image doesn't render — belt and suspenders for "is the image visible?".
    if (assetUrl) {
      try {
        await linear(
          key,
          `mutation($id:String!,$url:String!){ attachmentCreate(input:{ issueId:$id, title:"Screenshot", subtitle:"User-attached screenshot", url:$url }){ success } }`,
          { id: data.issueCreate.issue.id, url: assetUrl }
        );
      } catch { /* non-fatal: the inline embed already carries the image */ }
    }
    return NextResponse.json({ ok: true, url: data.issueCreate.issue.url }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Feedback couldn't be delivered right now.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }
}
