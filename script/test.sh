#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

xcodebuild -project AITokenScrooge.xcodeproj -scheme AITokenScrooge \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$ROOT_DIR/build" build-for-testing

# Xcode's staging Sparkle copy stalls in dyld before the test host reaches main.
# Prefer the framework embedded and signed with the app, as normal launches do.
# Keep the generated manifest beside the original so __TESTROOT__ is unchanged.
python3 - <<'PY'
from pathlib import Path
import plistlib

products = Path('build/Build/Products')
manifests = list(products.glob('AITokenScrooge_*.xctestrun'))
if len(manifests) != 1:
    raise SystemExit(f'Expected one test manifest, found {len(manifests)}')
with manifests[0].open('rb') as source:
    manifest = plistlib.load(source)
environment = manifest['ScroogeTests']['TestingEnvironmentVariables']
environment['DYLD_FRAMEWORK_PATH'] = (
    '__TESTHOST__/Contents/Frameworks:' + environment.get('DYLD_FRAMEWORK_PATH', '')
)
with (products / 'ScroogeEmbeddedFrameworks.xctestrun').open('wb') as output:
    plistlib.dump(manifest, output)
PY

exec xcodebuild test-without-building \
  -xctestrun build/Build/Products/ScroogeEmbeddedFrameworks.xctestrun \
  -destination 'platform=macOS,arch=arm64' -skip-testing:ScroogeUITests "$@"
