#!/usr/bin/env python3
# Verba blog-repost poster. Reposts ONE published blog article per run to Twitter + LinkedIn
# via omega-zernio (R-ZERNIO: never a hand-rolled uploader).
#
# Source of truth is the live site, not a hand-written queue: it reads Convex `blog:list`, which is
# exactly what /blog renders, so an article Outrank publishes becomes a post with no extra step.
# Dedup via the sent-log, so re-running is safe and an article is never posted twice.
#
# DELIBERATE DIFFERENCE from value-poster.py: this one DOES put the link in the body. The house rule
# (link-in-body suppresses reach) exists for value posts whose goal is engagement. A blog repost's
# only goal is the click through to the article, so the link ships. Pass --no-link to fall back to
# the engagement-first shape.
#
# Copy rules enforced in code, not by hope: EN only, zero em/en dash (R-NODASH), no pricing figures,
# never name the underlying models (secret-tech rule), Twitter hard-capped at 280 chars.
#
#   python3 blog-poster.py --dry-run     # validate + preview, publish nothing (DEFAULT for a first run)
#   python3 blog-poster.py --publish     # actually post, requires an active Zernio subscription
#   python3 blog-poster.py --publish --all   # drain every un-posted article instead of one
import datetime
import json
import os
import pathlib
import re
import subprocess
import sys
import urllib.request

BASE = "/home/vibe/Station/SideBusiness/Verba/marketing/04-publishing"
SENT = f"{BASE}/blog-repost-sent.json"
LOG = os.path.expanduser("~/.omega/state/verba/blog-poster.log")
CONVEX = "https://prestigious-wolf-290.eu-west-1.convex.cloud/api/query"
SITE = "https://verba.run"
PLATFORMS = ["twitter", "linkedin"]
TWITTER_MAX = 280

PUBLISH = "--publish" in sys.argv
DRY = not PUBLISH  # publishing is opt-in; a bare run never posts
ALL = "--all" in sys.argv
NO_LINK = "--no-link" in sys.argv

# Never let these reach a public timeline (secret-tech rule).
BANNED = re.compile(r"parakeet|qwen|whisper|claude|anthropic|openai|\bgpt\b|\bllama\b", re.I)


def log(m):
    pathlib.Path(os.path.dirname(LOG)).mkdir(parents=True, exist_ok=True)
    line = f"{datetime.datetime.now(datetime.timezone.utc).isoformat()} {m}"
    print(line)
    open(LOG, "a").write(line + "\n")


def load(p, d):
    try:
        return json.load(open(p))
    except Exception:
        return d


def articles():
    """Every article live on /blog, newest first."""
    req = urllib.request.Request(
        CONVEX,
        data=json.dumps({"path": "blog:list", "args": {}, "format": "json"}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=45) as r:
        body = json.load(r)
    if body.get("status") != "success":
        raise RuntimeError(f"convex blog:list failed: {body}")
    return body["value"]


def clean(s):
    """Strip the AI tells and the punctuation the brand bans."""
    s = (s or "").replace("—", ", ").replace("–", ", ")
    return re.sub(r"\s+", " ", s).strip()


def compose(a, platform):
    title = clean(a["title"])
    desc = clean(a.get("metaDescription") or "")
    url = f"{SITE}/blog/{a['slug']}"

    if platform == "twitter":
        body = title if NO_LINK else f"{title}\n\n{url}"
        if len(body) > TWITTER_MAX:
            # Trim the title, never the link.
            room = TWITTER_MAX - (0 if NO_LINK else len(url) + 2) - 1
            body = clean(title)[:room].rstrip(" ,.") + ("" if NO_LINK else f"\n\n{url}")
        return body

    parts = [title]
    if desc:
        parts.append(desc)
    if not NO_LINK:
        parts.append(f"Read it: {url}")
    return "\n\n".join(parts)


def check(text):
    """Refuse to publish copy that breaks a hard rule."""
    problems = []
    if "—" in text or "–" in text:
        problems.append("contains an em/en dash")
    hit = BANNED.search(text)
    if hit and hit.group(0).lower() != "whisper":  # MacWhisper is a competitor we name publicly
        problems.append(f"names a model or vendor: {hit.group(0)}")
    if re.search(r"[$€]\s?\d", text):
        problems.append("contains a price")
    return problems


def zpost(text, platform, media):
    cmd = ["omega-zernio", "post", "verba", "--text", text, "--platforms", platform, "--json"]
    if media:
        cmd += ["--media", media]
    if DRY:
        cmd.append("--dry-run")
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except Exception as e:
        return False, f"exec-error: {e}"
    return r.returncode == 0, ((r.stdout or "") + (r.stderr or "")).strip()[:300]


def main():
    try:
        arts = articles()
    except Exception as e:
        log(f"ERROR: cannot read the live blog: {e}")
        sys.exit(1)

    sent = load(SENT, {"campaign": "blog-reposts", "posted": {}})
    posted = sent.setdefault("posted", {})
    todo = [a for a in arts if not all(posted.get(a["slug"], {}).get(p, {}).get("ok") for p in PLATFORMS)]
    if not todo:
        log(f"nothing to repost: all {len(arts)} published articles already went out")
        return
    if not ALL:
        todo = todo[:1]

    log(f"{'[DRY] ' if DRY else ''}{len(todo)} article(s) to repost, {len(arts)} live on the blog")
    for a in todo:
        rec = posted.setdefault(a["slug"], {})
        media = a.get("imageUrl") or None
        for plat in PLATFORMS:
            if rec.get(plat, {}).get("ok"):
                continue
            text = compose(a, plat)
            problems = check(text)
            if problems:
                log(f"  BLOCKED {a['slug']} on {plat}: {'; '.join(problems)}")
                continue
            log(f"  {plat} ({len(text)} chars): {text[:110].replace(chr(10), ' / ')}")
            ok, resp = zpost(text, plat, media)
            rec[plat] = {
                "ok": ok,
                "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                "dry": DRY,
                "resp": resp,
            }
            log(f"    {'OK' if ok else 'FAIL'} :: {resp[:140]}")
        if DRY:
            rec.clear()  # a dry run must not mark anything as sent

    if not DRY:
        json.dump(sent, open(SENT, "w"), indent=2, ensure_ascii=False)
    else:
        log("dry run: nothing published, nothing recorded. Re-run with --publish to send.")


if __name__ == "__main__":
    main()
