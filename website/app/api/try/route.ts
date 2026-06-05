import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

// Best-effort in-memory IP counter (per warm serverless instance). Combined with the
// cookie below it deters token farming. For a hard guarantee, back this with Upstash/KV.
const ipHits = new Map<string, number>();
const FREE_TRIES = 7;

const NODASH = `Never use an em dash, en dash, or a spaced hyphen; use commas, periods, parentheses, or colons instead.`;

// Per-mode prompt + model, mirroring the app so the demo shows real efficiency.
const MODES: Record<string, { model: string; system: string }> = {
  polish: {
    model: "claude-haiku-4-5",
    system: `Rewrite this raw voice transcript as a clear, courteous professional message in the speaker's own voice. Fix punctuation and filler, order the points logically, keep every point, add nothing. ${NODASH} Output ONLY the message.`,
  },
  casual: {
    model: "claude-haiku-4-5",
    system: `Rewrite this raw voice transcript as a warm, natural casual message in the speaker's everyday voice. Just clean it up and keep the relaxed tone and all the content. ${NODASH} Output ONLY the message.`,
  },
  intent: {
    model: "claude-sonnet-4-6",
    system: `The transcript starts with an INTENT (how the speaker wants the rest handled) followed by CONTENT. Apply the intent faithfully to the content and output only the result. Do not restate the intent. If no clear intent, just clean up the text without losing anything. ${NODASH} Output ONLY the result.`,
  },
  coding: {
    model: "claude-sonnet-4-6",
    system: `Turn this rambling voice transcript into a precise, well-structured prompt for a coding agent. Open with the goal, then context, then an ordered list of concrete changes. Keep every technical detail verbatim (paths, names, commands). Add nothing the speaker didn't say. ${NODASH} Output ONLY the prompt.`,
  },
};

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
      { error: "You've used your free demos. Download Verba to keep going, it's free up to 10,000 words/month." },
      { status: 429 }
    );
  }

  let audio: File | null = null;
  let modeKey = "polish";
  let customPrompt = "";
  try {
    const form = await req.formData();
    audio = form.get("audio") as File | null;
    modeKey = (form.get("mode") as string | null) ?? "polish";
    customPrompt = ((form.get("customPrompt") as string | null) ?? "").slice(0, 800).trim();
  } catch {
    return NextResponse.json({ error: "bad request" }, { status: 400 });
  }
  const mode =
    modeKey === "custom" && customPrompt
      ? { model: "claude-sonnet-4-6", system: `${customPrompt}\n\n${NODASH} Output ONLY the resulting text.` }
      : MODES[modeKey] ?? MODES.polish;
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
    if (!original) return NextResponse.json({ error: "We couldn't hear anything, try again." }, { status: 422 });

    // Flow mode: raw dictation, no AI rewriting.
    if (modeKey === "flow") {
      ipHits.set(ip, ipUsed + 1);
      const res = NextResponse.json({ original, result: original, remaining: FREE_TRIES - (used + 1) });
      res.cookies.set("verba_try", String(used + 1), { path: "/", maxAge: 60 * 60 * 24 * 30, httpOnly: true, sameSite: "lax" });
      return res;
    }

    // 2. Restructure with Claude.
    const cr = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": anthropic, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({
        model: mode.model,
        max_tokens: 1024,
        system: mode.system,
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
