#!/bin/bash
# Cut a notarized release + Sparkle appcast + GitHub release.
#
#   DEVID="Developer ID Application: Gareth Moison (975755H4ZC)" \
#   VERSION=0.1.0 ./release.sh
#
# Prereqs: notary profile stored (see sign-and-notarize.sh), `gh` logged in,
# and the Sparkle EdDSA private key in your keychain (already set — public key
# tUNn6q4… is in bundle.sh's Info.plist).
#
# NOTE: for auto-update to reach end users, the release assets (Verba.dmg +
# appcast.xml) must be publicly downloadable. The repo is private — either make
# it public, or host the appcast/DMG on a public repo/CDN and update SUFeedURL.
set -e
cd "$(dirname "$0")"

VERSION="${VERSION:?Set VERSION, e.g. VERSION=0.1.0 ./release.sh}"
: "${DEVID:?Set DEVID to your Developer ID Application identity}"
# Releases (DMG + appcast) go to the PUBLIC repo: it backs both the website
# download (/releases/latest/download/Verba.dmg) and the Sparkle feed (SUFeedURL).
REPO="agentik-os/Verba-releases"
GENAPPCAST=".build/artifacts/sparkle/Sparkle/bin/generate_appcast"

# Stamp the version into the bundle, then sign + notarize (builds app + dmg).
VERSION="$VERSION" DEVID="$DEVID" ./sign-and-notarize.sh

# Collect this build into dist/ and (re)generate the signed appcast.
# dist/ is KEPT across releases (versioned DMG names) so generate_appcast can
# emit Sparkle delta updates between consecutive versions. The stable asset
# name (Verba.dmg) is still uploaded alongside, so the website's
# /releases/latest/download/Verba.dmg link keeps resolving.
mkdir -p dist
DMG_VERSIONED="dist/Verba-$VERSION.dmg"
cp Verba.dmg "$DMG_VERSIONED"
# generate_appcast signs the appcast with the Sparkle EdDSA PRIVATE key. Locally it reads it from
# the login keychain; in CI there's no keychain, so pass it as a file via SPARKLE_ED_KEY_FILE
# (the workflow writes the SPARKLE_ED_PRIVATE_KEY secret to a temp file).
GENAPPCAST_ARGS=(dist --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/")
[ -n "${SPARKLE_ED_KEY_FILE:-}" ] && GENAPPCAST_ARGS+=(--ed-key-file "$SPARKLE_ED_KEY_FILE")
"$GENAPPCAST" "${GENAPPCAST_ARGS[@]}"

# ── Gate: verify the appcast's EdDSA signature against the SUPublicEDKey that
# actually SHIPS in the app bundle. A keychain/bundle key mismatch would make
# every installed client reject the update — fail here, not in the field.
SHIPPED_KEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' Verba.app/Contents/Info.plist)"
[ -n "$SHIPPED_KEY" ] || { echo "❌ No SUPublicEDKey in Verba.app/Contents/Info.plist" >&2; exit 1; }
ED_SIG="$(grep -o "<enclosure[^>]*Verba-$VERSION\.dmg[^>]*" dist/appcast.xml \
  | grep -o 'sparkle:edSignature="[^"]*"' | head -1 | cut -d'"' -f2)"
[ -n "$ED_SIG" ] || { echo "❌ dist/appcast.xml has no sparkle:edSignature for Verba-$VERSION.dmg" >&2; exit 1; }
echo "▸ Verifying appcast EdDSA signature against shipped SUPublicEDKey…"
swift - "$SHIPPED_KEY" "$DMG_VERSIONED" "$ED_SIG" <<'SWIFT'
import CryptoKit
import Foundation
let a = CommandLine.arguments
guard a.count == 4,
      let pub = Data(base64Encoded: a[1]),
      let sig = Data(base64Encoded: a[3]),
      let data = try? Data(contentsOf: URL(fileURLWithPath: a[2])),
      let key = try? Curve25519.Signing.PublicKey(rawRepresentation: pub),
      key.isValidSignature(sig, for: data)
else {
    FileHandle.standardError.write(Data("❌ Appcast EdDSA signature does NOT verify against the shipped SUPublicEDKey — the signing key and the bundled public key disagree. Aborting release.\n".utf8))
    exit(1)
}
print("✓ Appcast EdDSA signature verifies against the shipped SUPublicEDKey")
SWIFT

# Optional: mark THIS version's appcast item as a critical update. Sparkle then surfaces it more
# insistently (skips the phased-rollout wait, harder to defer) so a reliability fix reaches everyone
# fast. Opt-in per release via CRITICAL=1 so ordinary releases stay non-critical. Inserted AFTER the
# signature gate and BEFORE upload, into this version's <item> only (before its enclosure) — the
# enclosure line the gate verifies is untouched.
if [ "${CRITICAL:-0}" = "1" ]; then
  echo "▸ Marking v$VERSION as a CRITICAL update in the appcast…"
  perl -0pi -e "s{(\n\s*)(<enclosure[^>]*Verba-\Q$VERSION\E\.dmg)}{\$1<sparkle:criticalUpdate></sparkle:criticalUpdate>\$1\$2}" dist/appcast.xml
  grep -q "sparkle:criticalUpdate" dist/appcast.xml \
    || { echo "❌ CRITICAL requested but the <sparkle:criticalUpdate/> tag was not inserted (appcast layout changed?)" >&2; exit 1; }
fi

echo "▸ Publishing GitHub release v$VERSION on $REPO…"
# Upload: versioned DMG (referenced by the appcast), stable-named Verba.dmg
# (website latest-link), the appcast, and any Sparkle deltas this run produced.
DELTAS=(dist/*.delta)
[ -e "${DELTAS[0]}" ] || DELTAS=()
gh release create "v$VERSION" \
  "Verba.dmg" "$DMG_VERSIONED" "dist/appcast.xml" "${DELTAS[@]}" \
  --repo "$REPO" --title "Verba $VERSION" --generate-notes

echo "✅ Released v$VERSION. Sparkle clients will pick it up from the appcast."
