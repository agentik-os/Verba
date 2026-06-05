import { NextRequest, NextResponse } from "next/server";
import { currentUser } from "@clerk/nextjs/server";
import { stripeClient, priceFor, SITE_URL, PlanId } from "@/lib/billing";

export const runtime = "nodejs";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const stripe = stripeClient();
  if (!stripe) return NextResponse.json({ error: "billing not configured" }, { status: 503, headers: cors });

  let body: { plan?: PlanId; email?: string; ref?: string };
  try { body = await req.json(); } catch { return NextResponse.json({ error: "bad request" }, { status: 400, headers: cors }); }

  const plan = body.plan;
  if (plan !== "monthly" && plan !== "annual") {
    return NextResponse.json({ error: "unknown plan" }, { status: 400, headers: cors });
  }
  const price = priceFor(plan);
  if (!price) return NextResponse.json({ error: `price for ${plan} not configured` }, { status: 503, headers: cors });

  // Prefer the signed-in Clerk user's email so the subscription ties to the account.
  let email = body.email?.toLowerCase().trim();
  try {
    const user = await currentUser();
    email = user?.primaryEmailAddress?.emailAddress?.toLowerCase() ?? email;
  } catch {}

  // Referral attribution: carried from the ?ref link → Stripe metadata, so a webhook
  // can later reward the referrer once this subscriber qualifies.
  const ref = (body.ref ?? "").toString().slice(0, 64).trim();
  const meta: Record<string, string> = { product: "verba", plan };
  if (ref) meta.referredBy = ref;

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price, quantity: 1 }],
      allow_promotion_codes: true,
      customer_email: email || undefined,
      subscription_data: { trial_period_days: 7, metadata: meta },
      metadata: meta,
      success_url: `${SITE_URL}/account?status=success`,
      cancel_url: `${SITE_URL}/#pricing`,
    });
    return NextResponse.json({ url: session.url }, { headers: cors });
  } catch {
    return NextResponse.json({ error: "stripe error" }, { status: 502, headers: cors });
  }
}
