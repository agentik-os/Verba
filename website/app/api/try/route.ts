import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

// Best-effort in-memory IP counter (per warm serverless instance). Combined with the
// cookie below it deters token farming. For a hard guarantee, back this with Upstash/KV.
const ipHits = new Map<string, number>();
const FREE_TRIES = 2;

const SYSTEM = `You clean up a raw voice transcript into clear, well-structured text in the
speaker's own voice. Fix punctuation and filler, reorder for clarity, keep every point,
never add facts. Output ONLY the cleaned text.`;

function ipOf(req: NextRequest): string {
  const xff = req.headers.get("x-forwarded-for") ?? "";
  return xff.split(",")[0].trim() || req.headers.get("x-real-ip") || "unknown";
}

export async function POST(req: NextRequest) {
  const openai = process.env.OPENAI_API_KEY;
  const anthropic = process.env.ANTHROPIC_API_KEY;
  if (!openai || !anthropic) {
    return NextResponse.json({ error: "The live demo isn't configured yet." }, { status: 503 });
  }

  // Rate limit: cookie (per browser) + IP (per instance).
  const used = Number(req.cookies.get("verba_try")?.value ?? "0");
  const ip = ipOf(req);
  const ipUsed = ipHits.get(ip) ?? 0;
  if (used >= FREE_TRIES || ipUsed >= FREE_TRIES) {
    return NextResponse.json(
      { error: "You've used your free demos. Download Verba to keep going — it's free up to 10,000 words/month." },
      { status: 429 }
    );
  }

  let audio: File | null = null;
  try {
    const form = await req.formData();
    audio = form.get("audio") as File | null;
  } catch {
    return NextResponse.json({ error: "bad request" }, { status: 400 });
  }
  if (!audio) return NextResponse.json({ error: "no audio" }, { status: 400 });
  if (audio.size > 8_000_000) return NextResponse.json({ error: "clip too long (max ~1 min)" }, { status: 413 });

  try {
    // 1. Transcribe with OpenAI.
    const tForm = new FormData();
    tForm.append("file", audio, "clip.webm");
    tForm.append("model", "gpt-4o-transcribe");
    const tr = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openai}` },
      body: tForm,
    });
    if (!tr.ok) return NextResponse.json({ error: "transcription failed" }, { status: 502 });
    const original = ((await tr.json()).text ?? "").trim();
    if (!original) return NextResponse.json({ error: "We couldn't hear anything — try again." }, { status: 422 });

    // 2. Restructure with Claude Haiku.
    const cr = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": anthropic, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({
        model: "claude-haiku-4-5",
        max_tokens: 1024,
        system: SYSTEM,
        messages: [{ role: "user", content: `Raw transcript:\n\n${original}` }],
      }),
    });
    if (!cr.ok) return NextResponse.json({ error: "cleanup failed" }, { status: 502 });
    const cj = await cr.json();
    const result = (cj.content ?? []).map((b: { type: string; text?: string }) => (b.type === "text" ? b.text : "")).join("").trim();

    ipHits.set(ip, ipUsed + 1);
    const res = NextResponse.json({ original, result, remaining: FREE_TRIES - (used + 1) });
    res.cookies.set("verba_try", String(used + 1), { path: "/", maxAge: 60 * 60 * 24 * 30, httpOnly: true, sameSite: "lax" });
    return res;
  } catch {
    return NextResponse.json({ error: "something went wrong" }, { status: 500 });
  }
}
