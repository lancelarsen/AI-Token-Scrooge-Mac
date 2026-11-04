# Windows Visual Parity Audit

Reference: Windows commit `5a88731`, November 4 conversion-for-mac pack. Source snapshot is extracted under ignored artifacts/windows-reference/source-snapshot. All 37 original PNGs are available locally.

Acceptance requires individual inspection and equivalent Mac captures; a successful build alone is not visual proof. Native macOS chrome and system-font metrics follow the reference guide's permitted adaptations.

| Image | Inspection | Findings / Verification |
| --- | --- | --- |
| 01-live-dashboard.png | Pending | Awaiting detailed inspection and Mac comparison |
| 02-settings-updates-time-retention.png | Inspected | Inspected: global Settings must be a centered panel with scrolling cards; current Mac separate window needs review. |
| 03-settings-sounds-quiet-hours.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 04-settings-thresholds.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 05-settings-reset-reminders.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 06-settings-refresh-reminders.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 07-settings-app-behavior.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 08-alert-history.png | Pending | Awaiting detailed inspection and Mac comparison |
| 09-demo-history-on.png | Inspected | Inspected: compare logical dimensions at 1463-wide baseline; preserve native title bar. |
| 10-demo-history-off.png | Pending | Awaiting detailed inspection and Mac comparison |
| 11-demo-filter-off-tooltip.png | Pending | Awaiting detailed inspection and Mac comparison |
| 12-demo-all-capacity-levels.png | Pending | Awaiting detailed inspection and Mac comparison |
| 13-usage-details.png | Pending | Awaiting detailed inspection and Mac comparison |
| 14-account-settings.png | Inspected | Inspected: account header should identify provider/account/plan; swatch outline and form columns differ. |
| 15-custom-color-chooser.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 16-custom-color-added.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 17-polling-snapped.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 18-account-connection-actions.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 19-first-launch.png | Pending | Awaiting detailed inspection and Mac comparison |
| 20-provider-chooser.png | Pending | Awaiting detailed inspection and Mac comparison |
| 21-connect-codex.png | Pending | Awaiting detailed inspection and Mac comparison |
| 22-connect-github-browser.png | Pending | Awaiting detailed inspection and Mac comparison |
| 23-connect-github-advanced.png | Pending | Awaiting detailed inspection and Mac comparison |
| 24-compact-empty.png | Pending | Awaiting detailed inspection and Mac comparison |
| 25-connect-claude.png | Pending | Awaiting detailed inspection and Mac comparison |
| 26-compact-dashboard.png | Inspected | Inspected: compact timeline keeps legends on first row and History/hint on second; corrected Mac wrapping, awaiting compact capture. |
| 27-compact-account-rows.png | Pending | Awaiting detailed inspection and Mac comparison |
| 28-compact-account-settings.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 29-compact-tooltip-placement.png | Pending | Awaiting detailed inspection and Mac comparison |
| 30-polling-tooltip.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 31-compact-global-settings.png | Pending | Awaiting detailed inspection and Mac comparison |
| 32-notification-banner.png | Pending | Awaiting detailed inspection and Mac comparison |
| 33-quota-alerts-muted.png | Pending | Awaiting detailed inspection and Mac comparison |
| 34-threshold-drag-feedback.png | Pending | Awaiting detailed inspection and Mac comparison |
| 35-earned-reset-details.png | Pending | Awaiting detailed inspection and Mac comparison |
| 36-timeline-event-tooltip.png | Pending | Awaiting detailed inspection and Mac comparison |
| 37-history-sample-readout.png | Pending | Awaiting detailed inspection and Mac comparison |

## Source-Confirmed Corrections

- Account card breakpoint: 1050 logical units of card width, replacing the unrelated 1200 window-width threshold.
- Compact timeline header: legends remain beside heading; History and contextual hint wrap beneath.

The supplied capture manifest contains invalid dimensions; use PNG headers for actual pixel sizes.

## Account Settings Pass

Provider/account/plan heading, two-column name/color form, selected swatch border, switch-style alert controls, compact reserve summary and full-width connection actions now follow the reference. Panel targets 1000 x 800 with host-window limits. Canonical build passed; equivalent Mac desktop/compact captures, exact slider styling and custom-color wrapper remain to verify.

## Account Control Rendering Verification

Mac desktop demo inspected after build: switches now align to the right with 40 x 20 purple tracks and 12-point dark thumbs. Polling slider follows captured MinuteEditor.cs: 4-point rail, 30 twelve-point ticks, 20-point outer/10-point inner thumb, 14-point endpoint insets. Accessibility increment changed 2 to 3 minutes; decrement restored 2. Alert switch toggled off and on successfully. Expiry labels now use palette amber. Build passed. Remaining: help icons, exact card/header spacing, compact sizing, pointer/keyboard slider checks and color dialog comparison. This is partial visual verification, not full account-panel parity.

## Global Settings Controls Pass

Inspected images 03–07 individually. Applied reference switch styling to global settings, reordered behavior switches, expanded behavior actions with icons, and reordered reminder rows to severity / amount / unit / delete. Reminder menus now use severity colors and 44-point controls; add button aligns left. Canonical build passed. Rendered global settings comparison and editable reminder interaction verification remain pending, along with quiet-hours geometry, slider styling and panel presentation.

## Quiet Hours Reference Geometry

Replaced midnight-to-11-PM axis with reference noon-to-noon scale, 32-point track insets, 6-point range, 24-point handles, five 16-point labels, 94/116-point track heights and staggered near-overlap time labels. Added duration/overnight summary and moved the enable switch into the section heading. Canonical build passed. Inspected the disabled 10 PM–8 AM range on Mac: placement and summary render correctly. Enabled dragging, keyboard behavior and overlap states still require runtime verification; final heading-switch placement is build-verified only.

## Percentage Slider Pass

Volume and threshold sliders now use 4-point colored rails and 20-point outer/10-point inner thumbs rather than native gray controls. Threshold labels include Alert and use blue/yellow/red severity colors. Volume rendered in purple during runtime inspection. That inspection also exposed a hidden-label layout expansion in the quiet-hours heading; the switch style now explicitly omits the visual label for header controls. Final canonical build passed. Final heading rendering, threshold rendering and pointer/keyboard interaction checks remain pending.
