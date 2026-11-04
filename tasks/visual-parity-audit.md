# Windows Visual Parity Audit

Reference: Windows commit `5a88731`, November 4 conversion-for-mac pack. Source snapshot is extracted under ignored artifacts/windows-reference/source-snapshot. All 37 original PNGs are available locally.

Acceptance requires individual inspection and equivalent Mac captures; a successful build alone is not visual proof. Native macOS chrome and system-font metrics follow the reference guide's permitted adaptations.

| Image | Inspection | Findings / Verification |
| --- | --- | --- |
| 01-live-dashboard.png | Pending | Awaiting detailed inspection and Mac comparison |
| 02-settings-updates-time-retention.png | Inspected | Inspected: global Settings must be a centered panel with scrolling cards; current Mac separate window needs review. |
| 03-settings-sounds-quiet-hours.png | Pending | Awaiting detailed inspection and Mac comparison |
| 04-settings-thresholds.png | Pending | Awaiting detailed inspection and Mac comparison |
| 05-settings-reset-reminders.png | Pending | Awaiting detailed inspection and Mac comparison |
| 06-settings-refresh-reminders.png | Pending | Awaiting detailed inspection and Mac comparison |
| 07-settings-app-behavior.png | Pending | Awaiting detailed inspection and Mac comparison |
| 08-alert-history.png | Pending | Awaiting detailed inspection and Mac comparison |
| 09-demo-history-on.png | Inspected | Inspected: compare logical dimensions at 1463-wide baseline; preserve native title bar. |
| 10-demo-history-off.png | Pending | Awaiting detailed inspection and Mac comparison |
| 11-demo-filter-off-tooltip.png | Pending | Awaiting detailed inspection and Mac comparison |
| 12-demo-all-capacity-levels.png | Pending | Awaiting detailed inspection and Mac comparison |
| 13-usage-details.png | Pending | Awaiting detailed inspection and Mac comparison |
| 14-account-settings.png | Inspected | Inspected: account header should identify provider/account/plan; swatch outline and form columns differ. |
| 15-custom-color-chooser.png | Pending | Awaiting detailed inspection and Mac comparison |
| 16-custom-color-added.png | Pending | Awaiting detailed inspection and Mac comparison |
| 17-polling-snapped.png | Pending | Awaiting detailed inspection and Mac comparison |
| 18-account-connection-actions.png | Pending | Awaiting detailed inspection and Mac comparison |
| 19-first-launch.png | Pending | Awaiting detailed inspection and Mac comparison |
| 20-provider-chooser.png | Pending | Awaiting detailed inspection and Mac comparison |
| 21-connect-codex.png | Pending | Awaiting detailed inspection and Mac comparison |
| 22-connect-github-browser.png | Pending | Awaiting detailed inspection and Mac comparison |
| 23-connect-github-advanced.png | Pending | Awaiting detailed inspection and Mac comparison |
| 24-compact-empty.png | Pending | Awaiting detailed inspection and Mac comparison |
| 25-connect-claude.png | Pending | Awaiting detailed inspection and Mac comparison |
| 26-compact-dashboard.png | Inspected | Inspected: compact timeline keeps legends on first row and History/hint on second; corrected Mac wrapping, awaiting compact capture. |
| 27-compact-account-rows.png | Pending | Awaiting detailed inspection and Mac comparison |
| 28-compact-account-settings.png | Pending | Awaiting detailed inspection and Mac comparison |
| 29-compact-tooltip-placement.png | Pending | Awaiting detailed inspection and Mac comparison |
| 30-polling-tooltip.png | Pending | Awaiting detailed inspection and Mac comparison |
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
