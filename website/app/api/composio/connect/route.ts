import { NextRequest, NextResponse } from "next/server";
import { Composio } from "@composio/core";
import { cors, credentialConfigName, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";
// Up to three serial Composio round-trips (list auth configs, create/update one, link the account).
// Without this the platform default (10-15s) kills a slow connect mid-flight.
export const maxDuration = 60;

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

// Auth schemes that are safe to SHARE across users. An OAuth config holds the DEVELOPER's client
// id/secret and each user still completes their own consent, so one config serves everyone. An
// API_KEY / BASIC / BEARER_TOKEN config holds ONE USER'S OWN SECRET and must never be reused by
// anybody else — see the reuse bug described on oauthAuthConfigId below.
const SHAREABLE_SCHEMES = new Set(["OAUTH2", "OAUTH1", "DCR_OAUTH", "S2S_OAUTH2"]);

/**
 * The auth config to link OAuth/no-auth connections against. Reuses an ENABLED existing config —
 * a custom one (BYO OAuth client) always wins — instead of creating a fresh managed config per
 * connect call (which both proliferated configs and pinned Google toolkits to Composio's blocked
 * shared client).
 *
 * SECURITY: the reuse loop must only ever consider OAUTH configs. It previously returned the first
 * config with `isComposioManaged === false`, regardless of scheme — and the credential branch at
 * the bottom of POST creates exactly such a config, holding ONE user's API key. So for any toolkit
 * where user A had connected with their own key, a later request from user B naming that toolkit
 * was linked to A's config and executed tools on A's credentials. The `auth` field is client
 * supplied, so B did not even need the toolkit to be an OAuth app: any unrecognised value fell
 * through to this branch. Filtering on authScheme closes that; POST additionally rejects an `auth`
 * value that is not one of the known styles.
 */
async function oauthAuthConfigId(composio: Composio, toolkit: string): Promise<string> {
  let managed: string | null = null;
  try {
    const list = await composio.authConfigs.list({ toolkit: toolkit.toLowerCase() });
    for (const item of list.items ?? []) {
      if (item.status === "DISABLED") continue;
      // An absent authScheme is NOT evidence that the config is an OAuth one, so skip it: a
      // wrongly-skipped config only costs us a managed fallback, a wrongly-reused one leaks a key.
      if (!item.authScheme || !SHAREABLE_SCHEMES.has(item.authScheme)) continue;
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

/**
 * The auth config for a CREDENTIAL connection, reused per (toolkit, user).
 * Previously this created a brand-new config on every submit, so a user who mistyped their API key
 * three times left three configs behind, each holding a secret, none ever deleted — and nothing in
 * the codebase could remove them. Now the same user re-connecting UPDATES their one config in
 * place, so the newest key wins and exactly one secret exists per user per app.
 */
async function credentialAuthConfigId(
  composio: Composio,
  toolkit: string,
  uid: string,
  authScheme: string,
  credentials: Record<string, string>
): Promise<string> {
  const name = credentialConfigName(toolkit, uid);
  try {
    const list = await composio.authConfigs.list({ toolkit: toolkit.toLowerCase() });
    const mine = (list.items ?? []).find((i) => i.name === name);
    if (mine) {
      // Refresh the stored credentials rather than stacking another config beside it.
      await composio.authConfigs.update(mine.id, { type: "custom", credentials });
      return mine.id;
    }
  } catch {
    // Lookup/update is best-effort: fall through and create one.
  }
  const ac = await composio.authConfigs.create(toolkit, {
    type: "use_custom_auth",
    authScheme: authScheme as never,
    name,
    credentials,
  });
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
  // Reject an unknown style instead of silently treating it as OAuth. The old fallthrough let a
  // caller send any string and land in the OAuth branch, which was half of the cross-user
  // credential-reuse path; it also turned a client/catalog mismatch into a confusing OAuth attempt
  // on an app that has no OAuth at all.
  if (style !== "oauth" && style !== "none" && !SCHEME[style]) {
    return NextResponse.json(
      { error: `Unsupported connection type "${style}".` },
      { status: 400, headers: cors }
    );
  }

  try {
    // OAuth → reused/BYO auth config + a browser redirect the user completes.
    if (style === "oauth") {
      // allowMultiple: SDK 0.13+ rejects link() when the user already has a connection for this
      // toolkit ("Multiple connected accounts found… use the allowMultiple flag") — which broke the
      // Connect button for every app the user had already connected. Allow it so re-connecting works.
      const conn = await composio.connectedAccounts.link(auth.uid, await oauthAuthConfigId(composio, toolkit), { allowMultiple: true });
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
    const acId = await credentialAuthConfigId(composio, toolkit, auth.uid, SCHEME[style], credentials);
    const conn = await composio.connectedAccounts.link(auth.uid, acId, { allowMultiple: true });
    // Credential auth has no redirect — it's active (or initializing) immediately.
    return NextResponse.json(
      { ok: true, id: conn.id, status: conn.status ?? "ACTIVE", redirectUrl: conn.redirectUrl ?? null },
      { headers: cors }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Connection failed.";
    // Some toolkits (Twitter, Telegram, Shopify…) have NO Composio-managed auth — connecting them
    // needs the developer's own OAuth app. Return a clear, specific signal instead of a raw 502 so
    // the app can tell the user plainly rather than appearing to do nothing.
    if (/managed credentials|Default auth config not found/i.test(msg)) {
      return NextResponse.json(
        { error: "This app can't be connected yet: it needs its own credentials.", unsupported: true },
        { status: 422, headers: cors },
      );
    }
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
