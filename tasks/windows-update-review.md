# Windows update and interaction review — November 3, 2026

Compared pinned Windows `3d0330b` with fetched `origin/main` `fc37458` (108 changed files). The substantial updates are `a769879` (credential hardening and dashboard/settings), `fd0e1f0` (Windows test fixtures), and `fc37458` (date versions and updater). Earlier intermediate commits document privacy/storage. The reference checkout remains pinned; review uses Git objects from origin/main.

## Corrected in this update
- Windows HistoryChartInput.Show uses a floating, noninteractive popup near the pointer, clamped to the screen. Mac previously inserted text below the navigator, changing card height. Replaced that block with an AppKit panel, including hide-on-exit and disposal, screen clamping, and title/detail styling.
- Reuse the existing Windows SVG assets for alarm on/off, refresh, and settings instead of approximate SF Symbols.
- Match the six hollow-dot reorder grip and rectangular remaining-capacity indicators from Windows ActionButton, replacing nine-dot and battery symbols.

## Relevant changes still requiring a Mac port
| Priority | Windows change | Mac finding / recommended action |
| --- | --- | --- |
| High | CLI environment sanitization across all providers, node runtime injection variables, and cloud credential variables | Codex and Claude currently strip only their own provider prefixes. Port the shared sanitizer and regression tests. |
| High | Pending-credential journal before starting sign-in, owned profile path validation, redirected-path rejection | Mac has retired-account cleanup and Keychain, but not the equivalent staged credential journal or complete owned-directory validation. Audit and port these with failure/recovery tests. Windows ACL/DPAPI code itself is platform-specific. |
| Medium | Selector filters affect history AND future resets/refreshes; History switch hides only graph, preserving rail geometry | Mac selectors currently filter history only; events are unfiltered and axis geometry changes with History. Port the new filter semantics and tests. |
| Medium | New-install defaults: sound on, quiet hours on from midnight to 8 AM, custom account order | Mac still uses older defaults. Change defaults without overwriting existing saved choices; add migration tests. |
| Medium | Date-based versioning, Settings update card, periodic/manual checks, verified download/restart | Mac remains 0.1.0/build 1 with preview-number releases, no updater. Needs a Mac-specific release/version/update design targeting AI-Token-Scrooge-Mac assets, signed/notarized distribution, and rollback/data preservation. Do not transplant the Windows ZIP launcher. |
| Medium | History popup click-to-pin and keyboard sample inspection, Escape dismissal | Floating hover is now corrected; native history sample keyboard navigation and pinning are still missing and need a dedicated interaction pass. |
| Low | Settings help cleanup, quiet-range disable/dim behavior, revised field layouts | Current controls are functional but do not yet reflect every new Windows layout/state detail. |

## Already present / platform-specific
- Custom color picker and saved palette: AccountSettingsView and RadarSettings.customColors already implement this.
- One-minute polling slider: native MinuteSlider already exists.
- Staged load / prevent saves before load: AppStore.localStateReady guards mutation/monitoring; LocalStore loads the aggregate state.
- Keychain replaces Windows secret encryption; do not replace it with DPAPI.
- Elevated Windows credential fixture fixes and Windows launcher/startup code are not directly portable.
- Alert separator text already uses proper middle dots in the Mac implementation.

## Scope limits
This is a source-backed porting review, not a full security audit or a claim of complete functional parity. Windows also uses Segoe Fluent glyphs for some platform controls; the exact reusable image assets and explicit custom geometry above are matched, while remaining native system glyphs may differ.

## Verification for this commit
- Canonical build passed; full suite: 72 tests, zero failures.
- Native popup regression test creates the panel, verifies its visible bounded width and noninteractive behavior, then verifies hiding on pointer exit.
- Native demo screenshot inspection confirmed the SVG bell/refresh/settings icons and custom grip/meter shapes render correctly.
- A fresh physical-pointer pass over chart lines is still recommended; the popup was exercised directly in the native regression test rather than claiming a physical hover capture.

## Implementation progress
- Batch 1: shared provider environment sanitization implemented for Codex and Claude. Also removes macOS DYLD injection variables, while preserving ordinary OS environment values. Regression coverage verifies cross-provider secrets, cloud credential paths, and runtime injection hooks are removed.
- Correction to review: HorizonEvent.events already filters hidden accounts. Remaining timeline work is stable geometry and History-off behavior, not reimplementing future-event filtering.
- Batch 2: new-install sound/quiet-hours/custom-order defaults now match Windows; explicit saved preferences are preserved. Quiet-range controls disable/dim when off. History-off retains axis space and selector-driven height, with a contextual filter hint. Build and all 74 tests passed, including saved-preference migration and existing future-event filtering coverage. Updated overnight/snooze fixtures to specify their quiet-hours policy independently of defaults.
- Batch 3: sign-in now durably stages provider/credential cleanup intent before CLI authentication or Keychain writes, using the existing retirement journal. Successful account adoption clears that record in the same database transaction; interrupted attempts remain recoverable after restart. Active attempts are excluded from background cleanup. Provider directories require UUID paths, current-user ownership, private folder permissions, and no symbolic links or special files in the owned tree. Logout precedes profile removal. Keychain remains the secret store; no plaintext credential journal is introduced. Canonical build and 76 tests passed, including restart recovery, atomic adoption, symlink rejection, private permissions, and preservation of an outside file. Live provider sign-in/logout still requires a real account pass. These checks do not claim protection against a malicious process already running as the same user racing filesystem operations.
- Batch 4: chart clicks pin sample details; focused chart Left/Right inspect recorded samples and Escape dismisses. Selected details are also exposed to accessibility. Pointer exit preserves pinned details; toggling History/privacy/account filters clears them. History-off retains reported event markers and applies the same current-time boundary to future icons. Build and 76 tests passed; native demo keyboard input selected a Claude sample and Escape returned accessibility details to “No sample selected.” Popup visibility/lifecycle is covered by native panel tests; the main-window screenshot API does not include separate floating panels.
