"use client";

import { useEffect, useState } from "react";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";
import ThemeToggle from "@/components/ThemeToggle";

export default function Account() {
  return (
    <main className="mx-auto flex min-h-[82vh] max-w-md flex-col justify-center px-6 py-16">
      <a href="/" className="text-sm muted hover:text-[var(--fg)]">← Verba</a>
      <div className="mt-6 flex items-center justify-between">
        <h1 className="text-3xl font-semibold tracking-tight">Account</h1>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <SignedIn><UserButton afterSignOutUrl="/" /></SignedIn>
        </div>
      </div>

      <SignedOut>
        <div className="mt-8 glass-strong rounded-2xl p-6 text-center">
          <p className="muted">Sign in to manage your subscription and sync your dictations.</p>
          <SignInButton mode="modal">
            <button className="mt-5 w-full rounded-xl bg-[var(--fg)] px-6 py-3 font-medium text-[var(--bg)]">Sign in</button>
          </SignInButton>
        </div>
      </SignedOut>

      <SignedIn><Panel /></SignedIn>
    </main>
  );
}

function Panel() {
  const { user } = useUser();
  const [plan, setPlan] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/me").then((r) => r.json()).then((d) => setPlan(d.plan ?? "free")).catch(() => setPlan("free"));
  }, []);

  async function manage() {
    const res = await fetch("/api/portal", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: user?.primaryEmailAddress?.emailAddress }),
    });
    const data = await res.json();
    if (data.url) window.location.href = data.url;
    else alert(data.error ?? "No subscription found.");
  }

  return (
    <div className="mt-8 space-y-4">
      <div className="glass-strong rounded-2xl p-6">
        <p className="text-sm muted">Signed in as</p>
        <p className="mt-1 font-medium">{user?.primaryEmailAddress?.emailAddress}</p>
        <div className="mt-4 flex items-center gap-2">
          <span className="text-sm muted">Plan</span>
          <span className={`rounded-full px-2.5 py-1 text-xs ${plan === "pro" ? "bg-[var(--fg)] text-[var(--bg)]" : "bg-[var(--tint)]"}`}>
            {plan === null ? "…" : plan === "pro" ? "Pro" : "Free"}
          </span>
        </div>
        {plan === "pro" ? (
          <button onClick={manage} className="mt-5 w-full rounded-xl glass px-6 py-3 font-medium hover:bg-[var(--tint-strong)]">
            Manage subscription
          </button>
        ) : (
          <a href="/#pricing" className="mt-5 block w-full rounded-xl bg-[var(--fg)] px-6 py-3 text-center font-medium text-[var(--bg)]">
            Upgrade to Pro
          </a>
        )}
      </div>
      <a
        href="https://github.com/agentik-os/Verba-releases/releases/latest/download/Verba.dmg"
        className="block glass rounded-2xl p-5 text-center font-medium hover:bg-[var(--tint-strong)]"
      >
        Download Verba for macOS
      </a>
    </div>
  );
}
