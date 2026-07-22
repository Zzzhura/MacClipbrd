#!/bin/bash
set -e

CONFIG="${1:-release}"
# Stable signing identity. Create once in Keychain Access:
#   Certificate Assistant → Create a Certificate → Self-Signed Root, Code Signing.
# Override with: SIGN_IDENTITY="Apple Development: you@example.com" ./build-app.sh
SIGN_IDENTITY="${SIGN_IDENTITY:-MacClipbrd Dev}"

APP="MacClipbrd.app"
BIN=".build/$CONFIG/MacClipbrd"
BUNDLE_ID="com.macclipbrd.app"

echo "Building ($CONFIG)…"
swift build -c "$CONFIG"

# Icon is keyed by CFBundleIconFile=AppIcon in Info.plist; regenerate from the
# 1024px source if it hasn't been built yet.
if [ ! -f "AppIcon.icns" ]; then
    echo "AppIcon.icns not found — generating from Assets/icon_1024.png…"
    ./generate-icns.sh
fi

echo "Packaging $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MacClipbrd"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# --deep is deprecated and signs nested code with the wrong flags; this bundle has
# no nested code, so sign it directly. --timestamp is required for notarization.
if security find-identity -p codesigning | grep -q "$SIGN_IDENTITY"; then
    echo "Signing with: $SIGN_IDENTITY"
    codesign --force --options runtime --timestamp \
        --identifier "$BUNDLE_ID" --sign "$SIGN_IDENTITY" "$APP"
else
    echo "WARNING: identity '$SIGN_IDENTITY' not found — falling back to ad-hoc (права будут запрашиваться при каждой пересборке)."
    codesign --force --identifier "$BUNDLE_ID" --sign - "$APP"
fi

# The Accessibility grant is keyed to this requirement. If it changes between
# releases, macOS treats the update as a different app and the grant stops
# applying — keep the identity and bundle id stable across versions.
echo
echo "Designated requirement (должен совпадать у всех версий):"
codesign -d -r- "$APP" 2>&1 | sed -n 's/^designated => /  /p'

# If a previous build is running, quit it and launch the freshly built bundle so
# the user is always testing the current binary.
if pgrep -x MacClipbrd >/dev/null; then
    echo "Quitting running MacClipbrd…"
    osascript -e 'quit app "MacClipbrd"' 2>/dev/null || pkill -x MacClipbrd
    # Wait for it to exit so `open` doesn't just reactivate the old instance.
    for _ in $(seq 1 20); do
        pgrep -x MacClipbrd >/dev/null || break
        sleep 0.1
    done
    pgrep -x MacClipbrd >/dev/null && pkill -9 -x MacClipbrd
fi

echo
echo "Done: $APP"
echo "Launching $APP…"
open "$APP"
