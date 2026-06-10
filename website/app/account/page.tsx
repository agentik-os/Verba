"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { SignedIn, SignedOut, SignInButton, UserButton, useUser } from "@clerk/nextjs";
import ThemeToggle from "@/components/ThemeToggle";

export default function Account() {
  return (
    <main className="mx-auto flex min-h-[82vh] max-w-md flex-col justify-center px-6 py-16">
      <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Verba</Link>
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

type PlanState = "loading" | "error" | "free" | "pro";

function Panel() {
  const { user } = useUser();
  const [plan, setPlan] = useState<PlanState>("loading");
  const [manageError, setManageError] = useState("");

  function loadPlan() {
    setPlan("loading");
    fetch("/api/me")
      .then((r) => { if (!r.ok) throw new Error("bad status"); return r.json(); })
      .then((d) => setPlan(d.plan === "pro" ? "pro" : "free"))
      .catch(() => setPlan("error"));
  }

  useEffect(loadPlan, []);

  async function manage() {
    setManageError("");
    try {
      const res = await fetch("/api/portal", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: user?.primaryEmailAddress?.emailAddress }),
      });
      const data = await res.json();
      if (data.url) window.location.href = data.url;
      else setManageError(data.error ?? "We couldn't open the billing portal. Please try again.");
    } catch {
      setManageError("We couldn't open the billing portal. Please try again.");
    }
  }

  const planLabel = plan === "pro" ? "Pro" : plan === "free" ? "Free" : plan === "error" ? "Unavailable" : "…";

  return (
    <div className="mt-8 space-y-4">
      <div className="glass-strong rounded-2xl p-6">
        <p className="text-sm muted">Signed in as</p>
        <p className="mt-1 font-medium">{user?.primaryEmailAddress?.emailAddress}</p>
        <div className="mt-4 flex items-center gap-2">
          <span className="text-sm muted">Plan</span>
          <span className={`rounded-full px-2.5 py-1 text-xs ${plan === "pro" ? "bg-[var(--fg)] text-[var(--bg)]" : "bg-[var(--tint)]"}`}>
            {planLabel}
          </span>
        </div>
        {plan === "error" ? (
          <div className="mt-5 space-y-2">
            <p className="text-sm muted">Unable to load your plan right now.</p>
            <button onClick={loadPlan} className="w-full rounded-xl glass px-6 py-3 font-medium hover:bg-[var(--tint-strong)]">
              Retry
            </button>
          </div>
        ) : plan === "pro" ? (
          <>
            <button onClick={manage} className="mt-5 w-full rounded-xl glass px-6 py-3 font-medium hover:bg-[var(--tint-strong)]">
              Manage subscription
            </button>
            {manageError && (
              <p role="alert" className="mt-3 rounded-lg border border-[#ff5f57]/30 bg-[#ff5f57]/10 px-3 py-2 text-xs text-[#ff8a84]">
                {manageError}
              </p>
            )}
          </>
        ) : plan === "free" ? (
          <a href="/#pricing" className="mt-5 block w-full rounded-xl bg-[var(--fg)] px-6 py-3 text-center font-medium text-[var(--bg)]">
            Upgrade to Pro
          </a>
        ) : (
          <div className="mt-5 h-12 w-full animate-pulse rounded-xl bg-[var(--tint)]" />
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
