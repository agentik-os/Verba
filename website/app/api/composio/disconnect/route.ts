import { NextRequest, NextResponse } from "next/server";
import { cors, credentialConfigName, getComposio, notConfigured, requireUid } from "../_lib";

export const runtime = "nodejs";
// One list plus N serial deletes; a user with several accounts on one toolkit exceeds the platform
// default.
export const maxDuration = 60;

// POST { toolkit } -> delete the user's connected account(s) for that toolkit. { ok: true }
export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function POST(req: NextRequest) {
  const auth = requireUid(req.headers.get("authorization"));
  if ("error" in auth) return auth.error;

  const composio = getComposio();
  if (!composio) return notConfigured();

  let toolkit = "";
  try {
    toolkit = String((await req.json())?.toolkit ?? "").toUpperCase();
  } catch {
    return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });
  }
  if (!toolkit) return NextResponse.json({ error: "Missing toolkit." }, { status: 400, headers: cors });

  try {
    const list = await composio.connectedAccounts.list({ userIds: [auth.uid] });
    const mine = (list.items ?? []).filter((item) => {
      const tk = (item as unknown as { toolkit?: { slug?: string } | string }).toolkit;
      const slug = (typeof tk === "string" ? tk : tk?.slug ?? "").toUpperCase();
      return slug === toolkit;
    });
    // Count what actually SUCCEEDED. This used to swallow every delete error and still answer
    // { ok: true, removed: <attempted> }, so a disconnect that Composio refused was reported as
    // done: the card cleared optimistically, the next /connections refresh brought the still-ACTIVE
    // account back, and the user was never told anything had failed.
    let removed = 0;
    let failed = 0;
    for (const acct of mine) {
      try {
        await composio.connectedAccounts.delete(acct.id);
        removed++;
      } catch {
        failed++;
      }
    }

    // Delete this user's CREDENTIAL auth config for the toolkit too. It holds their API key, and
    // nothing else in the codebase could ever remove it — disconnecting used to leave the secret
    // live on Composio indefinitely. Shared OAuth configs are deliberately untouched: they carry
    // the developer's client credentials and serve every other user.
    let keyRemoved = false;
    try {
      const name = credentialConfigName(toolkit, auth.uid);
      const configs = await composio.authConfigs.list({ toolkit: toolkit.toLowerCase() });
      for (const cfg of configs.items ?? []) {
        if (cfg.name !== name) continue;
        try {
          await composio.authConfigs.delete(cfg.id);
          keyRemoved = true;
        } catch {
          /* reported via ok:false below only if an account delete also failed */
        }
      }
    } catch {
      /* best-effort: the connection itself is already gone */
    }

    return NextResponse.json(
      {
        ok: failed === 0,
        removed,
        failed,
        credentialsRemoved: keyRemoved,
        ...(failed ? { error: `Couldn't disconnect ${failed} ${toolkit} account(s). Try again.` } : {}),
      },
      { status: failed ? 502 : 200, headers: cors }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Failed to disconnect.";
    return NextResponse.json({ error: msg }, { status: 502, headers: cors });
  }
}
