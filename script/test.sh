#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Use Xcode's per-checkout DerivedData location for the signed test host and frameworks.
exec xcodebuild test -project AITokenScrooge.xcodeproj -scheme AITokenScrooge \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -skip-testing:ScroogeUITests "$@"
