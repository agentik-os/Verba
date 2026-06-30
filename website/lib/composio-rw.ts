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
import { rankByLexical } from "./lexical";

// Example user phrases per action (the JARVIS "intent anchors"), keyed by toolkit → slug.
const PHRASE_MAP = PHRASES as Record<string, { slug: string; phrases: string[] }[]>;
function phrasesFor(toolkit: string, slug: string): string[] {
  return (PHRASE_MAP[toolkit] ?? []).find((a) => a.slug === slug)?.phrases ?? [];
}

export interface CatalogTool {
  slug: string;
  description: string;
  readOnly: boolean;
  /// Compact argument schema (types, required, nested list/object shapes) so the planner emits
  /// exactly-valid arguments — e.g. `messages: array of {role: string, content: string} (required)`.
  schema: string;
  /// Raw input schema, kept for SERVER-SIDE validation + auto-repair of the planner's arguments.
  ip?: { properties?: Record<string, JsonSchema>; required?: string[] };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type JsonSchema = any;

// One-line type for a JSON-Schema property, recursive into arrays/objects so the planner sees the
// real shape (a list of message objects, not a bare string).
function typeStr(spec: JsonSchema, depth = 0): string {
  if (!spec || typeof spec !== "object" || depth > 2) return "any";
  const t = spec.type;
  if (t === "array") return `array of ${typeStr(spec.items, depth + 1)}`;
  if (t === "object" && spec.properties) {
    const inner = Object.keys(spec.properties)
      .slice(0, 6)
      .map((k) => `${k}: ${typeStr(spec.properties[k], depth + 1)}`)
      .join(", ");
    return `{${inner}}`;
  }
  if (Array.isArray(spec.enum) && spec.enum.length) return `${t || "string"} (${spec.enum.slice(0, 6).join("|")})`;
  return typeof t === "string" ? t : "string";
}

// Compact the full input schema into a single readable line for the planner.
function compactSchema(ip?: { properties?: Record<string, JsonSchema>; required?: string[] }): string {
  const props = ip?.properties;
  if (!props) return "";
  const req = new Set(ip?.required ?? []);
  const skip = new Set(["user_id", "thread_id"]);
  const parts: string[] = [];
  for (const [name, spec] of Object.entries(props)) {
    if (skip.has(name)) continue;
    parts.push(`${name}: ${typeStr(spec)}${req.has(name) ? " (required)" : ""}`);
    if (parts.length >= 14) break;
  }
  return parts.join("; ");
}

// Rank tools so the high-value actions survive the per-toolkit cap. A plain alphabetical slice
// used to drop GMAIL_SEND_EMAIL (and other late-alphabet writes) entirely, so the planner could
// never propose sending an email and fell back to a local Mail.app draft. Send/reply rank highest,
// then create/update, then context reads, then destructive/niche tools.
function toolPriority(slug: string): number {
  const s = (slug ?? "").toUpperCase();
  if (/(?:^|_)(SEND|REPLY|FORWARD)(?:_|$)/.test(s)) return 100;
  if (/(?:^|_)(CREATE|ADD|POST|UPDATE|EDIT|MODIFY|SET|INVITE|SHARE|UPLOAD|ASSIGN|RSVP|SCHEDULE|STAR|UNSTAR|FORK|FOLLOW|WATCH|SUBSCRIBE)(?:_|$)/.test(s)) return 80;
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
  inputParameters?: { properties?: Record<string, JsonSchema>; required?: string[] };
}

// True when a REQUIRED input field is file-uploadable (Composio marks these) — a voice request
// can't provide one, so the planner must collect it from the user instead of failing later.
function hasRequiredFile(ip?: { properties?: Record<string, JsonSchema>; required?: string[] }): boolean {
  const props = ip?.properties;
  if (!props) return false;
  const req = new Set(ip?.required ?? []);
  return Object.entries(props).some(([k, v]) => req.has(k) && (v?.file_uploadable === true || v?.format === "binary"));
}

/// Validate the planner's arguments against a tool's real JSON schema. Returns human-readable
/// problems ([] = valid). Deliberately shallow-but-strict on the failure modes that actually break
/// execution: missing required fields, and wrong JSON types (string where a list/object is needed).
export function validateArgs(
  args: Record<string, unknown>,
  ip?: { properties?: Record<string, JsonSchema>; required?: string[] }
): string[] {
  const props = ip?.properties;
  if (!props) return [];
  const errs: string[] = [];
  for (const r of ip?.required ?? []) {
    const v = args[r];
    if (v === undefined || v === null || v === "") errs.push(`missing required field "${r}"`);
  }
  for (const [k, v] of Object.entries(args)) {
    const spec = props[k];
    if (!spec) { errs.push(`unknown field "${k}" (not in the tool's schema)`); continue; }
    const t = spec.type;
    if (t === "array" && !Array.isArray(v)) errs.push(`"${k}" must be an ARRAY (got ${typeof v})`);
    else if (t === "object" && (typeof v !== "object" || v === null || Array.isArray(v))) errs.push(`"${k}" must be an OBJECT`);
    else if (t === "string" && typeof v !== "string") errs.push(`"${k}" must be a string`);
    else if ((t === "number" || t === "integer") && typeof v !== "number") errs.push(`"${k}" must be a number`);
    else if (t === "boolean" && typeof v !== "boolean") errs.push(`"${k}" must be a boolean`);
  }
  return errs;
}

// A toolkit's raw tool catalog is user-independent and changes rarely, but loadReadWriteCatalog
// runs on EVERY transcript and used to re-fetch it per call — 1-2 Composio API calls per connected
// toolkit, every utterance, uncached. A chatty JARVIS session multiplied that into hundreds of
// calls/minute and tripped Composio's rate limits (the "aggressive usage" that burned the key).
// Cache each toolkit's raw fetch process-wide with a short TTL (same module-level pattern as the
// version caches in the agent/execute routes): a warm instance now hits Composio once per toolkit
// per window instead of once per utterance, regardless of how many users share it.
const TOOLKIT_TTL_MS = 10 * 60 * 1000;
const toolkitToolsCache = new Map<string, { at: number; tools: RawTool[] }>();

async function fetchToolkitTools(
  composio: { tools: { getRawComposioTools: (a: { toolkits: string[]; limit: number }) => Promise<unknown> } },
  tk: string
): Promise<RawTool[]> {
  const hit = toolkitToolsCache.get(tk);
  if (hit && Date.now() - hit.at < TOOLKIT_TTL_MS) return hit.tools;
  // Prefer Composio's CURATED "important" set: ~40 high-value tools (send/list/get/create) that
  // are the ones users actually invoke — and it includes core reads like GITHUB_LIST_REPOSITORIES
  // that a flat alphabetical limit:200 of a 600-tool app silently drops. Fall back to a wide flat
  // fetch if the curated set comes back thin.
  let raw = (await composio.tools.getRawComposioTools({ toolkits: [tk], important: true, limit: 60 } as never)) as RawTool[];
  if (!raw || raw.length < 12) {
    raw = (await composio.tools.getRawComposioTools({ toolkits: [tk], limit: 200 })) as RawTool[];
  }
  raw = raw ?? [];
  toolkitToolsCache.set(tk, { at: Date.now(), tools: raw });
  return raw;
}

// Build the read/write tool catalog for the uid's ACTIVE connected toolkits.
// Mirrors the toolkit-resolution shape used by tools/route.ts + connections/route.ts.
export async function loadReadWriteCatalog(
  composio: { connectedAccounts: { list: (a: { userIds: string[] }) => Promise<unknown> }; tools: { getRawComposioTools: (a: { toolkits: string[]; limit: number }) => Promise<unknown> } },
  uid: string,
  // The spoken request — used to keep the actions relevant to THIS request inside the per-toolkit
  // cap (apps like GitHub have 500+ tools; an alphabetical fetch+cap dropped GITHUB_CREATE_AN_ISSUE).
  query = ""
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
    const raw = await fetchToolkitTools(composio, tk);
    const byPriority = [...raw].sort((a, b) => toolPriority(b.slug) - toolPriority(a.slug));
    const scorable = byPriority.map((t) => ({ slug: t.slug, description: t.description ?? "", readOnly: false, raw: t }));
    const reranked = query ? rankByLexical(query, scorable) : scorable;
    const ranked = reranked.slice(0, 45).map((s) => s.raw);
    for (const t of ranked) {
      const d = (t.description ?? "").replace(/\n/g, " ");
      const short = d.length > 120 ? d.slice(0, 120) + "…" : d;
      const args = toolArgNames(t);
      // Attach example user phrases so JARVIS matches a spoken request to the right action faster
      // and more accurately (the action data, surfaced to the planner — the "make JARVIS smarter").
      const ex = phrasesFor(tk, t.slug).slice(0, 2);
      let desc = args.length ? `${short} [args: ${args.join(", ")}]` : short;
      if (ex.length) desc += ` (e.g. ${ex.map((p) => `"${p}"`).join(", ")})`;
      // A tool whose REQUIRED input is a file can't be satisfied by voice alone — say so up front,
      // so the planner asks for the file (inputRequest) instead of failing at execution.
      if (hasRequiredFile(t.inputParameters)) desc += " [REQUIRES A LOCAL FILE — ask the user for it]";
      out.push({
        slug: t.slug,
        description: desc,
        readOnly: isReadOnly(t.slug),
        schema: compactSchema(t.inputParameters),
        ip: t.inputParameters,
      });
    }
  }
  return out;
}
