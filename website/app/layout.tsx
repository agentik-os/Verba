import type { Metadata, Viewport } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { dark } from "@clerk/themes";
import { Analytics } from "@vercel/analytics/next";
import Script from "next/script";
import "./globals.css";
import RefCapture from "@/components/RefCapture";

// Apply the saved theme before paint to avoid a flash; no choice → follow the machine.
const themeScript = `(function(){try{var t=localStorage.getItem('verba_theme');if(t==='light'||t==='dark'){document.documentElement.setAttribute('data-theme',t);}}catch(e){}})();`;

export const metadata: Metadata = {
  title: "Verba, the Mac Voice Agent | Private Dictation that Acts",
  // ≤160 chars so Google doesn't truncate it in the SERP.
  description:
    "Verba is the private Mac voice agent: dictate and it acts across 1,000+ apps. On-device voice-to-text, your data stays on your Mac. $9.99/mo.",
  metadataBase: new URL("https://verba.run"),
  alternates: { canonical: "/" },
  // Google Search Console — renders <meta name="google-site-verification" …>. Verifies a URL-prefix
  // property (https://verba.run) without touching DNS (verba.run's DNS is at Hostinger).
  verification: { google: "ea4RLgHnVgZ5IXz7vQEtNDqCOVCRiXxhA7TNJ2F9PMA" },
  keywords: [
    "Mac voice agent", "AI dictation Mac", "voice to text macOS", "dictation app for Mac",
    "Wispr Flow alternative", "speech to text Mac", "on-device dictation", "private dictation app",
    "Jarvis for Mac", "voice to action Mac", "private AI dictation", "secure voice to text Mac",
  ],
  openGraph: {
    title: "Verba, the Mac Voice Agent | Dictation that Acts",
    description:
      "The private Mac voice agent: dictate and it acts across 1,000+ apps. On-device voice-to-text, AI cleanup, live translation. Your data stays on your Mac. $9.99/mo.",
    url: "/",
    siteName: "Verba",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "Verba, the Mac Voice Agent | Dictation that Acts",
    description:
      "The private Mac voice agent, dictation that acts on 1,000+ apps. On-device voice-to-text, your data stays on your Mac.",
  },
};

// Site-wide structured data, Google rich results + LLM/AI-search (GEO) citation eligibility.
const SITE_JSONLD = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      name: "Verba",
      applicationCategory: "UtilitiesApplication",
      operatingSystem: "macOS 14+",
      description:
        "The private Mac voice agent: on-device voice-to-text and AI cleanup in any app, plus JARVIS, which acts on 1,000+ connected apps. Your data stays on your Mac.",
      url: "https://verba.run",
      downloadUrl: "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg",
      softwareVersion: "0.9.29",
      offers: {
        "@type": "Offer",
        price: "9.99",
        priceCurrency: "USD",
        availability: "https://schema.org/InStock",
        priceValidUntil: "2027-12-31",
        url: "https://verba.run",
      },
      creator: { "@type": "Person", name: "Gareth Simono" },
      featureList: [
        "On-device voice-to-text, private by default",
        "AI rewriting in any app", "Live translation", "Reads your screen (Context mode)",
        "JARVIS voice agent acting on 1,000+ connected apps",
        "Choose your own AI engine, your data stays on your Mac", "15 UI languages",
      ],
    },
    {
      // Site entity, helps Google/LLMs treat verba.run as the canonical website node.
      "@type": "WebSite",
      name: "Verba",
      url: "https://verba.run",
      inLanguage: "en",
      publisher: { "@id": "https://verba.run/#org" },
    },
    {
      "@id": "https://verba.run/#org",
      "@type": "Organization",
      name: "Agentik OS",
      url: "https://verba.run",
      logo: "https://verba.run/icon.png",
      founder: { "@type": "Person", name: "Gareth Simono" },
      // Entity disambiguation for the Knowledge Graph + AI search.
      sameAs: [
        "https://github.com/agentik-os",
        "https://www.instagram.com/verba.run/",
        "https://www.tiktok.com/@verba.run",
        "https://www.youtube.com/@VerbaRun",
        "https://x.com/verba_run",
        "https://www.reddit.com/user/VerbaRun/",
        "https://es.pinterest.com/verbarun/",
        "https://t.me/verbarun",
      ],
    },
  ],
};

// Dark brand chrome on mobile browser address bars.
export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#0b0b0e" },
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
  ],
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
          // Account dropdown (UserButton popover), on-brand dark, high-contrast text
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
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(SITE_JSONLD) }}
          />
          <RefCapture />
          {children}
          <Analytics />
          {/* Google tag (gtag.js) — one load, both destinations: GA4 analytics (G-KGTS6B6WWP)
              + Google Ads conversion tracking (AW-18293643888). */}
          <Script src="https://www.googletagmanager.com/gtag/js?id=G-KGTS6B6WWP" strategy="afterInteractive" />
          <Script id="google-gtag" strategy="afterInteractive">
            {`window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-KGTS6B6WWP');
gtag('config', 'AW-18293643888');`}
          </Script>
        </body>
      </html>
    </ClerkProvider>
  );
}
