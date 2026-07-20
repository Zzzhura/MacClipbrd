#!/bin/bash
set -e

CONFIG="${1:-release}"
# Stable signing identity. Create once in Keychain Access:
#   Certificate Assistant → Create a Certificate → Self-Signed Root, Code Signing.
# Override with: SIGN_IDENTITY="Apple Development: you@example.com" ./build-app.sh
SIGN_IDENTITY="${SIGN_IDENTITY:-Multibuf Dev}"

APP="Multibuf.app"
BIN=".build/$CONFIG/Multibuf"
BUNDLE_ID="com.multibuf.app"

echo "Building ($CONFIG)…"
swift build -c "$CONFIG"

echo "Packaging $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Multibuf"
cp Info.plist "$APP/Contents/Info.plist"

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

echo
echo "Done: $APP"
echo "Run: open $APP"
