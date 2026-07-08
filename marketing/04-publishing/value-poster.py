#!/usr/bin/env python3
# Verba value-content poster. Posts ONE value post per run to Twitter + LinkedIn via omega-zernio.
# NO link in the body (Buffer 18.8M finding: link-in-body kills reach; link lives in bio).
# Image REQUIRED (never text-only). Dedup via sent-log. --dry-run validates only.
# Reach comes from the engagement layer (growth-engine), not this broadcast; this is the content baseline.
import json, subprocess, sys, os, datetime, pathlib
BASE = "/home/vibe/Station/SideBusiness/Verba/marketing/04-publishing"
QUEUE = f"{BASE}/value-content-queue.json"
SENT = f"{BASE}/value-content-sent.json"
MEDIA = f"{BASE}/value-media"
LOG = os.path.expanduser("~/.omega/state/verba/value-poster.log")
DRY = "--dry-run" in sys.argv
PLATFORMS = ["twitter", "linkedin"]

def log(m):
    pathlib.Path(os.path.dirname(LOG)).mkdir(parents=True, exist_ok=True)
    line = f"{datetime.datetime.now(datetime.timezone.utc).isoformat()} {m}"
    print(line)
    open(LOG, "a").write(line + "\n")

def load(p, d):
    try: return json.load(open(p))
    except Exception: return d

def zpost(text, platform, media):
    cmd = ["omega-zernio", "post", "verba", "--text", text, "--platforms", platform, "--media", media, "--json"]
    if DRY: cmd.append("--dry-run")
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=150)
    except Exception as e:
        return False, f"exec-error: {e}"
    return r.returncode == 0, ((r.stdout or "") + (r.stderr or "")).strip()[:300]

def media_for(iid):
    for ext in (".png", ".jpg", ".mp4"):
        p = f"{MEDIA}/{iid}{ext}"
        if os.path.isfile(p): return p
    return None

def main():
    q = load(QUEUE, None)
    if not q or not q.get("items"): log("ERROR: queue missing/empty"); sys.exit(1)
    sent = load(SENT, {"campaign": "value-content", "posted": {}})
    posted = sent.setdefault("posted", {})
    remaining = [it for it in q["items"] if not all(posted.get(it["id"], {}).get(p, {}).get("ok") for p in PLATFORMS)]
    if not remaining:
        log("value queue exhausted: all posted. REFILL value-content-queue.json (+ value-media) to continue.")
        return
    nxt = remaining[0]; iid = nxt["id"]
    media = media_for(iid)
    if not media:
        log(f"SKIP {iid}: no image in {MEDIA}/{iid}.png (image required, never text-only)."); return
    rec = posted.setdefault(iid, {})
    log(f"{'[DRY] ' if DRY else ''}posting {iid} ({nxt.get('pillar')}) +img  [{len(q['items'])-len(remaining)+1}/{len(q['items'])}]")
    for plat in PLATFORMS:
        if rec.get(plat, {}).get("ok"): continue
        ok, resp = zpost(nxt["twitter"], plat, media)
        rec[plat] = {"ok": ok, "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(), "resp": resp}
        log(f"  {plat}: {'OK' if ok else 'FAIL'} :: {resp[:120]}")
    if not DRY: json.dump(sent, open(SENT, "w"), indent=2, ensure_ascii=False)
    left = len([it for it in q["items"] if not all(posted.get(it["id"], {}).get(p, {}).get("ok") for p in PLATFORMS)])
    if left <= 6: log(f"WARNING: only {left} value posts left in queue. Refill soon.")

if __name__ == "__main__":
    main()
