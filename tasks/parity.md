# Feature parity tracking

Baseline: Windows 3d0330bc528196e583160d587465ea8b9bc5e979.

## Verified milestone

- Xcode Debug build and native app launch succeed on this Mac.
- Forty-eight tests pass (including Claude parser/version fixtures and the installed Codex CLI in a fresh signed-out profile): unknown/overage capacity, unknown billing units, workspace mismatch, reserve-only payloads, DST geometry, SQLite run compaction.
- Computer-use inspection confirms demo controls, provider artwork, future events, and history rendering. Native computer-use checks additionally confirm history toggle preserves selectors, navigator accessibility decrement changes dates, and historical reset details distinguish a reported schedule from an observed reset. Screenshot: artifacts/history-native-review.png (local evidence, ignored by Git). Full visual parity and live accounts are not verified.

## Implemented, awaiting complete verification

- Four-account demo values, quota IDs/units, reset periods, credit ownership and line colors now match the pinned source history demo.
- Source plan-label mapping is used throughout account cards, history selectors, labels and future events; unknown plans stay unavailable.
- Quota details include account/scope (hidden in privacy mode), fetch/provider timestamps and source provider-usage links; organization path escaping is tested, native browser handoff still to verify.
- Header freshness now shows source-matched latest observation date/time/zone and pending sign-in cleanup (date/zone regression coverage).
- Native SwiftUI dashboard/account cards; charcoal/lavender theme and bundled source artwork/sounds.
- Source-matched sorting keeps unknown/paused accounts last and preserves ties, with custom-order normalization and first-switch visible-order capture regression coverage. Drag reordering uses current serialized state. Custom drag order, history selectors, threshold controls, settings, reminders, account editor, alert history.
- Paused accounts are excluded from timeline selectors, curves and events; future-event fixtures cover pause, hidden selection and identity mismatch without deleting stored snapshots.
- Calendar-week history queries share viewport DST boundaries; cache expansion and the 169-hour fall-back week are tested, and zone changes reload history. Civil-day timeline geometry with DST handling, date rail, future reset/expiry details, overview navigation.
- SQLite snapshots/history runs, identity validation, Keychain token storage.
- GitHub advanced token identity and billing reads with provider/manual/unknown allowances and bounded no-redirect transport.
- Native menu bar, login item toggle, notification test, sound previews.
- Pure provider mapping and alert evaluation. GitHub retry handling covers seconds/date headers, short future deadlines, invalid values and fallback delay with source-matched tests.

## Remaining before parity

- Verify Codex browser login/cancellation and reconnect end-to-end with a live account; isolated transport and refresh are implemented and signed-out integration tested. Owned CLI processes now enforce a two-second termination deadline; a real SIGTERM-ignoring fixture verifies timeout cleanup.
- Verify Claude isolated auth, quota command and logout against an installed CLI and live account; implementation and parser/version fixtures are in place. Claude Code is not installed on this Mac.
- Verify GitHub device login and rotating credential renewal end-to-end, services and UI are implemented with credential-validation fixtures. Injected replacement-write and ambiguous-network failures now verify retry without double rotation and durable reconnect after restart; live renewal remains unverified.
- Verify scheduled refresh, native notification delivery/actions and menu/Dock badge end-to-end; scheduler, backoff, durable alert intents, quiet hours, account snooze, privacy, banner and Dock badge are implemented with policy tests. Delivery now revalidates current saved state after authorization and enqueue awaits, cancelling invalidated notifications. Menu alert indicator and queued notification routing now reopen the main window; verify both on screen.
- Verify startup login-item reconciliation and credential retirement against macOS/live providers; startup registration, approval status and Settings handoff are implemented (skipped during tests/demo). retired account records now persist and provider logout retries without touching active credentials. Connection commits and demo transitions share the mutation queue, and an epoch rejects pre-demo refresh results.
- Verify settings migration/default decoding and retention pruning end-to-end; top-level and nested preference default decoding, identity filtering and retirement round trips have tests. Alert/history retention now commits atomically; an injected SQLite delete failure proves rollback of both state and history, followed by successful retry. Version-one database loading and conversion on extension are verified across reopen, including revision/endpoints. Shared metadata packing, retained-history reads after pruning, and account removal/re-addition are tested; incremental revision reads/cache merges and pixel drawing reduction are implemented and tested.
- Verify source-matched weekly/monthly history selection and hover details visually; selection, replenishment/gap semantics and pixel reduction have tests. Historical reset/expiry markers are implemented and tested; latest-series labels and source-based event stacking height are implemented. Gap-line hover now exposes explicitly estimated values and rejects new-segment interpolation, with a regression test. History loading/read-error states and newest-request guards are implemented; leaving demo clears synthetic observations before real history loads. Source empty-history/no-upcoming-event text and account history status/coverage tooltips are implemented (Debug build passed). Verify marker interaction, hover and labels while navigating history visually.
- Account colors now resolve provider/plan defaults while preserving custom selections (round-trip and invalid-color fallback tests pass). Account color swatches use the exact source palette in source order (local Debug build passed). Threshold markers now have focus outlines and source-matched arrow-key adjustment (Debug build passed; native Left/Right changes Info 50→51→50, Tab reaches Warning, Up/Down changes Warning 30→31→30; local screenshot artifacts/threshold-keyboard-review.png). Native keyboard accessibility and visual review against the source screenshots at multiple window widths. Automated UI smoke test added with isolated storage; runner signing fixed, but UI automation initialization timed out before tests began (artifacts/ui-tests.log). Unit test launch now disables real-account monitoring through SCROOGE_TEST_MODE.
- First hosted preview workflow succeeded; preview-1-1 contains the ZIP and SHA-256 asset at source 69d013d. Verify subsequent previews after updates. Local Release ZIP packaging, arm64/resource/signature checks pass. Optional Developer ID/notarytool support is scripted and documented; no distribution identity/notarization has been verified.
- GitHub CLI is authenticated as lancelarsen with verified push access. Initial source published as 69d013d; hosted workflow run 41532806611 succeeded and published preview-1-1.
- Live account tests with user-authorized credentials. Never call demo results live verification.
