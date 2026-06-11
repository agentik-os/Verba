// Single home for the Convex deployment URL + the HTTP plumbing previously
// copy-pasted into individual API routes. Server-side only.
export const CONVEX_BASE = "https://prestigious-wolf-290.eu-west-1.convex.cloud";

/** Call a Convex function over its HTTP API. Returns the function's `value`, or throws. */
export async function convexCall<T>(
  kind: "query" | "mutation",
  path: string,
  args: Record<string, unknown>
): Promise<T> {
  const r = await fetch(`${CONVEX_BASE}/api/${kind}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ path, args, format: "json" }),
  });
  const json = await r.json();
  if (!r.ok || json?.status !== "success") {
    const msg = json?.errorMessage ?? `Convex ${path} failed (${r.status})`;
    throw new Error(msg);
  }
  return json.value as T;
}

/**
 * Shared daily rate-limit counter (Convex `ratelimit:bump`, survives serverless
 * instances). Returns true while within `limit`. The mutation requires our server
 * key (APP_TOKEN_SECRET) so the public cannot burn counters directly.
 * `failOpen` decides what a Convex transport failure means: true = allow the
 * request anyway (per-IP limits), false = reject (global cost ceilings).
 */
export async function convexBump(key: string, limit: number, failOpen: boolean): Promise<boolean> {
  try {
    const res = await convexCall<{ allowed: boolean; n: number }>("mutation", "ratelimit:bump", {
      key,
      limit,
      serverKey: process.env.APP_TOKEN_SECRET ?? "",
    });
    return res.allowed;
  } catch {
    return failOpen;
  }
}
