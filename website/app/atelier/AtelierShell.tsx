"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState, type ReactNode } from "react";
import AtelierSearch from "./AtelierSearch";

// Lean, serializable mirror of lib/atelier's AtelierFolder (no fs relPaths sent to the client).
export interface TreeDoc {
  slug: string;
  title: string;
}
export interface TreeFolder {
  name: string;
  slug: string;
  readmeTitle: string | null;
  folders: TreeFolder[];
  docs: TreeDoc[];
}
export interface SearchEntry {
  slug: string;
  title: string;
  folder: string;
}

function slugHref(slug: string): string {
  return slug ? `/atelier/${slug}` : "/atelier";
}

function isActive(pathname: string, slug: string): boolean {
  return pathname === slugHref(slug);
}

function isAncestor(pathname: string, slug: string): boolean {
  const base = slugHref(slug);
  return pathname === base || pathname.startsWith(base + "/");
}

function FolderNode({ folder, pathname }: { folder: TreeFolder; pathname: string }) {
  const label = folder.readmeTitle || folder.name;
  return (
    <li>
      <details open={isAncestor(pathname, folder.slug)}>
        <summary>
          <Link
            href={slugHref(folder.slug)}
            className={isActive(pathname, folder.slug) ? "active" : undefined}
            onClick={(e) => e.stopPropagation()}
          >
            {label}
          </Link>
        </summary>
        <ul>
          {folder.folders.map((f) => (
            <FolderNode key={f.slug} folder={f} pathname={pathname} />
          ))}
          {folder.docs.map((d) => (
            <li key={d.slug}>
              <Link href={slugHref(d.slug)} className={isActive(pathname, d.slug) ? "active" : undefined}>
                {d.title}
              </Link>
            </li>
          ))}
        </ul>
      </details>
    </li>
  );
}

function Breadcrumb({ index, pathname }: { index: SearchEntry[]; pathname: string }) {
  const titleBySlug = new Map(index.map((e) => [e.slug, e.title]));
  const rest = pathname.replace(/^\/atelier\/?/, "");
  const segments = rest ? rest.split("/") : [];
  const crumbs: { label: string; href: string; current: boolean }[] = [
    { label: "Atelier", href: "/atelier", current: segments.length === 0 },
  ];
  let acc = "";
  segments.forEach((seg, i) => {
    acc = acc ? `${acc}/${seg}` : seg;
    crumbs.push({
      label: titleBySlug.get(acc) || seg,
      href: `/atelier/${acc}`,
      current: i === segments.length - 1,
    });
  });
  return (
    <nav className="atelier-breadcrumb" aria-label="Fil d'Ariane">
      {crumbs.map((c, i) => (
        <span key={c.href} style={{ display: "contents" }}>
          {i > 0 && <span className="sep">/</span>}
          {c.current ? (
            <span className="current">{c.label}</span>
          ) : (
            <Link href={c.href}>{c.label}</Link>
          )}
        </span>
      ))}
    </nav>
  );
}

export default function AtelierShell({
  tree,
  index,
  children,
}: {
  tree: TreeFolder;
  index: SearchEntry[];
  children: ReactNode;
}) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="atelier-root">
      <div className="atelier-shell">
        {menuOpen && <div className="atelier-backdrop" onClick={() => setMenuOpen(false)} />}
        <aside className={`atelier-sidebar${menuOpen ? " open" : ""}`} onClick={() => setMenuOpen(false)}>
          <Link href="/atelier" className="at-brand">
            📓 Atelier
          </Link>
          <ul className="atelier-tree">
            {tree.docs.map((d) => (
              <li key={d.slug}>
                <Link href={slugHref(d.slug)} className={isActive(pathname, d.slug) ? "active" : undefined}>
                  {d.title}
                </Link>
              </li>
            ))}
            {tree.folders.map((f) => (
              <FolderNode key={f.slug} folder={f} pathname={pathname} />
            ))}
          </ul>
        </aside>
        <div className="atelier-main">
          <header className="atelier-topbar">
            <button
              className="atelier-menu-btn"
              onClick={() => setMenuOpen((v) => !v)}
              aria-label="Ouvrir le menu"
            >
              ☰
            </button>
            <Breadcrumb index={index} pathname={pathname} />
            <AtelierSearch index={index} />
          </header>
          <main className="atelier-content atelier-prose">{children}</main>
        </div>
      </div>
    </div>
  );
}
