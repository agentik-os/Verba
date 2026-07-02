import type { Metadata } from "next";
import { buildAtelier, searchIndex, type AtelierFolder } from "@/lib/atelier";
import AtelierShell, { type TreeFolder } from "./AtelierShell";
import "./atelier.css";

// Confidential internal docs — never indexed.
export const metadata: Metadata = {
  title: "Atelier · Verba (interne)",
  robots: { index: false, follow: false },
};

// Strip fs-only fields (relPath) before crossing the server→client boundary.
function toTree(folder: AtelierFolder): TreeFolder {
  return {
    name: folder.name,
    slug: folder.slug,
    readmeTitle: folder.readme ? folder.readme.title : null,
    folders: folder.folders.map(toTree),
    docs: folder.docs.map((d) => ({ slug: d.slug, title: d.title })),
  };
}

export default function AtelierLayout({ children }: { children: React.ReactNode }) {
  const { tree } = buildAtelier();
  const index = searchIndex();
  return (
    <AtelierShell tree={toTree(tree)} index={index}>
      {children}
    </AtelierShell>
  );
}
