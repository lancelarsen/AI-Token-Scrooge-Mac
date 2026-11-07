# Windows Visual Parity Audit

Current per-image status: [visual-parity-status.md](visual-parity-status.md). The original table below predates later fixes and is historical. No screenshot is certified identical.

Reference: Windows commit `5a88731`, November 4 conversion-for-mac pack. Source snapshot is extracted under ignored artifacts/windows-reference/source-snapshot. All 37 reference images are available locally (JPEG data with .png filenames).

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

The original dimension interpretation was invalid because the .png-named references contain JPEG data. See the current status table for decoded image dimensions.

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

### Connection text line boxes (image25)
- Runtime Claude inspection exposed nickname/actions approximately9 points above the reference relative to panel origin. Added35-point title minimum height and3-point description line spacing with1-point vertical padding to account for the shorter native font line boxes.
- Canonical build passed (`artifacts/connection-line-height-build.log`). Reopened Claude without initiating authentication: nickname top approximately140pt and sign-in227pt from panel top, versus reference139/225. Full description, nickname, Sign In and Cancel remain visible.
- Native wrapping still breaks before read rather than your; title glyph shape and panel height differ. The shared adjustment needs expanded-provider-state verification and is not exact typography parity.

### First-launch empty-state spacing (image19)
- Matched source VerticalStackLayout's24-point horizontal/36-point vertical padding; Mac previously used24 on all edges, placing empty-state content12 points too high.
- Matched the reference explanatory copy and32-point heading line box. Claude remains available in the provider chooser.
- Canonical build passed (`artifacts/empty-dashboard-spacing-build.log`). Runtime compact dashboard shows the heading, explanatory copy and demo action with corrected top spacing; demo action reaches the viewport bottom and remains in the scroll view. Full-size positioning, native font weight/width and compact timeline geometry still need comparison.

### Compact empty timeline anchors (image24)
- Added a compact empty-timeline layout below900 points of available content width:72-point blank selector gutter,34-point rail inset and38-point Today offset. Wide layout retains its existing dimensions.
- Canonical build passed (`artifacts/compact-empty-timeline-build.log`). At790-point window width, rendered divider x140, rail start x191 and Today x229 now match reference approximately140/190/229, replacing previous158/215/303 positions.
- Remaining compact differences include header typography, vertical positioning and navigator width. Wide empty state and breakpoint transitions still need runtime comparison; populated timeline behavior is untouched.

### History switch colors (images09/19/24)
- Captured Windows HorizonView explicitly sets OnColor #8670CC and ThumbColor #D1BEFF. Mac was reusing Settings' dark-thumb switch appearance.
- Added optional switch-style colors and applied the reference colors only to History; Settings retains its separate dark-thumb appearance shown in image02.
- Canonical build passed (`artifacts/history-switch-color-build.log`). Runtime enabled History shows pale thumb on the correct purple track with existing40x20 geometry and accessible on state. Off-state rendering was not exercised in this pass.

### Timeline header controls
- Matched source HorizonView legend spacing:7-point dot/text gap and20-point separation between legend items, plus exact refresh-dot #B5A0F4 and label #BEC1D2 colors.
- Corrected icon-only Timeline Settings button from52 to44 points wide, matching the Windows WidthRequest44 while preserving44-point height.
- Canonical build passed (`artifacts/horizon-header-controls-build.log`). Runtime compact header shows both complete count labels and square settings control without clipping. Source uses wrapping FlexLayout; Mac's two-layout fallback and native font metrics remain broader parity gaps.

### Dashboard brand line boxes and casing
- Matched source brand stack: zero spacing,40-point title line and26-point subtitle line, centered alongside66-point mascot. Previously intrinsic text heights and3-point spacing shifted the title down.
- Matched source sentence casing for empty/live-paused status and Add account/Exit demo labels.
- Canonical build passed (`artifacts/dashboard-header-parity-build.log`). Runtime compact empty dashboard shows complete brand/status text and Add account with no clipping. Demo casing follows the shared expression but was not reopened. Font-family differences and wide-layout baseline alignment remain unverified.

### Wide layout verification and navigator margins
- Expanded the running app using the native window zoom action. Wide header correctly uses one row and all legend/status/actions remain visible; empty-state content and demo button are visible without scrolling.
- Corrected both navigator variants from20-point to12-point card side margins, matching HorizonView's source padding. Their22-point height remains source-correct.
- Canonical build passed (`artifacts/navigator-margins-build.log`). Wide empty navigator now starts at44pt with card edge32pt. Populated navigator uses the same correction but drag behavior after resizing remains to be verified.
- Runtime window1496pt wide differs from1463pt reference; exact screenshot matching is still open, including font metrics, timeline header padding and chart anchors.

### History sample popup content and intrinsic width (image37)
- Replaced account-filter help reuse with the source sample structure: account/plan heading, period plus used percentage, timestamp, then optional coverage/interpolation/replenishment details. Observed Between Polls now occupies its own line.
- Popup body uses source #BEC1D2. Width derives from text metrics and is capped420pt instead of stretching short samples to420pt.
- Canonical build passed (`artifacts/history-popup-format-build.log`). In demo, focused Usage history and pressed Right: accessibility value reported OpenAI/Personal/Plus, Weekly ·22% Used, timestamp and coverage as separate lines. No live credentials touched.
- Main-window capture did not include the separate floating popup panel, so rendered popup width/line wrapping remains unverified. Keyboard selection/format evidence does not establish pointer-hover or all detail-variant parity.

### History popup window boundary (images29/37)
- Source HistoryChartInput clamps popup width and position to the app root with8-point margins. Mac previously clamped to the screen, allowing details to extend beyond compact windows.
- The existing AppKit tracking bridge now intersects the owning window's content-layout rectangle with the screen's visible frame, applying the same8-point margin to width/position calculations. Empty/offscreen bounds hide the popup.
- Canonical build passed (`artifacts/history-popup-boundary-build.log`) and diff checks passed. Runtime floating-panel edge positioning remains unverified; no claim of complete tooltip parity. SwiftUI retains sample selection/text ownership and the existing panel remains noninteractive.

### Timeline keyboard parity
- Added chart Up/Down sample selection, Page Up/Down seven-day panning, Home return-to-today, Return/Space sample pinning and shared Escape clearing; added equivalent navigator pan/Home controls.
- Matched Windows sample traversal scope to visible samples and removed automatic recentering during arrow selection. Panning/Home clear stale sample details.
- Canonical build passed (`artifacts/history-keyboard-parity-build.log`). Demo chart Page Up moved Nov4 to the earliest Oct28 boundary; Right selected a visible OpenAI sample without a navigator-date change; Home returned Nov4 midnight and accessibility reported No sample selected.
- Navigator-focused key paths and Return/Space remain untested at runtime; floating panel rendering remains separately unverified. Live state/credentials untouched.

### Navigator drag interaction parity
- Matched Windows BeginNavigation/DragNavigation: grabbing inside the visible thumb preserves the pointer offset; clicking outside centers once, then subsequent movement uses drag translation. Previous Mac behavior recentered on every update, causing an initial jump.
- Added pure HorizonViewport.dragOverview with finite-input guards and existing scroll bounds; drag start clears sample details and release resets transient drag state.
- Canonical build passed (`artifacts/navigator-drag-parity-build.log`). Standalone Swift check using the actual model source passed no-jump, proportional movement, lower/upper clamp and invalid-input cases (`artifacts/navigator-drag-check.swift`). Equivalent XCTest added to existing HorizonPerformanceTests; full hosted XCTest suite not rerun due previously documented host-launch failure.
- Native pointer drag/release and navigator-focused keyboard paths still require runtime verification; model checks do not prove gesture delivery.

### Native navigator drag and keyboard verification
- Verified rebuilt603bc5e app in isolated demo. Clicking near the left side inside the thumb retained Nov4 midnight; dragging140 screen pixels right moved to Nov5 3:58PM, confirming native gesture delivery and preserved grab offset.
- With navigator focused, Home returned Nov4 midnight, Right advanced exactly to Nov5 midnight, and Page Down advanced to Nov12 midnight. Returned Home afterward.
- These checks close the native drag and navigator-keyboard gaps recorded above for the exercised paths. Track-outside click, compact drag, Return/Space sample pinning and popup visual capture remain unverified. No implementation changes or new build were needed for this verification pass.

### History details focus-loss dismissal
- Matched Windows HistoryChartInput.OnLostFocus by binding chart keyboard focus and clearing pinned/sample text when focus leaves the chart. Existing Escape behavior remains.
- Canonical build passed (`artifacts/history-focus-dismissal-build.log`). In demo selected a history sample via Right, then Tab moved focus to Timeline Navigator; chart accessibility changed from sample details to No sample selected.
- Floating panel screenshot remains unavailable in the main-window capture; this check proves selection dismissal, not its exact visual rendering. Pointer-only focus transitions and application deactivation remain unverified.

### Conditional quota row content
- Matched QuotaRowView source conditions: omit the note label when CardNote is empty, and omit reset content when no reset date exists. Compact rows also avoid allocating an empty half-width reset column.
- Existing status-note precedence and reset countdown/reminder colors remain intact. Healthy rows now center only their actual quota title instead of an extra blank text line.
- Canonical build passed (`artifacts/quota-conditional-layout-build.log`) and diff checks passed. Healthy/no-reset fixture rendering remains unverified; standard demo rows contain notes and reset dates and do not prove these conditional states.

### Reset label column alignment

- Matched `QuotaRowView.cs` reset layout: clock with a 3-point top inset beside a single countdown/date column, 12-point horizontal and 3-point vertical spacing. This preserves date alignment when the countdown wraps.
- Matched the untriggered reminder clock color to Windows `#B5A0F4`; severity colors and reminder logic remain unchanged.
- Verification: canonical build passed (`artifacts/reset-label-alignment-build.log`), and `git diff --check` passed. This is source-level layout verification; exact rendered font/glyph parity and wrapped countdown screenshots remain unverified.

### Reset Horizon heading glyph

- Compared image 09 and `HorizonView.cs`: replaced the heavy SF history symbol with a thin vector history-clock outline, using the action lavender `#B5A0F4`, a 30-point slot and explicit 12-point title spacing.
- Canonical build passed (`artifacts/horizon-heading-icon-build.log`); native wide-window screenshot confirmed the new outline renders without clipping. This improves the reference silhouette; exact glyph pixel equality is not established. Overall font metrics and all 37 matched-state captures remain incomplete.

### Action state palette and sort borders

- Windows `ActionButton.ApplyColors` uses off-white normal text and lavender icons even over a selected background; white foreground is reserved for hover/busy. Separated processing from selection in the shared Mac button style so refresh retains its white processing state while selected sort/alarm controls retain normal icon colors.
- Matched sort segment separators and outline to `AccountSortControl` (#45464D), and icon/text gap to the shared action grid's 9 points.
- Canonical build and diff checks passed (`artifacts/action-state-palette-build.log`). Source-state comparison verified; hover/processing render captures remain outstanding.

### Quota detail targets and missing-reset alignment

- `QuotaRowView.SetWideLayout` reserves its 200-point reset column even when no reset is reported; compact mode likewise keeps two equal columns. Restored those empty layout slots without rendering a false reset value. This corrects the earlier conditional-layout pass's over-removal of the column.
- Added plain accessible buttons for quota descriptions and reset details, matching the Windows tap targets. They open the existing usage dialog independently from alarms and threshold dragging.
- Canonical build and diff checks passed (`artifacts/quota-details-targets-build.log`). Native demo verification: clicking the first quota description and then its reset label each opened the correct OpenAI Personal Plus / Codex 5-Hour dialog with 38% used and 62% left. Missing-reset fixture rendering remains unverified.

### Shared details-dialog frame

- Compared reference 13, `ThemedDialogs.cs` and Windows `App.xaml`: shared details dialogs now explicitly use a 16-point rounded frame with a 1-point #65577F outline, rather than relying solely on native sheet chrome. The overlay does not intercept input.
- Canonical build and diff checks passed (`artifacts/dialog-outline-build.log`). Native post-change border rendering still needs comparison; the pre-change popup was inspected, but its capture was scaled and insufficient for pixel measurement. Full screenshot parity remains unproven.

### Settings heading descriptions

- Reference 02 and `SettingsPage.WrapCard` group section headings and descriptions with 2-point spacing, then separate controls by 8 points. Added this description slot to shared SettingsCard and applied it to History and Alerts, Notifications, Quiet Hours and account Other Alerts. Previously each description was an ordinary content row with an 8-point gap.
- Matched description gray #A5A8BA and section-icon lavender #C3ADF8 (the shared action icon default was #B5A0F4).
- Canonical build and diff checks passed (`artifacts/settings-description-layout-build.log`). Post-change settings captures still needed; this is verified source/layout structure, not proof of full font or pixel parity.

### Asset identity and shared clock outlines

- Compared all 11 shared Resources/Images files against `origin/main` Git objects in the Windows reference repository: alarm_off/on, claude, github, openai, radar, refresh, settings, threshold_critical/warning and token_baron are byte-identical. This verifies asset identity, not rendered scaling.
- Added the thin clock ring/hands to ActionIcon for sort controls and settings headings; quota countdowns now use it with their severity color. Clock hands use the reference's upward/left orientation, including dialog action clocks. Account heading now uses the shared person outline and 29-point icon slot with 10-point spacing.
- Canonical build and diff checks passed (`artifacts/shared-clock-icons-build.log`). Post-change glyph rendering and exact pixel matching remain to be verified.

### Repeatable demo scenarios for remaining captures

- Added Windows-compatible `--scenario` fixture selection when entering demo: offline, auth, permission, unknown, exhausted, due, partial, history-long and reserve-only. Healthy and no-reset supplement the standard fixture for conditional row comparisons. Live state is still restored through the existing demo boundary; scenario code only constructs synthetic data.
- Canonical build passed (`artifacts/demo-scenarios-build.log`). A standalone executable compiled the actual Models, Format, LocalStore and PackedHistoryRun sources and passed assertions for all 12 scenarios, standard defaults, preserved offline usage and fixture independence (`artifacts/demo-scenario-check.swift`). Added focused regression coverage to CoreTests; the hosted XCTest suite was not run in this pass.
- This enables equivalent-state capture; it does not itself prove visual parity. Next captures should exercise missing-reset column reservation, healthy notes, unknown and exhausted bars, and status messages.

### Missing-reset and unknown usage runtime pass

- Launched isolated no-reset fixture and inspected all four wide account cards: reset columns remain reserved, no invented countdown/date is rendered, and usage bars retain their alignment. Compact missing-reset rendering is still outstanding.
- Unknown fixture exposed mismatched labels. Changed bar labels to Windows `Usage unavailable` / `Left unavailable`; native wide capture verified both labels on every quota and empty fill rather than zero usage. Exact text metrics remain different.
- Restored the Windows CardNote conditions: healthy provider messages and manual allowance notes remain visible unless explicitly suppressed by its Claude/GitHub rules; provider-paused usage is shown; nonhealthy notes include the health name. This corrects overly broad healthy-note suppression from the earlier pass.
- Canonical build and diff checks passed (`artifacts/quota-unavailable-status-build.log`). Provider-note branches are source-verified, not yet exhaustively exercised in UI.

### Repeatable compact launch and conditional row verification

- Added `--demo --compact` launch sizing (789 × 694 points); normal launches retain automatic restoration and their existing default size. Compact demo disables restoration so previous zoom state cannot defeat a reference capture.
- Native screenshot measured 1578 × 1388 Retina pixels, matching the intended 789 × 694 logical comparison dimensions. The earlier 662-point trial was corrected after runtime measurement.
- Compact unknown fixture showed both unavailable labels without truncation, stacked identities, and countdown/date columns. Compact no-reset fixture showed the quota label in its left column, no false reset text, and aligned full-width usage controls. This closes the missing-reset compact runtime gap; exact font metrics and full 37-image parity remain open.
- Canonical build and diff checks passed (`artifacts/compact-demo-launch-build.log`). Manual edge dragging was ineffective; the explicit demo option removes that dependency for future comparisons.

### Threshold live readout (reference 34)

- Replaced delayed system help on quota markers with a floating value readout for hover, focus and drag. Matches Windows text format, 14-point semibold white text, 18-point severity image, 8-point icon gap, 14×10 padding, 12-point corners and #65577F border on #222329. Warning/critical reuse identical reference SVGs.
- Reused the existing owner-window-clamped panel, with a 2-point threshold anchor gap. Added pending-content delivery when a new tracking view attaches to its window. Readouts dismiss with Escape, disable/mute, removal or non-drag geometry changes.
- Canonical build and diff checks passed (`artifacts/threshold-readout-build.log`). Native compact demo keyboard check moved the focused weekly Warning threshold from 30% to 29% without opening usage details. Floating-panel capture remains a verification limitation: live text/position and pointer-drag readout appearance are not yet proven by screenshot. Do not mark image 34 matched yet.

### Immediate event and settings tooltips (references 30 and 36)

- Compared reference 36 and Windows ToolTip style/source. Future event help now includes provider/account/plan, quota title, and labelled refresh/expiration date on separate lines. Settings information icons share the immediate popup implementation.
- Uses 13-point regular text, #F2F1F5 foreground, #222329 background, #65577F border, 12-point corners and 14×10 padding instead of default macOS help styling. Dismisses on pointer exit, click, geometry changes and removal.
- Canonical build passed (`artifacts/timeline-event-tooltip-build.log`); diff checks passed. Prior isolated demo interaction confirmed the event retains its usage-details click action. Floating popup appearance/placement has not been captured reliably, and the Mac system font still differs from Segoe UI; these references are not yet declared identical.

### Historical marker and account-selector help consistency

- Historical markers now use the immediate reference tooltip, with provider/account/plan, labelled refresh or expiration date, and the recorded schedule description. The History Event dialog uses that same content with blank lines between grouped events, matching Windows source instead of adding report timestamps and an extra explanatory paragraph.
- Account selector help now retains the Windows Show or Hide History, Resets and Refreshes instruction alongside history coverage/status, using the styled tooltip. Privacy masking remains applied.
- Canonical build passed (`artifacts/history-marker-tooltip-build.log`) and diff checks passed. Native demo accessibility inspection confirmed complete selector help for all four accounts. Historical popup rendering and grouped-dialog appearance remain visually unverified; an attempted automation PageUp key was unsupported, so it provides no pan verification.

### Compact capture sizing revalidation

- Live relaunch contradicted the earlier assumption that defaultSize plus disabled restoration guaranteed compact dimensions: the process had --demo --compact but reopened at 1496 points wide. Added a once-per-launch frame application on activation, gated by both demo flags; regular launches keep existing restoration.
- Canonical build passed (`artifacts/compact-demo-frame-build.log`). Native screenshot after relaunch measured 1578×1388 Retina pixels, proving the intended 789×694 frame.
- Compared reference 26: the current populated compact selector rail/chart are too far right (chart starts around x215 versus reference x190); current fixed 90-point selector allocation has no compact adaptation. Header/timeline vertical placement and font metrics also remain different. This comparison does not establish screenshot parity.

### Populated timeline rail geometry

- Matched Windows HorizonView padding (12 horizontal, 18 vertical), header/divider inset and 16-point section spacing. Matched timeline rail widths (95 compact, 112 wide, breakpoint 850), 10-point chart gap, selector inset (3/10/8), and rail divider vertical inset. Removed the previous 90-point selector plus two 16-point gaps.
- Canonical build passed (`artifacts/timeline-rail-layout-build.log`), diff checks passed. Native compact screenshot compared with reference 26: chart origin moved from approximately x215 to x189, versus reference x190; selector rail moved correspondingly. Navigator remains within the card.
- Vertical placement, font metrics, wide-layout rendering, and empty timeline geometry still need comparison. This is a verified horizontal alignment improvement, not full reference parity.

### Timeline heading and marker palette

- Compared TimelineDayHeading and chart drawing source. Corrected Today heading to #D1BEFF, ordinary headings/day circles to #B5A0F4, dates to #BEC1D2, and day/date spacing to 7. Rail now uses opaque #8170B7 rather than translucent general accent. Empty Today heading/date/rail share those colors.
- Historical marker text/symbol size corrected from 11 to 14 points, foreground #232429, refresh circle #B99AF8. SF Symbols still differ from Segoe Fluent glyphs; exact symbol outlines remain open.
- Canonical build passed (`artifacts/timeline-typography-palette-build.log`), diff checks passed, and compact native screenshot confirmed the updated day/date layout and differentiated Today color. Historical marker glyphs were not visible in that capture; full font metrics and vertical parity remain open.

### Timeline hint vertical spacing

- Shared history hint now uses Windows 8-point vertical margins and #BEC1D2 foreground in both header arrangements. The missing margin previously pulled the compact divider/chart upward.
- Canonical build passed (`artifacts/timeline-header-spacing-build.log`), diff checks passed. Compact native screenshot puts the rail at approximately y414, matching reference 26, and divider near y342 versus reference y340. Native chrome and font metrics still differ; these are approximate screenshot coordinates, not a pixel-diff certification.

### Quota threshold inset comparison (reference 27)

- Compared QuotaRowView, AccountQuotaView, UsageBar and Windows ThresholdEditor. Row spacing and nominal text sizes match source; threshold positions did not. Applied Windows eight-point endpoint inset and width-minus-sixteen span consistently to marker placement, drag-to-percent conversion and readout anchors.
- Canonical build passed (`artifacts/threshold-inset-build.log`) and diff checks passed. Native compact account screenshot confirms markers remain aligned within both bars, with labels and controls intact. Pointer endpoint dragging is not yet verified; font shapes/widths and card positioning still differ from reference 27.

### Threshold drag grab-offset behavior

- Windows starts each drag from the marker position and accumulates pointer movement. Mac previously mapped absolute pointer position directly, which could jump when grabbing off center. Updated Mac to preserve the initial marker position and apply gesture translation; readout and inset geometry remain shared. Unchanged clicks no longer persist a threshold update.
- Canonical build passed (`artifacts/threshold-grab-offset-build.log`), diff checks passed. Native compact demo pointer check: clicking near the Info marker edge retained 50%; dragging 47 Retina pixels right changed it to 45%, consistent with a 23.5-point movement over the 472-point span. No usage dialog opened. Full screenshot parity remains incomplete.

### Notification banner and threshold focus rendering

- Compared reference 32, Windows ShowBanner implementation, and a native compact test notification. Banner measured approximately 444×154 points versus approximately 442×154 in Windows: provider image, heading stack, detail, three actions, severity border, corner radius and bottom/right margin are present and closely aligned. Font-family differences remain; no claim of exact pixel parity. Existing banner geometry needed no speculative change.
- The test capture exposed a duplicate blue native focus ring around the quota marker in addition to its custom purple focus border. Disabled the native focus effect while retaining focusability and keyboard control.
- Canonical build passed (`artifacts/threshold-focus-ring-build.log`) and diff checks passed. Native compact check focused Info and pressed Right: 50% changed to 49%; screenshot confirms the purple focus border remains and blue duplicate ring is gone.

### Empty timeline rail geometry (reference 19)

- Updated the empty timeline to the same responsive rail widths as the populated chart (95/112, breakpoint 850), ten-point chart gap, forty-point axis inset and six-point divider end insets. The prior branch retained outdated rail widths and gaps after the populated-layout correction.
- Canonical build passed (`artifacts/empty-timeline-rail-build.log`) and diff checks passed. Isolated first-launch native screenshot shows divider near x155, chart start x206 and Today x294; reference 19 is near x156/x207/x295. Approximate coordinates differ by about one point.
- Capture used a 1496-point-wide native window versus the 1463-point reference; exact width, font metrics, and full first-launch parity remain open. No live accounts were used.

### Reminder input validation parity

- Windows ReminderEditor accepts positive Int32 values and displays a 12-point #F05B69 Enter a Positive Whole Number message for invalid text. Removed the Mac-only silent 1–365 clamp. Draft text stays visible while invalid; only valid amounts update the reminder. Severity/unit changes also validate the row draft, matching Windows Save behavior. Removing a reminder clears its draft and error.
- Canonical build passed (`artifacts/reminder-validation-build.log`) and diff checks passed. Native isolated demo check entered 0 and observed the exact validation message; correcting to 366 retained 366 and removed the message. Exact error text metrics/placement are still unverified against a reference capture.

### Settings page canvas palette

- Windows MainPage explicitly uses the #1B1C20-to-#141519 diagonal gradient, while SettingsPage uses a flat #141519 background for both global and account settings. Mac incorrectly reused the dashboard gradient for those two pages. Added Theme.canvas and applied it to both settings surfaces. Dashboard gradient remains source-aligned.
- Canonical build passed (`artifacts/settings-canvas-build.log`) and diff checks passed. This color correction is verified against authoritative source values; no new rendered settings capture was taken in this pass, so screenshot parity remains unproven.

### Alert history multiline row layout (reference 08)

- Compared reference 08, MainPage.OpenHistoryAsync and ActionButton layout. Windows renders each history entry as one multiline text block with a nine-point icon gap. Mac used three separately spaced labels with a ten-point gap. Replaced the stack with one leading-aligned multiline label and matched the icon gap. Retained macOS delivery wording and privacy masking.
- Canonical build passed (`artifacts/history-row-text-layout-build.log`) and diff checks passed. This pass verifies source structure; a new populated-history screenshot was not captured, so exact line metrics and screenshot parity remain open.

### Repeatable populated alert-history verification

- Added isolated --demo --scenario alert-history with eight synthetic recorded/delivered capacity, expiration and refresh entries. Standard demo remains empty-history; scenario construction performs no notification delivery and uses synthetic demo identities. README documents it.
- Canonical build passed (`artifacts/alert-history-scenario-build.log`) and diff checks passed. Opened Settings → Alert History through native UI. All eight entries appeared in accessibility state; screenshot confirms single multiline labels, 80-point row heights and 16-point gaps. This verifies the previous history text-layout change in a populated page.
- Capture was compact, unlike wide reference 08. Exact font-family metrics, glyph outlines and matching-width capture remain open.

### Thin history action icon outlines

- Replaced heavier SF folder/outgoing-arrow symbols with shared one-point vector outlines based on the visible reference 08 silhouettes. Dialog action labels route those symbols through the same shared renderer. Windows source selects Segoe Fluent E8B7/E8A7; these vectors are visual approximations, not extracted font outlines, so exact glyph parity remains unproven.
- Canonical build passed (`artifacts/history-action-icons-build.log`) and diff checks passed. Native populated-history screenshot confirms thin, unclipped folder/outgoing-arrow outlines and unchanged row geometry.

### Account line-color palette completeness

- Refreshed Windows remote; origin/main remains 694dc85. Compared reference 28 and SettingsPage palette construction. Mac now appends the account's selected color, validates six-digit hex values, normalizes case and deduplicates, matching Windows. This preserves a selected swatch even when the account color is absent from saved custom colors.
- Swatches now use nine-point corners. Add-color border uses #65577F and immediate Add Custom Line Color help/accessibility name. Color-picker internals were left at their existing radii.
- Canonical build passed (`artifacts/account-color-palette-build.log`) and diff checks passed. Palette inclusion is source-verified; selected custom-color rendering and exact compact account-settings parity require a new runtime capture.

### Compact settings form insets (reference 28)

- Native account-settings comparison exposed 36-point card insets versus approximately 29 in the Windows screenshot. Changed global/account form insets to 28. Post-change compact screenshot confirms card left edge at x28 relative to the sheet, close to the reference x29, and retains all seven default swatches plus add-color control.
- Matched Windows partial-reset-details wording and 12-point note size. This note branch is source-verified, not present in the standard capture.
- Canonical build passed (`artifacts/settings-form-inset-build.log`) and diff checks passed. Card vertical heights, font metrics and global-settings rendered comparison remain open.

### Account swatch-row vertical spacing and polling help

- Matched the Windows swatch row's trailing eight-point vertical margin and centered its label alongside the full palette height. This also supports wrapped palettes without leaving the label top-aligned.
- Polling information icon and label now share the complete Windows reference help wording using the immediate styled tooltip; removed the shortened icon text/default label help mismatch.
- Canonical build passed (`artifacts/account-swatch-spacing-build.log`) and diff checks passed. Native compact account-settings screenshot confirms the extra row margin, centered label, intact palette, and following polling/reset sections. Wrapped/custom palette and floating help appearance still require visual checks; typography differences remain.

### Provider chooser outline (reference 20)

- Added missing #65577F one-point border and sixteen-point clipping/presentation corners to the provider chooser, matching Windows dialog style and the other Mac detail dialogs.
- Canonical build passed (`artifacts/provider-chooser-outline-build.log`) and diff checks passed. Native isolated first-launch Add Account capture confirms the outline, three provider buttons and Cancel footer; captured size is 320×335 points versus approximately 320×337 in reference 20. Font metrics still differ.
- Reference-folder font inventory found no ttf/otf/ttc files. Asked user whether a Segoe UI bundle licensed for this Mac app is available; exact typography remains unresolved. Other visual work can continue independently.

### Connection description typography

- Windows App.xaml specifies 14-point Label defaults; provider descriptions do not override that size or line spacing. Removed the Mac 13.5-point override, extra three-point line spacing and one-point vertical padding, using the shared 14-point form text instead. Applies to Codex, GitHub browser/advanced and Claude descriptions.
- Canonical build passed (`artifacts/connection-description-typography-build.log`) and diff checks passed. Native isolated Codex form capture confirms a complete two-line description, nickname field, sign-in and Cancel controls with no clipping. No sign-in was performed. Exact Windows font metrics and GitHub/Claude post-change captures remain open.

### GitHub browser and token form behavior

- Captured browser form after typography correction: complete description and all fields/actions render. Compared reference 22 and GitHub Windows source. Corrected zero allowance acceptance in both browser/token paths to positive-or-blank validation with exact reference error wording; whitespace-only input counts as blank.
- Mode switching now clears token text and advanced-form errors, matching Windows SetGitHubMode. Native check entered zero and observed Allowance must be a positive number, or blank before any sign-in began. Entered dummy noncredential text in token field, switched modes twice, and verified Connect returned disabled with an empty token field. No authentication or real credential submission occurred.
- Canonical build passed (`artifacts/github-form-parity-build.log`) and diff checks passed. Browser rendering checked; exact advanced-form screenshot/font metrics and organization reconnect mode restrictions remain open.

### Claude and advanced GitHub capture; organization reconnect layout

- Native advanced GitHub capture confirms token and organization fields, browser-mode action, Connect and Cancel controls. Native Claude capture confirms complete two-line description including the 2.1.310 requirement, nickname, sign-in and Cancel. Compared Claude reference 25 and ConnectClaudePage; description and nominal spacing match, font metrics and panel chrome still differ. No sign-in was performed.
- Matched Windows ConfigureGitHubForm organization reconnect condition: an organization billing reconnect stays in token mode and omits the browser-mode switch. Description and width use token mode immediately rather than waiting for onAppear.
- Canonical build passed (`artifacts/organization-reconnect-layout-build.log`) and diff checks passed. Organization reconnect branch is source-verified; no real organization connection was used to render it. Full screenshot parity remains incomplete.

### Quota details field and status parity

- Compared Windows OpenDetailsAsync/QuotaRow.SourceNote and reference 13. Removed extra Mac-only numeric Used/Allowance rows from nonpercent quota popups. Missing values now use Usage unavailable / Left unavailable, matching dashboard and Windows.
- Popup source note now follows Windows rules: Demo data, health plus provider message, provider-paused state, reported message, or manual-allowance note. Previously several of these states were omitted. Privacy masking remains in place.
- Canonical build passed (`artifacts/quota-details-content-build.log`) and diff checks passed. Native isolated unknown demo popup confirmed the exact unavailable labels alongside reset/account/fetch/source details. Other status branches and nonpercent popup appearance are source-verified pending runtime captures.

### Remaining dashboard/settings native-help replacement

- Replaced delayed native help on account reorder/manage controls, row alert toggles, account rule/monitor toggles, timeline settings and reminder removal with the shared immediate styled tooltip. Existing accessibility labels remain; timeline settings now explicitly names the Windows Earned Reset Alert Settings action.
- Matched Windows reminder-removal help wording: Remove This Reminder from the Schedule. Source CapacityAlertToggle confirms immediate help for alarms.
- Canonical build passed (`artifacts/dashboard-tooltip-consistency-build.log`) and diff checks passed. No .help calls remain in DashboardView, HorizonView, AccountSettingsView or SettingsView. This proves consistent use of the shared implementation, not exact popup rendering; floating-panel placement and hover captures remain open.

### Color picker footer and spectrum focus (reference 15)

- Shared detail dialogs with a primary action now give both footer buttons equal flexible widths with an explicit eight-point gap. Single-action dialogs retain their right-aligned Close button. Reference 15 uses two equally sized footer buttons.
- Native color-picker capture confirmed both footer buttons span the available row equally, with spectrum, preview, brightness, RGB/hex and channel inputs intact. The capture exposed a native blue spectrum focus outline; disabled that extra system effect while keeping focus and keyboard handlers.
- Final canonical build passed (`artifacts/dialog-action-width-build.log`) and diff checks passed. Footer geometry is visually checked; spectrum focus suppression is build/source-verified pending post-change capture. Exact gradient interpolation, marker outline and font metrics remain open.

### Custom color synchronization and add/reopen flow (references 15–16)

- Native keyboard test exposed a stale hex field after changing hue: selected color changed to #D587A4 while hex remained #D587A5. Fixed color publishing, hex edits and RGB edits to derive linked values from an explicit new color rather than immediately rereading the parent binding. HSV coordinate preservation for grayscale/black remains intact.
- Canonical build passed (`artifacts/color-editor-sync-build.log`) and diff checks passed. Native checks: Right changed both selected color and hex to #D587A4; entering #FF9000 changed selected preview and RGB fields to 255/144/0; Add Color created a selected orange swatch; closing/reopening account settings retained that selected swatch. All work used isolated demo state.
- Post-change spectrum screenshot also confirms keyboard focus works without the unwanted blue system outline. Exact spectrum gradient/selection-marker shape and font metrics still differ from Windows and remain open.

### Deterministic HSV spectrum painting

- Replaced the six-stop generic hue gradient plus white overlay with a cached 512×512 sRGB hue/saturation image. Each pixel derives from the same normalized HSV coordinates used by selection, avoiding color-space interpolation between a small number of hue stops. The immutable image is generated once per process.
- Canonical build passed (`artifacts/color-spectrum-rendering-build.log`) and diff checks passed. Native picker capture confirms the hue/saturation surface, current selection, preview, brightness, channel inputs and footer remain visible and unclipped.
- This is a rendering-model correction; no per-pixel comparison proves identity to WinUI ColorSpectrum. Exact spectrum/marker appearance and typography remain open.

### Repeatable wide reference frame

- Added --demo --reference-wide to apply the 1463×866 reference frame once on activation, using the same narrowly scoped window bridge as --compact. Shared size resolution keeps compact precedence and disables restoration only for explicitly requested demo captures. Normal launches retain automatic restoration. README documents the flag.
- Canonical build passed (`artifacts/wide-reference-window-build.log`) and diff checks passed. Native screenshot measured 2926×1732 Retina pixels, proving the 1463×866-point frame. This removes the prior 1496-point-width mismatch for subsequent wide demo comparisons.
- Window dimensions now match; demo date/data, typography, native title bar and individual reference state still require alignment. No image is certified identical by this change.

### Wide History-off and filtered selector comparison (references 10–11)

- Captured 1463×866 History-off dashboard: usage grid/axis hidden, service rail and future events retained, navigator visible. Native account filter check changed refresh count 7→5 and expiration count 2→0 and removed that account's events. Date-dependent positions differ from the November 4 reference.
- Capture exposed whole-selector fading. Matched Windows BuildSelectors: only the provider container fades to half opacity; badge text uses #919195, badge strokes half-opacity, while the unchecked checkbox retains full accent border and control background. Removed global opacity that incorrectly dimmed that checkbox.
- Canonical build passed (`artifacts/filtered-selector-style-build.log`) and diff checks passed. Filtering behavior and pre-change rendering are verified; post-change per-element color rendering needs recapture. Exact switch hover appearance, fonts and floating tooltip remain open.

### Filtered selector post-change rendering verification

- Relaunched the current build at 1463×866, disabled History and filtered OpenAI Personal. Inspected a settled capture after both state updates. The provider container is dimmed, badge text/strokes muted, and unchecked box border remains clearly full accent; this closes the post-change per-element color capture gap from 664ec4a.
- Account quota rows retain their established wide columns after filtering. An earlier immediate capture appeared transiently misaligned; the settled capture does not reproduce it, so no speculative layout change was made.
- Updated per-image status for reference 11. Date-dependent event positions, exact fonts/glyphs and floating tooltip capture remain open. This verification-only change needs no rebuild; it used the already built current source.

### Global settings top-section and inherited text palette

- Captured current wide Settings top sections and compared reference 02/source. Version is already the source's sixteen-point size, so retained it. Demo notice corrected from thirteen-point #C3ADF8 to fourteen-point #B5A0F4, matching source with macOS wording.
- Settings heading icon now explicitly uses #C3ADF8. Global/account settings inherit #F2F1F5 primary text instead of platform default primary; account title uses that color explicitly. Existing specific secondary/severity colors remain explicit.
- Canonical build passed (`artifacts/settings-text-palette-build.log`) and diff checks passed. Top-section structure captured before this palette correction; exact post-change pixels remain unverified. Live update-available state differs from the demo capture and still needs separate verification.

### Sound options and quiet-hours switch styling (reference 03)

- Matched source volume row's twelve-point gap, secondary text color and rounded percentage display. Radio options now use thirty-two-point rows with no inter-row spacing, twenty-point inset-stroked circles, #A990ED selected ring and #F2F1F5 labels; this replaces a shorter overall option stack and incorrect selected lavender. Quiet-hours header switch uses source #8170CF.
- Canonical build passed (`artifacts/sound-controls-layout-build.log`) and diff checks passed. Native wide Settings capture confirms revised radio rows, preview grid, volume rail and quiet-hours section. Selecting Classic Chimes moved the selected accessibility state from Duck Sounds to Classic Chimes without invoking an audio preview.
- Exact radio/native glyph metrics, sound preview playback and quiet-hours drag states remain open.

### Quiet-hours enabled interaction and close-label verification

- Native current-build wide Settings check moved the end boundary with keyboard input from 8 AM toward midnight. At 2 AM, screenshot confirms vertically staggered start/end labels and increased track height; at 1 AM, summary shows 1 hours exactly as the Windows string construction does. At midnight, summary switches to Choose different start and end times to set a quiet period.
- Dragged the overlapping end handle from midnight to 8 AM; accessibility state and summary updated to 12 AM – 8 AM · 8 hours. This verifies an enabled pointer-drag path in addition to keyboard adjustment. A rapid initial key batch ended at 2 AM, so it is not evidence that every accelerated key event was processed.
- Source comparison confirms hour wrap, close-label threshold and equal-time text match Windows. No code changed; used current canonical build. Overnight wrap, disabled controls and exact focus/typographic pixels remain open.

### Thin sound-preview icons and corrected image metadata

- Routed the four sound-preview buttons through a shared twenty-point outlined play icon, replacing the heavier SF symbol. The path uses a one-point stroke and rounded joins, following reference 03 and Windows ActionButton E768. This is a vector approximation, not an extracted Segoe Fluent glyph.
- Canonical build passed (`artifacts/preview-play-icon-build.log`); native Settings screenshot confirms all four outlined triangles render without clipping. Audio playback was not invoked. Exact font and glyph identity remain open.
- Corrected the status table image dimensions by decoding all thirty-seven files: despite .png names, every reference is JPEG. Earlier attempts to read PNG headers produced invalid dimensions. References 01–23 are 1463×866, 24–29 and 31–37 are 789×694, and the cropped polling tooltip 30 is 322×118. Byte-identity evidence is unaffected by the file-format correction.

### Settings scrollbars (references 02–07, 14, 28, 31)

- Added a shared SwiftUI settings scroll wrapper with the Windows scrollbar's #B197F2 eight-point thumb, four-point corner radius, fourteen-point track and thirty-point minimum thumb height. Applied to global and account settings only, matching the Windows SettingsPage scope. Thumb size and position follow actual content/viewport geometry; wheel/trackpad/momentum remain owned by SwiftUI.
- Added thumb dragging, track page clicks, accessible position percentage and adjustable paging. No platform-wide scrollbar preferences or AppKit scroll handling changed.
- Canonical build passed (`artifacts/settings-scrollbar-build.log`) and diff checks passed. Native wide demo checks: wheel scroll changed 0→33%; thumb drag reached 96%; accessible increment reached 100%; dragging back reached 0%; track click paged to 33%. Account settings showed the same lavender thumb and wheel scrolling reached 100%, exposing both connection actions without clipping.
- Exact native scroll physics/performance and compact-size post-change captures remain unmeasured. Typography, content heights and glyph differences still prevent identical-image certification.

### Fixed-date reference demos

- Added `--demo --reference-date <ISO-8601 timestamp>` for repeatable comparisons. Demo snapshot/history generation, timeline Today/date classification, historical marker/readout bounds, navigator current-time marker, credit expiration status, icon-alert presentation and dashboard countdowns use the same fixed instant. Parsing requires explicit --demo; ordinary/live launches retain the current time. No network, credential or persistence clocks were changed.
- Canonical build passed (`artifacts/reference-demo-date-build.log`); `build-for-testing` compiled app and test targets (`artifacts/reference-demo-date-tests-build.log`). A standalone executable compiled actual Models/Format/LocalStore/PackedHistoryRun sources and passed demo-only parsing, missing/malformed arguments, fixed snapshot/history timestamps and all thirteen scenarios (`artifacts/reference-date-check.swift`). Hosted XCTest execution was not attempted because of the previously recorded host-launch issue.
- Native compact demo at 2026-11-04T16:11:00Z shows Today Nov 4, future events on matching calendar dates, first Codex reset Wed Nov 4 12:25 PM and 2h 14m countdown. The current screenshot state still needs matching history-pan position and fonts; fixed time alone does not certify visual identity. README documents the option and fallback.

### Capacity alarm segment geometry (references 27, 33)

- Compared source CapacityAlertToggle: restored the missing one-point center separator, #45464D inset outline, ten-point outer corners and eighty-one-by-forty-eight outer size. Two thirty-nine-by-forty-six segments plus divider and one-point border insets replace the previous eighty-by-forty-six control. Shared on/off behavior and source raster alarm icons remain intact.
- Canonical build passed (`artifacts/capacity-alert-segment-build.log`) and diff checks passed. Native compact fixed-date screenshot confirms aligned forty-eight-point alarm/bar heights and visible center divider. Turning off the first Codex alarm selected the right segment and removed its three threshold controls; turning it back on restored the left selection and 50/30/10 controls. Isolated demo state only.
- Header remains fixed during normal vertical scrolling. An immediate capture following an accessibility scroll-value change had stale clipping; settled normal-wheel captures retain the header, so no header code change was made. Exact typography and final per-image pixels remain open.

### Quiet-hours full-track interaction and overlap selection

- Native pre-change check confirmed clicking the 6 PM rail outside a handle left the range unchanged. Windows QuietHoursRange accepts the full graphics track, selects the nearest boundary and alternates selection on ties. Replaced handle-only drags with that shared track gesture; circles now paint with the track while time labels retain independent keyboard focus. Hour snapping uses nearest-even rounding to match Math.Round.
- Disabled controls explicitly reject pointer/key/accessibility changes and clear stale focus/drag state. Time labels now use source #F2F1F5. Existing noon-to-noon geometry and close-label layout remain.
- Canonical build passed (`artifacts/quiet-hours-track-build.log`) and diff checks passed. Native compact demo: rail click changed start midnight→6 PM and displayed 14 hours Overnight; end-circle drag changed 8→10 AM; Left changed 10→9 AM; disabling rejected a rail click and key input. Dragging end onto 6 PM showed the equal-time message and staggered labels; repeated clicks on the overlapping circle alternated focused start/end. Final rebuild verified disabling clears the white focus ring and moves focus to the sheet.
- These checks close the missing full-track and overnight/disabled behavior evidence. Exact Windows font/glyph/focus rendering and final matched-width pixel comparisons remain open.

### Sound preview status and volume rendering (reference 03)

- Restored the twelve-point amber preview-status row (including its empty sixteen-point line) below the sound buttons, matching Windows SettingsPage's reserved error space. SoundPlayer now returns Sound File Unavailable or Sound Playback Unavailable instead of silently skipping or beeping; preview bypasses the sound-enable setting as before. Bundle injection permits actual missing/corrupt-resource checks without altering signed app resources. Nonfinite volume falls back to 65, matching Windows.
- Volume now has the source's #C3ADF8 thumb over the #A990ED filled rail and accepts continuous pointer values; threshold sliders retain integer snapping. Display/accessibility percentages use nearest-even rounding.
- Canonical build passed (`artifacts/sound-preview-status-build.log`). A standalone executable compiled the actual playback service and Models/Format/LocalStore sources: missing/invalid-file errors, muted alert skip, preview bypass, unsupported cue skip, and both themes' five cue starts passed at zero volume (`artifacts/sound-preview-check.log`). Native Settings checks clicked all eight preview buttons at zero volume with no error text, then restored Ducks/65%. Physical audible output was not measured.
- Final native wide Settings capture shows the reserved status space and lighter thumb (`artifacts/sounds-status-and-thumb.jpg`). Capture bytes are JPEG with the Mac Display ICC profile; after converting to sRGB, sampled thumb center is (195,173,249), within one JPEG level of source #C3ADF8. Reference JPEGs are untagged. Future pixel comparisons must normalize color profiles and Retina scale. Exact typography/full-image identity remains open.

### Polling thumb grab offset and focus (reference 17)

- Native pre-change off-center click twelve points right of the two-minute thumb center changed polling to three minutes and drew a blue system focus rectangle across the entire rail. Windows MinuteEditor instead preserves the twenty-eight-point thumb grab area and accumulates movement from its snapped anchor.
- Polling now preserves that grab offset, retains rail selection and snapped integer values, and clears drag state at release/focus loss. Disabled the full-width system outline; keyboard adjustment shows a localized twenty-eight-by-forty-four lavender focus outline around the thumb, while pointer interaction leaves it hidden.
- Canonical build passed (`artifacts/polling-drag-offset-build.log`) and diff checks passed. Native wide demo: off-center click retained 2; a forty-five-Retina-pixel drag changed 2→3; Right changed 3→4 with localized focus; rail endpoints selected 1 and 30; another rail click restored 2 and removed the focus outline. No live account settings changed. Exact Windows system-focus pixels and typography remain unproven.

### Shared large-panel frame and surface (references 02, 08, 14, 21–23, 25, 28, 31)

- Corrected dashboard panel sizing to observe the owning NSWindow's complete frame. The Windows AppPanels host includes the title-bar area; using Mac content geometry had reduced every large panel by thirty-two points. A read-only NSView bridge observes resize notifications, deduplicates size callbacks, removes its observer on detach and never intercepts input or changes the window.
- Added the AppPanels #65577F one-point outline, sixteen-point corners, #141519 canvas and primary text to global Settings, account Settings, Alert History and connection forms through one shared surface modifier. Smaller chooser/detail dialogs retain their existing matching surfaces.
- Canonical build passed (`artifacts/panel-window-frame-build.log`) and diff checks passed. Decoded native Retina captures verify wide Settings 2000×1600 pixels (1000×800 points) and compact Settings/account/Alert History/Codex connection 1482×1260 pixels (741×630 points), matching reference panel dimensions. All show the shared outline; the compact Codex form retains visible Sign In and Cancel actions. No authentication started.
- Captures are under artifacts/*-panel-frame.jpg. Explicit wide/compact launch frame changes exercise the size observer; arbitrary live resize and exact modal screen positioning remain unverified. Fonts, internal line heights, source-dependent update data and full-image comparisons remain open.

### Plain help tooltip width and direct rendering (reference 30)

- Separated plain help from the wider history readout surface. Plain tooltips now cap at 320 points, retain fourteen/ten-point padding, add the one-point border inset and preserve the reference colors/twelve-point corners. Short messages size to their text; owner bounds still constrain narrow tooltips. History readouts retain their separate 420-point cap.
- Width is confirmed by Microsoft's DefaultToolTipStyle/ToolTipMaxWidth in https://github.com/microsoft/microsoft-ui-xaml/blob/85e1269f3a30beffdad33576dc9453b4d2c6e0c0/controls/dev/CommonStyles/ToolTip_themeresources.xaml; Scrooge overrides padding/font/colors in its Windows App.xaml.
- Regenerated the project with XcodeGen. Canonical build passed (`artifacts/help-tooltip-width-build.log`); direct ImageRenderer checks compiled the exact production ReferenceHelpTooltip component, asserted width limits, and rendered polling 640×204, narrow 360×364 and short 340×76 at Retina scale (`artifacts/help-tooltip-render.log`, artifacts/help-*.png). Inspected all three images for wrapping/clipping. Font metrics differ from Windows' polling reference, so its line breaks/height still differ.
- A native drag-entry attempt did not yield a visible floating tooltip capture; app inventory did not expose panel windows. Direct component rendering verifies appearance/layout, not actual hover activation, placement, shadow or deactivation behavior. Those remain open.

### Font and icon distribution dependency

- Confirmed Windows uses Segoe UI, Segoe UI Semibold and Segoe Fluent Icons. Microsoft's current font FAQ identifies a licensing route for Segoe UI, while Fluent Icons guidance says its downloadable font may not ship to another platform. No such fonts or rights were added to this repository. The exact-match target remains unchanged pending the user's asset decision; shared portable assets would require an explicit change to both apps.
- Sources checked: https://learn.microsoft.com/en-us/typography/fonts/font-faq and https://learn.microsoft.com/en-gb/windows/apps/design/iconography/segoe-fluent-icons-font. Updated the pending question to include icon-font distribution as well as text fonts. Independent visual/behavior fixes continue.

### Content-dialog headings and chooser title margin

- Matched Windows ScroogeDialogTitle's twenty-two-point semibold lavender title across provider chooser, quota details, reset details, custom color, history-event, confirmation and error headings. Previously these mixed twenty/twenty-one-point sizes and several used white. Shared Theme fonts make the heading style explicit.
- Separated the chooser's twelve-point title margin from ten-point option-row spacing, matching Microsoft's ContentDialogTitleMargin and the reference's 320×337 size. Source: https://github.com/microsoft/microsoft-ui-xaml/blob/85e1269f3a30beffdad33576dc9453b4d2c6e0c0/controls/dev/CommonStyles/ContentDialog_themeresources.xaml.
- Tried Windows' fourteen-point body size with the existing Mac system-font fallback. Native reserve/quota captures acquired extra wrapped lines, confirming that point-size substitution cannot resolve missing Segoe metrics. Reverted that experiment; the existing thirteen-point fallback and last-fetch fitting behavior remain explicitly pending the asset decision. This update does not claim body-font parity.
- Canonical build passed (`artifacts/dialog-typography-values-build.log`) and diff checks passed. Final native captures show readable twenty-two-point headings and complete quota/reset text, visible color-dialog Add/Cancel actions, and chooser 640×674 Retina pixels (320×337 points): artifacts/{weekly,reserve}-dialog-typography.jpg, artifacts/color-dialog-title.jpg and artifacts/chooser-dialog-typography.jpg. Generic confirmation/error/history-event branches are source/build verified, not separately captured.

### Color-spectrum selection marker (reference 15)

- Replaced the permanent black/white halo with WinUI's sixteen-point, two-point contrast-aware ring. Contrast uses the displayed full-brightness spectrum; keyboard focus adds the opposite-color twenty-point ring, pointer selection hides it, hover lowers the selection opacity to 0.8, and pressed state restores full opacity. Marker coordinates now reach the spectrum edges instead of using a seven-point inset.
- Matched Microsoft's ColorSpectrum.xaml and SelectionEllipseShouldBeLight at microsoft-ui-xaml commit 85e1269f3a30beffdad33576dc9453b4d2c6e0c0. Included its MIT notice in bundled resources for the adapted contrast calculation.
- Canonical build passed (artifacts/color-selection-indicator-build.log); build-for-testing compiled the app/test targets (artifacts/color-selection-test-build.log). A standalone actual-source check passed contrast for red, green, blue, white and pink, hue-seam equivalence, and rendered five production marker states. Normal and keyboard renders were inspected. Native demo pointer selection and Right-arrow adjustment changed HSV/RGB/hex together; captures confirm the extra focus ring appears for keyboard input and disappears after pointer selection (artifacts/spectrum-marker-native-{pointer,keyboard}.jpg). No account color was saved.
- Exact spectrum pixels, color-name tooltip, brightness keyboard behavior and font metrics remain open. Hosted XCTest runtime was not run because of the prior host-launch issue; test compilation is not a runtime suite pass.

### Color-picker keyboard controls

- Added focus and one-percent arrow-key adjustment to brightness: Right/Up increase, Left/Down decrease, and endpoints clamp at 0/100. Pointer interaction hides the localized keyboard indicator. Spectrum's ordinary arrow keys now follow WinUI's endpoint rule: stop at a crossed boundary first, then wrap when already at that boundary. Hue uses degree units and saturation percentage units, preserving fractional values.
- Source: Microsoft's ColorPickerSlider.cpp, ColorSpectrum.cpp and ColorHelpers.cpp at 85e1269f3a30beffdad33576dc9453b4d2c6e0c0. Pure channel adjustment is separated from view/input state and covered by fractional-boundary/wrap/clamp checks.
- Canonical build passed (artifacts/color-picker-keyboard-build.log); standalone actual-source checks passed (artifacts/color-channel-check.log). Native demo checked Right/Up increases and Left/Down decreases, 100% Right and 0% Left clamping, hue 0→360→0 and saturation 100→0 wrapping; RGB/hex/preview stayed synchronized. Cancel restored account settings with its original #D587A5 swatch. Native focus capture: artifacts/color-picker-brightness-keyboard.jpg. Test-target compilation passed; hosted XCTest execution remains unverified.
- Ctrl+arrow named-color jumps and color-name tooltips remain open: WinUI delegates names to ColorHelper_ToDisplayNameId, whose mapping is not in the fetched source. Brightness focus appearance is localized and readable but has not been certified identical to Windows. This closes ordinary-key functionality only.

### Color-picker template spacing (reference 15)

- Replaced the uniform twelve-point editor stack gaps with the Windows ColorPicker template values: four-point vertical outer padding, sixteen points below the spectrum/preview group, six below the brightness slider, and twelve between input rows. Spectrum/preview dimensions and the 420-point scroll viewport remain unchanged.
- Source: ColorPicker.xaml at Microsoft UI XAML 85e1269f3a30beffdad33576dc9453b4d2c6e0c0. Native top capture now puts spectrum top/brightness center/model row/red row at about 70/358/380/424 points relative to the dialog; reference 15 is about 71/359/381/425. This closes the inconsistent gaps, with a roughly one-point common inset difference still visible. It does not establish exact outer-frame or font parity.
- Canonical build passed (artifacts/color-picker-spacing-build.log), diff checks passed, and the native top capture was inspected (artifacts/color-picker-template-spacing.jpg). Native scrolling exposed all RGB fields while Add Color/Cancel remained fixed and visible. No color was saved. Existing typography, name tooltip and exact focus/rendering gaps remain open.

### Shared settings form width and padding

- Matched Windows SettingsPage.form's 960-point maximum INCLUDING its sixteen-point horizontal and twelve-point vertical padding. Both global/account Settings had applied twenty-eight-point side padding outside the cap; wide cards were too wide and compact cards too narrow. Global Settings also had twenty rather than twelve points of bottom padding.
- Canonical build passed (artifacts/settings-content-width-build.log). Native wide global/account captures show card edges at 36/964 points within the 1000-point panel, a 928-point card width, consistent with the source form cap (artifacts/{settings,account}-content-width-wide.jpg). Source layout yields 709-point cards inside a 741-point compact panel; this compact result is not yet a native measurement.
- A subsequent --compact relaunch did not produce the expected host-window size in computer-use captures; the file named settings-content-width-compact.jpg is a 2000×1600 wide panel and MUST NOT be used as compact evidence. The mismatch persists after refreshing the app handle; only one process is running with the compact argument. Do not infer compact parity from that capture. No window-sizing change was made in this update. Fonts, exact border insets and final per-image comparisons remain open.

### Font asset follow-up

- User requested reusing the original open-license assets. Fetched Windows main again: still 694dc85. The committed tree contains no font files or font-license package. App.xaml explicitly names Segoe UI for labels; SettingsPage and controls explicitly reference Segoe UI Semibold and Segoe Fluent Icons. MauiProgram registers no bundled font. Lucide's license is present and those assets already exist in the Mac resources.
- Asked for the branch/path or font name of the open-license font assets the user means; no asset substitution or Windows font change was made. Microsoft font FAQ and Segoe Fluent Icons documentation were rechecked; ordinary Windows font use does not establish Mac redistribution rights. Keep exact font parity open until the actual assets and permission can be verified.

### Reference capture sizing after window attachment

- Reproduced an explicit --compact launch retaining a large host frame. App activation is not a reliable point at which to find the SwiftUI dashboard window. Replaced the app-activation search with a tiny, noninteractive NSView bridge attached only when an explicit demo reference size is requested. It sizes its own attached window once on the next main-loop turn, preserves the top edge, captures window/self weakly, and does not reapply on ordinary focus changes. Ordinary launches retain automatic window restoration.
- Regenerated Xcode project; canonical build passed (artifacts/reference-window-attachment-build.log). Fresh native compact capture decodes to 1578×1388 Retina pixels (789×694 points), and wide relaunch decodes to 2926×1732 (1463×866). Compact global/account panels decode to 1482×1260 (741×630); both show the corrected sixteen-point side inset/709-point card width. Captures: artifacts/reference-window-attachment-{compact,wide}.jpg and artifacts/{settings,account}-content-width-compact-verified.jpg. The earlier incorrectly sized compact file remains historical, not evidence.
- This resolves the compact verification gap recorded immediately above. It does not certify full screenshot parity. No live provider or credential state was touched.

### Project-only font conclusion

- User confirmed there is no other font branch/location and requested using the project. Rechecked committed font extensions/paths: none. NSFontManager.availableFontFamilies reports no installed Segoe family on this Mac. Lucide remains reused with its existing license. Do not keep asking the user for another asset location or pretend the named Windows system fonts are bundled open-license assets.
- Exact Segoe font rendering remains a known unresolved dependency. Other parity work continues; no font substitution or font-file redistribution was performed in this update.

### Percentage-slider track extents

- Reference `04-settings-thresholds.png` shows the rails aligned with the content/label edges, while thumb centers retain their half-thumb inset. Corrected `ScroogePercentSlider` to draw the background across its full width and the filled segment from the leading edge to the thumb center. Thumb travel and input mapping are unchanged.
- Verification: canonical build passed (`artifacts/percent-slider-rail-build.log`); rebuilt isolated wide demo captured in `artifacts/percent-slider-rail-native.jpg`. Volume and threshold rails now align with their respective content edges. This is a geometry correction, not certification of complete screenshot/font parity.

### Compact settings form width reservation

- Rechecking `SettingsPage.SizeChanged` revealed an omitted rule: form width is `min(960, Width - 24)`, including its 16-point horizontal padding. The previous form-cap change correctly handled wide panels but left compact cards 24 points too wide. Reference 31 confirms the extra outer inset.
- Applied the rule to global and account settings. At the current 741-point panel width, the form is 717 points and cards 685 points, with 28-point outer margins. At 1000 points the form remains 960 points, preserving wide geometry.
- Canonical build passed (`artifacts/compact-form-inset-build.log`). Native compact global and account captures (`compact-form-inset-settings.jpg`, `compact-form-inset-account.jpg`) both show the corrected inset. Source and screenshot checks supersede the earlier claim that 709-point compact cards matched Windows. Exact typography and remaining outer-window differences remain unresolved.

### Account color swatch cell spacing

- Matched Windows `SettingsPage.AddSwatch` margins: each 32-point button occupies a 40-point cell with 8-point right and bottom margins. The previous adaptive grid omitted the final right margin when deciding how many columns fit. Replaced the add-color vector icon with the source's 22-point plus text and specified accent color.
- Canonical build passed (`artifacts/swatch-cell-spacing-build.log`). Native compact demo capture: `swatch-cell-spacing-native.jpg`. Added four custom hex colors through the real picker, verified each became selected, and captured `swatch-cell-spacing-wrap.jpg`: eleven swatches occupy row one, add-color wraps to row two, and polling remains below without overlap. Demo changes only; no live account data was edited. Font glyph identity remains unresolved.

### Populated alert-history comparison

- Rechecked `MainPage.Alerts.OpenHistoryAsync` and `ActionButton` against `AlertHistoryView` and screenshot 08. Fresh isolated `--demo --reference-wide --scenario alert-history` capture: `artifacts/history-wide-current.jpg` (2000×1600 Retina pixels, 1000×800 points).
- Confirmed 28-point outer padding, 80-point row height and 16-point row gaps in the native capture. Recorded, delivered, reset-expiration and quota-refresh icon categories are present in the eight-row fixture. Reference first-row top is about 76 points relative to panel, Mac about 74; text metrics and glyph shapes remain different. Fixture timestamps/detail strings are not equivalent to the reference's real history. No claim of pixel identity or live notification delivery.
- Reminder source review confirmed 80-point amount column, 8-point horizontal gaps, 44-point row controls and 6-point row gaps; fresh final reminder-image comparisons remain outstanding.

### Shared action colors, banner shadow and reminder validation spacing

- Removed the pure-white override from `DialogActionLabel` so shared actions inherit `ScroogeButtonStyle` normal #F2F1F5 / interacting white, matching Windows `ActionButton.ApplyColors`.
- Removed the Mac-only 16-point banner shadow; Windows `ShowBanner` specifies the rounded border/background without a shadow.
- Separated reminder rows (6-point spacing) from the error/action stack (8-point spacing), matching Windows `ReminderEditor`; normal row-to-add spacing remains 8 points.
- Canonical build passed (`artifacts/shared-action-format-build.log`). Native isolated demo entered zero, displayed the validation error with separate action spacing (`reminder-error-spacing.jpg`), then restored ten and verified the error cleared. Banner shadow and button color inheritance verified from code/build; no new live notification sent and no claim of complete visual identity.

### GitHub reconnect field states

- Rechecked Windows `ConnectAccountPage` and GitHub connection screens 22–23. Windows disables billing-unit changes and makes organization scope read-only for reconnects. Mac previously left both editable despite preloading the original values.
- Disabled those two fields only while `reconnectAccountID` is set. New-account inputs remain editable, and existing Keychain/identity checks remain in place.
- Canonical build passed (`artifacts/reconnect-locked-fields-build.log`); source review confirmed both modifiers depend on reconnect state. No live reconnect or authentication was performed. Exact disabled appearance and final connection-screen comparisons remain open.

### Shared image integrity audit

- Compared all eight shared image assets (`openai.png`, `token_baron.png`, `github.svg`, `claude.svg`, `alarm_off.svg`, `alarm_on.svg`, `refresh.svg`, `settings.svg`) against Windows `origin/main` and the currently built Mac app resources. All eight are byte-identical in all three locations. SHA-256 evidence: `artifacts/shared-image-integrity.json`.
- ProviderIcon loads the matching bundle PNG/SVG with aspect-fit rendering. No stale alternate GitHub/Claude PNG is present in the built bundle. This proves source and packaging identity only; rasterization, size, placement, and control glyphs still require rendered comparison.
- Font resolution remains pending: asked whether to adopt shared redistributable fonts/icons in both apps or retain Windows unchanged and use licensed Segoe assets when available. No substitution or Windows edits made while awaiting that decision.

### Rendered shared-surface color check

- Compared reference 31 with native `compact-form-inset-settings.jpg`, converting the Mac Display ICC screenshot into sRGB first. The Windows JPEG reference has no embedded profile and is treated as sRGB.
- The three dominant colors match exactly in both images: card fill RGB (29,30,35), panel canvas (20,21,25), and control fill (35,36,41). JPEG quantization explains the card fill's slight difference from the source #1C1E24; importantly both decoded images agree. Evidence: `artifacts/settings-surface-colors.json`.
- Also checked source dashboard gradient endpoints and capacity gradient endpoints against Windows; the defined hex values match. This does not certify full gradient rendering or the whole screenshot. No palette changes were justified by this evidence. Font/glyph selection remains pending user input.

### Threshold marker interaction bounds

- Windows `ThresholdEditor` defines a 32×48 Thumb around the 10×36 painted marker. Mac's target was 18×44. Matched 32×48 without changing marker paint size, position mapping or threshold rules.
- Canonical build passed (`artifacts/threshold-target-build.log`). Native compact demo: grabbed the Claude current-session info marker 12 points right of its center (outside the old 9-point half-width, inside the new 16-point half-width), dragged 50 points right, and verified the threshold changed from 50% to 39%. Evidence: `artifacts/threshold-expanded-target-drag.jpg` plus AX values. No live accounts changed. Exact focus/tooltip rendering remains open.

### Critical threshold marker color and help

- Windows `ThresholdEditor.CreateMarker` uses #FF5D68 specifically for the critical marker, distinct from the #F05B69 general critical-alert palette. Corrected only `UsageBar`'s marker fill; capacity gradients and reminder colors retain their source values.
- Added the Windows drag/arrow-key guidance as the marker accessibility hint. Source comparison also confirmed left/up increases remaining threshold and right/down decreases it, matching current Mac behavior.
- Canonical build and diff check passed (`artifacts/critical-marker-color-build.log`). This turn verifies the declared color and accessibility metadata through source/build, not final screenshot identity or live-provider behavior.

### Demo startup control state

- Matched Windows SettingsPage's `startup.IsEnabled = !demo`: Launch at Sign-In is disabled in the Mac demo. The store already avoids changing system login settings in demo mode; this fixes the visible interaction state as well.
- Canonical build passed (`artifacts/demo-startup-state-build.log`). Native compact demo AX verification confirms `switch (disabled) Launch at Sign-In`, while Keep Monitoring remains enabled (`artifacts/demo-startup-state-ax.txt`). No system startup setting was changed.
- User resolved the font decision: keep Windows unchanged and use licensed Segoe assets when available. Font availability remains a dependency, not a pending choice. Continue independent parity work without changing the Windows baseline.


## Segoe UI regular typography — 2026-11-05

- Located genuine Segoe UI Regular (`SegoeUI`) in the installed Microsoft Remote Desktop resources and bundled it in the Mac application. No Windows changes.
- Added process-local CoreText registration and shared SwiftUI typography; converted explicit reference text sizes across dashboard, timeline, controls, settings, dialogs, and readouts. Monospaced GitHub device code remains monospaced. Tooltip measurements use the same family. Restored Windows 14-point dialog body size.
- Verification: canonical build succeeded (`artifacts/segoe-font-build.log`); packaged font SHA-256 matches source asset; native demo dashboard launched and captured (`artifacts/segoe-dashboard.jpg`). No all-image identity claim.
- Dedicated Semibold and Fluent Icons assets remain absent. Requested weights and all 37 comparison captures still need verification. Native screenshot is a wide launch, not a matching-size compact reference capture.

## Threshold edit lifecycle — 2026-11-05

- Matched Windows ThresholdEditor keyboard transaction: arrow down/repeat previews locally; arrow release commits once; Escape cancels the pending edit. Focus loss cancels a pending keyboard edit.
- Resizing cancels an active pointer edit and ignores the rest of that gesture until release. Disabling alerts or removing the view clears pending edits; re-enabling does not leave a stale cancellation latch.
- Canonical build passed (`artifacts/threshold-edit-lifecycle-build.log`). Native demo verification: Left changed the first info threshold 50% → 51%; Escape after release retained 51%, demonstrating the completed edit persisted. Right then Escape restored 50% (`artifacts/threshold-keyboard-lifecycle-ax.txt`).
- Mid-drag resize and simultaneous held-key cancellation are source/build verified, not automated end-to-end verified. Tooltip positioning and exact font weights remain open.

## Threshold popup placement — 2026-11-05

- Matched Windows ThresholdEditor: horizontal four-point root margins, two-point marker separation, and a captured top offset retained until dismissal. Near the upper edge, clamp to the content top instead of flipping beneath the marker.
- Removed the threshold panel's extra macOS shadow. Accounted for the one-point border outside the 14/10 content padding, and drew the border inside the rounded rectangle.
- Canonical build passed (`artifacts/threshold-popup-placement-build.log`). A standalone harness compiled the production `ThresholdPopupPlacement` source and passed initial spacing, fixed top with changing anchor/size, left/right/top edge clamps, and reset/reopen checks (`artifacts/threshold-placement-check.swift`, `.log`).
- Floating-panel screenshot comparison remains outstanding; these checks verify placement calculations, not final font metrics or screenshot identity.

## Popup dismissal and ownership — 2026-11-05

- Immediate help now dismisses on mouse-down (matching Windows ImmediateToolTip PointerPressed), instead of waiting for a completed tap. The event is returned unchanged so controls retain normal input.
- Tracking panels dismiss when their owning window loses key status and cannot reopen from a stale view update while the window is inactive. A weak shared owner hides the previous readout when another opens, matching Windows threshold popup ownership.
- Window notification and event monitor subscriptions are removed when the view moves windows or is dismantled; callbacks capture the view weakly.
- Canonical build passed (`artifacts/popup-dismissal-build.log`); diff checks passed. Runtime multi-panel/activation checks remain unverified; no screenshot identity claim.

## Account help content parity — 2026-11-05

- Replaced seven shortened Mac help messages with the Windows SettingsHelp text: Account, Monitor This Account, Available Resets, Capacity Exhausted, Capacity Restored, Reset Expiry Reminders, and Connection. This restores the row-alarm prerequisites, monitoring/connection semantics, and explicit expiration-versus-quota-refresh distinction.
- An exact string comparison against Windows origin/main verified all seven messages; canonical build passed (`artifacts/account-help-parity-build.log`).
- Prior to this update, native threshold keyboard input was rechecked after the popup changes (50 → 51 → 50), and the Segoe account dialog was visually inspected. Native app inventory did not expose floating panels, so it does not prove popup visibility/dismissal; that runtime gap remains open. The account sheet itself rendered without overlapping the inspected controls, but is not certified identical.

## Global settings help and switch tint — 2026-11-05

- Removed the shortened Quiet Hours override so the existing Windows-matching shared help includes one-hour arrow-key instructions.
- Set ordinary global/account switch on-color to Windows SettingsPage's explicit #8170CF. The timeline's separate explicit styling is unchanged.
- Canonical build passed (`artifacts/settings-switch-help-build.log`). Native settings AX exposed the complete Quiet Hours message; settings capture (`artifacts/settings-switch-help-native.jpg`) verified the control renders. Source tint matches; full pixel parity remains unproven.

## Segoe Fluent action glyphs — 2026-11-05

- Downloaded Microsoft's Segoe Fluent Icons 1.56 package from https://www.microsoft.com/en-us/download/details.aspx?id=108863 (official download URL: https://download.microsoft.com/download/e67899fc-9e91-433c-91c6-876b3b98d787/Segoe-Fluent-Icons.zip). Bundled the font and its accompanying EULA.
- ActionIcon now uses the reference glyphs for clock, person, play, folder, desktop, plus, trash, close, moon, speaker, globe, sliders, link, and info. Removed superseded hand-drawn clock/person/play/plus/trash approximations. Dedicated custom sorting/reordering drawings and existing resource images remain.
- Canonical build passed (`artifacts/fluent-icons-build.log`); CoreText registration succeeded and all 14 mapped code points resolved to nonzero glyphs. Native visual alignment still needs checking; standalone info images and remaining fallback symbols are not yet migrated.
- Reviewed Windows ActionButton disabled template: it deliberately retains normal color styling, so no disabled-opacity change was made.

## Fluent information and history glyphs — 2026-11-05

- Replaced standalone settings/account help icons and the threshold information readout with Segoe Fluent E946 at their existing reference sizes (16/18). Preserved readable accessibility descriptions instead of exposing private-use glyph text.
- Replaced the Reset Horizon heading approximation with Windows HorizonView's E81C glyph at 30 points. Removed obsolete history/desktop drawing branches.
- Canonical build passed (`artifacts/fluent-info-history-build.log`). Native screenshots verified the information/globe/close glyphs in settings and history glyph on the compact dashboard (`artifacts/fluent-settings-native.jpg`, `artifacts/fluent-horizon-native.jpg`). Accessibility output retained complete Time Zone and Quiet Hours help. This proves rendering availability, not final image identity.

## Genuine Segoe UI Semibold — 2026-11-05

- Located and downloaded SegoeUI-SemiBold.ttf from Microsoft's MixedReality-AzureCommunicationServices-Sample repository at commit 0be22d2d10aa8172053206fa3d3a29799817313a, path unity/acsShowcase/Assets/Resources/Fonts/Segue UI/SegoeUI-SemiBold.ttf. Source: https://github.com/microsoft/MixedReality-AzureCommunicationServices-Sample/tree/0be22d2d10aa8172053206fa3d3a29799817313a/unity/acsShowcase/Assets/Resources/Fonts
- Bundled and registered the actual face; corrected the PostScript spelling to SegoeUI-SemiBold. Explicit semibold SwiftUI text and AppKit tooltip measurements now use the real face instead of the previous fallback.
- Canonical build passed (`artifacts/segoe-semibold-build.log`). CoreText/AppKit registration resolved the exact face with weight trait 0.30 and family Segoe UI. Native settings capture (`artifacts/segoe-semibold-settings.jpg`) verified visibly weighted headings without layout overlap in the captured sections.
- Final matching screenshots/metrics and possible Windows font-version differences remain to verify. Font availability is no longer the blocker it was earlier.

## Update label and selected-zone display — 2026-11-05

- Added the Windows Development Build suffix for display versions whose revision is zero. Matched the demo status text: Update Checks Are Paused in Demo.
- Last Checked now uses the selected Scrooge time zone and reference numeric date format, instead of the Mac's implicit local-zone formatter.
- Canonical build passed (`artifacts/update-label-timezone-build.log`). Native demo settings showed the Development Build suffix; changing Time Zone from Chicago to Los Angeles changed Last Checked from 11/5/2026 9:33 AM to 7:33 AM (`artifacts/update-zone-native-ax.txt`). No live updater action was triggered.
- Compact screenshot comparison still includes platform window/frame differences and live update-state differences; no full image certified identical.

## Shared dialog/action glyph routing — 2026-11-05

- Removed DialogActionLabel's separate hand-drawn Close, Info, and Snooze icons and routed all dialog symbols through ActionIcon. The previous Fluent migration did not cover those bypasses.
- Mapped Settings and Refresh to reference E713/E72C. Windows MainPage, HorizonView, and account-settings buttons use ActionButton glyphs, so their former SVG selection was mismatched. Alarm SVGs remain in use where appropriate.
- Canonical build passed (`artifacts/shared-dialog-glyphs-build.log`). Native settings capture (`artifacts/shared-dialog-glyphs-native.jpg`) verified Close, Settings, and Check Now glyph rendering. Final comparison with reference screenshot remains open.

## History/threshold readout precision — 2026-11-05

- Windows HistoryTimelineView details use 0.# for used percentage and observed replenishment amounts; ThresholdEditor uses it for threshold readouts. Mac previously rounded all of these to whole percentages.
- Added an opt-in fractionDigits parameter to Format.percent and requested one digit in history details and threshold popup/accessibility values. Dashboard whole-number labels and compact chart labels retain their existing formatting.
- Production Format.swift passed a standalone harness for fractional values, midpoint rounding, integer trailing-zero trimming, nil values, and unchanged whole-number defaults (`artifacts/readout-precision-check.swift`, `.log`). Canonical build passed (`artifacts/readout-precision-build.log`). Floating detail rendering still requires final comparison.

## Fractional threshold boundary parity — 2026-11-05

- Matched Windows AlertThresholds: warning's minimum uses floor(critical)+1; critical's maximum uses ceiling(warning)-1. Existing fractional saved values no longer force an unnecessary fractional gap.
- Info edits use midpoint-to-even rounding like decimal.Round; pointer positions first use whole-percent midpoint-away rounding like RemainingAt. Added finite/positive geometry guards.
- Added CoreTests regression cases for fractional neighbors, info midpoint rounding, pointer midpoint rounding, invalid geometry, and valid resulting order.
- Canonical build and build-for-testing passed (`artifacts/threshold-boundaries-build.log`, `artifacts/threshold-boundaries-test-build.log`). A standalone run of the exact production model declarations passed the regression scenarios (`artifacts/threshold-boundaries-check.swift`, `.log`). Hosted XCTest execution was not run; prior host-launch issue remains unresolved.

## Hosted XCTest launch retry — 2026-11-05

- Retried only CoreTests/testFractionalThresholdBoundariesMatchWindows with xcodebuild test-without-building against the successful test build. The host remained alive but never reached an assertion. A process sample showed dyld waiting in __open while loading dependent libraries (`artifacts/threshold-test-host-sample.txt`). The run was explicitly interrupted and its host terminated.
- Tested an isolated fresh derived-data build with ENABLE_DEBUG_DYLIB=NO to rule out split debug-library loading. Build completed, but its host stalled in the same dyld __open stack (`artifacts/threshold-monolithic-host-sample.txt`). Interrupted that run and terminated its host too. No production build settings changed.
- Evidence: `artifacts/threshold-hosted-retry.log`, `artifacts/threshold-monolithic.log`, and corresponding xcresult bundles. This is a launch/environment problem, not a failed threshold assertion. Hosted test execution remains unverified; prior standalone production-model checks remain the available execution evidence.
- Next diagnostic should identify the specific blocked library/file-open operation rather than rerunning an unchanged test command. No claim that the broader test suite passed.

## Allowance title casing — 2026-11-05

- Matched Windows QuotaRow.WindowTitle's ASCII word-start capitalization for dashboard allowance titles, usage details, row alarm help, and row accessibility labels. Existing capitals/acronyms remain unchanged; provider model data is not rewritten.
- Verified current Windows UsedText/LeftText are lowercase; no speculative capitalization change was made to those labels.
- Canonical build passed (`artifacts/allowance-title-build.log`). Production formatter harness checked lower-case names, AI/API acronyms, punctuation/hyphens, mixed-case preservation, and empty input (`artifacts/allowance-title-check.swift`, `.log`). Native screenshots remain needed for final comparison.

## Count-based quota labels — 2026-11-05

- Matched Windows QuotaRow's DisplayPercent rule: percentage windows and GitHub Copilot display percentages; other unit types display grouped counts with an over-limit amount when remaining is negative.
- Shared the formatter between the usage bar, bar accessibility label, and usage-details dialog. Missing count limits now say Limit unavailable, distinct from percentage Left unavailable.
- Added regression cases for count grouping, overage, Copilot's percentage exception, and missing values. A standalone executable compiled the actual production formatter and model declarations and passed those cases plus positive remaining counts (`artifacts/count-allowance-check.swift`, `.log`). Canonical build passed (`artifacts/count-allowance-build.log`). Hosted XCTest and live count-provider rendering remain unverified.

## Native count-usage verification — 2026-11-05

- Added an opt-in `--demo --scenario count-usage` fixture with an over-limit request allowance and an unknown request limit. Standard demo and live providers are unchanged.
- Canonical build passed (`artifacts/count-usage-demo-build.log`). Native AX verified OpenAI/Claude bars say 1,250 used / 250 over, unknown-limit bars say 50 used / Limit unavailable, and Copilot retains 125% used / 0% left.
- Opened the overage bar's details popup and verified it shows Request Allowance and 1,250 used · 250 over without clipping (`artifacts/count-usage-details-native.jpg`). This is synthetic demo evidence, not a live-provider check or reference-image identity claim.

### Remaining generic action glyphs — 2026-11-05

Compared Windows `ActionButton.GlyphFor` at reference `694dc85` with the Mac action icon routing. The generic fallback is Segoe Fluent U+E8A7 (including Explore with demo data and Use browser sign-in instead); token actions use U+E8D7. Mac now uses those bundled glyphs instead of a hand-drawn external arrow and an SF Symbols key. Removed the unreachable folder drawing, already superseded by its font glyph.

Verification: canonical build passed (`artifacts/remaining-action-glyphs-build.log`); CoreText resolved both characters to nonzero glyphs in the bundled SegoeFluentIcons face (`artifacts/remaining-action-glyphs-check.log`). This pass establishes source/glyph parity, not a new pixel-identical screenshot claim. Also checked detail-date formatting against Windows `ResetTime.Exact`: the existing `yyyy-MM-dd HH:mm:ss xxx` format and missing-value label already match; no date change needed.

### Exit Demo glyph routing — 2026-11-05

The dashboard used a second SF Symbols spelling (`arrow.up.forward.square`) for Exit Demo, bypassing the shared generic-action glyph. Routed it through the same U+E8A7 Segoe Fluent mapping as Windows `ActionButton.GlyphFor("Exit demo")`. Windows `MakeButton` ignores its legacy glyph argument, so the text-driven fallback is authoritative. Canonical build passed (`artifacts/exit-demo-glyph-build.log`); source search confirms the unmapped spelling is gone. No new native screenshot was captured for this one-line routing fix.

Also verified the dashboard sort labels against Windows `AccountSortControl`: its explicit 13-point override matches the Mac, so no font-size change was made there.

### Windows Restore Update Review — 2026-11-05

Fetched Windows `aaeb737` (new since `694dc85`). It defers tray/resume refresh until after a rendered frame and moves provider refresh setup off the UI thread. No conversion reference images changed. Mac already retains its snapshot-backed dashboard while refreshing, and Claude/GitHub provider work is actor-isolated. Activation previously started refresh immediately.

Mac activation now waits for `applicationDidUpdate`, clears the pending flag, and queues refresh outside the AppKit update callback. It checks active/visible/non-minimized state before refresh; resignation and termination clear the pending request. Existing demo/test/loading guards and wake/network refresh behavior remain. This is an AppKit window-update boundary, not proof that a compositor frame has been presented. Canonical build passed (`artifacts/restore-update-build.log`). Live-account restore latency, same-app minimized-window restoration, and cancellation/repeated-activation runtime checks remain open; do not claim complete parity with the Windows tray test.

### Activation Refresh Cancellation — 2026-11-05

Follow-up inspection found that clearing the pending-window-update flag did not cancel an already queued task. A rapid resign/reactivate sequence could therefore run the old activation's refresh before the new window update. The delegate now owns and cancels that task on reactivation, resignation and termination, checks cancellation before starting refresh, and directly awaits the refresh rather than spawning a second untracked task.

Canonical build passed (`artifacts/restore-cancellation-build.log`). A standalone Swift harness compiled the exact production activation/update/resignation methods with a fake app and counting store. It passed deferred execution, cancellation across rapid reactivation, one refresh across repeated update callbacks, minimized-window exclusion and demo exclusion (`artifacts/restore-cancellation-check.swift`). This verifies scheduling logic, not actual AppKit frame presentation or live-provider restore latency. Cancellation after provider work has already begun remains governed by the existing refresh/provider lifecycle.

### Fresh Compact Dashboard Comparison — 2026-11-05

Launched the latest build with `--demo --compact --reference-date 2026-11-04T16:11:00Z` and isolated data directory `/tmp/scrooge-final-compact`. Captured the actual app through computer use at 1578×1388 Retina pixels (`artifacts/compact-fonts-current.jpg`), corresponding to the reference's 789×694 point outer frame. AX confirmed all four demo accounts, seven refresh events, two expiry events, and frozen Nov 4 dates.

Compared with `26-compact-dashboard.png`: the header legend and History hint have differing horizontal placement. Windows `HorizonView` uses a wrapping FlexLayout with per-item margins; Mac `ViewThatFits` chooses fixed rows and groups both legends. The sources agree on 26-point section heading and 13-point legend/history text, so changing those sizes is not justified by this capture. Native title-bar height also shifts content vertically. Demo event times and same-day order differ from the captured fixture, so whole-image pixel equality cannot be claimed. Next layout work should reconcile the actual wrapping/margin model and use equivalent fixture times; no speculative visual adjustment was made in this verification pass.

### Header Wrap Experiment Rejected — 2026-11-05

Implemented and built a temporary SwiftUI Layout reproducing Windows HorizonView's independent items and declared margins (heading trailing 22, each legend trailing 20/vertical 8, History trailing 18). Native compact capture `artifacts/header-wrap-compact.jpg` showed History staying on row one and the hint alone on row two, unlike reference 26. The timeline also moved upward. This disproves equivalence between the two platforms' intrinsic measurements under the same declared margins. The experimental UI code was reverted rather than published as parity progress. Rebuilt the restored implementation successfully (`artifacts/header-wrap-restored-build.log`) and relaunched the compact demo.

Next work must measure the reference item allocations/row heights (including MAUI margin measurement and switch minimum dimensions) before replacing the current rows. The existing compact header gap remains open. The temporary capture is evidence of a rejected layout, not a successful visual match.

### Measured Header Spacing Correction — 2026-11-05

Measured colored legend components in reference 26 and the fresh pre-change native capture, normalizing Retina coordinates to points. Reference left edges were approximately x310/x467; Mac was x285/x422.5. Corrected compact heading-to-legend spacing from 22 to 44 and inter-legend spacing from 20 to 40. Compact History-to-hint spacing now 36 rather than 18. These are capture-backed layout corrections, not a claim about MAUI's internal margin implementation.

Canonical build passed (`artifacts/header-spacing-build.log`). Native compact capture (`artifacts/header-spacing-compact.jpg`) shows legend left edges approximately x307/x464.5, the hint near x180, and the original row arrangement/timeline vertical position retained. Wide capture (`artifacts/header-spacing-wide.jpg`) confirms the full header remains on one row without clipping. Residual few-point origin differences, title-bar geometry, intermediate-width wrapping and exact per-image metrics remain open. No screenshot is certified identical.

### Wide Header Spacing Correction — 2026-11-05

Compared the wide header with reference 09. Colored-dot horizontal spans were x309–316 / x467–475 in the reference versus x288–295.5 / x445–453.5 in the prior Mac capture (Retina coordinates normalized to points). Replaced the wide row's uniform 24-point gaps with explicit heading/legend/history trailing gaps of 44/40/36. This brings the legend dot spans approximately 20 points right, the History switch 36 points right, and the hint 48 points right, matching their reference placements much more closely.

Canonical build passed (`artifacts/wide-header-spacing-build.log`). Relaunched and captured the actual wide demo (`artifacts/wide-header-corrected.jpg`): all header elements fit on one row without clipping and the timeline's vertical position remains unchanged. Exact residual offsets, native title-bar differences, intermediate widths, and reference viewport/history positioning remain open. This is not a full-image identity claim.

### Tied Timeline Event Order — 2026-11-05

Windows `DashboardState.Events` concatenates dashboard-ordered quota refreshes before account-ordered earned resets, then stably sorts by timestamp. Mac previously interleaved each account's refreshes and resets, placing an OpenAI expiry above a Claude refresh at the same instant. Tied events now put refreshes first, order refresh accounts by `AccountPolicy.ordered`, and preserve original expiry order; unequal timestamps still take precedence.

Canonical build passed (`artifacts/horizon-event-order-build.log`). A standalone harness compiled the production HorizonEvent implementation with minimal model fixtures and passed refresh-before-expiry, reversed dashboard account order, stable expiry order, chronological precedence and hidden-account filtering (`artifacts/horizon-event-order-check.swift`). Native demo capture `artifacts/events-ordered-wide.jpg` confirms the Nov 8 Claude refresh is above the OpenAI expiry, matching reference 09. Remaining full-image, viewport and other parity gaps are unchanged.

### Conditional Timeline Plan Badges — 2026-11-05

Matched Windows `DashboardState.TimelineBadge`: future-event plan badges appear only when more than one enabled account uses that provider. Hidden timeline accounts still count, matching the Windows rule. The Mac previously displayed a plan badge on every event. The icon's reserved 62×49 area and timestamp placement are preserved when the badge is absent.

Canonical build passed (`artifacts/timeline-plan-badges-build.log`). Native demo capture `artifacts/timeline-plan-badges-wide.jpg` confirms both Claude event badges are absent while OpenAI Plus/Pro badges remain, matching reference 09. Sidebar account badges remain unchanged, as intended. Duplicate-provider enable/disable changes have not yet been exercised in the UI; full-image parity remains open.

### Persistent Timeline Ordering Regression — 2026-11-05

Added `CoreTests.testSimultaneousTimelineEventsFollowWindowsOrdering` using actual application models. It covers multiple quota windows per account, reversed custom dashboard order, refresh-before-expiry ties, stable expiry account order, chronological precedence, hidden accounts and disabled accounts. This preserves the expected behavior beyond the disposable standalone verification fixture.

`xcodebuild build-for-testing` passed (`artifacts/timeline-order-test-build.log`), including compilation of the new test. Re-ran the standalone production HorizonEvent harness successfully. Hosted XCTest execution was not retried: the previously sampled dyld launch stall remains unresolved, so the new XCTest's runtime is not claimed as passed. No app behavior changed in this test-only update.

### Dynamic Badge Verification — 2026-11-05

Through native UI in the isolated demo, turned off Monitor This Account for OpenAI Personal. AX confirmed off; dashboard capture `artifacts/single-openai-badge-check.jpg` confirmed the account's events disappeared, counts changed to 5 refreshes/0 expirations, and the remaining OpenAI Work events lost their Pro badges. Re-enabled the same account through its settings: AX confirmed on; `artifacts/duplicate-openai-badges-restored.jpg` confirms 7/2 counts and Plus/Pro event badges returned. The demo was left restored. This closes the earlier unverified dynamic enable/disable badge case; no production account settings were touched.

Source review also confirmed Windows OrderedUsageHistory uses saved custom order independently of dashboard sorting, matching Mac timelineAccounts; future event ties use dashboard order as tested previously. No further ordering change was necessary in this pass. Documentation-only update; no rebuild needed beyond the existing tested build.

### Final Reported Day Boundary — 2026-11-05

Windows HistoryTimelineView limits headings and rail dots to `model.LastDate`; extra content width is layout space only. Mac drew an extra day (Dec 1 in the fixed November demo) and could label empty padding beyond a short event range. The shared heading/dot/event loop now stops at the local calendar date of `viewport.lastEventAt`. Viewport width, navigator range and history grid calculations are unchanged.

Canonical build passed (`artifacts/timeline-final-date-build.log`). Relaunched the fixed-date demo and checked native AX: Nov 30 is present and Dec 1 absent. Repeated with History switched off, confirmed the same boundary, then restored History. Saved initial AX evidence in `artifacts/timeline-final-date-ax.txt`. Exact viewport appearance and full-image matching remain open.

### Historical Marker Glyph Parity — 2026-11-05

Matched Windows HistoryTimelineView's single historical marker glyphs: Segoe Fluent U+E823 for expiration and U+E72C for refresh, both 14 points. Replaced the SF hourglass/refresh symbols. Multi-event counts remain Segoe UI Semibold 14; existing 22-point circle dimensions and foreground/background colors already match the source.

Canonical build passed (`artifacts/historical-marker-glyphs-build.log`). Relaunched demo and moved the navigator back five days through its native accessibility action. Capture `artifacts/historical-marker-glyphs.jpg` visibly shows the amber clock and lavender refresh glyphs. The capture also exposes hollow day dots painting over some historical markers; Windows paints historical markers after day dots, so draw-order parity needs a follow-up. No full-image identity claim.

### Historical Marker Layer Order — 2026-11-05

Moved the historical marker views after the day-heading/dot/future-event loop in the timeline ZStack, matching Windows' historical-marker-over-day-dot paint order. Previously the hollow day dot could cover part of a nearby historical refresh icon.

Canonical build passed (`artifacts/historical-marker-layer-build.log`). Relaunched the fixed-date wide demo and moved the navigator five days back. Capture `artifacts/historical-marker-layer-fixed.jpg` shows Oct 30, Nov 1 and Nov 2 refresh glyphs unobscured, unlike the prior capture at the same viewport. Clicking the Nov 1 marker opened the correct History Event sheet for Claude / Personal · Pro, Quota Refresh Sun Nov 1 10:11 AM; closed it afterward. Remaining full-image and other interaction gaps are unchanged.

### History Endpoint Label Styling — 2026-11-05

Compared endpoint labels against Windows HistoryTimelineView at origin/main. Matched the #202229 fill, full-opacity series-colored border, and optional single decimal in used percentages (`0.#%`). Previously the Mac used the card background, a 70-percent-opacity border, and rounded to a whole percent. Dimensions, corner radius, connector and font size remain source-matched.

Canonical build passed (`artifacts/history-endpoint-label-build.log`). A standalone harness extracted the production Format.percent declaration and passed fractional rounding and whole-number trailing-zero checks (`artifacts/endpoint-percent-check.swift`). Source/diff checks passed. This pass does not claim native screenshot validation of endpoint labels or full-image identity; those remain open.

### History Chart Grid and Guide Palette — 2026-11-05

Matched HistoryTimelineView's chart-specific drawing values: opaque horizontal grid #343741, vertical grid #30333C at 2 points (Windows retains the rail's StrokeSize=2), historical refresh guides #B99AF8 at 60 percent opacity, hover guide #BEC1D2 at 60 percent, and current-time line #B5A0F4. Previously these used general theme colors or a thinner vertical grid.

Canonical build passed (`artifacts/history-chart-palette-build.log`). Launched isolated fixed-date compact demo and moved six days backward with the navigator's native accessibility action. Capture `artifacts/history-chart-palette.jpg` confirms chart rendering and visible endpoint labels from the previous change (including Max 82% and Plus 74%). The viewport auto-scrolled vertically to reveal the navigator; future-event badges overlap some endpoint labels in this state, so this is not a full-image parity result. Hover-guide appearance was source-checked but not captured. Full reference comparison remains open.

### History Axis and Keyboard Order — 2026-11-05

Matched Windows chart Muted (#BEC1D2) for percentage-axis text and the rotated axis title, and Accent (#B5A0F4) for the navigator thumb outline. Keyboard history inspection now preserves displayed series order when timestamps tie, matching Windows stable OrderBy(Point.At); the previous secondary account-ID sort could traverse accounts out of visual order.

Canonical build passed (`artifacts/history-axis-navigation-build.log`). In the fixed-date compact demo, panned four days backward. AX clicking the oversized canvas failed as offscreen, so clicked a visible chart point and used Right. Five successive native key presses showed Oct 31 3:21 PM samples in order OpenAI Personal, GitHub Copilot Work, OpenAI Work, Claude Personal, then the next timestamp's OpenAI Personal. Evidence: `artifacts/history-keyboard-order.txt`. Saved chart capture `artifacts/history-axis-navigation.jpg`; Escape dismissed the selection. This verifies keyboard traversal and rendered availability, not floating-panel appearance or full screenshot identity.

### History-Off Completed Reset Markers — 2026-11-05

Reproduced a functional mismatch in the fixed-date `due` demo: after History was switched off, a grouped marker for four completed resets at Nov 4 10:10 AM remained in the timeline. Windows excludes all historical events from both historical marker layout and overview dots when historyEnabled is false. Mac now returns no historical events while History is off; both drawing paths consume this filtered list.

Canonical build passed (`artifacts/history-off-markers-build.log`). Native demo verification confirmed the completed reset marker exists with History on, disappears with History off while the future earned-reset expiration stays visible, and returns after re-enabling History. Evidence: `artifacts/history-off-markers-check.json` and `artifacts/history-off-markers-fixed.jpg`. Left History enabled. No live provider settings were changed; full-image parity remains open.

### Historical Group Ordering — 2026-11-05

HistoricalEventMarker now stably sorts visible events by timestamp, preserves the first-seen order of timestamp/kind groups, and retains source account order inside each group. This matches Windows HistoryTimelineView's OrderBy followed by GroupBy. Previously Mac forced refresh before expiration for ties and sorted popup entries by opaque event IDs. Exact timestamps, visibility clipping, grouping keys and collision spacing remain unchanged.

Updated the existing regression test to expect source ordering and added an expiration-first tie case. Canonical app build and build-for-testing passed (`artifacts/historical-group-order-build.log`, `artifacts/historical-group-order-test-build.log`). Standalone harness used the production HistoricalEventMarker declaration and HorizonViewport with a minimal event fixture; grouping, lanes, account order, future exclusion and timestamp assertions passed (`artifacts/historical-group-order-check.swift`). Hosted XCTest execution remains unverified due to the previously observed loader stall.

Opened the four-event historical marker in the fixed-date due demo. Native popup AX confirmed OpenAI Personal, GitHub Copilot Work, OpenAI Work, Claude Personal order, matching the account selectors (`artifacts/historical-group-order-ax.txt`). Closed the popup afterward. Full-image parity remains open.

### First Recorded History Boundary — 2026-11-05

Windows Reflow supplies the earliest series observation (or now when empty) to the viewport. Mac had the same viewport capability but never passed earliestHistory. The view now supplies that date and updates the geometry when it changes. HorizonPresentation builds its source series from the fixed seven-calendar-day history range independently of the viewport, preventing History-off or a narrowed viewport from discarding observations needed when History is enabled again.

Canonical build and test-target build passed (`artifacts/history-range-build.log`, `artifacts/history-range-test-build.log`). Added a regression for a short retained history, disabled/enabled presentation equality, and left-bound clamping. Standalone validation compiled the actual Models and Format sources with the production PersistedState/HistoryRun declarations extracted from LocalStore; short-history and toggle-retention assertions passed (`artifacts/history-range-check.swift`). The initial fixture incorrectly assumed an exact-hour observation across the demo DST transition; corrected it to use the actual earliest retained observation and confirmed it predates now. Hosted XCTest execution remains unverified.

Native fixed-date compact demo: toggled History off/on, then decremented the navigator eight days. It clamped to Wed Oct 28 10:11 AM, the first recorded observation. Evidence `artifacts/history-range-ax.json`. The off-mode selector does not display the older History Begins hint because its viewport starts today; the model harness separately verifies retained samples. Full screenshot identity remains open.

### History Coverage and Hover Bounds — 2026-11-05

Selector help and history readouts now show History Begins only when the first observation is after the actual viewport origin, matching Windows StartAt. The old comparison against the origin day's midnight incorrectly added this note when the timeline already began at the first observation. Comparing projected positions also avoids a calendar-coordinate round-trip for this boundary.

Hover selection now rejects disabled history, pointers outside the visible horizontal range, future positions, and positions outside the plot before searching samples. This matches Windows Hover's early bounds checks and avoids unnecessary history scans over non-history regions. Existing nearest-point tolerance and interpolation are unchanged.

Canonical build passed (`artifacts/history-hover-boundary-build.log`); diff checks passed. Native fixed-date demo AX confirms History on and no redundant History Begins warning in account help (`artifacts/history-hover-boundary-ax.txt`). Ordinary mouse hover boundary behavior and floating popup rendering were not directly exercised in this pass; those remain verification gaps.

### Bounded History Sample Searches — 2026-11-05

Replaced whole-history scans for hover candidates, keyboard-visible samples, and endpoint labels with binary lower/upper bounds on projected timestamps. The inclusive slice preserves duplicate observations at both boundaries and their existing order. Estimated gap inspection now locates the following observation with binary search too, matching Windows' search strategy; interpolation and hit tolerance are unchanged.

Canonical app build and test-target build passed (`artifacts/history-bounded-search-build.log`, `artifacts/history-bounded-search-test-build.log`). Added regression coverage for inclusive duplicate boundaries and a projection-count bound. Standalone validation compiled actual Models/Format sources and production persistence model declarations: 50,000 samples required 29 projections to select six points; empty/reversed/outside ranges and duplicate endpoints matched exhaustive scans. Across all fixed demo series and 101 horizontal positions, bounded hover candidates matched the previous scans. Estimated-point results across the same positions and six vertical positions matched the previous production implementation extracted from HEAD (`artifacts/history-bounded-search-check.swift`, `artifacts/history-linear-interpolation.swift`). Hosted XCTest runtime and end-to-end pointer smoothness remain unverified; no wall-clock UI performance claim.

### Historical and Confirmation Message Formatting — 2026-11-05

Windows ThemedDialogs.ShowAsync builds each message line separately with 8-point spacing, 6-point blank-line separators, and a bright semibold label when a colon occurs after a short nonnumeric prefix. Added DialogMessage with those rules and used it for historical-event and confirmation messages. Previously these were single Text blocks with normal line spacing and no label emphasis. DetailLine now requests the bundled Segoe UI Semibold face explicitly rather than applying a generic font-weight modifier to regular Segoe UI.

Canonical build passed (`artifacts/dialog-message-format-build.log`). Extracted production Format.dialogLine checks passed for label whitespace, time strings, Unicode decimal digits, no-colon/leading-colon lines, and the 44/45 UTF-16-unit prefix boundary (`artifacts/dialog-message-check.swift`). Native fixed-date due demo popup visibly shows all four accounts, bold Quota Refresh labels and section gaps without clipping (`artifacts/dialog-message-history.jpg`); closed it afterward. Exact whole-dialog screenshot parity and all confirmation variants remain open.

### Text-Driven Dialog Action Icons — 2026-11-05

Ported Windows ActionButton.GlyphFor's ordered text mapping to Format.actionGlyph and applied it to DialogActionLabel. Removed obsolete per-call symbol overrides and the generic checkmark default for primary confirmation actions. Remove Account now maps to Segoe Fluent trash; Keep N Days uses the Windows fallback external-arrow glyph; Add Color, Cancel, Close and shared connection/settings/banner actions follow the same source rules. Icon size remains 20 points with 9-point text spacing.

Canonical build passed after updating all shared-label call sites (`artifacts/dialog-action-glyph-build.log`). Extracted production mapping checks passed for removal, retention, add/cancel/close, preview precedence, notification, info, snooze and token labels (`artifacts/dialog-action-glyph-check.swift`). Opened the 30-day retention confirmation in an isolated demo: native capture `artifacts/dialog-action-confirmation.jpg` visibly confirms the arrow and cancel glyphs. Cancelled and verified retention remained 90 Days, then closed Settings. No records were deleted. Other confirmation variants and exact hover-state styling remain open.

### Windows 3c863a5 Countdown Tooltips — 2026-11-05

Fetched Windows origin/main; new commit 3c863a5 makes future timeline event tooltips share quota-row countdown styling. Ported the change: quota refresh context includes Quota Refresh plus the window title; expiry context identifies Earned Reset Expires plus the account. Both show 20-point Segoe UI Semibold remaining time in #BDA3F5 and a 12-point #BEC1D2 exact date with 3-point spacing. ResetCountdownText is shared between quota rows and tooltip content. ImmediateResetTooltip snapshots the current clock on pointer entry, matching Windows ToolTip.Opened; explicit demo reference time remains deterministic. Accessibility hints preserve the prior event description, as Windows does. Existing click dismissal, owner-window bounds and geometry dismissal remain in use.

Canonical build passed (`artifacts/timeline-reset-tooltip-build.log`). An offscreen SwiftUI ImageRenderer harness compiled the actual tooltip/countdown views, typography, Format and Models with extracted production persistence declarations and a minimal theme fixture. Explicitly registered the bundled Segoe fonts. Refresh, expiry and narrow tooltip renders succeeded at 418×210, 336×210 and 360×244 pixels; inspected refresh and narrow images for correct typography and wrapping (`artifacts/reset-tooltip-*.png`, harness `artifacts/reset-tooltip-render.swift`). These are component renders, not native hover captures. Real pointer opening/placement and all final per-image comparisons remain open. The Windows reference image pack was not changed by this commit; source now supersedes its older timeline tooltip screenshot.

### Hosted XCTest Startup Resolved — 2026-11-05

A fresh targeted test reproduced the pre-main dyld stall. Attached LLDB, located the pathname saved in mapFileReadOnly's x24 register, and identified the blocked file as the build-products staging Sparkle.framework binary (`artifacts/host-loader-blocked-path.log`). Its on-disk signature verifies, but loading that copy stalls in this test environment. Prepending the app's embedded framework directory to the generated test manifest's DYLD_FRAMEWORK_PATH allowed the same targeted XCTest to execute successfully. No framework contents, signing policy or system security protections were changed.

Added executable `script/test.sh`: build-for-testing, create a sibling generated manifest with the embedded framework first for ScroogeTests, and execute the unit suite. README now documents this path. Script syntax and targeted execution passed. The first full run uncovered an outdated popup lifecycle fixture expecting a popup from a non-key window; replaced focus-dependent setup with an explicit test window key-state override and added an inactive-window suppression assertion. This is component lifecycle coverage, not real pointer-entry proof.

After that fixture correction, **all 89 hosted unit tests passed, zero failures**, in `artifacts/full-unit-embedded-framework.log`. This supersedes earlier statements that hosted XCTest runtime was unverified for these tests. UI tests, ordinary pointer hover and full visual parity are still open. The run also logged an empty-history Date onChange loop warning; follow-up required. The earlier CUA drag attempt still did not produce a visible event tooltip and is not counted as hover success.

### Empty-History Update Loop — 2026-11-05

The newly executable hosted tests exposed a SwiftUI repeated-update warning at empty-dashboard startup. earliestRecordedHistory used a fresh live Date fallback, so observing that property treated every render as a new history boundary. It now remains nil while there are no observations; the live-clock fallback is applied only when updating viewport geometry. This preserves the Windows no-history boundary without generating a Date onChange feedback loop.

Canonical build passed (`artifacts/empty-history-update-build.log`). Ran the new `script/test.sh` end to end: all 89 hosted unit tests passed, zero failures (`artifacts/empty-history-update-tests.log`). Unlike the prior full-suite log, this run has no "multiple times per frame" warning. No full visual or live-provider completion claim.

### Compact Quota Row Layout — 2026-11-05

Compared current Windows QuotaRowView.SetWideLayout against the Mac compact layout. Windows spans the quota label across both columns when there is no reset and vertically centers quota and reset content. The Mac retained an empty half-width reset slot and top alignment. Compact rows now omit that slot when resetsAt is nil and use centered alignment when a countdown exists. Wide layout is unchanged.

Canonical build passed (`artifacts/compact-quota-layout-build.log`); all 89 hosted unit tests passed (`artifacts/compact-quota-layout-tests.log`). Launched the isolated fixed-date compact no-reset demo and captured native account rows (`artifacts/compact-no-reset-layout.jpg`): no countdowns or clipping observed. Source inspection proves the conditional width allocation; this short-label capture does not establish long-label wrapping or exact per-image parity. Current Windows DashboardState still specifies lowercase used/left and Demo data, so these were preserved despite older screenshot capitalization. Full visual parity remains open.

### Account Identity Opens Quota Details — 2026-11-05

Windows AccountQuotaView's identity overlay invokes MainPage.OpenAccount with the first quota window ID. The Mac identity button incorrectly opened account settings. It now opens the shared AccountUsageDetailsView for the first quota window when the account is enabled and its snapshot belongs to the current identity and has windows. Accounts without usable quota rows retain the settings action; the separate gear action is unchanged.

Canonical build passed (`artifacts/account-identity-details-build.log`); all 89 hosted tests passed (`artifacts/account-identity-details-tests.log`). Native demo verification clicked OpenAI Personal identity and confirmed a Codex 5-Hour details sheet with 38% used / 62% left, rather than settings or earned resets (`artifacts/account-identity-details.jpg`). Dismissed it, clicked Manage Personal, and confirmed the Account Name, Line Color, Polling Interval and Monitor This Account settings controls. Closed settings without changes. This establishes action routing in demo, not live-provider or complete visual parity.

### Accounts Without Quota Rows — 2026-11-05

Matched MainPage's no-row account presentation: disabled accounts and accounts without a usable snapshot/window now show a 70-point-minimum shared action button containing provider, nickname, status and Manage account, instead of the full provider identity and quota-column layout. Retained reorder controls and the separate gear. The shared text-to-icon mapping supplies the Windows settings glyph. Privacy masking and snapshot identity checks are retained; mismatched snapshots cannot supply status text or quota content.

Canonical build passed (`artifacts/account-status-card-build.log`); all 89 hosted tests passed (`artifacts/account-status-card-tests.log`). In an isolated compact demo, disabled OpenAI Personal, observed its short Monitoring disabled status card (`artifacts/account-disabled-status.jpg`), clicked that status button to reopen settings, re-enabled monitoring, and confirmed the identity and quota details buttons returned. This verifies the disabled-state transition; empty-window and long-status visual variants remain to be captured.

### Account Control Hints and Borders — 2026-11-05

Matched WithAccountSettings' full provider/nickname/plan settings description for both the gear tooltip and accessibility label. Identity controls now explicitly announce the account and Open details, matching AccountQuotaView rather than repeating the logo's provider name. Privacy masking remains in both labels. Corrected the gear outline from the outer-card #383B46 to ActionButton's #45464D.

Canonical build passed (`artifacts/account-control-parity-build.log`). Fresh native compact demo accessibility inspection confirmed all four identity labels and all four provider-qualified settings labels. This is label/source-color verification, not proof of native hover opening or pixel-identical border rendering. Reused the immediately prior 89-test pass for unchanged behavior; no domain logic changed in this update.

### Usage Bar Semibold Face — 2026-11-05

Refreshed Windows origin/main: still 3c863a5, with no new source changes. UsageBar.cs explicitly selects Segoe UI Semibold at 16 points for the used label and regular 16-point text for the remaining label. The Mac used generic fontWeight on inherited regular Segoe. It now calls Font.reference(size: 16, weight: .semibold), which explicitly resolves the bundled SegoeUI-SemiBold face, consistent with the other corrected reference headings and labels. No generic fontWeight or semibold weight modifiers remain in Views/Support.

Canonical build and diff whitespace checks passed (`artifacts/usage-label-font-build.log`). This verifies compilation and explicit font selection in source; it does not establish pixel-identical font metrics. Existing behavioral tests were not rerun for this font-only change. Final native screenshot comparisons remain open.

### Fresh Compact Account Comparison — 2026-11-05

Captured the b0d92ad app after all recent account/font changes using --demo --compact --reference-date 2026-11-04T16:11:00Z, then scrolled outside Reset Horizon to expose the first two accounts. Native capture artifacts/compact-rows-segoe.jpg is 1578×1388 Retina pixels, representing the intended 789×694-point window. Compared against reference 27-compact-account-rows.png (789×694).

The first complete card is approximately 290 points tall versus 285 in the reference; content starts around x109 versus x112. These are visual estimates, not automated pixel measurements. The differently scrolled card top and native window chrome prevent raw full-frame comparison. Text, first/second usage bars, settings and alarms are unclipped. Used text now explicitly selects the bundled Semibold face. Capture fixture resets differ from the reference (12:25 versus 12:30, and fixed countdown versus elapsed capture), so those strings are not evidence of a format defect. Source confirms reorder columns remain 56+1 and content padding 20/8/16/8 on both platforms. Remaining geometry needs border-inset/font-line-box measurement before changing source constants. Updated status row 27; no claim of visual identity or live-provider verification.

### Demo Flow Test Assertion Refresh — 2026-11-05

The existing XCTest UI scenario expected Exit Demo, but current Windows MainPage and Mac source specify Exit demo. Corrected that assertion and made app termination deferred so thrown test errors also clean up the test process. No production behavior changed.

Replayed the scenario through native computer use against the isolated compact demo: History off retained the OpenAI Personal selector, History on restored the switch state, and Exit demo returned Add account plus Explore with demo data. script/test.sh rebuilt both test targets and all 89 unit tests passed (`artifacts/ui-flow-assertion-tests.log`). The XCTest UI runner was not executed; this is native computer-use flow evidence plus test compilation, not a claim of an XCTest UI pass. Container inspection also reconfirmed Windows body padding 32/24/32/32 and account reorder widths 56+1; remaining pixel/line-box differences require measurement rather than changing these matching constants.

### Segoe UI Symbol Account Reorder Glyph — 2026-11-05

Windows MainPage.Ordering uses U+283F in Segoe UI Symbol at 25 points for account reorder grips. Replaced the Mac's six manually drawn circles with that exact character and font selection. Bundled SegoeUISymbol.ttf from the installed Microsoft Word application's DFonts/seguisym.ttf; CoreText reports PostScript name SegoeUISymbol and maps U+283F to glyph 1856. SHA-256 5822500a2b7659b076aa340e9e13c3ea651682d9dbebef3f60e3d656a996048b matches the source resource and built app copy. Regenerated the Xcode project for the new resource. Existing 56×44 drag target and behavior are unchanged.

Canonical build passed (`artifacts/reorder-symbol-font-build.log`). Native compact capture `artifacts/reorder-segoe-symbol.jpg` shows the glyph without clipping on the first two accounts. Hosted unit suite passed (`artifacts/reorder-symbol-font-tests.log`). This establishes font/glyph use and packaging, not identical rasterization across macOS/Windows font versions or a new drag-interaction verification.

### Reference Checkmark Shapes — 2026-11-05

Removed two SF Symbol substitutions. Timeline selector checkmarks now use HistoryTimelineView's exact polyline points (1,6), (4.5,9.5), (11,2.5), 2.5-point white round-cap stroke and 12×12 layout inside the existing 19-point checkbox. Selected account color swatches now use U+2713 text, 14-point reference font (Windows App.xaml Button default), and #141519 foreground, matching SettingsPage rather than a black SF Symbol.

Canonical build and diff checks passed (`artifacts/reference-checkmarks-build.log`). Native compact screenshots show the timeline marks (`artifacts/reference-timeline-checkmarks.jpg`) and selected pink swatch text mark (`artifacts/reference-swatch-checkmark.jpg`) without clipping. Closed account settings without editing. Prior 89-test pass retained for unchanged behavior; no new behavioral tests added for these visual replacements. Cross-platform rasterization and final full-image comparison remain open.

### Missing-Plan Timeline Badges — 2026-11-05

Windows HistoryTimelineView substitutes the history period when PlanLabel is Plan unavailable. Added Format.historyPlanBadge and applied it only to selector badges: missing or unknown plans show Monthly for Copilot and Weekly for OpenAI/Claude. Known plans still display their provider-specific labels. Tooltip/account plan text continues to report Plan unavailable rather than implying a subscription tier.

Canonical build passed (`artifacts/history-plan-badge-build.log`). Added regression assertions for nil, unknown and known plan values; all 89 hosted tests passed (`artifacts/history-plan-badge-tests.log`). Native missing-plan screenshot remains open; the normal demo supplies known plans, so its existing captures do not establish this edge-state layout.

### Missing Plans and Empty Windows: Native Edge-State Verification — 2026-11-05

Added opt-in demo scenarios missing-plan and empty-windows, documented in README. The latter includes one long status message and three nil-message waiting states. These fixtures are only applied inside demo construction and never edit saved provider connections.

Canonical build passed (`artifacts/edge-demo-fixtures-build.log`); all 89 hosted tests passed (`artifacts/edge-demo-fixtures-tests.log`). Native compact missing-plan capture shows Weekly on both OpenAI selectors and Claude, Monthly on Copilot, with no badge clipping (`artifacts/missing-plan-selectors.jpg`). Plan unavailable remains in account/tooltip metadata. Native compact empty-windows capture shows all four short status cards and the longer first message wrapping onto two lines without clipping (`artifacts/empty-window-status-cards.jpg`). This closes the previously unobserved missing-plan badge and empty-window/long-status rendering checks at compact size. It does not certify pixel identity with Windows or live-provider behavior.

### Timeline Selector Action Semantics — 2026-11-05

Matched Windows selector descriptions: visible accounts announce Hide, hidden accounts announce Show, with provider/account/plan and Timeline context. Added stable timelineAccount-<id> identifiers. Reorder handle hints/labels now match Windows' Drag provider / nickname to Reorder Accounts description. Privacy masking is retained. Updated the existing UI scenario's selector expectation to the current visible-account action wording; turning History off does not hide the account itself.

Canonical build passed (`artifacts/timeline-selector-actions-build.log`); all 89 hosted unit tests passed and UI test target compiled (`artifacts/timeline-selector-actions-tests.log`). Native demo toggled OpenAI Personal: Hide label with 7 refreshes/2 expirations became Show with 5/0, then restored Hide and 7/2. This verifies label/state transitions through computer use; the XCTest UI runner remains unexecuted. Long nickname geometry still needs a separate comparison.

### Long Selector Nickname Verification — 2026-11-05

In the isolated demo, renamed OpenAI Personal to Personal Development Workspace through account settings. Native compact timeline capture (`artifacts/long-nickname-selector.jpg`) shows a single-line tail ellipsis without overlapping the selection checkmark or chart. Accessibility description and tooltip content preserve the full nickname. Windows specifies centered nickname badges with a 90-point maximum and tail truncation; the Mac's containing selector currently constrains the badge to its available width. No guessed width change was made from the maximum alone.

Restored the demo nickname to Personal through settings and verified the restored Hide OpenAI / Personal · Plus · Timeline description. No saved provider account was edited. This completes the observed long-name clipping check at compact width, not exact Windows width/rasterization parity or real pointer tooltip opening. Documentation-only update; reused the prior passing build/unit results.

### Native App Menu Verification and Acceptance Refresh — 2026-11-05

Checked the isolated running demo through native menus. View > Privacy Mode changed account-specific selector and gear descriptions to Account; toggling it again restored Personal/Work. App menu > Settings opened the standalone AI Token Scrooge Settings window; its Close action returned to the same dashboard. These are native app-menu checks, not Dock or menu-bar companion verification.

Re-read acceptance.md and corrected stale evidence: 89 current hosted tests supersede the old 71-test count; Preview 38 is no longer the current code because later commits include production and font changes. Current-commit packaged-release verification remains open. Rechecked local Claude CLI: still 2.1.308. Requested the user's choice of live provider to avoid using unrelated existing CLI credentials. No live sign-in was initiated. Documentation-only update; no build rerun needed.

### Release Preview Launch and Resource Verification — 2026-11-05

Packaging current source (0515561 plus this script change) exposed a real launch failure despite successful build, checksum and strict signature checks: hardened-runtime library validation rejected Sparkle in the ad-hoc app before main. Re-signing Sparkle ad hoc in a disposable extracted copy did not fix it. Preview packaging now explicitly disables hardened runtime when no signing identity is supplied, matching Debug; the Developer ID path retains hardened runtime and remains separately unverified. No system security settings were changed.

Added byte-for-byte verification of all 23 font, image and sound resources during packaging. The corrected Release archive passes those comparisons, arm64 validation, checksum and strict deep signature verification. Extracted artifacts/current-preview-fixed/AI Token Scrooge.app launched successfully with an isolated missing-plan demo; native computer use observed the dashboard. Signature flags confirm ad-hoc signing without runtime. Evidence: artifacts/current-preview-validation-fixed.log and artifacts/package/signature.txt. Shell syntax and diff checks pass. Prior 89 hosted test results cover unchanged app behavior; no unit rerun for this packaging-only change.

The local v2026.11.5.000 archive is a development preview, not notarized and not published. This does not close verification of a newly published/downloaded release or Developer ID distribution. The earlier failed extraction under current-preview-unpacked is not a deliverable.

### Account Ordering: Reach the Last Position — 2026-11-05

Compared Windows MainPage.Ordering.cs and AccountDragController.cs with the Mac drop handling. Mac previously always inserted before the destination, making the last slot unreachable. Drop handling now uses each card's measured midpoint: upper half inserts before, lower half inserts after, including after the last card. Moved the ordering mutation into AccountPolicy while retaining AppStore's serialized persistence path. Rejects self, unknown-account, multiple-item and non-custom-sort drops.

Canonical build passes (artifacts/account-drop-build.log); all 90 hosted tests pass (artifacts/account-drop-tests.log), including both list endpoints, a downward neighboring move and invalid/non-custom moves. UI target compiles; native drag/drop and its midpoint geometry have not yet been verified with a pointer. This is an ordering fix, not full drag parity: Windows whole-card vertical movement, displaced-card animation, edge auto-scroll, and cancellation/restoration remain open.

### Windows Drag Layout Foundation — 2026-11-05

Ported the reference AccountDragLayout calculation directly: stable placeholder slots cross neighboring card centers, variable-height cards retain the correct gap, and edge scrolling uses the same 56-point zone with a 10-point maximum per tick. Added invalid/nonfinite geometry guards. The four Windows regression scenarios are represented, plus single-card and invalid-geometry coverage.

Canonical build passes (artifacts/account-drag-layout-build.log); all 95 hosted tests pass (artifacts/account-drag-layout-tests.log). Xcode project regenerated to include both new files. This calculation is not yet connected to the native drag controller, so this commit does not change visible dragging or close the interaction gate. Next integration must capture the grip pointer, move the real card vertically with its grab offset, animate displaced cards for 110 ms, tick auto-scroll every 16 ms only inside the viewport, and settle/restore over 140 ms. Match Windows cancellation on Escape, capture loss and resize; preserve the original scroll position on cancel and persist only the final valid slot.

### Native Whole-Card Drag Integration — 2026-11-05

Replaced the text drag/drop shortcut with a narrow AppKit grip and dashboard-owned observable controller. The real SwiftUI card moves vertically with its original grab offset, .94 opacity, 2-point accent border and shadow. Neighbors use the Windows variable-height placeholder calculation and 110 ms cubic-out movement; release settles over 140 ms. A 16 ms timer applies the reference edge-scroll delta only inside the list. Escape, leaving the list on release, window resize/deactivation/close, card geometry changes and account/sort changes cancel. Cancellation restores the starting scroll position; observers and timers are detached on finish. Native grip accessibility descriptions are retained.

Only a completed valid slot is persisted through AppStore's serialized mutation path. The controller waits for that operation before removing presentation offsets. A stale original order, removed account, invalid slot or non-custom sort cannot overwrite newer state. Removed the superseded midpoint drop handler and its unused policy helper.

Canonical build passes (artifacts/native-account-drag-build.log); all 95 hosted tests pass (artifacts/native-account-drag-tests.log), including real local-database order persistence, stale/invalid rejection, both endpoints and the reference layout scenarios. Native computer use moved OpenAI Personal first-to-last and back in the empty-windows demo, and releasing over the header preserved its order. In the rebuilt regular demo, the shorter GitHub card moved above the taller OpenAI card; accessibility order and screenshot confirm the result (artifacts/native-account-drag.jpg).

A quick automated drag toward the lower edge did not establish sustained scrolling; do not treat the timer's implementation as runtime proof. Holding at edges, Escape during a held drag, resize during a held drag, persistence-failure presentation and perceived animation smoothness remain open. XCTest UI runner not executed. No live provider account was changed.

### GitHub Challenge Prompt and Remaining Font Fallbacks — 2026-11-05

Fetched Windows origin/main: still 3c863a5. Compared ConnectAccountPage.GitHub.cs and ReminderEditor.cs. The Mac GitHub challenge previously used a 30-point system monospaced code, code-before-instruction ordering, and side-by-side text-only actions. It now matches the source's centered instruction, centered 28-point Segoe UI Semibold code in #B5A0F4, 10-point spacing, and stacked Copy code/Open GitHub action buttons with shared reference icons. Added the Windows sign-in-code accessibility description and copy success/failure feedback; failed browser handoff now reports a usable fallback. No live challenge requested and no credentials accessed.

Removed remaining caption-font substitutions in the provider-details browser note (14-point reference dialog text, matching the Windows dialog body) and Mac-specific login-item status (explicit 12-point reference text). Reminder fields now expose the source's Reminder Severity, Time Before Event, and Days or Hours descriptions. Corrected the lifted account card's border to the source's #B5A0F4 accent.

Canonical build passes (artifacts/sign-in-prompt-parity-build.log), and diff checks pass. Prior 95 hosted test results retained for unchanged provider transports and ordering behavior. The challenge prompt is source-verified but has not been captured during a live sign-in; clipboard feedback/browser-failure branches remain runtime-unverified. No claim of full screenshot identity.

### Connection Action Order and Reminder Accessibility — 2026-11-05

A second source pass through ConnectAccountPage.cs confirmed the GitHub challenge belongs after the status and sign-in action. Moved that prompt below the action (its internal instruction/code/buttons order remains as corrected previously).

Native global Settings inspection exposed duplicate menu accessibility entries from decorative chevron images, and reminder menus did not announce selected severity/unit. Hid decorative arrows from accessibility in global settings, account settings and connection forms; reminder menus now expose their selected values. Rebuilt and natively verified one Time Zone entry, one retention entry, and single reminder entries with Info/Warning/Critical and Days/Hours values. No reminder values changed.

Fresh wide-demo captures: artifacts/settings-thresholds-current.jpg and artifacts/settings-reminders-current.jpg. Settings panel is 1000×800 points (2000×1600 Retina capture). Approximate threshold-card height is 243 points versus 244 in reference04; reminder controls remain 44 points tall with 6-point row gaps, matching source. Current text and controls fit without clipping within their rows. Platform text rasterization, borders/entry underlines, dropdown glyphs and exact per-image alignment still differ or remain unverified; no full visual-equivalence claim. Closed settings after inspection.

Canonical build passed (artifacts/settings-menu-accessibility-build.log); diff checks passed. Prior 95 hosted tests retained for these presentation/accessibility-only changes. No live sign-in initiated, and the challenge's complete live state remains unverified.

### Shared Live Quota Detail Footer — 2026-11-05

Windows OpenDetailsAsync supplies Open provider usage as the ContentDialog primary footer action, paired with Close. Mac previously rendered that action inside QuotaDetailsView's body. Added AccountUsageDialog and routed account identity, quota-row, current timeline event and alert-history detail entry points through it. The provider explanation remains in the body; opening the provider closes the dialog before handing off to the browser, and a failed handoff reports an error. Live two-action dialogs use the shared 480-point width so the footer labels fit; demo/reserve widths remain unchanged. Exact live Windows width comparison remains open.

Added a pure eligibility check: no action for demo data, missing accounts/windows, mismatched snapshot identities, or reserve details; valid current quota details retain their provider URL. The source-verified historical-schedule branch remains separate and now uses explicit 14-point reference text for its explanation.

Canonical build passes (artifacts/details-footer-build.log); all 96 hosted tests pass (artifacts/details-footer-tests.log), including the footer eligibility cases. Native compact demo identity click opens the complete first quota detail body with only Close; captured artifacts/details-shared-footer-demo.jpg and closed it successfully. This proves demo routing, not the live browser handoff or exact two-button pixels; those remain open pending a live connection.

### Matching-Timestamp Reset Popup Reveals Wrap Difference — 2026-11-05

Compared Platforms/Windows/App.xaml with shared Mac dialog styling: title #C3ADF8/22-point Semibold, background #222329, border #65577F, separator #3B3D47 and 16-point corners already match the source. A current-date native popup appeared approximately 332×281 points against reference35's approximately 332×282, but that was insufficient evidence because the strings differed.

Relaunched the unchanged build with --demo --compact --reference-date 2026-11-04T16:16:00Z and an isolated data directory. Captured artifacts/reset-details-reference-date.jpg. Text now matches reference35 exactly, including the 11/4/2026 10:16 AM snapshot and Nov8/Nov13 credit expirations. The Mac snapshot line wraps before Demo, increasing height to about 300 points; Windows keeps it on one line. This supersedes the earlier near-equal-height observation for exact parity. Closed the popup afterward.

CoreText reports bundled SegoeUI Regular version5.28; the matching timestamp line at 14 points measures 285.749 points against 284 points of body width. Downloaded the regular face from Microsoft's same sample commit used for Semibold (0be22d2d10aa8172053206fa3d3a29799817313a, unity/acsShowcase/Assets/Resources/Fonts/Segue UI/SegoeUI.ttf) into ignored artifacts/SegoeUI-sample.ttf only. It reports version5.05 and the same 285.749-point advance. Thus that font replacement would not solve the demonstrated wrap. Production fonts, dialog width and padding were not changed. Exact Windows shaping/advance comparison remains needed; this is a confirmed visual gap, not a passed full-image check. Documentation-only update, using the existing passing build.

### Popup Wrap Fixed with the Native WinUI Text Face — 2026-11-05

The prior measurement ruled out two versions of classic Segoe UI, but not the distinct Segoe UI Variable face selected by modern XAML TextBlocks. Microsoft documents that default at https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/typography and provides the official archive via https://learn.microsoft.com/en-us/windows/apps/design/downloads/ (https://aka.ms/SegoeUIVariable). Download resolved to https://download.microsoft.com/download/f/5/9/f5908651-3551-4a00-b8a0-1b46b5feb723/SegoeUI-VF.zip. Its static Text face measures the identical snapshot line at 276.9648 points, matching the roughly 277-point width in reference35, versus 285.749 for classic Segoe.

Bundled the official regular and Semibold static Text faces plus supplied EULA. Registered their explicit PostScript names, and applied them to shared dialog bodies, emphasized DetailLine labels and decorated dialog/action labels. Explicit classic Segoe headings and MAUI-style text retain their prior fonts. No dialog width, padding or font size changed. Regenerated the Xcode project.

Canonical build passes (artifacts/variable-dialog-font-build.log). Both font files in the built app are byte-identical to source. Native matching-date popup capture artifacts/reset-details-variable-font.jpg confirms the entire Snapshot fetched 11/4/2026 10:16 AM · Demo line fits without wrapping; popup returns to 332×281 points, within roughly one point of reference35. This resolves the demonstrated wrap discrepancy. Full rasterization/title/line-position identity is not certified. Closed popup after capture. No new behavioral tests for this font-only change; prior 96-test result retained.

Font SHA256: regular 4e79c52ac2123c0b1d8d62d5ccf1e4bb9599c9a17168e9272357e03fa80ac871; Semibold 9cbcaae3ab12ff94864dfe2f703ebd005d12f0f0579fd62369017d2d8e87577f.

### Native Action Button Font Parity — 2026-11-05

Windows ActionButton creates a native TextBlock without an explicit FontFamily; AccountSortControl sets its size to 13, while ordinary actions and alert-history row actions use 14. Applied the bundled Segoe UI Variable Text face to ScroogeButtonStyle, the explicit sort-label override, and alert-history row text. Preserved sizes, geometry, icons, and explicit classic Segoe labels elsewhere.

Canonical build passes (artifacts/native-button-font-build.log), and git diff --check passes. No new behavioral tests for this font-only change; previous 96 hosted-test result remains the behavioral baseline. This update was checked against Windows source; a new native screenshot comparison and full pixel parity remain open.

### Current Font Release Archive Verification — 2026-11-05

Packaged app source a691211 with script/package_preview.sh. Release build, all source font/image/sound byte comparisons (including both new Variable Text fonts), Info.plist lint, arm64 architecture, deep strict signature and ZIP checksum checks pass; log artifacts/current-font-release-validation.log. Extracted archive into artifacts/font-release-a691211 and independently verified its deep strict signature. Opened that extracted app with isolated compact demo data and fixed reference timestamp. Native accessibility tree confirms dashboard, timeline, account controls and sorting controls; artifacts/font-release-a691211-dashboard.jpg captures its rendered dashboard. This is actual extracted Release launch evidence, not just a Debug build. No full screenshot identity claim.

Windows App.xaml explicitly sets the plain ToolTip style to Segoe UI/13, so classic tooltip typography remains unchanged. The current Release is still ad-hoc signed, non-hardened and not notarized. This is local archive evidence only; publication and download verification remain open.

### Compact Sort Controls — 2026-11-05

Compared AccountSortControl.cs: native buttons use 8-point horizontal padding, centered wrapping and a selected-state accessibility description. Added the missing inner padding and centered multiline alignment to Mac sorting labels, and a native selected trait. Kept the shared ActionButton foreground behavior: Windows ApplyColors overrides its TextColor property, so the source initializer alone is not evidence to dim unselected labels.

Canonical build passes (artifacts/sort-control-parity-build.log). In an isolated compact demo, native accessibility now reports Custom Order selected; clicking Most Remaining moves the selected trait and reorders cards to Work OpenAI, Personal OpenAI, GitHub, Claude. Restored Custom Order; screenshot artifacts/sort-control-compact.jpg confirms all four labels fit without clipping at 789-point window width. This verifies compact layout and selection, not full screenshot identity or all narrower widths.

### Aligned Compact Account Card Check — 2026-11-05

Fetched Windows main: still 3c863a5. Reviewed AccountQuotaView, QuotaRowView, CapacityAlertToggle, UsageBar and WithOrderControls against current Mac: 56-point grip plus 1-point divider, content padding20/8/16/8, identity spacing16, identity-to-rows12, quota spacing4, compact row gap8, 81×48 alert toggle and 48-point bar all correspond. Windows App.xaml explicitly assigns classic Segoe UI to MAUI Labels, so the newly established native ActionButton TextBlock font does not justify replacing account label fonts globally.

Captured current compact app at a scroll position aligned closely to reference27: artifacts/compact-cards-aligned-current.jpg (1578×1388 Retina). In point coordinates the first card spans about y263–553 (290 high), versus reference y266–552 (286 high). Left card edges are about32 versus33; quota-content left edges about109 versus112. This confirms a remaining roughly4-point intrinsic-height difference independently of scroll offset, and a small horizontal inset difference. Header bottoms are about190 versus186, reflecting the window/header comparison separately. No arbitrary height or inset correction was applied: font line boxes and border layout need measurement before changing source-matched spacing. No production change or new test run; current f143a72 build remains the verified binary.

### Display-Synchronized Wheel Smoothing — 2026-11-05

Replaced HorizonWheelRouting's fixed120Hz Timer with NSView.displayLink(target:selector:), using CADisplayLink target timestamps. The installed AppKit SDK documents that this callback follows the display hosting the view. This removes unsynchronized timer-driven frame submissions while preserving the existing distance-conserving motion model. Precise trackpad events and Reduce Motion still take the immediate path. Hidden-view/detach teardown invalidates the link; an attached sheet stops pending animation.

Canonical build passes (artifacts/display-linked-wheel-build.log); subsequent test build includes hidden-view cleanup. All97 hosted tests pass (artifacts/display-linked-wheel-tests.log), including distance conservation at30/60/120/144Hz. Native isolated compact demo wheel input inside the card changes navigator from Nov4 midnight to Nov7 11:24AM while page offset remains0; outside-card wheel input moves page offset to0.2213 while navigator remains unchanged. This verifies routing after the change, not physical smoothness or a measured frame-time profile.

### Reuse Unchanged Floating Popup Content — 2026-11-05

HistoryPointerTracking previously constructed and installed a fresh NSHostingView on every showPopup call, including repeated pointer updates over the same sample. It now retains the hosted content until text, severity, plain-help mode, reset content or constrained width changes. Pointer/window positioning and fitting-size queries still run, preserving placement updates. ResetTooltipContent is Equatable so changing countdown/date/timezone invalidates the content correctly.

Canonical build passes (artifacts/history-popup-content-cache-build.log). Native compact isolated demo click plus arrow keys selects Claude history, then Right selects OpenAI Personal weekly73%; Escape returns accessibility details to No sample selected. Capture artifacts/history-popup-cache-check.jpg shows selected sample/guide in the dashboard but excludes the floating panel; it does not certify floating popup appearance. Physical hover and frame-time measurement remain open. Previous97-test baseline retained; no new tests for this view-allocation change.

### Connection Native Entry Typography — 2026-11-05

Windows ConnectAccountPage declares native Entry/Picker controls without a FontFamily override; App.xaml's classic Segoe UI style targets Labels, not those entry controls. Applied the bundled native Segoe UI Variable Text14 face to ConnectionFieldStyle (nickname, fallback allowance, token and organization fields) and the billing-unit selection label. Retained classic heading/explanation/status label fonts and existing sizes/layout.

Canonical build and diff checks pass (artifacts/connection-entry-font-build.log). Opened GitHub browser form in a fresh isolated compact app, captured artifacts/connection-entry-font-current.jpg: nickname, selected unit and full allowance placeholder fit their32-point fields. Cancelled without initiating sign-in and restored demo. This is a local layout check, not live authentication or full screenshot identity. No new tests for the font-only edit.

### Settings Native Control Typography — 2026-11-05

Applied the native Segoe UI Variable Text face to time-zone and retention selections, reminder severity/unit selections and amount fields, sound radio labels, and the account-name entry. These correspond to Windows Picker/Entry/RadioButton controls without explicit family overrides; classic Label headings, descriptions and switch captions remain unchanged. Time-zone selected text now uses14 points rather than the prior13-point parent override, matching native control text sizing.

Canonical build passes (artifacts/settings-native-font-build.log), as does diff checking. Native compact Settings capture artifacts/settings-native-font-current.jpg shows full Central Time selection and90 Days fitting their controls; account-native-font-current.jpg shows the Personal name fitting the focused account entry. Both panels close with Escape, with no values edited. Reminder/radio font changes compile but their updated scrolled sections have not been recaptured in this pass. Full pixel parity remains open; no new tests for these font-only changes.

### Published Preview Custom Color Keyboard Check — 2026-11-05

Used downloaded Preview272 (45b2364) in its isolated demo. Opened Personal OpenAI Account Settings → Add Custom Line Color. Entered #123456 by keyboard in Hex Color and pressed Tab: selected-color value becomes #123456 and RGB fields become18/52/86. Add Color inserts the swatch; reopening the editor initializes with #123456. Replaced the draft with #FFFFFF and pressed Escape: no white swatch was added, and reopening still initializes #123456. Closed both panels. No live account or underlying non-demo settings were changed.

This verifies keyboard hex input, RGB synchronization, accepted selection and cancellation preservation in the published binary. Named-color tooltips, full keyboard traversal and exact spectrum pixels remain open; no source change or new build was needed.

### Connection Placeholder Contrast — 2026-11-05

Windows App.xaml explicitly sets Entry.PlaceholderColor to #B6B8C8. Mac TextField/SecureField prompts previously inherited the system placeholder color. Added explicit reference-colored prompts for nickname, fallback allowance, personal token and organization fields, retaining their labels, secure input, bindings, native text face and dimensions.

Canonical build and diff checks pass (artifacts/connection-placeholder-color-build.log). This pass verifies source color and compilation; a fresh rendered color comparison remains open. No behavioral tests were added for this presentation-only change. Relaunched the Debug demo.

### Native UI Test Runner Initialization — 2026-11-05

Attempted the existing DashboardUITests test using test-without-building, the generated embedded-framework manifest, and only-testing:ScroogeUITests against source27834c8. The runner launched but failed before any test assertion with “Timed out while enabling automation mode.” A process sample located the wait in XCUIDevice.enableAutomationMode; testmanagerd logs show local authentication requested for “Enable UI Automation.” This is an environment/authentication prerequisite failure, not a dashboard assertion failure. No macOS security settings were changed. Requested the user authorize the system prompt if present; do not retry until that prerequisite changes.

Evidence: artifacts/native-ui-test-run.log and artifacts/ui-runner-startup-sample.txt. Existing hosted-unit results remain valid; native UI assertions and physical history hover remain open.

### Current Published Preview276 — 2026-11-05

GitHub run42124255236 completed successfully for27834c85b5877fd790df8e445d993af61c9d8710, publishing preview-276-1. Hosted suite reports98 tests, zero failures, two installed-CLI skips. Downloaded the release archive (not just the build artifact); SHA25655b1ec105cb5355c0f742ad72c58d71ac2eaddb635aa21c7a5f8a78a03b4be2e matches the published checksum. Strict deep codesign verification and arm64 architecture pass. All25 bundled font/image/sound files match source bytes.

Opened the extracted app with --demo --compact and a fresh isolated data directory. Native accessibility shows all four demo accounts, History enabled and Custom Order selected. Saved artifacts/preview-276-native-launch.jpg; CI log is artifacts/preview-276-ci.log. This closes the current-source archive recheck after the placeholder-color change, not full feature parity or clean-machine Gatekeeper acceptance. Preview remains ad-hoc, non-hardened and not notarized.

### Packaged Settings Typography Inspection — 2026-11-05

Inspected the previously unrecaptured native-control font changes in downloaded Preview276 at27834c8. In the compact741×630-point Settings sheet, Duck Sounds and Classic Chimes fit fully; severity names Info/Warning/Critical, reminder amounts including12, and Days/Hours fit their controls without text clipping. Scrolled both earned-reset and quota-refresh lists through their lower rows and Add Reminder buttons. Closed with Escape without editing values or playing audio.

Captures: artifacts/preview-276-sound-fonts.jpg, preview-276-reminder-fonts.jpg, preview-276-refresh-reminder-fonts.jpg. Compared the reminder structure against reference05; this establishes current rendered text fit, not exact border, glyph or pixel parity with the wide Windows reference. No application changes or additional build required; published archive validation from the preceding check still applies.

### Settings Picker Corner Parity — 2026-11-05

Windows Platforms/Windows/App.xaml explicitly sets ControlCornerRadius to10. Reminder controls already used10; the Time Zone and history-retention picker backgrounds/outlines still used8. Corrected both to10 without changing dimensions, text or behavior.

Canonical Debug build succeeds (artifacts/settings-picker-radius-build.log); native compact Settings shows complete Central Time and90 Days selections with the updated outlines (artifacts/settings-picker-radius-current.jpg). Closed with Escape without changing settings. Diff checks pass; no behavioral tests added for this shape-only change. Preview276 predates this correction; repeat final archive verification after application changes settle.

### Dropdown Chevron Glyph Parity — 2026-11-05

Replaced five SF Symbol dropdown arrows with shared ReferenceDropdownChevron using bundled Segoe Fluent Icons U+E70D at12 points in a12×12 frame. Applies to time zone, retention, reminder severity/unit labels, GitHub billing unit and color-model selector. Microsoft’s ComboBox template declares this glyph/size as its static fallback: https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/ComboBox/ComboBox_themeresources.xaml . The Mac uses the static glyph; WinUI animated opening transitions are not reproduced by this change. Existing foreground colors and menu behavior remain intact.

Canonical build passes (artifacts/dropdown-chevron-build.log). Native compact Settings renders both top-level arrows (artifacts/dropdown-chevron-current.jpg); retention menu opens with all six expected options and Escape dismisses menu and settings without value changes. Other shared-component placements compile but were not separately recaptured. No new behavioral tests for the icon-only change; full pixel parity remains open.

### Color Picker Native Typography and Corners — 2026-11-05

The custom color editor retained classic13-point input text,12-point channel labels,8-point corners and inherited muted dialog text. Windows uses the native ColorPicker without font overrides; its template uses standard TextBox/ComboBox/TextBlock elements and binds spectrum/preview corners to ControlCornerRadius (10 in the app). Updated the editor to native Segoe UI Variable Text14, primary text color and10-point spectrum, preview, selector and entry corners. Preserved input dimensions and value handling. Source: https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/ColorPicker/ColorPicker.xaml ; inspected local copies artifacts/winui-color-picker.xaml and winui-color-picker-template.xaml.

Canonical build succeeds (artifacts/color-picker-native-style-build.log). Native compact editor shows full RGB, hex and Red text; keyboard hex #123456 updates selected color and channels to18/52/86. Saved artifacts/color-picker-native-style-current.jpg; cancelled without adding a color, then closed account settings. Lower channel rows remain available through the existing scroll area. This does not close exact spectrum pixels or named-color tooltip gaps.

### Color Name Tooltip Behavior Audit — 2026-11-05

Inspected Microsoft ColorSpectrum.cpp: OnGotFocus opens ColorNameToolTip, OnLostFocus closes it, and OnColorChanged updates its content using ColorDisplayNameHelper.ToDisplayName(newColor). Pointer-enter/exit only update visual state; pointer movement without a press does not select a new color. Therefore the parity requirement is a selected-color name while the spectrum has focus, not a name for arbitrary hovered coordinates.

The Mac InlineLineColorEditor has focus/selection handling but no color-name tooltip. This is a confirmed implementation gap rather than merely unverified appearance. Microsoft ColorDisplayNameHelper_Partial.cpp delegates naming to ColorHelper_ToDisplayNameId; that implementation was not found in the inspected repository tree. Do not claim a guessed HSV label or a hex-only popup matches Windows naming. Exact naming requires a compatible implementation or authoritative Windows color/name fixtures.

Source evidence saved in artifacts/winui-color-spectrum.cpp and artifacts/winui-color-names.cpp. References: https://github.com/microsoft/microsoft-ui-xaml/blob/main/controls/dev/ColorPicker/ColorSpectrum.cpp and https://github.com/microsoft/microsoft-ui-xaml/blob/main/dxaml/xcp/dxaml/lib/ColorDisplayNameHelper_Partial.cpp . No application changes or new build in this source audit.

### Repair Color Model Menu Hit Testing — 2026-11-05

Native testing found the RGB/HSV menu did not open from its accessible label or visible arrow. InlineLineColorEditor inherited DetailsDialog’s enabled text selection. Disabled static text selection within the editor; retained its native Picker and all editable TextFields. After rebuilding, clicking Color Model opens RGB/HSV choices, choosing HSV and confirming updates the mode and Hue/Saturation/Value inputs. Capture artifacts/color-model-menu-hsv.jpg. Closed both dialogs with Escape without adding a color.

Canonical build passes (artifacts/color-model-menu-build.log) and diff checks pass. Before the fix, keyboard spectrum Right changed hue336→337 and brightness Left changed83→82 with selected-color/channel updates. Tab skipped the mode menu in the current Mac configuration; full keyboard traversal remains open. No new unit tests for the SwiftUI hit-testing fix; native execution establishes the regression and repaired behavior.

### Time Zone Menu Ordering — 2026-11-05

Windows SettingsPage uses TimeZoneInfo.GetSystemTimeZones, which orders by standard UTC offset and then display name. Mac previously sorted IANA identifiers alphabetically. Added Format.sortedTimeZones and wired the Settings picker to it: standard offset first, localized display-name comparison second, deterministic identifier tie-break. Deduplicates identifiers, ignores invalid entries, and retains the current selection by including it in the supplied list. Platform identifiers and display-name adaptations remain; this does not claim identical Windows zone inventory.

Focused hosted test verifies winter/summer order for Honolulu, Los Angeles, Phoenix, Kolkata and Kathmandu, including duplicate/invalid inputs; one test passes with zero failures. Canonical build passes. Logs: artifacts/time-zone-order-tests.log and artifacts/time-zone-order-build.log. No fresh rendered menu-order check in this pass. Reference: https://learn.microsoft.com/en-us/dotnet/api/system.timezoneinfo.getsystemtimezones .

Also audited DetailsDialog call sites after the color-menu fix: remaining content is text-only, with action buttons outside the selectable-text subtree. No equivalent nested interactive menu found there.

### Short Label and Heading Case — 2026-11-05

The conversion guide explicitly requires Title Case for short labels/headings and says to follow that rule over older sentence-case screenshots. Updated dashboard Add Account/Exit Demo/Explore with Demo Data and Demo Data labels; Connect Account, billing-unit choices and alternate sign-in actions; Alert History, Available Resets, Usage Details Unavailable and Open Provider Usage titles/actions. Explanatory sentences remain sentence case. Updated the existing UI assertion for Exit Demo without claiming its execution.

Canonical build passes (artifacts/short-label-case-build.log) and native compact accessibility confirms Exit Demo with the original addAccountButton identifier. Diff checks pass. UI runner still requires macOS automation authorization; no additional UI-test run was attempted. Windows origin/main remains3c863a5 after fetch.

### Quota Label Case — 2026-11-05

Applied the conversion guide’s short-label Title Case rule to shared Used, Left, Over and unavailable-state labels, including Plan Unavailable. Updated dependent history badge fallback checks so unknown plans still render a question mark or period label. Numeric formatting, rounding and quota calculations are unchanged. Existing count/overage/Copilot/unknown-plan expectations updated.

Canonical build passes (artifacts/quota-label-case-build.log). Native compact dashboard confirms Codex38% Used/62% Left, weekly74% Used/26% Left and Copilot82% Used/18% Left. The CoreTests attempt and focused formatter retry did not start a test host; both stalled in Xcode launch coordination before assertions and were explicitly stopped. Logs quota-label-case-tests.log and quota-label-case-focused.log retain the failures; do not count the changed expectations as passing tests. Hosted CI remains the next test verification path.

### Direct Formatter Verification and Publication Failure — 2026-11-05

The hosted suite for last published ea3d79f completed successfully in run42128345663:99 tests, two installed-CLI skips, zero failures. This excludes the later quota-label commit2984c91. Git push of2984c91 repeatedly failed with GitHub's fatal commit_refs_rules error; the repository rulesets endpoint returns an empty list. Remote main remains ea3d79f. No rules or protections were changed.

To verify2984c91 without the stalled Xcode test launcher, compiled the production Support/Format.swift and Models/Settings.swift with the unchanged quota-model declarations preceding AccountPolicy in Models/Quota.swift. A standalone assertion harness passed count/overage formatting, Copilot percentage behavior, missing-value labels and unknown-plan period fallbacks. Artifacts are formatter-direct/QuotaTypes.swift, Check.swift, check and result.txt. This verifies the pure formatter directly; it does not claim the hosted XCTest suite executed.


### Current Chooser Capture and Hosted Verification — 2026-11-05

Native current-font chooser capture provider-chooser-current-fonts.jpg is 640×674 Retina pixels, corresponding to the Windows reference20 panel's 320×337 logical size. The three 44-point provider buttons, 10-point row gaps, inset footer and Cancel placement match the reference layout; current Title Case follows the guide rather than the older screenshot. Cancel returns to the isolated empty dashboard without adding an account. This is layout evidence, not exact text rasterization signoff.

The empty-wide-current.jpg capture is 2506×1750 Retina pixels (1253×875 points); reference sizing was not enabled because the launch omitted --demo, so it cannot establish equivalent-wide-layout parity. No clipping observed.

Publication recovered: remote main reached6077a91. Hosted run42129128258 at that revision completed successfully, including the changed quota-label expectations:99 tests, two installed-CLI skips, zero failures. Preview build, archive validation and publication also passed. Full log:artifacts/current-6077a91-ci.log. This supersedes the prior publication-failure note; local Xcode launch and UI-automation limitations remain distinct from these passing hosted unit tests. No application code changed in this verification pass.


### Compact Empty Capture and Exact Color-Name Requirement — 2026-11-05

Corrected the previous wide-capture diagnosis: DemoReferenceWindow.size explicitly requires --demo; the earlier non-demo launch did not request a reference size at all. A --demo --compact launch followed by Exit Demo and setting the dashboard scrollbar to its top produced compact-empty-current-fonts.jpg at1578×1388 Retina pixels, matching reference24's789×694 logical window. The current empty rail reaches about745 points versus730 in the reference, and the card bottom is about631 versus635; inspect source geometry before changing these. Title-bar heights differ by platform, so absolute vertical offsets alone are not defects.

The user explicitly requires Windows-exact color names. Native macOS color names are not an accepted substitute. The selected-color focus tooltip remains missing until Windows ColorHelper_ToDisplayNameId naming behavior can be reproduced and verified.


### Empty Timeline Right Inset — 2026-11-06

Windows HistoryTimelineView defines PlotRight=12 and Span=chart.Width-AxisLeft-PlotRight; its rail ends at AxisLeft+Span. The Mac emptyTimeline Canvas omitted that inset and drew through size.width. Added the same12-point right reservation, clamped at the left endpoint. The populated scrolling timeline is unchanged. Canonical build passes in artifacts/empty-rail-inset-build.log. Post-build native verification was interrupted by a Sparkle update reminder and then CUA timeout; fresh rendered confirmation remains open. The reminder displayed available2026.11.3 versus installed2026.11.6 and requires a separate update-version investigation; no update was installed.


### Windows Countdown Updates Through c09f499 — 2026-11-06

Reviewed all four commits after3c863a5: earlier earned-reset deadlines (3fb017f), matching tooltip glyphs/colors (efa3e2f), clock scale (bae1c75), and visible left-edge offset (c09f499). Ported eligible weekly/monthly row selection of an available future expiry only when earlier than the quota refresh (or when refresh is missing). Expiry clicks open Available Resets; the row reevaluates on its30-second clock. Refresh uses Fluent E72C, expiry uses E823 in amber EAAA51 with44/41 scale and+1 horizontal offset in the existing25-point slot. Tooltip timing includes the icon,12-point gap and7-point top margin; width calculation reserves the new icon column.

Build passes (windows-row-deadline-build.log); final build-for-testing and focused deadline regression pass (windows-deadline-tests.log). Test covers earlier expiry, ineligible five-hour window, tied deadlines, missing refresh and elapsed expiry. Native hover rendering, click routing and clock-edge visual measurement remain to be checked; passing model tests do not establish those.

### Devin Enterprise and provider picker through c80de39 — 2026-11-06

Compared the Windows default branch with the previously reviewed countdown changes at c09f499. The Mac port adds the four-provider picker with service icons, updated empty-state text, Devin Enterprise SSO and background My Analytics reads, ACU percentages, monthly history, account colors, usage links, and the existing alert and reconnect flows. macOS uses a temporary WebKit browser per operation with per-connection session data saved in Keychain. Profile cleanup removes that Keychain entry. The packaging guard rejects DevinProfiles and DevinTrials. Windows' PowerShell test timing change is specific to its CLI test runner. Native macOS notifications use the app icon, and the in-app banner uses the provider logo.

Verified the running picker and Devin form, including the Work nickname and workspace field. The unit suite includes simulated HTTPS pages in WebKit verifying session restoration, monthly usage extraction, and identity rejection. The release preview packaged successfully and a staged trial directory was rejected. Company SSO and a live tenant quota read still require an authorized workspace.


### Windows color names and focused picker controls — November 6

The picker now uses the English names from the Windows release v2026.11.6.005. [Windows reference run](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42309270503) sampled the shipped classifier and matching English resource strings. The production Swift lookup matched all 16,777,216 opaque RGB colors across 41 names. The [regeneration and comparison instructions](../script/windows-color-reference/README.md) reproduce the bundled 784,760-byte table. Its SHA-256 is 9bc61b114ffedbdd8f6a8b18724d1e8cc8b98d416722019291f68b91b1dc96c1. Packaging checks the table bytes in the app.

In the isolated compact demo, keyboard focus on the spectrum at #0094B9 showed “Dark teal” anchored below the selector at its upper edge (artifacts/color-picker-dark-teal-final.jpg). From pure red, Ctrl+Right, Ctrl+Left, Ctrl+Left yielded #FF7700 Orange, #FF000D Red, #FF00AA Pink. Tab moved to brightness, where Ctrl+Left showed “Value 46 (Plum)”. Focusing the hex field dismissed the tooltip. Confirmed the pure-red hex entry exposes Hue 0 after sRGB conversion. Cancel returned to the existing swatches. This verifies the named-color interaction in English. Exact spectrum rendering and full keyboard traversal remain open.


### Color picker keyboard traversal — November 6

Tab moves from the spectrum to brightness, then to the native Color Model popup. Space opens the popup; Down and Return select HSV. The editor scrolls the channel fields into view so the last field precedes the footer. Blurring a field preserves fractional HSV components when its displayed integer was untouched. The picker footer uses native keyboard buttons, with Return or Space on the focused action and Escape to cancel.

The native XCTest `testColorPickerKeyboardModeAndExactSwatch` entered #123456, switched from RGB to HSV with the keyboard, traversed Hex and the three channels, saved with Return and found the exact swatch. The test then changed a fresh draft to #ABCDEF, canceled it with Space, reopened the picker and confirmed #123456. Escape dismissed the final editor. Native pointer opening and Escape dismissal of the popup were also inspected. Final test evidence is in artifacts/color-picker-keyboard-save-cancel.log.


### Whole-account refresh deadline (Windows eb042cb)

Reviewed the latest Windows refresh orchestration. The Mac already publishes each account independently and preserves identity/persistence checks. Added the Windows 45-second whole-account cancellation deadline around credential renewal and all quota requests. Cancellation remains cooperative; an in-progress protected credential rotation finishes or leaves its durable reconnect marker before returning. A timed-out operation is canceled, retains saved quota values, and uses the existing per-account failure/backoff path. The regression fixture uses a shorter injected deadline and verifies cancellation, an independently successful account, refresh completion, and persisted retained values. All 136 hosted tests passed. This is orchestration verification, not a claim that provider authentication has been restored.


### Adaptive Reset Horizon header and heading boundaries

Replaced the two fixed header arrangements with a SwiftUI flow layout that wraps each legend, the History control and its hint independently, matching the Windows FlexLayout's grouping behavior. Kept the capture-backed 44/40/36-point trailing allocations and existing first-row height and row gap; the earlier experiment with literal Windows margins remains rejected. Native 789-point and 1000-point captures show complete controls, with History on the first row at intermediate width and its hint below.

The captures also exposed partial offscreen weekday/date text in the axis gutter. Windows LayoutDayHeadings includes an anchor only when it is inside AxisLeft through AxisLeft+Span. Applied the same viewport-anchor bounds to Mac headings, while retaining the wider overlay that permits a visible left-edge label to extend into the axis gutter. Full visual sign-off remains separate from these layout corrections.

Final native captures: artifacts/header-flow-compact-final.png (789×694 points), header-flow-900-final.png (900×800), header-flow-medium-final.png (1000×800), and header-flow-wide-final.png (1463×866). Inspected all four: controls are complete, the compact History/hint row is retained, intermediate widths wrap the hint independently, the wide header remains one row, and offscreen date fragments are absent. The canonical build and both native UI tests (History toggle/selector/demo exit and Tab history entry from launch) pass. Synthetic demo evidence does not establish live provider behavior or exact raster equivalence.


### Fixed popup titles and bounded message scrolling

Windows ThemedDialogs.ShowAsync assigns Title separately from a ScrollViewer whose message body has MaxHeight=420. The Mac previously scrolled the title together with long content and capped the complete dialog at 560 points. DetailsDialog now owns a fixed 22-point title, limits only its message area to 420 points, and keeps the existing action footer separate. Migrated quota/earned-reset details, historical events, errors, confirmations and the color editor to the shared title slot. The complete dialog can grow to 640 points, including header and footer. Existing short quota-body spacing and button widths are preserved.

Added the isolated many-resets demo fixture and a native UI test that opens 30 earned resets, scrolls to the final entry, and verifies the title and Close frames do not move. Its native capture, artifacts/long-reset-fixed-title.png, is 664×1206 Retina pixels (332×603 points), showing the final December 4 entry and accessible fixed footer. The body measures 420 points. Quota overage/missing-limit and color-editor keyboard save/cancel UI tests also pass, and all 136 hosted tests pass. Initial count/long tests launched without a dashboard; their setup now reopens it using the same Window-menu path already used by the color test. The final reset-row lookup uses a stable accessibility ID rather than a Text label predicate because selectable native text exposes its content as a value. These test fixes do not substitute for the rendered scrolling assertions. Full per-image raster comparison remains open.


### Settings Close flushes edits and preserves failed drafts

Windows SettingsPage.CloseAsync flushes the account nickname, waits for saveGate, and refuses to close while its save status contains an error. The Mac previously dismissed global/account settings immediately. Added a shared Close action that flushes a focused nickname, disables editing while awaiting queued writes, shows Closing… with the processing ring, and dismisses only after successful settings persistence. Save errors remain in a right-aligned amber status line with the source's 24-point horizontal margin. A successful subsequent settings edit clears its own failure without clearing unrelated errors. Real-save failures remain separate from demo edits. Reconnect and Send Test Notification drain the same queue; account removal dismisses only if the account was actually removed.

The native account fixture deliberately rejects a write while Close is pressed with the nickname field still focused. Settings stays open, the error is visible, and the Business draft remains. After the trigger is removed, another Close saves Business to SQLite and closes the panel. The final integrated run passed 139 hosted tests and all nine native UI cases in one invocation, including settings/history navigation, reconnect choices, color keyboard save/cancel, quota details, History controls, pointer/keyboard history inspection, and long-reset scrolling. Results: /tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.06_20-35-51--0600.xcresult. All injected failures use isolated data; no live credential or account was removed.

A final local-draft check also found that reminder syntax errors never enter the store's autosave queue. ReminderEditor now derives invalid state from every live draft and reports it to Settings, which keeps Close and test-notification navigation from bypassing invalid amounts. Correcting or removing an invalid row clears only that row's error; another invalid draft continues to block dismissal. A separate native test enters zero, verifies Settings/error/draft remain after Close, corrects it to two, and verifies Close succeeds. This tenth native case passed after the 139-hosted/nine-native full run; it is separate evidence, not a claim that ten UI tests ran in the earlier invocation.


### Consistent connection processing feedback

The conversion guide requires immediate purple/white processing buttons with an in-button white ring, including Claude despite its Windows busy-ring gap. Codex, Claude, GitHub browser/token and Devin forms previously used normal disabled buttons with separate indicators. They now share DialogActionLabel's processing slot and ScroogeButtonStyle's processing palette. Codex claims its pending action synchronously before its Task starts, prevents duplicate activation, and distinguishes Signing In from Checking Sign-In. The advanced-token operation is retained in ConnectionForm's existing cancellation task. No provider protocol, acceptance or credential format changed.

A presentation-only native preview extracts the production label, style, font registration, glyph mapping and progress component. It contacts no provider and creates no credentials. The first capture exposed the native macOS spinner dimming inside disabled buttons. Replaced those indicators with ActionProgressRing: a white rotating arc in the existing icon slot, also shared by Refresh and settings Close. Inspected artifacts/connection-actions-busy.png and connection-actions-ready.png: all six busy actions keep purple fill/white text and ring while AX reports them disabled; resetting restores the normal labels, icons, colors and enabled state. A later native screenshot shows a changed arc orientation. Preview source is artifacts/connection-processing-preview.swift. This establishes component presentation, not live sign-in success or cancellation.

139 hosted tests and the native reconnect/provider-chooser test pass. Other provider/OS acceptance gaps remain open.

### Connection cancellation and field ownership

Compared Windows ConnectAccountPage's shared processing/committing state and CloseAsync guard. The Mac connection form now shares its phase with Codex, Claude and GitHub browser actions, locks submitted fields and flow switches during provider work, and retains the operation task. Cancel remains available before verified-account acceptance; the final acceptance phase disables Cancel and interactive dismissal. Devin and advanced GitHub previously disabled Cancel throughout sign-in, while child flows left parent fields editable. Codex cancellation now cancels its retained operation, with credential cleanup after that operation exits. Existing serialized acceptance still rejects a canceled queued connection and preserves an already-started atomic save.

The isolated Devin browser regression holds navigation before authentication, cancels the task, verifies CancellationError rather than an authenticated session, and confirms its owned window closes. No provider request is made by that fixture. All 140 hosted tests and the native reconnect-cancel/provider-choice test pass. Live authenticated cancellation, logout and remaining provider-specific acceptance are still open; these controlled checks do not establish those outcomes.

Running-app check after the canonical build: opened Add Account → Devin → Sign In with Devin. The real public sign-in page loaded without submitting credentials. Cycling back to the form showed nickname/workspace disabled, Signing In with Devin… disabled, and Cancel enabled. Cancel returned to the unchanged three-account dashboard. This checks the pre-authentication UI path; authenticated cancellation remains unverified.

### Row alarm save state and current provider-picker review

Windows CapacityAlertToggle.SelectAsync disables both segments until its save completes and ignores repeated/same-value activation. The Mac now claims the row save synchronously, ignores same-value selection, and disables both segments while its queued settings write completes. The saved selection remains authoritative; a failed write retains it and restores interaction. This preserves the project requirement to adopt persistent state only after a successful save.

Native XCTest uses an isolated saved quota fixture with monitoring disabled by the test environment. A second SQLite connection holds BEGIN IMMEDIATE while the Off action is clicked: both buttons are disabled and On remains selected. Releasing the lock lets Off become selected and both buttons become enabled. An injected update failure on the subsequent On action raises the normal error dialog, preserves Off, and restores both buttons. The native case passes; no provider is contacted.

Also rechecked latest Windows main (eb042cb) rather than reverting to older screenshots: ThemedDialogs.ChooseAsync now uses 28-point provider logos, 16-point text/gaps and 54-point rows. Mac ConnectionView already matches those constants. The old image20 generic 44-point chooser is superseded by c80de39; exact new picker/footer raster comparison remains open. Codex form reference21 and the current native 1000×800 panel agree on 550-point field/action width and 44-point actions, with small text-position/raster differences still unverified. No compensating font offsets were introduced without stronger evidence.

### Compact countdown date line box

Fresh isolated compact demo at 789×694 points reproduced the first account card's roughly 290-point height versus reference27's 286. Measured the actual registered classic Segoe faces in NSHostingView: 20-point Semibold Text reserves 27 points; 12-point regular Text reserves 16; 14-point regular reserves 19. Each countdown therefore used 27 + 3 + 16 = 46 points before its eight-point gap and 48-point bar. Constraining the date's line box to 14 points removes two points per quota row without changing its 12-point font, timestamp text, or the Semibold countdown. This is a capture-derived platform line-box adjustment, not a literal height constant in the Windows source.

Rebuilt and recaptured the isolated demo through native computer use. The first two-quota card now spans approximately y270–556 (286 points), matching reference27's approximately y266–552 height independently of scroll offset. Both date strings fit without visible clipping, and usage controls remain 48 points high. Small horizontal inset differences, individual glyph placement and fixture time differences remain open. Native demo History-toggle/filter/exit UI test passed; canonical build/run passed. No new unit test was added for this fixed visual line box. Wide rows retain their existing 56-point minimum; full wide and tooltip raster comparison remains open.

### Update-channel version publication check

Revisited the earlier older-release prompt against authoritative current state: the downloaded public appcast advertises build 1361 / 2026.11.6; the canonical running bundle reports build 1448 / 2026.11.6. Debug builds disable Sparkle. The historical prompt is not reproduced by these current versions; the prior channel repair is already documented in docs/mac-updates.md.

The publisher previously replaced the channel without comparing its new CFBundleVersion against existing items. It now rejects equal or lower integer builds before packaging/signing/upload, checks every item rather than assuming feed order, supports Sparkle's legacy enclosure version attribute, and rejects malformed/missing version data. Channel lookup errors cannot bypass the check; only a confirmed HTTP 404 permits initial channel creation. Added ten parser/preflight tests and a CI step. Mocked publication paths prove equal builds and lookup failures stop before packaging; a check against the actual downloaded feed accepts 1449 and rejects 1361. Shell syntax and all ten tests pass. No release/feed was uploaded, no signing-key access was requested, and no app behavior changed. Concurrent publishing is not an atomic GitHub transaction; documented single-publisher operation remains required. Developer ID/notarization and clean-machine install acceptance remain open.

### Live offline and recovered quota presentation

At current source 5ddec43, a temporary app-only loopback proxy forced a real Codex quota request to fail. The native weekly details popup showed 5% Used · 95% Left, the unchanged last-successful-fetch time and Offline: Codex could not complete this monitoring request. Check sign-in and retry. After stopping the proxy and canonical normal relaunch, a healthy provider read advanced the fetch to 9:16:31 PM CST and the same popup no longer contained Offline. SQLite independently confirmed the health transition, retained usage, and advanced observation time. This is live provider evidence rather than a synthetic fixture. No implementation change was needed for this path. Same-process reconnect and sleep/wake remain open; see tasks/acceptance.md for the exact scope.

Canonical build/run passed. Hosted preview run 42332925400 for 5ddec43 completed successfully, including the new update-publishing tests. The normal app remains the only running Scrooge instance; the loopback test server was stopped.

### Alert History shared icons and row padding

Rechecked current Windows MainPage.Alerts and ActionButton. History rows send the complete three-line display text through GlyphFor; they do not choose icons directly from delivery/reminder flags. Mac AlertHistoryView now uses the existing shared DialogActionLabel, including its ordered text-to-icon rules and white-on-hover foreground. This preserves common history/sent/reset/refresh icons and also handles titles/details that match an earlier shared action rule. Replaced the row's 12-point vertical padding with Windows's 10-point action padding while keeping the 80-point minimum, nine-point icon/text gap and 16-point row gaps. macOS delivery wording remains the intentional platform adaptation.

Canonical builds passed. Native Alert History return-navigation UI test passed. Opened a populated eight-alert isolated demo at 1463×866 points, with a 1000×800 panel, and compared to reference08: standard rows are approximately 80 points with 16-point gaps, and the history/sent/reset/refresh glyphs render with intact three-line text. A populated weekly row opens the matching 74% Used / 26% Left demo quota; Close returns to history and Escape returns to Settings. Native screenshot was inspected in the computer-use session. Fixture dates/details, one-point panel-border inset, exact glyph baselines and full raster comparison remain open. Banner source constants (38-point provider mark, 12/15-point heading, 12-point detail, 18-point padding, 10/8-point gaps, 14-point corners, 520-point cap and 20-point margin) already agree; no banner formatting change was made or final rendered signoff claimed. Restored the normal live app after the isolated check.

### Secondary-panel border participates in layout

Windows AppPanels wraps each secondary page in a native Border with BorderThickness=1 inside its fixed 1000×800 maximum outer bounds. The Mac's equivalent only painted an overlay over full-size page content. Added shared referencePanelFrame(size:), which reserves one point per edge before applying the fixed outer dimensions and existing surface. Settings, Account Settings, connection forms and Alert History now use it. The two settings forms compute their Width−24 reservation from the inner page width, excluding both border edges; their 960-point cap is unchanged. Provider chooser and ContentDialog-style popups are separate surfaces and were not changed by this pass.

Four native UI tests pass together: focused nickname save/failure retention, reconnect cancel/provider choices, Alert History return navigation, and color-editor keyboard/save/cancel. Canonical build passed. In an isolated compact demo, the Settings panel remains 741×630 points (1482×1260 Retina screenshot); the visible card starts approximately 29 points from its outer edge and is about 683 points wide. Header Close, version text, timezone picker, history retention picker and other visible controls are unclipped. Escape returns to the dashboard. This checks the source-backed border inset and compact fit; final typography/raster comparison remains open. Normal live app restored through the canonical run script.

### Fresh native Windows reference capture

Added a manual Windows-runner reference probe using the checksum-pinned v2026.11.6.006 release (eb042cb). The first three runs identified capture-driver startup/window-lookup issues, including the portable launcher's deliberate handoff; they produced no accepted capture. The corrected harness mirrors the launcher environment, retains the process and resolves its own visible full-size window by process ID. Run 42335310777 at 2496f48 succeeded, and its downloaded dashboard screenshot was visually inspected: actual populated WinUI rendering, 79 automation elements and 42 font-bearing elements, graphical session 2. Temporary app state is removed, and only screenshots/geometry are exported. No provider sign-in or quota call was used.

The runner's outer window measures 800×680 pixels and includes invisible frame margins, so it is not a matching-width replacement for the original compact gallery. It nevertheless supplies fresh text-element measurements: the 32-point brand label is 39 points high, the 26-point Reset Horizon label 32 high, and 14-point weekday labels 17 high; available font attributes report their declared sizes/families. Bare Mac Semibold Text measures 43/35/19 points at those sizes. Font-name fallback strings do not prove resolved physical typefaces, and this evidence does not establish the 20-point countdown or popup line boxes. Next work must capture those rows/popups and normalize viewport geometry before replacing earlier visual compensation or claiming exact parity. Usage/confirmation popup width remains open. Reproduction and limitations are in script/windows-ui-reference/README.md.


### Account identity fills its Windows click region

Expanded native Windows reference run 42336148115 (758cbd3) succeeded and its account-row and quota-popup screenshots were inspected. The compact first identity button covers 569×44 points, including the blank space beside the name/badge. Windows AccountQuotaView overlays a transparent fill button across its identity grid, whose wide column is 220 points. Mac previously applied the width outside an intrinsically sized button label; its blank identity space did not participate in hit testing. The label now fills the proposed identity width before defining its rectangular hit area. The displayed logo/text and existing details routing are unchanged.

Canonical build passed. A native UI regression test confirms the 220-point wide action opens first-quota details when clicked at 98% of its width beside the badge, then closes normally. Compact was checked directly in an isolated demo: set the outer vertical scrollbar to 0.40, invoke the expanded identity action at its center (blank space beyond the intrinsic content), and inspect the resulting OpenAI / Personal · Plus popup with Codex · 5-Hour and 38% Used · 62% Left. The earlier combined compact test attempts failed to bring the account onscreen because XCTest wheel scrolling hit Reset Horizon; these are not counted as passing compact automation. Final automated coverage is wide only, with compact computer-use evidence.

The new Windows 20-point countdown measures 24 points high, its 12-point date 16 points, and the gap three points. This contradicts the previous assertion that Windows intrinsically uses a 14-point date line; that earlier compensation requires correction alongside the Semibold line-box mismatch. No typography change or final font acceptance is claimed in this update. Native popup title attributes report Segoe UI Variable, 22 points in a 30-point rectangle; body 14 points in 19-point rectangles. Available requested font strings are not proof of resolved physical fonts. Equivalent viewport capture and typography remain open.


### Match the installed Windows classic font versions

Native Windows capture run 42336843207 at bd72383 passed after adding installed-face resolution through WPF. Its Segoe UI and Segoe UI Semibold files both report version 5.71, replacing the Mac's previously bundled Regular 5.28 and Semibold 5.00. Both resources now match the captured installed files byte for byte; SHA-256 values and provenance are recorded in script/windows-ui-reference/README.md. Updated the Semibold PostScript spelling to SegoeUI-Semibold, matching the captured file. No Windows source changed. This proves installed-file parity with that Windows runner, not the physical face selected by every WinUI fallback list.

Measured the old/new faces independently in NSHostingView. A 20-point Semibold 2h 13m label changes from 69 to 66 points wide; its natural Mac line box stays 27 high. Both versions retain the same hhea metrics, so replacing the font does not explain or solve the measured Windows 24-point countdown rectangle. Canonical build passed. Native count-usage overage/missing-limit popup and history/filter/exit tests passed. Inspected isolated compact demo rows and their usage popup: the new face renders countdowns, account names, usage labels and popup title without clipping. Demo fixture times differ from the Windows capture; no pixel-identical acceptance is claimed. Normal live app restored through the canonical script.

Countdown/date line-box correction, baseline matching, equivalent visible viewport measurements and final popup sizing remain open. The old 14-point date constraint is still a temporary gallery-derived compensation, not a verified Windows line-height constant.


### Native popup title face and title-to-body spacing

Pinned Windows App.xaml at eb042cb defines a 22-point Semibold native TextBlock title template without a classic font-family override. The fresh usage popup reports Segoe UI Variable / 22 / weight 600, with a 30-point title rectangle and a 12-point gap before the first 19-point body line. The official ContentDialog template independently specifies ContentDialogTitleMargin=0,0,0,12 (microsoft/microsoft-ui-xaml 85e1269f3a30beffdad33576dc9453b4d2c6e0c0, controls/dev/CommonStyles/ContentDialog_themeresources.xaml). Mac shared popup titles now use the existing Variable Text Semibold face rather than classic Semibold. DetailsDialog uses the native title's natural height and a separate 12-point title/body gap instead of the previous 32-point minimum plus eight points. Body paragraph spacing remains eight points.

Canonical build passed. Three native UI tests passed: count-usage overage/missing-limit popups, long reset body scrolling with fixed title/footer, and reconnect cancel/provider choices. Inspected the standard compact popup using the exact Windows capture time 2026-11-06T21:55:53-06:00: identical account, 38/62 usage, reset and fetch timestamp content; title, body and Close remain unclipped. The screenshot is 684×842 Retina pixels, giving a 342×421-point popup (previously 342×419). The fresh Windows popup is approximately 348×422; title/body spacing is now source-backed, while width, final raster/baseline comparison and other variants remain open. Normal live app restored through the canonical run script. No live provider behavior changed.


### Content-sized message popups and equal footer columns

Windows ContentDialog measures its content within 320–548-point bounds; the native template's two star footer columns share the available width. Replaced DetailsDialog's default fixed 480-point width with natural sizing in that range, and removed AccountUsageDialog's inferred 332/342/480 widths plus the historical schedule popup's fixed 342 width. Explicit color-editor width remains supported. A small footer Layout measures the larger action for its ideal width and gives both columns equal actual width, including the empty leading slot for Close-only dialogs. Removed QuotaDetailsView's additional 440-point content cap and the fetch timestamp's single-line/90-percent shrinking workaround. Long text now wraps at the dialog's width cap.

Canonical build passed. Four existing native cases passed: reconnect/provider choices, color-editor keyboard/save/cancel, count overage/missing-limit details, and long reset-body scrolling with fixed title/footer. Updated count assertions confirm natural width below the cap and half-width Close geometry. Added an isolated long-details demo fixture and native regression: its long provider note reaches 548-point width, wraps over multiple lines inside the sheet, and leaves Close hittable. Its first attempt failed only because the selectable-text label query did not locate the note; a stable accessibility identifier corrected the query, and the final case passes. No live provider call is used by these fixtures.

Inspected standard compact usage details at the exact Windows capture time 2026-11-06T21:55:53-06:00. Screenshot measures 698×842 Retina pixels, or 349×421 points, replacing the fixed 342×421 popup. Account, 38/62 usage, reset/fetch times, title, full-size timestamp and Close render intact. This agrees with the fresh Windows standard popup to approximately one point; full raster/baseline equality and other content variants remain open. The source-backed width behavior also applies to confirmations and attention messages, while special editor sizes remain explicit. Normal live app restored through the canonical run script. Countdown line-box correction and the wider acceptance backlog remain open.


### Countdown fallback line metrics replace the date workaround

Investigated the remaining 20-point countdown's 27-point Mac versus 24-point native Windows line box. Microsoft's CCompositeFontFamily::CreateFromDWrite initializes its fallback baseline to .9 em and line advance to 1.2 em (microsoft/microsoft-ui-xaml 78c72df1a5e6df181ce2d86a8a8cdff53be5ef22, dxaml/xcp/core/text/Fonts/CompositeFontFamily.cpp). Its fallback-metric path in DetermineDefaultLineMetrics explains why requested family strings alone cannot establish resolved font metrics. These values agree with the captured Semibold label heights at 14/16/20/26/32 points; this is a matching line-metric adaptation, not proof of every physical fallback face.

Added a narrow SwiftUI TextRenderer plus Layout that retains SwiftUI's shaping and full unconstrained text height, positions each drawn baseline at .9 em plus 1.2 em per line, and reserves the matching line-box height. Applying a reduced height directly to TextRenderer's own proposal was rejected in the prototype because it truncated wrapped lines. The enclosing Layout keeps the complete child layout and compresses only the reported line spacing. Applied the component to ResetCountdownText, shared by quota rows and reset tooltips, and removed the incorrect 14-point date constraint. The 12-point regular date again uses its natural 16-point line, separated by three points from the 24-point countdown.

Two hosted image-rendering regressions pass: the 24-point single-line box and baseline/descender bounds; and a wrapped Reset Due — Checking label retaining both lines inside 48 points. The initial wrapped ink-top assertion differed by one row because the two lines begin with different glyphs; the final test allows that raster difference while requiring both bands and the correct line-box height. The native history/filter/exit UI test also passes. Regenerated the checked-in Xcode project for the new test file. Canonical build passed.

Compared the native Windows 2h 13m screenshot crop: purple ink occupies rows 3–17 within its 24-point rectangle. The equivalent Mac prototype occupies 3–17.5 points at 2×, matching to raster tolerance. Inspected the running compact demo at reference time 2026-11-06T21:55:53-06:00: ordinary countdowns and full date labels fit. Inspected the wide due fixture: both Reset Due / — Checking lines and the date are intact across the visible account rows. These are synthetic UI checks, not live reset verification. Normal live app restored via the canonical run script. Other measured Semibold headings, card border/layout insets, floating tooltip placement and full raster acceptance remain open.


### Dashboard label metrics and normal card/badge borders

Applied the measured fallback line metrics to the dashboard's 32-point brand title (inside its existing 40-point slot), 26-point Reset Horizon title, 20-point provider names, 16-point Used labels and 14-point day names. These correspond directly to the fresh Windows capture's 39/32/24/20/17-point text rectangles. The regular subtitle/date/Left labels and native popup faces retain their own metrics. Empty and populated timelines now share the same day-heading View instead of separate Canvas text placement: 17-point day + seven-point gap + 16-point date fits the 40-point heading exactly. The previous natural 19-point day made that stack 42 points inside its clipped 40-point slot.

Windows account cards and plan badges use native one-point borders that participate in layout. Mac now reserves those insets and paints the normal outlines inside their bounds. The account layout's wide/compact threshold excludes the card's two border points, agreeing with the Windows AccountQuotaView width measurement. Source-backed content padding and column constants remain unchanged. This addresses normal card/badge insets; highlighted/drag states and exact total card-height agreement are not signed off.

Canonical build passed. Three hosted rendering regressions pass, including a table of all five captured font sizes/line heights. Three native UI checks pass: identity blank-space details routing, history/filter/demo exit, and alarm pending-save/failure retention. The first UI selection included a nonexistent row-alarm method name and therefore ran only the other two UI cases; the actual testRowAlarmWaitsForSaveAndRestoresAfterFailure was subsequently run separately and passed. Inspected compact populated header/timeline and account rows at reference time 2026-11-06T21:55:53-06:00: text and badges are intact with the corrected vertical placement. Exited the isolated demo and inspected the empty timeline at the top: Today and its date align cleanly, the rail and current marker remain intact, and ordinary controls are visible. Normal live app restored through the canonical script. Broader secondary-page headings, exact card-height/raster comparison and the wider acceptance backlog remain open.


### Secondary headings, provider picker reuse, and literal URL placeholder

Rechecked the Windows repository's latest commits; main remains eb042cb, with no newer application changes to port. Windows Settings/Account Settings/connection/history headings explicitly use classic Segoe UI Semibold at 26 points, section headings use 21, the in-app alert title uses 15, and the empty-dashboard headline uses 24. Applied the same fallback line-metric component already validated against native Windows to these labels. Removed the connection heading's obsolete 35-point minimum and the empty headline's 32-point minimum; natural wrapped text remains supported. Native ContentDialog titles retain their separate Variable Text face.

Provider chooser had duplicated popup chrome and retained the old title minimum. It now uses shared DetailsDialog at the Windows 320-point width, with the corrected title/body gap, one-point border inset, and equal footer columns. Option rows retain 28-point service logos, 16-point label sizes, 16-point icon gaps, 54-point minimum heights, and ten-point row gaps. Their native TextBlock labels now use Variable Text rather than classic Segoe. Text selection is disabled for these action labels. Cancel still dismisses the chooser, and choosing a provider enters its form.

Four native UI cases passed: focused nickname save/failure retention, reconnect/provider choices, Alert History return navigation, and color-picker keyboard/save/cancel. Four hosted typography render tests passed, including 15/21/24-point heading boxes with intact descenders. Canonical builds passed. Inspected compact Settings header/sections, the 640×862-pixel (320×431-point) provider picker, and the compact Devin form; headings, four logos/options, fields, and Cancel fit without clipping. No sign-in was started and no credentials entered.

The Devin workspace placeholder was visibly blue because its URL was interpreted as styled text. Windows Entry style specifies PlaceholderColor #B6B8C8. Added an explicit verbatim, gray prompt. A new build and separate running-form inspection confirm the placeholder is neutral gray; this second inspection used the normal large panel in the isolated empty data directory. Prior behavioral tests were reused for this placeholder-only edit. Native banner presentation itself and full per-surface pixel acceptance are not established by the heading render tests. Normal live app restored through the canonical script; broader acceptance gaps remain open.


### Native reset tooltip placement and click-through

Rechecked pinned Windows ImmediateToolTip.AttachReset: context, countdown and date content, three-point stack gaps, seven-point timing inset, 12-point icon/text gap, immediate pointer entry, pointer exit/press dismissal and nonintercepting details action agree with the existing Mac implementation. Added a native UI regression that selects a fully visible right-side OpenAI event in the compact fixture, hovers it, obtains the newly visible owned panel's bounds, verifies window containment and the 320-point cap, reads the actual panel pixels with Vision, and checks the account/context/countdown/date. It then verifies exit dismissal, hover reopening, click dismissal and matching account/quota details (Work · Pro, weekly 58% Used · 42% Left in this fixture).

The first test run's only failure was Vision recognizing the uppercase I in OpenAI as lowercase l; actual cropped pixels show correct OpenAI text. The final check accepts that optical ambiguity, strengthens details matching and passes. Inspected the retained production-panel crop in artifacts/reset-tooltip-native-check: 418×218 Retina pixels (209×109 points), complete account/window context, 5d 0h countdown and Mon, Nov 9 10:16 AM date, intact rounded border and icon. This establishes one real native compact hover/exit/click-through path with synthetic data, not a physical-user mouse check or every edge/expiry variant. Existing history-hover acceptance is not broadened by this result.

Also corrected the event plan badge's explicit 10-point Segoe Semibold Label to the shared measured fallback line metrics and reserved its native one-point border inset. Its 12-point text line plus two points of vertical padding and two border points retain the 16-point outer height, while horizontal inset and glyph position now match the source structure. Historical count markers use a different Canvas text pipeline and were intentionally left unchanged pending measurement. Canonical build passed. Normal live app restored through the canonical script; forced edge clamping, expiry tooltip variants and final raster acceptance remain open.


### User-requested warning icons for quota service messages

Replaced inline quota-row notes with a yellow filled warning triangle immediately before the quota title, shared across providers. Hover uses the existing immediate styled help popup with the full original message. The icon is also an accessible button with the message as its hint; clicking it opens the same usage details as the title. Kept the title as a separate details action rather than nesting buttons. Healthy rows without notes have no icon. Repeated Demo Data row notes are omitted because the dashboard header already identifies demo mode. Existing message-selection rules and provider/credential state are unchanged. This is an intentional user-requested change from the Windows inline-note layout, recorded in tasks/parity.md.

Canonical build and normal launch passed. Native service-message test verifies the icon precedes the title, appears on Codex/Copilot/Claude permission fixtures, replaces the inline paragraph, renders the message on hover, opens full details from both icon and title, and disappears in a healthy fixture. The existing count-usage overage/missing-limit details test also passed. These are synthetic behavior checks. In the restarted live dashboard, directly inspected Devin Monthly ACUs and Copilot AI Credits · Monthly: yellow icons precede their quota names, permission paragraphs are gone, rows are compact, and the healthy Codex weekly row has no warning icon. The live AX hints retain the exact Keychain permission message. No credentials or access permissions were changed.

### Native expiry tooltip and forced window-edge placement

Added an isolated `edge-tooltips` demo scenario and stable refresh/expiry event identifiers for native interaction checks. The expiry is six days ahead at the compact viewport’s right side; the test explicitly proves that centering its popup would overflow, then verifies the actual popup ends eight points inside the window. This exercises the existing placement implementation rather than merely checking a conveniently centered event.

Canonical build passed. Both native tooltip tests passed together: expiry and quota refresh show their distinct wording and countdown, remain inside the dashboard, dismiss on pointer exit, reopen on hover, and permit the underlying event click. The expiry opens Available Resets containing the exact fixture credit; the refresh opens its matching account and quota values. The captured expiry popup was visually inspected: orange clock/countdown, two context lines, date below the countdown, purple rounded border, no clipping. Screenshot: ignored `artifacts/expiry-tooltip-native-check/E229EA9D-9A48-4466-858B-0A69819EFDCE.png`. These are isolated demo UI checks, not live provider reset verification. No tooltip behavior correction was necessary.

### Rendered account drag, bottom-edge scrolling and outside cancellation

The native compact-dashboard test now uses macOS XCTest `click(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` from the actual account grip. With the standard four-account demo, it moves OpenAI Personal from first to last, holds at the bottom edge for 1.5 seconds, verifies all four resulting card positions and a greater-than-50-point scroll displacement, then drags the last card over the fixed header. That outside release leaves the saved demo order unchanged and restores the exact pre-cancellation position. The passing run used production dragging code unchanged; temporary diagnostics were removed. An earlier test attempt used XCTest’s touch `press` API and delivered no mouse-down to the grip; it does not establish an app failure.

Native test passed with zero failures. Visually inspected the owned-window attachment `artifacts/account-mouse-drag-native-check/9FD08DD0-091E-420B-86CF-D6814556B9F2.png`: the scrolled lower dashboard shows Claude followed by the moved OpenAI Personal card, with ordinary card borders restored. This closes rendered bottom-edge scrolling and outside-release cancellation for this demo fixture. It does not measure frame pacing or establish live-account persistence across relaunch; smoothness and broader lifecycle checks remain open.

### Horizon chart height, navigator gap and date-rail alignment

Reviewed Windows `HistoryChartLayout.cs` and `HistoryTimelineView.cs` directly at reviewed source eb042cb. The minimum selector/chart height is 16 + 3×66 + 2×6 = 226; the history grid’s navigator row gap is 12. Mac’s empty path used a separate 216-point chart and its outer stack supplied a 16-point navigator gap. The empty path now shares the populated minimum height, and chart/navigator share their own 12-point stack. Horizon content also reserves the Windows border’s one-point inset.

With the corrected classic-font heading heights (17-point weekday, 7-point gap and 16-point date), Windows places the rail at heading height + 18 = 58. Updated the rail, day dots, future tiles, historical markers and plot top together from the old 56-point anchor. Compact empty Today uses half the source 80-point minimum day width. Its current-time guide now uses the shared plot bottom (height minus eight), source 1.5-point stroke and 4/4 dash instead of its separate longer/thicker guide. The previously added 12-point right rail reservation remains.

Canonical build passed. Four native UI checks passed together after the geometry changes: compact empty controls, history hover/dismissal, refresh tooltip click-through, and expiry tooltip edge clamping/details routing. After the final empty-guide styling change, reran the compact empty check successfully and inspected the 1578×1388 owned-window capture `artifacts/empty-horizon-final-native-check/EC845D55-40FA-44A8-906E-4BE89AE26420.png`. Rail, Today/date, dashed guide, navigator and settings are intact; the lower toolbar is reachable at the same compact size. The new check explicitly reopens a restored-closed dashboard and activates the newest isolated process before clicking, avoiding collisions with the normal app’s identical bundle ID. Demo/isolated empty-state evidence only; date/native title bar and exact whole-image raster parity remain separate.

### Shared settings-card border inset

Reviewed current Windows SettingsPage.WrapCard at eb042cb: Border contributes its one-point stroke before Padding=16. SettingsCard now reserves 17 points in the Mac card, matching that inner-content geometry across global and account settings. Regular Segoe UI body labels retain their natural metrics; the measured Semibold fallback compression is deliberately not applied to these regular labels.

Canonical build and normal launch passed. Four hosted typography regressions and three native UI tests passed: focused nickname save/failure/recovery, Alert History return to global settings, and exact custom-color keyboard save/cancel. The color test captures the wide account panel before opening the picker. Inspected `artifacts/settings-border-native-check/F96E5976-CC06-44DA-BED1-1B4115CBACE8.png`: Account, Available Resets and Other Alerts are intact with the one-point content reservation. Regular text/card raster comparison remains open pending the expanded Windows capture; these checks do not establish full visual acceptance.

### Native Windows account-settings typography evidence

Expanded reference workflow [42342870134](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42342870134) completed successfully at harness 8277f95. Downloaded to ignored `artifacts/windows-ui-reference-8277f95`; inspected the account-settings screenshot and UIA export. Regular Segoe UI labels explicitly measure 19 points at font 14 (Account Name, Line Color and both expiry dates), 27 points at font 20 (2 Available), and 18 points at font 13 (Other Alerts description). Semibold section labels measure 26 points at font 21. This supports retaining regular-text natural metrics while using the existing correction only for measured fallback labels. Requested-family UIA strings remain distinct from physical-font proof.

The runner viewport remains 800×680 including its invisible frame margins; its settings panel is compact, whereas the Mac attachment above is a 1000×800-point sheet. Both forms and their labels render, but this evidence does not establish whole-image equality across those different viewport sizes. The initial expanded run was cancelled after a selector-height correction; the next run failed because Windows PowerShell decoded a literal middle dot as ANSI. The successful run uses an explicit Unicode code point and uniquely selects the actual application action. Neither failed attempt is counted as account-settings verification.

### Measured horizon scrolling: prepare future schedules outside viewport redraws

Used the code-first SwiftUI performance-audit workflow and Apple’s [Instruments guidance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance). A usable paired capture attaches to a single already-visible isolated demo process, avoiding launch-time window/target ambiguity. Baseline PID 33979 (`artifacts/horizon-scroll-attached.trace`) and changed PID 38648 (`artifacts/horizon-scroll-prepared.trace`) each had one Scrooge instance, the same canonical Debug build settings, 1463×866 reference window, fixed 2026-11-04T16:16:00Z demo clock and twelve half-page vertical-wheel inputs on the horizon header: three back/three forward, repeated twice. Native AX navigator dates advanced through Nov 3/Nov 2 and returned to Nov 4 midnight. No live provider or credentials were included. Earlier launch-based captures did not expose scrolling updates adequately and are excluded from this comparison.

The baseline identified DynamicBody<ViewBodyAccessor<HorizonView>> rebuilds at each gesture. Future events were regenerated, sorted and compared through Calendar separately for each rendered day and other consumers. Added pure HorizonFuturePresentation: saved schedules and calendar-day buckets prepare when persisted view inputs change; scrolling reads the prepared buckets. Clock filtering stays dynamic, so an event still expires at its deadline without another provider snapshot. Account/snapshot/visibility/order/time-zone changes rebuild the presentation. Identity rejection, reported-zero reserves and missing-date behavior continue through the existing HorizonEvent event builder.

Paired Instruments exports (nanoseconds converted to milliseconds):

| Measurement | Before | After |
| --- | ---: | ---: |
| Larger HorizonView rebuilds (>1 ms), count | 12 | 12 |
| Mean of those rebuilds | 7.425 ms | 6.544 ms |
| Worst HorizonView rebuild | 11.140 ms | 7.578 ms |
| All HorizonView rebuilds, count | 16 | 42 |
| Mean across all rebuilds | 5.577 ms | 1.904 ms |
| Worst app frame-update interval during the gesture window | 42.739 ms | 36.117 ms |
| Unique update intervals above 30 ms | 10 | 6 |

All-update sample counts differ (25 before, 551 after), so their means are not used as a like-for-like FPS comparison. Duplicate nested update records with identical start/duration are counted once. This is one paired Debug/demo measurement under instrumentation, not a release-build or physical-wheel smoothness certification. Residual multi-millisecond rebuilds and long update intervals remain; do not close the smoothness requirement.

Canonical build and normal launch passed. Seven hosted horizon tests and four native UI tests passed together (history/filter/demo exit, history hover, refresh details and expiry edge clamping). Added a regression comparing prepared schedules with the existing builder across clock advances, exact deadline removal, DST/time-zone day buckets, hidden/disabled accounts and changed identities. Extended and reran the native filter test: hiding OpenAI Personal removes its reset tile, showing it restores the tile. Restored the normal non-demo app after profiling.

### Threshold pointer targets and captured readouts

Shared action-button review confirmed the 44-point minimum already matches Windows ActionButton; no speculative button-size change was made. The remaining threshold-feedback check exposed a functional defect instead: UsageBar attached its hover and drag handlers after `.position`, outside the 32×48 thumb target. An attempted Warning interaction displayed Critical feedback and did not move Warning correctly. Moved positioning outside the thumb’s interaction/accessibility modifiers so the handlers remain local to the actual target. The visible 10×36 markers and named-coordinate drag calculation are unchanged.

Canonical build passed. Three native tests now exercise Info, Warning and Critical separately with real macOS click-and-drag, verify the moved marker’s expected snapped position (including unchanged Info/Critical positions for the Warning drag), then inspect the owned floating popup. All three pass two-point placement above the bar, stable top through value changes, OCR of the correct severity/current percentage, Escape/exit dismissal, pointer-selected Left/Right adjustment and ordinary bar-space clicks opening quota details. The original accessibility `value` string is empty for these Other-role elements in XCTest, so the regression uses actual marker positions and popup OCR rather than treating that unsupported XCTest value as an app-state error.

Inspected all three Retina popup captures in ignored `artifacts/all-threshold-readouts-native-check`: Info is 388×82 pixels, Warning 444×82, Critical 408×82 (194/222/204×41 logical points). All show the expected blue information, yellow warning or red critical icon, white Semibold caption, two-tone border and rounded dark surface without clipping. Warning’s 222×41 box agrees with reference34’s intrinsic popup dimensions for the same-length percentage text. These are wide-demo hover/after-drag crops; they do not establish the complete compact gallery frame or capture the mouse while held. The final native run includes all keyboard and bar-space routing checks and passes with zero failures.

### Remaining draggable-control target audit and native quiet-hours regression

Reviewed positioning and gesture/hover scope across HorizonView, SettingsView, AccountSettingsView and shared Theme controls after the threshold fix. Quiet-hours labels position outside their own tap/key handlers; the chart intentionally uses one whole-track pointer handler that selects the nearest boundary, including its existing overlap alternation. Spectrum, brightness, volume, polling and navigator input intentionally cover their track/plane. No analogous thumb-local handler defect was identified in this source review; it does not substitute for rendered testing of every control.

Added and passed a native quiet-hours regression using the actual default schedule (enabled, midnight–8 AM). A real mouse drag moves Start four hours backward across midnight to 8 PM while End stays fixed; a separate End drag reaches 10 AM without moving Start. Clicking Start’s label and pressing Right/Left changes 8 PM→9 PM→8 PM and updates the 14/13/14-hour overnight summary. Disabling quiet hours rejects a physical drag and a subsequent arrow input without changing the schedule. Closed settings normally. No production control changes were needed and no live preferences were changed.

Inspected the 1000×800-point owned-sheet capture `artifacts/quiet-handles-native-check/63960842-DF1B-4DD3-B544-623A0630B95B.png`: both handle labels, white Start focus ring, selected overnight interval, axis labels and full summary are visible. The screenshot also contains the surrounding Sounds controls, but this is not audible-output verification or final full-image equality with reference03. Canonical build and normal launch passed after the test.


### Downloaded Preview 409 verification — 2026-11-07

Selected source: `10f14d5eeba299a8636abccd0e237a170589ad77`. GitHub Mac Preview run [42345266120](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42345266120) completed both build and publication successfully. Its hosted suite executed 145 tests with two installed-CLI skips and zero failures. Downloaded the published `preview-409-1` release ZIP, rather than substituting a local rebuild. `artifacts/preview-409-ci.log` saves the CI evidence.

The ZIP checksum is `44200684ff9cf7d850b52591500f720ca04dd52cf3bce2583897694cc48d825d`. Independent extraction passed strict deep signature verification, including the nested Sparkle updater/XPC helpers. The app is arm64, build 1480, display version v2026.11.7.000. All 28 source font, image, sound, color-name and GitHub configuration files match packaged bytes. Assets.car is present and no DevinProfiles/DevinTrials directories are included. Saved the machine-readable result and Gatekeeper assessment under `artifacts/preview-409-download/`.

Stopped the normal dashboard before opening the extracted Release app with `SCROOGE_TEST_MODE=1`, `--demo --compact` and fresh `/tmp/scrooge-preview-409-native-check` storage. The sole process was PID 57933 at the extracted bundle path. Native accessibility confirms four demo accounts, History on, quota/reset detail controls and Custom Order. The owned-window screenshot `artifacts/preview-409-dashboard.jpg` shows the rendered compact demo, provider icons, fonts and timeline; its isolated SQLite database was initialized. This is actual downloaded Release launch evidence, not live provider verification or a full raster parity assertion.

Gatekeeper rejected the ad-hoc app with exit 3. No Developer ID Application identity is available on this Mac. No quarantine/security policy was bypassed. Trusted signed/notarized distribution and a clean-Mac launch remain open. Stopped and unregistered the extracted bundle and restored the canonical working dashboard; only one Scrooge instance remains. No production code changed in this verification pass.


### Native unavailable/critical status summaries and privacy — 2026-11-07

Added `testUnavailableStatusIndicatorAndPrivacy` and `testCriticalStatusIndicatorAndPrivacy` in the native dashboard UI suite. Both pass in one invocation against isolated demo storage (`artifacts/status-indicator-native-check.log`; result bundle `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-15-21--0600.xcresult`). The permission fixture exposes “Some Current Usage Data Is Unavailable” in its native status-item title. The healthy fixture exposes “Critical Alert · Quota Refresh” for the currently due Codex refresh reminder. The test uses the actual View-menu Privacy Mode action: critical details become Account Details Hidden and the native title excludes Personal; disabling privacy restores the summary. The unavailable summary remains through both changes. Tests activate the newest isolated process and reopen a restored closed dashboard when necessary.

Earlier test assumptions were corrected: AppKit status items have an empty XCTest label and expose the summary as title; full debugDescription also contains historical query paths, so assertions now query current native titles. A higher-priority critical refresh reminder legitimately wins over the weekly low-capacity alert. These were test issues, not evidence of a production defect. No application behavior changed.

Actual icon appearance and menu clicks are not established: attempts to open the status menu did not yield hittable actions, even after stopping the normal app. Inspected owned status-item screenshots (`artifacts/status-indicator-native-check/D6F49C66-DF15-428F-9F55-531B242C7AC5.png` and `C41F6E9A-CD30-4F53-83EB-43D6C34B02AC.png`) show the menu-bar overflow chevron at the reported Scrooge location, rather than Scrooge glyphs. Removed these misleading icon attachments from the durable tests; the passing logic is unchanged. No menu-bar system preference was changed. Visual info/warning/critical/unavailable glyph review and deliberate status-menu actions in these states remain open; existing normal live status-menu checks remain separate. Canonical build/launch restored after the tests with one Scrooge process.


### Compact held threshold feedback and pointer focus — 2026-11-07

Extended the native threshold helper with `testCompactThresholdReadoutTracksDragAndDismisses`: 789×694-point dashboard, fixed Nov 4 demo time, muted Codex 5-hour alerts and a weekly Warning drag from 30% to 26% remaining, matching reference34’s interaction state. Scrolls through the vertical scrollbar using the sort row’s actual location before selecting the marker. Verifies contained popup bounds, the two-point bar anchor gap and stable popup top, unchanged Info/Critical positions, OCR of Warning/26% Left, pointer-selected arrow adjustments, Escape/exit dismissal and the bar-space quota-details action. Owned full-frame and marker attachments supplement the existing cropped popup. Popup detection excludes small unrelated native tooltips rather than treating every newly visible window as threshold feedback.

An actual held-pointer capture exposed a large 32×48 focus outline around the mouse-selected marker. Windows `Platforms/Windows/ThresholdEditor.cs` at eb042cb explicitly selects `FocusState.Pointer` while retaining `UseSystemFocusVisuals = true`; reference34 does not show this large keyboard outline during the mouse drag. `UsageBar` now remembers pointer selection, suppresses that custom outline for pointer focus, restores it on arrow input and clears pointer state on focus transfer/cancellation. Keyboard focusability, arrow adjustment and the painted 10×36 marker remain intact.

Added an opt-in longer hold to the native test (`TEST_RUNNER_SCROOGE_CAPTURE_HELD_THRESHOLD=1` when invoking xcodebuild). During that real 20-second mouse hold, a foreground-process-checked capture of only the isolated app’s 789×694 display rectangle includes its separate floating panel. The corrected capture `artifacts/compact-threshold-held-corrected.png` shows Warning Alert @ 26% Left above the weekly bar without the large outline. The simultaneously inspected owned window list reports dashboard (353,119,789,694) and popup (796,632,222,41). The popup is contained in the dashboard; its lower edge is two points above the bar. This establishes actual held feedback, not just a post-release hover. No desktop-wide capture or system-permission change was used.

Earlier attempts are not held-popup evidence: the separate capture child launched by the UI-test runner returned failure and was removed; a base-window-only computer-use screenshot omits the separate popup. The successful bounded parent capture includes both. Initial compact pointer failure came from selecting an offscreen marker after insufficient scrolling; corrected fixture setup brings the card into view. Surrounding scroll position, native title bar, fixture countdown timing, requested omission of repeated Demo Data notes and final card-inset/raster differences remain separate from this verified popup interaction.

Final verification: all four native threshold tests (compact Warning plus wide Info/Warning/Critical) passed together, zero failures, in `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-26-38--0600.xcresult`; log `artifacts/all-threshold-final-native-check.log`. Inspected the compact pointer marker (`artifacts/all-threshold-final-native-check/9E90AD56-15E0-419B-B1CD-B65346F00542.png`) with no large outline and the same marker after arrow adjustment (`326C451C-7224-4602-AC01-EBF4F3B57D40.png`) with its keyboard outline restored. The full compact frame (`445E4E11-7E29-4891-897C-FCDEFCCD3119.png`) and cropped Warning popup (`AC91CF24-E222-4F2F-903D-2B86D0B91285.png`) are retained in the same export. Canonical build and launch passed after the tests, with one working-app process restored.


### Quota-row and usage-bar border insets — 2026-11-07

Re-read Windows `Controls/QuotaRowView.cs`, `AccountQuotaView.cs`, `UsageBar.cs` and `CapacityAlertToggle.cs` at eb042cb. QuotaRowView derives from Border with transparent stroke and zero padding; the one-point border still participates in layout. UsageBar has a one-point outer Border around its content grid. Mac previously painted the usage outline over full-width content and omitted the transparent row border. Existing account-card and plan-badge border corrections did not cover these nested surfaces.

The current Windows native capture/UIA from run42342870134 (`artifacts/windows-ui-reference-8277f95/account-rows-elements.json`, release v2026.11.6.006) supplies independent geometry evidence: account identity x230, quota title x231, alarm-on button x232 and usage details content x321. Usage details are 46 points high; threshold Thumb targets are 48 and centered over the content. The bar-content width is 476 and the measured marker span is 460. This confirms the two layout reservations rather than inferring an arbitrary offset from JPEG edges.

QuotaRow now reserves one point before applying its outer 56-point minimum. UsageBar keeps its 48-point outer size, reserves one point around its geometry/content, paints the outline inside the outer bounds, and centers the 48-point targets over its 46-point content. Labels retain their source 15-point inset inside that content. The tooltip anchor remains at the outer target top (minus one point relative to the inner content), preserving its two-point gap.

The compact native threshold regression now checks the source-measured relative x offsets 1/2/91, content/target heights 46/48, shared vertical center and inner-width-minus16 marker span, with half-point raster tolerance. The first targeted run passed, including OCR, drag, arrow, dismissal and quota-details routing. Inspected its full compact capture `artifacts/quota-border-native-check/63BD31A9-E54C-409E-A3A5-BF6BE9BECE51.png`: controls, labels, countdowns and popup fit. Native result: `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-31-40--0600.xcresult`. This closes the identified nested-border inset discrepancy; it does not establish exact total card height or full raster identity with the older gallery frame.

Final regressions: all five selected native tests passed together with zero failures: compact Warning, wide Info/Warning/Critical, and row-alarm pending-save/failure restoration. Result bundle `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-32-30--0600.xcresult`; log `artifacts/quota-border-regressions.log`. Canonical build/launch passed after testing, restoring one normal app instance. No provider transport, credentials, persistence or quota interpretation changed.


### Dashboard sort-group border and separators — 2026-11-07

Reviewed Windows `Controls/AccountSortControl.cs` and `ActionButton.cs` at eb042cb. AccountSortControl has a one-point outer Border, three independent one-point divider columns and four equal star-width buttons. Each ActionButton is 44 points high; the outer sort group is therefore 46 points, with the adjacent 44-point action centered vertically. The first/last button corners are explicitly nine points inside the ten-point outer radius, and the group background is #232429. The existing Mac group painted its border/dividers over the buttons, omitting layout space and the independent inner corner shapes.

Mac now reserves the outer border, gives each divider its own one-point column, permits equal flexible segment widths and clips the end segments to the source nine-point corners over the source group background. Other action-button sizing remains unchanged: the current comparison does not establish that changing their intrinsic width globally would improve parity.

Added compact and wide native sort checks. They measure the 44-point segments, equal widths, one-point gaps, first-segment/card-grip leading alignment and adjacent-action vertical alignment. Each of Most Remaining, Least Remaining, Next Reset and Custom Order must become the sole selected mode and render the expected four-account vertical order; returning to Custom Order restores its drag grips. A bounded composite screenshot checks that the fixed header remains visible after scrolling, using OCR on the owned header region and saving only the owned dashboard rectangle. No live provider data or credentials are involved.

Initial automated page-scroll attempts still had the pointer over Reset Horizon and correctly moved the horizontal viewport instead of the page. Native page-scroll tests now explicitly hover the vertical scrollbar before sending wheel input, covering compact empty-state navigation, threshold setup and drag setup as well as sorting. The local monitor correctly uses the actual event position; no production wheel-routing change was made. One base-window capture omitted the header, while the composite capture/OCR established that the actual header was present. OCR’s Al/AI ambiguity was corrected in the assertion by matching the brand words and subtitle instead of mistaking a lowercase-l recognition for missing UI. These failed attempts are not counted as acceptance passes.

Final verification: all five native checks passed together, zero failures and no test skips: compact/wide sorting, compact threshold feedback, compact empty navigation, and actual account drag edge-scroll/cancellation. Result `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-44-12--0600.xcresult`; log `artifacts/sort-border-regressions.log`. Wide owned capture `artifacts/sort-border-final-native-check/3150762E-7C0B-4866-9748-EE4191ECD0E2.png` was inspected. The compact automated composite `9F26E71B-666E-4F70-A4A4-01B7345C7586.png` has partially missing text layers despite correct geometry/current accessibility and a visible header; it is not counted as a complete visual pass.

To distinguish that capture from stable application rendering, stopped the normal instance and launched the canonical current binary alone with SCROOGE_TEST_MODE=1, fresh `/tmp/scrooge-sort-stable-native-review` storage, compact demo and the same fixed timestamp. Native computer-use moved the main page scrollbar to 0.42 and captured the settled dashboard. `artifacts/sort-border-stable-compact.jpg` shows all four sort labels, the selected end corner, separators, adjacent Exit Demo, header actions, provider identity/badge, both quota names/countdowns and complete usage labels. This supplies stable compact visual evidence without assuming the incomplete automated snapshot was correct. It does not prove absence of every transient rendering issue or final whole-image raster parity. The isolated demo was then stopped through the canonical build/run loop and the normal single-instance dashboard restored.


### Shared action-button border bounds and sort icon extents — 2026-11-07

The existing Windows capture already supplies sufficient button geometry; a new Windows capture was not needed. At pinned source eb042cb/release v2026.11.6.006, `dashboard-elements.json` reports Refresh 109×44 and Settings 113×44. Before this change, a hosted NSHostingView fitting-size probe measured the corresponding production Mac components at 107×44 and 111×44 (`artifacts/action-button-measurements.log`), confirming the missing two border-layout points. `Controls/ActionButton.cs` wraps its padded content in a one-point native Border.

`ScroogeButtonStyle` now reserves that border for nonsegmented actions before applying its outer 44-point minimum and paints the stroke inside the bounds. Segmented alarm/sort actions retain their existing dimensions. The custom keyboard color-editor footer uses the same inset. Explicit inner minimums were adjusted so the source outer sizes remain unchanged: provider chooser 54 (ThemedDialogs.ChooseAsync), Alert History rows 80 (MainPage.Alerts), and paused/no-quota actions 70 (MainPage). Icon-only horizon/reminder actions retain 44×44. Header Refresh now uses the source 20-point icon/progress ring and nine-point icon/text gap instead of compensating with 19/10.

The icon audit also found that ActionIcon’s final square frame overrode the source capacity meter’s 22×20 and Custom Order canvas’s 20×22 extents. Their actual artwork was already correct, but neighboring text was laid out using a 20×20 slot. Those two final frame extents now match the source, while ordinary 20×20 action glyphs retain their size.

Seven hosted typography/component checks passed, including independent Windows button-bound expectations and source icon/minimum-size contracts (`artifacts/action-button-bounds-tests.log`). Five native tests passed together with zero failures: compact/wide sorting, reconnect cancellation/provider choices, populated Alert History and color-editor keyboard/save/cancel. Native header assertions confirm Refresh 109×44 and Settings 113 wide in both layouts; the horizon action remains 44 wide. Provider rows remain 54 high, and the populated history row remains 80 high. Native result `/tmp/scrooge-keychain-clean-tests/Logs/Test/Test-AITokenScrooge-2026.11.07_00-55-14--0600.xcresult`; log `artifacts/action-button-native-check.log`.

Inspected complete compact/wide dashboard captures (`artifacts/action-button-native-check/A95B503F-40E7-43DA-9F28-2D339DD04F47.png` and `77B97619-A1F2-4CA7-B0E1-7F09829C4117.png`) and populated Alert History (`4CF4293B-0395-4CD2-9010-B88CD6009044.png`). Labels/icons are intact; history rows retain their three-line content and source minimum. These current complete captures supplement the incomplete compact snapshot recorded in the prior pass; they do not retroactively validate that snapshot or prove every transient frame. Canonical build/launch passed and restored one normal instance. Exact glyph rasterization, wider per-surface screenshot acceptance, and live/distribution requirements remain open.

### Historical-marker projections during scrolling — November 7

`HorizonPresentation` already caches calendar-to-content positions for historical samples and events, but historical marker grouping and dashed-line drawing still called `HorizonViewport.position(at:)` during every pan. Reuse `historyX` in both paths; marker layout accepts the prepared projection while retaining its original fallback for other callers. Visibility bounds, stable grouping, event order and lane allocation are unchanged. Existing cache invalidation for time zone, history revision, day origin and scale remains in control.

A standalone optimized Swift check compiled the production Models, ProviderMapping and Format sources. It compared IDs, event order, positions and lanes across ten panned viewport/time-zone cases (Chicago including the November daylight-saving boundary, and UTC), then measured 100 layouts of 3,000 events. Three paired runs measured 1,197–1,241 ms for the original calendar-projection path and 146–155 ms with prepared positions. Both paths returned identical marker counts. Sources/log retained at `artifacts/marker-position-cache-check.swift` and `artifacts/marker-position-cache-check.log`. These are model-layout CPU measurements, not SwiftUI frame rates or proof of physical-wheel smoothness. Canonical app build and complete test-bundle build passed. A hosted regression covers prepared/fallback grouping, tie order, clipping and lanes across five pan positions in each time zone.

Native demo verification after the change: a wheel scroll over the timeline moved its navigator from November 4 to October 28; a historical Copilot marker opened matching October 31 monthly-refresh details. Wheel scrolling over a quota row moved the page vertically while the navigator stayed at October 28. Owned panned capture: `artifacts/marker-cache-panned-demo.jpg`. Restarting the stalled user test service recovered hosted execution: all 14 focused history/performance tests passed, then all 150 hosted tests passed locally with zero failures. Logs: `/tmp/scrooge-marker-cache-tests-fresh-service.log` and `/tmp/scrooge-marker-cache-regressions.log`. Physical-wheel frame pacing remains open.

The subsequent combined invocation completed all 150 hosted tests successfully, then the three requested native UI checks failed to start: `Timed out while enabling automation mode` after 60 seconds. The overall command therefore exited 65. No native UI test pass is claimed for that run; manual computer-use checks above and prior native evidence remain distinct.

### Account removal confirmation matches current Windows — November 7

Compared Windows `eb042cb` Views/SettingsPage.cs with the Mac confirmation. Windows uses title `Remove Account?`, message `This removes the saved connection from Scrooge. Your provider account is unaffected.`, and primary action `Remove`. The Mac independently used a longer title, different message and `Remove Account` primary action. These strings now match the Windows source; the shared dialog layout and account-removal implementation are unchanged.

Canonical build/run passed. In the normal native app, opened Devin account settings, opened Remove Account, and inspected the rendered confirmation. Title, message, Remove/Cancel order, trash/cancel icons and shared footer are present; captured `artifacts/remove-confirmation-source-matched.jpg`. Chose Cancel and Close to return to the dashboard. A read-only before/after comparison confirms the account-settings digest is identical, all three accounts remain and pending credential retirements remain zero. No removal was performed. Native XCTest remains gated by the previously requested macOS automation authentication; this reversible text change was verified through native computer use instead.

### Native settings switch layout slots — November 7

Current Windows `eb042cb` native account-settings UI Automation evidence reports Monitor This Account as a 40×40 control. Its SettingsPage.Toggle row has only a 36-point minimum, but the Windows switch's intrinsic height expands that row to 40. The Mac's custom switch paints a 40×20 track and has no corresponding intrinsic 40-point height, so its 36-point minimum compressed each row by four points. The three Other Alerts rows were therefore twelve points shorter overall; native before-capture track centers are 44 points apart rather than the source's 48-point row-plus-gap pitch.

Global settings switches, account monitoring/rule switches, and the quiet-hours header switch now reserve 40-point layout slots. The visible track remains 40×20; the dashboard History switch is unaffected. Canonical build/run passed. Compared native before/after account captures: track-center pitch changed from 44 to 48 points, and the Other Alerts card gained the missing twelve points. Inspected the rebuilt global settings notification/sound switches and quiet-hours heading in artifacts/global-settings-switch-slots-corrected.jpg; account result is artifacts/account-switch-slots-corrected.jpg. No toggles, schedules, accounts or credentials were edited. Closed Settings and left the connected dashboard running. Native XCTest still requires the pending OS authentication; no new implementation-mirroring test was added for these layout constants.

The preceding source/reference review also captured all eight quota-refresh reminder rows in artifacts/settings-refresh-reminders-wide-current.jpg: Info 5 Days; Warning 3 Days; Critical 2/1 Days and 12/6/3/1 Hours. Severity colors, 44-point control rows, six-point gaps and Add/Remove controls agree with reference 06. Account connection help plus Sign In Again/Remove Account order and glyphs agree with reference 18; provider plan/dates differ because the account capture is live. Full raster and interaction acceptance remain separate.

### Runtime timeline trace and indexed status lookup — November 7

Instruments Animation Hitches successfully attached to the isolated history-long Debug demo for a 15-second recording while native wheel input moved the viewport in both directions. The completed trace at /tmp/scrooge-scroll-feasibility-20261107.trace contains 38 hitch rows attributed to Scrooge PID 85283 (reported delays approximately 8.33–41.67 ms). These are instrument hitch events, not per-frame execution times or a Release/physical-wheel acceptance result. Display frame-lifetime rows were not treated as app FPS because that table lacks process attribution. The trace remains local; no raw trace is checked in.

The time-profile export includes repeated HorizonView.historyStatus → HorizonViewport.visibleStart → date/fromCoordinate calendar work inside its point-by-point contains predicate. Replaced that linear scan with the existing inclusive UsageHistory.pointsWithin binary lookup. Compute the same visible start/end dates once and query their reference timestamps, preserving the original date comparisons rather than relying on an approximate projected-pixel boundary. Errors/loading/disabled-history/empty-selection handling is unchanged.

Canonical build passed. An optimized executable compiled the production models and compared the previous date predicate with the indexed query for 164 viewport/date cases across Chicago's spring/fall DST transitions and UTC; all agreed. A deliberately absent 4,000-point / 100-query microbenchmark measured approximately 1.018 seconds for the repeated-calendar scan and 0.000248 seconds for the indexed lookup; this isolates lookup cost and is not a rendered-scrolling speedup claim. In the rebuilt isolated native app, wheel input panned to October 31 with history present and no incorrect empty-history notice; hiding all four timeline accounts produced Select an Account to View History. Restored the normal canonical app. Release profiling and physical-wheel/frame-pacing acceptance remain open.

### Optimized local Release timeline trace — November 7

Built current source `1db74dd` through the existing script/package_preview.sh workflow, which validated the Release bundle, resources and deep signatures. A preliminary plain Release build failed at launch because an ad-hoc app has no Team ID for hardened-runtime Sparkle library validation; both app and framework were already ad-hoc signed. No extra entitlement, system-policy change or new build-script configuration was retained. The established local preview workflow uses its existing ad-hoc development policy; Developer ID packaging keeps hardened runtime enabled. README now identifies the working Release profiling path.

Launched the packaged Release app alone with SCROOGE_TEST_MODE=1, fresh isolated storage, --demo --reference-wide --scenario history-long and a fixed 2026-11-07T08:42:00Z sample. Instruments Animation Hitches recorded PID 93141 for twenty seconds while four alternating native wheel inputs moved October 31 ↔ November 7. Exported hitch data contains 67 events attributed to that PID, with reported delays approximately 8.33–41.67 ms. The CPU table has 1,528 statistical sample rows; repeated NSDateFormatter regeneration/string formatting and timeline/history drawing are present. These identify further areas to review, not proof of final smoothness. The preceding fifteen-second Debug recording used only two wheel inputs, so the counts are not a before/after comparison. Physical wheel acceptance, drag animation and representative longer-session frame pacing remain open.

The raw trace and exports remain local under /tmp/scrooge-release-scroll-20261107.trace and /tmp/scrooge-release-*.xml. Stopped the package app, restored the normal canonical Debug app through script/build_and_run.sh --verify, and unregistered the two temporary Release bundle paths from Launch Services to avoid duplicate app entries. No provider credentials or real settings were changed.

### Reuse timeline date formatters — November 7

The optimized Release trace showed NSDateFormatter regeneration/string formatting during timeline updates. Format now reuses formatter configurations by exact pattern, explicit time zone and POSIX/current-locale mode. A private lock serializes cache access and formatting; the cache is capped at 32 configurations and clears on NSLocale.currentLocaleDidChangeNotification. Existing patterns, nil-value labels, ordinal header text and locale choices are unchanged. This avoids rebuilding ICU formatter state on each redraw without caching date strings or retaining account data.

Canonical app and test-bundle builds passed. The focused hosted CoreTests.testDateFormattingMatchesFreshFormattersAcrossZonesAndThreads passed locally: 192 concurrent cases compare the production functions with fresh formatters across six zones and interleaved locale-change notifications, plus exact header/nil-label assertions. The initial attempt used an older DerivedData directory with a stale ScroogeTests.cstemp signing artifact and failed before execution; the clean test directory passed. A standalone optimized production-source check compared 3,000 complete strings, churned forty time zones and invalidated the locale cache; all outputs agreed. Its formatting-only workload measured 0.388 seconds for fresh formatters versus 0.00359 seconds for reuse. This is not a whole-app FPS or smoothness claim.

A subsequent full local hosted run stalled before test execution. A fresh sample of user testmanagerd PID 41461 confirms it remains blocked in XCTest enableAutomationMode → XAMLocalAuthenticationProvider → LAContext.evaluatePolicy on the already-pending OS authentication request. Cancelled that specific xcodebuild driver (INT, then TERM after cancellation also waited); no test service or authentication policy was changed. Full-suite execution remains for CI, and native UI automation remains pending user authentication. Restored the canonical normal app, inspected its current Updated time and weekly quota's reset/fetch timestamps, closed details and left the connected dashboard open. Matched Release re-profiling remains open.

### Release re-profile after formatter reuse — November 7

Rebuilt `31ad093` with script/package_preview.sh and repeated the twenty-second Animation Hitches recording using the same fixed history-long demo, wide frame and four alternating two-page wheel inputs. Native navigator positions matched the prior run: October 31 2:42 AM ↔ November 7 6:54 PM. Target PID was 4948. The exported CPU table has 1,643 statistical sample rows and zero NSDateFormatter _regenerateFormatter sample rows, compared with seventeen regeneration-containing samples in the preceding Release recording. This is consistent with the intended formatter reuse; absence from statistical samples is not proof of zero executions.

The app-attributed hitch table contains 128 events with reported delays approximately 8.33–58.33 ms, versus 67 in the preceding recording. No overall scrolling improvement is claimed from this pair. Input delivery timing and background load were not controlled tightly enough to establish a causal hitch regression, but this result does not satisfy smoothness acceptance. Repeated viewport position/coordinate/day-anchor/calendar work and history drawing remain in the CPU samples and are the next review targets. Raw data remains local in /tmp/scrooge-cached-date-release-scroll-20261107.trace and its exported XML files. Restored the canonical normal app and unregistered the temporary package path.

GitHub run 42358157605 at `31ad093148ab97a92f2328b9c4ff47749ffaf704` completed successfully: 155 hosted tests, two installed-CLI skips and zero failures. Its log explicitly records the new concurrent date-formatting regression passing. This supplies the broad executed test evidence that the local full run could not provide while testmanagerd waited on OS authentication. Native UI and physical-wheel acceptance remain open.

### Prepared calendar-day geometry while panning — November 7

Release samples continued to include HorizonViewport coordinate/day-anchor/calendar work. Added pure HorizonDayGeometry: prepare the existing day list, grid positions and normalized day anchors once for a projection key containing start/end coordinates, pixels per day and time zone. Horizontal offset is excluded, so panning reuses those values. HorizonView prepares on viewport/history updates and falls back to the original calculation if the key does not match. Day normalization still calls the original viewport helper during preparation; it is not replaced with fixed 24-hour arithmetic. Each timeline day also evaluates Today once, and the last-event day is computed once per heading/rail render rather than inside each filter predicate.

Canonical app and test-bundle builds passed. A production-model executable passed five calendar cases: Chicago spring/fall DST, São Paulo's midnight DST transition, Apia's skipped civil day, and UTC. Every cached anchor/grid position agrees exactly with the original viewport helper; panning retains the key, and independent scale/extent/time-zone changes reject it. The Apia case retains the source's 24 generated cells, versus 23 in the other fixtures. Added the corresponding hosted regression and compiled it; it is not claimed executed locally while testmanagerd remains gated on OS authentication.

In the isolated native fixed-date history-long demo, wheel input panned to October 31 with aligned headings, rail markers, grid and traces (artifacts/prepared-day-geometry-panned.jpg). History off/on rebuilt the layout and returned to today's viewport. Native window zoom resized the dashboard and preserved the current/future date layout. Restored the connected canonical app. This removes repeated calendar projection work by construction; Release hitch/frame-pacing and physical-wheel acceptance remain open.

### Release geometry profile with fewer accessibility queries — November 7

Rebuilt `f6ffb08` through the preview packager and recorded the same fixed wide history-long demo for twenty seconds (PID 18490). Issued four alternating two-page wheel inputs as one deterministic batch; the full accessibility snapshot was taken before and after the burst, not between inputs. The final navigator again reached November 7 6:54 PM. This reduces measurement intrusion but changes the input/query protocol, so its counts must not be presented as a direct before/after speedup versus the earlier recordings.

The app-attributed hitch table contains 105 events with reported delays approximately 8.33–25.00 ms. The CPU export contains 898 statistical sample rows; history drawing is the leading remaining named application work (thirteen samples include HorizonView.drawHistory), with viewport coordinate/calendar work still present at lower counts. This does not establish final smoothness or physical-wheel behavior. Next review target is repeated history drawing, including which chart work can remain stable while the native scroll view pans. Raw trace and exports remain local under /tmp/scrooge-day-cache-release-scroll-20261107.trace and /tmp/scrooge-day-cache-release-*.xml. Restored the normal app and unregistered the temporary package path; one canonical process remains.

GitHub run 42359259570 at `f6ffb08bf7c969b77380be0fdbf66d1398a79381` passed: 156 hosted tests, two installed-CLI skips and zero failures, followed by successful preview publication. Its log explicitly records the new calendar-projection/cache-invalidation regression passing, including the skipped-day fixture. Native UI automation and full visual/physical acceptance remain open.


### Prepared history curve paths outside pan redraws — November 7

Moved stable per-point remaining-value conversion, reset-step insertion, observation-gap segmentation, and stroke/fill/dot Path construction into HistoryCurveDrawing. HorizonView prepares those pixel-space paths when its history projection or plot height changes; pan offset is not an input. Drawing still chooses current account colors and computes hover guides, historical markers, current time and viewport-dependent latest labels dynamically. A plot-bounds mismatch uses freshly prepared source geometry until the owner updates its cache. Stroke width remains two points; isolated observations remain five-point dots.

Regenerated the checked-in project with XcodeGen. Canonical build and clean test-bundle build passed. Added two hosted geometry regressions; the same test bodies also ran in an optimized standalone production-source executable with explicit assertions and return code zero. They cover reset vertical steps, gaps without connecting lines, area closure to baseline, isolated dots, empty series, changed bounds/projection, and refreshed remaining values. Hosted execution is not claimed locally while the prior testmanagerd authentication gate remains unresolved. The first standalone attempt tried unavailable macOS XCTMain and was replaced with the assertion harness; it did not execute tests.

The rebuilt native app used isolated fixed-date history-long demo data (2026-11-07T08:42:00Z). Two-page wheel input reached October 31 2:42 AM. Its plot crop (414,690)-(1535,1109) in artifacts/prepared-curve-geometry-panned.jpg is pixel-identical to artifacts/prepared-day-geometry-panned.jpg: all channel differences zero, both full images 2926x1732. History off/on returned to today; window zoom resized the dashboard, and another pan showed aligned traces and resets. This is demo rendering evidence, not live-provider or frame-pacing acceptance. Release profiling, physical wheel/drag acceptance and the other recorded parity gates remain open. Restored the normal canonical app.


### Release curve-path profile and published artifact — November 7

Rebuilt source ea9f107 with script/package_preview.sh and recorded the isolated fixed history-long demo at 2026-11-07T08:42:00Z, wide reference frame, for twenty seconds (PID 30830). Used the preceding lower-query protocol: one native batch of four alternating two-page wheel inputs, with full accessibility observations before/after rather than between inputs. Final navigator was November 7 6:54 PM. The app-attributed hitch export contains 33 events, with reported delays approximately 8.33–25.00 ms; the preceding same-protocol day-cache run contained 105 events. CPU export contains 464 app statistical sample rows versus 898 previously. No drawHistory-named frames occur in this run's samples, versus thirteen previously; a HistoryCurveDrawing copy appears once. This pair is encouraging evidence for less redraw work, not a controlled performance guarantee or proof of zero drawing executions. Physical wheel, drag and longer-session frame-pacing acceptance remain open. Raw traces stay local: /tmp/scrooge-curves-release-scroll-20261107.trace and /tmp/scrooge-curves-release-*.xml.

GitHub run 42360473475 at ea9f1070d8147a9973aa191b205ea3957792fbd4 completed successfully: 158 hosted tests, two installed-CLI skips, zero failures, and preview publication. Both HistoryCurveDrawingTests explicitly passed. Downloaded that run's mac-preview artifact into artifacts/preview-ea9f107-download and verified its SHA-256 sidecar, strict deep code signature, arm64 architecture, build 1513/display v2026.11.7.000, and byte equality for 27 source font/image/sound/color-name resources. No Devin browser-profile directories were present. Signature is ad-hoc, Team ID absent; Gatekeeper assessment returned rejected (code 3), consistent with the documented development-preview policy. No quarantine removal or trust-policy override was used.

The downloaded app launched alone in SCROOGE_TEST_MODE with fresh isolated demo storage and fixed date. Native quota-bar activation opened matching OpenAI / Personal · Plus, Codex · 5-Hour details with 38% used / 62% left, reset November 7 4:56 AM and Demo data. Close returned to the dashboard. This verifies this specific published binary's demo launch/details, not live authentication or clean-machine trust. Restored the canonical connected Debug app and unregistered both temporary Release/downloaded paths from Launch Services. Developer ID/notarization and other acceptance gaps remain open.


### Compact rows and earned-reset final geometry review — November 7

Inspected source 60833ff in a rebuilt native 789x694-point isolated demo with fixed data 2026-11-04T16:16:00Z plus one presentation second. Captured artifacts/compact-rows-final-geometry.jpg at 1578x1388 pixels and compared both reference27 and the newer eb042cb Windows runner account-rows screenshot/UIA tree. The latter's root is 784 points wide; normalize all absolute UIA x values by its root x=120 before comparing. Mac provider identity x=170, icon x=110 and quota title x=111 agree with that Windows source capture. The shared row inset and control widths retain the previously verified quota-title/alarm/bar-content offsets of 1/2/91 points. The two-quota card is approximately 288 points high in both current captures, and the first/second bar top offsets are approximately 126/231 points from the card top. Wider Mac bars follow the five-point client-width difference. No source-backed spacing defect was found. The title-only row label sits lower than the older Windows title-plus-Demo-data block by design after the user's inline-message removal. Current Windows refresh cycle arrows supersede the old gallery's clock glyphs. Native title chrome and platform text rasterization remain intentional adaptations; full-image pixel identity is not claimed.

Opened the matching November 8 earned-reset expiry through the native timeline. The popup shows Available resets, the same account/two credits, snapshot 11/4/2026 10:16 AM and November 8/13 expiry lines as reference35; Close returned to the dashboard. Current owned-sheet capture artifacts/earned-resets-final-geometry.jpg is 666x570 Retina pixels (333x285 points), versus the reference's roughly 333x283 popup crop. After normalizing the Mac to logical resolution, text-ink row ranges relative to popup top were Windows 33–48,71–82,98–109,125–135,152–162 and Mac 32–48,71–84,99–109,126–135,153–162. This establishes matching wrapping/order and text rows within two logical pixels for this fixture. It does not establish identical glyph rasterization, and the few-point footer/overall-height difference remains recorded rather than hidden by a speculative layout adjustment. Earlier 332x281 measurements predate shared border/action changes and must not be treated as current. No production code changed in this review. Restored the connected canonical app; live provider/physical-pointer and other acceptance checks remain open.


### Current Windows earned-reset measurement closes the height discrepancy — November 7

Extended the read-only isolated Windows reference probe to invoke the uniquely visible earned-reset expiry, export earned-resets.png / earned-resets-elements.json, assert Available resets and the reported count, close it, and continue existing quota/account-settings captures. Published harness 6987029 and dispatched Windows UI reference run 42361188549; it completed successfully in graphical session 2 against the checksum-pinned eb042cb Windows release. Downloaded output is local under artifacts/windows-earned-resets-6987029. No live provider, account, credential or Windows application code was changed.

The current Windows screenshot has exact border pixels #65577F at x234/566 and y194/478, giving 333x285 outer bounds. UIA reports a 331x191 inner content/separator pane, title 156x30 at 22 points, a 283x100 body, four 19-point text rectangles at 27-point pitch, and Close 137x44. With 24-point footer padding, one-point separator and outer border these agree with the current Mac's 333x285 owned-sheet capture. Standalone NSHostingView measurements using the production ReferenceTypography code and bundled fonts independently report title height30, mixed-weight count height19, snapshot height19 and credit height19. The current height discrepancy is therefore closed for this fixture: it came from comparing the newer implementation with the older gallery's approximately 333x283 popup, not an incorrect current Mac line height. No production layout adjustment is warranted. Exact cross-platform glyph rasterization and other content variants remain separate acceptance items.

The native template was also checked at microsoft/microsoft-ui-xaml 85e1269f3a30beffdad33576dc9453b4d2c6e0c0, controls/dev/CommonStyles/ContentDialog_themeresources.xaml: one-point outer border, 24-point content/footer padding, twelve-point title margin, one-point separator and equal footer columns agree with the existing implementation. This supports the observed geometry; runtime measurements above are the direct evidence. Normal app remained running alone throughout the Windows probe.


### Long-message dialog width-first measurement fixes clipping — November 7

Functional review found a concrete compact-popup regression despite the preceding short-popup geometry match. In the existing long-details demo, clicking the yellow quota-message icon opened a 548x421-point sheet whose wrapped body pushed its title above the top edge and Close partly below the bottom (artifacts/long-status-popup-final.jpg). The source note itself wrapped; that alone was insufficient evidence that the entire dialog fit. The short earned-reset fixture did not expose this failure.

Replaced the outer ideal-size/frame combination with a narrow DialogSizing Layout that first resolves the natural width within the existing 320–548 bounds, then measures height at that exact width, capped by the existing maximumHeight. Child placement receives both final dimensions, so overlong bodies can still select the scrolling alternative. Content/footer spacing, title/body fonts, explicit-width dialogs and the 420-point body cap are unchanged. This prevents unwrapped ideal height from being reused after width contraction.

Canonical app and test-bundle builds passed. Added hosted regressions for the independently measured Windows 333x285 earned-reset fixture, a long wrapped body requiring the full 605-point title/body/footer layout, and a 300-point maximum-height cap. Strengthened the native long-note test to require the complete title and Close frames inside the sheet, and added compact coverage. Hosted/native XCTest execution is not claimed locally while the existing OS authentication gate remains unresolved; these tests compile and hosted CI execution follows publication.

Native CUA verification in fresh isolated compact demos: the long-details popup now measures 548x516 points, fully showing title, all wrapped provider text and Close (artifacts/long-status-popup-width-first.jpg); Close returns to the dashboard. The 30-reset list remains 341x605 with an independently scrolling body: scroll value1 exposes the final December4 credit while title and Close stay fully visible (artifacts/many-resets-width-first-footer.jpg). The standard two-credit popup remains exactly 333x285 and its entire capture is pixel-identical to the prior current-geometry capture (all channel differences zero; artifacts/earned-resets-width-first.jpg).

Additional unchanged native branch checks: partial-reset demo shows three reported available credits, one known expiry and the partial-details warning without clipping (artifacts/partial-reset-details-final.jpg). Empty-windows demo shows Quota Refresh (Not reported), no invented zero usage bars and readable compact status actions; clicking the first unavailable-data action opens its matching account settings (artifacts/empty-quotas-final.jpg). Restored the normal connected canonical app. Windows main was freshly checked and remains eb042cb; no newer source changes were found. Live reconnection, physical-input and remaining distribution/OS acceptance gates remain open.


Width-first follow-up verification: GitHub run 42362001216 at 5bff7e4dbf2492edad759ace58b713145ba41b12 passed 160 hosted tests, two installed-CLI skips and zero failures, then published the preview. Its log explicitly records testDialogMeasuresWrappedBodyAtItsFinalWidth and testEarnedResetDialogRetainsMeasuredWindowsGeometry passing. The compact/wide native XCTest changes compiled but remain unexecuted under the local authentication gate. Native CUA additionally checked the normal live Codex details popup: full title and body plus Open Provider Usage and Close fit, and Close returns to the connected dashboard. In a fresh isolated demo the explicit-width Add Line Color popup retains its title and both footer actions; body scrolling exposes the Blue field, Cancel returns without changing the selected #D587A5 swatch, and account settings closes normally. Restored the normal app and confirmed one canonical process. These checks cover shared short, wrapped, scrolling, two-action and explicit-width dialog layouts; they do not establish live provider reconnection or physical pointer/frame-pacing acceptance.


### Keyboard history readout anchor matches Windows — November 7

Reviewed pinned eb042cb Platforms/Windows/HistoryChartInput.cs. Keyboard inspection uses KeyboardAnchor at the visible native chart's horizontal center and y0; pointer-pinned samples keep the clicked point. The Mac used the sample point for both modes, moving keyboard readouts around the plotted lines. Extended the isolated Windows probe to focus Usage History, send Right, require the Weekly / percent-used sample, capture its UIA/screenshot and dismiss with Escape. Workflow run 42362619856 at harness 678d8d3 passed. Downloaded native output is local under artifacts/windows-history-keyboard-678d8d3. Windows chart bounds x270/y382/width589 give center564.5; the readout heading's x488/width153 gives that same center. Heading font is Segoe UI 14/600 in a 19-point rectangle, detail is Segoe UI 13/400 in a 35-point two-line rectangle. The surface is approximately183x81. This is isolated keyboard/demo evidence, not live hover.

HorizonView now distinguishes keyboard inspection from pointer pinning. Keyboard anchors at the visible chart center/top, accounting for the separate 40-point axis gutter and scroll offset in the tracking surface's content coordinates. Mouse taps clear the keyboard mode; clearing samples/focus/navigation also resets it. Sample text, actual plotted guide/selection and pointer anchor behavior are unchanged. Added source-position assertions to the existing native keyboard-entry test; app and native test bundles compile. Native XCTest execution is not claimed under the pending OS authentication gate.

Native CUA fixed compact demo before/after: Right selects the same OpenAI Personal Plus Weekly73% sample. Read-only CGWindowList bounds showed the old panel183x80 at screenx451/y529, with dashboard x353/y116/789x694; its center was189.5 points from the dashboard left. After the change the panel is183x80 at x708/y382, center446.5 from the dashboard left, agreeing with the visible chart midpoint. Right then selects GitHub Copilot Work Max Monthly76.1%; its wider212x80 panel remains centered within0.5 point. Escape exposes No sample selected; Right restores inspection and Tab moves focus to Timeline Navigator while clearing the sample. The existing 80-point Mac versus81-point Windows readout height remains a separate raster/line-metric item; no speculative font adjustment was included. Restored one normal connected canonical app. Physical mouse hover and broader acceptance remain open.


### History readout fractional text advance matches measured Windows bounds — November 7

Investigated the remaining 183x80 Mac versus 183x81 Windows readout. The pinned Windows probe reports a classic Segoe UI 14/600 heading in 19 points and a Segoe UI 13/400 two-line detail in 35 points. The identical bundled regular font has ascent14.0283203125, descent−3.2626953125, and zero leading at 13 points: advance17.291015625. SwiftUI measured each detail line at17 points (1/2/3/4/5/6 lines became17/34/51/68/85/102), while Windows rounds the complete fractional block. The mismatch was body layout rounding, not a font-size or padding difference.

Extracted ReferenceHistoryTooltip as the exact production history surface. Its detail text uses a narrow line Layout and TextRenderer to preserve SwiftUI wrapping/shaping while placing baselines at the font's fractional advance and allocating the rounded whole-block height. The existing 14-point heading, five-point gap, fourteen/ten-point padding, one-point border, colors, width cap and popup placement remain unchanged. Help/reset tooltips and threshold readouts keep their prior paths. Regenerated the checked-in Xcode project.

Canonical app and test-bundle builds passed. Added hosted checks for the independently captured 183x81 Windows fixture and rendered 1/2/4/12-line detail blocks, verifying every line and its final descenders. A standalone executable compiled the production ReferenceHistoryTooltip and ReferenceTypography files with the source color definitions and bundled fonts; all corresponding dimension/render assertions passed with explicit return code 0. Heights were64/81/116/254 for those fixtures, with 2/3/5/13 separate ink groups. The exact comparison component render is local artifacts/history-readout-fractional-metrics.png. Compared with Windows, body/title ink rows remain within one pixel due to platform rasterization; no pixel-identical glyph claim is made.

Native fixed compact demo: Right exposes OpenAI Personal Plus Weekly73%; read-only CGWindowList metadata now reports the actual floating panel 183x81 at x708/y381 against dashboard x353/y116/789x694. The corrected chart midpoint and fourteen-point anchor gap are retained, and Escape clears the readout. Restored the normal connected canonical app. Hosted CI execution of the new checks follows publication; local native XCTest remains OS-authentication gated. Prior keyboard-anchor run 42362999894 at 7093c40 completed successfully with 160 hosted tests, two installed-CLI skips and zero failures. Physical hover, other content variants and remaining live/OS/distribution gates remain open.


### Popup edge-rule equivalence and executed readout regressions — November 7

GitHub run 42363462162 at 72a8610e577cd2aae8caac989f222063489e9df0 passed 162 hosted tests, two installed-CLI skips and zero failures, then published the preview. Its log explicitly records both new readout bounds and multiline/descender render regressions passing. Local native XCTest remains gated by the pending OS authentication request; this hosted result does not imply those native tests ran.

Checked the general history/help/reset popup placement against pinned Windows HistoryChartInput.Show. A standalone Swift executable used the exact x/above/y statements extracted from production Support/HorizonInteraction.swift, comparing their bottom-left-coordinate results with an independently written translation of the Windows top-left-coordinate clamp. All 5,292 cases agreed with return code 0. Cases span three screen origins (including negative secondary-display coordinates), three window widths/heights, four measured popup-size classes (history 183x81, reset 209x109, help 320x118 and longer history 420x254), and 49 anchors including all edges/corners and points outside the owner. Widths are constrained as the real caller does. Every fitting-height case stayed inside its supplied visible bounds. The 441 overheight cases matched Windows top anchoring; they intentionally do not prove full containment of a popup taller than the window. No production placement change was warranted. Harness remains local at /tmp/scrooge-popup-edge-check.swift; this is source-algorithm evidence, not physical-pointer or native edge-hover acceptance.

Read-only signing-identity inspection currently finds Apple Development identities but no Developer ID Application identity. The existing preview remains ad-hoc and Developer ID/notarized distribution remains unavailable until that identity is provisioned; no certificate, keychain ACL or trust policy was changed. The connected canonical app remained running alone during this review. General Windows ToolTip style was also rechecked in Platforms/Windows/App.xaml: it explicitly uses classic Segoe UI 13, fourteen/ten-point padding and a one-point border. Its rendered ordinary-help variants still need their own current measurement rather than assuming the history-only fractional-line correction covers them.


### Ordinary help and reset tooltip text matches native Windows measurement — November 7

Extended the isolated Windows probe with ordinary selector help and a styled reset tooltip. The first cursor-position-only attempt (42364031687 at 65217cf) correctly failed: no help popup appeared in the exported UIA tree or screenshot. Replaced position assignment with accepted native SendInput movement on the runner's virtual desktop and exported observed pointer positions; no input policy was relaxed. The corrected run 42364265780 at a49467d passed every capture against pinned Windows eb042cb. Output is local artifacts/windows-tooltip-input-a49467d.

Windows UIA directly measures selector help 278x57, with two-line Segoe UI 13/400 text 248x35, and reset tooltip 209x110, with context 179x35 at 13/400, countdown 110x24 at 20 and date 110x16 at 12. Existing Mac production components measured 278x56 and 209x109. Importantly, native countdown measurement confirms the existing 24-point fallback line is correct, despite the requested FontFamily string; no countdown font change was made. This avoided an unsupported natural 27-point substitution based on the family name alone.

Extracted the already-verified fractional 13-point line component into ReferenceTooltipText and reused it for history details, ordinary help, and reset context. Widths, colors, padding/borders, popup placement and threshold rendering are unchanged. Regenerated Xcode project. Canonical app and test-bundle builds passed. Added a hosted regression for the native Windows selector/reset bounds and retained 43-point combined countdown/date height. A standalone executable compiled the production tooltip/typography/model/format code and actual style/icon definitions: selector 278x57, reset 209x110, countdown/date 110x43 and history 183x81 all passed with return code 0. The wrapped polling-help component now measures 320x109. Rendered the actual help/reset components in artifacts/help-tooltip-measured-metrics.png and artifacts/reset-tooltip-measured-metrics.png and inspected complete text, countdown, date and icon. Existing multiline/descender coverage still applies to the shared renderer. Hosted CI execution follows publication; local native hover XCTest is still OS-authentication gated, so these are component renders rather than newly completed Mac physical-hover evidence.

The Windows selector ToolTip appears outside its owner client on the left (popup x70 versus client x120), while Mac deliberately retains its existing owner-contained placement. This source-native placement difference remains separately recorded; content-size checks do not claim full placement parity. Restored the connected canonical app, with no real account/settings edits. Physical hover and other live/OS/distribution acceptance remain open.


### Ordinary tooltip placement follows measured native Windows policy — November 7

The native Windows selector/reset captures from run 42364265780 expose a placement difference beyond the corrected text metrics: selector target x168/y390/82x66 has a 278x57 tooltip at x70/y333, touching the target top and extending outside the owner client (x120). Reset target x479/y461/62x74 has a 209x110 tooltip at x405/y351, also touching the target top. Added a moved-window left-edge capture to determine the display limit. Initial run 42365017394 failed on a transient null-valued UI Automation expression after exporting the moved target; the selector was present. After guarding unavailable text ranges and names and exporting failure diagnostics, run 42365234171 passed. Its selector target x56/y390/82x66 has the same tooltip at x0/y333: the surface clamps at the screen edge, without an owner margin. Local reference artifacts are under artifacts/windows-tooltip-screen-edge-b09e5f5.

Ordinary help and reset tooltips now use NativeTooltipPlacement: center over the complete target, touch its top edge, flip below when needed, and clamp to the display work area. They may extend outside the app window. This supersedes the earlier recorded owner-contained ordinary-tooltip adaptation and the overbroad application of HistoryChartInput placement to ordinary Windows ToolTip. Custom history readouts retain their independent owner inset and 14-point gap; threshold feedback retains its own policy. Service-message warning help uses the ordinary-tooltip rule too.

Canonical app and test-bundle builds passed. A standalone executable compiled the production placement helper and passed the three native capture rectangles plus 144 screen-edge, below-target and translated-display cases with explicit return code 0. Added two hosted geometry regressions and updated native reset/expiry/service-message assertions to use screen containment and zero target gap. Native XCTest execution remains gated by the pending macOS authentication prompt, so physical Mac hover and native edge rendering are not claimed. The normal connected canonical app is running; warning-icon click-through was also checked without changing real settings or credentials. Prior Mac Preview run 42365213514 at b09e5f5 passed 163 hosted tests, two installed-CLI skips and zero failures, including the preceding tooltip content-size regression. Execution of the two new placement checks follows this publication.


### Downloaded current production preview — November 7

Downloaded mac-preview from successful GitHub run 42365978491 at production commit 2a932aa74c11fefa48ba7cabf16f3660a4f7406c. The run executed 165 hosted tests, two installed-CLI skips and zero failures; both new TooltipPlacementTests and the help/reset content-size regression explicitly passed. Archive SHA256 is 54377f5fe93872bf05e9332fc674cbe2cfc56a1db8846c0a25e9ce6108b1dc85 and matches its published manifest. The independently extracted build1529 / version2026.11.7 is arm64, passes strict deep codesign verification including Sparkle nested code, and contains all28 byte-identical source font/image/sound/color-name/GitHub configuration resources plus Assets.car. No DevinProfiles or DevinTrials directories are bundled.

Stopped the canonical app and launched the downloaded Release app as the only Scrooge process with SCROOGE_TEST_MODE=1, fresh isolated storage, --demo and --compact. Its four-account dashboard rendered correctly (artifacts/preview-2a932aa-dashboard.jpg). Clicking the Personal Plus weekly timeline event opened matching Codex Weekly74% used /26% left details; Close returned normally. Tab/Right selected OpenAI Personal Plus Weekly73% used at Nov4 12:01AM. Read-only CGWindowList metadata reports the actual separate readout183x81 at x355/y293 against dashboard x0/y28/789x694, retaining the expected446.5-point chart-relative center. Escape cleared the selection. These are demo/keyboard checks, not physical hover or live provider verification.

Gatekeeper rejects the downloaded ad-hoc signature (exit3), as expected: TeamIdentifier is not set. No trust setting, quarantine attribute or credential was changed. Developer ID/notarization and clean-Mac acceptance remain open. Stopped and unregistered the extracted app, then restored the normal connected canonical app using script/build_and_run.sh --verify; build/launch passed and exactly one Scrooge process remained. This supersedes the older ea9f107 downloaded-preview check for the selected production revision only; subsequent evidence-only commits do not change that inspected binary.


### Long polling help uses Windows desired width — November 7

Extended the isolated Windows probe to hover the visible Polling Interval label in account settings and require an actual matching ToolTip. Run42366495646 at harness45ab25d passed. Native UIA measures the current long help surface314x109 at x125/y176, with classic Segoe UI13/400 text284x87 at x140/y187. The target label is x216/y285/190x19. Thus the popup again touches the target top. Its five visible lines end with “this”, “minutes.”, “longer”, “save”, and “automatically.”. The older gallery322x118 is superseded for current-source dimensions; it remains a historical visual reference. Output is local artifacts/windows-polling-tooltip-45ab25d.

The Mac previously assigned every sufficiently long ordinary tooltip the full320-point cap, leaving a six-point extra strip for this message. ReferenceHelpTooltip now wraps at the existing content cap, measures the widest resulting line without trailing wrap whitespace, and uses that desired width plus the unchanged padding/border. CoreText line breaking uses the same bundled classic face as rendering. Leading whitespace is retained; the available-screen cap remains enforced. This is shared behavior for long ordinary help, not a polling-message special case. Short selector help, history readouts and styled reset tooltip sizing are unchanged.

Canonical app and native test-bundle builds passed. An independent executable compiled the exact production help-component source and its typography/shared line renderer; selector278x57 and polling314x109 assertions passed with explicit return code0. The polling render contains all five separate text-ink groups and was inspected at artifacts/polling-tooltip-measured-metrics.png; line breaks agree with the native Windows capture. Added a hosted regression for the independently captured314x109 surface, five visible lines/last line, and constrained widths. Execution follows publication. Local native hover remains OS-authentication gated; component rendering does not close physical-pointer, screen-edge or full raster acceptance. Restored the normal connected canonical app through the standard build/run script.


### Equivalent-size settings captures and enabled switch thumbs — November 7

Extended the read-only isolated Windows probe with account top/connection actions and global-settings top/footer. It derives the outer resize delta from the native host pane and targets789x694 logical points, producing741x630 secondary panels. First run42367327733 selected the784x32 caption-input pane instead of the784x672 host; corrected selection filters caption panes and explicitly ranks dictionary fields by area. Run42367468386 then exposed only a partially scrolled account panel after one endpoint request. The final probe exports vertical scroll percentages/view sizes and reapplies the endpoint after four bounded layout turns. Run42367678432 at5703a86 passed all captures, including visible disabled Sign In Again / Remove Account and visible Alert History / Send Test Notification. Neither authentication, removal, update nor notification actions were activated. Local output: artifacts/windows-settings-panels-5703a86.

At the matched host size Windows connection buttons are649x44 at y537 and589 (eight-point gap), with21-point Semibold Connection heading in a26-point line. The corresponding Mac compact account panel is741x630, with the same full-width44-point actions and eight-point gap, both exposed disabled in demo; reference captures account-settings-matched-top-mac.jpg and account-connection-actions-mac.jpg show all relevant text/actions. Source review independently confirms the same connection explanation and behavior. Global top/footer are also captured in global-settings-matched-top-mac.jpg and global-settings-footer-mac.jpg. This covers inspected structure and sizes, not full per-pixel, baseline or vertical-scroll-offset equivalence. The Mac adds its login-item status in normal mode, and live reconnection/removal remain separate acceptance gates.

The native account capture proves enabled switches use a white thumb on#8170CF, whereas Mac defaults used#141519. For example the Windows matched account screenshot has pure white at thumb-center pixel717/324 and track#8170CF at707/324; UIA exposes the40x40 control target. Changed the shared ScroogeSwitchStyle default enabled thumb to white, retaining its40x20 visual track,12-point thumb, off-state color and explicit per-call thumb overrides. Canonical build passed. Fresh isolated native account capture account-switch-white-thumb-mac.jpg shows the corrected thumb. Clicking Monitor This Account exposes off, then on again; account-switch-off-mac.jpg verifies the existing off appearance. No real account setting was edited. No new test mirrors the color constant; this low-impact visual change is verified by the independent source capture, native before/after rendering and toggle behavior. Full native hover/scroll smoothness and exact glyph raster acceptance remain open.


### Settings retain the empty Windows status row — November 7

Current Windows SettingsPage builds a three-row Grid: Auto heading, Star settings scroll, Auto status Label. The status Label remains present when its text is empty. Native matched-panel run42367678432 at5703a86 independently measures the741x630 panel and541-point scroll viewport. Its68-point header and two outer border points leave19 points for the status row. Mac SettingsView and AccountSettingsView conditionally omitted the row entirely when no error existed, giving the scroll view19 extra points. At maximum scroll this placed both footer actions19 points below their measured Windows positions.

Both panels now retain a minimum19-point status row, with empty text excluded from accessibility. Existing global invalid-reminder / settings-save / general-error precedence and account-save text are preserved, as are trailing alignment, wrapping and horizontal padding. Only the empty-row reservation changes. Canonical app build passed. In a fresh isolated compact demo, account and global panels still measure741x630. Native before/after captures show action border tops moving from Retina1008/1112 to970/1074 pixels: logical504/556 to485/537, exactly matching Windows UIA y537/589 relative to panel top52. The649x44 actions and8-point gap are retained. Captures: account-connection-status-row-mac.jpg and global-footer-status-row-mac.jpg. Set the final demo reminder amount from1 to0: the row exposed complete “Enter a Positive Whole Number for Each Reminder” text, with the local field warning also visible (global-status-row-validation-mac.jpg). Restored1, confirmed settingsSaveStatus no longer exposed, and Close returned to the dashboard. Real settings were not edited; the normal connected canonical app was restored through the standard build/run script.

A separate native action-name inspection remains inconclusive: the long-scrolled settings tree can omit footer button names even with explicit accessibility labels. The actual Alert History action opened the live history list, and Escape returned to Settings. The unproven label changes and their trial test edits were reverted; this is not recorded as a completed accessibility fix. Local native XCTest remains authentication-gated. Prior Mac Preview42367896506 at0fabe0f passed166 hosted tests, two installed-CLI skips and zero failures, upgrading the switch-thumb change from pending CI to executed hosted validation. Execution for this layout update follows publication.


### Regular classic-label line blocks match captured Windows metrics — November 7

Reviewed the current native Windows captures from run42367678432, not just requested font-family strings. Dashboard legend/History/hint labels measure13-point classic Segoe UI in18-point rectangles; the16-point tagline measures22. Account Other Alerts/Connection descriptions measure13/18; global update status13/18 and version16/22. The649-point-wide retention description is two classic13-point lines in35 points. SwiftUI natural classic text rounds individual13/16-point lines to17/21, leaving one-point gaps even though the correct5.71 font assets are present. Native Variable dialog text and the measured Semibold fallback are separate policies.

Generalized the already-verified fractional tooltip line-box/renderer into referenceClassicLineMetrics, retaining full unconstrained text shaping, hhea baseline/advance and whole-block upward rounding. ReferenceTooltipText reuses it without changing tooltip rendering. Applied it to classic settings descriptions, account connection explanation, update version/status, dashboard tagline, regular quota-remaining labels, timeline legend/History/hint/status text. Semibold usage/countdown/heading boxes and native Variable controls are unchanged; unmeasured control/canvas typography is not signed off by this change.

Canonical app and native test-bundle builds passed. Added two hosted regressions: independent captured13/18,16/22 and649-wide13/35 labels, plus16-point1/2/4/12-line rendering with all ink groups and final descenders. A standalone executable compiled production typography/shared line renderer and the exact production help-component source: those captured bounds pass;16-point multiline heights22/43/86/256 and all1/2/4/12 line groups pass with explicit return code0. Existing short/help regression sizes remain278x57 and314x109. Prior history/tooltip multiline tests continue to cover the shared13-point path; full hosted execution follows publication.

Fresh isolated native compact captures classic-label-dashboard-mac.jpg, classic-label-quota-rows-mac.jpg and classic-label-account-footer-mac.jpg were inspected. Regular labels/descriptions remain complete and the two-quota card remains approximately288 points. Other Alerts and Connection each gain their missing one-point line height; card borders shift consistently with the extra lines. The corrected footer button borders remain at Retina970/1074 (logical485/537), preserving the independent native Windows positions. Exact glyph rasterization, unreviewed control variants and physical-pointer/frame-pacing acceptance remain open. No real setting or credential was changed. Previous layout-update run42368661206 at eb47019 completed successfully with166 hosted tests, two installed-CLI skips and zero failures.


### Quiet-hours text roles, target width and summary line — November 7

Added a bounded middle-panel capture requiring both visible native time buttons and duration summary. Windows run42369557174 at3382e87 passed. UIA independently reports Quiet Hours Start/End as80x32 buttons at x475/x670,y460; the classic Segoe16 summary is649x22 at x190,y558. Source QuietHoursRange confirms a94-point track plus4-point gap before that summary, giving120 points total, and106-point positioning slots around80-point buttons. The older Mac used106-point interactive labels and a21-point summary, yielding119 points. Native screenshot glyph bounds are42 pixels wide for12AM and35 for8AM at the runner's1x scale.

Source review distinguishes native MAUI time Buttons (FontSize16 with no family override), the explicit classic Label summary and GraphicsView ticks. The pinned MAUI10.0.120 framework source uses XamlAutoFontFamily for a default Windows graphics font (dotnet/maui tag10.0.120, FontExtensions.cs and PlatformCanvas.cs). Microsoft documents Segoe UI Variable as the default XAML common-control typeface (https://learn.microsoft.com/en-gb/windows/apps/design/signature-experiences/typography). That is a source/default inference, not a physical-font resolution result from the button's UIA attributes. Existing bundled native Text16 rendering independently matches the captured42/35-pixel time-label ink widths; the classic family differs for12AM. Canvas tick typography remains separately unverified and was not changed based on that inference.

Mac time handles now use native Text16 button labels with80x32 targets while retaining the source's106-point positioning/clamping and overlap rule. The summary uses the measured22-point classic line. Existing Mac accessibility increment/decrement actions are retained; the native accessibility tree exposes these handles as adjustable elements, rather than claiming identical Windows UIA roles. The XCTest handle selectors remain role-independent and now assert80x32 frames when native automation is available.

Canonical app and native test-bundle builds passed. Added a hosted production-control regression for649x120. A standalone executable compiled the exact production QuietHoursControl source, typography and extracted production colors: full control649x120 and time-label inkx303–344/502–536 (42/35 pixels) pass with explicit return code0. Actual component render quiet-control-measured-metrics.png and isolated native capture quiet-control-native-after.jpg were inspected. CUA verified clicking Start then Right gives1AM/end8AM/7hours; Left restores12AM. Clicking End then Right gives12AM/end9AM/9hours; Left restores8AM. Turning Quiet Hours off exposes both handles disabled; invoking the exposed Start Increment leaves both times unchanged. Re-enabling retains12AM/8AM. All edits were in isolated demo storage; no real settings were changed. The actual keyboard/focus and disabled paths are verified, while new native XCTest frame assertions remain unexecuted under the macOS authentication gate. Physical drag smoothness, hover states and full raster acceptance remain open.

Prior typography run42369241747 at b6b90a6 completed successfully with168 hosted tests, two installed-CLI skips and zero failures; both new captured-label and multiline/descender tests explicitly passed. This quiet-hours update's hosted execution follows publication.


### Theme-dependent settings controls — November 7

The supplied sounds/quiet-hours gallery uses dark native controls inside the fixed dark panels. Earlier Windows runner captures used light native controls; their white-thumb evidence therefore did not establish dark-gallery parity. Windows run42370975807 at ee38ee1 explicitly records AppsUseLightTheme=0 and appTheme=Dark. Its enabled switch and selected-radio centers are black, slider outer thumb is #454545, and unselected radio fill over #1C1E24 is RGB25/27/32. Prior light run42369557174 remains valid light-theme evidence: white centers/slider outer thumb and radio fill RGB27/29/35. Geometry and typography evidence from that run remains useful. This supersedes the white-only correction in0fabe0f.

Shared settings switches, sound radio choices and percentage sliders now select these captured colors by color scheme. The explicit timeline switch-thumb override remains #D1BEFF. Sound choices also retain the independently captured120x32 minimum target. Ownership, persistence, exclusive selection and switch accessibility are unchanged. Off-switch, hover, pressed and disabled palettes are not signed off by these normal-state samples.

Canonical build and test-bundle build passed. A standalone check compiled the production control components and typography, rendered both schemes and compared raw eight-bit sRGB pixels with the independent native samples: all switch, radio, slider and explicit-override samples passed, as did both120x32 sound targets; explicit process return0. The regression uses raw bitmap getPixel samples because calibrated NSColor conversion changes otherwise correct source pixels. Hosted regressions were added; their execution follows publication. Local gated XCTest execution was not restarted.

The isolated native demo capture dark-controls-native-mac.jpg visibly agrees with black enabled knobs/radio center and dark-grey slider outer thumb. Native interaction verified selecting Classic Chimes deselects Duck Sounds, selecting Duck Sounds restores exclusivity, and Notification Sounds switches off then on. All changes used isolated demo storage. The normal connected app was restored with script/build_and_run.sh --verify; live AX again shows the existing Devin/Copilot service-message icons. Real settings and credentials were not edited. Full-gallery raster, physical pointer/drag and unmeasured state acceptance remain open.


### Off-switch palette and disabled time labels — November 7

Windows run42373113228 at31e0638 passed the extended isolated probe. Native TogglePattern reports Quiet Hours Off, both80x32 time targets become disabled, and toggling restores On. The off screenshot independently gives thumb RGB203/203/204, track25/27/32 and border151/152/154 over the fixed card. The native disabled range retains one half-opacity fade; its start-time ink peaks135/135/140. Microsoft ToggleSwitch resources independently map off fill/stroke to ControlAltFillColorSecondary/ControlStrongStrokeColorDefault and knob to TextFillColorSecondary.

Corrected shared off switches from the fixed lavender/control palette to theme-specific native brushes and an inset one-point border. Dark values are captured; light off brushes follow the native resource definitions but do not yet have a separate light off-state capture. Existing explicit thumb overrides remain intact. Quiet Hours already applied the correct whole-range fade at its SettingsView call site. Native comparison found that macOS PlainButtonStyle also faded the disabled time labels, producing approximately87/88/93 rather than135/135/140. A narrow label-only ButtonStyle now avoids that extra fade while retaining Button disabled semantics and keyboard ownership. An attempted duplicate whole-range fade was caught in the native check and removed before publication.

Canonical build passed. A standalone executable compiled the production components and rendered all prior on-state dark/light samples plus the dark off switch and enabled/disabled quiet-hours samples. All matched native capture values within one8-bit step; time ink242/241/245 enabled and135/135/141 disabled, explicit return0. Added hosted coverage for disabled time-label ink and extended captured-control samples. Local authentication-gated XCTest execution was not restarted.

Final isolated native capture quiet-hours-off-native-mac.jpg was inspected after removing the duplicate fade. Both time handles expose disabled state, an advertised Increment leaves12AM/8AM unchanged, re-enabling preserves both times, and clicking Start/Right produces1AM/8AM/7hours; Left restores12AM/8AM/8hours. The normal app was restored through script/build_and_run.sh --verify. No real setting or credential was edited. Hover/pressed states, light off-state capture and full-gallery raster acceptance remain open. Prior production run42372734303 at45a59b0 completed successfully with171 hosted tests, two installed-CLI skips, zero failures and preview publication; both then-new control tests explicitly passed.
