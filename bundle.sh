#!/bin/bash
# Build Verba and assemble a runnable .app bundle.
set -e
cd "$(dirname "$0")"

# No silent default: an unstamped bundle ships a wrong CFBundleVersion and
# breaks Sparkle's version comparison. Always pass it explicitly.
VERSION="${VERSION:?Set VERSION explicitly, e.g. VERSION=0.2.0 ./bundle.sh}"
APP="Verba.app"

echo "▸ Building release (arm64)…"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp ".build/release/Verba" "$APP/Contents/MacOS/Verba"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# Localizations: <lang>.lproj/Localizable.strings → Resources, so the UI can switch language.
[ -d Localizations ] && cp -R Localizations/*.lproj "$APP/Contents/Resources/" 2>/dev/null || true
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
# Prefer Verba's own relocated cache (parakeet moved out of the foreign-looking FluidAudio/ container
# to stop the "access data from other apps" prompt); fall back to the legacy FluidAudio path.
if [ -z "${PARAKEET_SRC:-}" ]; then
  if [ -d "$HOME/Library/Application Support/Verba/parakeet-tdt-0.6b-v3" ]; then
    PARAKEET_SRC="$HOME/Library/Application Support/Verba/parakeet-tdt-0.6b-v3"
  else
    PARAKEET_SRC="$HOME/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3"
  fi
fi
if [ -d "$PARAKEET_SRC" ]; then
  mkdir -p "$APP/Contents/Resources/Models"
  ditto "$PARAKEET_SRC" "$APP/Contents/Resources/Models/parakeet-tdt-0.6b-v3"
  echo "▸ Bundled Parakeet model ($(du -sh "$PARAKEET_SRC" | cut -f1))"
elif [ "${SKIP_PARAKEET:-0}" = "1" ]; then
  echo "⚠︎ SKIP_PARAKEET=1 — building WITHOUT the bundled Parakeet model (first-run download fallback)."
else
  echo "❌ Parakeet model not found at: $PARAKEET_SRC" >&2
  echo "   Refusing to silently ship a bundle without the on-device model." >&2
  echo "   Fix: run the app once to fetch it, set PARAKEET_SRC to the model dir," >&2
  echo "   or set SKIP_PARAKEET=1 to knowingly build without it (dev only)." >&2
  exit 1
fi

# Bundle the Whisper tokenizer (config.json + tokenizer.json + tokenizer_config.json for
# openai/whisper-large-v3, shared by large-v3 and large-v3-turbo). Seeded into Application Support
# at launch (EngineManager.seedWhisperTokenizer) so WhisperKit loads the tokenizer LOCALLY and never
# hits the Hugging Face Hub — which would hang activation and re-create the macl-tagged
# ~/Documents/huggingface folder (the "access data from other apps" prompt). ~2.6 MB.
if [ -d WhisperTokenizer ]; then
  mkdir -p "$APP/Contents/Resources/WhisperTokenizer"
  cp -R WhisperTokenizer/* "$APP/Contents/Resources/WhisperTokenizer/"
  echo "▸ Bundled Whisper tokenizer ($(du -sh WhisperTokenizer | cut -f1))"
else
  echo "⚠︎ WhisperTokenizer/ not found; Whisper will fetch the tokenizer from the Hub on first load."
fi

# Embed Sparkle (silent auto-update). The binary loads @rpath/Sparkle.framework.
ditto ".build/release/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/Verba" 2>/dev/null || true

# ── Embed the WidgetKit extension as a proper macOS app-extension bundle ──
# VerbaWidget.appex/Contents/{Info.plist, MacOS/VerbaWidget}. The @main
# WidgetBundle binary is launched by WidgetKit's extension runtime. Lives in
# Verba.app/Contents/PlugIns so the host app advertises the widget.
if [ -f ".build/release/VerbaWidget" ]; then
  APPEX="$APP/Contents/PlugIns/VerbaWidget.appex"
  mkdir -p "$APPEX/Contents/MacOS"
  cp ".build/release/VerbaWidget" "$APPEX/Contents/MacOS/VerbaWidget"
  # The extension links SwiftUI/WidgetKit dynamically from the OS; it also needs
  # the Swift runtime rpath available to the host. The OS provides swift in /usr/lib/swift.
  cat > "$APPEX/Contents/Info.plist" <<APPEXPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>VerbaWidget</string>
    <key>CFBundleDisplayName</key>     <string>Verba Widget</string>
    <key>CFBundleExecutable</key>      <string>VerbaWidget</string>
    <key>CFBundleIdentifier</key>      <string>com.agentik.verba.widget</string>
    <key>CFBundleVersion</key>         <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key>     <string>XPC!</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key><string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
APPEXPLIST
  echo "▸ Embedded VerbaWidget.appex"
else
  echo "⚠︎ VerbaWidget binary not found; skipping widget embed."
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Verba</string>
    <key>CFBundleDisplayName</key>     <string>Verba</string>
    <key>CFBundleExecutable</key>      <string>Verba</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
      <string>en</string><string>fr</string><string>es</string><string>de</string><string>it</string>
      <string>pt</string><string>nl</string><string>ru</string><string>zh-Hans</string><string>ja</string>
      <string>ko</string><string>ar</string><string>hi</string><string>tr</string><string>pl</string>
    </array>
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
    <!-- SUAutomaticallyUpdate=false: do NOT silently auto-download/install in the background. That
         downloaded whatever was newest at check time and installed THAT on relaunch, so a user could
         land on an intermediate build instead of the newest (the "installs the next update, not the
         latest" bug). With it off, Sparkle still checks hourly and prompts, and downloads the LATEST
         appcast build at the moment the user clicks Update. -->
    <key>SUAutomaticallyUpdate</key>   <false/>
    <key>SUScheduledCheckInterval</key><integer>3600</integer>
    <!-- VER-19: register Transforms as a macOS Service so selecting text in ANY app and
         right-clicking shows Services ▸ "Transform with Verba…", which runs a chosen transform
         on the selection and replaces it. The provider is VerbaServiceProvider (Services.swift),
         installed via NSApp.servicesProvider; NSMessage is the selector, NSPortName the process. -->
    <key>NSServices</key>
    <array>
      <dict>
        <key>NSMenuItem</key>
        <dict>
          <key>default</key><string>Transform with Verba…</string>
        </dict>
        <key>NSMessage</key>       <string>transformWithVerba</string>
        <key>NSPortName</key>      <string>Verba</string>
        <key>NSSendTypes</key>     <array><string>NSStringPboardType</string></array>
        <key>NSReturnTypes</key>   <array><string>NSStringPboardType</string></array>
      </dict>
    </array>
</dict>
</plist>
PLIST

# Sign with a STABLE identity if available (Developer ID) so macOS keeps the
# Accessibility/Microphone grant across rebuilds. Falls back to ad-hoc otherwise.
# NOTE: this is the quick dev/local signature. The release path
# (sign-and-notarize.sh) does the hardened-runtime + App-Group + inside-out
# Sparkle + notarization signing. Here we just sign inside-out (appex, then app)
# so the local bundle passes `codesign --verify --deep --strict`.
SIGN_ID="${SIGN_ID:-Developer ID Application: Gareth Moison (975755H4ZC)}"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
  SIGN_WITH="$SIGN_ID"
else
  SIGN_WITH="-"
fi

# App-Group entitlement so the app and the widget extension share the
# "today's tasks" container EVEN ON A LOCAL DEV BUILD. Verified empirically: a
# Developer-ID signature honors this group's container on-device without portal
# registration (the portal/provisioning-profile step is only required for the
# notarized release flow in sign-and-notarize.sh). Ad-hoc ("-") signatures get
# NO container, so the widget falls back to its placeholder — by design.
GROUP_ENT="$(mktemp).plist"
cat > "$GROUP_ENT" <<'GENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.application-groups</key>
  <array><string>group.975755H4ZC.verba</string></array>
</dict></plist>
GENT

APPEX="$APP/Contents/PlugIns/VerbaWidget.appex"
if [ "$SIGN_WITH" = "-" ]; then
  # Ad-hoc: no entitlement (the group container is denied to ad-hoc signatures).
  [ -d "$APPEX" ] && codesign --force --sign - "$APPEX"
  codesign --force --sign - "$APP"
  echo "▸ Ad-hoc signed (set SIGN_ID for a stable signature + working widget container)"
else
  # Developer ID: sign inside-out (appex first) WITH the App-Group entitlement so
  # the widget actually reads the shared "today" snapshot during local testing.
  [ -d "$APPEX" ] && codesign --force --entitlements "$GROUP_ENT" --sign "$SIGN_WITH" "$APPEX"
  codesign --force --entitlements "$GROUP_ENT" --sign "$SIGN_WITH" "$APP"
  echo "▸ Signed with: $SIGN_ID (App-Group entitlement applied)"
fi

echo "✅ Built $APP (v$VERSION)"
