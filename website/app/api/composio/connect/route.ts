import { NextRequest, NextResponse } from "next/server";
import { Composio } from "@composio/core";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// POST { toolkit } -> start a Composio connection for the user.
// Returns { redirectUrl, id }: the app opens redirectUrl in the browser and the
// user completes OAuth there; the key never leaves the server.

// Google toolkits: Google BLOCKS Composio's shared OAuth client for sensitive
// scopes ("This app is blocked"). These need the project's OWN Google OAuth
// client — either an auth config created in the Composio dashboard (picked up
// by the reuse logic below) or GOOGLE_OAUTH_CLIENT_ID/SECRET env credentials.
const GOOGLE_TOOLKITS = new Set([
  "GMAIL",
  "GOOGLECALENDAR",
  "GOOGLEDRIVE",
  "GOOGLEDOCS",
  "GOOGLESHEETS",
  "GOOGLESLIDES",
  "GOOGLETASKS",
  "GOOGLEMEET",
  "GOOGLEPHOTOS",
  "GOOGLE_MAPS",
  "YOUTUBE",
]);

/**
 * The auth config to link OAuth/no-auth connections against. Reuses an ENABLED
 * existing config — a custom one (BYO OAuth client) always wins — instead of
 * creating a fresh managed config per connect call (which both proliferated
 * configs and pinned Google toolkits to Composio's blocked shared client).
 */
async function oauthAuthConfigId(composio: Composio, toolkit: string): Promise<string> {
  let managed: string | null = null;
  try {
    const list = await composio.authConfigs.list({ toolkit: toolkit.toLowerCase() });
    for (const item of list.items ?? []) {
      if (item.status === "DISABLED") continue;
      if (item.isComposioManaged === false) return item.id;
      managed ??= item.id;
    }
  } catch {
    // Listing is an optimization — fall through to creating a config.
  }
  const clientId = process.env.GOOGLE_OAUTH_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_OAUTH_CLIENT_SECRET;
  if (GOOGLE_TOOLKITS.has(toolkit) && clientId && clientSecret) {
    const ac = await composio.authConfigs.create(toolkit, {
      type: "use_custom_auth",
      authScheme: "OAUTH2",
      name: `verba-${toolkit.toLowerCase()}`,
      credentials: { client_id: clientId, client_secret: clientSecret },
    });
    return ac.id;
  }
  if (managed) return managed;
  const ac = await composio.authConfigs.create(toolkit, { type: "use_composio_managed_auth" });
  return ac.id;
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let body: { toolkit?: string; auth?: string; fields?: Record<string, string> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Bad request" }, { status: 400, headers: cors });
  }
  const toolkit = (body.toolkit ?? "").trim().toUpperCase();
  if (!toolkit) {
    return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  }
  const style = (body.auth ?? "oauth").toLowerCase();
  const SCHEME: Record<string, string> = { api_key: "API_KEY", bearer: "BEARER_TOKEN", basic: "BASIC" };

  try {
    // OAuth (and unknown) → reused/BYO auth config + a browser redirect the user completes.
    if (style === "oauth" || (!SCHEME[style] && style !== "none")) {
      const conn = await composio.connectedAccounts.link(auth.uid, await oauthAuthConfigId(composio, toolkit));
      return NextResponse.json({ redirectUrl: conn.redirectUrl, id: conn.id }, { headers: cors });
    }
    // No-auth toolkits need no connected account at all — Composio refuses to even
    // create an auth config for them ("Auth_Config_NoAuthApp") and /execute works
    // with just the user id. Nothing to link; report active.
    if (style === "none") {
      return NextResponse.json({ ok: true, status: "ACTIVE" }, { headers: cors });
    }
    // API key / bearer / basic → create a custom auth config with the user's credentials, then link.
    const credentials = body.fields ?? {};
    if (!Object.keys(credentials).length) {
      return NextResponse.json({ error: "Missing credentials." }, { status: 400, headers: cors });
    }
    const ac = await composio.authConfigs.create(toolkit, {
      type: "use_custom_auth",
      authScheme: SCHEME[style] as never,
      credentials,
    });
    const conn = await composio.connectedAccounts.link(auth.uid, ac.id);
    // Credential auth has no redirect — it's active (or initializing) immediately.
    return NextResponse.json(
      { ok: true, id: conn.id, status: conn.status ?? "ACTIVE", redirectUrl: conn.redirectUrl ?? null },
      { headers: cors }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Connection failed.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
