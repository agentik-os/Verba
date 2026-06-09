import crypto from "crypto";

// App-session token: HMAC-SHA256 over a base64url JSON payload, signed with
// APP_TOKEN_SECRET (shared with the Convex deployment, which verifies the same
// format in convex/auth.ts). Issued by /api/link-referral after a Clerk sign-in,
// stored in the macOS app's Keychain, and sent as "Authorization: Bearer v1.…"
// on every protected app→site call (reprompt / portal / username / entitlement).
export type AppToken = { email: string; code: string };

export function signAppToken(email: string, code: string): string {
  const secret = process.env.APP_TOKEN_SECRET!;
  const payload = Buffer.from(
    JSON.stringify({ e: email.toLowerCase(), c: code, iat: Math.floor(Date.now() / 1000) })
  ).toString("base64url");
  const sig = crypto.createHmac("sha256", secret).update(payload).digest("hex");
  return `v1.${payload}.${sig}`;
}

/// Verify "Authorization: Bearer v1.…". Returns null on ANY failure (missing env included).
export function verifyAppToken(authHeader: string | null): AppToken | null {
  const secret = process.env.APP_TOKEN_SECRET;
  if (!secret || !authHeader?.startsWith("Bearer ")) return null;
  const [ver, payload, sig] = authHeader.slice(7).trim().split(".");
  if (ver !== "v1" || !payload || !sig) return null;
  const expect = crypto.createHmac("sha256", secret).update(payload).digest();
  let got: Buffer;
  try {
    got = Buffer.from(sig, "hex");
  } catch {
    return null;
  }
  if (got.length !== expect.length || !crypto.timingSafeEqual(expect, got)) return null;
  try {
    const p = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
    if (!p.e || !p.c || !p.iat || Date.now() / 1000 - p.iat > 365 * 86400) return null;
    return { email: p.e, code: p.c };
  } catch {
    return null;
  }
}
