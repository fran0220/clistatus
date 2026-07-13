#!/bin/bash
# Build and package cliadmin.app (host + Finder Sync extension) via Xcode.

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen is required. Install with: brew install xcodegen" >&2
  exit 1
fi

echo "Generating Xcode project..."
xcodegen generate

DERIVED=".build/DerivedData"
APP_DIR=".build/cliadmin.app"
rm -rf "$DERIVED" "$APP_DIR"

echo "Building with xcodebuild..."
xcodebuild \
  -project CLIStatusApp.xcodeproj \
  -scheme CLIStatusApp \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  build

BUILT_APP=$(find "$DERIVED/Build/Products/Release" -maxdepth 1 -name "CLIStatusApp.app" | head -n 1)
if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
  echo "error: CLIStatusApp.app not found in build products" >&2
  exit 1
fi

cp -R "$BUILT_APP" "$APP_DIR"

# Prefer display name for install path convenience
if [ -d "$APP_DIR" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName cliadmin" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
fi

APPEX="$APP_DIR/Contents/PlugIns/CLIStatusFinderSync.appex"
if [ ! -d "$APPEX" ]; then
  echo "error: Finder Sync appex missing at $APPEX" >&2
  exit 1
fi

echo "Done! App bundle created at: $APP_DIR"
echo "Finder Sync extension: $APPEX"
echo ""
echo "To run: open $APP_DIR"
echo "To install: cp -R $APP_DIR /Applications/cliadmin.app"
echo "Then enable: System Settings → Privacy & Security → Extensions → Finder Extensions"
