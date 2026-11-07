# Mac updates

Scrooge uses Sparkle 2.10.1 rather than a Windows executable-replacement script. Settings offers automatic checks (eight hours), a manual check, current date version, and last-check time. Sparkle presents download/install/relaunch choices and handles replacement of the app bundle. Provider data in Application Support and credentials in Keychain are outside that bundle.

The feed and update archives must carry valid Ed25519 signatures. Archives are verified before extraction. The public key is embedded in the app; the private key stays in the publishing Mac's login Keychain under account `com.lancelarsen.AITokenScrooge.updates`. No private key is committed or uploaded to CI. Do not lose this Keychain key; follow Sparkle's key-rotation guidance before replacing it.

The public feed is the `appcast.xml` asset on this repository's `mac-updates` release. Versioned archives are immutable assets on `vYYYY.M.D.NNN` releases. Unsigned CI previews are separate and never automatically enter the trusted channel. Release dates use America/Chicago. Local packages use revision 000; publishers choose the next unused daily revision (001–999). `CFBundleVersion` uses 1000 plus the commit count, so publish at most one version per commit, and do not rewrite main history.

## Prepare and publish

After a clean committed build and tests, run `./script/publish_update.sh 1` for the first release that day (increment for subsequent releases). This packages and signs without publishing. Add `--publish` to publish the immutable archive first and replace the signed channel feed last. The signing tool is supplied by the resolved, pinned Sparkle package. Publishing requires the existing GitHub CLI repository authorization and local Keychain key. No provider credentials are used.

Before packaging for `--publish`, the script downloads the current channel feed and requires the new integer build number to exceed every published item. Equal/older builds, missing or malformed versions, and channel lookup/download failures stop publication. Only a confirmed HTTP 404 allows initial channel creation. The daily display revision does not make an equal build number newer. Run publishers one at a time. The version checks and mocked publication preflight run in CI with `python3 -m unittest discover -s script/tests -v`.

Inspect the generated feed and verify its signature using Sparkle's `sign_update --account com.lancelarsen.AITokenScrooge.updates --verify PATH/appcast.xml`. Keep previous versioned releases for manual rollback. Installation must be exercised from a disposable installed copy against a newer signed build; unit tests alone do not prove relaunch or install permissions on another Mac.

## Distribution status

The current distribution is an ad-hoc-signed development preview, not Developer ID notarized. Ed25519 update signatures authenticate our update channel but do not replace Apple's Gatekeeper identity or notarization. This machine has no Developer ID Application certificate. For public production distribution, configure that identity and notarization and sign all nested Sparkle code before the outer bundle. Do not disable Gatekeeper or signature validation to make an update install.

References: https://sparkle-project.org/documentation/ and https://sparkle-project.org/documentation/programmatic-setup/.

November 3 verification: the published v2026.11.3.001 feed and archive passed signature verification, including a negative test that changed signed feed content. Sparkle installed build 1117 over a disposable build-100 copy under ~/Applications. Automatic relaunch was not observed. Testing from the Desktop triggered a macOS folder-access prompt; test installed copies under Applications instead of granting the updater broad Desktop access. Developer ID/notarization and a production relaunch pass remain outstanding.

## Development build protection

Debug builds never start Sparkle or allow manual release updates. Settings explain that local builds must be rebuilt. The build/run script also assigns the commit-based build number used by packaging instead of the project's placeholder 100.

November 6 incident: a local Debug bundle was replaced by signed channel build 1117 (November 3). Feed and archive signature checks passed, but the installed app crashed at launch because hardened-runtime library validation rejected Sparkle's different Team ID. This also explains the previously unobserved November 3 relaunch. The published November 3 archive remains unsuitable; the existing packaging script's ad-hoc runtime correction must be used for a replacement release, followed by an installed-copy update and relaunch check. Newer CI previews do not refresh the signed feed.

## November 6 repaired channel

Published v2026.11.6.001 (build 1361, source dde779c) to replace the faulty November 3 channel entry. The exact published ZIP was first installed by Sparkle over a disposable release copy with build number 1117 under ~/Applications/Scrooge Update Repair. The test used a locally served, Ed25519-signed feed and archive; signature enforcement remained enabled. Automatic relaunch succeeded and the dashboard rendered. This tests replacement from a runnable test host, not recovery of the already-crashing November 3 binary.

All 100 unit tests passed. After publishing, the public feed and ZIP were downloaded and compared byte-for-byte with the tested artifacts, and the downloaded feed signature was verified. The installed app checked the public GitHub feed and displayed “You’re up to date.” The channel now points to the corrected ad-hoc preview; Developer ID notarization and verification on another Mac remain outstanding.
