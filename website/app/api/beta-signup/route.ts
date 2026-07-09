import { NextRequest, NextResponse } from "next/server";
import { verifyAppToken } from "@/lib/apptoken";
import { convexBump, convexCall } from "@/lib/convex";

export const runtime = "nodejs";

// Receives iPhone TestFlight beta-signup requests from the macOS app: validates the email, stores
// it durably in Convex (beta_signups, deduped by email) so a signup is NEVER lost, and pings the
// operator via a lightweight Linear issue (mirroring the feedback pipeline). The actual TestFlight
// invite is the last manual/cron step — see website/scripts/testflight-invite.mjs — because the
// App Store Connect issuer ID + beta group ID aren't wired yet. No key ever lives in the app.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const LINEAR_URL = "https://api.linear.app/graphql";
const TEAM_ID = "16e9d4a0-b7ca-4463-ab8a-a024a4049ba1";
const PROJECT_ID = "02a68254-e055-49c0-8d91-4e97af001e83";
// File the operator ping into Backlog for consistent triage, same as the feedback route.
const BACKLOG_STATE_ID = "fb9524bf-9b3c-433a-ac87-49069f7523f1";

// RFC-lite check — same intent as the app's client-side one; deliverability is the real gate.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

type Body = { email?: string; deviceAlias?: string; appVersion?: string; uid?: string };

export async function POST(req: NextRequest) {
  // NO per-user cap — anyone can sign up. Keep only a very high global daily ceiling as pure abuse
  // protection (a runaway script), matching the /api/feedback grammar.
  const day = new Date().toISOString().slice(0, 10);
  const globalOk = await convexBump(`beta:global:${day}`, 20000, false);
  if (!globalOk) {
    return NextResponse.json(
      { ok: false, error: "Beta signup is temporarily unavailable, please try again shortly." },
      { status: 429, headers: cors }
    );
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }

  const email = (body.email ?? "").trim().toLowerCase();
  if (!EMAIL_RE.test(email) || email.length > 254) {
    return NextResponse.json({ ok: false, error: "Please enter a valid email address." }, { status: 400, headers: cors });
  }

  // The body email is user-supplied AND must stay editable (TestFlight needs the iCloud address,
  // which may differ from the signed-in account), so we store it as given. A verified app token,
  // when present, still lets us record which account the signup came from.
  const tok = verifyAppToken(req.headers.get("authorization"));

  // Durable store FIRST (deduped by email) so a Linear outage never loses a signup.
  try {
    await convexCall<string>("mutation", "beta:submit", {
      serverKey: process.env.APP_TOKEN_SECRET ?? "",
      email,
      alias: body.deviceAlias ?? "",
      appVersion: body.appVersion ?? "",
      uid: body.uid ?? tok?.code ?? "",
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't record your signup right now.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  // Operator ping — mirror the feedback pipeline (a Linear issue). Best-effort: a Linear hiccup
  // must NEVER fail the request, because the durable Convex row already captured the signup.
  const key = process.env.LINEAR_API_KEY;
  if (key) {
    try {
      const user = [body.deviceAlias, body.uid].map((v) => (v ?? "").trim()).filter(Boolean).join(" · ") || "—";
      const description = [
        "New iPhone beta-test signup.",
        "",
        `- **iCloud email:** ${email}`,
        `- **App version:** ${(body.appVersion ?? "").trim() || "—"}`,
        `- **User:** ${user}`,
        tok ? `- **Account email:** ${tok.email}` : `- **Identity:** unverified (no app token)`,
        `- **Submitted:** ${new Date().toISOString()}`,
        "",
        "Add this address to the TestFlight beta group — see `website/scripts/testflight-invite.mjs`.",
      ].join("\n");
      await fetch(LINEAR_URL, {
        method: "POST",
        headers: { Authorization: key, "Content-Type": "application/json" },
        body: JSON.stringify({
          query: `mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success } }`,
          variables: {
            i: { teamId: TEAM_ID, projectId: PROJECT_ID, stateId: BACKLOG_STATE_ID, title: `iPhone beta signup: ${email}`, description },
          },
        }),
      });
    } catch {
      /* non-fatal: the durable Convex row already captured the signup */
    }
  }

  return NextResponse.json({ ok: true }, { headers: cors });
}
