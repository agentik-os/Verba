import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";
// JARVIS planning (2-phase Opus + Composio reads) + reprompting can run tens of seconds;
// without this Vercel kills the function at its default timeout → the app shows "took too long".
export const maxDuration = 300;

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
    // Composio's manual execution requires a CONCRETE toolkit version (it rejects "latest" with
    // "Toolkit version not specified"). Resolve the tool's own version by slug, then execute.
    let version: string | undefined;
    try {
      const raw = (await composio.tools.getRawComposioTools({ tools: [tool], limit: 1 } as never)) as {
        slug: string;
        version?: string;
      }[];
      version = raw.find((t) => t.slug === tool)?.version ?? raw[0]?.version;
    } catch {
      /* best effort: some no-auth tools execute without an explicit version */
    }

    const execArgs = {
      userId: auth.uid,
      arguments: body.arguments ?? {},
      ...(version ? { version } : {}),
    };
    const result = await composio.tools.execute(
      tool,
      execArgs as Parameters<typeof composio.tools.execute>[1]
    );
    return NextResponse.json({ ok: true, result }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Tool execution failed.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }
}
