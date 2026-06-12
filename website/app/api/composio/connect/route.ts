import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// POST { toolkit } -> start a Composio managed-auth connection for the user.
// Returns { redirectUrl, id }: the app opens redirectUrl in the browser and the
// user completes OAuth there; the key never leaves the server.
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: { toolkit?: string; auth?: string; fields?: Record<string, string> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Bad request" }, { status: 400, headers: cors });
  }
  const toolkit = (body.toolkit ?? "").trim().toUpperCase();
  if (!toolkit) {
    return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  }
  const style = (body.auth ?? "oauth").toLowerCase();
  const SCHEME: Record<string, string> = { api_key: "API_KEY", bearer: "BEARER_TOKEN", basic: "BASIC" };

  try {
    // OAuth (and unknown) → Composio-managed auth + a browser redirect the user completes.
    if (style === "oauth" || (!SCHEME[style] && style !== "none")) {
      const ac = await composio.authConfigs.create(toolkit, { type: "use_composio_managed_auth" });
      const conn = await composio.connectedAccounts.link(auth.uid, ac.id);
      return NextResponse.json({ redirectUrl: conn.redirectUrl, id: conn.id }, { headers: cors });
    }
    // No-auth tools → link directly, no credentials, no redirect.
    if (style === "none") {
      const ac = await composio.authConfigs.create(toolkit, { type: "use_composio_managed_auth" });
      const conn = await composio.connectedAccounts.link(auth.uid, ac.id);
      return NextResponse.json({ ok: true, id: conn.id, status: conn.status ?? "ACTIVE" }, { headers: cors });
    }
    // API key / bearer / basic → create a custom auth config with the user's credentials, then link.
    const credentials = body.fields ?? {};
    if (!Object.keys(credentials).length) {
      return NextResponse.json({ error: "Missing credentials." }, { status: 400, headers: cors });
    }
    const ac = await composio.authConfigs.create(toolkit, {
      type: "use_custom_auth",
      authScheme: SCHEME[style] as never,
      credentials,
    });
    const conn = await composio.connectedAccounts.link(auth.uid, ac.id);
    // Credential auth has no redirect — it's active (or initializing) immediately.
    return NextResponse.json(
      { ok: true, id: conn.id, status: conn.status ?? "ACTIVE", redirectUrl: conn.redirectUrl ?? null },
      { headers: cors }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Connection failed.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
