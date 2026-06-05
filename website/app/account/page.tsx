"use client";

import { useState } from "react";

type Ent = { active: boolean; plan: string; currentPeriodEnd?: number };

export default function Account() {
  const [email, setEmail] = useState("");
  const [ent, setEnt] = useState<Ent | null>(null);
  const [loading, setLoading] = useState(false);

  async function check() {
    setLoading(true);
    try {
      const res = await fetch(`/api/entitlement?email=${encodeURIComponent(email)}`);
      setEnt(await res.json());
    } finally {
      setLoading(false);
    }
  }

  async function manage() {
    const res = await fetch("/api/portal", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email }),
    });
    const data = await res.json();
    if (data.url) window.location.href = data.url;
    else alert(data.error ?? "No subscription found for that email.");
  }

  return (
    <main className="mx-auto max-w-md px-6 py-24">
      <a href="/" className="text-sm text-white/50 hover:text-white">← Verba</a>
      <h1 className="mt-6 text-3xl font-bold">Your subscription</h1>
      <p className="mt-2 text-white/60">Enter the email you used at checkout.</p>

      <div className="mt-6 glass-strong rounded-2xl p-6">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@email.com"
          className="w-full rounded-xl bg-black/30 px-4 py-3 outline-none ring-1 ring-white/10 focus:ring-white/30"
        />
        <button
          onClick={check}
          disabled={loading || !email}
          className="mt-3 w-full rounded-xl bg-white px-6 py-3 font-semibold text-black hover:bg-white/90 disabled:opacity-60"
        >
          {loading ? "Checking…" : "Check status"}
        </button>

        {ent && (
          <div className="mt-5 rounded-xl bg-black/20 p-4 text-sm">
            {ent.active ? (
              <>
                <p className="font-semibold text-teal-brand">Active — {ent.plan}</p>
                {ent.currentPeriodEnd && (
                  <p className="mt-1 text-white/60">
                    Renews {new Date(ent.currentPeriodEnd * 1000).toLocaleDateString()}
                  </p>
                )}
                <button onClick={manage} className="mt-3 w-full rounded-xl glass px-4 py-2 hover:bg-white/10">
                  Manage subscription
                </button>
              </>
            ) : (
              <>
                <p className="text-white/70">No active Verba subscription for this email.</p>
                <a href="/#pricing" className="mt-3 block w-full rounded-xl bg-white px-4 py-2 text-center font-semibold text-black">
                  Start free trial
                </a>
              </>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
