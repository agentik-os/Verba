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
# Keep the DMG asset name STABLE (Verba.dmg) so /releases/latest/download/Verba.dmg
# always resolves; the version is read from the app bundle, not the filename.
rm -rf dist && mkdir -p dist
cp Verba.dmg "dist/Verba.dmg"
"$GENAPPCAST" dist \
  --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/"

echo "▸ Publishing GitHub release v$VERSION on $REPO…"
gh release create "v$VERSION" \
  "dist/Verba.dmg" "dist/appcast.xml" \
  --repo "$REPO" --title "Verba $VERSION" --generate-notes

echo "✅ Released v$VERSION. Sparkle clients will pick it up from the appcast."
