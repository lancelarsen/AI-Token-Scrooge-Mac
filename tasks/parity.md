# Feature parity tracking

Baseline: Windows 3d0330bc528196e583160d587465ea8b9bc5e979.

## User-requested presentation changes

- November 6: quota-row service messages use a yellow warning icon before the quota name instead of an inline paragraph. Hover reveals the full message; activating the icon or title opens usage details. This applies across providers. Healthy rows stay clear, and the demo header identifies synthetic data without repeated row notes. This user-requested presentation supersedes the Windows inline-note layout.

## Verified milestone

- Xcode Debug build and native app launch succeed on this Mac.
- Latest local unit run: 71 tests passed with zero failures (artifacts/notification-permission-message-tests.log). Coverage includes provider/parser fixtures, signed-out Codex transport, quota uncertainty, DST/history geometry, SQLite compaction/rollback, and AppStore alert failure/recovery/queue/demo-isolation checks. This does not establish live-provider or native notification correctness.
- Computer-use inspection confirms demo controls, provider artwork, future events, and history rendering. Native computer-use checks additionally confirm history toggle preserves selectors, navigator accessibility decrement changes dates, and historical reset details distinguish a reported schedule from an observed reset. Screenshot: artifacts/history-native-review.png (local evidence, ignored by Git). Full visual parity and live accounts are not verified.

## Implemented, awaiting complete verification

- Four-account demo values, quota IDs/units, reset periods, credit ownership and line colors now match the pinned source history demo.
- Source plan-label mapping is used throughout account cards, history selectors, labels and future events; unknown plans stay unavailable.
- Quota details include account/scope (hidden in privacy mode), fetch/provider timestamps and source provider-usage links; organization path escaping is tested, native browser handoff still to verify.
- Header freshness now shows source-matched latest observation date/time/zone and pending sign-in cleanup (date/zone regression coverage).
- Account names save trimmed, non-empty edits on submit/focus loss; native demo verifies blank-name rejection and whitespace trimming, then restores the original name.
- Native SwiftUI dashboard/account cards; charcoal/lavender theme and bundled source artwork/sounds.
- Source-matched sorting keeps unknown/paused accounts last and preserves ties, with custom-order normalization and first-switch visible-order capture regression coverage. Drag reordering uses current serialized state. Timeline selectors/series follow saved custom order independently of active card sorting, with regression coverage. Custom drag order, history selectors, threshold controls, settings, reminders, account editor, alert history.
- Paused accounts are excluded from timeline selectors, curves and events; future-event fixtures cover pause, hidden selection and identity mismatch without deleting stored snapshots. Native demo pause verified: quota rows become Monitoring Disabled, selector disappears, future counts change 7/2 to 5/0, and management stays available. Demo exit clears synthetic accounts/events.
- Calendar-week history queries share viewport DST boundaries; cache expansion and the 169-hour fall-back week are tested, and zone changes reload history. Civil-day timeline geometry with DST handling, date rail, future reset/expiry details, overview navigation.
- SQLite snapshots/history runs, identity validation, Keychain token storage.
- GitHub advanced token identity and billing reads with provider/manual/unknown allowances and bounded no-redirect transport.
- Native menu bar, login item toggle, notification test, sound previews. Notification tests now record intent before sending, show an in-app test banner, and mark delivery only after macOS accepts the notification; errors retain the history entry. Epoch and dismissal/snooze checks guard authorization/enqueue waits. Debug build and unit suite pass; native permission/delivery validation remains outstanding.
- Alert history displays recorded versus macOS-delivered status. Clicking an entry opens shared quota details or earned-reset availability/expiry details; removed accounts/windows show the source unavailable message. Debug build passes. Native CUA check verified Settings → Alert History → No Alerts Yet → Close, and the extracted quota popover showed demo Codex 38% used/62% left with fetch/reset timestamps. Exit Demo restored the empty connected-account dashboard. Native demo checks also verified a populated test-alert entry, its reserve details, dismissal, and Show Info account highlighting. Native notification delivery/actions remain unverified.
- Pure provider mapping and alert evaluation. GitHub retry handling covers seconds/date headers, short future deadlines, invalid values and fallback delay with source-matched tests.

## Remaining before parity

- Verify Codex browser login/cancellation and reconnect end-to-end with a live account; isolated transport and refresh are implemented and signed-out integration tested. Owned CLI processes now enforce a two-second termination deadline; a real SIGTERM-ignoring fixture verifies timeout cleanup.
- Verify Claude isolated auth, quota command and logout against an installed CLI and live account; implementation and parser/version fixtures are in place. Claude Code 2.1.308 is now installed on this Mac, below the required 2.1.310 quota-command version.
- Verify GitHub device login and rotating credential renewal end-to-end, services and UI are implemented with credential-validation fixtures. Injected replacement-write and ambiguous-network failures now verify retry without double rotation and durable reconnect after restart; live renewal remains unverified.
- Verify scheduled refresh, native notification delivery/actions and menu/Dock badge end-to-end; scheduler, backoff, durable alert intents, quiet hours, account snooze, privacy, banner and Dock badge are implemented with policy tests. Delivery now revalidates current saved state after authorization and enqueue awaits, cancelling invalidated notifications. Snooze/dismiss now persist through the serial mutation queue before clearing a banner, cancelling the notification or playing confirmation audio; a captured banner ID protects newer arrivals. Debug build and unit suite pass; injected action-save failure/recovery, newer-banner protection and demo-state isolation now pass AppStore integration tests; native notification races remain outstanding. Menu alert indicator and queued notification routing now reopen the main window; verify both on screen. Banner and notification Show Info now follow the source account-card navigation: dismiss dashboard sheets, scroll to the account, and highlight it for six seconds; repeated requests restart the highlight. Debug build and unit suite pass; native in-app Show Info scrolling/highlight was observed in demo; delivered-notification actions and timing remain to be verified.
- Verify startup login-item reconciliation and credential retirement against macOS/live providers; startup registration, approval status and Settings handoff are implemented (skipped during tests/demo). retired account records now persist and provider logout retries without touching active credentials. Connection commits and demo transitions share the mutation queue, and an epoch rejects pre-demo refresh results.
- Verify settings migration/default decoding and retention pruning end-to-end; top-level and nested preference default decoding, identity filtering and retirement round trips have tests. Alert/history retention now commits atomically; an injected SQLite delete failure proves rollback of both state and history, followed by successful retry. Version-one database loading and conversion on extension are verified across reopen, including revision/endpoints. Shared metadata packing, retained-history reads after pruning, and account removal/re-addition are tested; incremental revision reads/cache merges and pixel drawing reduction are implemented and tested.
- Verify source-matched weekly/monthly history selection and hover details visually; selection, replenishment/gap semantics and pixel reduction have tests. Historical reset/expiry markers are implemented and tested; latest-series labels and source-based event stacking height are implemented. Gap-line hover now exposes explicitly estimated values and rejects new-segment interpolation, with a regression test. History loading/read-error states and newest-request guards are implemented; leaving demo clears synthetic observations before real history loads. Source empty-history/no-upcoming-event text and account history status/coverage tooltips are implemented (Debug build passed). Native single-marker detail navigation, nearby-event lanes, future quota/reserve details, overview dragging and shorter-plot scaling are verified in demo. Endpoint labels were verified in a two-account demo with current observations at the right edge: Pro 94% and Pro 58% rendered separately. A four-event exact-time refresh group and its scrollable details were verified with a temporary synthetic fixture. Larger account counts and hover remain unverified. The user confirmed no details appeared with a normal mouse in the original SwiftUI implementation. A native AppKit tracking surface now replaces onContinuousHover; build and coordinate/lifecycle regression checks pass, but actual pointer-driven details still need verification in the replacement build.
- Account colors now resolve provider/plan defaults while preserving custom selections (round-trip and invalid-color fallback tests pass). Account color swatches use the exact source palette in source order (local Debug build passed). Threshold markers now have focus outlines and source-matched arrow-key adjustment (Debug build passed; native Left/Right changes Info 50→51→50, Tab reaches Warning, Up/Down changes Warning 30→31→30; local screenshot artifacts/threshold-keyboard-review.png). Native keyboard accessibility and visual review against the source screenshots at multiple window widths. Automated UI smoke test added with isolated storage; runner signing fixed, but UI automation initialization timed out before tests began (artifacts/ui-tests.log). Unit test launch now disables real-account monitoring through SCROOGE_TEST_MODE.
- Most recently downloaded and checked release: preview-32-1 at 820c03e, with valid checksum, strict extracted-app signature and arm64-only binary. Hosted run 41546584191 succeeded. This includes native history pointer tracking but predates the baseline-fill correction; packaged runtime hover remains unverified. Local Release ZIP packaging, arm64/resource/signature checks pass. Optional Developer ID/notarytool support is scripted and documented; no distribution identity/notarization has been verified.
- GitHub CLI is authenticated as lancelarsen with verified push access. Initial source published as 69d013d; hosted workflow run 41532806611 succeeded and published preview-1-1.
- Live account tests with user-authorized credentials. Never call demo results live verification.

### Native alert checks (2026-11-02)

- In demo mode, Send Test Notification created an in-app banner and a populated Alert History entry. Show Info scrolled to the first Codex account and visibly applied the lavender card outline. The history entry opened Available Resets with two reported credits and their expiry dates. Dismiss disabled the history snooze/dismiss controls. Exit Demo restored the empty dashboard.
- The test entry remained Recorded in History; macOS notification acceptance/display was not confirmed. These checks establish in-app navigation and dismissal only, not native notification delivery or live-provider behavior.

- Alert banners now include the source provider icon/name and severity-specific title/border colors (info blue, warning yellow, critical red, default lavender), with the source dark banner background. Debug build passes; native rendering across all severity variants remains to be checked.

- Account snooze deadlines persist independently of alert history, matching the source account-level behavior. Legacy alert deadlines migrate on decode; account removal clears its deadline. A regression test covers legacy migration, history removal, reopen and exact expiry. Unit suite passes.

- Icon quota alerts now derive from the highest current enabled quota/reminder severity, independently of popup delivery, quiet hours and snooze, matching source IconAlerts. Dock uses an attention mark rather than a misleading delivered-alert count. Regression coverage verifies critical status with popups off/quiet/snooze, paused-account exclusion and icon preference. Unit suite passes. Source unavailable-data/paused-usage icon treatment and native icon rendering remain outstanding.

- Monitor availability now flags no accounts, paused monitoring, missing/stale/identity-mismatched data, unknown allowances, and provider-paused usage. Menu bar uses a distinct question-mark state and explanatory menu/accessibility text; quota severity retains priority. Unit suite passes with missing/stale/identity/paused regression cases. Native menu-bar rendering and the source limiting-quota tooltip remain to be verified/completed.

- Menu-bar tooltip/menu summary now identifies the limiting account/window by source severity rank and remaining-percentage tie break, adds monitoring notices, labels demo state, and respects privacy. Current icon alerts override the summary with source alert details. Unit suite passes, including limiting-window ordering and paused exclusion. Native tooltip/menu visual verification remains outstanding.

- Timed quota/reset alerts now include the exact timestamp in the selected display zone alongside the countdown, matching source reminder details. Unit suite passes with timestamp coverage and demo/stale/offline/authentication health rejection checks.

- Account settings reset details now label counts as reported, include snapshot fetch time/health, show credit status and locally expired notices, and distinguish unavailable details. Identity-mismatched reserves are excluded. Debug build passes; native reserve-settings review remains outstanding.

- Native demo check verified account reset counts, fetched time and available-credit status; pausing monitoring changed the status to Monitoring Paused. Restored monitoring and exited demo.
- Hosted run 41539142189 succeeded at de5c03c and published preview-20-1. The downloaded ZIP passes its checksum, strict extracted-app signature check and arm64 inspection. This preview precedes the exact-reminder-time and account-reset-detail changes.

- macOS app activation, workspace wake and offline-to-online network transitions now request refresh through the existing throttle-aware refresh path. Initial path discovery does not force an extra refresh; observers are disabled in test mode and cleaned up at termination. Debug build and unit suite pass. Physical sleep/wake/network recovery with live accounts remains unverified.

- Forced refresh requests received during an active refresh now coalesce into one follow-up pass. The monitoring epoch rejects queued work after demo transitions; normal polling does not queue redundant work, and the follow-up still honors provider throttles. Unit suite passes; live overlapping recovery-event testing remains outstanding.

- Advanced GitHub connection now tracks/cancels its task on form disappearance, clears token text, and prevents provider switching while the attempt runs. A post-Keychain cancellation check removes the new credential before account commit if cancelled. Unit suite passes; live cancellation at Keychain/network boundaries remains unverified.

- Quiet-hour boundary handles now support keyboard focus with visible outlines and source-matched Left/Down decrement, Right/Up increment, wrapping across midnight. Dragging focuses the adjusted boundary. Debug build passes. Native keyboard check verified Right 10 PM→11 PM, Up→Midnight, Left/Down→10 PM, Tab→end boundary, Right 8 AM→9 AM and Left→8 AM. Focus ring visually confirmed. Restored values and exited demo.

- Reminder regression tests now verify nearest-milestone catch-up, highest-severity ties, invalid-unit exclusion, exact/past deadline rejection, and suppression of repeated milestones when a rolling reset estimate shifts by five minutes (with a larger shift remaining eligible). Full unit suite passes.

- Alert rule regressions verify that muting one quota preserves other-window and reserve alerts, muting all windows suppresses reserve reminders, stored alerts revalidate against current mute settings, and window/account/global thresholds remain isolated. Full unit suite passes.

- Refresh scheduling now updates only after epoch/account-generation/enabled checks, so rejected old-connection results cannot alter the current connection schedule. Retry deadlines remain honored even if saving locally fails. Unit suite passes; live reconnect-during-refresh race verification remains outstanding.

- Native demo privacy check verified account names become Account in cards, timeline selector labels/help, and management tooltips; quota details omit account identity and scope while retaining usage/reset/fetch information. Exited demo to restore saved state. Live notification privacy remains unverified.

- Retention picker now matches source presets (7/30/60/90/180/365 days) and adds the current saved value, preventing an unlisted valid retention value from losing its picker selection. Debug build passes.

- Time-zone picker now binds to the resolved zone used by dates/quiet hours and includes valid aliases absent from the standard zone list. Invalid saved IDs visibly resolve to Chicago rather than producing an empty picker selection. Unit suite passes with fallback/quiet-hour and UTC coverage; native invalid-ID picker verification remains outstanding.

- Native compact-width review at about 900 points verified the wrapped header and stacked Codex/Copilot account cards, readable usage/reset labels and management controls. Today-history lines still overlap today event cards; exact source visual comparison/resolution remains open. Exited demo after review.

- Source review confirms future day markers (including Today) stay centered in calendar-day buckets while history extends to the current timestamp; arbitrary event shifts would diverge from source. Added the missing fixed % Used axis with 0/25/50/75/100 labels and a 40-point gutter in history mode. Debug build passes; native axis rendering remains to be checked.

- Native demo axis review at about 900 points verified readable 0/25/50/75/100 labels and the vertical % Used caption, aligned with the horizontal grid. Navigating back one day leaves the axis fixed while the history moves. History off removes the axis; re-enabling restores it. Saved local evidence in artifacts/history-axis-native-review.png and exited demo to restore the empty dashboard. This verifies chart presentation only, not live data accuracy.

- Added source-matched vertical day grid lines in the historical plot, using the selected time zone's calendar boundaries and stopping at the current timestamp. Debug build passes (artifacts/history-day-grid-build.log); native visual verification of these lines remains outstanding. Hosted run 41541408666 completed successfully for the preceding axis implementation at 26439c6.

- Timeline day markers now match the source: filled for event days, hollow for empty days, 16-point pale lavender Today and 10-point other markers. Explicit rail positioning fixes the previous vertical offset. Debug build passes (artifacts/timeline-markers-build.log). Native demo review verified marker alignment/fills and the preceding historical day grid at compact width; screenshot saved as artifacts/timeline-marker-native-review.png. Exited demo afterward. Live-provider verification remains separate.

- Replaced the enclosing future-event card with the source composition: 42-point bordered provider icon, overlapping plan badge (question mark when unavailable), separate time label, source colors, 62-by-74 target and 76-point row spacing starting 21 points below the rail. Debug build passes (artifacts/timeline-event-style-build.log). Native visual review of this event composition remains outstanding.

- Native demo review verified the event icon/badge/time composition and amber expiration styling at compact width. Clicking the weekly Codex event opens and closes its summary sheet; screenshot saved in artifacts/timeline-event-native-review.png. Exited demo afterward. Source MainPage.History.cs routes future events to OpenAccount(accountID, windowID), so the current summary-only sheet still needs quota/reset-detail parity; this click check does not establish behavioral parity.

- Future timeline events now open shared account usage details, matching the source routing: quota events retain their window ID, expiration events use reserve details, and historical markers keep their reported-schedule explanation. Shared details preserve privacy and identity checks and handle unavailable accounts/windows. Debug build and full unit suite pass, including a regression verifying future event window identity against the originating snapshot (artifacts/timeline-details-tests.log). Native quota/expiration sheet verification remains outstanding.

- Native demo checks now verify both future-event detail paths: the weekly Codex event displays 74% used / 26% left, its weekly reset and fetch/account information; an earned-reset expiration opens Available Resets with two reported credits and their dates. Both sheets close successfully, reserve layout is readable, and exiting demo restores the empty dashboard. Saved artifacts/timeline-reserve-details-native.png. These checks use demo data; live-provider and removed-account race coverage remain outstanding.

- Account-detail source review confirmed nil-window reserve-first routing and unavailable-window fallback. Added missing provider/account context to shared quota details and plan context to reserve details, preserving nickname masking in privacy mode. Debug build passes (artifacts/account-detail-context-build.log); native review of these additional labels remains outstanding.

- Added the source's dashed current-time boundary to the history plot and made latest-visible sample dots independent of endpoint-label visibility. The current-time line appears only when its position is inside the viewport; dots remain visible when labels are suppressed away from the right edge. Debug build passes (artifacts/history-current-time-build.log); native visual verification remains outstanding.

- Native demo review after navigating one day backward confirms the dashed current-time boundary and colored sample endpoint dots render while endpoint labels are suppressed. Saved artifacts/history-boundary-native-review.png and exited demo. Today event icons still overlap the end of the history region as previously documented; this check establishes marker rendering, not full visual parity.

- History hover now draws the source dashed sample guide and white-outlined, series-colored point. Hover clears on pointer exit, non-history/no-hit locations, scrolling and viewport updates; hidden/disabled accounts do not retain a visible guide. Removed the date-only hover fallback outside history to match source no-hit behavior. Debug build passes (artifacts/history-hover-build.log). Native pointer verification and complete source hover-detail text parity remain outstanding.

- Hover details now include provider/account/plan, weekly or monthly history context, coverage start, usage/timestamp, estimated-connection notice, and observed capacity increases with the prior/current polling timestamps. History points retain the prior observation time without inventing a reset instant. Debug build and full unit suite pass, including prior-observation regression coverage (artifacts/history-hover-details-tests.log). Native hover text/layout verification remains outstanding.

- Native hover attempt: in demo after navigating one day backward, computer-use click and short drag over visible history samples did not expose hover text or the sample guide. Chart rendered normally and demo was exited afterward. This is not a passed hover check; determine whether native pointer-event delivery or view hit testing/coordinate handling prevents the interaction before claiming parity.

- Cached hover text/sample now clears immediately when privacy, hidden history accounts, or enabled timeline account IDs change, preventing stale account names or selection details from surviving those updates. Debug build passes (artifacts/history-hover-privacy-build.log). Raising the native window did not establish hover behavior; native pointer verification remains unresolved.

- Temporary notice-level tracing at the onContinuousHover entry captured no callbacks during an automated native click over a historical sample (artifacts/hover-pointer-trace.log). This narrows investigation to event delivery/tracking, not proof of a formatting failure. Removed all temporary instrumentation and rebuilt successfully (artifacts/hover-diagnostic-clean-build.log). Requested an optional normal-mouse check; no result yet. Hosted run 41543228761 completed successfully for db933cb.

- History boundary regression verifies that 120% usage renders at zero remaining without altering the raw observation, unknown/negative usage produces no invented samples, and a subsequent valid reading is an estimated connection rather than a claimed observed replenishment. Full unit suite passes (artifacts/history-boundary-values-tests.log).

- Navigator rendering now matches source overview composition: grouped historical and future day markers, refresh/expiration rows, future markers centered in their calendar days, current-time line, six-dot selection grip, and source track/thumb colors. Drag mapping uses the inset track width; existing keyboard actions remain. Debug build passes (artifacts/timeline-overview-build.log). Native visual and drag/keyboard regression checks remain outstanding.

- Native demo navigator review verified historical markers, separate refresh/expiration rows, current-time line and six-dot grip. Accessibility Decrement moved Nov 2 to Nov 1; dragging the selection right moved the visible start to Nov 4 at 9:57 PM. Saved artifacts/timeline-overview-native-review.png and exited demo. This verifies the accessibility adjustment action and pointer drag, not physical keyboard focus behavior.

- Historical event markers now group identical timestamp/kind events with count labels, allocate nonoverlapping lanes to nearby markers, and retain exact timestamp positions. Group details include every constituent event with privacy masking and reported-schedule wording. Viewport edge filtering matches source. Debug build and full unit suite pass, including exact-time grouping, distinct kinds, nearby lanes and future exclusion (artifacts/history-marker-groups-tests.log). Native grouped-marker/detail verification remains outstanding.

- Native demo review at Oct 30 verifies nearby weekly/monthly reset and expiration markers occupy separate lanes. Opening a historical weekly reset shows provider/plan, scheduled date, reported date and the reported-schedule disclaimer; Close works. Saved artifacts/history-marker-lanes-native.png and exited demo. No duplicate-time group was present in this native check, so count-label/multiple-entry sheet rendering remains unverified beyond model tests.

- Downloaded hosted preview-29-1 (0523bab) into artifacts/downloaded-preview-29. Its relative SHA-256 checksum passes; the extracted app passes codesign --verify --deep --strict and lipo reports arm64 only. Release metadata identifies it as ad-hoc signed and not notarized. This package precedes the newest overview/historical-marker changes; download integrity is not live-provider or UI verification.

- Future event icons now follow source visibility bounds: day centers must be within the viewport margins and, in history mode, not more than 24 points behind the current-time boundary. History-off retains today's icons. Full unit suite passes with morning/evening/history-off/outside-view cases (artifacts/future-event-visibility-tests.log). Native late-day verification remains outstanding.

- History plot geometry now follows timeline height: top is rail plus 32 points, bottom is timeline height minus 8, replacing the fixed 200-point plot. Axis/grid/series/labels/current-time/hover drawing and estimated-point hit testing share the dynamic extent. Debug build and full unit suite pass, including taller-plot estimate hit testing (artifacts/history-dynamic-height-tests.log). Native multi-height verification remains outstanding.

- Native demo check paused the first Codex account, reducing the timeline to three selectors and two today-event rows. The axis/grid/data compressed together, with the zero-percent baseline retaining its bottom inset above the navigator. Saved artifacts/history-shorter-plot-native.png. Exiting demo discarded the pause change and restored the empty dashboard. Taller-than-demo account counts and pointer hover remain unverified natively.

- Added AppStore integration coverage using an isolated SQLite database with an aborting update trigger. Both failed Dismiss and failed Snooze preserve the active banner and alert state, expose an error, and leave persisted alerts/account snooze deadlines unchanged. A database-injected initializer and mutation-queue await method make the test deterministic. Full unit suite passes (artifacts/alert-save-failure-tests.log). Native notification cancellation/race behavior is not established by this failure-path test.

- AppStore queue regression now submits Dismiss and Snooze before replacing the active banner with a newer alert from the same account. Both persisted changes survive, the newer alert remains unchanged/visible, and the account deadline matches the saved alert deadline. Full unit suite passes (artifacts/alert-action-race-tests.log). This verifies application-state ordering; no native notification was delivered by the test.

- AppStore demo-isolation regression queues a real dismissal before demo entry, then a demo alert edit/snooze before exit. Exit restores the dismissed real alert, discards demo alerts/deadlines and leaves the database equal to real state. Full unit suite passes (artifacts/alert-demo-isolation-tests.log). The test uses isolated local storage and no live providers.

- Menu-bar alert severity now uses distinct native symbols (info circle, warning triangle, critical octagon), preserving the source's severity distinction without relying on color. Unavailable-data question mark and normal gauge remain. Debug build passes (artifacts/menu-severity-symbols-build.log); native status-item rendering across all states remains unverified.

- Extended the SQLite alert-save failure test through recovery: after removing the failing trigger, retrying Dismiss saves successfully and clears the old banner without persisting the failed snooze. Full unit suite passes (artifacts/alert-save-recovery-tests.log). Native menu-bar inspection via SystemUIServer timed out; status-item rendering remains unverified.

### History pointer repair (2026-11-02)

- User feedback confirmed the original hover failure with a physical mouse. Replaced the SwiftUI hover modifier with a non-interactive AppKit tracking surface sized to the full timeline. It reports top-left timeline coordinates and clears selection on exit; event buttons retain hit testing.
- Regression coverage directly invokes pointer callbacks and verifies window-to-chart coordinate conversion, exit clearing, a single tracking area after repeated layout, and non-interception of hit testing. All 67 tests pass in artifacts/history-pointer-regression-tests.log; canonical Debug build passes in artifacts/history-native-hover-build.log.
- These tests do not prove OS event delivery. Computer-use pointer attempts still showed no details. Physical-mouse verification of the replacement remains pending; do not mark hover complete.

- Native wide-history review exposed diagonal fill closures caused by Path.addLines starting a new subpath after the baseline move. History fills now explicitly connect every sample to the starting/ending baseline, matching the source polygon. Canonical Debug build passes (artifacts/history-fill-build.log); native demo screenshot confirms baseline shading without diagonal gaps (artifacts/history-fill-native-review.png).

- Endpoint-label native check: paused the synthetic Codex Personal and Copilot Work accounts to shorten the future horizon, then inspected the earliest history viewport. Claude Pro 94% and Codex Pro 58% labels appeared at the right edge with separate positions, colored outlines and connectors. Evidence: artifacts/history-endpoint-labels-native.png. Exited and reentered demo to restore all four synthetic accounts. This is a two-label visual check, not proof of dense-label collision handling.

- History reset/expiry dashed lines now draw after usage fills and strokes, matching the pinned source, and are bounded to the visible historical range. Canonical Debug build passes (artifacts/history-marker-layer-build.log). Native demo review shows lavender refresh and amber expiry dashes over the shaded plot (artifacts/history-marker-layer-native.png).

### Notification delivery integration checks (2026-11-02)

- AppStore now accepts an injectable notification-delivery service while production still uses UNUserNotificationCenter through NotificationService. Tests use no real notification requests.
- Verified permission denial retains an undelivered durable alert and its banner, successful enqueue marks delivery only after acceptance returns, and dismissal while enqueue is suspended cancels the notification and preserves dismissed/undelivered state on disk.
- All 70 unit tests and canonical Debug build pass (artifacts/notification-delivery-race-tests.log and artifacts/notification-delivery-build.log). These controlled integration checks do not establish real macOS permission prompts, delivery, or action routing.

- Native notification diagnosis: Send Test Notification produced the app error “Notifications are not allowed for this application.” System Settings → Notifications → AI Token Scrooge shows Allow notifications off (artifacts/notification-permission-off.png). No permission setting was changed. User confirmation to enable notifications and send one test is pending; current denial is a verified environment condition, not evidence of successful delivery.

- The native permission-denied error from authorization or enqueue now maps to the explicit recovery message: System Settings → Notifications → AI Token Scrooge → Allow notifications. Other error domains remain unchanged. SDK headers confirm the native error identity; regression coverage checks permission mapping and preservation of an unrelated same-number error. Canonical Debug build and all 71 tests pass. No macOS permission was changed.

- Native window-lifecycle check invoked the dashboard close action in demo with Keep Monitoring After Closing enabled. App inventory still reported Scrooge running, and subsequent app inspection showed the same four-account demo session. The automation appears to bring the dashboard back during inspection, so this establishes session survival across the close action but not independent Dock/menu reopening or live background polling. Dock inspection timed out; those checks remain open.

- Native custom-order review found the drag handles and toolbar grid icon were invisible: NSImage(systemSymbolName:) returned nil for circle.grid.2x3.fill. Replaced both with circle.grid.3x3.fill; the current macOS runtime resolves it and all 20 literal UI symbol names checked. Canonical Debug build passes (artifacts/account-drag-symbol-build.log), and native screenshot confirms visible handles (artifacts/account-drag-handles-native.png). Automated Copilot-to-Codex drag did not change order; drag/drop behavior remains unverified rather than being inferred from handle visibility.

- Installed Claude Code through the Homebrew route documented by Anthropic (https://code.claude.com/docs/en/setup). The installed binary reports 2.1.308; both Homebrew stable/latest metadata currently list that version. Ran only --version in a fresh temporary CLAUDE_CONFIG_DIR with inherited provider environment variables excluded; no authentication or inference was invoked. Version evidence: artifacts/claude-installed-version.txt.
- Claude connect now checks quota-command version support before opening browser login, so unsupported installed versions fail with update guidance before requesting credentials. The usage path retains its version guard. Canonical Debug build passes (artifacts/claude-preflight-build.log). Live Claude verification still requires a supported CLI and account.

- Native Claude preflight verified against installed 2.1.308: Add Account → Claude → temporary nickname → Sign In with Claude displayed “Update Claude Code to version 2.1.310 or later to read usage in Scrooge.” Cancel returned to the empty-account dashboard; no account was added. Screenshot: artifacts/claude-preflight-native.png. This verifies unsupported-version rejection, not live authentication or quota reading.

- Grouped-history native fixture: temporarily set the four demo history refresh timestamps to the same instant, without altering the production grouping/view code. The timeline exposed a count-4 button; clicking it listed both Codex accounts, Copilot and Claude with the shared scheduled timestamp and each reported timestamp. Scrolling reached the final entry and the reported-schedule disclaimer (artifacts/grouped-history-details-native.png). Restored Models/DemoData.swift byte-for-byte and rebuilt successfully (artifacts/grouped-history-restored-build.log); no fixture source change remains. This checks four grouped refreshes, not arbitrary group sizes or live reset occurrence.

### Native history mouse delivery follow-up — 2026-11-02

- Restored the standard four-account DemoData after the temporary eight-account inspection; no synthetic fixture modifications remain. That inspection did not complete the dense-layout acceptance gate.
- The history AppKit view now explicitly enables `acceptsMouseMovedEvents` when attached to its hosting window. This addresses a missing event-delivery prerequisite; it is not yet evidence that the user-visible hover defect is resolved.
- Canonical build passed (`artifacts/history-window-mouse-build.log`). The focused tracking lifecycle test passed (`artifacts/history-window-mouse-tests.log`), including attachment to a window initially configured not to deliver movement events.
- Reopened the app, entered the standard demo, and moved the navigator to October 31 so historical lines are available for the pending physical-pointer check. Native hover acceptance remains open.

### Preview 37 launch and selector fit — 2026-11-02

- Hosted run 41549873958 published preview-37-1 for 17f054f. Its 71-test suite had zero failures and one skipped installed-Codex test because the runner has no Codex CLI. Downloaded archive checksum, strict codesign verification and arm64 architecture passed. Signature is ad-hoc; no notarization claim.
- Launched the extracted archive and verified the running executable path points into artifacts/downloaded-preview-37/extracted. Empty dashboard and standard demo rendered with bundled artwork; evidence: artifacts/preview-37-native-launch.png. This is local launch evidence, not a clean-machine Gatekeeper test.
- Native inspection exposed a clipped final timeline selector. The stack used 12-point spacing and intrinsic heights, while the source height calculation assumes 66-point cards and 6-point spacing. Matched those source constants in the SwiftUI selector stack. Canonical build passed (artifacts/history-selector-layout-build.log); native screenshot confirms all four cards now fit completely (artifacts/history-selector-layout-native.png). Dense eight-account acceptance remains open.

### Eight-account selector access — 2026-11-02

- On 71a4aeb, temporarily duplicated the four demo account configurations with distinct IDs and Two-suffixed nicknames. No view or height-calculation changes were made for the fixture.
- Native accessibility exposed all eight selectors. Scrolling the main dashboard exposed the complete eighth card and navigator; clicking Claude Personal Two removed its selected state. Navigator Decrement changed the visible start from November 2 to November 1. Evidence: artifacts/eight-selectors-lower-native.png and artifacts/eight-selectors-upper-native.png.
- This verifies eight-account selector and navigation access at the current wide window, not dense endpoint labels or compact-window parity.
- Restored Models/DemoData.swift byte-for-byte to the standard fixture. Both fixture and restored canonical builds passed (artifacts/eight-selectors-build.log and artifacts/eight-selectors-restored-build.log).

### Compact standard dashboard — 2026-11-02

- Tested production code at 71a4aeb with standard four-account demo, using macOS Window > Move & Resize > Left. Screenshot width was 1722 pixels (near the 860-point app minimum on this Retina display). Native edge dragging did not resize; the native menu did.
- Header wrapped into two rows; timeline heading, history switch, settings button, all four account selectors and navigator fit. Account cards reflowed vertically while keeping quota labels, percentages, reset dates, thresholds, alert buttons, reorder handles and management buttons visible. Clicking the first session quota bar opened a details popover showing 38% used / 62% left and the demo identity.
- Evidence: artifacts/compact-timeline-native.png and artifacts/compact-account-cards-native.png. Restored previous window size via the native menu and returned to the top. This check covers the standard four-account layout, not the eight-account compact combination or every settings sheet.

### Dense endpoints and eight-account compact layout — 2026-11-02

- Temporary eight-account fixture duplicated the standard configurations and shortened future Copilot/reserve dates to expose the current endpoints at the earliest history viewport. Wide native screenshot shows all eight labels separated: duplicate pairs of Pro94, Max82, Plus74 and Pro58 (artifacts/dense-endpoints-upper-native.png).
- At 1722-pixel compact width, all eight selectors and navigator remain accessible by main-dashboard scrolling (artifacts/eight-compact-lower-native.png). Today event icons overlap some endpoint labels (artifacts/dense-endpoints-compact-native.png). This is a visible limitation, not a clean visual pass. The pinned HistoryTimelineView.LayoutEvents uses the same day-center position and TodayX minus24 visibility tolerance as HorizonViewport.showsFutureEvents; no unrequested divergence was introduced.
- Restored prior window size and standard DemoData byte-for-byte. Fixture and restored builds passed (artifacts/dense-endpoints-build.log, artifacts/dense-endpoints-restored-build.log).

### Severity banner appearance and privacy — 2026-11-02

- Temporarily composed three unchanged production AlertBannerView instances over the demo dashboard, with synthetic info/Codex, warning/Copilot and critical/Claude events. Native screenshot confirms blue/yellow/red heading and border accents, matching provider icons, and all three action labels (artifacts/alert-severities-native.png). The stacked composition was fixture-only; production shows one active banner.
- Enabled Privacy Mode in demo settings: native accessibility returned Account Details Hidden for all three banners, replacing each synthetic detail (artifacts/alert-severities-privacy-native.png). This is appearance/privacy evidence only; fixture IDs were not persisted and action lifecycle or OS delivery was not tested here.
- Restored DashboardView.swift byte-for-byte. Fixture and restored canonical builds passed (artifacts/alert-appearance-fixture-build.log and artifacts/alert-appearance-restored-build.log). Menu-bar severity states remain unverified.

### Window close process lifetime — 2026-11-02

- Standard app code at 71a4aeb, demo session, process PID70233. Native close button with default Keep Monitoring After Closing enabled left PID70233 alive, verified using ps before asking computer use to inspect/reopen the app. Subsequent dashboard inspection retained the same demo session.
- In demo settings, unchecked Keep Monitoring After Closing, closed Settings, then clicked the native dashboard close button. ps for PID70233 returned no process (exit1), before any app reacquisition. This verifies the disabled preference terminates after the last window closes.
- Reopened the app through computer use and observed the normal signed-out dashboard. Demo-only preference change was not persisted. No source change required. This does not prove actual Dock/menu activation or background live quota refresh.

### Selected app-code preview verification — 2026-11-02

- Preview38 / run41550639905 targets 71a4aeb, the latest application-code commit. Subsequent commits only document acceptance evidence. Hosted tests: 71 total, one installed-Codex skip on the runner, zero failures.
- Downloaded mac-preview artifact to artifacts/downloaded-preview-38; SHA256 manifest check, strict codesign verification and arm64 architecture passed. Launched extracted app and verified PID70742 executable path points into that extraction. Standard demo opened with four selectors; navigator moved to November1. Evidence: artifacts/preview-38-native-launch.png and artifacts/preview-38-ci.log.
- Ad-hoc development preview, not notarized; local launch is not clean-machine Gatekeeper proof. Remaining live/OS/physical-input gates stay open in acceptance.md.

### Authorized native notification test — 2026-11-03

- User explicitly approved Enable and test notifications. In System Settings > Notifications > AI Token Scrooge, switched Allow notifications from off to on and verified the on state. Existing Desktop/Notification Center/Lock Screen selections and Temporary alert style were preserved. Evidence: artifacts/notification-permission-enabled.png.
- Using running downloaded Preview38 in demo mode, clicked Send Test Notification exactly once. In-app test banner appeared; Alert History reports Scrooge Notification Test at November3 11:44AM with Sent to macOS. Evidence: artifacts/notification-test-sent-macos.png. No permission-denied error appeared.
- This proves native submission accepted by macOS, not visible OS presentation or notification action callbacks. Computer-use access to Notification Center exposed its calendar widget rather than the notification list; visibility remains unverified. No application code changed.

### Supported Claude CLI Installed — 2026-11-05

Homebrew refreshed package metadata and advertised Claude Code2.1.311 from downloads.claude.ai, with2.1.308 installed. Upgraded the existing claude-code cask successfully; log artifacts/claude-upgrade.log, package metadata artifacts/claude-current-package-info.json. Repeated Scrooge’s executable preference order and selected /opt/homebrew/bin/claude. Running only --version with a fresh temporary CLAUDE_CONFIG_DIR and an environment limited to HOME/PATH/TMPDIR/LANG reports2.1.311 (Claude Code); evidence artifacts/claude-upgraded-version.txt. This meets the app’s >=2.1.310 guard. No login, quota command or inference was invoked, and no provider credentials were read.

The previous unsupported-version blocker is resolved. Live Claude authentication, quota correctness and logout remain unverified. This is an environment-only update; no application source or build changed.

### Current Downloaded Preview272 Verified — 2026-11-05

GitHub run42122375440 completed and published preview-272-1 targeting45b236458d6f626057a43edd841c7ebb36fed6e8. Hosted97 tests passed with zero failures and one installed-Codex skip because the runner lacks that CLI. Downloaded release assets into artifacts/downloaded-preview-272. SHA256 f40591900a8e6a6f787cda463574e5eb9501b874cc08c4654034347ca95a0013 matches the manifest; strict deep codesign and arm64 checks pass. All25 source font/image/sound assets match the extracted app byte-for-byte.

Launched the extracted app with isolated compact demo data, verified process84611 executable path inside that extraction, and observed the dashboard, allfour account selectors, timeline and selected Custom Order state. Screenshot artifacts/preview-272-native-launch.jpg; hosted evidence artifacts/preview-272-ci.log. Release https://github.com/lancelarsen/AI-Token-Scrooge-Mac/releases/tag/preview-272-1. This verifies the current application source in a downloaded preview, not full UI/live-provider parity. Ad-hoc signed, hardened runtime disabled, not notarized; no clean-machine Gatekeeper claim.

### Installed Claude Signed-Out Isolation Regression — 2026-11-05

Added an installed-CLI integration test analogous to the existing Codex isolation test. It creates a fresh app-owned Claude profile, uses the production sanitized environment and executable selection, and invokes only auth status through BoundedProcess. A success response must explicitly report loggedIn=false and no email; the CLI's nonzero signed-out path must map to authenticationRequired. Temporary profile cleanup runs afterward. The test skips when Claude is absent and never calls login, usage or inference. Assertions do not print account identities.

All98 hosted local tests pass with installed Claude2.1.311 (artifacts/claude-isolated-auth-tests.log). After making the no-email assertion privacy-preserving, the focused installed-Claude test also passes (artifacts/claude-isolated-auth-focused.log). This checks signed-out isolation, not live subscription authentication, refresh or logout. Application source is unchanged, so Preview272 remains the current app-source archive.

### Missing reset schedules across providers — November 7

Native reproduction: in the `no-reset` demo, hide both OpenAI accounts and Claude so only GitHub Copilot remains selected. Before this fix, Reset Horizon showed `Quota Refresh (0)` despite the monthly quota having no reported reset timestamp. The completeness check had been restricted to Codex/Claude.

Moved refresh coverage into a pure shared policy for every provider: absent or mismatched snapshots, empty quota windows, omitted expected Codex/Claude periods, or a missing reset timestamp qualify the count as incomplete. Known schedules remain complete even when usage is zero. After the change, the same native Copilot-only fixture shows `Quota Refresh (Not reported) Reset Expires (0)` (`artifacts/copilot-missing-reset-qualified.jpg`). This extends the user's requested missing-versus-zero distinction; no reset date or quota window is synthesized.

Canonical app and test-bundle builds passed. An optimized executable compiled production model sources and checked zero usage, missing dates, empty windows, changed identity and absent snapshots for OpenAI, GitHub Copilot, Claude and Devin (`artifacts/refresh-coverage-check.log`). The equivalent hosted regression is compiled; native/hosted XCTest execution is not claimed while the macOS automation authentication request remains pending. The history fixture's refresh/expiry arithmetic was also compared with Windows `HistoryDemo.cs` at eb042cb; no fixture math change was needed.

### Claude percentage token integrity — November 7

Production-parser reproduction found that `1,000% used` and `1,00% used` were interpreted as 0%, and Unicode-minus `−5% used` was interpreted as 5%. Require a complete whitespace-delimited ASCII percentage token instead of accepting a numeric suffix. Malformed session values stay unreported while a separate valid weekly zero remains available. The regression covers twelve malformed tokens (including Unicode signs and slash/label prefixes), genuine zero and a percentage following a progress bar. No quota request or inference is used by these checks.

An optimized executable compiled the production model/parser sources and passed malformed-token, independent-window and valid 0/24/62.5/100 assertions. Canonical build/run and test-bundle compilation were checked. The new hosted XCTest regression is not claimed executed locally while the macOS automation-authentication request is pending. Live signed-in Claude verification remains open.

### Reminder choices during validation — November 7

Matched Windows' draft behavior: severity and unit choices remain visible while the amount is temporarily invalid, then join the accepted update once it is valid. Native isolated0/Hours/Warning ->2/Hours/Warning trace, invalid Close rejection, sorted-row identity and Close/reopen retention passed. Build and UI-test-bundle compilation passed; the added native regression remains execution-gated by macOS authorization.

### Normal scrolling confirmation and color-input drafts — November 7

User confirmed Reset Horizon scrolling is “Smooth now.” Normal perceived scrolling is accepted; unrelated hover/reorder/long-session checks remain separately tracked.

Color numeric inputs now retain invalid/empty drafts without clamping the accepted color and restore the last valid displayed value on blur. RGB/HSV clear actions and three-character numeric limits match the native control. Corrected opaque Hex behavior from the earlier last-color assumption: Windows keeps the # prefix, resolves cleared/malformed Hex to black, and interprets short Hex as an integer (#12 -> #000012). Native trace and source conversion helper establish this behavior. Focus changes no longer re-decode unchanged rounded strings and shift HSV coordinates.


November7 RGB/Hex input constraint: pinned Windows run42381576873 confirms #FF0001 and RGB255,0,1 resolve to#FF0004 after the default359-degree HSV bound. Mac now applies that same edit-time constraint and retains fractional HSV through byte rounding. Seven captured edge/primary/gray model vectors, canonical app/test-bundle builds and actual isolated native Hex/Blue/HSV/Cancel checks passed. Native XCTest execution remains OS-auth-gated; see visual-parity-audit.md for scope and remaining picker states.
