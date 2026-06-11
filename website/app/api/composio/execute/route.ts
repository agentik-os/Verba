import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// POST { tool, arguments } -> run a Composio tool as the authenticated user.
// The uid from the verified token is the Composio entity, so a user can only
// ever execute against their own connected accounts.
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: { tool?: string; arguments?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }
  const tool = (body.tool ?? "").trim();
  if (!tool) {
    return NextResponse.json({ ok: false, error: "Missing tool." }, { status: 400, headers: cors });
  }

  try {
    const result = await composio.tools.execute(tool, {
      userId: auth.uid,
      arguments: body.arguments ?? {},
    });
    return NextResponse.json({ ok: true, result }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Tool execution failed.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }
}
