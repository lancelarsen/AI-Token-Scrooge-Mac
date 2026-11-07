#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_NAME="AI Token Scrooge"
APP_BUNDLE="$ROOT_DIR/build/Build/Products/Debug/$APP_NAME.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
case "$MODE" in run|--debug|--logs|--telemetry|--verify|--build) ;; *) echo "usage: $0 [--debug|--logs|--telemetry|--verify|--build]" >&2; exit 2;; esac
# Multiple checkouts and installed previews share the same process name.
running_pids() {
  ps -axo pid=,comm= | awk -v executable="$APP_EXECUTABLE" '{
    pid = $1
    sub(/^ *[0-9]+ +/, "")
    if ($0 == executable) print pid
  }'
}

if [[ "$MODE" != --build ]]; then
  SCROOGE_INSTANCE_PIDS="$(/usr/bin/swift -e '
    import AppKit
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge") {
      print(app.processIdentifier)
    }
  ')"
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill "$pid" 2>/dev/null || true
  done <<< "$SCROOGE_INSTANCE_PIDS"
fi
cd "$ROOT_DIR"
BUILD_NUMBER="$((1000 + $(git rev-list --count HEAD)))"
BUILD_DAY="$(TZ=America/Chicago date +%Y.%-m.%-d)"
xcodebuild -project AITokenScrooge.xcodeproj -scheme AITokenScrooge -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$ROOT_DIR/build" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" MARKETING_VERSION="$BUILD_DAY" SCROOGE_DISPLAY_VERSION="v$BUILD_DAY.000" build
case "$MODE" in
  --build) exit 0;;
  --debug) exec lldb -- "$APP_EXECUTABLE";;
  *) /usr/bin/open "$APP_BUNDLE";;
esac
case "$MODE" in
  --verify) sleep 1; [[ -n "$(running_pids)" ]];;
  --logs) exec /usr/bin/log stream --info --style compact --predicate 'process == "AI Token Scrooge"';;
  --telemetry) exec /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.lancelarsen.AITokenScrooge"';;
esac
