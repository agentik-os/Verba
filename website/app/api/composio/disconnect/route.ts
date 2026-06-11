import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// POST { toolkit } -> delete the user's connected account(s) for that toolkit. { ok: true }
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let toolkit = "";
  try {
    toolkit = String((await req.json())?.toolkit ?? "").toUpperCase();
  } catch {
    return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  }
  if (!toolkit) return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });

  try {
    const list = await composio.connectedAccounts.list({ userIds: [auth.uid] });
    const mine = (list.items ?? []).filter((item) => {
      const tk = (item as unknown as { toolkit?: { slug?: string } | string }).toolkit;
      const slug = (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
      return slug === toolkit;
    });
    for (const acct of mine) {
      try { await composio.connectedAccounts.delete(acct.id); } catch { /* best-effort */ }
    }
    return NextResponse.json({ ok: true, removed: mine.length }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to disconnect.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
