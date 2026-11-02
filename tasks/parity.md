# Feature parity tracking

Baseline: Windows 3d0330bc528196e583160d587465ea8b9bc5e979.

## Verified milestone

- Xcode Debug build and native app launch succeed on this Mac.
- Thirty-one tests pass (including Claude parser/version fixtures and the installed Codex CLI in a fresh signed-out profile): unknown/overage capacity, unknown billing units, workspace mismatch, reserve-only payloads, DST geometry, SQLite run compaction.
- Computer-use inspection confirms demo controls, provider artwork, future events, and history rendering. Full visual parity and live accounts are not verified.

## Implemented, awaiting complete verification

- Native SwiftUI dashboard/account cards; charcoal/lavender theme and bundled source artwork/sounds.
- Account sorting, custom drag order, history selectors, threshold controls, settings, reminders, account editor, alert history.
- Civil-day timeline geometry with DST handling, date rail, future reset/expiry details, overview navigation.
- SQLite snapshots/history runs, identity validation, Keychain token storage.
- GitHub advanced token identity and billing reads with provider/manual/unknown allowances and bounded no-redirect transport.
- Native menu bar, login item toggle, notification test, sound previews.
- Pure provider mapping and alert evaluation.

## Remaining before parity

- Verify Codex browser login/cancellation and reconnect end-to-end with a live account; isolated transport and refresh are implemented and signed-out integration tested.
- Verify Claude isolated auth, quota command and logout against an installed CLI and live account; implementation and parser/version fixtures are in place. Claude Code is not installed on this Mac.
- Verify GitHub device login and rotating credential renewal end-to-end, including persistence/network fault injection; services and UI are implemented with credential-validation fixtures.
- Verify scheduled refresh, native notification delivery/actions and menu/Dock badge end-to-end; scheduler, backoff, durable alert intents, quiet hours, account snooze, privacy, banner and Dock badge are implemented with policy tests. Menu alert indicator and queued notification routing now reopen the main window; verify both on screen.
- Verify startup login-item reconciliation and credential retirement against macOS/live providers; startup registration, approval status and Settings handoff are implemented (skipped during tests/demo). retired account records now persist and provider logout retries without touching active credentials. Connection commits and demo transitions share the mutation queue, and an epoch rejects pre-demo refresh results.
- Verify settings migration/default decoding and retention pruning end-to-end; default decoding, identity filtering and retirement round trips have tests. Shared metadata packing, retained-history reads after pruning, and account removal/re-addition are tested; incremental revision reads/cache merges and pixel drawing reduction are implemented and tested.
- Verify source-matched weekly/monthly history selection and hover details visually; selection, replenishment/gap semantics and pixel reduction have tests. Historical reset/expiry markers are implemented and tested; latest-series labels and source-based event stacking height are implemented. Verify marker interaction and labels while navigating history visually.
- Native keyboard accessibility and visual review against the source screenshots at multiple window widths. Automated UI smoke test added with isolated storage; runner signing fixed, but UI automation initialization timed out before tests began (artifacts/ui-tests.log). Unit test launch now disables real-account monitoring through SCROOGE_TEST_MODE.
- Run the new GitHub preview workflow after publication and verify its prerelease/artifacts. Local Release ZIP packaging, arm64/resource/signature checks pass. Optional Developer ID/notarytool support is scripted and documented; no distribution identity/notarization has been verified.
- GitHub CLI is authenticated as lancelarsen with verified push access. Initial publication and hosted workflow verification are in progress.
- Live account tests with user-authorized credentials. Never call demo results live verification.
