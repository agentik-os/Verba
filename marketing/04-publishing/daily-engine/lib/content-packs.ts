// Content packs: map a calendar day (pillar + hook) to a video SCRIPT + image prompt.
// The SCRIPT is the data injected into timeline-template.html (window.__SCRIPT).
// One pack per pillar family (P1..P5). All copy obeys R-NODASH (no em/en dash) and the
// Verba brand law (near-black + one red accent, product-UI led, VO voice Eric).
//
// Every string here is scanned for "—"/"–" by the engine before render. Keep it clean.

export type Script = {
  dur: number;
  vo: string; // ElevenLabs Eric voice-over, doubles the captions on hooks/announcements
  s1: { text: string; size?: string };
  s2: { eyebrow?: string; html: string };
  s3: { html: string; ids: string[]; revealSrc: string };
  s4: { pill?: string; dictate: string; belowSrc?: string; below?: string };
  s5: { brand?: string; sub?: string; cta?: string };
};

export type Pack = {
  imagePrompt: string; // Higgsfield nano_banana_2 Product-UI hero, brand-locked, no readable "Composio"
  script: Script;
};

const RECDOT = '<span class="dotr" style="background:#ff5a4d"></span>';

// P2 - Private on-device (day 1). Product-UI hero + Motion-UI closed-loop privacy story.
const P2: Pack = {
  imagePrompt:
`A straight-on product hero photograph of the Verba macOS menu-bar dictation app on an Apple-Silicon MacBook Pro in a quiet near-black room. A dark macOS window overlay card is open in the center of the screen, showing a live dictation session. The only text visible inside the app card reads exactly, on three short lines: "Verba", then "Listening on-device", then "Your audio stays on this Mac". A small overlay pill sits near the menu bar with the single word "Recording" and one lit red record dot. A soft thin device-boundary line is drawn around the whole Mac, and a small audio waveform sits clearly inside that boundary, with a tiny padlock and a small "Offline" chip. Palette: near-black background, a #0c0c10 window panel with hairline borders, off-white #f4f4f6 crisp interface text, the single red #ff5a4d record dot as the only vivid color, matte anodized aluminium. A small microphone glyph in a black rounded square sits as a watermark in the bottom-left corner. Lighting is one soft directional key from the upper-left, low-key and matte. The interface is a sharp real screenshot, never blurred; faint fine film grain lives only on the aluminium. No people, no cloud icons, no upload arrows, no neon, no rainbow, exactly one bright color.`,
  script: {
    dur: 16.0,
    vo: `Your dictation app might be uploading your voice right now. Most of them do. We built Verba the other way. Whisper and Parakeet run on your Mac. Your audio never leaves it. Local history, with a real off switch. Speak freely. Private by default.`,
    s1: { text: "Your dictation app is uploading your voice right now.", size: "sm" },
    s2: { eyebrow: "MOST APPS DO", html: `Every word you say<span class="muted">, </span><span class="accent">sent to a server.</span>` },
    s3: {
      html:
`<div class="center" style="top:44%;text-align:center">
  <div class="uicard" id="s3card" style="position:relative;left:0;right:0;top:0;margin:0 auto;max-width:888px">
    <div class="bar"><span class="dotr" style="background:#ff5f57"></span><span class="dotr" style="background:#febc2e"></span><span class="dotr" style="background:#28c840"></span><span class="lock" style="margin-left:auto">${RECDOT}Wi-Fi off</span></div>
    <div class="body" id="s3body">Cut the Wi-Fi. Verba keeps transcribing.<br><span class="warm">On-device.</span> Your audio stays here.</div>
  </div>
  <div class="muted" id="s3sub" style="font-size:38px;margin-top:34px;font-weight:500;letter-spacing:-.015em">Whisper and Parakeet run on your Mac.</div>
</div>`,
      ids: ["s3card", "s3body", "s3sub"],
      revealSrc:
`(t,t0,els,h)=>{els.s3card&&(els.s3card.style.transform='translateY('+((1-h.snap(h.inv(t,t0,t0+.5)))*30)+'px)');
 els.s3sub&&(els.s3sub.style.opacity=h.snap(h.inv(t,t0+1.4,t0+1.9)),els.s3sub.style.transform='translateY('+((1-h.snap(h.inv(t,t0+1.4,t0+1.9)))*24)+'px)');}`
    },
    s4: {
      pill: "Verba · rec",
      dictate: "audio never leaves your Mac",
      belowSrc:
`(t,t0,els,h)=>{const p=h.snap(h.inv(t,t0+2.1,t0+2.6));els.s4below&&(els.s4below.style.opacity=p,els.s4below.style.transform='translateY('+((1-p)*22)+'px)');}`,
      below: `<div id="s4below" class="lock" style="justify-content:center;font-size:34px"><span class="dotr" style="background:#ff5a4d"></span>Local history. A real off switch.</div>`
    },
    s5: { brand: "Verba", sub: "Private by default. Yours by design.", cta: "verba.run" }
  }
};

// Fallback generic pack (used if a pillar has no bespoke pack): product-UI hero + generic motion.
const GENERIC: Pack = {
  imagePrompt: P2.imagePrompt,
  script: {
    dur: 16.0,
    vo: `Verba is the Mac dictation app that became a voice agent. It transcribes on your Mac, cleans your text with the AI you already pay for, and acts on what you say, after you confirm. Speak it. Send it clean.`,
    s1: { text: "The Mac dictation app that became a voice agent.", size: "sm" },
    s2: { eyebrow: "JUST TALK", html: `Verba writes<span class="muted">, and </span><span class="accent">acts.</span>` },
    s3: {
      html:
`<div class="center" style="top:44%;text-align:center">
  <div class="big" style="font-size:150px;line-height:1"><span class="w">Just</span> <span class="accent w">talk.</span></div>
  <div class="line xs" id="s3eq" style="margin-top:28px;font-weight:600">It writes. It acts.</div>
  <div class="muted" id="s3sub" style="font-size:38px;margin-top:26px;font-weight:500">On-device. Your Claude sub. No key.</div>
</div>`,
      ids: ["s3eq", "s3sub"],
      revealSrc:
`(t,t0,els,h)=>{els.s3eq&&(els.s3eq.style.opacity=h.snap(h.inv(t,t0+.9,t0+1.4)),els.s3eq.style.transform='translateY('+((1-h.snap(h.inv(t,t0+.9,t0+1.4)))*28)+'px)');
 els.s3sub&&(els.s3sub.style.opacity=h.snap(h.inv(t,t0+1.5,t0+2.0)));}`
    },
    s4: { pill: "Verba · rec", dictate: "speak it, send it clean", below: `<div id="s4below" class="lock" style="justify-content:center;font-size:34px"><span class="dotr" style="background:#ff5a4d"></span>On-device. Confirm before it acts.</div>` },
    s5: { brand: "Verba", sub: "Speak it. Send it clean.", cta: "verba.run" }
  }
};

export function packForPillar(pillar: string): Pack {
  const p = (pillar || "").toUpperCase();
  if (p.includes("P2") || p.includes("PRIVATE") || p.includes("ON-DEVICE") || p.includes("DICTEE PRIVE")) return P2;
  return GENERIC;
}
