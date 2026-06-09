#!/bin/bash
# Build Verba and assemble a runnable .app bundle.
set -e
cd "$(dirname "$0")"

VERSION="${VERSION:-0.1.0}"
APP="Verba.app"

echo "▸ Building release (arm64)…"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp ".build/release/Verba" "$APP/Contents/MacOS/Verba"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
[ -f ACKNOWLEDGEMENTS.txt ] && cp ACKNOWLEDGEMENTS.txt "$APP/Contents/Resources/ACKNOWLEDGEMENTS.txt"

# Bundle custom UI sounds (Sounds/<cue>.mp3 → Resources/Sounds). Optional; falls back to
# macOS system sounds for any cue without a file. Cues: start stop done pause resume cancel mode error.
if [ -d Sounds ] && ls Sounds/*.mp3 >/dev/null 2>&1; then
  mkdir -p "$APP/Contents/Resources/Sounds"
  cp Sounds/*.mp3 "$APP/Contents/Resources/Sounds/"
  echo "▸ Bundled custom sounds ($(ls Sounds/*.mp3 | wc -l | tr -d ' ') file(s))"
fi

# Bundle the default on-device model (Parakeet TDT v3) so the app transcribes offline
# instantly on first launch, with no download and no API key. Seeded into the FluidAudio
# cache at first run (see EngineManager.seedBundledModels). Requires the model present in
# the local cache at build time (run the app once to fetch it, or it's skipped).
PARAKEET_SRC="${PARAKEET_SRC:-$HOME/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3}"
if [ -d "$PARAKEET_SRC" ]; then
  mkdir -p "$APP/Contents/Resources/Models"
  ditto "$PARAKEET_SRC" "$APP/Contents/Resources/Models/parakeet-tdt-0.6b-v3"
  echo "▸ Bundled Parakeet model ($(du -sh "$PARAKEET_SRC" | cut -f1))"
else
  echo "⚠︎ Parakeet model not found locally ($PARAKEET_SRC); DMG will fall back to first-run download."
fi

# Embed Sparkle (silent auto-update). The binary loads @rpath/Sparkle.framework.
ditto ".build/release/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/Verba" 2>/dev/null || true

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Verba</string>
    <key>CFBundleDisplayName</key>     <string>Verba</string>
    <key>CFBundleExecutable</key>      <string>Verba</string>
    <key>CFBundleIdentifier</key>      <string>com.agentik.verba</string>
    <key>CFBundleVersion</key>         <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSMicrophoneUsageDescription</key><string>Verba records your voice to transcribe it into text.</string>
    <key>NSCalendarsUsageDescription</key><string>Verba creates the Calendar events you dictate, after you confirm.</string>
    <key>NSRemindersUsageDescription</key><string>Verba creates the Reminders you dictate, after you confirm.</string>
    <key>NSCalendarsFullAccessUsageDescription</key><string>Verba creates the Calendar events you dictate, after you confirm.</string>
    <key>NSRemindersFullAccessUsageDescription</key><string>Verba creates the Reminders you dictate, after you confirm.</string>
    <key>NSAppleEventsUsageDescription</key><string>Verba runs the actions you dictate, after you confirm.</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>SUFeedURL</key>               <string>https://github.com/agentik-os/Verba-releases/releases/latest/download/appcast.xml</string>
    <key>SUPublicEDKey</key>           <string>tUNn6q4RYRTmz5eB73hBC7Gh/RQfeCk8LHbGoczQGhs=</string>
    <key>SUEnableAutomaticChecks</key> <true/>
    <key>SUAutomaticallyUpdate</key>   <true/>
    <key>SUScheduledCheckInterval</key><integer>3600</integer>
</dict>
</plist>
PLIST

# Sign with a STABLE identity if available (Developer ID) so macOS keeps the
# Accessibility/Microphone grant across rebuilds. Falls back to ad-hoc otherwise.
SIGN_ID="${SIGN_ID:-Developer ID Application: Gareth Moison (975755H4ZC)}"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
  codesign --force --deep --sign "$SIGN_ID" "$APP"
  echo "▸ Signed with: $SIGN_ID"
else
  codesign --force --deep --sign - "$APP" 2>/dev/null || true
  echo "▸ Ad-hoc signed (set SIGN_ID for a stable signature)"
fi

echo "✅ Built $APP (v$VERSION)"
