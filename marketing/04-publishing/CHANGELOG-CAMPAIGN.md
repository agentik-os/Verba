# Changelog campaign "It's shipped" — LIVE (2026-07-07)

Auto-posts one marketable changelog feature per HOUR to Twitter (@verba_run) and
Reddit (@VerbaRun owned profile) via omega-zernio, oldest to newest, until the queue is done.

- Queue: `changelog-campaign-queue.json` (22 features, scrubbed of underlying tech, zero em dash, EN, benefit-led).
- Poster: `changelog-poster.py` (runtime copy in `~/.omega/bin/verba-changelog-poster.py`). Dedup via `changelog-campaign-sent.json`. `--dry-run` validates only.
- Cron: `0 * * * *` (marker OMEGA-CRON-VERBA-CHANGELOG-v1) on the VPS.
- Log: `~/.omega/state/verba/changelog-poster.log`.

SINGLE PUBLISHER: this cron is the ONLY executor of this campaign. The Marketing-machine hub must NOT also run it (one Zernio profile, published posts are irreversible).

Reddit is posted to the OWNED profile only (never community subs, which would trigger a ban).
Videos per feature (real app design) are produced separately and attached via the poster's media field as they land.
