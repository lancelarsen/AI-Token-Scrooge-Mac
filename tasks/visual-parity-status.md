# Current screenshot parity status

Reference image integrity checked against Windows `origin/main` at `694dc85`. All 37 local PNGs are byte-identical to GitHub. Dimensions below come from PNG headers; the pack manifest contains invalid dimension values and is not used for sizing.

**No image is certified identical.** Every row remains partial or unverified. Builds verify compilation, not visual identity. Prior captures may predate shared-control changes and need final recapture.

Repeatable captures: `--demo --compact` (789×694 points) and `--demo --reference-wide` (1463×866 points), both verified by native screenshots.

Cross-cutting open requirements: Segoe UI font assets/metrics; exact Segoe Fluent glyph shapes; matching window dimensions; popup captures and positioning; final per-image comparisons after shared changes. User question about an app-licensed Segoe UI bundle is pending.

| Reference | PNG pixels | Current evidence / next check |
| --- | --- | --- |
| 01-live-dashboard.png | 11010048 × 4292542531 | Live-provider equivalent capture missing. |
| 02-settings-updates-time-retention.png | 11010048 × 4292542531 | Wide demo top sections captured; inherited palette corrected; live update-available and post-change pixel checks needed. |
| 03-settings-sounds-quiet-hours.png | 11010048 × 4292542531 | Wide sounds/quiet-hours captured; radio selection, keyboard/equal-time summaries, close labels and end-handle drag checked; playback, overnight/disabled states and exact pixels remain open. |
| 04-settings-thresholds.png | 11010048 × 4292542531 | Threshold controls revised; matching global-settings capture needed. |
| 05-settings-reset-reminders.png | 11010048 × 4292542531 | Validation and ordering checked; matching reminder-list capture needed. |
| 06-settings-refresh-reminders.png | 11010048 × 4292542531 | Validation and ordering checked; matching reminder-list capture needed. |
| 07-settings-app-behavior.png | 11010048 × 4292542531 | Behavior section seen during native navigation; exact layout comparison pending. |
| 08-alert-history.png | 11010048 × 4292542531 | Populated demo captured; 80-point rows and 16-point gaps checked; matching-width capture needed. |
| 09-demo-history-on.png | 11010048 × 4292542531 | Timeline geometry revised; fresh wide equivalent capture needed. |
| 10-demo-history-off.png | 11010048 × 4292542531 | Wide History-off captured at matching size; date/font and switch-hover differences remain. |
| 11-demo-filter-off-tooltip.png | 11010048 × 4292542531 | Wide filter-off captured; event counts and corrected per-element selector colors checked; floating tooltip capture needed. |
| 12-demo-all-capacity-levels.png | 11010048 × 4292542531 | Scenario fixtures available; equivalent capacity-level capture needed. |
| 13-usage-details.png | 11010048 × 4292542531 | Unknown-usage popup checked; standard and nonpercent captures need recheck. |
| 14-account-settings.png | 11010048 × 4292542531 | Compact account panel captured; matching wide panel needed. |
| 15-custom-color-chooser.png | 11010048 × 4292542531 | Picker captured; footer and synchronization checked; spectrum/ring pixels remain different. |
| 16-custom-color-added.png | 11010048 × 4292542531 | Orange custom swatch added and retained after reopening; exact comparison pending. |
| 17-polling-snapped.png | 11010048 × 4292542531 | Polling control seen; endpoint and snapped pointer capture needed. |
| 18-account-connection-actions.png | 11010048 × 4292542531 | Connection section source-reviewed; matching capture needed. |
| 19-first-launch.png | 11010048 × 4292542531 | Isolated empty dashboard captured; horizontal coordinates checked; matching width needed. |
| 20-provider-chooser.png | 11010048 × 4292542531 | Chooser captured; border and dimensions checked; text metrics differ. |
| 21-connect-codex.png | 11010048 × 4292542531 | Codex form captured after typography change; exact metrics differ. |
| 22-connect-github-browser.png | 11010048 × 4292542531 | GitHub browser form captured; zero validation checked; exact metrics differ. |
| 23-connect-github-advanced.png | 11010048 × 4292542531 | Advanced form captured; dummy token mode reset checked; exact metrics differ. |
| 24-compact-empty.png | 11010048 × 4292542531 | Empty geometry revised; fresh compact equivalent capture needed. |
| 25-connect-claude.png | 11010048 × 4292542531 | Claude form captured with complete version requirement; exact metrics differ. |
| 26-compact-dashboard.png | 11010048 × 4292542531 | Compact dashboard captured; rail x/y alignment checked; full fresh comparison needed. |
| 27-compact-account-rows.png | 11010048 × 4292542531 | Compact rows captured; threshold inset and pointer movement checked; fonts differ. |
| 28-compact-account-settings.png | 11010048 × 4292542531 | Account panel captured after inset/swatch fixes; vertical metrics differ. |
| 29-compact-tooltip-placement.png | 11010048 × 4292542531 | Owner-window clamping implemented; floating tooltip capture missing. |
| 30-polling-tooltip.png | 11010048 × 4292542531 | Complete polling help shared; floating tooltip capture missing. |
| 31-compact-global-settings.png | 11010048 × 4292542531 | Global card inset/background revised; fresh compact capture needed. |
| 32-notification-banner.png | 11010048 × 4292542531 | Test banner captured; approximate dimensions checked; text metrics differ. |
| 33-quota-alerts-muted.png | 11010048 × 4292542531 | Alert toggle tooltips revised; muted-state equivalent capture needed. |
| 34-threshold-drag-feedback.png | 11010048 × 4292542531 | Native threshold grab/drag and keyboard checked; floating readout capture missing. |
| 35-earned-reset-details.png | 11010048 × 4292542531 | Reset details source-reviewed; equivalent popup capture needs recheck. |
| 36-timeline-event-tooltip.png | 11010048 × 4292542531 | Event details and click action checked; floating tooltip capture missing. |
| 37-history-sample-readout.png | 11010048 × 4292542531 | History readout source/keyboard checked; equivalent floating readout capture missing. |

Detailed implementation and validation evidence: [visual-parity-audit.md](visual-parity-audit.md). This status replaces its original summary table; chronological evidence there remains useful.
