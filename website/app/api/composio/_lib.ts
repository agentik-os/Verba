import { Composio } from "@composio/core";
import { NextResponse } from "next/server";
import { verifyAppToken } from "@/lib/apptoken";

// Shared helpers for the Composio secure-relay routes. The macOS app never sees
// the COMPOSIO_API_KEY: it authenticates with its app-session token and the
// site proxies every Composio call, using the user's uid as the Composio entity.
export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

let client: Composio | null = null;
export function getComposio(): Composio | null {
  const apiKey = process.env.COMPOSIO_API_KEY;
  if (!apiKey) return null;
  if (!client) client = new Composio({ apiKey });
  return client;
}

/// Verify the app-session token and return the user's uid (the Composio entity),
/// or a ready-to-return 401/503 response on failure.
export function requireUid(authHeader: string | null): { uid: string } | { error: NextResponse } {
  const tok = verifyAppToken(authHeader);
  if (!tok) {
    return {
      error: NextResponse.json({ error: "Sign in to use connected apps." }, { status: 401, headers: cors }),
    };
  }
  return { uid: tok.code };
}

export function notConfigured(): NextResponse {
  return NextResponse.json({ error: "Connected apps aren't configured yet." }, { status: 503, headers: cors });
}

/// A stable, per-user, per-toolkit name for a CREDENTIAL auth config (API key / bearer / basic).
/// Such a config holds the USER'S OWN secret, so it is never shared: the name is how `connect`
/// finds and updates the one config that belongs to this user, and how `disconnect` deletes it so
/// the secret does not outlive the connection.
export function credentialConfigName(toolkit: string, uid: string): string {
  return `verba-${toolkit.toLowerCase()}-${uid}`;
}

/// The shape Composio RESOLVES with. A provider-level failure (bad arguments, revoked token, a 404
/// on the target resource) comes back as an HTTP 200 carrying `successful: false` — it does NOT
/// throw. Routes that only catch exceptions therefore treat a failed write as a success.
export interface ToolResult {
  successful?: boolean;
  error?: string | null;
  data?: unknown;
}

/// True when Composio reported the call itself failed. `successful` is optional in the SDK types,
/// so only an explicit `false` counts — an absent field is not treated as a failure.
export function toolFailed(result: unknown): boolean {
  return (result as ToolResult | null)?.successful === false;
}

/// Turn a raw Composio/SDK error string into something a Verba user can act on.
/// The raw strings are written for an API consumer ("No connected account found for user
/// <uuid>…"), so surfacing them verbatim tells the user nothing they can do. Anything we don't
/// recognize is passed through unchanged rather than replaced by a vague catch-all, so a novel
/// failure is still diagnosable.
export function friendlyToolError(raw: string | null | undefined, toolkitOrTool?: string): string {
  const msg = (raw ?? "").trim();
  const app = appLabel(toolkitOrTool);
  if (!msg) return `${app} couldn't complete that. Try again.`;
  if (/no connected account|connected account not found|not connected|no connection found/i.test(msg)) {
    return `Connect ${app} in Verba first, then try again.`;
  }
  if (/invalid_grant|token (has )?expired|refresh token|reauthor|re-author|unauthorized|401/i.test(msg)) {
    return `Your ${app} connection expired. Reconnect ${app} in Verba, then try again.`;
  }
  if (/forbidden|403|insufficient (permission|scope)|missing scope|access denied/i.test(msg)) {
    return `Verba doesn't have permission for that in ${app}. Reconnect ${app} and grant the access it asks for.`;
  }
  if (/rate ?limit|too many requests|429|quota/i.test(msg)) {
    return `${app} is rate-limiting requests right now. Try again in a moment.`;
  }
  if (/not found|404/i.test(msg)) {
    return `${app} couldn't find that item. It may have been moved or deleted.`;
  }
  if (/timeout|timed out|ETIMEDOUT|ECONNRESET|socket hang up/i.test(msg)) {
    return `${app} didn't respond in time. Try again.`;
  }
  // Argument problems are the planner's fault, not the user's — say what to do, keep the detail.
  if (/invalid (argument|parameter|request|value)|validation|required (field|parameter)|400/i.test(msg)) {
    return `${app} rejected the details for that action: ${clip(msg)}`;
  }
  return clip(msg);
}

/// HTTP status for a failed tool call. A provider rejecting our request is an upstream failure
/// (502), but an expired/missing connection is something the USER fixes, so it gets a 4xx the app
/// can branch on instead of a generic bad-gateway.
export function toolErrorStatus(raw: string | null | undefined): number {
  const msg = (raw ?? "").trim();
  if (/no connected account|connected account not found|not connected|no connection found/i.test(msg)) return 409;
  if (/invalid_grant|token (has )?expired|refresh token|reauthor|re-author|unauthorized|401/i.test(msg)) return 401;
  if (/forbidden|403|insufficient (permission|scope)|missing scope|access denied/i.test(msg)) return 403;
  if (/rate ?limit|too many requests|429|quota/i.test(msg)) return 429;
  return 502;
}

// "GMAIL_SEND_EMAIL" / "GMAIL" -> "Gmail"-ish. Good enough for a sentence, and never worse than
// echoing the raw slug at the user.
function appLabel(toolkitOrTool?: string): string {
  const head = (toolkitOrTool ?? "").split("_")[0];
  if (!head) return "That app";
  return head.charAt(0).toUpperCase() + head.slice(1).toLowerCase();
}

// Keep an error one line: the macOS app renders it in a feed row, not a log viewer.
function clip(s: string): string {
  const one = s.replace(/\s+/g, " ").trim();
  return one.length > 200 ? one.slice(0, 200) + "…" : one;
}
