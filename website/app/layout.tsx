import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { dark } from "@clerk/themes";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";
import RefCapture from "@/components/RefCapture";

// Apply the saved theme before paint to avoid a flash; no choice → follow the machine.
const themeScript = `(function(){try{var t=localStorage.getItem('verba_theme');if(t==='light'||t==='dark'){document.documentElement.setAttribute('data-theme',t);}}catch(e){}})();`;

export const metadata: Metadata = {
  title: "Verba, speak it, send it clean",
  description:
    "A macOS menu-bar app that turns your speech into clean, well-structured text anywhere on your Mac. Dictate in any app, in your style, hands free.",
  metadataBase: new URL("https://verba.run"),
  openGraph: {
    title: "Verba, speak it, send it clean",
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
      afterSignOutUrl="/"
      appearance={{
        baseTheme: dark,
        variables: {
          colorPrimary: "#ffffff",
          colorBackground: "#101014",
          colorText: "#f4f5f8",
          colorTextSecondary: "rgba(244,245,248,0.62)",
          colorInputBackground: "#ffffff",
          colorInputText: "#0b0b0f",
          colorTextOnPrimaryBackground: "#0b0b0f", // dark text on the white primary button (fixes white-on-white)
          borderRadius: "0.85rem",
          fontSize: "1rem",
          spacingUnit: "1.1rem",
        },
        elements: {
          card: "rounded-3xl px-7 py-8 border border-white/10",
          headerTitle: "text-xl font-semibold !text-white",
          headerSubtitle: "!text-[rgba(244,245,248,0.6)]",
          socialButtonsBlockButton:
            "min-h-[52px] text-base rounded-2xl border border-white/15 hover:bg-white/10 !text-white",
          socialButtonsBlockButtonText: "font-medium !text-white",
          dividerLine: "bg-white/10",
          dividerText: "!text-[rgba(244,245,248,0.5)]",
          formFieldLabel: "!text-[rgba(244,245,248,0.7)]",
          formFieldInput: "min-h-[52px] text-base rounded-2xl px-4 !text-black",
          formButtonPrimary:
            "min-h-[52px] text-base rounded-2xl font-semibold !bg-white !text-black hover:!bg-white/90",
          footerActionText: "!text-[rgba(244,245,248,0.6)]",
          footerActionLink: "!text-white font-medium",
          // Account dropdown (UserButton popover) — on-brand dark, high-contrast text
          userButtonPopoverCard:
            "rounded-2xl border border-white/10 bg-[#101014] shadow-2xl",
          userButtonPopoverMain: "bg-[#101014]",
          userPreviewMainIdentifier: "!text-white font-medium",
          userPreviewSecondaryIdentifier: "!text-[rgba(244,245,248,0.6)]",
          userButtonPopoverActionButton:
            "!text-[rgba(244,245,248,0.85)] hover:bg-white/[0.06] hover:!text-white",
          userButtonPopoverActionButtonText: "!text-inherit",
          userButtonPopoverActionButtonIcon: "!text-[rgba(244,245,248,0.7)]",
          userButtonPopoverFooter: "bg-[#101014] border-t border-white/[0.06]",
        },
      }}
    >
      <html lang="en" suppressHydrationWarning>
        <head><script dangerouslySetInnerHTML={{ __html: themeScript }} /></head>
        <body className="font-sans antialiased">
          <RefCapture />
          {children}
          <Analytics />
        </body>
      </html>
    </ClerkProvider>
  );
}
