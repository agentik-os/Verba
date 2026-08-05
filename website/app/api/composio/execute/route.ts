import { NextRequest, NextResponse } from "next/server";
import {
  cors,
  friendlyToolError,
  getComposio,
  notConfigured,
  requireUid,
  toolErrorStatus,
  toolFailed,
  type ToolResult,
} from "../_lib";
import { activeToolkits, resolveToolMeta } from "@/lib/composio-rw";

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
    // Resolve the tool's CONCRETE version (Composio rejects a call without one) plus its owning
    // toolkit, cached across requests so a confirmed write costs one Composio call instead of two.
    const meta = await resolveToolMeta(composio as never, tool);

    // AUTHORIZE THE TOOL, not just the caller. A valid session used to be able to run ANY slug in
    // Composio's whole catalog. For an app the user connected, Composio bounds it to their own
    // account — but no-auth toolkits need no connected account, so any signed-up user could drive
    // the sandboxed code-execution and headless-browser tools on the owner's COMPOSIO_API_KEY with
    // no connection step and no accounting. Require the tool's toolkit to be one this user has
    // ACTIVE, using the tool's own `isNoAuth` metadata rather than a hardcoded app list that drifts.
    if (meta.toolkit && !meta.isNoAuth) {
      let connected = await activeToolkits(composio as never, auth.uid);
      // Never refuse on a cached miss: re-check fresh first, so someone who connected the app
      // seconds ago is not told to connect it again.
      if (!connected.has(meta.toolkit)) connected = await activeToolkits(composio as never, auth.uid, true);
      if (!connected.has(meta.toolkit)) {
        return NextResponse.json(
          { ok: false, error: friendlyToolError("no connected account", meta.toolkit) },
          { status: 409, headers: cors }
        );
      }
    }

    const version = meta.version;
    const execArgs = {
      userId: auth.uid,
      arguments: body.arguments ?? {},
      ...(version ? { version } : {}),
    };
    const result = (await composio.tools.execute(
      tool,
      execArgs as Parameters<typeof composio.tools.execute>[1]
    )) as ToolResult;

    // A provider-level failure does NOT throw: Composio RESOLVES with { successful: false, error }
    // on an HTTP 200. Reporting that as ok:true is the worst bug this relay can have — the macOS
    // app marks the feed row done and speaks the announce line, so a user whose Gmail token was
    // revoked is told their email was sent when nothing left the building. Check the flag.
    if (toolFailed(result)) {
      const raw = result.error ?? null;
      return NextResponse.json(
        { ok: false, error: friendlyToolError(raw, tool), detail: raw ?? undefined },
        { status: toolErrorStatus(raw), headers: cors }
      );
    }
    return NextResponse.json({ ok: true, result }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Tool execution failed.";
    return NextResponse.json(
      { ok: false, error: friendlyToolError(msg, tool), detail: msg },
      { status: toolErrorStatus(msg), headers: cors }
    );
  }
}
