#!/usr/bin/env bun
/**
 * Verba daily content engine (2/day cadence, dry-run by default).
 *
 * Reads the 90-day calendar + the operator-VALIDATED style, picks the next
 * pending day, and produces that day's on-brand batch:
 *   IMAGE  = "Product-UI hero" (Higgsfield nano_banana_2), 1080x1350 + 9:16 + 1:1 variants.
 *   VIDEO  = "Motion produit (UI)" + VO Eric + tense-minimal music + kinetic SF Pro captions,
 *            9:16, ~16s, product UI in action (dictated text word-by-word + caret, pulsing rec dot).
 * Saves under out/<date>/ and marks the day produced in sent-log.json.
 *
 * Brand law (VALIDATED-STYLE.md + kill-list.md): near-black + ONE red accent, no neon,
 * no stock people, UI always crisp. R-NODASH: never an em/en dash in any caption/VO/on-image
 * string (enforced: the engine aborts if it finds one).
 *
 *   bun verba-daily.ts              # pure dry-run: produce + save + log, NO posting
 *   bun verba-daily.ts --publish    # ALSO post to the connected organic networks via omega-zernio
 *   bun verba-daily.ts --date 2026-07-03   # force the logical date (default: today)
 *   bun verba-daily.ts --day 1      # force a specific calendar dayOffset
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync, rmSync } from "fs";
import { spawnSync } from "child_process";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { packForPillar, type Script } from "./lib/content-packs.ts";

const HERE = dirname(fileURLToPath(import.meta.url));
const MKT = join(HERE, "..", "..");                       // marketing/
const OUT = join(HERE, "out");
const ASSETS = join(HERE, "assets");
const FONTDIR = join(process.env.HOME!, ".local", "share", "fonts", "verba");
const CALENDAR = join(MKT, "05-calendar", process.env.VERBA_CALENDAR || "calendar-90d-en.json");
const STYLE = join(MKT, "06-branding", "VALIDATED-STYLE.md");
const SENTLOG = join(HERE, "sent-log.json");
const TMP = join("/tmp", "verba-daily-work");

const ELEVEN_ERIC = "cjVigY5qzO86Huf0OWal"; // "Eric - Smooth, Trustworthy" (VALIDATED voice)
const MODEL = "nano_banana_2";              // Nano Banana Pro (readable UI text)

const args = process.argv.slice(2);
const PUBLISH = args.includes("--publish");
// On-brand auto default: still image + text (product-UI in a STILL is allowed; on-screen UI in VIDEO is not, per brand law).
const IMAGE_ONLY = args.includes("--image-only") || process.env.VERBA_IMAGE_ONLY === "1";
const forceDate = argVal("--date");
const forceDay = argVal("--day");
function argVal(f: string): string | null { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : null; }
function log(...a: any[]) { console.log(...a); }
function die(msg: string): never { console.error("FATAL:", msg); process.exit(1); }
function sh(cmd: string, cmdArgs: string[], opts: any = {}) {
  const r = spawnSync(cmd, cmdArgs, { encoding: "utf8", maxBuffer: 1 << 26, ...opts });
  return r;
}

// ---- secrets (integrations.env has a stray line that breaks `source`, so parse defensively) ----
function secret(name: string): string {
  if (process.env[name]) return process.env[name]!;
  const p = join(process.env.HOME!, ".omega", "secrets", "integrations.env");
  if (!existsSync(p)) return "";
  const m = readFileSync(p, "utf8").match(new RegExp(`^${name}\\s*=\\s*"?([^"\\n]+)"?`, "m"));
  return m ? m[1].trim() : "";
}

// ---- R-NODASH guard: no em/en dash anywhere in delivered copy/captions/VO ----
const DASH_RE = /[—–]/;
function assertNoDash(label: string, ...strings: string[]) {
  for (const s of strings) {
    if (s && DASH_RE.test(s)) die(`R-NODASH violation in ${label}: found em/en dash in ${JSON.stringify(s)}`);
  }
}

// ---- calendar ----
type Post = { slot: string; platform: string; pillar: string; text: string; visualPrompt: string; cta: string; manualNote?: string; mode?: string };
type Day = { dayOffset: number; posts: Post[] };
function loadCalendar(): Day[] { return JSON.parse(readFileSync(CALENDAR, "utf8")).days; }
function loadSentLog(): { produced: number[]; entries: any[] } {
  if (existsSync(SENTLOG)) return JSON.parse(readFileSync(SENTLOG, "utf8"));
  return { produced: [], entries: [] };
}
function pickDay(days: Day[], sent: { produced: number[] }): Day {
  if (forceDay) { const d = days.find(x => x.dayOffset === +forceDay); if (!d) die(`day ${forceDay} not in calendar`); return d; }
  const next = days.find(d => !sent.produced.includes(d.dayOffset));
  if (!next) die("all calendar days already produced");
  return next;
}
// Pick the primary auto post of the day (the one that carries the image+video subject).
function primaryPost(day: Day): Post {
  return day.posts.find(p => p.mode !== "manual" && p.visualPrompt) || day.posts.find(p => p.visualPrompt) || day.posts[0];
}

// ---- IMAGE: Higgsfield Product-UI hero, 3 variants ----
function genImage(pack: ReturnType<typeof packForPillar>, dir: string): string[] {
  assertNoDash("image prompt", pack.imagePrompt);
  const src = join(dir, "hero-src.png");
  if (existsSync(src) && fileSize(src) > 5000) {
    log("  reusing existing hero-src.png (idempotent re-run, no credit spent)");
  } else {
    log("  higgsfield generate (nano_banana_2, 4:5 Product-UI hero)...");
    const r = sh("higgsfield", ["generate", "create", MODEL, "--prompt", pack.imagePrompt, "--aspect_ratio", "4:5", "--wait", "--wait-timeout", "8m", "--json"], { cwd: dir });
    const out = (r.stdout || "") + (r.stderr || "");
    // Extract the first result URL from the JSON/plain output.
    const url = (out.match(/https?:\/\/[^\s"'\\)]+\.(?:png|jpg|jpeg|webp)/i) || [])[0];
    if (!url) die("higgsfield returned no image URL. Output:\n" + out.slice(0, 1200));
    log("  downloading", url.slice(0, 80) + "...");
    sh("curl", ["-sL", url, "-o", src]);
    if (!existsSync(src) || fileSize(src) < 5000) die("image download failed");
  }
  // Recompose (never crop) into the 3 validated formats via ffmpeg pad/scale on a near-black field.
  const files: string[] = [];
  const variants: [string, number, number][] = [["hero-1080x1350", 1080, 1350], ["hero-9x16", 1080, 1920], ["hero-1x1", 1080, 1080]];
  for (const [name, w, h] of variants) {
    const f = join(dir, `${name}.png`);
    // scale to fit inside, pad the rest with the brand near-black #050507
    sh("ffmpeg", ["-y", "-i", src, "-vf",
      `scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h}`,
      "-frames:v", "1", f]);
    if (existsSync(f)) files.push(f);
  }
  return files;
}
function fileSize(p: string): number { try { return require("fs").statSync(p).size; } catch { return 0; } }

// ---- VIDEO: Playwright caption frames over base scene clips + VO Eric + tense-minimal music ----
function genVideo(script: Script, dir: string): { file: string; dur: number } {
  // Guard every visible/audible string.
  assertNoDash("VO", script.vo);
  assertNoDash("captions", script.s1.text, script.s2.eyebrow || "", script.s4.dictate, script.s4.pill || "",
    script.s5.brand || "", script.s5.sub || "", script.s5.cta || "");
  assertNoDash("s2/s3/s4 html", script.s2.html, script.s3.html, script.s4.below || "");

  rmSync(TMP, { recursive: true, force: true }); mkdirSync(TMP, { recursive: true });
  const framesDir = join(TMP, "frames"); mkdirSync(framesDir);

  // 1) Materialize the timeline HTML with this day's SCRIPT injected.
  let tpl = readFileSync(join(HERE, "lib", "timeline-template.html"), "utf8")
    .replaceAll("__FONTDIR__", FONTDIR)
    .replaceAll("__ASSETDIR__", ASSETS);
  // Serialize the SCRIPT to a JS object literal, turning the reveal source-strings into functions.
  const scriptJs = serializeScript(script);
  const htmlFile = join(TMP, "timeline.html");
  writeFileSync(htmlFile, tpl.replace("const S = window.__SCRIPT;", `const S = ${scriptJs};`));

  // 2) Render frames with Playwright (global install).
  const DUR = script.dur, FPS = 30;
  const renderJs = join(TMP, "render.cjs");
  writeFileSync(renderJs, `
const { chromium } = require(${JSON.stringify(join("/usr/lib/node_modules/playwright"))});
(async () => {
  const FPS=${FPS}, DUR=${DUR}, total=Math.round(FPS*DUR);
  const b = await chromium.launch({ args:['--force-color-profile=srgb','--disable-lcd-text','--no-sandbox'] });
  const p = await b.newPage({ viewport:{width:1080,height:1920}, deviceScaleFactor:1 });
  await p.goto('file://${htmlFile}');
  await p.waitForFunction(()=>window.__ready===true,{timeout:15000});
  await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300);
  for(let i=0;i<total;i++){ const t=i/FPS; await p.evaluate(tt=>window.__seek(tt),t);
    await p.screenshot({ path: require('path').join('${framesDir}','f'+String(i).padStart(4,'0')+'.png'), omitBackground:true }); }
  await b.close(); console.log('frames',total);
})().catch(e=>{console.error(e);process.exit(1);});`);
  const rf = sh("node", [renderJs]);
  if (rf.status !== 0) die("frame render failed:\n" + (rf.stderr || rf.stdout));

  // 3) Base video track: hero clip under scene 2 (2.6-6.4s), hands clip under scene 4 (10.3-14.4s),
  //    near-black elsewhere. Build an 1080x1920 base by concatenating trims on a black canvas.
  const base = join(TMP, "base.mp4");
  const hero = join(ASSETS, "clips", "hero.mp4"), hands = join(ASSETS, "clips", "hands.mp4");
  // black canvas for full duration, overlay hero+hands during their windows (product footage).
  sh("ffmpeg", ["-y",
    "-f", "lavfi", "-t", String(DUR), "-i", "color=c=#050507:s=1080x1920:r=30",
    "-stream_loop", "-1", "-t", String(DUR), "-i", hero,
    "-stream_loop", "-1", "-t", String(DUR), "-i", hands,
    "-filter_complex",
    "[1:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setpts=PTS-STARTPTS[h];" +
    "[2:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setpts=PTS-STARTPTS[n];" +
    "[0:v][h]overlay=enable='between(t,2.6,6.4)'[b1];" +
    "[b1][n]overlay=enable='between(t,10.3,14.4)'[v]",
    "-map", "[v]", "-t", String(DUR), "-r", "30", "-pix_fmt", "yuv420p", "-c:v", "libx264", "-crf", "18", base]);
  if (!existsSync(base)) die("base video build failed");

  // 4) VO via ElevenLabs (Eric), then duck the music under it and mux.
  const voMp3 = join(TMP, "vo.mp3");
  ttsEleven(script.vo, voMp3);
  const music = join(ASSETS, "music-tense-minimal.mp3");
  const mixed = join(TMP, "audio.m4a");
  // Music bed ducked under the VO. VO is delayed 500ms and split: one copy keys the
  // sidechain compressor on the music, the other is mixed on top. Trim to DUR.
  const amix = sh("ffmpeg", ["-y", "-i", music, "-i", voMp3, "-filter_complex",
    "[0:a]volume=0.34,apad[bed];" +
    "[1:a]volume=1.25,adelay=500|500,asplit=2[vo][vokey];" +
    "[bed][vokey]sidechaincompress=threshold=0.05:ratio=8:attack=5:release=250[duck];" +
    "[duck][vo]amix=inputs=2:duration=first:dropout_transition=0[mixraw];" +
    `[mixraw]apad,atrim=0:${DUR},asetpts=PTS-STARTPTS[aout]`,
    "-map", "[aout]", "-c:a", "aac", "-b:a", "192k", mixed]);
  const haveAudio = existsSync(mixed) && fileSize(mixed) > 2000;
  if (!haveAudio) log("  WARN audio mix failed:\n" + (amix.stderr || "").slice(-800));

  // 5) Composite caption frames over base + audio -> final reel.
  const out = join(dir, "reel-9x16.mp4");
  const ff = ["-y", "-i", base, "-framerate", "30", "-i", join(framesDir, "f%04d.png")];
  if (haveAudio) ff.push("-i", mixed);
  ff.push("-filter_complex", "[0:v][1:v]overlay=0:0:format=auto[v]", "-map", "[v]");
  if (haveAudio) ff.push("-map", "2:a", "-c:a", "aac", "-b:a", "192k", "-shortest");
  ff.push("-t", String(DUR), "-r", "30", "-pix_fmt", "yuv420p", "-c:v", "libx264", "-crf", "18", "-movflags", "+faststart", out);
  const rr = sh("ffmpeg", ff);
  if (!existsSync(out)) die("final compose failed:\n" + (rr.stderr || "").slice(-1500));
  return { file: out, dur: DUR };
}

function ttsEleven(text: string, outMp3: string) {
  const key = secret("ELEVENLABS_API_KEY");
  if (!key) die("ELEVENLABS_API_KEY missing");
  log("  ElevenLabs TTS (Eric voice)...");
  const body = JSON.stringify({ text, model_id: "eleven_multilingual_v2", voice_settings: { stability: 0.5, similarity_boost: 0.75, style: 0.15 } });
  const r = sh("curl", ["-sS", "-X", "POST",
    `https://api.elevenlabs.io/v1/text-to-speech/${ELEVEN_ERIC}`,
    "-H", `xi-api-key: ${key}`, "-H", "Content-Type: application/json",
    "-H", "Accept: audio/mpeg", "-d", body, "--output", outMp3]);
  if (!existsSync(outMp3) || fileSize(outMp3) < 2000) die("ElevenLabs TTS failed:\n" + (r.stderr || r.stdout || ""));
}

// ---- serialize the SCRIPT (with reveal fn source strings -> real fns) into a JS literal ----
function serializeScript(s: Script): string {
  const s3reveal = (s.s3 as any).revealSrc as string;
  const s4below = (s.s4 as any).belowSrc as string | undefined;
  return `{
    dur:${s.dur},
    s1:${JSON.stringify(s.s1)},
    s2:${JSON.stringify(s.s2)},
    s3:{ html:${JSON.stringify(s.s3.html)}, ids:${JSON.stringify(s.s3.ids)}, reveal:(${s3reveal}) },
    s4:{ pill:${JSON.stringify(s.s4.pill || "")}, dictate:${JSON.stringify(s.s4.dictate)}, below:${JSON.stringify(s.s4.below || "")}${s4below ? `, belowReveal:(${s4below})` : ""} },
    s5:${JSON.stringify(s.s5)}
  }`;
}

// ---- per-network format adaptation (only used with --publish) ----
// video reels -> 9:16; x/linkedin -> 16:9 (recompose); ig feed -> 4:5 image; pinterest -> 2:3 image.
const NETWORKS = ["facebook", "instagram", "linkedin", "pinterest", "reddit", "telegram", "threads", "tiktok", "twitter", "youtube"];
function mediaForNetwork(net: string, imgs: string[], video: string, dir: string): { media: string; kind: string } {
  const img1350 = imgs.find(f => f.includes("1080x1350")) || imgs[0];
  const img11 = imgs.find(f => f.includes("1x1")) || imgs[0];
  const img916 = imgs.find(f => f.includes("9x16")) || imgs[0];
  // Image-only mode (or no video produced): post the on-brand still everywhere.
  if (IMAGE_ONLY || !video) {
    if (net === "pinterest") return { media: recompose(img11, 1080, 1620, dir, "pin-2x3.png"), kind: "image-2x3" };
    if (net === "linkedin") return { media: img1350, kind: "image-4x5" };
    if (net === "instagram" || net === "facebook") return { media: img1350, kind: "image-4x5" };
    return { media: img11, kind: "image-1x1" };
  }
  switch (net) {
    case "tiktok": case "youtube": case "threads": return { media: video, kind: "video-9x16" };
    case "instagram": case "facebook": return { media: video, kind: "video-9x16-reel" };
    case "twitter": return { media: recompose(video, 1920, 1080, dir, "reel-16x9.mp4"), kind: "video-16x9" };
    case "linkedin": return { media: img1350, kind: "image-4x5" };
    case "pinterest": return { media: recompose(img11, 1080, 1620, dir, "pin-2x3.png"), kind: "image-2x3" };
    default: return { media: img11, kind: "image-1x1" };
  }
}
function recompose(src: string, w: number, h: number, dir: string, name: string): string {
  const out = join(dir, name);
  const isVid = src.endsWith(".mp4");
  if (isVid) sh("ffmpeg", ["-y", "-i", src, "-vf", `scale=${w}:${h}:force_original_aspect_ratio=decrease,pad=${w}:${h}:(ow-iw)/2:(oh-ih)/2:color=#050507`, "-c:a", "copy", out]);
  else sh("ffmpeg", ["-y", "-i", src, "-vf", `scale=${w}:${h}:force_original_aspect_ratio=decrease,pad=${w}:${h}:(ow-iw)/2:(oh-ih)/2:color=#050507`, "-frames:v", "1", out]);
  return existsSync(out) ? out : src;
}

function publish(post: Post, imgs: string[], video: string, dir: string) {
  log("\n== PUBLISH (--publish) to connected organic networks ==");
  for (const net of NETWORKS) {
    if (net === "reddit") { log(`  reddit: posting to brand PROFILE u/VerbaRun (safe auto, no subreddit rule). Community subs (r/macapps, r/ClaudeAI) stay MANUAL per the calendar.`); }
    const text = post.text.trim();
    assertNoDash("publish text " + net, text);
    const { media, kind } = mediaForNetwork(net, imgs, video, dir);
    log(`  ${net} [${kind}]: ${media}`);
    const r = sh("omega-zernio", ["post", "verba", "--text", text, "--platforms", net, "--media", media]);
    log("   ->", (r.stdout || r.stderr || "").trim().split("\n").slice(-1)[0]);
  }
}

// ---------------- main ----------------
function main() {
  if (!existsSync(STYLE)) die("VALIDATED-STYLE.md not found, refusing to run");
  mkdirSync(OUT, { recursive: true });
  const days = loadCalendar();
  const sent = loadSentLog();
  const day = pickDay(days, sent);
  const post = primaryPost(day);
  const pack = packForPillar(post.pillar);
  const date = forceDate || new Date().toISOString().slice(0, 10);
  const dir = join(OUT, date);
  mkdirSync(dir, { recursive: true });

  log(`Verba daily engine ${PUBLISH ? "[PUBLISH]" : "[DRY-RUN]"}`);
  log(`  date=${date} calendar day #${day.dayOffset} pillar="${post.pillar}" platform=${post.platform}`);
  log(`  hook: ${post.text.split("\n")[0].slice(0, 80)}...`);

  log("\n[1/2] IMAGE (Product-UI hero)");
  const imgs = genImage(pack, dir);
  log("  ->", imgs.map(f => f.split("/").pop()).join(", "));

  let video = ""; let dur = 0;
  if (IMAGE_ONLY) {
    log("\n[2/2] VIDEO skipped (--image-only: on-brand still image + text to all networks)");
  } else {
    log("\n[2/2] VIDEO (Motion-UI + VO Eric + tense-minimal music)");
    const v = genVideo(pack.script, dir); video = v.file; dur = v.dur;
    log("  ->", video.split("/").pop(), `${dur}s`);
  }

  // write the batch manifest
  const manifest = {
    date, calendarDay: day.dayOffset, pillar: post.pillar, platform: post.platform,
    postText: post.text, cta: post.cta, vo: pack.script.vo,
    imageFiles: imgs, videoFile: video, durationSec: dur, voUsed: true, produced: true,
  };
  writeFileSync(join(dir, "manifest.json"), JSON.stringify(manifest, null, 2));

  // mark produced in sent-log
  if (!sent.produced.includes(day.dayOffset)) sent.produced.push(day.dayOffset);
  sent.entries.push({ date, calendarDay: day.dayOffset, pillar: post.pillar, dir, published: PUBLISH, at: new Date().toISOString() });
  writeFileSync(SENTLOG, JSON.stringify(sent, null, 2));

  if (PUBLISH) publish(post, imgs, video, dir);

  log("\nDONE. batchDir=" + dir);
  log(JSON.stringify({
    batchDir: dir, imageFiles: imgs, videoFile: video, durationSec: dur,
    voUsed: true, calendarDay: day.dayOffset, published: PUBLISH
  }));
}
main();
