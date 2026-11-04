# Windows Visual Parity Audit

Reference: Windows commit `5a88731`, November 4 conversion-for-mac pack. Source snapshot is extracted under ignored artifacts/windows-reference/source-snapshot. All 37 original PNGs are available locally.

Acceptance requires individual inspection and equivalent Mac captures; a successful build alone is not visual proof. Native macOS chrome and system-font metrics follow the reference guide's permitted adaptations.

| Image | Inspection | Findings / Verification |
| --- | --- | --- |
| 01-live-dashboard.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 02-settings-updates-time-retention.png | Inspected | Inspected: global Settings must be a centered panel with scrolling cards; current Mac separate window needs review. |
| 03-settings-sounds-quiet-hours.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 04-settings-thresholds.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 05-settings-reset-reminders.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 06-settings-refresh-reminders.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 07-settings-app-behavior.png | Inspected | Reference reviewed. Global switches and behavior actions aligned; slider styling, reminder control dimensions and rendered comparison pending. |
| 08-alert-history.png | Inspected | Reference hierarchy and spacing reviewed; detail heading/history row changes implemented. Runtime comparison remains pending. |
| 09-demo-history-on.png | Inspected | Inspected: compare logical dimensions at 1463-wide baseline; preserve native title bar. |
| 10-demo-history-off.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 11-demo-filter-off-tooltip.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 12-demo-all-capacity-levels.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 13-usage-details.png | Inspected | Reference hierarchy and spacing reviewed; detail heading/history row changes implemented. Runtime comparison remains pending. |
| 14-account-settings.png | Inspected | Inspected: account header should identify provider/account/plan; swatch outline and form columns differ. |
| 15-custom-color-chooser.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 16-custom-color-added.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 17-polling-snapped.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 18-account-connection-actions.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 19-first-launch.png | Inspected | Desktop/compact reference inspected. Empty-state button and dashboard Settings presentation corrected; equivalent compact captures pending. |
| 20-provider-chooser.png | Inspected | Provider chooser and named form headings implemented; full form sizing, field order and rendered comparison pending. |
| 21-connect-codex.png | Inspected | Provider chooser and named form headings implemented; full form sizing, field order and rendered comparison pending. |
| 22-connect-github-browser.png | Inspected | Provider chooser and named form headings implemented; full form sizing, field order and rendered comparison pending. |
| 23-connect-github-advanced.png | Inspected | Provider chooser and named form headings implemented; full form sizing, field order and rendered comparison pending. |
| 24-compact-empty.png | Inspected | Desktop/compact reference inspected. Empty-state button and dashboard Settings presentation corrected; equivalent compact captures pending. |
| 25-connect-claude.png | Inspected | Provider chooser and named form headings implemented; full form sizing, field order and rendered comparison pending. |
| 26-compact-dashboard.png | Inspected | Inspected: compact timeline keeps legends on first row and History/hint on second; corrected Mac wrapping, awaiting compact capture. |
| 27-compact-account-rows.png | Inspected | Desktop/compact reference inspected. Empty-state button and dashboard Settings presentation corrected; equivalent compact captures pending. |
| 28-compact-account-settings.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 29-compact-tooltip-placement.png | Inspected | Desktop/compact reference inspected. Empty-state button and dashboard Settings presentation corrected; equivalent compact captures pending. |
| 30-polling-tooltip.png | Inspected | Account form alignment, switches, swatches, connection buttons and polling help corrected; rendered comparison still pending. |
| 31-compact-global-settings.png | Inspected | Desktop/compact reference inspected. Empty-state button and dashboard Settings presentation corrected; equivalent compact captures pending. |
| 32-notification-banner.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 33-quota-alerts-muted.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 34-threshold-drag-feedback.png | Inspected | Reference reviewed; equivalent Mac state capture and detailed parity verification remain pending. |
| 35-earned-reset-details.png | Inspected | Reference hierarchy and spacing reviewed; detail heading/history row changes implemented. Runtime comparison remains pending. |
| 36-timeline-event-tooltip.png | Inspected | Reference hierarchy and spacing reviewed; detail heading/history row changes implemented. Runtime comparison remains pending. |
| 37-history-sample-readout.png | Inspected | Reference hierarchy and spacing reviewed; detail heading/history row changes implemented. Runtime comparison remains pending. |

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

## Provider Chooser Pass

Inspected images 20–23 and 25. Added reference 320-point three-provider chooser with lavender title, 44-point buttons, divider and right-aligned Cancel footer. Selecting a provider opens a named form with Personal prefilled; reconnect skips chooser. GitHub advanced-mode selector now uses a full-width action button. Canonical build passed. Runtime chooser screenshot inspected and OpenAI selection verified; no authentication initiated. Larger form panels, description/field order and provider action layout remain open parity work.

## Connection Forms Pass

Provider forms now target a 1000 x 800 host-limited panel with centered 550-point content column, description above nickname and full-width sign-in/Cancel actions. GitHub billing unit and fallback allowance stay above the browser/token mode button; shared bindings preserve these fields across mode changes. Authentication status remains visible after starting an operation; Keychain wording retained. Canonical build passed. GitHub browser form inspected at runtime and token mode transition verified without credentials or sign-in. Remaining: native field/picker styling, precise vertical gaps, compact panel behavior, other provider captures and busy/error states.

## Connection Field Styling

Matched source Entry background #2A2B30, 32-point field heights, bottom focus line, full-width billing menu and source placeholders. Form now uses source 18-point spacing and 640-point total maximum width including 32-point padding on each side. Added scrolling inside the host-limited panel and solid #141519 panel background. Canonical build passed; final field rendering, compact scrolling and focus behavior still require runtime comparison.

## History and Detail Formatting Pass

Inspected images 08, 13, 35, 36 and 37 individually. Usage detail heading now identifies provider/account/plan in lavender, followed by quota name and used/remaining values. Earned reset details combine account/count and fetched/status lines with bullet credit rows. Alert history now uses three-line action rows with leading category icons and hover styling; snooze/dismiss retained in context menu. Canonical build passed. History panel dimensions, detail dialog widths, date formatting and equivalent runtime screenshots remain open; tooltip image inspection alone does not establish Mac parity.

## Dashboard Settings Presentation

Dashboard Settings now presents a sheet over its dashboard with host-limited 1000 x 800 sizing. Runtime accessibility confirmed sheet presentation and scrollable content. Native Settings menu scene remains available separately. Empty-state description now uses 14-point text and demo action spans the content width with the reference external-link icon. Reviewed images 19, 24, 27, 29 and 31; compact resizing and screenshot comparison remain pending. Added explicit accessibility name to header switches after runtime inspection exposed the missing name.

## Compact Quota Rows and Notification Actions

All 37 reference images have received initial visual inspection; none of this implies all-state parity. Compact quota rows now place name/status and reset countdown above the full-width alarm/bar row, following image 27. Notification actions now include info, clock and dismiss icons with 8-point spacing. Canonical build passed. Compact runtime layout and notification rendering remain to verify. Images 01/10/11/12 show additional audit targets: refreshing purple busy state, consistent history-off rail height, faded disabled selector with filter tooltip, and capacity-state bar/marker colors.

## Refresh Feedback and Regression Check

Dashboard Refresh immediately disables after click, displays Refreshing… with a spinner, and uses purple active styling until the request returns. Canonical build passed. Full unit run attempted with ScroogeTests: host stalled before test execution in dyld library loading (sample saved in ignored artifacts/test-host-sample.txt); interrupted the run and terminated its host. No passing unit result claimed. Busy-state visual capture still pending because demo/empty accounts complete immediately.

## Timeline and Alarm Controls

History switch uses shared 40 x 20 reference styling and explicit accessible label. History-off account filter help matches reference action wording. Alarm segments now use shared selected/hover active styling and identify provider/account/plan/quota in help text. Timeline gear now presents the same settings sheet as dashboard. Canonical build passed; runtime history off/on transition and gear-to-sheet navigation verified. Alarm hover/icon screenshots remain pending. Normal app launch succeeded after the prior test-host loader stall.

## Settings Selection Styling

History retention now follows images 02/31 with visible explanation and full-width 32-point selector, preserving confirmation before shortening retention. Sound-theme choices use reference purple selection rings; preview actions use shared icon labels. Existing section help icons precede headings. Canonical build and diff checks passed. Final rendered settings comparison and keyboard/accessibility choice behavior remain pending; custom sound choices expose selected button state rather than a native radio group.

## Alert History Panel Geometry

Compared image 08 against captured MainPage.Alerts.cs and Services/AppPanels.cs. History now uses a host-limited 1000 x 800 panel, 28-point content margins, 16-point gaps and minimum 80-point rows. Title and empty-state wording match the reference; Close follows the list within the scrollable content. macOS delivery wording and context-menu actions remain platform-appropriate. Canonical build and diff checks passed. Rendered desktop/compact comparison and nested usage-detail navigation remain pending; this source-level correction does not establish complete visual parity.

## Runtime Reminder Selector Correction

Runtime inspection exposed borderless native Menu rendering that discarded the intended full-width field label. Switched reminder menus to button presentation with plain styling so the custom background, right chevron and equal flexible columns render. Amount width now matches the Windows control's 80-point column. Canonical build passed; demo screenshot verified full-width bordered selectors and aligned amount/remove columns. Opened severity menu and verified all three choices, then dismissed without changing values. Also verified the revised Alert History empty-state panel at runtime (1000 x 800, 28-point margins, full-width Close); populated rows remain unverified because demo history is empty.

## Retention and Billing Selector Runtime Pass

Confirmed the retention menu also collapsed to a borderless text label at runtime. Applied the same plain button menu presentation to retention and GitHub billing-unit selection. Canonical build passed. Runtime screenshots now show both fields at full content width with their intended 32-point height and right-hand chevron. GitHub billing menu opens with AI credits and Premium requests; dismissed without starting authentication or changing saved settings. Compact layout comparison remains pending.

## Account Settings Fields and Help

Compared image 14 and captured SettingsPage.cs. Account name now uses the reference 32-point dark entry with bottom focus underline and 12-point column gap. Added visible help icons to Account, Available Resets, Connection, polling, monitoring and account-alert controls. Runtime demo screenshot confirmed those icons and field rendering. Subsequent source comparison corrected account header to 20 horizontal/12 vertical padding, connection description to 13-point type, and shared settings-card inner spacing from 12 to the source's 8. Final canonical build passed; final spacing and compact screenshots remain pending.

## First-Launch Timeline

Compared image 19 with the running empty Mac dashboard. Added a distinct no-account timeline presentation: single Today heading/date/marker, 216-point plot region, lavender rail and history boundary, full-width navigator fill, and no percentage axis or select-account status. Populated accounts retain the existing interactive timeline path. Canonical build passed and first-launch runtime screenshot verified the new presentation. Remaining image-19 differences include typography metrics, navigator grip artwork and exact outer geometry; compact and transition checks remain pending.

## Compact Window Reachability

Found the app scene imposed an 860-point minimum width, overriding DashboardView's 760-point minimum and preventing the 789-point compact reference viewport. Removed the redundant scene constraint; the dashboard remains the owner of minimum size. Canonical build passed. Runtime right-edge resize reached approximately 790 logical points (1580-pixel Retina capture), showing the compact header and wrapped horizon controls without truncation. Exact compact height and populated screenshots 26–31 remain to compare; this does not certify compact parity.

## Compact Account Columns

Compared image 27 and QuotaRowView.cs with populated demo at approximately 790 logical points. Restored the account's vertical divider in compact mode and changed label/countdown layout to two equal flexible columns with the source 12-point gap. Canonical build passed. Runtime screenshot verified divider and countdown position alongside the label, with full-width alarm/bar row below. Scrolling outside the horizon moved the page vertically; scrolling over the horizon moved the timeline horizontally. Exact font metrics, card insets and full compact-height matching remain open.

## Account Card Source Measurements

Matched AccountQuotaView.cs and MainPage.WithAccountSettings/WithOrderControls: 56-point reorder column, 1-point divider with 14-point vertical inset only in Custom Order, content padding 20/8/16/8, 12-point identity/usage spacing, 4-point quota-row spacing, and 44-point gear with 14 top/12 trailing margin. Wide layout now uses actual account-content width, 220-point identity, 156-point quota label and 200-point reset column. Canonical build passed. Compact demo screenshot verified revised card geometry against image 27; wide runtime comparison remains pending.

## Usage Popup Dimensions and Timestamps

Verified revised desktop cards at runtime. Compared usage popup with image 13: usage/reset detail dialogs now use 342-point width instead of 480, with a 136-point minimum Close action. Percentage-only windows omit the redundant numeric allowance. Usage detail timestamps now include seconds and UTC offset, with reference-style labels and a blank separator before account metadata. Canonical build passed; runtime weekly-usage dialog verified width, allowance omission and timestamp format. System-font metrics still wrap the last-fetch offset onto a second line where the Windows reference fits one; exact typography and demo message/identity fixture parity remain unresolved.

### Demo usage-detail content comparison
- Compared Windows image 13 and captured `DashboardState.LoadDemo` / `ThemedDialogs` with the running Mac weekly usage popup.
- Matched demo subjects and scopes for all four accounts and restored the `Demo data` footer with the source's 6-point blank spacer and 8-point stack spacing.
- Canonical build passed (`artifacts/demo-details-parity-build.log`); running popup confirmed Personal address, scope, and footer.
- Discarded a condensed-system-font experiment: it fixed line wrapping but visibly distorted the reference letter proportions. Standard font remains; timestamp wrapping and exact typography remain unresolved. This is not full popup parity.

### Empty navigator grip
- Replaced the empty timeline's three-dot SF Symbol with the Windows navigator's six-dot drawing (two rows, three columns, 2-point dots, 4-point center spacing, #D1BEFF).
- Shared the drawing with the populated navigator to keep both states consistent.
- Canonical build passed (`artifacts/navigator-grip-parity-build.log`); inspected first-launch rendering and confirmed the six-dot grip centered in the track. Overall typography and remaining screenshot comparisons are still open.

### Sort and reorder icon geometry
- Matched the source Custom Order icon's 20x22 canvas, six hollow 5-point circles, 1.5-point stroke, and 9x7.5 center spacing.
- Matched remaining-sort meters to 22x20 with 14-point outline height and 4/14x7 fills; removed proportional approximations.
- Account drag handles now use separate filled six-dot artwork, matching the Windows braille grip's filled appearance rather than reusing Custom Order's hollow circles. Exact font-glyph raster equivalence remains unproven.
- Canonical build passed (`artifacts/action-icon-parity-build.log`). Inspected desktop demo with all four account grips and sorting controls visible. Other typography and icon comparisons remain pending.

### Usage bar text layering and reference colors
- Matched captured UsageBar.cs: paint labels above threshold markers, keeping labels input-transparent; use 15-point horizontal padding, #30333E track and #515461 border.
- Matched lowercase `used`, `left`, and `Demo data` text from captured QuotaRow.
- Canonical build passed (`artifacts/usage-label-parity-build.log`). Desktop demo inspection confirmed intact percentage characters where critical markers overlap them. Clicking label text opened usage details; dragging the critical marker under the label changed 10% to 12%, then accessibility decrements restored 10%.
- This verifies layering and input behavior, not exact font rasterization or full dashboard parity.

### Account row height and text colors
- Matched captured QuotaRowView's 56-point minimum row height, 8-point compact row gap, 4-point title/note gap and 8-point alert-toggle/bar gap.
- Matched quota title (#BEC1D2), status note (#A5A8BA), countdown (#BDA3F5), reset date (#BEC1D2), and account badge fill/border (#2C293E/#51476D).
- Reset clock now uses the source's 25-point size; date indentation follows the 25+12 layout and countdown/date gap is 3 points.
- Canonical build passed (`artifacts/account-row-metrics-build.log`); inspected four desktop demo cards. Two-window cards now have the reference 132-point content height. Compact rendering after this change remains to be checked; exact font metrics remain unresolved.

### Compact account sheet sizing
- Inspected the updated cards at 790-point dashboard width against image 27: compact label/countdown columns and full-width usage controls remain visible.
- Found account settings initially rendered at 1000 points despite the compact parent. Replaced post-presentation key-window guessing with the dashboard's measured size passed into AccountSettingsView before presentation.
- Canonical build passed (`artifacts/compact-account-sheet-build.log`). Reopened account settings at compact width: screenshot width now 1484 Retina pixels (742 points), correctly within the 790-point host with 24-point side margins, instead of 2000 pixels.
- Popup content typography and exact Windows compact dimensions still need comparison; other sheet types still use the old sizing approach.

### Shared compact sheet sizing
- Settings, connection forms and Alert History now derive initial dimensions from dashboard geometry through a shared environment value, rather than measuring keyWindow after presentation. Standalone Settings retains its 1000x800 default.
- Canonical build passed (`artifacts/compact-sheets-build.log`). At a 790-point dashboard width, Settings and the OpenAI connection form both rendered at 742 points (1484 Retina pixels); provider chooser retained its separate compact width. No authentication was started.
- Alert History uses the same sizing calculation but runtime presentation of that screen remains unverified in this pass. Content parity, native Settings scene behavior and exact typography remain open.

### App Updates card hierarchy and demo isolation
- Compared image 31 and captured SettingsPage.cs: changed version to regular 16-point text, heading icon to settings, separate 13-point status and 12-point last-check lines, and half-width refresh-icon action.
- Demo update toggle now edits local preview state; manual Check Now is disabled. Wording explicitly says manual checks because Sparkle background scheduling is independent of demo mode.
- Canonical build passed (`artifacts/update-card-parity-build.log`). Compact rendering inspected. Toggled preview checks off, closed/reopened Settings, and confirmed real updater setting remained on; Check Now remained disabled.
- Sparkle's native update availability/install interface differs from Windows. No update check/download/install was initiated. Exact typography and available-update presentation remain open.

### Settings heading icon columns
- Replaced automatic Label icon layout with captured SectionHeading measurements: 21-point section icons in 24-point columns with 10-point text gaps. Shared SettingsCard applies this to global and account sections.
- Settings title now uses a 26-point icon in a 29-point column instead of ActionLabel's fixed 19-point icon. Gear headings reuse the same bundled settings artwork as action buttons.
- Canonical build passed (`artifacts/settings-heading-metrics-build.log`); compact Settings rendering inspected with aligned section titles. Outer panel margins, help-icon coverage and full font equivalence remain open.

### Settings help indicators
- Added captured SettingsHelp coverage to shared section headings and global switches. Help icons use 16-point symbols, 20-point columns, 6-point gaps and #B5A0F4; account helper icons now use the same size/color.
- Source help text retained except Windows tray/sign-in terminology adapted to Mac menu bar/sign-in behavior.
- Canonical build passed (`artifacts/settings-help-parity-build.log`). Compact Settings inspection confirmed new Time Zone, Notifications and switch help icons without clipped labels.
- macOS native hover tooltip styling/timing has not been matched to the Windows immediate themed tooltip; full help interaction parity remains open.

### Custom-color dialog presentation and initial value
- Compared image 15 and PickColorAsync: custom color now starts from the selected account's resolved line color on each opening, rather than a stale/default purple.
- Changed anchored popover to modal sheet, width360; title21 accent; Add Color uses plus icon via configurable DetailsDialog primary symbol.
- Canonical build passed (`artifacts/color-dialog-parity-build.log`). Demo Personal popup visually confirmed pink; AX RGB 0.835294/0.529412/0.647059 equals #D587A5. Modal title/actions verified.
- Major remaining gap: native Mac color well still opens the system panel, whereas Windows displays an inline spectrum and RGB/hex fields. Image15 is not fully matched.

### Inline custom-color editor
- Replaced native color well with inline 256-point hue/saturation spectrum, 44-point preview, brightness track, RGB/HSV model picker, hex entry and numeric channels. Body scrolls within 420 points, matching image15's arrangement; dialog maximum height640 accommodates its content/footer.
- Added spectrum arrow-key support and brightness accessibility adjustment. Inputs clamp channel ranges; incomplete hex drafts do not replace the selected color.
- Fixed existing Color.hex truncation by using rounded sRGB components. Runtime test initially exposed #58A6FF becoming #57A6FF; rebuilt fix preserves #58A6FF and RGB88/166/255 exactly.
- Canonical build passed (`artifacts/inline-color-editor-build.log`). Inspected spectrum and fields; edited red88→122 and verified #7AA6FF, then Add Color selected #7AA6FF in the demo account palette.
- Remaining: RGB/HSV picker visual styling, hue/brightness pointer and keyboard edge cases, cancel behavior, and exact selector/gradient raster equivalence need verification. No live account settings changed.

### Color editor edge cases and selector styling
- Prevented programmatic hex synchronization from re-decoding HSV: black/gray output must not discard the selected hue or saturation.
- Replaced native compact RGB/HSV picker with the reference-sized 120x32 dark field and chevron; inline picker style avoids a redundant Color Model submenu.
- Canonical build passed (`artifacts/color-editor-edge-build.log`). Runtime HSV selection verified; brightness pointer at both ends produced #000000 then #FFA2C6 while preserving hue336/saturation36. Cancel returned to the original selected #D587A5 account color.
- Final inline-menu-style adjustment was build-checked after those runtime checks; its expanded menu remains to be reinspected. Exact rendering and full keyboard/input edge coverage remain open.

### Earned-reset popup width and snapshot format
- Matched image35's 332-point popup width for earned-reset events; quota windows retain342. Snapshot fetched now uses M/d/yyyy h:mm a in the selected display zone, matching the reference numeric format.
- Matched lowercase expiration/partial-data status wording.
- Canonical build passed (`artifacts/reset-details-parity-build.log`). Opened demo expiration event; inspected332-point popup and numeric snapshot date with both expiration bullets.
- Typography still causes the account summary and snapshot status to wrap where the reference fits single lines. This popup is not yet visually identical; its font metrics need correction.

### Earned-reset body font metrics
- Measured native font widths before adjusting: at14pt system font, account summary289pt and snapshot294pt exceed the284pt body; at13pt they measure271pt/276pt before bold-label styling.
- Set earned-reset detail body to13pt system while retaining21pt heading. This intentionally uses a different native point size to match the supplied rendered reference's line wrapping.
- Canonical build passed (`artifacts/reset-detail-font-build.log`). Runtime popup now shows account summary and fetched-status on single lines, as image35 does, with both expiration lines unclipped.
- Glyph rasterization and vertical spacing are not yet proven identical; usage-detail body font is unchanged and its timestamp wrapping remains open.

### Usage detail native font metrics
- Located Segoe UI inside Microsoft Remote Desktop and registered it only in a temporary measurement process; no font copied into the app or repository. Compared sample widths against system, Helvetica Neue, Arial and Tahoma.
- Usage popup supporting text now uses13pt system; heading remains21pt. Fetch timestamp is single-line with at most10% scaling to fit294pt content width, avoiding condensed letter shapes.
- Canonical build passed (`artifacts/usage-font-parity-build.log`). Weekly usage popup inspected: full fetched timestamp including timezone fits, account identity and provider-data lines remain readable and untruncated.
- Vertical rhythm still differs from Segoe's taller line metrics and needs correction; this is a measured width improvement, not proof of exact typography.

### Detail popup row heights
- Compared image13 and captured ThemedDialogs.cs: supporting rows use an eight-point gap and approximately19-point line boxes (27-point baseline steps). Native13-point text previously compressed the layout.
- Added19-point minimum row heights and32-point title boxes to usage and earned-reset details, preserving blank separators and allowing multiline content to grow.
- Canonical build passed (`artifacts/detail-row-height-build.log`). Runtime demo weekly popup measured342x417 points versus reference342x422; earned-reset popup332x281 versus reference332x283. Text and complete timestamps remain visible; four earned-reset body lines stay single-line.
- Remaining few-point overall-height differences and font rasterization are not exact parity. No live provider behavior changed or tested.

### Dialog palette and Close glyph
- Read captured Platforms/Windows/App.xaml and Services/ThemedDialogs.cs: dialog background #222329, separator #3B3D47, body #BEC1D2, emphasized labels #F2F1F5 and action icons #B5A0F4. Applied these explicit roles rather than reusing dashboard card/heading colors.
- Shared Close/Cancel glyph now draws a14-point diagonal cross inside its20-point icon slot, matching the reference screenshot footprint instead of the larger SF Symbol. Button hit targets and keyboard dismissal are retained.
- Canonical build passed (`artifacts/dialog-palette-build.log`). Opened weekly usage popup, visually checked palette, separator, smaller cross and complete metadata; clicked Close and verified dismissal.
- Other shared action icons inherit the corrected idle accent; their individual geometry still requires screenshot comparison. Native sheet outline and remaining typography differences are unresolved.

### Notification banner sizing (image32)
- Compared captured MainPage.Alerts.cs and image32. Corrected vertical stack spacing12→10 and removed forced expansion to520 points by allowing intrinsic sizing within that maximum.
- Canonical build passed (`artifacts/banner-sizing-build.log`). Generated a demo notification test through Settings; rebuilt app rendered the banner at approximately450x153 points with20-point bottom/right margins, versus reference442x154. Provider icon, title, detail and three action buttons are visible without clipping.
- An earlier screenshot capture showed a blank dashboard region; it did not recur after rebuilding. Notification delivery outside the app was not visually verified.
- Remaining8-point width difference relates to typography/icon metrics. Long and multiline banner content still needs visual verification; exact image32 parity remains open.

### Banner action icon geometry
- Replaced SF Symbols for DialogActionLabel's info/clock with thin18-point rings inside20-point slots, matching image32's footprint and stroke weight. The clock uses right-angle hands; info retains its stem, dot and foot.
- Canonical build passed (`artifacts/banner-icon-build.log`). Generated demo test banner and visually inspected all three buttons. Banner now measures approximately444x153 points versus442x154 in the reference; action text and provider identity remain unclipped.
- This is visual evidence for the demo banner only. Other icon families, typography differences and longer banner content remain open.

### Alert History timestamp format (image08)
- Captured MainPage.Alerts.cs formats row timestamps as `MMM d, h:mm tt`; Mac reused the dashboard formatter and included an extra weekday while omitting the comma after the date.
- Added a dedicated POSIX history formatter and applied it only to history row timestamps, retaining the selected display zone.
- Executed the formatter extracted from current source with reference Nov4 3:01AM, UTC conversion and previous-local-day rollover assertions; all passed. Canonical build passed (`artifacts/history-date-build.log`).
- Populated history row geometry/icons still require runtime comparison against image08. These date checks do not establish full screen parity.

### Populated Alert History runtime check
- Generated a demo test alert, reopened Settings → Alert History and inspected its actual populated row after the timestamp change. Verified three lines,80-point row height,28-point panel inset,16-point gap to Close, corrected `Nov 4, 12:39 PM` formatting and complete detail/delivery text at742-point panel width.
- Clicked the account-level test alert: it opened Available resets for the matching OpenAI Personal account. This matches captured MainPage.Actions.cs OpenAccount behavior for a nil window ID and a reserve-bearing account.
- Existing build470088e was used; no production code changed in this check. Only one delivered demo test row was exercised. Multi-row scrolling, refresh/expiration/undelivered icon variants and exact font metrics remain unverified against image08.

### Global switch help-icon correction (images02/03/07)
- Rechecked captured SettingsPage.Toggle: `showHelp` defaultsfalse for global switches, and only explicitly enabled account switches attach help. Earlier Mac helper incorrectly added info icons from the lookup table to all global switches.
- Removed the extra global-switch icons, restoring the reference left alignment. Section heading and account-setting help remain intact.
- Canonical build passed (`artifacts/settings-toggle-alignment-build.log`). Opened Settings and inspected Check for Newer Versions, Popup Notifications and Alert on Icon: labels now align at the card content edge; section help remains visible. No settings toggled.
- Mac's additional Privacy Mode row is absent from image07 and remains an explicit layout difference; its privacy behavior should remain available when reconciling that placement. Other section icon geometry/typography remains open.

### Outlined notification monitor (images02/07)
- Replaced filled SF desktopcomputer glyph with a thin outlined screen and two-part stand, matching the reference notification section/button silhouette. Shared ActionIcon scales it to the section21-point or button20-point slot; Send Test Notification uses the same rendering.
- Canonical build passed (`artifacts/notification-monitor-icon-build.log`). Opened Settings and visually confirmed the outlined notification heading with existing title/help alignment. No preference changed.
- Button variant shares the geometry but was not separately rendered this pass. Remaining Settings font metrics, time-zone labels, native controls and extra Privacy row remain open.

### Time-zone display labels (image02)
- Replaced the raw selected identifier with `(UTC-06:00) Central Time (US & Canada)` for the reference Chicago zone. Other zones show standard UTC offset, macOS-readable standard name and region identifier to distinguish zones with similar names. Saved IANA IDs and selection behavior remain unchanged.
- Standard offsets subtract DST rather than changing displayed offset seasonally, matching Windows DisplayName semantics.
- Formatter checks passed for Chicago in winter/summer and half-hour Kolkata/Adelaide offsets. Canonical build passed (`artifacts/time-zone-label-build.log`). Runtime selected Chicago label inspected at compact width, single-line and accessible by the same readable text.
- Complete Windows display-name catalog and ordering are not reproduced; non-Chicago names use platform data. The expanded menu remains a native Mac adaptation, not verified visually identical.

### Privacy control placement and App Behavior parity (image07)
- Removed the Mac-only Privacy Mode row from App Behavior to match the reference's two switches followed by Alert History and Send Test Notification.
- Preserved the existing preference and behavior through Privacy Mode in the native View menu and menu-bar menu. Both use the existing serialized store edit path; no preference migration/reset.
- Canonical build passed (`artifacts/privacy-menu-placement-build.log`). In demo, enabled Privacy Mode through View and verified timeline account names became Account; toggled back and verified Personal/Work returned. Inspected bottom Settings: expected row order, section help and outlined test-notification icon visible.
- Menu-bar extra's duplicate control shares the binding but was not independently clicked. Exact font metrics and other section glyphs remain open; this placement does not establish full image07 parity.

### Reminder action icons and button surface
- Added thin vector Add/Delete glyphs in shared ActionIcon, replacing heavier SF fallback shapes. Dialog actions also reuse these glyphs for Add Color/Remove Account.
- Reminder Delete uses shared button styling with12-point horizontal padding around20-point icon, preserving44-point width/height while providing the standard selected/hover/pressed surface.
- Canonical build passed (`artifacts/reminder-action-icons-build.log`). Inspected rendered reminder rows and Add Reminder: icons are centered, fields retain their widths and44-point buttons remain aligned. No reminders deleted or settings changed during verification.
- Hover coloring follows the shared style but was not pointer-tested here. Exact glyph corner rasterization and account-dialog instances remain unverified; full parity is still open.

### Reminder default and visual ordering (images05/06/07)
- Matched captured ReminderEditor.cs: Add Reminder creates Info/1/Days, unit choices list Days before Hours, and displayed rows sort by descending lead time with stable original order for equal durations. Display sorting also responds to amount/unit edits without changing reminder identities.
- Increased gap before Add Reminder from6 to8 points while retaining6-point row gaps.
- Canonical build passed (`artifacts/reminder-order-build.log`). In isolated demo settings added a reminder: Info/1/Days appeared immediately after the existing1-day row and before12-hours. Deleted that created row and visually verified original list restoration. Live reminder settings untouched.
- Editing existing amounts/units and invalid-entry feedback still require parity verification; default insertion/deletion evidence does not cover all editor states.

### Shared control icon sizing
- Corrected Time Zone chevron to10pt, consistent with other selector arrows; it previously inherited the13pt text font.
- Matched captured ActionButton.cs's20pt icon slot and9pt text gap in ActionLabel (previously19/10). Total horizontal allocation is unchanged.
- Custom line-color Add button now uses the same thin vector plus as other Add actions rather than an SF Symbol fallback.
- Canonical build passed (`artifacts/control-icon-consistency-build.log`). Inspected Settings Time Zone/retention arrows and Check Now after build: matching chevron sizes, readable labels, no clipping. Custom-color Add instance not reopened in this pass; its runtime check remains open.

### Connection status-row spacing (images21–25)
- Captured Codex/GitHub/Claude forms retain an empty status label between fields and Sign In, with18-point gaps. Mac omitted empty status entirely, placing actions37 points too high.
- Added shared ConnectionStatusLine with19-point minimum height and18-point child spacing. Advanced GitHub now places errors/status before Connect account, matching source order; blank status is hidden from accessibility.
- Matched GitHub billing label `Legacy premium requests`.
- Canonical build passed (`artifacts/connection-status-spacing-build.log`). Opened Codex form without starting authentication: nickname bottom to Sign In top now55 points, matching image21; Cancel remains18 points below the action. Full text visible.
- Form content width currently576 points versus approximately550 in reference; other provider runtime layouts and active sign-in states remain unverified. No browser login or credential operation started.

### Connection form width verification (images21–25)
- Replaced the shared576-point form limit with measured reference widths: Codex550, GitHub browser544, GitHub advanced534; Claude retains576. Description text uses13.5pt to improve wrapping within the narrower forms.
- Canonical build passed (`artifacts/connection-form-width-build.log`). Opened Codex, GitHub browser, and advanced forms: measured rendered field widths550/544/534 points, complete descriptions and controls, and retained blank status spacing. No authentication started or credentials entered.
- Native font wrapping still differs from Segoe UI (Codex breaks before protected rather than Codex); Mac Keychain copy differs intentionally. Claude description change and active authentication states still need runtime comparison. This is a width correction, not proof of complete connection-screen parity.

### Provider chooser surface and dimensions (image20)
- Matched the dialog background (#222329) and one-point separator (#3B3D47), replacing dashboard-card colors.
- Added the32-point title line box and130-point Cancel button width measured from image20. Retained320-point popup width,24-point padding,44-point provider buttons and10-point gaps.
- Canonical build passed (`artifacts/provider-chooser-parity-build.log`). Runtime chooser rendered320x335 points versus reference approximately320x336, all three providers and Cancel visible. Native title/person glyph metrics and popup edge treatment remain different; exact parity is not claimed.

### Account action glyph (images20–23/25)
- Replaced the heavy SF person fallback in shared DialogActionLabel with a20-point vector glyph: thin circular head and shallow rounded shoulder panel, matching the reference silhouette more closely.
- Shared ActionIcon retains action foreground/hover coloring and accessibility-hidden decoration; text labels remain accessible. Account page heading symbols are unchanged pending separate measurement.
- Canonical build passed (`artifacts/account-action-glyph-build.log`); rendered all three chooser buttons and verified aligned20-point icons without clipping. Exact raster equality and sign-in/reconnect instances remain unverified.
