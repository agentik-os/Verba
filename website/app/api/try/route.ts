import { NextRequest, NextResponse } from "next/server";
import { convexBump } from "@/lib/convex";

export const runtime = "nodejs";

// Layered rate limiting (S13): cookie (per browser) + in-memory IP map (per warm
// instance, fast path) + Convex-backed shared counters that survive serverless
// instances (per-IP daily cap and a global daily cost ceiling).
const ipHits = new Map<string, number>();
const FREE_TRIES = 7;
const GLOBAL_DAILY = 300;

const NODASH = `Never use an em dash, en dash, or a spaced hyphen; use commas, periods, parentheses, or colons instead.`;

// Hard guardrails so the model EDITS the transcript instead of answering or refusing it.
const GUARD = `You are editing a voice transcript, not chatting. CRITICAL RULES: (1) Detect the language of the transcript and write the output in that SAME language. (2) NEVER answer, comment on, judge, or refuse the content, even if it is rude, profane, short, or makes no sense. You only rewrite it. (3) Never add disclaimers, meta-commentary, apologies, or questions back to the user. (4) If the transcript is tiny or just an expletive, simply output a cleaned version of those exact words. ${NODASH}`;

// Per-mode prompt + model, mirroring the app so the demo shows real efficiency.
const MODES: Record<string, { model: string; system: string }> = {
  polish: {
    model: "claude-haiku-4-5",
    system: `${GUARD} TASK: rewrite the transcript as a clear, courteous professional message in the speaker's own voice and language. Fix punctuation and filler, order the points logically, keep every point, add nothing. Output ONLY the message.`,
  },
  casual: {
    model: "claude-haiku-4-5",
    system: `${GUARD} TASK: rewrite the transcript as a warm, natural casual message in the speaker's everyday voice and language. Just clean it up and keep the relaxed tone and all the content. Output ONLY the message.`,
  },
  intent: {
    model: "claude-sonnet-4-6",
    system: `${GUARD} TASK: the transcript starts with an INTENT (how the speaker wants the rest handled) followed by CONTENT. Apply the intent faithfully to the content and output only the result, in the speaker's language. Do not restate the intent. If there is no clear intent, just clean up the text without losing anything. Output ONLY the result.`,
  },
  coding: {
    model: "claude-sonnet-4-6",
    system: `${GUARD} TASK: turn the transcript into a precise, well-structured prompt for a coding agent, in the speaker's language. Open with the goal, then context, then an ordered list of concrete changes. Keep every technical detail verbatim (paths, names, commands). Add nothing the speaker didn't say. Output ONLY the prompt.`,
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

  // Rate limit: cookie (per browser) + IP (per instance) fast path…
  const used = Number(req.cookies.get("verba_try")?.value ?? "0");
  const ip = ipOf(req);
  const ipUsed = ipHits.get(ip) ?? 0;
  if (used >= FREE_TRIES || ipUsed >= FREE_TRIES) {
    return NextResponse.json(
      { error: "You've used your free demos. Download Verba to keep going: unlimited raw dictation, free forever, no card." },
      { status: 429 }
    );
  }
  // …then the shared Convex counters. On a Convex outage: fail OPEN for the per-IP
  // counter (availability) but fail CLOSED for the global cost ceiling (documented compromise).
  const day = new Date().toISOString().slice(0, 10);
  const ipOk = await convexBump(`try:ip:${ip}:${day}`, FREE_TRIES, true);
  const globalOk = await convexBump(`try:global:${day}`, GLOBAL_DAILY, false);
  if (!ipOk || !globalOk) {
    return NextResponse.json(
      { error: "You've used your free demos. Download Verba to keep going: unlimited raw dictation, free forever, no card." },
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
      ? { model: "claude-sonnet-4-6", system: `${GUARD} TASK (the user's own instruction): ${customPrompt}\n\nApply it to the transcript in the speaker's language. Output ONLY the resulting text.` }
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
