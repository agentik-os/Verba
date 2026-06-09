import { ImageResponse } from "next/og";

export const alt = "Verba, speak it, send it clean";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          justifyContent: "center",
          padding: "80px",
          background: "linear-gradient(135deg, #0b0b0f 0%, #15151c 100%)",
          color: "#f4f5f8",
          fontFamily: "sans-serif",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "20px",
            marginBottom: "36px",
          }}
        >
          <div
            style={{
              width: "72px",
              height: "72px",
              borderRadius: "20px",
              background: "#ffffff",
              color: "#0b0b0f",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: "44px",
              fontWeight: 700,
            }}
          >
            V
          </div>
          <div style={{ fontSize: "44px", fontWeight: 600 }}>Verba</div>
        </div>
        <div
          style={{
            fontSize: "72px",
            fontWeight: 700,
            lineHeight: 1.1,
            maxWidth: "900px",
          }}
        >
          Speak it, send it clean.
        </div>
        <div
          style={{
            marginTop: "28px",
            fontSize: "32px",
            color: "rgba(244,245,248,0.62)",
            maxWidth: "880px",
          }}
        >
          Dictation for your Mac that writes clean, well-structured text in any
          app.
        </div>
      </div>
    ),
    { ...size }
  );
}
