import { NextResponse } from "next/server";
import { currentUser } from "@clerk/nextjs/server";
import { entitlementByEmail } from "@/lib/billing";

export const runtime = "nodejs";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Cache-Control": "no-store",
};
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// The site (and the native app via its Clerk session) reads this to learn who the
// user is + their plan. Plan = Stripe entitlement looked up by the Clerk email.
export async function GET() {
  try {
    const user = await currentUser();
    if (!user) return NextResponse.json({ signedIn: false, plan: "free" }, { headers: cors });
    const email = user.primaryEmailAddress?.emailAddress ?? user.emailAddresses?.[0]?.emailAddress ?? "";
    const ent = email ? await entitlementByEmail(email) : { plan: "free", active: false };
    return NextResponse.json(
      { signedIn: true, email, firstName: user.firstName ?? "", plan: ent.active ? "pro" : "free" },
      { headers: cors }
    );
  } catch {
    return NextResponse.json({ signedIn: false, plan: "free" }, { headers: cors });
  }
}
