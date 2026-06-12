import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// GET ?toolkits=GMAIL,NOTION -> lightweight tool catalog for those toolkits
// (default: all the user's ACTIVE connections). Big input schemas are stripped:
// the app only needs slug + description to let the model pick a tool.
const MAX_PER_TOOLKIT = 12;

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  try {
    let toolkits = (req.nextUrl.searchParams.get("toolkits") ?? "")
      .split(",")
      .map((s) => s.trim().toUpperCase())
      .filter(Boolean);

    if (toolkits.length === 0) {
      const list = await composio.connectedAccounts.list({ userIds: [auth.uid] });
      toolkits = [
        ...new Set(
          (list.items ?? [])
            .filter((item) => item.status === "ACTIVE")
            .map((item) => {
              const tk = (item as unknown as { toolkit?: { slug?: string } | string }).toolkit;
              return (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
            })
            .filter(Boolean)
        ),
      ];
    }

    const tools: { slug: string; name: string; description: string; toolkit: string }[] = [];
    for (const toolkit of toolkits) {
      const raw = await composio.tools.getRawComposioTools({ toolkits: [toolkit], limit: 30 });
      for (const t of (raw as unknown as { slug: string; name?: string; displayName?: string; description?: string }[]).slice(
        0,
        MAX_PER_TOOLKIT
      )) {
        tools.push({
          slug: t.slug,
          name: t.displayName ?? t.name ?? t.slug,
          description: t.description ?? "",
          toolkit,
        });
      }
    }
    return NextResponse.json({ tools }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to list tools.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
