// Local, model-free action retrieval for JARVIS: a tiny BM25 ranker over the connected toolkits'
// actions (slug words + description + example phrases). Zero embeddings, zero tokens, zero network —
// it just surfaces the most relevant actions for a spoken request so the planner zeroes in fast.

export interface ScorableTool {
  slug: string;
  description: string;
  readOnly: boolean;
}

const STOP = new Set(
  ("the a an to of for in on at with and or but my your me i you he she it we they this that these those is are be can " +
    "could would should please will just want need add new get set make do my mine our")
    .split(" ")
);

function tokenize(s: string): string[] {
  return (s.toLowerCase().match(/[a-z0-9]+/g) ?? []).filter((t) => t.length > 2 && !STOP.has(t));
}

/// Rank `tools` by BM25 relevance to `query`; returns a new array, most-relevant first. Ties and
/// no-match queries keep the original order, so this only ever *improves* ordering.
export function rankByLexical<T extends ScorableTool>(query: string, tools: T[]): T[] {
  const q = tokenize(query);
  if (q.length === 0 || tools.length === 0) return tools;

  const docs = tools.map((t) => tokenize(t.slug.replace(/_/g, " ") + " " + t.description));
  const N = docs.length;
  const avgLen = docs.reduce((a, d) => a + d.length, 0) / N || 1;

  const df: Record<string, number> = {};
  for (const d of docs) for (const term of new Set(d)) df[term] = (df[term] ?? 0) + 1;

  const k1 = 1.5;
  const b = 0.75;
  const scored = tools.map((t, i) => {
    const d = docs[i];
    const len = d.length || 1;
    const tf: Record<string, number> = {};
    for (const term of d) tf[term] = (tf[term] ?? 0) + 1;
    let score = 0;
    for (const term of q) {
      const f = tf[term] ?? 0;
      if (!f) continue;
      const n = df[term] ?? 0;
      const idf = Math.log(1 + (N - n + 0.5) / (n + 0.5));
      score += idf * ((f * (k1 + 1)) / (f + k1 * (1 - b + (b * len) / avgLen)));
    }
    return { t, score, i };
  });
  // Stable sort: higher score first, original order on ties.
  scored.sort((a, c) => c.score - a.score || a.i - c.i);
  return scored.map((s) => s.t);
}

/// The top-K slugs that actually matched at least one query term (for the planner's "best matches").
export function topMatches(query: string, tools: ScorableTool[], k = 10): string[] {
  const q = new Set(tokenize(query));
  if (q.size === 0) return [];
  const ranked = rankByLexical(query, tools);
  const out: string[] = [];
  for (const t of ranked) {
    const toks = new Set(tokenize(t.slug.replace(/_/g, " ") + " " + t.description));
    if ([...q].some((term) => toks.has(term))) out.push(t.slug);
    if (out.length >= k) break;
  }
  return out;
}
