"use client";

import Link from "next/link";
import { useMemo, useRef, useState } from "react";

interface Entry {
  slug: string;
  title: string;
  folder: string;
}

// Case- and diacritic-insensitive normalization for matching French titles.
function norm(s: string): string {
  return s
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();
}

export default function AtelierSearch({ index }: { index: Entry[] }) {
  const [q, setQ] = useState("");
  const [open, setOpen] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);

  const results = useMemo(() => {
    const needle = norm(q.trim());
    if (needle.length < 2) return [];
    return index
      .filter((e) => norm(e.title).includes(needle) || norm(e.slug).includes(needle))
      .slice(0, 20);
  }, [q, index]);

  return (
    <div
      className="atelier-search"
      ref={boxRef}
      onBlur={(e) => {
        if (!boxRef.current?.contains(e.relatedTarget as Node)) setOpen(false);
      }}
    >
      <input
        type="search"
        placeholder="Rechercher…"
        value={q}
        onChange={(e) => {
          setQ(e.target.value);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        aria-label="Rechercher dans l'atelier"
      />
      {open && q.trim().length >= 2 && (
        <div className="atelier-search-results">
          {results.length === 0 ? (
            <div className="atelier-search-empty">Aucun résultat</div>
          ) : (
            results.map((r) => (
              <Link
                key={r.slug}
                href={r.slug ? `/atelier/${r.slug}` : "/atelier"}
                onClick={() => {
                  setOpen(false);
                  setQ("");
                }}
              >
                <span className="r-title">{r.title}</span>
                <span className="r-path">/atelier{r.slug ? `/${r.slug}` : ""}</span>
              </Link>
            ))
          )}
        </div>
      )}
    </div>
  );
}
