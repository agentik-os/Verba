import Link from "next/link";
import { Logo, CrossRule } from "@/components/Brand";

const DOWNLOAD_URL = "https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg";

// Shared footer used on every page. `whitespace-nowrap` on each link keeps every item on a single
// line (no two-line wraps like "Best Mac dictation / app").
export default function SiteFooter() {
  return (
    <>
      <CrossRule />
      <footer className="pb-10 pt-16 text-sm">
        <div className="grid gap-12 lg:grid-cols-[1.2fr_1fr]">
          <div>
            <Logo />
            <p className="t-anchor mt-8 max-w-md text-[var(--faint)]">Speak it.<br />Send it clean.</p>
          </div>
          <div className="grid grid-cols-2 gap-8 sm:grid-cols-3">
            <div>
              <p className="mono-meta mb-4">Product</p>
              <ul className="space-y-2.5 muted">
                <li><a href={DOWNLOAD_URL} className="link-quiet whitespace-nowrap">Download</a></li>
                <li><Link href="/#pricing" className="link-quiet whitespace-nowrap">Pricing</Link></li>
                <li><Link href="/compare" className="link-quiet whitespace-nowrap">Compare</Link></li>
                <li><Link href="/changelog" className="link-quiet whitespace-nowrap">Changelog</Link></li>
              </ul>
            </div>
            <div>
              <p className="mono-meta mb-4">Resources</p>
              <ul className="space-y-2.5 muted">
                <li><Link href="/features" className="link-quiet whitespace-nowrap">Features</Link></li>
                <li><Link href="/docs" className="link-quiet whitespace-nowrap">Documentation</Link></li>
                <li><Link href="/features/jarvis-voice-agent" className="link-quiet whitespace-nowrap">JARVIS voice agent</Link></li>
                <li><Link href="/features/voice-notes" className="link-quiet whitespace-nowrap">Voice notes</Link></li>
                <li><Link href="/acknowledgements" className="link-quiet whitespace-nowrap">Acknowledgements</Link></li>
              </ul>
            </div>
            <div>
              <p className="mono-meta mb-4">Company</p>
              <ul className="space-y-2.5 muted">
                <li><Link href="/account" className="link-quiet whitespace-nowrap">Account</Link></li>
                <li><a href="https://discord.gg/7xfkfQN9AR" target="_blank" rel="noopener" className="link-quiet whitespace-nowrap">Community (Discord)</a></li>
                <li><Link href="/best-mac-dictation-app" className="link-quiet whitespace-nowrap">Best Mac dictation app</Link></li>
                <li><Link href="/privacy" className="link-quiet whitespace-nowrap">Privacy</Link></li>
                <li><Link href="/terms" className="link-quiet whitespace-nowrap">Terms</Link></li>
                <li><Link href="/contact" className="link-quiet whitespace-nowrap">Contact</Link></li>
              </ul>
            </div>
          </div>
        </div>
        <div className="mt-14 flex flex-wrap items-center justify-between gap-4 border-t hairline pt-6">
          <span className="mono-meta flex items-center gap-2">
            <span className="inline-block h-1.5 w-1.5 rounded-full bg-[#6ee7a8]" />
            All systems operational
          </span>
          <span className="mono-meta">© 2026 Verba · Runs on-device with open models</span>
        </div>
      </footer>
    </>
  );
}
