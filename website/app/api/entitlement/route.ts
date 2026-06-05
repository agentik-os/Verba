import { NextRequest, NextResponse } from "next/server";
import { entitlementByEmail } from "@/lib/billing";

export const runtime = "nodejs";

// The Verba macOS app calls this to check whether a user has an active
// subscription (BYOK, so this only gates the app licence, not API usage).
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET(req: NextRequest) {
  const email = req.nextUrl.searchParams.get("email") ?? "";
  if (!email) {
    return NextResponse.json({ active: false, plan: "free", error: "email required" }, { status: 400, headers: cors });
  }
  const ent = await entitlementByEmail(email);
  return NextResponse.json(ent, { headers: cors });
}
