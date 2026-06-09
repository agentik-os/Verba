import { NextRequest, NextResponse } from "next/server";
import { entitlementByEmail } from "@/lib/billing";
import { verifyAppToken } from "@/lib/apptoken";

export const runtime = "nodejs";

// The Verba macOS app calls this to check whether a user has an active
// subscription (BYOK, so this only gates the app licence, not API usage).
// S6: requires the app-session token; the email comes from it. The old
// `?email=` contract is gone — a request without a valid token is a 401.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const tok = verifyAppToken(req.headers.get("authorization"));
  if (!tok) {
    return NextResponse.json(
      { active: false, plan: "free", error: "unauthenticated" },
      { status: 401, headers: cors }
    );
  }
  const ent = await entitlementByEmail(tok.email);
  return NextResponse.json(ent, { headers: cors });
}
