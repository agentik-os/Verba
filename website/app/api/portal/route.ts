import { NextRequest, NextResponse } from "next/server";
import { currentUser } from "@clerk/nextjs/server";
import { stripeClient, SITE_URL } from "@/lib/billing";
import { verifyAppToken } from "@/lib/apptoken";

export const runtime = "nodejs";

// Opens the Stripe Billing Portal for a customer (manage/cancel subscription).
// S4: the email is resolved from the Clerk web session or the app-session token —
// never from the request body (anyone could open anyone's portal otherwise).
export async function POST(req: NextRequest) {
  const stripe = stripeClient();
  if (!stripe) return NextResponse.json({ error: "billing not configured" }, { status: 503 });

  // Resolve the authenticated email: signed-in web user first, then app token.
  let email = "";
  try {
    const user = await currentUser();
    email = (user?.primaryEmailAddress?.emailAddress ?? user?.emailAddresses?.[0]?.emailAddress ?? "")
      .toLowerCase()
      .trim();
  } catch {
    email = "";
  }
  if (!email) {
    const tok = verifyAppToken(req.headers.get("authorization"));
    email = tok?.email ?? "";
  }
  if (!email) return NextResponse.json({ error: "unauthenticated" }, { status: 401 });

  const customers = await stripe.customers.list({ email, limit: 1 });
  const customer = customers.data[0];
  if (!customer) return NextResponse.json({ error: "no customer for that email" }, { status: 404 });

  const session = await stripe.billingPortal.sessions.create({
    customer: customer.id,
    return_url: `${SITE_URL}/account`,
  });
  return NextResponse.json({ url: session.url });
}
