import { notFound } from "next/navigation";
import Link from "next/link";
import { allSlugs, buildAtelier, getDoc, getFolder } from "@/lib/atelier";

export const dynamic = "force-static";
export const dynamicParams = false;

export function generateStaticParams(): { slug: string[] }[] {
  // Root index → empty slug array; every folder + every doc otherwise.
  return allSlugs().map((s) => ({ slug: s ? s.split("/") : [] }));
}

function slugHref(slug: string): string {
  return slug ? `/atelier/${slug}` : "/atelier";
}

export default async function AtelierPage({
  params,
}: {
  params: Promise<{ slug?: string[] }>;
}) {
  const { slug: segments } = await params;
  const slug = (segments ?? []).join("/");
  const model = buildAtelier();

  // A folder slug takes precedence (its README, if any, is the folder's index page).
  if (model.foldersBySlug.has(slug)) {
    const res = getFolder(slug);
    if (!res) notFound();
    const { folder, readmeHtml } = res;
    const hasChildren = folder.folders.length > 0 || folder.docs.length > 0;
    return (
      <article>
        {readmeHtml ? (
          <div dangerouslySetInnerHTML={{ __html: readmeHtml }} />
        ) : (
          <h1>{folder.name === "Atelier" ? "Atelier" : folder.name}</h1>
        )}
        {hasChildren && (
          <>
            <h2 className="atelier-children-heading">Dans ce dossier</h2>
            <ul className="atelier-listing">
              {folder.folders.map((f) => (
                <li key={f.slug}>
                  <Link href={slugHref(f.slug)}>📁 {f.readme ? f.readme.title : f.name}</Link>
                </li>
              ))}
              {folder.docs.map((d) => (
                <li key={d.slug}>
                  <Link href={slugHref(d.slug)}>📄 {d.title}</Link>
                </li>
              ))}
            </ul>
          </>
        )}
      </article>
    );
  }

  const doc = getDoc(slug);
  if (!doc) notFound();
  return <article dangerouslySetInnerHTML={{ __html: doc.html }} />;
}
