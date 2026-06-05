import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Verba — talk, and Claude cleans it up",
  description:
    "A macOS menu-bar dictation app. Speak your mind; Verba transcribes you and uses Claude to restructure the mess into a clean prompt or message. Bring your own keys.",
  metadataBase: new URL("https://verba.run"),
  openGraph: {
    title: "Verba — talk, and Claude cleans it up",
    description:
      "macOS menu-bar dictation with AI reprompting. OpenAI or on-device transcription + Claude restructuring. BYOK.",
    url: "https://verba.run",
    siteName: "Verba",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
