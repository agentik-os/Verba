import { NextRequest, NextResponse } from "next/server";
import { auth, clerkClient } from "@clerk/nextjs/server";

export const runtime = "nodejs";

function newCode() {
  return Math.random().toString(36).slice(2, 10);
}

/// Sets up referral state for the signed-in user:
///  1. ensures they have a stable `referralCode` on their Clerk account (so the webhook
///     can map an incoming referral back to this account),
///  2. records who referred THEM (`referredBy`) from the affiliate cookie, once.
/// Returns the user's own referral code so the macOS app can display the real link.
export async function POST(req: NextRequest) {
  const { userId } = await auth();
  if (!userId) return NextResponse.json({ error: "unauthenticated" }, { status: 401 });

  let ref = "";
  try {
    const body = await req.json();
    ref = (body.ref ?? "").toString().slice(0, 64).trim();
  } catch {}

  const client = await clerkClient();
  const user = await client.users.getUser(userId);
  const meta = { ...(user.publicMetadata ?? {}) } as Record<string, unknown>;

  // 1. Ensure a stable own code.
  let referralCode = (meta.referralCode as string | undefined) ?? "";
  if (!referralCode) {
    referralCode = newCode();
    meta.referralCode = referralCode;
  }

  // 2. Record who referred this user (only once, never self).
  if (ref && !meta.referredBy && ref !== referralCode) {
    meta.referredBy = ref;
    meta.referredAt = new Date().toISOString();
  }

  await client.users.updateUserMetadata(userId, { publicMetadata: meta });
  return NextResponse.json({ ok: true, referralCode });
}
