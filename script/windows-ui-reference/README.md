# Native Windows reference probe

This read-only comparison tool downloads Windows release `v2026.11.6.006` at source `eb042cb1fd9f44e896c2126738121ae8c80d80b0`, verifies the archive SHA-256, and launches it with fresh isolated demo data. The workflow has read-only repository permission. It exports a screenshot, UI Automation control bounds and available text attributes, then stops the app and removes generated state. It never signs in or checks a live provider.

Run **Windows UI reference** through GitHub Actions, or use:

```sh
gh workflow run windows-ui-reference.yml --ref main
gh run download RUN_ID --name windows-ui-reference --dir artifacts/windows-ui-reference
```

The native script requires Windows PowerShell, UI Automation, System.Drawing and a graphical Windows session. It mirrors `UpdateInstallation.Launch`'s application-directory environment marker and finds the visible full-size window by its retained process identity. A missing window, wrong process, absent dashboard or blank capture fails the job rather than establishing parity.

Outputs:

- `dashboard.png`: actual native window capture.
- `dashboard-elements.json`: element names, rectangles, enabled/offscreen states and available font attributes.
- `account-rows.png` / `account-rows-elements.json`: scrolled demo account rows and their measured controls.
- `usage-details.png` / `usage-details-elements.json`: first demo quota popup, opened through UI Automation.
- `capture.json`: pinned release/source and measured window dimensions.
- `startup.json`: session/window diagnostics if no visible window appears.
- `resolved-fonts.json` and `font-*.ttf`: installed classic Segoe UI faces resolved independently through WPF, with hashes and family metrics. This identifies installed files for comparison; it does not establish WinUI fallback resolution on its own.

The first successful run is [42335310777](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42335310777), harness source `2496f48`. The inspected output contains a populated native demo, 79 elements and 42 font-bearing elements in graphical session 2. Its window is 800×680 pixels, constrained by that runner's work area; it is not yet an equivalent-viewport replacement for the gallery's 789×694 compact image. Some captured outer pixels include the window's invisible frame margins.

UI Automation font-family strings can contain requested fallback lists. They are reported properties, not proof of the resolved physical font file. For example, the 32-point brand label has a 39-point element rectangle, the 26-point section label has a 32-point rectangle, and 14-point weekday labels have 17-point rectangles. The Mac's current bare Semibold Text measurements at those sizes are 43, 35 and 19 points respectively. Those differences merit targeted line-box investigation; this probe does not by itself prove which font or layout adjustment is correct.

Expanded run [42336148115](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42336148115), harness source `758cbd3`, also passed account-row scrolling and quota-popup invocation. Both screenshots were inspected. The compact OpenAI identity action spans 569×44 points, including blank space beside its content. The 20-point countdown text measures 24 points high; its 12-point date measures 16 points, with a three-point gap. The popup reports Segoe UI Variable, a 22-point title in a 30-point rectangle and 14-point body in 19-point rectangles. These properties supplement the older gallery; they do not prove the physical font selected or equivalent viewport geometry. Equivalent visible viewport sizing, font-baseline comparison and final surface acceptance remain open. Synthetic demo screenshots do not establish provider, notification, sleep/wake or distribution behavior.


Font-resolution run [42336843207](https://github.com/lancelarsen/AI-Token-Scrooge-Mac/actions/runs/42336843207) passed at harness `bd72383`. Both installed classic faces are version 5.71. Their files are now the Mac's `Resources/Fonts/SegoeUI.ttf` (SHA-256 `8134dbcd09e7b123c9a7f229d49cffbcb01352cc72ea5e1076b65d0dca9f73cd`) and `SegoeUI-Semibold.ttf` (`2d9b22d71f72de2823fee5d9c8bc1b0fc32b2577c4c27b9ec6abdbb8df0e1731`). Semibold's PostScript name is `SegoeUI-Semibold`. These replace older Mac versions 5.28/5.00. The regular and Semibold hhea metrics remain 2210 ascent / −514 descent at 2048 units per em, so the asset replacement is not a line-height fix. A local 20-point `2h 13m` Semibold Text changes from 69 to 66 points wide, while its 27-point natural Mac height remains unchanged. UI Automation family strings still do not prove WinUI's resolved font on their own.
