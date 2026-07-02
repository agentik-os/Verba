import { clerkMiddleware } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

// The /atelier internal docs site is gated by HTTP Basic Auth (confidential: fundraising,
// investors). Everything else keeps Clerk's default behavior byte-identical. Fail closed:
// if ATELIER_PASSWORD is unset, /atelier always returns 401.
export default clerkMiddleware((auth, req) => {
  const { pathname } = req.nextUrl;
  if (pathname === "/atelier" || pathname.startsWith("/atelier/")) {
    const expected = process.env.ATELIER_PASSWORD;
    const header = req.headers.get("authorization");
    let ok = false;
    if (expected && header?.startsWith("Basic ")) {
      try {
        const decoded = atob(header.slice(6));
        const sep = decoded.indexOf(":");
        const user = sep >= 0 ? decoded.slice(0, sep) : decoded;
        const password = sep >= 0 ? decoded.slice(sep + 1) : "";
        ok = user === "verba" && password === expected;
      } catch {
        ok = false;
      }
    }
    if (!ok) {
      return new Response("Authentication required", {
        status: 401,
        headers: {
          "WWW-Authenticate": 'Basic realm="Verba Atelier", charset="UTF-8"',
          "X-Robots-Tag": "noindex, nofollow",
        },
      });
    }
    const res = NextResponse.next();
    res.headers.set("X-Robots-Tag", "noindex, nofollow");
    return res;
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
