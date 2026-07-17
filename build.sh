#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/.build"
APP="$ROOT/Codex 用量.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICON_SOURCE="$ROOT/Assets/CodexUsageIcon.png"
MENU_ICON_SOURCE="$ROOT/Assets/CodexUsageMenuIcon.png"
ICONSET="$BUILD_DIR/CodexUsageIcon.iconset"

rm -rf "$BUILD_DIR" "$APP"
mkdir -p "$BUILD_DIR" "$MACOS" "$RESOURCES"

swiftc \
  -target arm64-apple-macos13.0 \
  -O \
  "$ROOT"/Sources/CodexUsageWidget/*.swift \
  -o "$MACOS/CodexUsageWidget" \
  -framework AppKit \
  -framework SwiftUI

cp "$ICON_SOURCE" "$RESOURCES/CodexUsageIcon.png"
cp "$MENU_ICON_SOURCE" "$RESOURCES/CodexUsageMenuIcon.png"

mkdir -p "$ICONSET"
sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$ICON_SOURCE" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$RESOURCES/CodexUsageIcon.icns"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleExecutable</key>
  <string>CodexUsageWidget</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.usage-widget</string>
  <key>CFBundleName</key>
  <string>Codex 用量</string>
  <key>CFBundleDisplayName</key>
  <string>Codex 用量</string>
  <key>CFBundleIconFile</key>
  <string>CodexUsageIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
echo "$APP"
