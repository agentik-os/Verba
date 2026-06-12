import Link from "next/link";
import ThemeToggle from "./ThemeToggle";

// Minimal, dependency-free markdown renderer for our own trusted legal/contact docs.
// Supports: #/##/### headings, - bullet lists, **bold**, [text](url) links, and paragraphs.
function inline(text: string, keyBase: string): React.ReactNode[] {
  const nodes: React.ReactNode[] = [];
  // Split on links first, then bold within each segment.
  const linkRe = /\[([^\]]+)\]\(([^)]+)\)/g;
  let last = 0;
  let m: RegExpExecArray | null;
  let i = 0;
  const pushBold = (s: string, kb: string) => {
    s.split(/(\*\*[^*]+\*\*)/g).forEach((part, j) => {
      if (part.startsWith("**") && part.endsWith("**")) nodes.push(<strong key={`${kb}-b${j}`}>{part.slice(2, -2)}</strong>);
      else if (part) nodes.push(<span key={`${kb}-s${j}`}>{part}</span>);
    });
  };
  while ((m = linkRe.exec(text))) {
    if (m.index > last) pushBold(text.slice(last, m.index), `${keyBase}-${i++}`);
    nodes.push(
      <a key={`${keyBase}-l${i++}`} href={m[2]} className="underline decoration-[var(--border)] underline-offset-2 hover:text-[var(--fg)]">
        {m[1]}
      </a>
    );
    last = m.index + m[0].length;
  }
  if (last < text.length) pushBold(text.slice(last), `${keyBase}-${i++}`);
  return nodes;
}

function render(md: string): React.ReactNode[] {
  const out: React.ReactNode[] = [];
  const lines = md.replace(/\r/g, "").split("\n");
  let list: string[] = [];
  const flush = (k: string) => {
    if (!list.length) return;
    out.push(
      <ul key={`ul-${k}`} className="my-3 list-disc space-y-1.5 pl-5 muted">
        {list.map((li, j) => <li key={j}>{inline(li, `li-${k}-${j}`)}</li>)}
      </ul>
    );
    list = [];
  };
  lines.forEach((raw, idx) => {
    const line = raw.trimEnd();
    if (line.startsWith("- ")) { list.push(line.slice(2)); return; }
    flush(String(idx));
    if (!line.trim()) return;
    if (line.startsWith("### ")) out.push(<h3 key={idx} className="mt-7 text-lg font-semibold">{inline(line.slice(4), `h3-${idx}`)}</h3>);
    else if (line.startsWith("## ")) out.push(<h2 key={idx} className="mt-10 text-xl font-semibold tracking-tight">{inline(line.slice(3), `h2-${idx}`)}</h2>);
    else if (line.startsWith("# ")) out.push(<h1 key={idx} className="text-3xl font-semibold tracking-tight">{inline(line.slice(2), `h1-${idx}`)}</h1>);
    else out.push(<p key={idx} className="mt-3 leading-relaxed muted">{inline(line, `p-${idx}`)}</p>);
  });
  flush("end");
  return out;
}

export default function LegalDoc({ title, md }: { title: string; md: string }) {
  return (
    <main className="mx-auto max-w-3xl px-6 pb-24">
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="inline-flex h-7 w-7 items-center justify-center rounded-[8px] bg-black ring-1 ring-[var(--border)]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" /><path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" /></svg>
          </span>
          <span className="text-[17px] font-semibold tracking-tight">Verba</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
        </div>
      </nav>
      <article className="py-8">
        <h1 className="text-4xl font-semibold tracking-tight">{title}</h1>
        <div className="mt-6">{render(md)}</div>
      </article>
    </main>
  );
}
