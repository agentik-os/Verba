// Build step (runs before `next build`): copies every non-markdown file from marketing/
// into website/public/atelier/ (preserving relative paths) and emits _search.json — the
// client-side search index of [{slug,title,folder}] for all docs. Both outputs live under
// public/atelier/ which is gitignored (a reproducible build artifact) and gated by middleware.
import fs from "node:fs";
import path from "node:path";

const README = "README.md";

function locateMarketingDir() {
  const candidates = [
    path.join(process.cwd(), "..", "marketing"),
    path.join(process.cwd(), "marketing"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c) && fs.statSync(c).isDirectory()) return c;
  }
  throw new Error(`[atelier-assets] marketing directory not found. Looked in: ${candidates.join(", ")}`);
}

function mdSlug(relPath) {
  const parts = relPath.split("/");
  if (parts[parts.length - 1] === README) {
    parts.pop();
    return parts.join("/");
  }
  return relPath.replace(/\.md$/, "");
}

function firstHeadingOrName(content, fallbackName) {
  const m = content.match(/^#\s+(.+?)\s*$/m);
  return m ? m[1].trim() : fallbackName.replace(/\.md$/, "");
}

const marketingDir = locateMarketingDir();
const outDir = path.join(process.cwd(), "public", "atelier");

// Clean prior artifact so removed source files don't linger.
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

let assetCount = 0;
const search = [];

function walk(absDir, relDir) {
  for (const entry of fs.readdirSync(absDir, { withFileTypes: true })) {
    const rel = relDir ? `${relDir}/${entry.name}` : entry.name;
    const abs = path.join(absDir, entry.name);
    if (entry.isDirectory()) {
      walk(abs, rel);
    } else if (entry.name.endsWith(".md")) {
      const content = fs.readFileSync(abs, "utf8");
      search.push({
        slug: mdSlug(rel),
        title: firstHeadingOrName(content, entry.name),
        folder: relDir,
      });
    } else {
      // Non-markdown asset → copy into public/atelier/ preserving the relative path.
      const dest = path.join(outDir, rel);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(abs, dest);
      assetCount++;
    }
  }
}

walk(marketingDir, "");

fs.writeFileSync(path.join(outDir, "_search.json"), JSON.stringify(search));

console.log(
  `[atelier-assets] copied ${assetCount} assets + ${search.length} search entries into public/atelier/ from ${marketingDir}`,
);
