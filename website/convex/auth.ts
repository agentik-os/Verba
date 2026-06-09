import { sha256 } from "js-sha256";
import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// ---- shared guard, used by history/notes/stats/leaderboard/wishlist/feedback ----
// The client always sends the RAW 64-char hex device secret; we store/compare its sha256.
export async function requireDevice(ctx: any, uid: string, secret: string) {
  if (!(await deviceOk(ctx, uid, secret))) throw new Error("unauthorized");
}

/// Non-throwing variant (used to compute `me`/`mine` flags on public queries).
export async function deviceOk(ctx: any, uid: string, secret: string): Promise<boolean> {
  if (!uid || !secret) return false;
  const hash = sha256(secret);
  const rows = await ctx.db
    .query("device_auth")
    .withIndex("by_uid", (q: any) => q.eq("uid", uid))
    .collect();
  return rows.some((r: any) => r.secretHash === hash);
}

// ---- app-session token verification (HMAC-SHA256, shared APP_TOKEN_SECRET) ----
// Token format: "v1.<base64url(JSON{e,c,iat})>.<hex hmac of the b64url payload>"
// (Convex runtime has no Buffer — decode base64url via atob + TextDecoder.)
function b64urlToUtf8(s: string): string {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (s.length % 4)) % 4);
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new TextDecoder().decode(bytes);
}

export function verifyToken(token: string): { email: string; code: string } | null {
  const secret = process.env.APP_TOKEN_SECRET;
  if (!secret) return null;
  const [ver, payload, sig] = token.split(".");
  if (ver !== "v1" || !payload || !sig) return null;
  if (sha256.hmac(secret, payload) !== sig) return null; // hex compare
  try {
    const p = JSON.parse(b64urlToUtf8(payload));
    if (!p.e || !p.c || !p.iat) return null;
    if (Date.now() / 1000 - p.iat > 365 * 86400) return null; // 1-year validity
    return { email: p.e, code: p.c };
  } catch {
    return null;
  }
}

/// Register this device's secret under a uid (idempotent).
/// - Anon device uids ("anon-…") self-claim their FIRST device row.
/// - Account uids (a Clerk referral code) need a valid app-session token proving ownership.
/// - Any ADDITIONAL device on an existing uid needs a token (multi-Mac case).
export const register = mutation({
  args: { uid: v.string(), secret: v.string(), token: v.optional(v.string()) },
  handler: async (ctx, a) => {
    if (!/^[0-9a-f]{64}$/.test(a.secret)) throw new Error("bad secret");
    const secretHash = sha256(a.secret);
    const rows = await ctx.db
      .query("device_auth")
      .withIndex("by_uid", (q) => q.eq("uid", a.uid))
      .collect();
    if (rows.some((r) => r.secretHash === secretHash)) return { ok: true }; // idempotent
    if (rows.length === 0) {
      // First claim. Account uids need a token proving ownership; anon device uids
      // are self-claimed. Legacy uids: first caller claims (accepted, day-old base).
      if (!a.uid.startsWith("anon-")) {
        const t = a.token ? verifyToken(a.token) : null;
        if (!t || t.code !== a.uid) throw new Error("unauthorized");
      }
    } else {
      // Additional device on an existing uid: ONLY via a valid account token.
      const t = a.token ? verifyToken(a.token) : null;
      if (!t || t.code !== a.uid) throw new Error("unauthorized");
    }
    if (rows.length >= 10) throw new Error("too many devices");
    await ctx.db.insert("device_auth", { uid: a.uid, secretHash, created: Date.now() });
    return { ok: true };
  },
});

/// Cheap registered-device check for server bridges (e.g. /api/wishlist comment).
export const check = query({
  args: { uid: v.string(), secret: v.string() },
  handler: async (ctx, a) => {
    return await deviceOk(ctx, a.uid, a.secret);
  },
});
