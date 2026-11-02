# Development previews

Run `./script/package_preview.sh` to build a Release configuration for Apple silicon, check resources and the code signature, and create a ZIP plus SHA-256 checksum under `artifacts/package/`.

The default archive is ad-hoc signed. It is not notarized or a trusted Developer ID release. Local packaging validates the bundle; it does not prove Gatekeeper acceptance on another Mac, live provider integration, or complete feature parity.

The GitHub workflow builds on a macOS 26 Apple silicon runner, runs the unit suite, and uploads the archive and test evidence. Successful main-branch builds publish a prerelease. Pull requests only upload artifacts. Action versions are pinned to commits. UI tests remain in the Xcode scheme but are not claimed as a release gate: the local Xcode UI runner currently times out enabling automation before assertions run.

## Download verification

Keep the ZIP and its `.sha256` file in the same folder. From that folder, run `shasum -a 256 -c AI-Token-Scrooge-Mac-0.1.0-arm64-preview.zip.sha256`. The checksum uses the ZIP filename, so it works outside the build machine. Preview 1 and Preview 2 used absolute build paths in their checksum files; those older files require replacing that path with the downloaded ZIP filename before verification.

## Developer ID and notarization

Once a Developer ID Application certificate is installed in the signing machine's Keychain, set `SCROOGE_SIGNING_IDENTITY` to its identity name when running the packaging script. This signs the completed app with hardened runtime and a secure timestamp.

For notarization, configure a notarytool Keychain profile separately, then set `SCROOGE_NOTARY_PROFILE` to that profile name. The script submits the ZIP, waits for acceptance, staples the app, validates the ticket, and recreates the ZIP/checksum. It does not print or save signing credentials. Do not commit certificate files, passwords, or notary credentials.

The hosted preview workflow intentionally uses ad-hoc signing until distribution credentials are configured. No notarization was performed during the current development pass.
