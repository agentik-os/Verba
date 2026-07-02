// Build-time-only module (uses Node fs). Scans the repo's `marketing/**` tree into a
// folder/doc model and renders each markdown file to HTML with internal link rewriting.
// NEVER import this from a client component or a runtime (edge/serverless) path — it reads
// the filesystem and must only run during `next build` / static generation.
import fs from "node:fs";
import path from "node:path";
import { Marked } from "marked";

export interface AtelierDoc {
  slug: string; // "" for the root index, else e.g. "fundraising/investors-research"
  title: string;
  relPath: string; // path relative to the marketing dir, e.g. "fundraising/investors-research.md"
}

export interface AtelierFolder {
  name: string; // display name (folder basename; "Atelier" for the root)
  slug: string; // "" for root, else e.g. "fundraising"
  readme?: AtelierDoc; // the folder's README.md, rendered as its index page
  folders: AtelierFolder[];
  docs: AtelierDoc[]; // non-README docs directly inside this folder
}

interface AtelierModel {
  marketingDir: string;
  tree: AtelierFolder;
  docsBySlug: Map<string, AtelierDoc>; // non-README docs
  foldersBySlug: Map<string, AtelierFolder>;
  mdSet: Set<string>; // every markdown relPath under marketing/
  assetSet: Set<string>; // every non-markdown file relPath under marketing/
}

const README = "README.md";

// YAML frontmatter is metadata — never rendered content, never a title source.
function stripFrontmatter(content: string): string {
  if (!content.startsWith("---\n")) return content;
  const end = content.indexOf("\n---\n", 3);
  if (end === -1) return content;
  return content.slice(end + 5);
}

// Minimal HTML-escape for values interpolated into attributes by the custom renderer.
function escapeAttr(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// GitHub-style heading slug: lowercase, drop punctuation, spaces → hyphens.
function slugifyHeading(text: string): string {
  return text
    .trim()
    .toLowerCase()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");
}

// A markdown file's page slug. README.md maps to its folder's slug (root README → "").
function mdSlug(relPath: string): string {
  const parts = relPath.split("/");
  if (parts[parts.length - 1] === README) {
    parts.pop();
    return parts.join("/");
  }
  return relPath.replace(/\.md$/, "");
}

function firstHeadingOrName(content: string, fallbackName: string): string {
  const m = content.match(/^#\s+(.+?)\s*$/m);
  if (m) return m[1].trim();
  return fallbackName.replace(/\.md$/, "");
}

function locateMarketingDir(): string {
  const candidates = [
    path.join(process.cwd(), "..", "marketing"),
    path.join(process.cwd(), "marketing"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c) && fs.statSync(c).isDirectory()) return c;
  }
  throw new Error(
    `[atelier] marketing directory not found. Looked in: ${candidates.join(", ")}. ` +
      `Refusing to render an empty docs site.`,
  );
}

let cached: AtelierModel | null = null;

export function buildAtelier(): AtelierModel {
  if (cached) return cached;
  const marketingDir = locateMarketingDir();
  const docsBySlug = new Map<string, AtelierDoc>();
  const foldersBySlug = new Map<string, AtelierFolder>();
  const mdSet = new Set<string>();
  const assetSet = new Set<string>();

  function walk(absDir: string, relDir: string, displayName: string): AtelierFolder {
    const folder: AtelierFolder = { name: displayName, slug: relDir, folders: [], docs: [] };
    const entries = fs.readdirSync(absDir, { withFileTypes: true });
    // Directories first, then files; each group alphabetical for a stable sidebar.
    const dirs = entries.filter((e) => e.isDirectory()).sort((a, b) => a.name.localeCompare(b.name));
    const files = entries.filter((e) => e.isFile()).sort((a, b) => a.name.localeCompare(b.name));

    for (const d of dirs) {
      const childRel = relDir ? `${relDir}/${d.name}` : d.name;
      folder.folders.push(walk(path.join(absDir, d.name), childRel, d.name));
    }
    for (const f of files) {
      const rel = relDir ? `${relDir}/${f.name}` : f.name;
      if (f.name.endsWith(".md")) {
        mdSet.add(rel);
        const content = stripFrontmatter(fs.readFileSync(path.join(absDir, f.name), "utf8"));
        const doc: AtelierDoc = { slug: mdSlug(rel), title: firstHeadingOrName(content, f.name), relPath: rel };
        if (f.name === README) {
          folder.readme = doc;
        } else {
          folder.docs.push(doc);
          docsBySlug.set(doc.slug, doc);
        }
      } else {
        assetSet.add(rel);
      }
    }
    foldersBySlug.set(relDir, folder);
    return folder;
  }

  const tree = walk(marketingDir, "", "Atelier");
  cached = { marketingDir, tree, docsBySlug, foldersBySlug, mdSet, assetSet };
  return cached;
}

// Every static param: root ("") + every folder + every non-README doc.
export function allSlugs(): string[] {
  const { docsBySlug, foldersBySlug } = buildAtelier();
  const set = new Set<string>();
  for (const s of foldersBySlug.keys()) set.add(s);
  for (const s of docsBySlug.keys()) set.add(s);
  return [...set];
}

export interface LinkReport {
  total: number;
  toPage: number;
  toAsset: number;
  dead: number;
  deadTargets: string[]; // "<docRelPath> -> <rawHref>"
}

// Resolve one relative href from a doc against the marketing tree. Pure, so it is reusable
// by both the renderer and the link-resolution report.
type Resolution =
  | { kind: "page"; href: string }
  | { kind: "asset"; href: string }
  | { kind: "external"; href: string }
  | { kind: "anchor"; href: string }
  | { kind: "dead" };

function resolveHref(model: AtelierModel, docRelPath: string, rawHref: string): Resolution {
  const href = rawHref.trim();
  if (!href) return { kind: "dead" };
  if (/^(https?:)?\/\//i.test(href) || /^(mailto:|tel:)/i.test(href)) {
    return { kind: "external", href };
  }
  if (href.startsWith("#")) return { kind: "anchor", href };

  const hashIdx = href.indexOf("#");
  const pathPart = hashIdx >= 0 ? href.slice(0, hashIdx) : href;
  const anchor = hashIdx >= 0 ? href.slice(hashIdx) : "";
  if (!pathPart) return { kind: "anchor", href };

  const docDir = path.posix.dirname(docRelPath === "" ? "." : docRelPath);
  let target = path.posix.normalize(path.posix.join(docDir === "." ? "" : docDir, pathPart));
  target = target.replace(/\/$/, ""); // trailing slash off for folder links

  // Escapes the marketing root → treat as unpublished/dead.
  if (target === ".." || target.startsWith("../")) return { kind: "dead" };
  if (target === ".") return { kind: "page", href: "/atelier" + anchor };

  if (model.mdSet.has(target)) {
    const slug = mdSlug(target);
    return { kind: "page", href: "/atelier" + (slug ? "/" + slug : "") + anchor };
  }
  if (model.foldersBySlug.has(target)) {
    return { kind: "page", href: "/atelier/" + target + anchor };
  }
  if (model.assetSet.has(target)) {
    return { kind: "asset", href: "/atelier/" + target + anchor };
  }
  return { kind: "dead" };
}

function makeMarked(model: AtelierModel, docRelPath: string): Marked {
  const usedIds = new Map<string, number>();
  const m = new Marked({ gfm: true });
  m.use({
    renderer: {
      heading(token) {
        const text = this.parser.parseInline(token.tokens);
        let id = slugifyHeading(token.text.replace(/<[^>]+>/g, ""));
        if (!id) id = "section";
        const n = usedIds.get(id) ?? 0;
        usedIds.set(id, n + 1);
        if (n > 0) id = `${id}-${n}`;
        return `<h${token.depth} id="${escapeAttr(id)}">${text}</h${token.depth}>`;
      },
      link(token) {
        const inner = this.parser.parseInline(token.tokens);
        const r = resolveHref(model, docRelPath, token.href);
        const titleAttr = token.title ? ` title="${escapeAttr(token.title)}"` : "";
        switch (r.kind) {
          case "external":
            return `<a href="${escapeAttr(r.href)}"${titleAttr} target="_blank" rel="noopener">${inner}</a>`;
          case "page":
          case "asset":
          case "anchor":
            return `<a href="${escapeAttr(r.href)}"${titleAttr}>${inner}</a>`;
          case "dead":
          default:
            return `<span class="dead-link" title="document interne non publié">${inner}</span>`;
        }
      },
    },
  });
  return m;
}

export function renderMarkdown(docRelPath: string, content: string): string {
  const model = buildAtelier();
  const m = makeMarked(model, docRelPath);
  return m.parse(stripFrontmatter(content), { async: false }) as string;
}

export function getDoc(slug: string): { doc: AtelierDoc; html: string } | null {
  const model = buildAtelier();
  const doc = model.docsBySlug.get(slug);
  if (!doc) return null;
  const content = fs.readFileSync(path.join(model.marketingDir, doc.relPath), "utf8");
  return { doc, html: renderMarkdown(doc.relPath, content) };
}

export function getFolder(slug: string): {
  folder: AtelierFolder;
  readmeHtml: string | null;
} | null {
  const model = buildAtelier();
  const folder = model.foldersBySlug.get(slug);
  if (!folder) return null;
  let readmeHtml: string | null = null;
  if (folder.readme) {
    const content = fs.readFileSync(path.join(model.marketingDir, folder.readme.relPath), "utf8");
    readmeHtml = renderMarkdown(folder.readme.relPath, content);
  }
  return { folder, readmeHtml };
}

// Breadcrumb trail for a slug: [{label, href}] from Atelier root to the current node.
export function breadcrumb(slug: string): { label: string; href: string }[] {
  const model = buildAtelier();
  const trail: { label: string; href: string }[] = [{ label: "Atelier", href: "/atelier" }];
  if (!slug) return trail;
  const parts = slug.split("/");
  let acc = "";
  for (let i = 0; i < parts.length; i++) {
    acc = acc ? `${acc}/${parts[i]}` : parts[i];
    // Prefer a doc/folder title when we have one; else the raw segment.
    const doc = model.docsBySlug.get(acc);
    const folder = model.foldersBySlug.get(acc);
    const label = folder ? (folder.name === "Atelier" ? "Atelier" : folder.name) : doc ? doc.title : parts[i];
    trail.push({ label, href: "/atelier/" + acc });
  }
  return trail;
}

// Flat search index consumed by the client search box: every doc (incl. folder READMEs).
export function searchIndex(): { slug: string; title: string; folder: string }[] {
  const { mdSet } = buildAtelier();
  const list: { slug: string; title: string; folder: string }[] = [];
  const model = buildAtelier();
  for (const rel of mdSet) {
    const slug = mdSlug(rel);
    const doc = model.docsBySlug.get(slug);
    const folder = model.foldersBySlug.get(slug);
    const title = doc ? doc.title : folder?.readme ? folder.readme.title : slug || "Atelier";
    list.push({ slug, title, folder: path.posix.dirname(rel) === "." ? "" : path.posix.dirname(rel) });
  }
  return list.sort((a, b) => a.slug.localeCompare(b.slug));
}

// Link-resolution report across every markdown doc — for the D2 build-time proof.
export function linkReport(): LinkReport {
  const model = buildAtelier();
  const report: LinkReport = { total: 0, toPage: 0, toAsset: 0, dead: 0, deadTargets: [] };
  const linkRe = /\]\(([^)]+)\)/g;
  for (const rel of model.mdSet) {
    const content = fs.readFileSync(path.join(model.marketingDir, rel), "utf8");
    let match: RegExpExecArray | null;
    while ((match = linkRe.exec(content)) !== null) {
      const raw = match[1].split(/\s+/)[0]; // drop optional "title"
      if (/^(https?:)?\/\//i.test(raw) || /^(mailto:|tel:|#)/i.test(raw)) continue;
      report.total++;
      const r = resolveHref(model, rel, raw);
      if (r.kind === "page") report.toPage++;
      else if (r.kind === "asset") report.toAsset++;
      else if (r.kind === "anchor" || r.kind === "external") report.total--; // not a doc-relative link
      else {
        report.dead++;
        report.deadTargets.push(`${rel} -> ${raw}`);
      }
    }
  }
  return report;
}
