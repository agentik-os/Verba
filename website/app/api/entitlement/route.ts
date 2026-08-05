import { NextRequest, NextResponse } from "next/server";
import { entitlementByEmail } from "@/lib/billing";
import { verifyAppToken } from "@/lib/apptoken";

export const runtime = "nodejs";

// The Verba macOS app calls this to check whether a user has an active
// subscription (BYOK, so this only gates the app licence, not API usage).
// S6: requires the app-session token; the email defaults to the one it carries.
// A request without a valid token is a 401. An OPTIONAL `?email=` (checkout-email
// restore) is honoured only alongside a valid token, see the GET handler.
//
// THE ONE FREE/PRO CONTRACT: Free = unlimited raw dictation forever, no card. Pro = every AI
// mode plus Notes, Tasks and JARVIS. `active: true` means "this email holds Pro right now".
//
// THREE RESPONSES, and the difference between them matters more than it looks. The macOS client
// (Sources/Verba/Entitlement.swift) maps ANY non-2xx to `.unreachable`, which keeps the user's
// last known state instead of revoking Pro. So an honest error code is what protects a paying
// customer during an outage, and a wrong 200 is what silently downgrades them:
//   200 + { active, plan, currentPeriodEnd }  a real answer from Stripe. `active:false` here
//                                             genuinely means "no Verba subscription".
//   401 + { error: "unauthenticated" }        no valid app-session token. NOT a revoke.
//   503 + { error: "billing_not_configured" } this deployment has no STRIPE_SECRET_KEY, so the
//                                             question cannot be answered. NEVER answer "free":
//                                             on a key-less deploy that would revoke everyone.
// A thrown Stripe error (bad key, outage) surfaces as an unhandled 500, which the client also
// reads as `.unreachable`. That is deliberate, see the note in lib/billing.ts.
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
  // Restore-by-checkout-email: a signed-in Verba user whose app-token email differs from
  // the email they used at Stripe checkout can pass ?email= to restore their real
  // subscription. SECURITY: this is only honoured because the request ALSO carries a valid
  // app-session token (verifyAppToken above) — i.e. the caller is an authenticated Verba
  // user, so an anonymous caller can't probe arbitrary emails. And the only thing it
  // unlocks is a CLIENT-SIDE Pro flag: Verba is BYOK (the user brings their own AI key), so
  // Pro grants zero server-side spend. Worst case an authenticated user flips their local
  // Pro UI against an email that genuinely has an active Verba subscription — low abuse
  // value. The no-email path is unchanged: it still uses the token's own email.
  const providedEmail = req.nextUrl.searchParams.get("email")?.trim();
  const email = providedEmail && providedEmail.length > 0 ? providedEmail : tok.email;
  const ent = await entitlementByEmail(email);
  // Billing is not wired up on this deployment. Say so explicitly rather than reporting the
  // user as Free: `active: false` would be indistinguishable from a real "no subscription",
  // and the app would revoke Pro for every paying customer the moment a key went missing.
  if (!ent.configured) {
    return NextResponse.json(
      { active: false, plan: "free", error: "billing_not_configured" },
      { status: 503, headers: cors }
    );
  }
  const { configured: _configured, ...body } = ent;   // internal flag, not part of the wire shape
  return NextResponse.json(body, { headers: cors });
}
