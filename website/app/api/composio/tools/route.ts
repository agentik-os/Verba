import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { fetchToolkitTools, toolPriority } from "@/lib/composio-rw";

export const runtime = "nodejs";
// One Composio round-trip per requested toolkit, in series. Ten connected apps on a cold cache
// blows straight through Vercel's 10-15s platform default, and this runs on every app refresh.
export const maxDuration = 60;

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

    // These tools are injected verbatim into the Action-mode prompt, which tells the model to use
    // ONLY the listed slugs — so a tool missing here is unreachable by voice. This used to fetch a
    // flat limit:30 and slice the first 12 ALPHABETICALLY, which is the exact bug composio-rw.ts
    // already documents having fixed for the planner catalog: GMAIL_SEND_EMAIL sorts last of
    // Gmail's tools and was dropped, so Verba could not send an email. LINEAR_UPDATE_ISSUE,
    // NOTION_UPDATE_PAGE and SLACK_SEND_MESSAGE fell out the same way, while ACL/admin tools that
    // no one asks for by voice survived on the strength of an "A".
    // Share the ranked + 10-minute-cached fetch with the planner instead of a second raw call:
    // same ordering everywhere, and one Composio request per toolkit per window rather than one
    // per app refresh (the "aggressive usage" that previously tripped the shared rate limit).
    const tools: { slug: string; name: string; description: string; toolkit: string }[] = [];
    for (const toolkit of toolkits) {
      const raw = await fetchToolkitTools(composio as never, toolkit);
      const ranked = [...raw].sort((a, b) => toolPriority(b.slug) - toolPriority(a.slug));
      for (const t of ranked.slice(0, MAX_PER_TOOLKIT)) {
        tools.push({
          slug: t.slug,
          // `name` is required on the SDK's Tool type; there is no `displayName` field anywhere in
          // @composio/core, so the old `t.displayName ?? …` limb was always undefined.
          name: (t as { name?: string }).name ?? t.slug,
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
