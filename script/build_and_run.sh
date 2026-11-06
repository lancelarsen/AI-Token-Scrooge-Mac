#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AI Token Scrooge"
APP_BUNDLE="$ROOT_DIR/build/Build/Products/Debug/$APP_NAME.app"
case "$MODE" in run|--debug|--logs|--telemetry|--verify|--build) ;; *) echo "usage: $0 [--debug|--logs|--telemetry|--verify|--build]" >&2; exit 2;; esac
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
cd "$ROOT_DIR"
BUILD_NUMBER="$((1000 + $(git rev-list --count HEAD)))"
BUILD_DAY="$(TZ=America/Chicago date +%Y.%-m.%-d)"
xcodebuild -project AITokenScrooge.xcodeproj -scheme AITokenScrooge -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$ROOT_DIR/build" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" MARKETING_VERSION="$BUILD_DAY" SCROOGE_DISPLAY_VERSION="v$BUILD_DAY.000" build
case "$MODE" in
  --build) exit 0;;
  --debug) exec lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME";;
  *) /usr/bin/open "$APP_BUNDLE";;
esac
case "$MODE" in
  --verify) sleep 1; pgrep -x "$APP_NAME" >/dev/null;;
  --logs) exec /usr/bin/log stream --info --style compact --predicate 'process == "AI Token Scrooge"';;
  --telemetry) exec /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.lancelarsen.AITokenScrooge"';;
esac
