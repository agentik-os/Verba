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

// Curated EXACT slugs that are verified reads. An exact slug match is the strongest evidence we
// have, so it is checked FIRST — ahead of the write-verb blocklist. That is what makes this list
// useful at all: it is the escape hatch for a genuine read whose slug happens to contain a token
// that reads as a write verb (GMAIL_GET_DRAFT, TWITTER_GET_POST_ANALYTICS: DRAFT and POST are
// NOUNS there, the object of the GET). Previously this set sat AFTER the write test and every
// entry also matched READ_RE on its own, so it was dead code that changed no decision.
// Only add a slug here after confirming in Composio's catalog that it mutates nothing.
const READ_ALLOW = new Set<string>([
  "GOOGLECALENDAR_FREE_BUSY",
  "GOOGLECALENDAR_FIND_FREE_SLOTS",
  "GMAIL_GET_PROFILE",
  "GMAIL_GET_CONTACTS",
  "GMAIL_LIST_THREADS",
  "GMAIL_GET_DRAFT",
  "GMAIL_LIST_DRAFTS",
  "GMAIL_LIST_SEND_AS",
  "SLACK_LIST_ALL_USERS",
  "SLACK_LIST_ALL_CHANNELS",
  "NOTION_FETCH_DATABASE",
  "NOTION_QUERY_DATABASE",
  "GITHUB_LIST_REPOSITORIES_FOR_THE_AUTHENTICATED_USER",
  "LINEAR_LIST_ISSUES",
  "LINEAR_GET_ISSUE",
  "JIRA_GET_ISSUE_CREATE_METADATA",
  "JIRA_GET_ISSUE_EDIT_METADATA",
  "TWITTER_GET_POST_ANALYTICS",
  "TWITTER_LIST_POST_LIKERS",
  "TWITTER_GET_POST_RETWEETS",
  "GITLAB_GET_PROJECT_MERGE_REQUESTS",
  "GITLAB_GET_MERGE_REQUEST_NOTES",
]);

// Write verbs that must NEVER be auto-run even if the slug also matches a read pattern
// (e.g. FIND_AND_DELETE). If a write verb is present anywhere, force WRITE.
//
// The second line is the set this classifier used to MISS, each one verified against a real
// Composio slug that was being auto-executed with no confirmation card:
//   REPLACE  → GOOGLESHEETS_FIND_REPLACE   ("replace every 2025 with 2026") rewrote the sheet
//   FOLLOW   → TWITTER_FOLLOW_LIST         a public action on the user's own account
//   WATCH    → GOOGLECALENDAR_CALENDAR_LIST_WATCH  opens a persistent push channel
//   ANSWER   → TELEGRAM_ANSWER_CALLBACK_QUERY      sends a message
//   OPERATION→ SHOPIFY_BULK_QUERY_OPERATION        starts a server-side bulk job
// All five contain a READ_RE token (FIND/LIST/QUERY) and no old WRITE_RE token, so they were
// classified read-only and ran through the auto-exec path. The rest of the line is the same class
// of mutation verb, added before it is paid for on a live account.
// Deliberately NOT here: BATCH and BULK (GOOGLESHEETS_BATCH_GET, JIRA_FETCH_BULK_ISSUES are reads)
// and ISSUE (a noun in LINEAR_LIST_ISSUES / JIRA_GET_ISSUE, not the verb).
const WRITE_RE =
  /(?:^|_)(CREATE|SEND|UPDATE|DELETE|REMOVE|ADD|POST|PUT|PATCH|STAR|UNSTAR|ARCHIVE|TRASH|MOVE|SET|EDIT|MODIFY|INSERT|UPSERT|REPLY|FORWARD|DRAFT|INVITE|SHARE|UPLOAD|MARK|ASSIGN|CLOSE|MERGE|CANCEL|DECLINE|ACCEPT|RSVP|PUBLISH|REVOKE|GRANT|REPLACE|FOLLOW|UNFOLLOW|WATCH|UNWATCH|ANSWER|OPERATION|SUBSCRIBE|UNSUBSCRIBE|JOIN|LEAVE|KICK|BAN|UNBAN|MUTE|UNMUTE|PIN|UNPIN|LOCK|UNLOCK|ENABLE|DISABLE|APPROVE|REJECT|SNOOZE|CLEAR|EMPTY|PURGE|RESET|RESTORE|DUPLICATE|CLONE|COPY|IMPORT|SYNC|TRIGGER|RUN|EXECUTE|START|STOP|PAUSE|RESUME|APPEND|WRITE|SAVE|SUBMIT|RENAME|TRANSFER|APPLY|INSTALL|UNINSTALL|DEPLOY|REFUND|CHARGE|REOPEN|ACTIVATE|DEACTIVATE)(?:_|$)/;

/// Slug-only read/write classification. Order matters and is the whole safety argument:
///   1. an exact curated slug is a READ (strongest evidence, human-verified)
///   2. any write verb anywhere is a WRITE (blocklist, fail-safe)
///   3. a read verb with no write verb is a READ
///   4. no recognized verb at all is a WRITE (fail-safe: unknown is never auto-run)
export function isReadOnly(slug: string): boolean {
  const s = (slug ?? "").toUpperCase();
  if (!s) return false;
  if (READ_ALLOW.has(s)) return true;
  if (WRITE_RE.test(s)) return false;
  return READ_RE.test(s);
}

/// Read/write classification WITH the tool's Composio metadata, when the caller has it.
/// Today this adds exactly one fact on top of the slug heuristic: a DEPRECATED tool is never
/// auto-run unattended. Metadata is optional throughout the SDK, so an absent field changes
/// nothing, and this can only ever be MORE conservative than isReadOnly(), never less.
///
/// Deliberately NOT used here: the tool's OAuth `scopes`. Requiring every scope to look read-only
/// (".readonly" / ":read" / "read:…") looks like a stronger safety signal and is actually a trap,
/// because providers grant reads through BROAD scopes: Gmail's read tools ride on
/// `.../auth/gmail.modify`, and Slack's history reads use `channels:history`, neither of which
/// matches a read-only naming convention. Gating on that would have reclassified the core Gmail
/// and Slack READS as writes and silently blinded the planner's context gathering — a worse
/// regression than the bug it was meant to backstop, and one that cannot be verified here without
/// live Composio credentials. The slug classifier is the tested gate (see isReadOnly); if a
/// metadata-based gate is wanted later it must be built from a real scope inventory, not a
/// naming guess.
export function isReadOnlyTool(t: { slug: string; isDeprecated?: boolean }): boolean {
  if (!isReadOnly(t.slug)) return false;
  if (t.isDeprecated) return false;
  return true;
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
export function toolPriority(slug: string): number {
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
  // Catalog metadata the SDK marks optional; isReadOnlyTool uses isDeprecated.
  isDeprecated?: boolean;
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
  ip?: {
    properties?: Record<string, JsonSchema>;
    required?: string[];
    additionalProperties?: boolean;
  }
): string[] {
  const props = ip?.properties;
  if (!props) return [];
  const errs: string[] = [];
  for (const r of ip?.required ?? []) {
    const v = args[r];
    // An empty STRING is a legitimate value for a string field (an email with no body, a cleared
    // note). Only absence is absence; treating "" as missing made the repairer invent content.
    const missing = v === undefined || v === null || (v === "" && !acceptsType(props[r], "string"));
    if (missing) errs.push(`missing required field "${r}"`);
  }
  // Only complain about unknown fields when the schema actually closes the object. A schema with
  // both `properties` and `additionalProperties` (map-typed arguments) legitimately carries keys
  // that are not listed — and a false "unknown field" here is not cosmetic: the repair prompt is
  // told to "drop unknown fields", so it DELETES the user's real data before the confirm card.
  const closed = ip?.additionalProperties !== true;
  for (const [k, v] of Object.entries(args)) {
    const spec = props[k];
    if (!spec) {
      if (closed) errs.push(`unknown field "${k}" (not in the tool's schema)`);
      continue;
    }
    // A composed schema (oneOf/anyOf/allOf/$ref) cannot be judged by a shallow type check, and
    // guessing produced errors that sent valid arguments to the repairer. Leave these alone.
    if (spec.oneOf || spec.anyOf || spec.allOf || spec.$ref) continue;
    if (v === null && (spec.nullable === true || acceptsType(spec, "null"))) continue;

    if (acceptsType(spec, "array") && !Array.isArray(v)) {
      errs.push(`"${k}" must be an ARRAY (got ${typeof v})`);
    } else if (acceptsType(spec, "object") && !acceptsType(spec, "array") && (typeof v !== "object" || v === null || Array.isArray(v))) {
      errs.push(`"${k}" must be an OBJECT`);
    } else if (acceptsType(spec, "string") && typeof v !== "string") {
      errs.push(`"${k}" must be a string`);
    } else if ((acceptsType(spec, "number") || acceptsType(spec, "integer")) && typeof v !== "number") {
      errs.push(`"${k}" must be a number`);
    } else if (acceptsType(spec, "boolean") && typeof v !== "boolean") {
      errs.push(`"${k}" must be a boolean`);
    }

    // The item type of a list is the shape compactSchema advertises to the planner as load-bearing
    // ("array of {role, content}"), and it was the one thing the validator never checked — so the
    // classic failure, a bare string where a list of objects is required, passed validation and
    // failed at execution instead.
    if (Array.isArray(v) && spec.items) {
      const itemSpec = spec.items;
      if (!(itemSpec.oneOf || itemSpec.anyOf || itemSpec.allOf || itemSpec.$ref)) {
        for (const el of v.slice(0, 10)) {
          if (acceptsType(itemSpec, "object") && (typeof el !== "object" || el === null || Array.isArray(el))) {
            errs.push(`"${k}" must be a list of OBJECTS, not of ${typeof el}`);
            break;
          }
          if (acceptsType(itemSpec, "string") && typeof el !== "string") {
            errs.push(`"${k}" must be a list of strings`);
            break;
          }
        }
      }
    }

    // Enums are surfaced to the planner by typeStr, so an invented value is a real failure mode.
    if (Array.isArray(spec.enum) && spec.enum.length && !spec.enum.includes(v as never)) {
      errs.push(`"${k}" must be one of: ${spec.enum.slice(0, 8).join(", ")}`);
    }
  }
  return errs;
}

// `type` is legally either a string or a list of strings (`["string","null"]`). Reading it as a
// string alone meant a nullable field matched NO branch and was silently accepted unchecked.
function acceptsType(spec: JsonSchema, want: string): boolean {
  const t = spec?.type;
  if (typeof t === "string") return t === want;
  if (Array.isArray(t)) return t.includes(want);
  return false;
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

export async function fetchToolkitTools(
  composio: { tools: { getRawComposioTools: (a: { toolkits: string[]; limit: number }) => Promise<unknown> } },
  tk: string
): Promise<RawTool[]> {
  const hit = toolkitToolsCache.get(tk);
  if (hit && Date.now() - hit.at < TOOLKIT_TTL_MS) return hit.tools;
  // Prefer Composio's CURATED "important" set: ~40 high-value tools (send/list/get/create) that
  // are the ones users actually invoke — and it includes core reads like GITHUB_LIST_REPOSITORIES
  // that a flat alphabetical limit:200 of a 600-tool app silently drops. Fall back to a wide flat
  // fetch if the curated set comes back thin.
  let raw: RawTool[];
  try {
    raw = ((await composio.tools.getRawComposioTools({ toolkits: [tk], important: true, limit: 60 } as never)) as RawTool[]) ?? [];
    if (raw.length < 12) {
      const wide = ((await composio.tools.getRawComposioTools({ toolkits: [tk], limit: 200 })) as RawTool[]) ?? [];
      // Keep the wide set only when it is actually WIDER. This used to assign it unconditionally, so
      // a hiccup on this SECOND call threw away a perfectly good curated set: the toolkit went from
      // "thin but real" to empty because the fallback meant to enrich it failed. The wide fetch is a
      // superset of the curated one for the same toolkit, so fewer tools here always means a bad call.
      if (wide.length > raw.length) raw = wide;
    }
  } catch (e) {
    // A RATE LIMIT DOES NOT COME BACK AS AN EMPTY LIST, IT THROWS. @composio/client treats 429 as
    // retryable, then throws a status error once its retries are spent, and _lib.ts already renders
    // that error string to the user. So the stale-tools path below has to cover the THROW too:
    // without this catch, the exact incident this cache is being hardened against still answers
    // /tools with a 502 and the app shows no tools at all for an app the user sees as connected.
    // With nothing to fall back on, rethrow, so a genuine hard failure surfaces as an error instead
    // of masquerading as an app that legitimately has no tools.
    const stale = toolkitToolsCache.get(tk);
    if (stale?.tools.length) return stale.tools;
    throw e;
  }
  // NEVER CACHE AN EMPTY RESULT. A Composio hiccup can hand back an empty page for a toolkit that
  // really has tools, and writing that answers /tools with ZERO tools for the whole 10-minute
  // window: the Mac app then shows a connected app with an empty tool list and latches it. So on
  // an empty fetch, leave the cache UNSET so the very next request retries,
  // and if a previous non-empty entry exists serve it even though it has expired. Stale tools beat
  // no tools for a prompt catalog, and this can only ever return MORE tools than before, never less.
  if (raw.length === 0) {
    const stale = toolkitToolsCache.get(tk);
    return stale?.tools.length ? stale.tools : [];
  }
  toolkitToolsCache.set(tk, { at: Date.now(), tools: raw });
  return raw;
}

// Composio's manual execution requires a CONCRETE toolkit version — it rejects a call with none
// ("Toolkit version not specified"), which is why every execution path resolves the tool's version
// by slug first. This used to be copy-pasted three times with two different bugs:
//   - execute/route.ts resolved it INSIDE the request with NO cache, so every confirmed write paid
//     an extra Composio round-trip at the most latency-sensitive moment in the product.
//   - agent/route.ts and agent-reads/route.ts cached with `if (!cache.has(slug))`, which stored
//     `undefined` when the lookup THREW. A single transient Composio blip then permanently pinned
//     that slug to "no version" for the whole warm instance, and every later call failed with the
//     exact "Toolkit version not specified" error the cache exists to prevent.
// One implementation, and it only ever caches a SUCCESSFUL lookup: a failure is retried next time.
/// What the execution paths need to know about a tool before running it: its concrete version, the
/// toolkit that owns it (authoritative — a slug prefix is not, e.g. GOOGLE_MAPS_*), and whether it
/// needs a connected account at all.
export interface ToolMeta {
  version?: string;
  toolkit?: string;
  isNoAuth?: boolean;
}

const toolMetaCache = new Map<string, ToolMeta>();

export async function resolveToolMeta(
  composio: { tools: { getRawComposioTools: (a: { tools: string[]; limit: number }) => Promise<unknown> } },
  slug: string
): Promise<ToolMeta> {
  const hit = toolMetaCache.get(slug);
  if (hit) return hit;
  try {
    const raw = (await composio.tools.getRawComposioTools({ tools: [slug], limit: 1 })) as {
      slug: string;
      version?: string;
      toolkit?: { slug?: string } | string;
      isNoAuth?: boolean;
    }[];
    const t = raw?.find((x) => x.slug === slug) ?? raw?.[0];
    if (!t) return {};
    const tk = typeof t.toolkit === "string" ? t.toolkit : t.toolkit?.slug;
    const meta: ToolMeta = {
      version: t.version,
      toolkit: tk ? tk.toUpperCase() : undefined,
      isNoAuth: t.isNoAuth,
    };
    // Cache successes only — never a failed lookup.
    if (meta.version || meta.toolkit) toolMetaCache.set(slug, meta);
    return meta;
  } catch {
    return {}; // best effort: some no-auth tools execute without an explicit version
  }
}

/// The uid's ACTIVE connected toolkit slugs, briefly cached. Used to authorize a tool call: a
/// signed-in user may only run tools belonging to an app they actually connected.
const ACTIVE_TTL_MS = 60 * 1000;
const activeToolkitsCache = new Map<string, { at: number; toolkits: Set<string> }>();

export async function activeToolkits(
  composio: { connectedAccounts: { list: (a: { userIds: string[] }) => Promise<unknown> } },
  uid: string,
  // Skip the cache. A user who has JUST finished connecting an app would otherwise be told for up
  // to a minute that the app is not connected, so a negative result is always re-checked fresh
  // before it is allowed to block a call.
  fresh = false
): Promise<Set<string>> {
  const hit = activeToolkitsCache.get(uid);
  if (!fresh && hit && Date.now() - hit.at < ACTIVE_TTL_MS) return hit.toolkits;
  const list = (await composio.connectedAccounts.list({ userIds: [uid] })) as {
    items?: { status?: string; toolkit?: { slug?: string } | string }[];
  };
  const toolkits = new Set(
    (list.items ?? [])
      .filter((i) => i.status === "ACTIVE")
      .map((i) => {
        const tk = i.toolkit;
        return (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
      })
      .filter(Boolean)
  );
  activeToolkitsCache.set(uid, { at: Date.now(), toolkits });
  return toolkits;
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
        // Metadata-aware: the tool's own deprecation flag can only make this STRICTER than the
        // slug heuristic, never looser. This flag is what the planner prompt renders as READ/WRITE.
        readOnly: isReadOnlyTool(t),
        schema: compactSchema(t.inputParameters),
        ip: t.inputParameters,
      });
    }
  }
  return out;
}
