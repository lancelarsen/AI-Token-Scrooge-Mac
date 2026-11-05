# Current screenshot parity status

Reference image integrity checked against Windows `origin/main` at `694dc85`. All 37 local image files are byte-identical to GitHub. The files have .png names but contain JPEG data. Dimensions below are decoded image sizes; the previous PNG-header interpretation was invalid.

**No image is certified identical.** Every row remains partial or unverified. Builds verify compilation, not visual identity. Prior captures may predate shared-control changes and need final recapture.

Repeatable captures: `--demo --compact` (789×694 points) and `--demo --reference-wide` (1463×866 points), both verified by native screenshots. `--demo --reference-date 2026-11-04T16:11:00Z` freezes data and presentation time for subsequent comparisons; native compact Today/date/countdown rendering checked.

Cross-cutting open requirements: exact Semibold font metrics and Segoe Fluent glyph shapes; final captures at matching window dimensions; popup captures and positioning; final per-image comparisons after shared changes. User said font licensing need not hold up this work and Windows must remain unchanged. Segoe UI Regular was found inside Microsoft Remote Desktop on this Mac and is now bundled and used for explicit reference text sizes and tooltip measurements. Dialog body text is 14 points. Segoe UI Semibold is now bundled from Microsoft’s sample repository and selected explicitly for semibold rendering and measurements; native heading rendering was checked. Final font-version/metric comparison remains open. Microsoft Segoe Fluent Icons is now bundled and used by 14 mapped ActionIcon symbols; remaining symbols and final alignment still require verification. Lucide assets are already reused. The exact reference target remains unchanged.

| Reference | Image pixels | Current evidence / next check |
| --- | --- | --- |
| 01-live-dashboard.png | 1463 × 866 | Live-provider equivalent capture missing. |
| 02-settings-updates-time-retention.png | 1463 × 866 | Wide demo top sections captured; inherited palette corrected; live update-available and final pixel checks needed; persistent lavender scrollbar verified. |
| 03-settings-sounds-quiet-hours.png | 1463 × 866 | Wide sounds/quiet-hours captured; radio selection, full-track clicks/drags, keyboard, overnight/equal-time summaries, overlap alternation and disabled input/focus checked; all eight preview actions and audio start/error paths checked at zero volume; status row and volume thumb corrected; audible output and exact pixels remain open. |
| 04-settings-thresholds.png | 1463 × 866 | Fresh wide settings-thresholds-current.jpg capture; threshold card about 243 points high versus 244 in reference, controls fit. Exact text rasterization/full alignment remain open. |
| 05-settings-reset-reminders.png | 1463 × 866 | Validation and ordering checked; fresh settings-reminders-current.jpg wide capture confirms 44-point rows/6-point gaps and no row clipping. Native menus announce selected values once; exact border/underline/glyph comparison remains open. |
| 06-settings-refresh-reminders.png | 1463 × 866 | Validation and ordering checked; matching reminder-list capture needed. |
| 07-settings-app-behavior.png | 1463 × 866 | Behavior section seen during native navigation; exact layout comparison pending. |
| 08-alert-history.png | 1463 × 866 | Fresh populated wide panel captured at 1000×800 points; 80-point rows, 16-point gaps and 28-point inset confirmed against reference 08. Fixture text/dates, typography and icon shapes still differ. |
| 09-demo-history-on.png | 1463 × 866 | Fresh wide header capture `artifacts/wide-header-corrected.jpg`; measured legend/history/hint gaps corrected. Matching timeline viewport and final full-image comparison remain open. |
| 10-demo-history-off.png | 1463 × 866 | Wide History-off captured at matching size; date/font and switch-hover differences remain. |
| 11-demo-filter-off-tooltip.png | 1463 × 866 | Wide filter-off captured; event counts and corrected per-element selector colors checked; floating tooltip capture needed. |
| 12-demo-all-capacity-levels.png | 1463 × 866 | Scenario fixtures available; equivalent capacity-level capture needed. |
| 13-usage-details.png | 1463 × 866 | Standard weekly popup recaptured with 22-point title and complete timestamps; unknown checked earlier; nonpercent comparison and exact body metrics remain open. |
| 14-account-settings.png | 1463 × 866 | Wide and compact panel frames captured; shared lavender scrollbar and bottom connection actions checked; shared 960-point form cap/16-point padding corrected in a native wide capture; vertical text metrics still differ. |
| 15-custom-color-chooser.png | 1463 × 866 | Picker captured; footer and synchronization checked; contrast-aware 16-point ring, keyboard-only focus ring and pointer/keyboard updates verified; template spacing corrected; ordinary brightness arrows/clamping and spectrum boundary wrapping checked; exact spectrum pixels, named-color keyboard/tooltip and fonts remain open. |
| 16-custom-color-added.png | 1463 × 866 | Orange custom swatch added and retained after reopening; exact comparison pending. |
| 17-polling-snapped.png | 1463 × 866 | Wide off-center grab, snapped drag, keyboard, both endpoints and localized focus checked; exact rendered comparison remains. |
| 18-account-connection-actions.png | 1463 × 866 | Connection section source-reviewed; matching capture needed. |
| 19-first-launch.png | 1463 × 866 | Isolated empty dashboard captured; horizontal coordinates checked; matching width needed. |
| 20-provider-chooser.png | 1463 × 866 | Chooser recaptured at 320×337 after 22-point title/12-point gap fixes; exact font metrics remain open. |
| 21-connect-codex.png | 1463 × 866 | Codex form recaptured at compact 741×630 with visible actions and reference outline; exact text metrics differ. |
| 22-connect-github-browser.png | 1463 × 866 | GitHub browser form captured; zero validation checked. Challenge prompt now uses source-matched centered 28-point Segoe Semibold, instruction/order/spacing and stacked reference action buttons; live challenge capture and exact metrics remain open. |
| 23-connect-github-advanced.png | 1463 × 866 | Advanced form captured; dummy token mode reset checked; exact metrics differ. |
| 24-compact-empty.png | 789 × 694 | Empty geometry revised; fresh compact equivalent capture needed. |
| 25-connect-claude.png | 789 × 694 | Claude form captured with complete version requirement; exact metrics differ. |
| 26-compact-dashboard.png | 789 × 694 | Fresh Segoe-font compact capture `artifacts/compact-fonts-current.jpg` compared with reference 26; native title-bar height and header legend/hint placement differ. Measured compact legend/hint gaps corrected and natively recaptured; intermediate-width wrapping and full pixel parity remain open. |
| 27-compact-account-rows.png | 789 × 694 | Fresh post-Segoe capture at b0d92ad: artifacts/compact-rows-segoe.jpg (1578×1388 Retina pixels). Used-label explicit Semibold face, centered quota/reset text and account action routing corrected. No clipping seen; aligned current capture compact-cards-aligned-current.jpg confirms a roughly 290-point first card versus 286 in reference, and quota content about 3 points farther left. Source spacing and control sizes match; intrinsic text/border layout still needs measurement. Scroll position and fixture times differ; not pixel-identical. |
| 28-compact-account-settings.png | 789 × 694 | Fresh compact account panel captured at 741×630 with shared border and corrected responsive form inset/685-point card width; internal text metrics still differ. |
| 29-compact-tooltip-placement.png | 789 × 694 | Owner-window clamping implemented; floating tooltip capture missing. |
| 30-polling-tooltip.png | 322 × 118 | Exact production help component rendered at 320-point cap; short/narrow wrapping checked; Segoe metrics and actual floating hover placement remain open. |
| 31-compact-global-settings.png | 789 × 694 | Fresh compact Settings captured at 741×630; scrollbar and outer surface checked; shared 960-point form cap/16-point padding corrected; internal typography/vertical spacing still differ, compact form width corrected again to include the Windows 24-point width reservation and verified in native captures. |
| 32-notification-banner.png | 789 × 694 | Test banner captured; approximate dimensions checked; text metrics differ. |
| 33-quota-alerts-muted.png | 789 × 694 | Compact muted first-row state captured; selection and threshold hide/restore checked; equivalent full-image comparison remains. |
| 34-threshold-drag-feedback.png | 789 × 694 | Native threshold grab/drag and keyboard checked; floating readout capture missing. |
| 35-earned-reset-details.png | 789 × 694 | Matching-date reset-details-variable-font.jpg resolves the snapshot-line wrap using the official Segoe UI Variable Text face (276.9648-point advance, matching the reference). Native popup 332×281 points versus reference about 332×282. Full rasterization and final line-position comparison remain open. |
| 36-timeline-event-tooltip.png | 789 × 694 | Windows 3c863a5 supersedes this image with a styled countdown tooltip. Shared quota-row/countdown component implemented; offscreen production-component renders checked at normal and narrow widths. Floating hover placement remains unverified. |
| 37-history-sample-readout.png | 789 × 694 | History readout source/keyboard checked; equivalent floating readout capture missing. |

Detailed implementation and validation evidence: [visual-parity-audit.md](visual-parity-audit.md). This status replaces its original summary table; chronological evidence there remains useful.
