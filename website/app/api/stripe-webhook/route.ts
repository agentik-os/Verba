import { NextRequest, NextResponse } from "next/server";
import { stripeClient } from "@/lib/billing";

export const runtime = "nodejs";

// Entitlement is computed live from Stripe by email (see lib/billing), so this
// webhook is mainly a verified acknowledgement hook for future use (analytics,
// emails, caching). It verifies the signature when STRIPE_WEBHOOK_SECRET is set.
export async function POST(req: NextRequest) {
  const stripe = stripeClient();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!stripe || !secret) return NextResponse.json({ received: true });

  const sig = req.headers.get("stripe-signature") ?? "";
  const raw = await req.text();
  try {
    stripe.webhooks.constructEvent(raw, sig, secret);
  } catch {
    return NextResponse.json({ error: "bad signature" }, { status: 400 });
  }
  return NextResponse.json({ received: true });
}
