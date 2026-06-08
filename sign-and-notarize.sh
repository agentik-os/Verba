#!/bin/bash
# Sign + notarize Verba so it installs with NO Gatekeeper warning.
#
# ONE-TIME SETUP (paid Apple Developer account):
#  1. "Developer ID Application" certificate in your login keychain.
#       security find-identity -v -p codesigning
#  2. Store a notarization profile once (app-specific password from appleid.apple.com):
#       xcrun notarytool store-credentials verba-notary \
#         --apple-id "you@example.com" --team-id "YOURTEAMID" \
#         --password "xxxx-xxxx-xxxx-xxxx"
#
# THEN:
#   DEVID="Developer ID Application: Your Name (TEAMID)" ./sign-and-notarize.sh
set -e
cd "$(dirname "$0")"

DEVID="${DEVID:?Set DEVID to your \"Developer ID Application: …\" identity}"
PROFILE="${NOTARY_PROFILE:-verba-notary}"
APP="Verba.app"
DMG="Verba.dmg"
ENTITLEMENTS="$(mktemp).plist"

cat > "$ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.cs.allow-jit</key><true/>
  <key>com.apple.security.cs.allow-unsigned-executable-memory</key><true/>
  <key>com.apple.security.network.client</key><true/>
  <key>com.apple.security.device.audio-input</key><true/>
  <key>com.apple.security.device.microphone</key><true/>
  <key>com.apple.security.personal-information.calendars</key><true/>
  <key>com.apple.security.personal-information.reminders</key><true/>
</dict></plist>
PLIST

echo "▸ Building app…"
./bundle.sh >/dev/null

echo "▸ Signing Sparkle (inside-out) + app (hardened runtime)…"
# Sparkle must be signed inside-out (XPC services, Autoupdate, Updater.app, then
# the framework), then the app WITHOUT --deep (--deep breaks notarization).
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE" ]; then
  for c in \
    "Versions/B/XPCServices/Downloader.xpc" \
    "Versions/B/XPCServices/Installer.xpc" \
    "Versions/B/Autoupdate" \
    "Versions/B/Updater.app"; do
    [ -e "$SPARKLE/$c" ] && codesign --force --options runtime --timestamp --sign "$DEVID" "$SPARKLE/$c"
  done
  codesign --force --options runtime --timestamp --sign "$DEVID" "$SPARKLE"
fi
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" --sign "$DEVID" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "▸ Building DMG…"
./make-dmg.sh >/dev/null
codesign --force --timestamp --sign "$DEVID" "$DMG"

echo "▸ Notarizing (a few minutes)…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait

echo "▸ Stapling…"
xcrun stapler staple "$DMG"
xcrun stapler staple "$APP" || true

echo "✅ $DMG is signed + notarized — installs with no warning."
