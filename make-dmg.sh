#!/bin/bash
# Build a drag-and-drop Awish.dmg (app on the left, Applications on the right).
set -e
cd "$(dirname "$0")"

APP="Awish.app"
VOL="Awish"
DMG="Awish.dmg"
TMP="Awish-rw.dmg"

[ -d "$APP" ] || { echo "Build $APP first (./bundle.sh)"; exit 1; }

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG" "$TMP"
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -fs HFS+ -format UDRW -ov "$TMP" >/dev/null
DEV=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP" | egrep '^/dev/' | head -1 | awk '{print $1}')

osascript <<EOF 2>/dev/null || true
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {220, 120, 760, 470}
    set vo to the icon view options of container window
    set arrangement of vo to not arranged
    set icon size of vo to 112
    set position of item "$APP" of container window to {150, 175}
    set position of item "Applications" of container window to {410, 175}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

sync
hdiutil detach "$DEV" >/dev/null 2>&1 || hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true
hdiutil convert "$TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$TMP"
rm -rf "$STAGE"
echo "Built $DMG ($(du -h "$DMG" | cut -f1))"
