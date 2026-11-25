#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="EvenDisplay"
VERSION="1.0.0"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET="$DIST_DIR/AppIcon.iconset"
DMG_STAGING="$DIST_DIR/dmg_staging"
DMG_PATH="$DIST_DIR/$APP_NAME-v$VERSION.dmg"

mkdir -p "$DIST_DIR" "$ROOT_DIR/site/assets"
rm -rf "$APP_BUNDLE" "$ICONSET" "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$MACOS" "$RESOURCES"

echo "1/4 Generating macOS AppIcon.icns, web icon & OG card..."
swift "$ROOT_DIR/scripts/generate_assets.swift" "$ICONSET" "$ROOT_DIR/site/assets/og-card.png"
sips -s format icns "$ICONSET/icon_512x512@2x.png" --out "$RESOURCES/AppIcon.icns" >/dev/null
cp "$ICONSET/icon_512x512.png" "$ROOT_DIR/site/assets/icon.png"
rm -rf "$ICONSET"

echo "2/4 Writing Info.plist..."
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.evendisplay.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "3/4 Compiling & ad-hoc signing $APP_NAME.app..."
swiftc -O -parse-as-library \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ServiceManagement \
    -framework UniformTypeIdentifiers \
    -o "$MACOS/$APP_NAME" \
    "$ROOT_DIR/macos/Sources/main.swift"

codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"

echo "4/4 Packaging release archives..."
ZIP_PATH="$DIST_DIR/$APP_NAME-v$VERSION.zip"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
ZIP_SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
if hdiutil create -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" >/dev/null 2>&1; then
    DMG_SHA="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
    echo "  DMG: $DMG_PATH (SHA256: $DMG_SHA)"
else
    echo "  Note: Skipped .dmg in restricted environment; .zip release archive is ready."
fi
rm -rf "$DMG_STAGING"

echo "Done!"
echo "  App: $APP_BUNDLE"
echo "  ZIP: $ZIP_PATH (SHA256: $ZIP_SHA)"
