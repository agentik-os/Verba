import { NextRequest, NextResponse } from "next/server";
import { convexCall, convexBump } from "@/lib/convex";

export const runtime = "nodejs";

// Bridges the Verba feature wishlist between Convex (the live item + vote store the
// macOS app talks to directly) and Linear (the team's planning surface). A wish lives
// in Convex; its Linear issue carries a "convexId: <id>" marker in its description so
// the two stay linked WITHOUT adding any Convex field. When the Linear issue reaches a
// "completed" (Done) state, the wish is reported back as shipped. The LINEAR_API_KEY is
// read server-side only — it never leaves this route.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const LINEAR_URL = "https://api.linear.app/graphql";
const TEAM_ID = "16e9d4a0-b7ca-4463-ab8a-a024a4049ba1";
const PROJECT_ID = "66e42b13-f82b-43b9-be0a-6ec5c709e2ab";
const WISHLIST_LABEL_ID = "b440fe10-8e32-4182-867b-2eab5c1b7d76";
// File every wishlist issue into Backlog for consistent triage.
const BACKLOG_STATE_ID = "fb9524bf-9b3c-433a-ac87-49069f7523f1";

const CONVEX_MARKER = "convexId:";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

// S12: Convex no longer exposes the voters uid list; `mine` is computed server-side
// for callers that prove device ownership (uid + device secret).
type WishItem = {
  id: string;
  text: string;
  author: string;
  votes: number;
  mine?: boolean;
  shipped?: boolean;        // persisted in Convex (durable across Linear board changes)
  shippedAt?: number | null;
};

type WishComment = {
  id: string;
  author: string;
  text: string;
  createdAt: string;
};

type Body = {
  action?: "add" | "upvote" | "comment";
  text?: string;
  id?: string;
  uid?: string;
  alias?: string;
  secret?: string;
};

/** Call a Convex function over its HTTP API. Returns the function's `value`, or throws. */
const convex = convexCall;

/** Map a Convex mutation failure to the right HTTP error: device-auth failures are 401. */
function convexErrorResponse(e: unknown, fallback: string) {
  const msg = e instanceof Error ? e.message : fallback;
  if (/unauthorized/i.test(msg)) {
    return NextResponse.json(
      { ok: false, error: "This device isn't registered. Update Verba and try again." },
      { status: 401, headers: cors }
    );
  }
  return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
}

function ipOf(req: NextRequest): string {
  const xff = req.headers.get("x-forwarded-for") ?? "";
  return xff.split(",")[0].trim() || req.headers.get("x-real-ip") || "unknown";
}

/** Run a Linear GraphQL request with the server-side key. Throws on transport/GraphQL errors. */
async function linear<T>(key: string, query: string, variables: Record<string, unknown>): Promise<T> {
  const r = await fetch(LINEAR_URL, {
    method: "POST",
    headers: { Authorization: key, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await r.json();
  if (!r.ok || json.errors) {
    const msg = json?.errors?.[0]?.message ?? `Linear request failed (${r.status})`;
    throw new Error(msg);
  }
  return json.data as T;
}

type LinearCommentNode = {
  id: string;
  body: string;
  createdAt: string;
  user: { name: string | null } | null;
};

type LinearIssue = {
  id: string;
  title: string;
  description: string | null;
  updatedAt: string;
  state: { type: string } | null;
  comments?: { nodes: LinearCommentNode[] } | null;
};

/** Fetch all wishlist-project issues (paginated) so convexId markers can be parsed. */
async function fetchWishlistIssues(key: string): Promise<LinearIssue[]> {
  const out: LinearIssue[] = [];
  let after: string | null = null;
  // Cap pages defensively; a wishlist won't realistically exceed this.
  for (let page = 0; page < 20; page++) {
    type Resp = {
      project: {
        issues: {
          nodes: LinearIssue[];
          pageInfo: { hasNextPage: boolean; endCursor: string | null };
        };
      } | null;
    };
    const data: Resp = await linear<Resp>(
      key,
      `query($id:String!,$after:String){ project(id:$id){ issues(first:100, after:$after){ nodes { id title description updatedAt state { type } comments(first:100){ nodes { id body createdAt user { name } } } } pageInfo { hasNextPage endCursor } } } }`,
      { id: PROJECT_ID, after }
    );
    const conn = data.project?.issues;
    if (!conn) break;
    out.push(...conn.nodes);
    if (!conn.pageInfo.hasNextPage) break;
    after = conn.pageInfo.endCursor;
  }
  return out;
}

// Module-scoped cache for the Linear issue walk: the wishlist tolerates ~45s of
// staleness, and re-walking up to 20 sequential GraphQL pages on every GET/upvote
// burns seconds of latency plus the Linear rate limit.
const ISSUE_CACHE_TTL_MS = 45_000;
let issueCache: { at: number; data: LinearIssue[] } | null = null;

/** fetchWishlistIssues behind the TTL cache. Mutating paths call invalidateIssueCache(). */
async function fetchWishlistIssuesCached(key: string): Promise<LinearIssue[]> {
  if (issueCache && Date.now() - issueCache.at < ISSUE_CACHE_TTL_MS) return issueCache.data;
  const data = await fetchWishlistIssues(key);
  issueCache = { at: Date.now(), data };
  return data;
}

function invalidateIssueCache() {
  issueCache = null;
}

/** Extract the convexId marker from a Linear issue description, if present. */
function convexIdOf(issue: LinearIssue): string | null {
  const desc = issue.description ?? "";
  const m = desc.match(/convexId:\s*([A-Za-z0-9_-]+)/);
  return m ? m[1] : null;
}

// Comments are stored on the Linear issue with the author alias prefixed as "alias: text".
const COMMENT_PREFIX = /^([^\n:]{1,40}):\s([\s\S]*)$/;

/** Turn a Linear comment node into a wish comment, recovering the alias from the "alias: text" body. */
function toWishComment(node: LinearCommentNode): WishComment {
  const body = (node.body ?? "").trim();
  const m = body.match(COMMENT_PREFIX);
  // Prefer the embedded alias; fall back to the Linear user name, then "anonymous".
  const author = (m ? m[1] : node.user?.name ?? "")?.trim() || "anonymous";
  const text = m ? m[2].trim() : body;
  return { id: node.id, author, text, createdAt: node.createdAt };
}

/** All non-system comments on an issue, oldest-first, mapped to WishComment. */
function commentsOf(issue: LinearIssue): WishComment[] {
  const nodes = issue.comments?.nodes ?? [];
  return nodes
    .map(toWishComment)
    .filter((c) => c.text.length > 0)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

// GET — list wishes merged with a `shipped` flag derived from the linked Linear issue.
export async function GET() {
  let items: WishItem[];
  try {
    items = await convex<WishItem[]>("query", "wishlist:list", {});
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't load the wishlist.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  // Map convexId -> the matching Linear issue (best-effort; tolerate Linear being down/unconfigured).
  const shippedAt = new Map<string, string>();
  const commentsByWish = new Map<string, WishComment[]>();
  const key = process.env.LINEAR_API_KEY;
  if (key) {
    try {
      const issues = await fetchWishlistIssuesCached(key);
      for (const issue of issues) {
        const cid = convexIdOf(issue);
        if (!cid) continue;
        if (issue.state?.type === "completed") {
          shippedAt.set(cid, issue.updatedAt);
        }
        commentsByWish.set(cid, commentsOf(issue));
      }
    } catch {
      // Linear unavailable — fall back to unshipped wishes rather than failing the list.
    }
  }

  const merged = await Promise.all(
    items.map(async (w) => {
      const liveAt = shippedAt.get(w.id);                // from the (current) Linear board
      const comments = commentsByWish.get(w.id) ?? [];
      const base = { ...w, commentCount: comments.length, comments };
      // Shipped = persisted-in-Convex OR live-from-Linear. Once Linear reports a wish Done, persist
      // it to Convex so the green badge survives even if the Linear board/workspace later changes.
      if (liveAt && w.shipped !== true) {
        try { await convex("mutation", "wishlist:setShipped", { id: w.id, at: Date.parse(liveAt) }); } catch { /* best-effort */ }
      }
      const isShipped = w.shipped === true || !!liveAt;
      if (!isShipped) return { ...base, shipped: false };
      const shippedAtMs = w.shippedAt ?? (liveAt ? Date.parse(liveAt) : Date.now());
      return { ...base, shipped: true, shippedAt: new Date(shippedAtMs).toISOString() };
    })
  );
  merged.sort((a, b) => b.votes - a.votes);

  return NextResponse.json({ ok: true, items: merged }, { headers: cors });
}

// POST — { action: "add" | "upvote" | "comment", ... } (all require a registered device secret)
export async function POST(req: NextRequest) {
  // S12: shared per-IP daily cap on all wishlist mutations (fail open on Convex outage —
  // the mutations themselves still require a registered device).
  const day = new Date().toISOString().slice(0, 10);
  const ipAllowed = await convexBump(`wish:ip:${ipOf(req)}:${day}`, 20, true);
  if (!ipAllowed) {
    return NextResponse.json({ ok: false, error: "Too many wishlist actions today." }, { status: 429, headers: cors });
  }

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400, headers: cors });
  }

  if (body.action === "add") return handleAdd(body);
  if (body.action === "upvote") return handleUpvote(body);
  if (body.action === "comment") return handleComment(body);
  return NextResponse.json({ ok: false, error: "Unknown action" }, { status: 400, headers: cors });
}

async function handleAdd(body: Body) {
  const text = (body.text ?? "").trim();
  const uid = (body.uid ?? "").trim();
  const alias = (body.alias ?? "").trim();
  const secret = (body.secret ?? "").trim();
  if (!text) {
    return NextResponse.json({ ok: false, error: "Wish text is required." }, { status: 400, headers: cors });
  }
  if (!uid || !secret) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401, headers: cors });
  }

  // Convex enforces the same 280-char trim; mirror it so the Linear title matches the stored item.
  const stored = text.slice(0, 280);

  // 1) Create the item in Convex (requireDevice validates uid+secret there).
  try {
    await convex<unknown>("mutation", "wishlist:add", { uid, secret, alias, text: stored });
  } catch (e) {
    return convexErrorResponse(e, "Couldn't save the wish.");
  }

  // 2) Re-list to find the id of the just-created item: the newest wish matching this
  //    text that is `mine` (the submitter auto-votes on creation).
  let createdId: string | null = null;
  try {
    const items = await convex<WishItem[]>("query", "wishlist:list", { uid, secret });
    const mine = items.filter((w) => w.text === stored && w.mine);
    // list() has no created field; if several match, the marker still links the most likely one.
    createdId = mine.length ? mine[mine.length - 1].id : null;
  } catch {
    createdId = null;
  }

  // 3) Best-effort: file the linked Linear issue. The wish is already saved in Convex, so a
  //    Linear outage must not fail the add — just skip the issue.
  const key = process.env.LINEAR_API_KEY;
  if (key && createdId) {
    const title = stored.replace(/\s+/g, " ").trim().slice(0, 250) || "Feature wish";
    const submitter = alias || "anonymous";
    const description = [
      stored,
      "",
      "---",
      "",
      `${CONVEX_MARKER} ${createdId}`,
      `Submitted by: ${submitter}`,
      `Votes: 1`,
      `Filed: ${new Date().toISOString()}`,
    ].join("\n");
    try {
      await linear<unknown>(
        key,
        `mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success } }`,
        {
          i: {
            teamId: TEAM_ID,
            projectId: PROJECT_ID,
            stateId: BACKLOG_STATE_ID,
            labelIds: [WISHLIST_LABEL_ID],
            title,
            description,
          },
        }
      );
      invalidateIssueCache();
    } catch {
      // tolerate Linear failure; the wish is live in Convex.
    }
  }

  return NextResponse.json({ ok: true, id: createdId }, { headers: cors });
}

/**
 * Create the Linear issue that mirrors a wish (used when commenting on a wish whose
 * issue doesn't exist yet). Returns the new issue id, or null on failure. Mirrors the
 * add path's issue shape so the convexId marker keeps the two linked.
 */
async function createIssueForWish(
  key: string,
  convexId: string,
  text: string,
  author: string,
  votes: number,
): Promise<string | null> {
  const title = (text || "Feature wish").replace(/\s+/g, " ").trim().slice(0, 250) || "Feature wish";
  const description = [
    text,
    "",
    "---",
    "",
    `${CONVEX_MARKER} ${convexId}`,
    `Submitted by: ${author || "anonymous"}`,
    `Votes: ${Math.round(votes)}`,
    `Filed: ${new Date().toISOString()}`,
  ].join("\n");
  try {
    type Resp = { issueCreate: { success: boolean; issue: { id: string } | null } };
    const data = await linear<Resp>(
      key,
      `mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success issue { id } } }`,
      {
        i: {
          teamId: TEAM_ID,
          projectId: PROJECT_ID,
          stateId: BACKLOG_STATE_ID,
          labelIds: [WISHLIST_LABEL_ID],
          title,
          description,
        },
      },
    );
    invalidateIssueCache();
    return data.issueCreate?.issue?.id ?? null;
  } catch {
    return null;
  }
}

// POST { action: "comment", id, uid, alias, text } — append a comment to the wish's Linear issue.
async function handleComment(body: Body) {
  const id = (body.id ?? "").trim();
  const uid = (body.uid ?? "").trim();
  const alias = (body.alias ?? "").trim();
  const text = (body.text ?? "").trim();
  const secret = (body.secret ?? "").trim();
  if (!id || !uid) {
    return NextResponse.json({ ok: false, error: "id and uid are required." }, { status: 400, headers: cors });
  }
  if (!text) {
    return NextResponse.json({ ok: false, error: "Comment text is required." }, { status: 400, headers: cors });
  }

  // S12: comments are written to Linear, not Convex — require a registered device explicitly.
  let registered = false;
  try {
    registered = secret ? await convex<boolean>("query", "auth:check", { uid, secret }) : false;
  } catch {
    registered = false;
  }
  if (!registered) {
    return NextResponse.json(
      { ok: false, error: "This device isn't registered. Update Verba and try again." },
      { status: 401, headers: cors }
    );
  }

  const key = process.env.LINEAR_API_KEY;
  if (!key) {
    return NextResponse.json(
      { ok: false, error: "Comments are temporarily unavailable." },
      { status: 503, headers: cors },
    );
  }

  // Locate the wish's Linear issue by its convexId marker; create one on the fly if missing.
  let issueId: string | null = null;
  try {
    const issues = await fetchWishlistIssuesCached(key);
    issueId = issues.find((iss) => convexIdOf(iss) === id)?.id ?? null;
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't reach Linear.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  if (!issueId) {
    // No linked issue yet — mirror the add path so the comment has somewhere to live.
    let wish: WishItem | undefined;
    try {
      const items = await convex<WishItem[]>("query", "wishlist:list", {});
      wish = items.find((w) => w.id === id);
    } catch {
      wish = undefined;
    }
    issueId = await createIssueForWish(
      key,
      id,
      wish?.text ?? "",
      wish?.author ?? alias,
      wish?.votes ?? 1,
    );
  }

  if (!issueId) {
    return NextResponse.json({ ok: false, error: "Couldn't attach the comment." }, { status: 502, headers: cors });
  }

  // Store the comment with the alias prefixed so the author survives the round-trip.
  // Never fall back to the uid here — it would leak into the public comment list.
  const speaker = alias || "anonymous";
  const commentBody = `${speaker}: ${text}`.slice(0, 4000);
  try {
    await linear<unknown>(
      key,
      `mutation($i:CommentCreateInput!){ commentCreate(input:$i){ success } }`,
      { i: { issueId, body: commentBody } },
    );
    invalidateIssueCache();
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't post the comment.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  return NextResponse.json({ ok: true }, { headers: cors });
}

async function handleUpvote(body: Body) {
  const id = (body.id ?? "").trim();
  const uid = (body.uid ?? "").trim();
  const secret = (body.secret ?? "").trim();
  if (!id || !uid) {
    return NextResponse.json({ ok: false, error: "id and uid are required." }, { status: 400, headers: cors });
  }
  if (!secret) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401, headers: cors });
  }

  // 1) Toggle the vote in Convex (the source of truth for vote counts; requireDevice there).
  try {
    await convex<unknown>("mutation", "wishlist:upvote", { id, uid, secret });
  } catch (e) {
    return convexErrorResponse(e, "Couldn't record the vote.");
  }

  // 2) Best-effort: reflect the new vote count + voter on the matching Linear issue.
  const key = process.env.LINEAR_API_KEY;
  if (key) {
    try {
      const items = await convex<WishItem[]>("query", "wishlist:list", {});
      const wish = items.find((w) => w.id === id);
      const issues = await fetchWishlistIssuesCached(key);
      const match = issues.find((iss) => convexIdOf(iss) === id);
      if (wish && match) {
        const baseTitle = (wish.text || match.title).replace(/\s+/g, " ").trim().slice(0, 230) || "Feature wish";
        const title = `${baseTitle} (${Math.round(wish.votes)} votes)`;
        const description = [
          wish.text,
          "",
          "---",
          "",
          `${CONVEX_MARKER} ${id}`,
          `Submitted by: ${wish.author}`,
          `Votes: ${Math.round(wish.votes)}`,
          `Updated: ${new Date().toISOString()}`,
        ].join("\n");
        await linear<unknown>(
          key,
          `mutation($id:String!,$i:IssueUpdateInput!){ issueUpdate(id:$id, input:$i){ success } }`,
          { id: match.id, i: { title, description } }
        );
        invalidateIssueCache();
      }
    } catch {
      // tolerate Linear failure; the vote is already recorded in Convex.
    }
  }

  return NextResponse.json({ ok: true }, { headers: cors });
}
