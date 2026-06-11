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

  let body: { toolkit?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Bad request" }, { status: 400, headers: cors });
  }
  const toolkit = (body.toolkit ?? "").trim().toUpperCase();
  if (!toolkit) {
    return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  }

  try {
    const ac = await composio.authConfigs.create(toolkit, { type: "use_composio_managed_auth" });
    const conn = await composio.connectedAccounts.link(auth.uid, ac.id);
    return NextResponse.json({ redirectUrl: conn.redirectUrl, id: conn.id }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Connection failed.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
