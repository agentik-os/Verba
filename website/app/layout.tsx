import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";
import RefCapture from "@/components/RefCapture";

export const metadata: Metadata = {
  title: "Verba — speak it, send it clean",
  description:
    "A macOS menu-bar app that turns your speech into clean, well-structured text anywhere on your Mac. Dictate in any app, in your style, hands free.",
  metadataBase: new URL("https://verba.run"),
  openGraph: {
    title: "Verba — speak it, send it clean",
    description:
      "Speak naturally; Verba writes it cleanly into any app on your Mac. Fast, private, hands-free.",
    url: "https://verba.run",
    siteName: "Verba",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider
      appearance={{ variables: { colorPrimary: "#ffffff", colorBackground: "#0b0b0f", borderRadius: "0.8rem" } }}
    >
      <html lang="en">
        <body className="font-sans antialiased"><RefCapture />{children}</body>
      </html>
    </ClerkProvider>
  );
}
