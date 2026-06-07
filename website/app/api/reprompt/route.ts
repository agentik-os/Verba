import { NextRequest, NextResponse } from "next/server";
import { entitlementByEmail } from "@/lib/billing";

export const runtime = "nodejs";

// Verba's own hosted AI rewriting endpoint. The macOS app calls this so users don't
// need their own API key: we run it on the company Anthropic key, gated by the user's
// account (active subscribers, plus a small daily allowance that covers the free trial).
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

// Best-effort per-email daily allowance for non-subscribers (covers the free trial).
// The app enforces the real trial limit; this just protects the key from abuse.
// Cold starts reset it; back with Upstash/KV for a hard guarantee.
const freeHits = new Map<string, { day: string; n: number }>();
const FREE_DAILY = 60;

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const anthropic = process.env.ANTHROPIC_API_KEY;
  if (!anthropic) {
    return NextResponse.json({ error: "AI rewriting isn't configured yet." }, { status: 503, headers: cors });
  }

  let body: { email?: string; transcript?: string; system?: string; model?: string; image?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Bad request" }, { status: 400, headers: cors });
  }

  const email = (body.email ?? "").trim().toLowerCase();
  const transcript = body.transcript ?? "";
  const system = body.system ?? "";
  const model = body.model || "claude-sonnet-4-6";
  const image = body.image; // optional base64 PNG (Context mode)

  if (!email) {
    return NextResponse.json({ error: "Sign in to use Verba's AI rewriting." }, { status: 401, headers: cors });
  }
  if (!transcript && !image) {
    return NextResponse.json({ error: "Nothing to rewrite." }, { status: 400, headers: cors });
  }

  // Gate: active subscribers are generous; everyone else gets a daily allowance.
  const ent = await entitlementByEmail(email).catch(() => ({ active: false }));
  if (!ent.active) {
    const day = new Date().toISOString().slice(0, 10);
    const rec = freeHits.get(email);
    const n = rec && rec.day === day ? rec.n : 0;
    if (n >= FREE_DAILY) {
      return NextResponse.json(
        { error: "Daily free limit reached. Upgrade to Pro for unlimited rewriting." },
        { status: 402, headers: cors }
      );
    }
    freeHits.set(email, { day, n: n + 1 });
  }

  const userText = `Here is the raw voice transcript to restructure:\n\n<transcript>\n${transcript}\n</transcript>`;
  const content = image
    ? [
        { type: "image", source: { type: "base64", media_type: "image/png", data: image } },
        { type: "text", text: `Here is what I said. Use the screenshot to do it:\n\n<request>\n${transcript}\n</request>` },
      ]
    : userText;

  try {
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropic,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({ model, max_tokens: 8000, system, messages: [{ role: "user", content }] }),
    });
    const data = await r.json();
    if (!r.ok) {
      return NextResponse.json({ error: data?.error?.message ?? "Rewrite failed." }, { status: r.status, headers: cors });
    }
    const text: string = (data.content ?? [])
      .filter((b: { type: string }) => b.type === "text")
      .map((b: { text: string }) => b.text)
      .join("")
      .trim();
    if (!text) {
      return NextResponse.json({ error: "Empty response." }, { status: 502, headers: cors });
    }
    return NextResponse.json({ text }, { headers: cors });
  } catch {
    return NextResponse.json({ error: "Rewrite failed." }, { status: 502, headers: cors });
  }
}
