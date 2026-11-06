# AI Token Scrooge for Mac

Native SwiftUI port of [AI Token Scrooge](https://github.com/lancelarsen/AI-Token-Scrooge), targeting macOS 26 or later on Apple silicon.

**Status: in development; feature parity is not complete.** The dashboard, demo, settings, timeline, local history store, and GitHub advanced token connection are implemented. Codex browser authentication is implemented but not live-account verified. Claude authentication and quota reading are implemented with fixture tests. This development Mac has Claude Code 2.1.308 installed; quota reading requires 2.1.310 or later, and live verification remains open. GitHub device flow and credential renewal are implemented but still need end-to-end verification. Scheduled monitoring and alert delivery are implemented with policy tests; native end-to-end validation and full visual parity are still in progress. Do not rely on this development build for quota alerts.

The Windows reference baseline is commit `3d0330bc528196e583160d587465ea8b9bc5e979`. Its source is authoritative for behavior and defaults. Later Windows changes have been reviewed through `c80de39` (Devin Enterprise and provider icons); detailed port evidence and remaining gaps are recorded in `tasks/visual-parity-audit.md`. macOS uses native window controls, dialogs, Keychain, notifications, login items, and a menu bar companion.

## Devin Enterprise

Choose **Add Account → Devin**, then select **Sign In with Devin** and enter your work email on Devin’s page. If Devin redirects to your Enterprise workspace, Scrooge detects its address. You can also enter the workspace URL directly. Scrooge verifies the signed-in user and reads personal monthly Agent Compute Units (ACUs) from **Settings → My Analytics**. Refreshes run every ten minutes by default. Percentages need a reported allowance. The reset countdown needs an unambiguous reset time in the browser’s time zone.

Each connection uses its own temporary WebKit browser and keeps its saved session in macOS Keychain. Removing the account queues its session for deletion. Browser fixtures exercise sign-in state, refresh, and identity changes. Live company SSO and tenant access still need verification.

## Build

Open `AITokenScrooge.xcodeproj` in Xcode and choose the `AITokenScrooge` scheme, or run:

```sh
./script/build_and_run.sh
```

The same command is available through Codex's Run action. `--build` builds without opening the app, and `--verify` checks that the launched process exists. `--debug`, `--logs`, and `--telemetry` support development inspection.

`project.yml` is the XcodeGen source. Run `xcodegen generate` after changing targets, resources, or adding source files. The generated project is checked in so XcodeGen is not needed for ordinary builds.

To run the unit tests:

```sh
./script/test.sh
```

The script builds the tests and runs the unit suite using the app-embedded Sparkle framework; the Xcode staging copy stalls during test-host startup on this Mac. Pass an Xcode filter such as `-only-testing:ScroogeTests/CoreTests` to narrow the run. UI tests are excluded from this command.

The test scheme sets `SCROOGE_TEST_MODE=1`, which uses temporary state and disables scheduled monitoring. UI tests also set this explicitly.

Use `--demo` in the scheme's launch arguments for synthetic accounts. Add `--scenario offline|auth|permission|unknown|exhausted|due|partial|history-long|reserve-only` to reproduce the Windows reference scenarios. `healthy` and `no-reset` additionally exercise conditional row layouts. `missing-plan` verifies Weekly/Monthly selector fallbacks; `empty-windows` verifies waiting-for-usage cards and a long status message. `alert-history` adds synthetic delivered/recorded capacity alerts and reset reminders for the history reference. Scenario arguments apply only when entering demo; they never modify saved accounts. Unknown scenario names use the standard demo. Add `--compact` alongside `--demo` to start a 789-point-wide compact comparison window without restoring a previous window size. Use `--demo --reference-wide` for the 1463 × 866 wide reference frame; `--compact` takes precedence if both sizing flags are supplied. Add `--reference-date 2026-11-04T16:11:00Z` to an explicit `--demo` launch to freeze synthetic data, timeline dates and countdowns for repeatable reference captures. The date option is ignored outside demo launches; invalid or missing timestamps use the current time. `--data-dir /absolute/path` isolates local state for development.

## Local data

State and history are stored in SQLite under `~/Library/Application Support/AI Token Scrooge/`. GitHub tokens are stored in Keychain, not SQLite. Provider reports may lag; missing usage or allowances stay unknown. Demo changes are intended to remain separate from saved accounts.

## License

MIT. Original artwork, sounds, and third-party notices are retained under `Resources`.
