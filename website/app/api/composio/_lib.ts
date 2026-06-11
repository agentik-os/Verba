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
