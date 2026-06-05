"use client";

import { useEffect, useState } from "react";
import { SignIn, useUser } from "@clerk/nextjs";

/// Sign-in surface opened by the macOS app inside a secure web window.
/// Once authenticated (Google / email via Clerk), it links any referral and hands the
/// verified email back to the app through the verba:// callback scheme.
export default function AppAuth() {
  const { isSignedIn, user, isLoaded } = useUser();
  const [msg, setMsg] = useState("Finishing sign-in…");

  useEffect(() => {
    if (!isLoaded || !isSignedIn || !user) return;
    const email = user.primaryEmailAddress?.emailAddress ?? "";
    let ref: string | null = null;
    try { ref = localStorage.getItem("verba_ref"); } catch {}

    const handBack = (code?: string) => {
      setMsg("Done! Returning to Verba…");
      const q = new URLSearchParams({ email });
      if (code) q.set("code", code);
      window.location.href = `verba://auth?${q.toString()}`;
    };

    // Always set up referral state (ensures the account has its own code), then return.
    fetch("/api/link-referral", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ref: ref ?? "" }),
    })
      .then((r) => r.json())
      .then((d) => handBack(d?.referralCode))
      .catch(() => handBack());
  }, [isLoaded, isSignedIn, user]);

  return (
    <main className="grid min-h-screen place-items-center px-6">
      <div className="aurora" />
      {isSignedIn ? (
        <div className="glass-strong rounded-2xl px-8 py-6 text-center">
          <p className="text-lg font-medium">{msg}</p>
          <p className="mt-2 text-sm muted">You can close this window if it doesn't return automatically.</p>
        </div>
      ) : (
        <div className="text-center">
          <h1 className="mb-6 text-2xl font-semibold tracking-tight">Sign in to Verba</h1>
          <SignIn
            routing="hash"
            appearance={{ variables: { colorPrimary: "#ffffff", colorBackground: "#0b0b0f", borderRadius: "0.8rem" } }}
          />
        </div>
      )}
    </main>
  );
}
