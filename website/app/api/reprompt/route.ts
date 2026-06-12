import { NextRequest, NextResponse } from "next/server";
import { entitlementByEmail } from "@/lib/billing";
import { verifyAppToken } from "@/lib/apptoken";
import { convexBump } from "@/lib/convex";

export const runtime = "nodejs";

// Verba's own hosted AI rewriting endpoint. The macOS app calls this so users don't
// need their own API key: we run it on the company Anthropic key, gated by the user's
// app-session token (S2 — the email is taken from the verified token, never the body).
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// Only these models may be requested; anything else is forced to the default so a
// leaked token can't burn the key on expensive models.
const ALLOWED_MODELS = ["claude-sonnet-4-6", "claude-haiku-4-5", "claude-opus-4-6"];
const DEFAULT_MODEL = "claude-sonnet-4-6";

// In-memory fast-path short-circuit only — the authoritative daily counter lives in
// Convex (ratelimit:bump) and survives serverless instances.
const freeHits = new Map<string, { day: string; n: number }>();
const FREE_DAILY = 60;

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const anthropic = process.env.ANTHROPIC_API_KEY;
  const openrouter = process.env.OPENROUTER_API_KEY;
  if (!anthropic && !openrouter) {
    return NextResponse.json({ error: "AI rewriting isn't configured yet." }, { status: 503, headers: cors });
  }

  // S2: require a valid app-session token; the email comes from it, never the body.
  const tok = verifyAppToken(req.headers.get("authorization"));
  if (!tok) {
    return NextResponse.json({ error: "Sign in to use Verba's AI rewriting." }, { status: 401, headers: cors });
  }
  const email = tok.email;

  let body: { transcript?: string; system?: string; model?: string; image?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Bad request" }, { status: 400, headers: cors });
  }

  const transcript = body.transcript ?? "";
  const system = body.system ?? "";
  const model = ALLOWED_MODELS.includes(body.model ?? "") ? (body.model as string) : DEFAULT_MODEL;
  const image = body.image; // optional base64 PNG (Context mode)

  if (!transcript && !image) {
    return NextResponse.json({ error: "Nothing to rewrite." }, { status: 400, headers: cors });
  }

  // Gate: active subscribers are generous; everyone else gets a daily allowance.
  const ent = await entitlementByEmail(email).catch(() => ({ active: false }));
  if (!ent.active) {
    const day = new Date().toISOString().slice(0, 10);
    const limitMsg = NextResponse.json(
      { error: "Daily free limit reached. Upgrade to Pro for unlimited rewriting." },
      { status: 402, headers: cors }
    );
    // Fast path: this warm instance already knows the limit is hit.
    const rec = freeHits.get(email);
    const n = rec && rec.day === day ? rec.n : 0;
    if (n >= FREE_DAILY) return limitMsg;
    // Authoritative shared counter. FAIL CLOSED on a Convex outage: serverless spins many instances
    // so the per-instance fast path can't bound global spend, and a public free tier on the company
    // Anthropic key must not become unlimited if the counter is unreachable.
    const allowed = await convexBump(`reprompt:${email}:${day}`, FREE_DAILY, false);
    if (!allowed) {
      freeHits.set(email, { day, n: FREE_DAILY });
      return limitMsg;
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

  // Primary engine: OpenRouter open-source (cost-controlled — see VerbaMobile economics
  // report 2026-06-12: hosted Sonnet loses money on heavy users; qwen-2.5-72b holds an
  // ~85% margin worst case). Anthropic stays as the fallback when configured.
  try {
    if (openrouter) {
      const orModel = image
        ? (process.env.REPROMPT_VISION_MODEL ?? "qwen/qwen2.5-vl-72b-instruct")
        : (process.env.REPROMPT_MODEL ?? "qwen/qwen-2.5-72b-instruct");
      const orContent = image
        ? [
            { type: "image_url", image_url: { url: `data:image/png;base64,${image}` } },
            { type: "text", text: `Here is what I said. Use the screenshot to do it:\n\n<request>\n${transcript}\n</request>` },
          ]
        : userText;
      const r = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: { Authorization: `Bearer ${openrouter}`, "content-type": "application/json" },
        body: JSON.stringify({
          model: orModel,
          provider: { sort: "throughput" },   // measured: 0.9s vs 7s on default routing
          messages: [
            { role: "system", content: system },
            { role: "user", content: orContent },
          ],
        }),
      });
      const data = await r.json();
      const text: string = data?.choices?.[0]?.message?.content?.trim() ?? "";
      if (r.ok && text) {
        return NextResponse.json({ text }, { headers: cors });
      }
      // fall through to Anthropic if configured; else surface the OpenRouter error
      if (!anthropic) {
        return NextResponse.json(
          { error: data?.error?.message ?? "Rewrite failed." },
          { status: r.ok ? 502 : r.status, headers: cors }
        );
      }
    }
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropic!,
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
