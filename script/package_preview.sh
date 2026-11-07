#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if [[ "$(git rev-parse --is-shallow-repository)" != false ]]; then
  echo 'Preview packaging requires full Git history for the Sparkle build number. Run git fetch --unshallow and retry.' >&2
  exit 1
fi
if [[ -n "${SCROOGE_NOTARY_PROFILE:-}" && -z "${SCROOGE_SIGNING_IDENTITY:-}" ]]; then
  echo "Notarization requires a Developer ID signing identity." >&2
  exit 1
fi
OUTPUT_DIR="$ROOT_DIR/artifacts/package"
BUILD_DIR="$ROOT_DIR/build/package"
APP_NAME="AI Token Scrooge"
APP_BUNDLE="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
# Browser sign-in trials and profiles are local credentials, never distributable resources.
reject_devin_profiles() {
  local match
  match="$(find "$1" \( -iname DevinProfiles -o -iname DevinTrials \) -print -quit)"
  [[ -z "$match" ]] || { echo 'Package contains a Devin sign-in directory.' >&2; exit 1; }
}
reject_devin_profiles Resources
mkdir -p "$OUTPUT_DIR"
RELEASE_DAY="$(TZ=America/Chicago date +%Y.%-m.%-d)"
RELEASE_REVISION="${SCROOGE_RELEASE_REVISION:-0}"
[[ "$RELEASE_REVISION" =~ ^[0-9]{1,3}$ ]] || { echo "Release revision must be 0–999." >&2; exit 1; }
DISPLAY_VERSION="v$RELEASE_DAY.$(printf '%03d' "$((10#$RELEASE_REVISION))")"
BUILD_NUMBER="$((1000 + $(git rev-list --count HEAD)))"
# Ad-hoc previews have no Team ID for hardened-runtime library validation.
# Match the working Debug configuration; Developer ID distribution keeps runtime.
HARDENED_RUNTIME=NO
if [[ -n "${SCROOGE_SIGNING_IDENTITY:-}" ]]; then HARDENED_RUNTIME=YES; fi
xcodebuild -project AITokenScrooge.xcodeproj -scheme AITokenScrooge \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$BUILD_DIR" ENABLE_HARDENED_RUNTIME="$HARDENED_RUNTIME" MARKETING_VERSION="$RELEASE_DAY" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" SCROOGE_DISPLAY_VERSION="$DISPLAY_VERSION" build > "$OUTPUT_DIR/build.log" 2>&1
reject_devin_profiles "$APP_BUNDLE"
/usr/bin/plutil -lint "$APP_BUNDLE/Contents/Info.plist"
ARCHS_FOUND="$(/usr/bin/lipo -archs "$APP_BUNDLE/Contents/MacOS/$APP_NAME")"
[[ "$ARCHS_FOUND" == "arm64" ]] || { echo "Expected Apple silicon-only app; got $ARCHS_FOUND" >&2; exit 1; }
for resource in token_baron.png openai.png github.svg claude.svg devin.svg github-app.json duck-alert.wav classic-alert.wav WindowsColorNames.plist Assets.car; do
  [[ -f "$APP_BUNDLE/Contents/Resources/$resource" ]] || { echo "Missing bundle resource: $resource" >&2; exit 1; }
done
# Typography, provider marks and alert sounds are part of UI parity. Verify the
# packaged bytes, not just the presence of a subset of historical resources.
for source in Resources/Fonts/*.ttf Resources/Images/* Resources/Sounds/*.wav Resources/WindowsColorNames.plist; do
  [[ -f "$source" ]] || continue
  resource="$(basename "$source")"
  /usr/bin/cmp -s "$source" "$APP_BUNDLE/Contents/Resources/$resource" || {
    echo "Missing or changed bundle resource: $resource" >&2
    exit 1
  }
done
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
ZIP_PATH="$OUTPUT_DIR/AI-Token-Scrooge-Mac-$DISPLAY_VERSION-arm64-preview.zip"
if [[ -n "${SCROOGE_SIGNING_IDENTITY:-}" ]]; then
  /usr/bin/codesign --force --options runtime --timestamp --sign "$SCROOGE_SIGNING_IDENTITY" "$APP_BUNDLE"
fi
# Never publish a release that allows another process to attach a debugger.
# Debug builds retain Xcode's normal development entitlements.
/usr/bin/codesign -d --entitlements - --xml "$APP_BUNDLE" 2>/dev/null | python3 -c '
import plistlib, sys
payload = sys.stdin.buffer.read()
entitlements = plistlib.loads(payload) if payload.strip() else {}
if entitlements.get("com.apple.security.get-task-allow", False):
    sys.exit("Release package contains the get-task-allow debugger entitlement.")
'
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
if [[ -n "${SCROOGE_NOTARY_PROFILE:-}" ]]; then
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
  echo "Development preview: ad-hoc signed, hardened runtime disabled, not notarized."
fi
