"use client";

import { useEffect, useState } from "react";
import { SignIn, useUser } from "@clerk/nextjs";

/// Sign-in surface opened by the macOS app inside a secure web window.
/// Once authenticated (Google / email via Clerk), it links any referral and hands the
/// verified email back to the app through the verba:// callback scheme.
export default function AppAuth() {
  const { isSignedIn, user, isLoaded } = useUser();
  const [msg, setMsg] = useState("Finishing sign-in…");
  const [dark, setDark] = useState(true);

  useEffect(() => {
    const t = document.documentElement.getAttribute("data-theme");
    setDark(t === "dark" || (t === null && window.matchMedia("(prefers-color-scheme: dark)").matches));
  }, []);

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
        <SignIn
          routing="hash"
          appearance={{
            variables: {
              colorPrimary: dark ? "#ffffff" : "#0b0b0f",
              colorBackground: "transparent",
              colorText: dark ? "#f4f5f8" : "#0b0b0f",
              colorTextSecondary: dark ? "rgba(244,245,248,0.6)" : "rgba(11,11,15,0.6)",
              colorInputBackground: dark ? "#ffffff" : "#ffffff",
              colorInputText: "#0b0b0f",
              colorTextOnPrimaryBackground: dark ? "#0b0b0f" : "#ffffff",
              borderRadius: "0.85rem",
              fontSize: "1rem",
              spacingUnit: "1.15rem",
            },
            elements: {
              rootBox: "w-[360px] max-w-full",
              card: "bg-[var(--tint)] backdrop-blur-xl border border-[var(--border)] shadow-2xl rounded-3xl px-7 py-8",
              headerTitle: "text-xl font-semibold",
              headerSubtitle: "text-[var(--muted)]",
              socialButtonsBlockButton:
                "min-h-[52px] text-base bg-[var(--tint)] border border-[var(--border)] hover:bg-[var(--tint-strong)] rounded-2xl",
              socialButtonsBlockButtonText: "font-medium",
              dividerLine: "bg-[var(--border)]",
              dividerText: "text-[var(--muted)]",
              formFieldLabel: "text-[var(--muted)]",
              formFieldInput: "min-h-[52px] text-base rounded-2xl px-4 !text-black",
              formButtonPrimary:
                "min-h-[52px] text-base bg-[var(--fg)] text-[var(--bg)] hover:opacity-90 rounded-2xl font-semibold",
              footerActionLink: "text-[var(--fg)] font-medium",
              footer: "text-[var(--muted)]",
            },
          }}
        />
      )}
    </main>
  );
}
