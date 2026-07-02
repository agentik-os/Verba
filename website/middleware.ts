import { clerkMiddleware } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

// The /atelier internal docs site is gated for confidential content (fundraising, investors).
// Three ways in, checked in order: magic link (?key=<password> → sets a 30-day cookie and
// redirects the key out of the URL — for in-app webviews that never show the Basic-auth
// popup), the atelier_auth cookie (sha256 of the password), then HTTP Basic Auth (username
// case-insensitive — phone keyboards auto-capitalize; password exact). Everything else keeps
// Clerk's default behavior byte-identical. Fail closed: if ATELIER_PASSWORD is unset,
// /atelier always returns 401.
const ATELIER_COOKIE = "atelier_auth";

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function unauthorized(): Response {
  return new Response("Authentication required", {
    status: 401,
    headers: {
      "WWW-Authenticate": 'Basic realm="Verba Atelier", charset="UTF-8"',
      "X-Robots-Tag": "noindex, nofollow",
    },
  });
}

function setAuthCookie(res: NextResponse, hash: string): void {
  res.cookies.set(ATELIER_COOKIE, hash, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/atelier",
    maxAge: 2592000, // 30 days
  });
}

function allow(): NextResponse {
  const res = NextResponse.next();
  res.headers.set("X-Robots-Tag", "noindex, nofollow");
  return res;
}

export default clerkMiddleware(async (auth, req) => {
  const { pathname, searchParams } = req.nextUrl;
  if (pathname === "/atelier" || pathname.startsWith("/atelier/")) {
    const expected = process.env.ATELIER_PASSWORD;
    if (!expected) return unauthorized();

    // 1. Magic link: ?key=<password> → 307 to the same URL without the key + auth cookie.
    const key = searchParams.get("key");
    if (key !== null) {
      if (key !== expected) return unauthorized();
      const clean = req.nextUrl.clone();
      clean.searchParams.delete("key");
      const res = NextResponse.redirect(clean, 307);
      setAuthCookie(res, await sha256Hex(expected));
      return res;
    }

    // 2. Cookie: previously authenticated via magic link or Basic auth.
    if (req.cookies.get(ATELIER_COOKIE)?.value === (await sha256Hex(expected))) {
      return allow();
    }

    // 3. Basic auth (user case-insensitive, password exact).
    const header = req.headers.get("authorization");
    if (header?.startsWith("Basic ")) {
      try {
        const decoded = atob(header.slice(6));
        const sep = decoded.indexOf(":");
        const user = sep >= 0 ? decoded.slice(0, sep) : decoded;
        const password = sep >= 0 ? decoded.slice(sep + 1) : "";
        if (user.toLowerCase() === "verba" && password === expected) {
          const res = allow();
          setAuthCookie(res, await sha256Hex(expected));
          return res;
        }
      } catch {
        // Malformed header → fall through to 401.
      }
    }

    return unauthorized();
  }
  // Non-atelier paths: defer to Clerk's default handling.
  return undefined;
});

export const config = {
  matcher: [
    "/atelier/:path*",
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
