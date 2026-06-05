#!/bin/bash
# Build Verba and assemble a runnable .app bundle.
set -e
cd "$(dirname "$0")"

VERSION="${VERSION:-0.1.0}"
APP="Verba.app"

echo "▸ Building release (arm64)…"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/Verba" "$APP/Contents/MacOS/Verba"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

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
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign for local runs (replace with Developer ID via sign-and-notarize.sh for release).
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "✅ Built $APP (v$VERSION)"
