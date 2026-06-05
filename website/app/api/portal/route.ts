import { NextRequest, NextResponse } from "next/server";
import { stripeClient, SITE_URL } from "@/lib/billing";

export const runtime = "nodejs";

// Opens the Stripe Billing Portal for a customer (manage/cancel subscription).
export async function POST(req: NextRequest) {
  const stripe = stripeClient();
  if (!stripe) return NextResponse.json({ error: "billing not configured" }, { status: 503 });

  let body: { email?: string };
  try { body = await req.json(); } catch { return NextResponse.json({ error: "bad request" }, { status: 400 }); }

  const email = body.email?.toLowerCase().trim();
  if (!email) return NextResponse.json({ error: "email required" }, { status: 400 });

  const customers = await stripe.customers.list({ email, limit: 1 });
  const customer = customers.data[0];
  if (!customer) return NextResponse.json({ error: "no customer for that email" }, { status: 404 });

  const session = await stripe.billingPortal.sessions.create({
    customer: customer.id,
    return_url: `${SITE_URL}/account`,
  });
  return NextResponse.json({ url: session.url });
}
