#!/usr/bin/env python3
# Verba "It's shipped" changelog campaign poster.
# Posts ONE feature per run to Twitter + Reddit (owned profile) via omega-zernio.
# Dedup via a sent-log so hourly cron never double-posts. --dry-run validates only.
# Single executor: this poster is the only thing that should run this queue (anti double-post).
import json, subprocess, sys, os, datetime, pathlib

BASE = "/home/vibe/Station/SideBusiness/Verba/marketing/04-publishing"
QUEUE = f"{BASE}/changelog-campaign-queue.json"
SENT = f"{BASE}/changelog-campaign-sent.json"
LOG = os.path.expanduser("~/.omega/state/verba/changelog-poster.log")
DRY = "--dry-run" in sys.argv
PLATFORMS = ["twitter", "reddit"]

def log(msg):
    pathlib.Path(os.path.dirname(LOG)).mkdir(parents=True, exist_ok=True)
    line = f"{datetime.datetime.now(datetime.timezone.utc).isoformat()} {msg}"
    print(line)
    with open(LOG, "a") as f:
        f.write(line + "\n")

def load(p, default):
    try:
        return json.load(open(p))
    except Exception:
        return default

MEDIA_DIR = f"{BASE}/changelog-media"  # optional per-feature video: <id>.mp4

def media_for(iid):
    # video preferred if present, else the feature illustration image (always required)
    for ext in (".mp4", ".mov", ".webm", ".png", ".jpg", ".jpeg"):
        p = f"{MEDIA_DIR}/{iid}{ext}"
        if os.path.isfile(p):
            return p
    return None

def zpost(text, platform, media=None):
    cmd = ["omega-zernio", "post", "verba", "--text", text, "--platforms", platform, "--json"]
    if media:
        cmd += ["--media", media]
    if DRY:
        cmd.append("--dry-run")
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=150)
    except Exception as e:
        return False, f"exec-error: {e}"
    out = (r.stdout or "") + (r.stderr or "")
    ok = r.returncode == 0
    return ok, out.strip()[:400]

def main():
    q = load(QUEUE, None)
    if not q or not q.get("items"):
        log("ERROR: queue empty/missing"); sys.exit(1)
    sent = load(SENT, {"campaign": q.get("campaign"), "posted": {}})
    posted = sent.setdefault("posted", {})

    # next item not fully done (both platforms succeeded)
    nxt = None
    for it in q["items"]:
        done = posted.get(it["id"], {})
        if not all(done.get(p, {}).get("ok") for p in PLATFORMS):
            nxt = it; break
    if nxt is None:
        log("campaign complete: all items posted on all platforms. Nothing to do.")
        return

    iid = nxt["id"]
    rec = posted.setdefault(iid, {})
    media = media_for(iid)
    if not media:
        # HARD RULE: every post must carry an illustrating picture/video. Never post text-only.
        log(f"SKIP {iid} ({nxt.get('feature')}): no media in {MEDIA_DIR}/{iid}.(png|mp4). Waiting, not posting text-only.")
        return
    log(f"{'[DRY] ' if DRY else ''}posting {iid} ({nxt.get('feature')}) +{os.path.splitext(media)[1].lstrip('.')}")

    # twitter
    if not rec.get("twitter", {}).get("ok"):
        ok, resp = zpost(nxt["twitter"], "twitter", media)
        rec["twitter"] = {"ok": ok, "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(), "resp": resp}
        log(f"  twitter: {'OK' if ok else 'FAIL'} :: {resp[:160]}")
    # reddit (title + body as content; owned profile @VerbaRun account)
    if not rec.get("reddit", {}).get("ok"):
        rtext = f"{nxt['reddit_title']}\n\n{nxt['reddit_body']}"
        ok, resp = zpost(rtext, "reddit", media)
        rec["reddit"] = {"ok": ok, "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(), "resp": resp}
        log(f"  reddit: {'OK' if ok else 'FAIL'} :: {resp[:160]}")

    if not DRY:
        json.dump(sent, open(SENT, "w"), indent=2, ensure_ascii=False)
    done_count = sum(1 for it in q["items"] if all(posted.get(it["id"], {}).get(p, {}).get("ok") for p in PLATFORMS))
    log(f"progress: {done_count}/{len(q['items'])} features fully posted")

if __name__ == "__main__":
    main()
