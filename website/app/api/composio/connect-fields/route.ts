import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";

// GET /api/composio/connect-fields?toolkit=PERPLEXITYAI&scheme=API_KEY
//   -> { fields: [{ name, label, description, required, type, default }] }
// The credentials a non-OAuth toolkit needs, so the app can render the right modal. The RESPONSE is
// public catalog metadata (no user data, no secrets), but the CALL spends the shared
// COMPOSIO_API_KEY, so it is authenticated and cached: unauthenticated it was a free way to burn
// the shared Composio quota that /execute and /tools depend on. The app is signed in well before
// it can open a connect modal.

const SCHEME: Record<string, string> = {
  api_key: "API_KEY",
  bearer: "BEARER_TOKEN",
  basic: "BASIC",
};
// Accept only schemes Composio actually defines. The old code uppercased whatever arrived and
// handed it to the SDK, so an arbitrary string became a probe of Composio's internals via the raw
// error text.
const KNOWN_SCHEMES = new Set(["API_KEY", "BEARER_TOKEN", "BASIC", "BASIC_WITH_JWT", "OAUTH2", "OAUTH1", "NO_AUTH"]);

// Field metadata is per (toolkit, scheme) and changes about as often as Composio ships a release.
const FIELDS_TTL_MS = 60 * 60 * 1000;
const fieldsCache = new Map<string, { at: number; body: unknown }>();

interface RawField {
  name?: string;
  displayName?: string;
  description?: string;
  required?: boolean;
  type?: string;
  default?: unknown;
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const url = new URL(req.url);
  const toolkit = (url.searchParams.get("toolkit") ?? "").toUpperCase().trim();
  const styleOrScheme = (url.searchParams.get("scheme") ?? "api_key").trim();
  const scheme = SCHEME[styleOrScheme.toLowerCase()] ?? styleOrScheme.toUpperCase();
  if (!toolkit) return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  if (!KNOWN_SCHEMES.has(scheme)) {
    return NextResponse.json({ error: `Unsupported connection type "${styleOrScheme}".` }, { status: 400, headers: cors });
  }

  const composio = getComposio();
  if (!composio) return notConfigured();

  const cacheKey = `${toolkit}:${scheme}`;
  const hit = fieldsCache.get(cacheKey);
  if (hit && Date.now() - hit.at < FIELDS_TTL_MS) {
    return NextResponse.json(hit.body, { headers: cors });
  }

  try {
    const raw = (await composio.toolkits.getConnectedAccountInitiationFields(toolkit, scheme as never)) as RawField[];
    const fields = (raw ?? []).map((f) => ({
      name: f.name ?? "",
      label: f.displayName ?? f.name ?? "",
      description: (f.description ?? "").slice(0, 160),
      required: f.required ?? true,
      type: f.type ?? "string",
      default: typeof f.default === "string" ? f.default : "",
    })).filter((f) => f.name);
    const bodyOut = { toolkit, scheme, fields };
    fieldsCache.set(cacheKey, { at: Date.now(), body: bodyOut });
    return NextResponse.json(bodyOut, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to load connection fields.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
