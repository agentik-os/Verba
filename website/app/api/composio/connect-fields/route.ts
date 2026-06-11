import { NextRequest, NextResponse } from "next/server";
import { cors, getComposio, notConfigured } from "../_lib";

export const runtime = "nodejs";

// GET /api/composio/connect-fields?toolkit=PERPLEXITYAI&scheme=API_KEY
//   -> { fields: [{ name, label, description, required, type, default }] }
// The credentials a non-OAuth toolkit needs, so the app can render the right modal. Public catalog
// metadata (no user data, no secrets).

const SCHEME: Record<string, string> = {
  api_key: "API_KEY",
  bearer: "BEARER_TOKEN",
  basic: "BASIC",
};

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
  const url = new URL(req.url);
  const toolkit = (url.searchParams.get("toolkit") ?? "").toUpperCase().trim();
  const styleOrScheme = (url.searchParams.get("scheme") ?? "api_key").trim();
  const scheme = SCHEME[styleOrScheme.toLowerCase()] ?? styleOrScheme.toUpperCase();
  if (!toolkit) return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });

  const composio = getComposio();
  if (!composio) return notConfigured();

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
    return NextResponse.json({ toolkit, scheme, fields }, { headers: cors });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to load connection fields.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
