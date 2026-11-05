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
