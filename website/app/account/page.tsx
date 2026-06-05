"use client";

import { useEffect, useState } from "react";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";

export default function Account() {
  return (
    <main className="mx-auto max-w-md px-6 py-20">
      <a href="/" className="text-sm muted hover:text-white">← Verba</a>
      <div className="mt-6 flex items-center justify-between">
        <h1 className="text-3xl font-semibold tracking-tight">Account</h1>
        <SignedIn><UserButton afterSignOutUrl="/" /></SignedIn>
      </div>

      <SignedOut>
        <div className="mt-8 glass-strong rounded-2xl p-6 text-center">
          <p className="muted">Sign in to manage your subscription and sync your dictations.</p>
          <SignInButton mode="modal">
            <button className="mt-5 w-full rounded-xl bg-white px-6 py-3 font-medium text-black">Sign in</button>
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
          <span className={`rounded-full px-2.5 py-1 text-xs ${plan === "pro" ? "bg-white text-black" : "bg-white/10"}`}>
            {plan === null ? "…" : plan === "pro" ? "Pro" : "Free"}
          </span>
        </div>
        {plan === "pro" ? (
          <button onClick={manage} className="mt-5 w-full rounded-xl glass px-6 py-3 font-medium hover:bg-white/10">
            Manage subscription
          </button>
        ) : (
          <a href="/#pricing" className="mt-5 block w-full rounded-xl bg-white px-6 py-3 text-center font-medium text-black">
            Upgrade to Pro
          </a>
        )}
      </div>
      <a
        href="https://github.com/agentik-os/Verba/releases/latest/download/Verba.dmg"
        className="block glass rounded-2xl p-5 text-center font-medium hover:bg-white/10"
      >
        Download Verba for macOS
      </a>
    </div>
  );
}
