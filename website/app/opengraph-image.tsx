import { ImageResponse } from "next/og";

export const alt = "Verba. Speak it. Send it clean.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

// The link preview IS the first impression (WhatsApp, iMessage, X, Slack).
// Mirrors the live site exactly: near-black ground with the quiet top glow,
// the real mic mark, the two-tone hero headline, the single red rec-dot
// accent, and a hairline + mono meta footer.
export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "72px 80px 60px",
          background: "#050507",
          backgroundImage:
            "radial-gradient(900px 380px at 50% -12%, rgba(255,255,255,0.07), transparent 65%)",
          color: "#f4f4f6",
          fontFamily: "sans-serif",
        }}
      >
        {/* Brand row: the real mic mark + wordmark */}
        <div style={{ display: "flex", alignItems: "center", gap: "18px" }}>
          <div
            style={{
              width: "64px",
              height: "64px",
              borderRadius: "16px",
              background: "#0c0c10",
              border: "1px solid rgba(255,255,255,0.18)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <svg width="32" height="32" viewBox="0 0 24 24" fill="#f4f4f6">
              <path d="M12 14a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Z" />
              <path d="M5 11a1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 1 1 2 0 7 7 0 0 1-6 6.93V21a1 1 0 1 1-2 0v-3.07A7 7 0 0 1 5 11Z" />
            </svg>
          </div>
          <div style={{ fontSize: "40px", fontWeight: 600, letterSpacing: "-0.02em" }}>
            Verba
          </div>
        </div>

        {/* The hero headline, two-tone exactly like the site */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div
            style={{
              fontSize: "106px",
              fontWeight: 700,
              lineHeight: 1.02,
              letterSpacing: "-0.035em",
              color: "#f4f4f6",
            }}
          >
            Speak it.
          </div>
          <div
            style={{
              fontSize: "106px",
              fontWeight: 700,
              lineHeight: 1.02,
              letterSpacing: "-0.035em",
              color: "rgba(244,244,246,0.45)",
            }}
          >
            Send it clean.
          </div>
          <div
            style={{
              marginTop: "32px",
              fontSize: "30px",
              color: "rgba(244,244,246,0.62)",
              letterSpacing: "-0.01em",
            }}
          >
            The most complete voice-to-text on the Mac.
          </div>
        </div>

        {/* Footer: hairline + rec dot + quiet mono-style meta */}
        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          <div style={{ height: "1px", background: "rgba(255,255,255,0.10)", display: "flex" }} />
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "14px",
              fontSize: "23px",
              letterSpacing: "0.14em",
              color: "rgba(244,244,246,0.55)",
            }}
          >
            <div
              style={{
                width: "12px",
                height: "12px",
                borderRadius: "50%",
                background: "#ff5a4d",
                display: "flex",
              }}
            />
            VERBA.RUN · FOR MACOS · APPLE SILICON
          </div>
        </div>
      </div>
    ),
    { ...size }
  );
}
