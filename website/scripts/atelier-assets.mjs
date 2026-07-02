// Build step (runs before `next build`): copies every non-markdown file from marketing/
// into website/public/atelier/ (preserving relative paths). The output lives under
// public/atelier/ which is gitignored (a reproducible build artifact) and gated by middleware.
// (The client search index is prop-fed from lib/atelier's searchIndex() — no JSON artifact.)
import fs from "node:fs";
import path from "node:path";

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

const marketingDir = locateMarketingDir();
const outDir = path.join(process.cwd(), "public", "atelier");

// Clean prior artifact so removed source files don't linger.
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

let assetCount = 0;

function walk(absDir, relDir) {
  for (const entry of fs.readdirSync(absDir, { withFileTypes: true })) {
    const rel = relDir ? `${relDir}/${entry.name}` : entry.name;
    const abs = path.join(absDir, entry.name);
    if (entry.isDirectory()) {
      walk(abs, rel);
    } else if (!entry.name.endsWith(".md")) {
      // Non-markdown asset → copy into public/atelier/ preserving the relative path.
      // (Markdown is rendered by lib/atelier at build time, never served raw.)
      const dest = path.join(outDir, rel);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(abs, dest);
      assetCount++;
    }
  }
}

walk(marketingDir, "");

console.log(`[atelier-assets] copied ${assetCount} assets into public/atelier/ from ${marketingDir}`);
