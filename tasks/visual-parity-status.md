# Current screenshot parity status

Reference image integrity checked against Windows `origin/main` at `694dc85`. All 37 local image files are byte-identical to GitHub. The files have .png names but contain JPEG data. Dimensions below are decoded image sizes; the previous PNG-header interpretation was invalid.

**No image is certified identical.** Every row remains partial or unverified. Builds verify compilation, not visual identity. Prior captures may predate shared-control changes and need final recapture.

Repeatable captures: `--demo --compact` (789×694 points) and `--demo --reference-wide` (1463×866 points), both verified by native screenshots. `--demo --reference-date 2026-11-04T16:11:00Z` freezes data and presentation time for subsequent comparisons; native compact Today/date/countdown rendering checked.

Cross-cutting open requirements: Segoe UI font assets/metrics; exact Segoe Fluent glyph shapes; final captures at matching window dimensions; popup captures and positioning; final per-image comparisons after shared changes. Updated user question about Mac-redistributable Segoe text/icon assets versus explicitly changing both apps to portable assets is pending. The exact reference target remains unchanged.

| Reference | Image pixels | Current evidence / next check |
| --- | --- | --- |
| 01-live-dashboard.png | 1463 × 866 | Live-provider equivalent capture missing. |
| 02-settings-updates-time-retention.png | 1463 × 866 | Wide demo top sections captured; inherited palette corrected; live update-available and final pixel checks needed; persistent lavender scrollbar verified. |
| 03-settings-sounds-quiet-hours.png | 1463 × 866 | Wide sounds/quiet-hours captured; radio selection, full-track clicks/drags, keyboard, overnight/equal-time summaries, overlap alternation and disabled input/focus checked; all eight preview actions and audio start/error paths checked at zero volume; status row and volume thumb corrected; audible output and exact pixels remain open. |
| 04-settings-thresholds.png | 1463 × 866 | Threshold controls revised; matching global-settings capture needed. |
| 05-settings-reset-reminders.png | 1463 × 866 | Validation and ordering checked; matching reminder-list capture needed. |
| 06-settings-refresh-reminders.png | 1463 × 866 | Validation and ordering checked; matching reminder-list capture needed. |
| 07-settings-app-behavior.png | 1463 × 866 | Behavior section seen during native navigation; exact layout comparison pending. |
| 08-alert-history.png | 1463 × 866 | Populated demo rows checked earlier; fresh empty compact panel captured at 741×630; final populated matching-width capture needed. |
| 09-demo-history-on.png | 1463 × 866 | Timeline geometry revised; fresh wide equivalent capture needed. |
| 10-demo-history-off.png | 1463 × 866 | Wide History-off captured at matching size; date/font and switch-hover differences remain. |
| 11-demo-filter-off-tooltip.png | 1463 × 866 | Wide filter-off captured; event counts and corrected per-element selector colors checked; floating tooltip capture needed. |
| 12-demo-all-capacity-levels.png | 1463 × 866 | Scenario fixtures available; equivalent capacity-level capture needed. |
| 13-usage-details.png | 1463 × 866 | Unknown-usage popup checked; standard and nonpercent captures need recheck. |
| 14-account-settings.png | 1463 × 866 | Wide and compact panel frames captured; shared lavender scrollbar and bottom connection actions checked; vertical text metrics still differ. |
| 15-custom-color-chooser.png | 1463 × 866 | Picker captured; footer and synchronization checked; spectrum/ring pixels remain different. |
| 16-custom-color-added.png | 1463 × 866 | Orange custom swatch added and retained after reopening; exact comparison pending. |
| 17-polling-snapped.png | 1463 × 866 | Wide off-center grab, snapped drag, keyboard, both endpoints and localized focus checked; exact rendered comparison remains. |
| 18-account-connection-actions.png | 1463 × 866 | Connection section source-reviewed; matching capture needed. |
| 19-first-launch.png | 1463 × 866 | Isolated empty dashboard captured; horizontal coordinates checked; matching width needed. |
| 20-provider-chooser.png | 1463 × 866 | Chooser captured; border and dimensions checked; text metrics differ. |
| 21-connect-codex.png | 1463 × 866 | Codex form recaptured at compact 741×630 with visible actions and reference outline; exact text metrics differ. |
| 22-connect-github-browser.png | 1463 × 866 | GitHub browser form captured; zero validation checked; exact metrics differ. |
| 23-connect-github-advanced.png | 1463 × 866 | Advanced form captured; dummy token mode reset checked; exact metrics differ. |
| 24-compact-empty.png | 789 × 694 | Empty geometry revised; fresh compact equivalent capture needed. |
| 25-connect-claude.png | 789 × 694 | Claude form captured with complete version requirement; exact metrics differ. |
| 26-compact-dashboard.png | 789 × 694 | Compact dashboard captured; rail x/y alignment checked; full fresh comparison needed. |
| 27-compact-account-rows.png | 789 × 694 | Compact fixed-date rows captured; alarm divider/81×48 geometry and off/on threshold visibility checked; fonts differ. |
| 28-compact-account-settings.png | 789 × 694 | Fresh compact account panel captured at 741×630 with shared border; internal text metrics still differ. |
| 29-compact-tooltip-placement.png | 789 × 694 | Owner-window clamping implemented; floating tooltip capture missing. |
| 30-polling-tooltip.png | 322 × 118 | Exact production help component rendered at 320-point cap; short/narrow wrapping checked; Segoe metrics and actual floating hover placement remain open. |
| 31-compact-global-settings.png | 789 × 694 | Fresh compact Settings captured at 741×630; scrollbar and outer surface checked; internal typography/vertical spacing still differ. |
| 32-notification-banner.png | 789 × 694 | Test banner captured; approximate dimensions checked; text metrics differ. |
| 33-quota-alerts-muted.png | 789 × 694 | Compact muted first-row state captured; selection and threshold hide/restore checked; equivalent full-image comparison remains. |
| 34-threshold-drag-feedback.png | 789 × 694 | Native threshold grab/drag and keyboard checked; floating readout capture missing. |
| 35-earned-reset-details.png | 789 × 694 | Reset details source-reviewed; equivalent popup capture needs recheck. |
| 36-timeline-event-tooltip.png | 789 × 694 | Event details and click action checked; floating tooltip capture missing. |
| 37-history-sample-readout.png | 789 × 694 | History readout source/keyboard checked; equivalent floating readout capture missing. |

Detailed implementation and validation evidence: [visual-parity-audit.md](visual-parity-audit.md). This status replaces its original summary table; chronological evidence there remains useful.
