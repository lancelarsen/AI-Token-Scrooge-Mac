#!/usr/bin/env bash
# Package and sign locally; the private update key never leaves login Keychain.
set -euo pipefail
cd "$(dirname "$0")/.."
REVISION="${1:?Usage: publish_update.sh DAILY_REVISION [--publish]}"
[[ "$REVISION" =~ ^[1-9][0-9]{0,2}$ ]] || { echo 'Revision must be 1–999.' >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit changes before preparing an update.' >&2; exit 1; }
DAY="$(TZ=America/Chicago date +%Y.%-m.%-d)"
TAG="v$DAY.$(printf '%03d' "$REVISION")"
REPO='lancelarsen/AI-Token-Scrooge-Mac'
if [[ "${2:-}" == '--publish' ]]; then
  [[ "$(git branch --show-current)" == main ]] || { echo 'Publish from main.' >&2; exit 1; }
  [[ "$(git rev-parse HEAD)" == "$(git ls-remote origin refs/heads/main | cut -f1)" ]] || { echo 'Push this commit before publishing.' >&2; exit 1; }
  if gh release view "$TAG" --repo "$REPO" > /dev/null 2>&1; then
    echo 'That release already exists; use a new commit and revision.' >&2; exit 1
  fi
fi
SCROOGE_RELEASE_REVISION="$REVISION" ./script/package_preview.sh
TOOLS='build/SourcePackages/artifacts/sparkle/Sparkle/bin'
[[ -x "$TOOLS/generate_appcast" ]] || { echo 'Build the Debug app first to resolve Sparkle tools.' >&2; exit 1; }
STAGING="artifacts/updates/$TAG"
mkdir -p "$STAGING"
cp "artifacts/package/AI-Token-Scrooge-Mac-$TAG-arm64-preview.zip" "$STAGING/"
"$TOOLS/generate_appcast" --account com.lancelarsen.AITokenScrooge.updates \
  --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" "$STAGING"
if [[ "${2:-}" != '--publish' ]]; then
  echo "Signed update prepared in $STAGING. Pass --publish to publish it."
  exit 0
fi
# Immutable versioned archive first; replace the channel feed only after upload succeeds.
gh release create "$TAG" "$STAGING/"*.zip --repo "$REPO" --target "$(git rev-parse HEAD)" \
  --title "AI Token Scrooge Mac $TAG" --prerelease \
  --notes 'Mac preview, Apple silicon / macOS 26+. Sparkle update archives and feed are Ed25519-signed. This preview is ad-hoc code signed, not Developer ID notarized.'
if ! gh release view mac-updates --repo "$REPO" > /dev/null 2>&1; then
  gh release create mac-updates --repo "$REPO" --target "$(git rev-parse HEAD)" --prerelease \
    --title 'Mac update channel' --notes 'Signed Sparkle feed. Versioned downloads are listed in individual releases.'
fi
gh release upload mac-updates "$STAGING/appcast.xml" --repo "$REPO" --clobber
