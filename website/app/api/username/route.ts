import { NextRequest, NextResponse } from "next/server";
import { currentUser, clerkClient } from "@clerk/nextjs/server";

export const runtime = "nodejs";

// The public leaderboard identity. A deliberate handle the user chooses — NEVER
// their real first/last name or email. Stored on the Clerk user's publicMetadata
// so it syncs across the macOS app and the web.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Cache-Control": "no-store",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// Sanitize a candidate username. Returns the cleaned value or null if invalid.
// Rules: trim, collapse internal whitespace, 2–24 chars, letters/digits/_/-/space.
function sanitizeUsername(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const collapsed = raw.replace(/\s+/g, " ").trim();
  if (collapsed.length < 2 || collapsed.length > 24) return null;
  if (!/^[A-Za-z0-9_\- ]+$/.test(collapsed)) return null;
  return collapsed;
}

// Resolve the Clerk userId for this request: an explicit email (app→site model,
// like /api/entitlement) takes precedence, else the signed-in web user.
async function resolveUserId(email: string): Promise<string | null> {
  if (email) {
    const client = await clerkClient();
    const list = await client.users.getUserList({ emailAddress: [email] });
    return list.data[0]?.id ?? null;
  }
  const user = await currentUser();
  return user?.id ?? null;
}

export async function GET(req: NextRequest) {
  try {
    const email = (req.nextUrl.searchParams.get("email") ?? "").trim();
    const userId = await resolveUserId(email);
    if (!userId) {
      return NextResponse.json({ username: null }, { headers: cors });
    }
    const client = await clerkClient();
    const user = await client.users.getUser(userId);
    const username = (user.publicMetadata?.username as string | undefined) ?? null;
    return NextResponse.json({ username }, { headers: cors });
  } catch {
    return NextResponse.json({ username: null }, { headers: cors });
  }
}

export async function POST(req: NextRequest) {
  let body: { username?: unknown; email?: unknown } = {};
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "invalid body" }, { status: 400, headers: cors });
  }

  const username = sanitizeUsername(body.username);
  if (!username) {
    return NextResponse.json(
      { error: "username must be 2–24 chars, letters/digits/spaces/_/- only" },
      { status: 400, headers: cors }
    );
  }

  const email = typeof body.email === "string" ? body.email.trim() : "";
  const userId = await resolveUserId(email);
  if (!userId) {
    return NextResponse.json({ error: "user not found" }, { status: 400, headers: cors });
  }

  const client = await clerkClient();
  const existing = (await client.users.getUser(userId)).publicMetadata ?? {};
  await client.users.updateUserMetadata(userId, {
    publicMetadata: { ...existing, username },
  });
  return NextResponse.json({ username }, { headers: cors });
}
