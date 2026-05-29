#!/bin/bash
# Build DiskLeaner and install it as a proper .app bundle to /Applications.
set -e

APP_NAME="DiskLeaner"
BUNDLE_ID="com.jophie.diskleaner"
VERSION="1.0"
BUILD_NUMBER="1"
MIN_MACOS="13.0"

STAGING=".build/$APP_NAME.app"
DEST="/Applications/$APP_NAME.app"

cd "$(dirname "$0")"

# ── 1. Build ────────────────────────────────────────────────────────────────
echo "▶  Building release binary…"
swift build -c release 2>&1 | grep -v "^warning:"

# ── 2. Quit running instance ────────────────────────────────────────────────
if pgrep -xq "$APP_NAME"; then
    echo "▶  Quitting running $APP_NAME…"
    pkill -x "$APP_NAME" || true
    sleep 1
fi

# ── 3. Assemble .app bundle in staging area ──────────────────────────────────
echo "▶  Assembling bundle…"
rm -rf "$STAGING"
mkdir -p "$STAGING/Contents/MacOS"
mkdir -p "$STAGING/Contents/Resources"

cp ".build/release/$APP_NAME" "$STAGING/Contents/MacOS/$APP_NAME"

cat > "$STAGING/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# ── 4. Install to /Applications ──────────────────────────────────────────────
echo "▶  Installing to /Applications (may ask for your password)…"
sudo rm -rf "$DEST"
sudo cp -R "$STAGING" "$DEST"

echo ""
echo "✅  DiskLeaner.app installed — launching…"
open "$DEST"
