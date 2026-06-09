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

type Body = {
  action?: "add" | "upvote";
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

type LinearIssue = {
  id: string;
  title: string;
  description: string | null;
  updatedAt: string;
  state: { type: string } | null;
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
      `query($id:String!,$after:String){ project(id:$id){ issues(first:100, after:$after){ nodes { id title description updatedAt state { type } } pageInfo { hasNextPage endCursor } } } }`,
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
  const key = process.env.LINEAR_API_KEY;
  if (key) {
    try {
      const issues = await fetchWishlistIssues(key);
      for (const issue of issues) {
        const cid = convexIdOf(issue);
        if (cid && issue.state?.type === "completed") {
          shippedAt.set(cid, issue.updatedAt);
        }
      }
    } catch {
      // Linear unavailable — fall back to unshipped wishes rather than failing the list.
    }
  }

  const merged = items
    .map((w) => {
      const at = shippedAt.get(w.id);
      return at ? { ...w, shipped: true, shippedAt: at } : { ...w, shipped: false };
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
