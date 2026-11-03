# Mac updates

Scrooge uses Sparkle 2.10.1 rather than a Windows executable-replacement script. Settings offers automatic checks (eight hours), a manual check, current date version, and last-check time. Sparkle presents download/install/relaunch choices and handles replacement of the app bundle. Provider data in Application Support and credentials in Keychain are outside that bundle.

The feed and update archives must carry valid Ed25519 signatures. Archives are verified before extraction. The public key is embedded in the app; the private key stays in the publishing Mac's login Keychain under account `com.lancelarsen.AITokenScrooge.updates`. No private key is committed or uploaded to CI. Do not lose this Keychain key; follow Sparkle's key-rotation guidance before replacing it.

The public feed is the `appcast.xml` asset on this repository's `mac-updates` release. Versioned archives are immutable assets on `vYYYY.M.D.NNN` releases. Unsigned CI previews are separate and never automatically enter the trusted channel. Release dates use America/Chicago. Local packages use revision 000; publishers choose the next unused daily revision (001–999). `CFBundleVersion` uses 1000 plus the commit count, so publish at most one version per commit, and do not rewrite main history.

## Prepare and publish

After a clean committed build and tests, run `./script/publish_update.sh 1` for the first release that day (increment for subsequent releases). This packages and signs without publishing. Add `--publish` to publish the immutable archive first and replace the signed channel feed last. The signing tool is supplied by the resolved, pinned Sparkle package. Publishing requires the existing GitHub CLI repository authorization and local Keychain key. No provider credentials are used.

Inspect the generated feed and verify its signature using Sparkle's `sign_update --account com.lancelarsen.AITokenScrooge.updates --verify PATH/appcast.xml`. Keep previous versioned releases for manual rollback. Installation must be exercised from a disposable installed copy against a newer signed build; unit tests alone do not prove relaunch or install permissions on another Mac.

## Distribution status

The current distribution is an ad-hoc-signed development preview, not Developer ID notarized. Ed25519 update signatures authenticate our update channel but do not replace Apple's Gatekeeper identity or notarization. This machine has no Developer ID Application certificate. For public production distribution, configure that identity and notarization and sign all nested Sparkle code before the outer bundle. Do not disable Gatekeeper or signature validation to make an update install.

References: https://sparkle-project.org/documentation/ and https://sparkle-project.org/documentation/programmatic-setup/.
