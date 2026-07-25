#!/usr/bin/env node
// ---------------------------------------------------------------------------
// Outrank -> Verba blog sync, the pull-based safety net behind the webhook.
//
// Normally Outrank PUSHES an article to /api/outrank-webhook the moment you click
// Publish. That only happens when the product's integration in Outrank is the
// "Custom Integration" (webhook) one. When it is set to anything else (it was on
// `nextjs-blog` until 2026-07-25), publishing silently never notifies us and the
// blog stays empty even though Outrank shows the articles as published.
//
// This script closes that gap from our side: it reads the published articles from
// the Outrank REST API and replays them through our OWN webhook receiver, so the
// data path (validation, markdown->html, Convex upsert) stays identical to a real
// delivery. Idempotent: the receiver upserts on Outrank's article id, so running it
// twice just refreshes the rows. Safe to put on a cron.
//
//   OUTRANK_API_KEY         Outrank API key (outr_live_…). Generate at https://outrank.so/api-keys
//   OUTRANK_WEBHOOK_TOKEN   Same secret as the Vercel env var, sent as the Bearer to our receiver.
//   VERBA_WEBHOOK_URL       Override the receiver (default: https://verba.run/api/outrank-webhook)
//
// Usage:
//   node scripts/outrank-sync.mjs              # fetch published articles and push them
//   node scripts/outrank-sync.mjs --dry-run    # fetch and report, send nothing
// ---------------------------------------------------------------------------

const OUTRANK = "https://www.outrank.so/api/agent/v1";
const HOOK = process.env.VERBA_WEBHOOK_URL ?? "https://verba.run/api/outrank-webhook";
const API_KEY = process.env.OUTRANK_API_KEY;
const HOOK_TOKEN = process.env.OUTRANK_WEBHOOK_TOKEN;
const DRY = process.argv.includes("--dry-run");

// Outrank's edge answers 403 to a default scripting user-agent.
const UA = "verba-outrank-sync/1.0";

if (!API_KEY) {
  console.error("OUTRANK_API_KEY is required");
  process.exit(1);
}
if (!HOOK_TOKEN && !DRY) {
  console.error("OUTRANK_WEBHOOK_TOKEN is required (or pass --dry-run)");
  process.exit(1);
}

async function outrank(path) {
  const r = await fetch(`${OUTRANK}${path}`, {
    headers: { Authorization: `Bearer ${API_KEY}`, "User-Agent": UA },
  });
  if (!r.ok) throw new Error(`Outrank ${path} -> ${r.status} ${await r.text()}`);
  const json = await r.json();
  if (!json.ok) throw new Error(`Outrank ${path} -> ${JSON.stringify(json.error)}`);
  return json.data;
}

const listing = await outrank("/articles?limit=100");
const published = listing.items.filter((a) => a.status === "published");
console.log(`${listing.items.length} articles in Outrank, ${published.length} published`);

const articles = [];
for (const a of published) {
  const body = await outrank(`/articles/${a.id}/content`);
  console.log(`  ${a.slug} (${(body.content ?? "").length} chars)`);
  articles.push({
    id: a.id,
    title: a.title,
    slug: a.slug,
    content_markdown: body.content ?? "",
    meta_description: a.meta_description,
    image_url: a.image_url,
    created_at: a.created_at,
    tags: a.tags ?? [],
  });
}

if (DRY) {
  console.log("dry run, nothing sent");
  process.exit(0);
}

const res = await fetch(HOOK, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${HOOK_TOKEN}`,
    "Content-Type": "application/json",
    "User-Agent": UA,
  },
  body: JSON.stringify({ event_type: "publish_articles", data: { articles } }),
});
console.log("webhook:", res.status, await res.text());
if (!res.ok) process.exit(1);
