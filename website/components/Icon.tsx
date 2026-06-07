import type { ReactNode } from "react";

/**
 * Minimal monochrome line icons (currentColor), used in place of the old emoji
 * decorations so the site stays on-brand black & white.
 */
const PATHS: Record<string, ReactNode> = {
  key: (
    <>
      <circle cx="7.5" cy="15.5" r="4.3" />
      <path d="M10.8 12.2 21 2" />
      <path d="m15.5 5.5 3 3" />
    </>
  ),
  bolt: <path d="M13 2 4 13.5h6l-1 8.5 9-11.5h-6z" />,
  mail: (
    <>
      <rect x="3" y="5" width="18" height="14" rx="2.2" />
      <path d="m3.5 7 8.5 6 8.5-6" />
    </>
  ),
  doc: (
    <>
      <path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z" />
      <path d="M14 3v5h5" />
      <path d="M9 13h6M9 17h4" />
    </>
  ),
  image: (
    <>
      <rect x="3" y="3" width="18" height="18" rx="2.2" />
      <circle cx="8.8" cy="8.8" r="1.6" />
      <path d="m21 15-5-5L5 21" />
    </>
  ),
  question: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.3 9a2.8 2.8 0 0 1 5.4 1c0 1.9-2.7 2.3-2.7 3.7" />
      <circle cx="12" cy="17.2" r="0.6" fill="currentColor" stroke="none" />
    </>
  ),
  calendar: (
    <>
      <rect x="3" y="4.5" width="18" height="16" rx="2.2" />
      <path d="M3 9.2h18M8 2.5v4M16 2.5v4" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8.5a6 6 0 1 0-12 0c0 6.5-2.5 8.5-2.5 8.5h17S18 15 18 8.5" />
      <path d="M10.3 20.5a2 2 0 0 0 3.4 0" />
    </>
  ),
  pen: (
    <>
      <path d="M12 20h9" />
      <path d="M16.4 3.4a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z" />
    </>
  ),
  note: (
    <>
      <path d="M15 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <path d="M15 3v5h5" />
    </>
  ),
  outline: (
    <>
      <path d="M8.5 6H21M8.5 12H21M8.5 18H21" />
      <circle cx="3.6" cy="6" r="0.7" fill="currentColor" stroke="none" />
      <circle cx="3.6" cy="12" r="0.7" fill="currentColor" stroke="none" />
      <circle cx="3.6" cy="18" r="0.7" fill="currentColor" stroke="none" />
    </>
  ),
  journal: (
    <>
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </>
  ),
  ticket: (
    <>
      <path d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2 2 2 0 0 0 0 4 2 2 0 0 1-2 2H5a2 2 0 0 1-2-2 2 2 0 0 0 0-4z" />
      <path d="M13 7.5v9" strokeDasharray="2 2.4" />
    </>
  ),
  check: (
    <>
      <path d="M9 11.5l2.5 2.5L21 4.5" />
      <path d="M20.5 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
    </>
  ),
  article: (
    <>
      <path d="M4 22a2 2 0 0 1-2-2V5a1 1 0 0 1 1-1h13a1 1 0 0 1 1 1v15a2 2 0 0 1-2 2z" />
      <path d="M18 8h2a1 1 0 0 1 1 1v9a3 3 0 0 1-3 3" />
      <path d="M6 8h7M6 12h7M6 16h4" />
    </>
  ),
};

export default function Icon({ name, className = "h-6 w-6" }: { name: string; className?: string }) {
  const children = PATHS[name];
  if (!children) return null;
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth={1.6}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      {children}
    </svg>
  );
}
