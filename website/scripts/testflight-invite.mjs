#!/usr/bin/env node
// ---------------------------------------------------------------------------
// TestFlight beta-invite helper — the LAST manual/cron step of the iPhone beta
// signup pipeline.
//
// The macOS app POSTs signups to /api/beta-signup, which stores them durably in
// Convex (table `beta_signups`, status "pending"). This script reads the pending
// signups and adds each email to a TestFlight beta group via the App Store Connect
// API, then marks the Convex row invited. Apple emails the tester the invite; they
// accept it from the email. Run it by hand or on a cron once the prerequisites below
// exist.
//
// ⚠️ IT DOES NOTHING WITHOUT ITS ENV VARS. Nothing here runs against a real Apple
// account unless you explicitly provide the issuer ID + beta group ID. As of writing
// those are NOT known, and it is unconfirmed the iOS app even exists in App Store
// Connect yet — so this is intentionally gated and safe to commit.
//
// TO TURN IT ON you need, as env vars:
//   ASC_ISSUER_ID        App Store Connect API issuer ID (UUID).            [REQUIRED — not known yet]
//   ASC_BETA_GROUP_ID    The iOS app's TestFlight beta group id.           [REQUIRED — not known yet]
//   ASC_KEY_ID           API key id.            (default: J9GPQFGN66)
//   ASC_PRIVATE_KEY_PATH Path to the .p8.       (default: ~/.appstoreconnect/private_keys/AuthKey_J9GPQFGN66.p8)
//
// To pull pending signups from Convex + mark them invited (otherwise pass emails as CLI args):
//   ASC_CONVEX_URL       Convex deployment URL. (default: the prod URL below)
//   ADMIN_SECRET         Convex admin secret — reads beta:list.
//   APP_TOKEN_SECRET     Convex server key — calls beta:markInvited.
//
// Find the issuer ID: App Store Connect ▸ Users and Access ▸ Integrations ▸ App Store
//   Connect API ▸ (the "Issuer ID" shown above the key list).
// Find the beta group id: GET https://api.appstoreconnect.apple.com/v1/apps/<appId>/betaGroups
//   with a token from this same key (or ASC ▸ your app ▸ TestFlight ▸ the group).
//
// Usage:
//   node website/scripts/testflight-invite.mjs                 # invite all pending (from Convex)
//   node website/scripts/testflight-invite.mjs a@b.com c@d.com # invite these specific emails
//   node website/scripts/testflight-invite.mjs --dry-run       # print what it WOULD do, no calls
// ---------------------------------------------------------------------------

import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const DEFAULT_CONVEX_URL = "https://prestigious-wolf-290.eu-west-1.convex.cloud";
const ASC_BASE = "https://api.appstoreconnect.apple.com/v1";

const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const emailArgs = args.filter((a) => !a.startsWith("--"));

// --- config from env, with the documented defaults --------------------------
const ISSUER_ID = process.env.ASC_ISSUER_ID;
const BETA_GROUP_ID = process.env.ASC_BETA_GROUP_ID;
const KEY_ID = process.env.ASC_KEY_ID || "J9GPQFGN66";
const KEY_PATH =
  process.env.ASC_PRIVATE_KEY_PATH ||
  path.join(os.homedir(), ".appstoreconnect", "private_keys", `AuthKey_${KEY_ID}.p8`);
const CONVEX_URL = process.env.ASC_CONVEX_URL || DEFAULT_CONVEX_URL;
const ADMIN_SECRET = process.env.ADMIN_SECRET;
const APP_TOKEN_SECRET = process.env.APP_TOKEN_SECRET;

function die(msg) {
  console.error(`✗ ${msg}`);
  process.exit(1);
}

// --- hard gate: refuse to do anything without the two unknowns ---------------
if (!ISSUER_ID || !BETA_GROUP_ID) {
  die(
    "ASC_ISSUER_ID and ASC_BETA_GROUP_ID are required and not set.\n" +
      "  These are the two things we don't have yet (issuer ID + the iOS app's TestFlight beta group id),\n" +
      "  and it's unconfirmed the iOS app exists in App Store Connect. Set them, then re-run.\n" +
      "  See the header of this file for exactly where to find each value."
  );
}

// --- ES256 App Store Connect JWT (no external deps; node:crypto only) --------
function b64url(buf) {
  return Buffer.from(buf).toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function makeJWT() {
  let pem;
  try {
    pem = fs.readFileSync(KEY_PATH, "utf8");
  } catch {
    die(`Can't read the .p8 private key at ${KEY_PATH} (set ASC_PRIVATE_KEY_PATH).`);
  }
  const header = { alg: "ES256", kid: KEY_ID, typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  // ASC caps token lifetime at 20 min; 15 is comfortably inside that.
  const payload = { iss: ISSUER_ID, iat: now, exp: now + 15 * 60, aud: "appstoreconnect-v1" };
  const signingInput = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  // ES256 = ECDSA/P-256/SHA-256 with the signature in JOSE (raw r‖s) form, which
  // `dsaEncoding: "ieee-p1363"` produces (Node's default is DER, which ASC rejects).
  const sig = crypto.sign("sha256", Buffer.from(signingInput), { key: pem, dsaEncoding: "ieee-p1363" });
  return `${signingInput}.${b64url(sig)}`;
}

// --- App Store Connect: add a beta tester to the beta group ------------------
// POST /v1/betaTesters with the email + a relationship to the beta group. Apple then
// emails the tester their TestFlight invite. Docs: "Create a Beta Tester".
async function addTester(jwt, email) {
  const res = await fetch(`${ASC_BASE}/betaTesters`, {
    method: "POST",
    headers: { Authorization: `Bearer ${jwt}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      data: {
        type: "betaTesters",
        attributes: { email },
        relationships: { betaGroups: { data: [{ type: "betaGroups", id: BETA_GROUP_ID }] } },
      },
    }),
  });
  if (res.status === 201) return { ok: true };
  let detail = `HTTP ${res.status}`;
  try {
    const j = await res.json();
    const e = j?.errors?.[0];
    if (e) detail = `${e.title}${e.detail ? ` — ${e.detail}` : ""} (${res.status})`;
    // A tester already in the group comes back 409 — treat as already-invited, not a failure.
    if (res.status === 409) return { ok: true, already: true };
  } catch {
    /* keep the generic detail */
  }
  return { ok: false, error: detail };
}

// --- Convex HTTP helpers (read pending, mark invited) ------------------------
async function convex(kind, pathName, argsObj) {
  const r = await fetch(`${CONVEX_URL}/api/${kind}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ path: pathName, args: argsObj, format: "json" }),
  });
  const json = await r.json();
  if (!r.ok || json?.status !== "success") {
    throw new Error(json?.errorMessage ?? `Convex ${pathName} failed (${r.status})`);
  }
  return json.value;
}

async function pendingEmailsFromConvex() {
  if (!ADMIN_SECRET) {
    die("No emails passed as args and ADMIN_SECRET is not set, so I can't read pending signups from Convex.");
  }
  const rows = await convex("query", "beta:list", { secret: ADMIN_SECRET });
  return rows.filter((r) => !r.invited).map((r) => r.email);
}

async function markInvited(email) {
  if (!APP_TOKEN_SECRET) return; // nothing to stamp with — leave the row as-is
  try {
    await convex("mutation", "beta:markInvited", { serverKey: APP_TOKEN_SECRET, email });
  } catch (e) {
    console.warn(`  (couldn't mark ${email} invited in Convex: ${e.message})`);
  }
}

// --- main --------------------------------------------------------------------
async function main() {
  const emails = emailArgs.length ? emailArgs.map((e) => e.trim().toLowerCase()) : await pendingEmailsFromConvex();
  if (!emails.length) {
    console.log("No pending signups to invite. Done.");
    return;
  }
  console.log(`${dryRun ? "[dry-run] " : ""}Inviting ${emails.length} email(s) to TestFlight beta group ${BETA_GROUP_ID}:`);
  if (dryRun) {
    emails.forEach((e) => console.log(`  would invite: ${e}`));
    return;
  }

  const jwt = makeJWT();
  let ok = 0;
  let fail = 0;
  for (const email of emails) {
    const r = await addTester(jwt, email);
    if (r.ok) {
      ok++;
      console.log(`  ✓ ${email}${r.already ? " (already in group)" : ""}`);
      await markInvited(email);
    } else {
      fail++;
      console.error(`  ✗ ${email}: ${r.error}`);
    }
  }
  console.log(`Done. ${ok} invited, ${fail} failed.`);
  if (fail) process.exit(1);
}

main().catch((e) => die(e.message));
