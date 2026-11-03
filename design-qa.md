# Windows screenshot comparison

Final result: passed for the requested screenshot correction pass.

## Scope and references
Compared all three published Windows screenshots in `.reference/docs/images`: `dashboard.png`, `accounts.png`, and `settings.png`. Native macOS window chrome, system font, and system controls are retained. This is visual alignment of those screens, not a claim of completion of the separate live-provider acceptance backlog.

## Corrections and evidence
| Screen | Corrections | Rendered evidence |
| --- | --- | --- |
| Dashboard | Overlapping nickname/plan/check selector badges; neutral legend labels and colored dots; inline History control and navigation hint; action sizing; sort dividers | `artifacts/dashboard-history-parity.png` |
| Account rows | Paired alert buttons; provider separator; dark-bordered threshold markers; reminder-colored clocks; date alignment; top-aligned settings gears | `artifacts/accounts-aligned.png` |
| Settings | 1000 x 800 default window; reference section order, spacing and insets; right-aligned switches; full-width time-zone menu; four labeled sound-preview buttons in the reference order | `artifacts/settings-menu-fixed.png` |

Reference and implementation captures were inspected together, accounting for the Mac's 2x screenshot density. Dashboard history was moved five days back to compare the same relative history position. Demo dates and event positions reflect the current date rather than the October 31 Windows capture.

## Interaction and regression checks
- Row alert off/on controls selected the correct segment; disabling removed the three threshold controls and enabling restored them.
- Time-zone menu rendered at full width and opened choices directly, without an extra submenu; dismissed without changing the zone.
- Timeline navigator moved through five prior days and rendered history/reset markers.
- Compact 861-point window: header and account rows reflowed; quota controls and countdowns remained within the cards. The timeline remains horizontally scrollable. Evidence: `artifacts/compact-parity-current.png`, `artifacts/compact-accounts-parity.png`.
- Canonical build passed: `artifacts/settings-menu-build.log`.
- All 71 ScroogeTests passed, zero failures: `artifacts/visual-parity-tests.log`.
- `git diff --check` passed.

## Remaining minor visual differences
Native SF typography is heavier than Windows Segoe UI and system switches differ. Horizon vertical spacing differs by approximately 10 points. These are minor polish differences; no blocking layout defects were observed in the compared views. Live authentication, audible playback, and physical-pointer hover acceptance are outside this screenshot pass and retain their existing status in `tasks/acceptance.md`.
