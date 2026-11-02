#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
OUTPUT_DIR="$ROOT_DIR/artifacts/package"
BUILD_DIR="$ROOT_DIR/build/package"
APP_NAME="AI Token Scrooge"
APP_BUNDLE="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
mkdir -p "$OUTPUT_DIR"
xcodebuild -project AITokenScrooge.xcodeproj -scheme AITokenScrooge \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$BUILD_DIR" build > "$OUTPUT_DIR/build.log" 2>&1
/usr/bin/plutil -lint "$APP_BUNDLE/Contents/Info.plist"
ARCHS_FOUND="$(/usr/bin/lipo -archs "$APP_BUNDLE/Contents/MacOS/$APP_NAME")"
[[ "$ARCHS_FOUND" == "arm64" ]] || { echo "Expected Apple silicon-only app; got $ARCHS_FOUND" >&2; exit 1; }
for resource in token_baron.png openai.png github.svg claude.svg github-app.json duck-alert.wav classic-alert.wav Assets.car; do
  [[ -f "$APP_BUNDLE/Contents/Resources/$resource" ]] || { echo "Missing bundle resource: $resource" >&2; exit 1; }
done
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
ZIP_PATH="$OUTPUT_DIR/AI-Token-Scrooge-Mac-$VERSION-arm64-preview.zip"
if [[ -n "${SCROOGE_SIGNING_IDENTITY:-}" ]]; then
  /usr/bin/codesign --force --options runtime --timestamp --sign "$SCROOGE_SIGNING_IDENTITY" "$APP_BUNDLE"
fi
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
if [[ -n "${SCROOGE_NOTARY_PROFILE:-}" ]]; then
  [[ -n "${SCROOGE_SIGNING_IDENTITY:-}" ]] || { echo "Notarization requires a Developer ID signing identity." >&2; exit 1; }
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$SCROOGE_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
fi
(
  cd "$OUTPUT_DIR"
  /usr/bin/shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$ZIP_PATH").sha256"
  /usr/bin/shasum -a 256 -c "$(basename "$ZIP_PATH").sha256"
)
/usr/bin/codesign -dv --verbose=2 "$APP_BUNDLE" 2> "$OUTPUT_DIR/signature.txt"
echo "Packaged: $ZIP_PATH"
if [[ -z "${SCROOGE_SIGNING_IDENTITY:-}" ]]; then
  echo "Development preview: ad-hoc signed, not notarized."
fi
