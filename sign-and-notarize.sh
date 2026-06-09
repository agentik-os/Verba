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
#   VERSION=0.2.0 DEVID="Developer ID Application: Your Name (TEAMID)" ./sign-and-notarize.sh
set -e
cd "$(dirname "$0")"

DEVID="${DEVID:?Set DEVID to your \"Developer ID Application: …\" identity}"
# No silent version default — the bundle must be stamped explicitly (see bundle.sh).
VERSION="${VERSION:?Set VERSION explicitly, e.g. VERSION=0.2.0 DEVID=… ./sign-and-notarize.sh}"
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
  <!-- Shared container so the WidgetKit extension can read today's tasks.
       The App Group "group.975755H4ZC.verba" MUST be registered in the Apple
       Developer portal (Certificates, IDs & Profiles → Identifiers → App Groups)
       and enabled on both the app ID (com.agentik.verba) and the widget ID
       (com.agentik.verba.widget) BEFORE this entitlement will be honored. -->
  <key>com.apple.security.application-groups</key>
  <array><string>group.975755H4ZC.verba</string></array>
</dict></plist>
PLIST

# Entitlements for the widget extension: just the shared App Group (it reads,
# never records audio / hits the network in the spike). Hardened runtime too.
WIDGET_ENTITLEMENTS="$(mktemp).plist"
cat > "$WIDGET_ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.application-groups</key>
  <array><string>group.975755H4ZC.verba</string></array>
</dict></plist>
PLIST

echo "▸ Building app…"
VERSION="$VERSION" ./bundle.sh >/dev/null

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
# Widget extension is signed inside-out too: before the host app, hardened
# runtime, with its own App-Group entitlement.
APPEX="$APP/Contents/PlugIns/VerbaWidget.appex"
[ -d "$APPEX" ] && codesign --force --options runtime --timestamp \
  --entitlements "$WIDGET_ENTITLEMENTS" --sign "$DEVID" "$APPEX"
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
