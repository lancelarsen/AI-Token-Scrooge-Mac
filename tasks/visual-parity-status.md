# Current screenshot parity status

Reference image integrity checked against Windows `origin/main` at `694dc85`. All 37 local image files are byte-identical to GitHub. The files have .png names but contain JPEG data. Dimensions below are decoded image sizes; the previous PNG-header interpretation was invalid.

**No image is certified identical.** Every row remains partial or unverified. Builds verify compilation, not visual identity. Prior captures may predate shared-control changes and need final recapture.

Repeatable captures: `--demo --compact` (789×694 points) and `--demo --reference-wide` (1463×866 points), both verified by native screenshots.

Cross-cutting open requirements: Segoe UI font assets/metrics; exact Segoe Fluent glyph shapes; final captures at matching window dimensions; popup captures and positioning; final per-image comparisons after shared changes. User question about an app-licensed Segoe UI bundle is pending.

| Reference | Image pixels | Current evidence / next check |
| --- | --- | --- |
| 01-live-dashboard.png | 1463 × 866 | Live-provider equivalent capture missing. |
| 02-settings-updates-time-retention.png | 1463 × 866 | Wide demo top sections captured; inherited palette corrected; live update-available and final pixel checks needed; persistent lavender scrollbar verified. |
| 03-settings-sounds-quiet-hours.png | 1463 × 866 | Wide sounds/quiet-hours captured; radio selection, keyboard/equal-time summaries, close labels and end-handle drag checked; playback, overnight/disabled states and exact pixels remain open. |
| 04-settings-thresholds.png | 1463 × 866 | Threshold controls revised; matching global-settings capture needed. |
| 05-settings-reset-reminders.png | 1463 × 866 | Validation and ordering checked; matching reminder-list capture needed. |
| 06-settings-refresh-reminders.png | 1463 × 866 | Validation and ordering checked; matching reminder-list capture needed. |
| 07-settings-app-behavior.png | 1463 × 866 | Behavior section seen during native navigation; exact layout comparison pending. |
| 08-alert-history.png | 1463 × 866 | Populated demo captured; 80-point rows and 16-point gaps checked; matching-width capture needed. |
| 09-demo-history-on.png | 1463 × 866 | Timeline geometry revised; fresh wide equivalent capture needed. |
| 10-demo-history-off.png | 1463 × 866 | Wide History-off captured at matching size; date/font and switch-hover differences remain. |
| 11-demo-filter-off-tooltip.png | 1463 × 866 | Wide filter-off captured; event counts and corrected per-element selector colors checked; floating tooltip capture needed. |
| 12-demo-all-capacity-levels.png | 1463 × 866 | Scenario fixtures available; equivalent capacity-level capture needed. |
| 13-usage-details.png | 1463 × 866 | Unknown-usage popup checked; standard and nonpercent captures need recheck. |
| 14-account-settings.png | 1463 × 866 | Compact account panel captured; Wide panel captured; shared lavender scrollbar and bottom connection actions checked; vertical text metrics still differ. |
| 15-custom-color-chooser.png | 1463 × 866 | Picker captured; footer and synchronization checked; spectrum/ring pixels remain different. |
| 16-custom-color-added.png | 1463 × 866 | Orange custom swatch added and retained after reopening; exact comparison pending. |
| 17-polling-snapped.png | 1463 × 866 | Polling control seen; endpoint and snapped pointer capture needed. |
| 18-account-connection-actions.png | 1463 × 866 | Connection section source-reviewed; matching capture needed. |
| 19-first-launch.png | 1463 × 866 | Isolated empty dashboard captured; horizontal coordinates checked; matching width needed. |
| 20-provider-chooser.png | 1463 × 866 | Chooser captured; border and dimensions checked; text metrics differ. |
| 21-connect-codex.png | 1463 × 866 | Codex form captured after typography change; exact metrics differ. |
| 22-connect-github-browser.png | 1463 × 866 | GitHub browser form captured; zero validation checked; exact metrics differ. |
| 23-connect-github-advanced.png | 1463 × 866 | Advanced form captured; dummy token mode reset checked; exact metrics differ. |
| 24-compact-empty.png | 789 × 694 | Empty geometry revised; fresh compact equivalent capture needed. |
| 25-connect-claude.png | 789 × 694 | Claude form captured with complete version requirement; exact metrics differ. |
| 26-compact-dashboard.png | 789 × 694 | Compact dashboard captured; rail x/y alignment checked; full fresh comparison needed. |
| 27-compact-account-rows.png | 789 × 694 | Compact rows captured; threshold inset and pointer movement checked; fonts differ. |
| 28-compact-account-settings.png | 789 × 694 | Account panel captured after inset/swatch fixes; vertical metrics differ. |
| 29-compact-tooltip-placement.png | 789 × 694 | Owner-window clamping implemented; floating tooltip capture missing. |
| 30-polling-tooltip.png | 322 × 118 | Complete polling help shared; floating tooltip capture missing. |
| 31-compact-global-settings.png | 789 × 694 | Global card inset/background revised; fresh compact capture needed after shared scrollbar change. |
| 32-notification-banner.png | 789 × 694 | Test banner captured; approximate dimensions checked; text metrics differ. |
| 33-quota-alerts-muted.png | 789 × 694 | Alert toggle tooltips revised; muted-state equivalent capture needed. |
| 34-threshold-drag-feedback.png | 789 × 694 | Native threshold grab/drag and keyboard checked; floating readout capture missing. |
| 35-earned-reset-details.png | 789 × 694 | Reset details source-reviewed; equivalent popup capture needs recheck. |
| 36-timeline-event-tooltip.png | 789 × 694 | Event details and click action checked; floating tooltip capture missing. |
| 37-history-sample-readout.png | 789 × 694 | History readout source/keyboard checked; equivalent floating readout capture missing. |

Detailed implementation and validation evidence: [visual-parity-audit.md](visual-parity-audit.md). This status replaces its original summary table; chronological evidence there remains useful.
