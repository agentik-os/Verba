import type { MetadataRoute } from "next";

// PWA/manifest: gives search engines the canonical name/icon/theme bundle and makes the site
// installable. Icons reuse the existing /icon.png.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Verba — AI Dictation for Mac",
    short_name: "Verba",
    description:
      "On-device AI dictation for Mac: voice-to-text, AI cleanup in any app, live translation, and a voice agent for 1,000+ apps.",
    start_url: "/",
    display: "standalone",
    background_color: "#0b0b0e",
    theme_color: "#0b0b0e",
    icons: [{ src: "/icon.png", sizes: "512x512", type: "image/png" }],
  };
}
