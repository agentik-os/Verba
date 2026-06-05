import Stripe from "stripe";

// Env-driven so the site builds and runs even before Stripe keys are set —
// handlers return a clean "not configured" instead of crashing.
export type PlanId = "monthly" | "annual";

export const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://verba.run";

export function stripeClient(): Stripe | null {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  return new Stripe(key);
}

export function priceFor(plan: PlanId): string | undefined {
  return {
    monthly: process.env.STRIPE_PRICE_VERBA_MONTHLY,
    annual: process.env.STRIPE_PRICE_VERBA_ANNUAL,
  }[plan];
}

// IMPORTANT: this Stripe account is SHARED with other products (LiquidPad,
// øRits/Dafnck). Only Verba's own price IDs count toward a Verba subscription —
// `planForPrice` returns undefined for anything else, so a customer's unrelated
// LiquidPad/øRits subscription never grants Verba Pro.
export function planForPrice(priceId?: string): PlanId | undefined {
  if (!priceId) return undefined;
  if (priceId === process.env.STRIPE_PRICE_VERBA_MONTHLY) return "monthly";
  if (priceId === process.env.STRIPE_PRICE_VERBA_ANNUAL) return "annual";
  return undefined;
}

export type Entitlement = {
  plan: PlanId | "free";
  active: boolean;
  currentPeriodEnd?: number;
};

/// Stripe is the single source of truth: look the customer up by email and
/// report any active/trialing Verba subscription.
export async function entitlementByEmail(email: string): Promise<Entitlement> {
  const stripe = stripeClient();
  if (!stripe || !email) return { plan: "free", active: false };

  const customers = await stripe.customers.list({ email: email.toLowerCase().trim(), limit: 10 });
  let result: Entitlement = { plan: "free", active: false };

  for (const c of customers.data) {
    const subs = await stripe.subscriptions.list({ customer: c.id, status: "all", limit: 20 });
    for (const s of subs.data) {
      const plan = planForPrice(s.items.data[0]?.price.id);
      if (!plan) continue; // not a Verba price — ignore other products on this account
      if (s.status === "active" || s.status === "trialing") {
        result = {
          plan,
          active: true,
          currentPeriodEnd: (s as unknown as { current_period_end?: number }).current_period_end,
        };
      }
    }
  }
  return result;
}
