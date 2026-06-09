import { NextRequest, NextResponse } from "next/server";

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

const CONVEX_BASE = "https://fortunate-aardvark-443.convex.cloud";

const LINEAR_URL = "https://api.linear.app/graphql";
const TEAM_ID = "e2568123-2c86-4283-a88f-88e0b508f5ae";
const PROJECT_ID = "6844e446-a0ca-46b6-a8b4-997cfa13ad83";
const WISHLIST_LABEL_ID = "b440fe10-8e32-4182-867b-2eab5c1b7d76";
// File every wishlist issue into Backlog for consistent triage.
const BACKLOG_STATE_ID = "e7d24547-43c5-464d-8881-413f6e80dd2e";

const CONVEX_MARKER = "convexId:";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

type WishItem = {
  id: string;
  text: string;
  author: string;
  votes: number;
  voters: string[];
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
};

/** Call a Convex function over its HTTP API. Returns the function's `value`, or throws. */
async function convex<T>(kind: "query" | "mutation", path: string, args: Record<string, unknown>): Promise<T> {
  const r = await fetch(`${CONVEX_BASE}/api/${kind}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ path, args, format: "json" }),
  });
  const json = await r.json();
  if (!r.ok || json?.status !== "success") {
    const msg = json?.errorMessage ?? `Convex ${path} failed (${r.status})`;
    throw new Error(msg);
  }
  return json.value as T;
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
      const issues = await fetchWishlistIssues(key);
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

  const merged = items
    .map((w) => {
      const at = shippedAt.get(w.id);
      const comments = commentsByWish.get(w.id) ?? [];
      const base = { ...w, commentCount: comments.length, comments };
      return at ? { ...base, shipped: true, shippedAt: at } : { ...base, shipped: false };
    })
    .sort((a, b) => b.votes - a.votes);

  return NextResponse.json({ ok: true, items: merged }, { headers: cors });
}

// POST — { action: "add" | "upvote", ... }
export async function POST(req: NextRequest) {
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
  if (!text) {
    return NextResponse.json({ ok: false, error: "Wish text is required." }, { status: 400, headers: cors });
  }
  if (!uid) {
    return NextResponse.json({ ok: false, error: "A uid is required." }, { status: 400, headers: cors });
  }

  // Convex enforces the same 280-char trim; mirror it so the Linear title matches the stored item.
  const stored = text.slice(0, 280);

  // 1) Create the item in Convex.
  try {
    await convex<unknown>("mutation", "wishlist:add", { uid, alias, text: stored });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't save the wish.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  // 2) Re-list to find the id of the just-created item. The newest matching wish by this
  //    uid+text is ours; voters always include the submitter on creation.
  let createdId: string | null = null;
  try {
    const items = await convex<WishItem[]>("query", "wishlist:list", {});
    const mine = items.filter((w) => w.text === stored && w.voters.includes(uid));
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
    const submitter = [alias, uid].filter(Boolean).join(" · ") || "anonymous";
    const description = [
      stored,
      "",
      "---",
      "",
      `${CONVEX_MARKER} ${createdId}`,
      `Submitted by: ${submitter}`,
      `Wanted by (voters): ${uid}`,
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
  voters: string[],
): Promise<string | null> {
  const title = (text || "Feature wish").replace(/\s+/g, " ").trim().slice(0, 250) || "Feature wish";
  const description = [
    text,
    "",
    "---",
    "",
    `${CONVEX_MARKER} ${convexId}`,
    `Submitted by: ${author || "anonymous"}`,
    `Wanted by (voters): ${voters.join(", ")}`,
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
  if (!id || !uid) {
    return NextResponse.json({ ok: false, error: "id and uid are required." }, { status: 400, headers: cors });
  }
  if (!text) {
    return NextResponse.json({ ok: false, error: "Comment text is required." }, { status: 400, headers: cors });
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
    const issues = await fetchWishlistIssues(key);
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
      wish?.voters ?? [uid],
    );
  }

  if (!issueId) {
    return NextResponse.json({ ok: false, error: "Couldn't attach the comment." }, { status: 502, headers: cors });
  }

  // Store the comment with the alias prefixed so the author survives the round-trip.
  const speaker = alias || uid || "anonymous";
  const commentBody = `${speaker}: ${text}`.slice(0, 4000);
  try {
    await linear<unknown>(
      key,
      `mutation($i:CommentCreateInput!){ commentCreate(input:$i){ success } }`,
      { i: { issueId, body: commentBody } },
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't post the comment.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  return NextResponse.json({ ok: true }, { headers: cors });
}

async function handleUpvote(body: Body) {
  const id = (body.id ?? "").trim();
  const uid = (body.uid ?? "").trim();
  if (!id || !uid) {
    return NextResponse.json({ ok: false, error: "id and uid are required." }, { status: 400, headers: cors });
  }

  // 1) Toggle the vote in Convex (the source of truth for vote counts).
  try {
    await convex<unknown>("mutation", "wishlist:upvote", { id, uid });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Couldn't record the vote.";
    return NextResponse.json({ ok: false, error: msg }, { status: 502, headers: cors });
  }

  // 2) Best-effort: reflect the new vote count + voter on the matching Linear issue.
  const key = process.env.LINEAR_API_KEY;
  if (key) {
    try {
      const items = await convex<WishItem[]>("query", "wishlist:list", {});
      const wish = items.find((w) => w.id === id);
      const issues = await fetchWishlistIssues(key);
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
          `Wanted by (voters): ${wish.voters.join(", ")}`,
          `Updated: ${new Date().toISOString()}`,
        ].join("\n");
        await linear<unknown>(
          key,
          `mutation($id:String!,$i:IssueUpdateInput!){ issueUpdate(id:$id, input:$i){ success } }`,
          { id: match.id, i: { title, description } }
        );
      }
    } catch {
      // tolerate Linear failure; the vote is already recorded in Convex.
    }
  }

  return NextResponse.json({ ok: true }, { headers: cors });
}
