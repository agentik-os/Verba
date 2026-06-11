import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// GET -> the user's Composio connected accounts: { connections: [{ toolkit, status, id }] }.
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  try {
    const list = await composio.connectedAccounts.list({ userIds: [auth.uid] });
    const connections = (list.items ?? []).map((item) => {
      // The SDK nests the toolkit slug; tolerate both shapes.
      const tk = (item as unknown as { toolkit?: { slug?: string } | string }).toolkit;
      const toolkit = (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
      return { toolkit, status: item.status, id: item.id };
    });
    return NextResponse.json({ connections }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to list connections.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
