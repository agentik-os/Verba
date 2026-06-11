// Read/write classifier for Composio tool slugs — the single source of truth that
// gates server-side auto-execution in the agent loop. A READ tool only observes
// (list/get/search/read); a WRITE tool changes the world (create/send/update/delete).
// The agent endpoint may auto-run READ tools to gather context, but NEVER auto-runs a
// WRITE — those are returned to the app as proposedWriteActions the user confirms.
//
// FAIL-SAFE: anything ambiguous is treated as a WRITE, so an unrecognized slug can never
// be auto-executed against a user's real connected account.

// Observe-verb patterns. Composio slugs are SCREAMING_SNAKE like GMAIL_FETCH_EMAILS,
// GOOGLECALENDAR_EVENTS_LIST, SLACK_SEARCH_MESSAGES. Match a read verb as a whole token.
const READ_RE =
  /(?:^|_)(GET|LIST|SEARCH|READ|FETCH|FIND|RETRIEVE|VIEW|CHECK|LOOKUP|QUERY|COUNT|SHOW|EXPORT|DOWNLOAD|FREE_BUSY|FREEBUSY)(?:_|$)/;

// Curated known-good reads whose slug doesn't obviously contain a read verb.
const READ_ALLOW = new Set<string>([
  "GOOGLECALENDAR_FREE_BUSY",
  "GOOGLECALENDAR_FIND_FREE_SLOTS",
  "GMAIL_GET_PROFILE",
  "GMAIL_GET_CONTACTS",
  "GMAIL_LIST_THREADS",
  "SLACK_LIST_ALL_USERS",
  "SLACK_LIST_ALL_CHANNELS",
  "NOTION_FETCH_DATABASE",
  "NOTION_QUERY_DATABASE",
  "GITHUB_LIST_REPOSITORIES_FOR_THE_AUTHENTICATED_USER",
]);

// Write verbs that must NEVER be auto-run even if the slug also matches a read pattern
// (e.g. a hypothetical FIND_AND_DELETE). If a write verb is present, force WRITE.
const WRITE_RE =
  /(?:^|_)(CREATE|SEND|UPDATE|DELETE|REMOVE|ADD|POST|PUT|PATCH|STAR|UNSTAR|ARCHIVE|TRASH|MOVE|SET|EDIT|MODIFY|INSERT|UPSERT|REPLY|FORWARD|DRAFT|INVITE|SHARE|UPLOAD|MARK|ASSIGN|CLOSE|MERGE|CANCEL|DECLINE|ACCEPT|RSVP|PUBLISH|REVOKE|GRANT)(?:_|$)/;

export function isReadOnly(slug: string): boolean {
  const s = (slug ?? "").toUpperCase();
  if (!s) return false;
  if (WRITE_RE.test(s)) return false; // a write verb anywhere ⇒ WRITE, fail-safe
  if (READ_ALLOW.has(s)) return true;
  return READ_RE.test(s);
}

import PHRASES from "./action-phrases.json";

// Example user phrases per action (the JARVIS "intent anchors"), keyed by toolkit → slug.
const PHRASE_MAP = PHRASES as Record<string, { slug: string; phrases: string[] }[]>;
function phrasesFor(toolkit: string, slug: string): string[] {
  return (PHRASE_MAP[toolkit] ?? []).find((a) => a.slug === slug)?.phrases ?? [];
}

export interface CatalogTool {
  slug: string;
  description: string;
  readOnly: boolean;
}

// Rank tools so the high-value actions survive the per-toolkit cap. A plain alphabetical slice
// used to drop GMAIL_SEND_EMAIL (and other late-alphabet writes) entirely, so the planner could
// never propose sending an email and fell back to a local Mail.app draft. Send/reply rank highest,
// then create/update, then context reads, then destructive/niche tools.
function toolPriority(slug: string): number {
  const s = (slug ?? "").toUpperCase();
  if (/(?:^|_)(SEND|REPLY|FORWARD)(?:_|$)/.test(s)) return 100;
  if (/(?:^|_)(CREATE|ADD|POST|UPDATE|EDIT|MODIFY|SET|INVITE|SHARE|UPLOAD|ASSIGN|RSVP|SCHEDULE)(?:_|$)/.test(s)) return 80;
  if (/(?:^|_)(FETCH|SEARCH|LIST|GET|FIND|RETRIEVE|READ|QUERY|FREE_BUSY|FREEBUSY)(?:_|$)/.test(s)) return 60;
  if (/(?:^|_)(DELETE|REMOVE|TRASH|ARCHIVE|REVOKE|BATCH)(?:_|$)/.test(s)) return 10;
  return 30;
}

// User-facing argument names from a tool's input schema (skipping internal/auto fields), so the
// planner emits arguments under the EXACT keys Composio expects (e.g. recipient_email, not "to").
function toolArgNames(t: { inputParameters?: { properties?: Record<string, unknown> } }): string[] {
  const props = t.inputParameters?.properties;
  if (!props) return [];
  const skip = new Set(["user_id", "thread_id"]);
  return Object.keys(props).filter((k) => !skip.has(k)).slice(0, 8);
}

interface RawTool {
  slug: string;
  description?: string;
  inputParameters?: { properties?: Record<string, unknown> };
}

// Build the read/write tool catalog for the uid's ACTIVE connected toolkits.
// Mirrors the toolkit-resolution shape used by tools/route.ts + connections/route.ts.
export async function loadReadWriteCatalog(
  composio: { connectedAccounts: { list: (a: { userIds: string[] }) => Promise<unknown> }; tools: { getRawComposioTools: (a: { toolkits: string[]; limit: number }) => Promise<unknown> } },
  uid: string
): Promise<CatalogTool[]> {
  const list = (await composio.connectedAccounts.list({ userIds: [uid] })) as {
    items?: { status?: string; toolkit?: { slug?: string } | string }[];
  };
  const toolkits = [
    ...new Set(
      (list.items ?? [])
        .filter((i) => i.status === "ACTIVE")
        .map((i) => {
          const tk = i.toolkit;
          return (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
        })
        .filter(Boolean)
    ),
  ];

  const out: CatalogTool[] = [];
  for (const tk of toolkits) {
    const raw = (await composio.tools.getRawComposioTools({ toolkits: [tk], limit: 50 })) as RawTool[];
    // These are the user's CONNECTED toolkits — give the planner the FULL action set (ranked so the
    // high-value ones lead) so JARVIS knows everything it can do with each connected app.
    const ranked = [...raw].sort((a, b) => toolPriority(b.slug) - toolPriority(a.slug)).slice(0, 45);
    for (const t of ranked) {
      const d = (t.description ?? "").replace(/\n/g, " ");
      const short = d.length > 120 ? d.slice(0, 120) + "…" : d;
      const args = toolArgNames(t);
      // Attach example user phrases so JARVIS matches a spoken request to the right action faster
      // and more accurately (the action data, surfaced to the planner — the "make JARVIS smarter").
      const ex = phrasesFor(tk, t.slug).slice(0, 2);
      let desc = args.length ? `${short} [args: ${args.join(", ")}]` : short;
      if (ex.length) desc += ` (e.g. ${ex.map((p) => `"${p}"`).join(", ")})`;
      out.push({ slug: t.slug, description: desc, readOnly: isReadOnly(t.slug) });
    }
  }
  return out;
}
