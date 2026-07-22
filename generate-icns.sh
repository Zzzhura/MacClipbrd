#!/bin/bash
# Script to compile icon_1024.png into AppIcon.icns for macOS application bundle

set -e

INPUT_IMAGE="Assets/icon_1024.png"
ICONSET_NAME="AppIcon.iconset"
FINAL_ICNS="AppIcon.icns"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "Error: $INPUT_IMAGE not found."
    exit 1
fi

echo "Verifying input image..."
sips -g pixelWidth -g pixelHeight -g hasAlpha "$INPUT_IMAGE"

mkdir -p "$ICONSET_NAME"

echo "Generating scaled PNG representations..."
sips -z 16 16     "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_16x16.png"
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_16x16@2x.png"
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_32x32.png"
sips -z 64 64     "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_32x32@2x.png"
sips -z 128 128   "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_128x128.png"
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_128x128@2x.png"
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_256x256.png"
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_256x256@2x.png"
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_NAME/icon_512x512.png"
cp "$INPUT_IMAGE" "$ICONSET_NAME/icon_512x512@2x.png"

echo "Creating AppIcon.icns..."
iconutil -c icns "$ICONSET_NAME" -o "$FINAL_ICNS"

rm -rf "$ICONSET_NAME"
echo "Done! AppIcon.icns is ready."
