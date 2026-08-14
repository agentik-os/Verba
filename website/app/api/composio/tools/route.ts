import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";
import { fetchToolkitTools, toolPriority } from "@/lib/composio-rw";

export const runtime = "nodejs";
// One Composio round-trip per requested toolkit, four in flight at a time (see CONCURRENCY below).
// Even so, ten connected apps on a cold cache cost three waves plus their wide-fallback fetches,
// which is past Vercel's 10-15s platform default, and this runs on every app refresh.
export const maxDuration = 60;

// GET ?toolkits=GMAIL,NOTION -> lightweight tool catalog for those toolkits
// (default: all the user's ACTIVE connections). Big input schemas are stripped:
// the app only needs slug + description to let the model pick a tool.
const MAX_PER_TOOLKIT = 12;

// The per-toolkit fetches used to run one at a time, each awaiting the last, so the wall clock was
// the SUM of every connected app's round-trip and ten apps on a cold cache timed the route out
// (the platform then returns a bare 504 and the app shows no tools at all). Four at a time keeps
// the burst small enough not to trip Composio's shared rate limit, which is the constraint that
// put the 10-minute cache in composio-rw.ts in the first place.
const CONCURRENCY = 4;

type ToolkitTools = Awaited<ReturnType<typeof fetchToolkitTools>>;

// A shared cursor rather than chunked Promise.all: a chunk barrier makes every toolkit in a chunk
// wait for the slowest member, while a worker pool picks up the next toolkit the moment a worker
// frees up. Each result is written at its ORIGINAL index, so the response is ordered by `toolkits`
// and never by which fetch happened to finish first.
async function fetchToolkitsBounded(
  composio: Parameters<typeof fetchToolkitTools>[0],
  toolkits: string[]
): Promise<ToolkitTools[]> {
  const results: ToolkitTools[] = new Array(toolkits.length);
  let next = 0;
  const worker = async () => {
    for (let i = next++; i < toolkits.length; i = next++) {
      results[i] = await fetchToolkitTools(composio, toolkits[i]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(CONCURRENCY, toolkits.length) }, worker));
  return results;
}

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
    const rawByToolkit = await fetchToolkitsBounded(composio as never, toolkits);
    const tools: { slug: string; name: string; description: string; toolkit: string }[] = [];
    toolkits.forEach((toolkit, i) => {
      const ranked = [...rawByToolkit[i]].sort((a, b) => toolPriority(b.slug) - toolPriority(a.slug));
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
    });
    return NextResponse.json({ tools }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to list tools.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
