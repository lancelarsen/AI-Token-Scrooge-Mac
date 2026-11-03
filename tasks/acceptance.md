# Remaining acceptance checks

This is a verification checklist for the original native Mac parity objective, not a reduced definition of completion. The pinned Windows baseline and detailed evidence remain in README.md and tasks/parity.md.

Current local evidence: 71 unit tests pass in artifacts/notification-permission-message-tests.log; canonical Debug build passes in artifacts/notification-permission-message-build.log. These results do not prove live authentication, OS event delivery, or full visual parity.

| Requirement | Evidence required to close it | Current gap |
| --- | --- | --- |
| Codex connection lifecycle | Native browser login, cancellation, quota refresh, reconnect, and logout using an isolated profile; verify identity and displayed quotas against the provider | Live account session not supplied; signed-out transport only verified |
| GitHub connection lifecycle | Device login and advanced-token flow, quota units/allowance, renewal, reconnect, and credential retirement with a live authorized account | Fixture and persistence tests pass; live session remains unverified |
| Claude connection lifecycle | Install supported official CLI; isolated login/status/usage/logout; verify displayed quota windows against the provider | Installed CLI is 2.1.308, below required 2.1.310; live account session unverified |
| History hover | Physical pointer displays the correct account, observation/estimate, guide and details; leaving chart clears them; privacy and selection changes clear stale content | Original failure confirmed by user; native replacement builds and coordinate tests pass, physical verification pending |
| Native notification delivery | Enable per-app permission with user confirmation, send one test, observe OS notification and accepted history status; exercise Show Info, Snooze and Dismiss | Permission explicitly off in System Settings; confirmation pending. Controlled race tests are not OS delivery evidence |
| Scheduled and resumed monitoring | Live account refreshes at configured intervals; sleep/wake and network recovery respect throttling and reject stale identities | Scheduler/backoff tests pass; live runtime checks remain |
| Window and menu lifecycle | Close preserves background monitoring when enabled; menu/Dock reopen correct dashboard; disabled close-to-menu setting exits; verify menu actions | Close action preserved demo session; Dock inspection timed out; live background polling not established |
| Login items | Verify registration, OS approval, launch at sign-in, disable/unregister, and settings reconciliation in a stable app location | Service implementation exists; actual login-cycle behavior unverified |
| Dense and grouped history UI | Inspect exact-time counted reset/expiry groups and every included detail; exercise larger account counts, dense endpoint labels, compact and wide windows | Nearby lanes, two endpoint labels, a four-refresh counted group/detail sheet, and eight-account selector/navigator access and standard four-account compact layout verified; dense endpoint labels and combined eight-account compact layout remain |
| Alert and status appearance | Inspect info/warning/critical banners and menu indicators, unavailable status, privacy text, and action behavior | Policy tests and some demo banner actions pass; all native variants not yet inspected |
| Remaining native interactions | Verify custom account drag order, provider-page handoff, sound themes/volume, and keyboard navigation across relevant controls | Partial demo checks recorded in parity.md; complete interaction coverage not established |
| Packaged release | Verify the final selected commit's downloaded archive, resources, signature, architecture and launch; retain explicit ad-hoc/not-notarized labeling unless Developer ID credentials are supplied | Preview 37 at 17f054f downloaded: checksum, strict signature, arm64 architecture and native demo launch verified. Later selector correction needs a new package. No Developer ID/notarization evidence |

## Pending user decisions

- Whether to enable AI Token Scrooge notifications in macOS and send one test. Do not change the switch without the pending confirmation.
- Which live provider account to connect first. Do not substitute existing unrelated CLI credentials.
- Whether the replacement history pointer handler now displays details with normal mouse movement.

## Reporting rules

- Keep unverified requirements open even when related unit tests pass.
- Record the tested commit, environment, steps and concrete result for native/live checks.
- Demo checks establish synthetic UI behavior only. They do not establish provider correctness or background monitoring.
- The project is not ready to be marked feature-complete while any required acceptance evidence remains missing.
