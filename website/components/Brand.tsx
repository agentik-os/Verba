import type { ReactNode } from "react";

/* The Verba mic glyph — the single brand mark, reused everywhere. */
export function MicGlyph({ size = 14, className = "" }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden>
      <path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" />
      <path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" />
    </svg>
  );
}

/* The black rounded-square mic mark — the recurring signature motif. */
export function MicMark({ size = 28, glyph, className = "" }: { size?: number; glyph?: number; className?: string }) {
  return (
    <span
      className={`mic-mark ${className}`}
      style={{ width: size, height: size, borderRadius: Math.round(size * 0.26) }}
    >
      <MicGlyph size={glyph ?? Math.round(size * 0.5)} />
    </span>
  );
}

export function Logo({ size = 28 }: { size?: number }) {
  return (
    <div className="flex items-center gap-2.5">
      <MicMark size={size} />
      <span className="text-[17px] font-semibold tracking-tight">Verba</span>
    </div>
  );
}

/* A section divider built from the mic motif. */
export function MotifRule({ label }: { label?: string }) {
  return (
    <div className="motif-rule mx-auto my-2 max-w-xs">
      {label ? <span className="eyebrow whitespace-nowrap">{label}</span> : <MicMark size={18} glyph={10} />}
    </div>
  );
}

/* Left-aligned section header — used to break the centered-stack loop. */
export function HeadLeft({
  eyebrow,
  title,
  lead,
  anchor = false,
  children,
}: {
  eyebrow?: string;
  title: ReactNode;
  lead?: ReactNode;
  anchor?: boolean;
  children?: ReactNode;
}) {
  return (
    <div className="max-w-2xl">
      {eyebrow && (
        <div className="mb-4 flex items-center gap-2.5">
          <span className="rec-dot" />
          <span className="eyebrow">{eyebrow}</span>
        </div>
      )}
      <h2 className={anchor ? "t-anchor" : "t-section"}>{title}</h2>
      {lead && <p className="t-lead mt-5">{lead}</p>}
      {children}
    </div>
  );
}

/* Centered section header — reserved for the few moments that earn it. */
export function HeadCenter({
  eyebrow,
  title,
  lead,
  anchor = false,
}: {
  eyebrow?: string;
  title: ReactNode;
  lead?: ReactNode;
  anchor?: boolean;
}) {
  return (
    <div className="mx-auto max-w-2xl text-center">
      {eyebrow && (
        <div className="mb-4 flex items-center justify-center gap-2.5">
          <span className="rec-dot" />
          <span className="eyebrow">{eyebrow}</span>
        </div>
      )}
      <h2 className={`${anchor ? "t-anchor" : "t-section"} text-balance`}>{title}</h2>
      {lead && <p className="t-lead mx-auto mt-5 text-balance">{lead}</p>}
    </div>
  );
}
