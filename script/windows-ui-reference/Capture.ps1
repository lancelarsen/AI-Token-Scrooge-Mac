param(
    [Parameter(Mandatory)][string]$Release,
    [Parameter(Mandatory)][string]$Output
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Output | Out-Null
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms
# Resolve the installed classic faces independently of UIA's requested fallback
# strings. Preserve the actual files so the Mac comparison uses the same version.
$fontRows = @()
foreach ($name in @('Segoe UI', 'Segoe UI Semibold')) {
    $typeface = [System.Windows.Media.Typeface]::new($name)
    $glyph = $null
    if (-not $typeface.TryGetGlyphTypeface([ref]$glyph)) { throw "Could not resolve reference font: $name" }
    $fontPath = $glyph.FontUri.LocalPath
    $file = 'font-' + [System.IO.Path]::GetFileName($fontPath)
    Copy-Item -LiteralPath $fontPath -Destination (Join-Path $Output $file)
    $fontRows += [ordered]@{ requestedFamily = $name; file = $file;
        sha256 = (Get-FileHash -LiteralPath $fontPath -Algorithm SHA256).Hash;
        familyLineSpacing = $typeface.FontFamily.LineSpacing; baseline = $glyph.Baseline }
}
$fontRows | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'resolved-fonts.json')
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text;
public static class ReferenceWindowNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle, out Rect rect);
    delegate bool WindowCallback(IntPtr handle, IntPtr argument);
    [DllImport("user32.dll")] static extern bool EnumWindows(WindowCallback callback, IntPtr argument);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr handle, out uint processId);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr handle);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr handle, StringBuilder text, int count);
    public static IntPtr FindReferenceWindow(int processId) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr handle, IntPtr argument) {
            uint owner;
            Rect rect;
            GetWindowThreadProcessId(handle, out owner);
            if (owner == processId && IsWindowVisible(handle) && GetWindowRect(handle, out rect)
                && rect.Right - rect.Left >= 600 && rect.Bottom - rect.Top >= 400) {
                found = handle; return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }
    public static string[] OwnedWindowTitles(int processId) {
        var titles = new List<string>();
        EnumWindows(delegate(IntPtr handle, IntPtr argument) {
            uint owner;
            GetWindowThreadProcessId(handle, out owner);
            if (owner == processId) {
                var title = new StringBuilder(512);
                GetWindowText(handle, title, title.Capacity);
                titles.Add(title.ToString());
            }
            return true;
        }, IntPtr.Zero);
        return titles.ToArray();
    }
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle, int command);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool repaint);
    [StructLayout(LayoutKind.Sequential)]
    struct MouseInput { public int X, Y; public uint Data, Flags, Time; public IntPtr Extra; }
    [StructLayout(LayoutKind.Sequential)]
    struct Input { public uint Type; public MouseInput Mouse; }
    [DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
    [DllImport("user32.dll", SetLastError = true)]
    static extern uint SendInput(uint count, Input[] inputs, int size);
    public static void MovePointer(int x, int y) {
        int left = GetSystemMetrics(76), top = GetSystemMetrics(77);
        int width = GetSystemMetrics(78), height = GetSystemMetrics(79);
        if (width <= 1 || height <= 1) throw new InvalidOperationException("No virtual input desktop.");
        var input = new Input { Mouse = new MouseInput {
            X = (int)Math.Round((x - left) * 65535.0 / (width - 1)),
            Y = (int)Math.Round((y - top) * 65535.0 / (height - 1)),
            Flags = 0xC001 // MOVE | ABSOLUTE | VIRTUALDESK
        }};
        if (SendInput(1, new[] { input }, Marshal.SizeOf(typeof(Input))) != 1)
            throw new InvalidOperationException("Pointer input was not accepted: " + Marshal.GetLastWin32Error());
    }
}
'@
[ReferenceWindowNative]::SetProcessDPIAware() | Out-Null
function Save-ReferenceView {
    param([string]$Name, [System.Windows.Automation.AutomationElement]$Root, [IntPtr]$Handle, [string]$Output)
    $elements = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $rows = @()
    foreach ($element in $elements) {
        $current = $element.Current
        $bounds = $current.BoundingRectangle
        if ($bounds.IsEmpty) { continue }
        $row = [ordered]@{ name = $current.Name; type = $current.ControlType.ProgrammaticName;
            x = $bounds.X; y = $bounds.Y; width = $bounds.Width; height = $bounds.Height;
            enabled = $current.IsEnabled; offscreen = $current.IsOffscreen }
        $toggle = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$toggle)) {
            $row['toggleState'] = $toggle.Current.ToggleState.ToString()
        }
        $rangeValue = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.RangeValuePattern]::Pattern, [ref]$rangeValue)) {
            $row['rangeValue'] = $rangeValue.Current.Value
            $row['rangeMinimum'] = $rangeValue.Current.Minimum
            $row['rangeMaximum'] = $rangeValue.Current.Maximum
        }
        $pattern = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern) -and $null -ne $pattern) {
            $range = $pattern.DocumentRange
            foreach ($attribute in @('FontName', 'FontSize', 'FontWeight') | Where-Object { $null -ne $range }) {
                $field = [System.Windows.Automation.TextPattern].GetField($attribute + 'Attribute')
                $value = $range.GetAttributeValue($field.GetValue($null))
                if ($value -is [string] -or $value -is [double] -or $value -is [int]) { $row[$attribute] = $value }
            }
        }
        $scroll = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$scroll)) {
            $row['verticalScrollable'] = $scroll.Current.VerticallyScrollable
            $row['horizontalScrollable'] = $scroll.Current.HorizontallyScrollable
            $row['verticalScrollPercent'] = $scroll.Current.VerticalScrollPercent
            $row['verticalViewSize'] = $scroll.Current.VerticalViewSize
        }
        $rows += $row
    }
    $rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $Output ($Name + '-elements.json'))
    $pointer = [System.Windows.Forms.Cursor]::Position
    [ordered]@{ x = $pointer.X; y = $pointer.Y } | ConvertTo-Json |
        Set-Content -Encoding UTF8 (Join-Path $Output ($Name + '-pointer.json'))
    $rect = New-Object ReferenceWindowNative+Rect
    if (-not [ReferenceWindowNative]::GetWindowRect($handle, [ref]$rect)) { throw 'Could not read native window bounds.' }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -lt 600 -or $height -lt 400) { throw 'Unexpected reference window dimensions.' }
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
        $bitmap.Save((Join-Path $Output ($Name + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
        $colors = New-Object 'System.Collections.Generic.HashSet[int]'
        for ($x = 0; $x -lt $width; $x += 17) {
            for ($y = 0; $y -lt $height; $y += 17) { [void]$colors.Add($bitmap.GetPixel($x, $y).ToArgb()) }
        }
        if ($colors.Count -lt 8) { throw 'The runner returned a blank/unrendered desktop capture.' }
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
    return [pscustomobject]@{ Rows = $rows; Width = $width; Height = $height }
}

function Invoke-ReferenceAction {
    param([string]$Name, [System.Windows.Automation.AutomationElement]$Root, [double]$MinimumHeight = 40)
    $condition = [System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, $Name),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button))
    $targets = @($Root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition) | Where-Object {
        -not $_.Current.IsOffscreen -and $_.Current.BoundingRectangle.Height -ge $MinimumHeight
    })
    if ($targets.Count -ne 1) { throw "Reference action not uniquely visible: $Name" }
    $invoke = $null
    if (-not $targets[0].TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$invoke)) {
        throw "Reference action did not expose Invoke: $Name"
    }
    $invoke.Invoke()
}

$data = Join-Path $Output 'isolated-demo-state'
$app = $null
try {
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = Join-Path $Release 'AIResetRadar.App.exe'
    $start.WorkingDirectory = $Release
    $start.Arguments = '--demo --compact --data-dir "' + $data + '"'
    $start.UseShellExecute = $false
    foreach ($key in @($start.EnvironmentVariables.Keys)) {
        if ($key -match '^(GH_|GITHUB_|OPENAI_|CODEX_|ANTHROPIC_|CLAUDE_)') { $start.EnvironmentVariables.Remove($key) }
    }
    # Mirror UpdateInstallation.Launch so the portable app does not hand off
    # to its launcher and exit before the retained process can be observed.
    $start.EnvironmentVariables['SCROOGE_LAUNCHED_DIRECTORY'] = [System.IO.Path]::GetFullPath($Release)
    $app = New-Object System.Diagnostics.Process
    $app.StartInfo = $start
    if (-not $app.Start()) { throw 'Reference process did not start.' }
    $deadline = [DateTime]::UtcNow.AddSeconds(40)
    [IntPtr]$handle = [IntPtr]::Zero
    while ($handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline) {
        if ($app.HasExited) { throw "Reference app exited before showing a window (exit $($app.ExitCode))." }
        $handle = [ReferenceWindowNative]::FindReferenceWindow($app.Id)
        if ($handle -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 500 }
    }
    if ($handle -eq [IntPtr]::Zero) {
        [ordered]@{ userInteractive = [Environment]::UserInteractive; appSession = $app.SessionId;
            driverSession = [Diagnostics.Process]::GetCurrentProcess().SessionId;
            ownedWindowTitles = @([ReferenceWindowNative]::OwnedWindowTitles($app.Id)) } |
            ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'startup.json')
        throw 'No visible native reference window became available; see startup.json.'
    }
    [ReferenceWindowNative]::ShowWindow($handle, 9) | Out-Null
    [ReferenceWindowNative]::SetForegroundWindow($handle) | Out-Null
    Start-Sleep -Seconds 3
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($handle)
    if ($root.Current.ProcessId -ne $app.Id) { throw 'Reference window belongs to a different process.' }
    $dashboard = Save-ReferenceView -Name 'dashboard' -Root $root -Handle $handle -Output $Output
    $rows = $dashboard.Rows
    $width = $dashboard.Width
    $height = $dashboard.Height
    if (-not ($rows | Where-Object { $_.name -match 'Reset Horizon|Reset horizon' })) { throw 'The captured window did not expose the demo dashboard.' }
    $appTheme = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
    [ordered]@{ release = 'v2026.11.6.006'; source = 'eb042cb1fd9f44e896c2126738121ae8c80d80b0';
        appsUseLightTheme = $appTheme; appTheme = $(if ($appTheme -eq 0) { 'Dark' } elseif ($appTheme -eq 1) { 'Light' } else { 'System default' });
        width = $width; height = $height; elements = $rows.Count; session = $app.SessionId;
        scope = 'Isolated demo rendering only; no live provider or authentication verification.' } |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'capture.json')
    $historyCondition = [System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, 'Usage History'),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button))
    $historyTarget = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $historyCondition)
    if ($null -eq $historyTarget) { throw 'The usage-history keyboard target was not exposed.' }
    $historyTarget.SetFocus()
    [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
    Start-Sleep -Seconds 1
    $keyboard = Save-ReferenceView -Name 'history-keyboard' -Root $root -Handle $handle -Output $Output
    if (-not ($keyboard.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -match 'Weekly.*% Used' })) {
        throw 'Keyboard history inspection did not expose a sample readout.'
    }
    [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
    Start-Sleep -Seconds 1
    # Exercise the application's actual immediate-hover tooltips in the fresh
    # runner session. Locate targets through UIA bounds rather than fixed pixels.
    $away = [System.Drawing.Point]::new([int]($root.Current.BoundingRectangle.X + 20), [int]($root.Current.BoundingRectangle.Y + 16))
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    $plainTargets = @($rows | Where-Object {
        $_.type -eq 'ControlType.Button' -and $_.name -like 'Hide OpenAI / Personal*' -and -not $_.offscreen
    })
    if ($plainTargets.Count -ne 1) { throw 'The selector help target was not uniquely visible.' }
    $plainTarget = $plainTargets[0]
    [ReferenceWindowNative]::MovePointer([int]($plainTarget.x + $plainTarget.width / 2), [int]($plainTarget.y + $plainTarget.height / 2))
    Start-Sleep -Seconds 1
    $plain = Save-ReferenceView -Name 'selector-tooltip' -Root $root -Handle $handle -Output $Output
    if (-not ($plain.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -match 'Show or Hide History' })) {
        throw 'Selector pointer entry did not expose its help tooltip.'
    }
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    Start-Sleep -Seconds 1
    $originalRect = New-Object ReferenceWindowNative+Rect
    if (-not [ReferenceWindowNative]::GetWindowRect($handle, [ref]$originalRect)) { throw 'Cannot retain the reference window bounds.' }
    if (-not [ReferenceWindowNative]::MoveWindow($handle, 0, $originalRect.Top,
        $originalRect.Right - $originalRect.Left, $originalRect.Bottom - $originalRect.Top, $true)) {
        throw 'Cannot place the reference window at the screen edge.'
    }
    Start-Sleep -Seconds 1
    $edgeDashboard = Save-ReferenceView -Name 'tooltip-edge-targets' -Root $root -Handle $handle -Output $Output
    $edgeTargets = @($edgeDashboard.Rows | Where-Object {
        $_.type -eq 'ControlType.Button' -and $_.name -like 'Hide OpenAI / Personal*' -and -not $_.offscreen
    })
    if ($edgeTargets.Count -ne 1) { throw 'The screen-edge selector target was not uniquely visible.' }
    $edgeTarget = $edgeTargets[0]
    [ReferenceWindowNative]::MovePointer([int]($edgeTarget.x + $edgeTarget.width / 2), [int]($edgeTarget.y + $edgeTarget.height / 2))
    Start-Sleep -Seconds 1
    $edgeTip = Save-ReferenceView -Name 'selector-tooltip-screen-edge' -Root $root -Handle $handle -Output $Output
    if (-not ($edgeTip.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -match 'Show or Hide History' })) {
        throw 'Screen-edge pointer entry did not expose its help tooltip.'
    }
    [ReferenceWindowNative]::MovePointer(20, $originalRect.Top + 16)
    if (-not [ReferenceWindowNative]::MoveWindow($handle, $originalRect.Left, $originalRect.Top,
        $originalRect.Right - $originalRect.Left, $originalRect.Bottom - $originalRect.Top, $true)) {
        throw 'Cannot restore the reference window bounds.'
    }
    Start-Sleep -Seconds 1
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    $resetTargets = @($rows | Where-Object {
        $_.type -eq 'ControlType.Button' -and $_.name.StartsWith('OpenAI / Personal') -and
        $_.name.Contains('Weekly') -and $_.name.Contains('Quota Refresh:') -and -not $_.offscreen
    })
    if ($resetTargets.Count -ne 1) { throw 'The reset tooltip target was not uniquely visible.' }
    $resetTarget = $resetTargets[0]
    [ReferenceWindowNative]::MovePointer([int]($resetTarget.x + $resetTarget.width / 2), [int]($resetTarget.y + $resetTarget.height / 2))
    Start-Sleep -Seconds 1
    $resetTip = Save-ReferenceView -Name 'reset-tooltip' -Root $root -Handle $handle -Output $Output
    if (-not ($resetTip.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -match 'Quota Refresh' })) {
        throw 'Reset pointer entry did not expose its styled tooltip.'
    }
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    Start-Sleep -Seconds 1
    # Measure the earned-reset dialog separately: its mixed-weight first line
    # and four short paragraphs expose line-height differences hidden by the
    # longer quota popup. Use the real visible expiry action, never a coordinate.
    $expiry = @($rows | Where-Object {
        $_.type -eq 'ControlType.Button' -and $_.name.StartsWith('Earned Reset Expires') -and -not $_.offscreen
    })
    if ($expiry.Count -ne 1) { throw 'The expected earned-reset expiry action was not uniquely visible.' }
    Invoke-ReferenceAction -Name $expiry[0].name -Root $root
    Start-Sleep -Seconds 2
    $resets = Save-ReferenceView -Name 'earned-resets' -Root $root -Handle $handle -Output $Output
    if (-not ($resets.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -eq 'Available resets' }) -or
        -not ($resets.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -match '2 reported available' })) {
        throw 'The earned-reset popup title and reported count were not exposed.'
    }
    Invoke-ReferenceAction -Name 'Close' -Root $root
    Start-Sleep -Seconds 1
    $scrollTarget = $null
    foreach ($element in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        $pattern = $null
        if ($element.Current.BoundingRectangle.Width -ge 600 -and
            $element.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$pattern) -and
            $pattern.Current.VerticallyScrollable -and -not $pattern.Current.HorizontallyScrollable) {
            $scrollTarget = $pattern; break
        }
    }
    if ($null -eq $scrollTarget) { throw 'No vertical dashboard scroll provider was exposed.' }
    $scrollTarget.SetScrollPercent([System.Windows.Automation.ScrollPattern]::NoScroll, 40)
    Start-Sleep -Seconds 2
    $accounts = Save-ReferenceView -Name 'account-rows' -Root $root -Handle $handle -Output $Output
    $button = @($accounts.Rows | Where-Object { $_.type -eq 'ControlType.Button' -and $_.name -match '38%' })
    if ($button.Count -ne 1) { throw 'The expected demo quota detail action was not uniquely visible.' }
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $button[0].name)
    $target = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
    $invoke = $null
    if ($null -eq $target -or -not $target.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$invoke)) {
        throw 'Demo quota action did not expose Invoke.'
    }
    $invoke.Invoke()
    Start-Sleep -Seconds 2
    $details = Save-ReferenceView -Name 'usage-details' -Root $root -Handle $handle -Output $Output
    if (-not ($details.Rows | Where-Object { $_.name -match 'Last successful fetch' })) {
        throw 'The usage popup body was not exposed after invoking the quota.'
    }
    Invoke-ReferenceAction -Name 'Close' -Root $root
    Start-Sleep -Seconds 1
    Invoke-ReferenceAction -Name ('Settings for OpenAI / Personal ' + [char]0x00B7 + ' Plus') -Root $root
    Start-Sleep -Seconds 2
    $settings = Save-ReferenceView -Name 'account-settings' -Root $root -Handle $handle -Output $Output
    if (-not ($settings.Rows | Where-Object { $_.name -eq 'Account Name' }) -or
        -not ($settings.Rows | Where-Object { $_.name -eq '2 Available' })) {
        throw 'The account settings form and reserve count were not exposed.'
    }
    # Measure the long ordinary tooltip independently of the short selector.
    # The gallery predates later source/typography changes; capture current
    # wrapping and the surface limit rather than assuming the old dimensions.
    $polling = @($settings.Rows | Where-Object {
        $_.type -eq 'ControlType.Text' -and $_.name -like 'Polling Interval: *' -and -not $_.offscreen
    })
    if ($polling.Count -ne 1) { throw 'Polling tooltip label was not uniquely visible.' }
    [ReferenceWindowNative]::MovePointer([int]($polling[0].x + $polling[0].width / 2), [int]($polling[0].y + $polling[0].height / 2))
    Start-Sleep -Seconds 2
    $pollingTip = Save-ReferenceView -Name 'polling-tooltip' -Root $root -Handle $handle -Output $Output
    if (-not ($pollingTip.Rows | Where-Object {
        $_.type -eq 'ControlType.ToolTip' -and $_.name -like 'How often Scrooge automatically checks*'
    })) { throw 'Polling pointer entry did not expose its long help tooltip.' }
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    # Match the Mac reference host's logical size before comparing panels.
    # Native window chrome adds to the outer rectangle; use exported host-pane
    # bounds to calculate that delta instead of guessing the frame thickness.
    $hostPane = @($settings.Rows | Where-Object { $_.type -eq 'ControlType.Pane' -and $_.height -ge 400 } |
        Sort-Object -Property { [double]$_['width'] * [double]$_['height'] } -Descending)[0]
    if ($hostPane.width -lt 600 -or $hostPane.height -lt 400) { throw 'Reference host pane is unavailable.' }
    $matchedRect = New-Object ReferenceWindowNative+Rect
    if (-not [ReferenceWindowNative]::GetWindowRect($handle, [ref]$matchedRect)) { throw 'Cannot retain the panel comparison window bounds.' }
    if (-not [ReferenceWindowNative]::MoveWindow($handle, $matchedRect.Left, $matchedRect.Top,
        [int]($matchedRect.Right - $matchedRect.Left + 789 - $hostPane.width),
        [int]($matchedRect.Bottom - $matchedRect.Top + 694 - $hostPane.height), $true)) {
        throw 'Cannot size the reference host for panel comparison.'
    }
    Start-Sleep -Seconds 2
    $matched = Save-ReferenceView -Name 'account-settings-matched-size' -Root $root -Handle $handle -Output $Output
    Invoke-ReferenceAction -Name 'Add Custom Line Color' -Root $root -MinimumHeight 32
    Start-Sleep -Seconds 1
    $colorPicker = Save-ReferenceView -Name 'custom-color-picker' -Root $root -Handle $handle -Output $Output
    if (-not ($colorPicker.Rows | Where-Object { $_.type -eq 'ControlType.Button' -and $_.name -eq 'Add Color' -and -not $_.offscreen })) {
        throw 'Custom color picker did not expose its Add Color action.'
    }
    # Only inspect both ends of the native picker; Cancel leaves the palette
    # unchanged. Its bounded dialog scroll is narrower than the settings form.
    $colorScrolls = @()
    foreach ($element in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        $scroll = $null
        $bounds = $element.Current.BoundingRectangle
        if (-not $element.Current.IsOffscreen -and $bounds.Width -ge 200 -and $bounds.Width -lt 600 -and
            $element.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$scroll) -and
            $scroll.Current.VerticallyScrollable) {
            $colorScrolls += [pscustomobject]@{ Pattern = $scroll; Height = $bounds.Height }
        }
    }
    if ($colorScrolls.Count -eq 0) { throw 'Custom color picker did not expose its bounded scroll area.' }
    $colorScroll = $colorScrolls | Sort-Object -Property Height -Descending | Select-Object -First 1
    for ($settle = 0; $settle -lt 4; $settle++) {
        $colorScroll.Pattern.SetScrollPercent([System.Windows.Automation.ScrollPattern]::NoScroll, 100)
        Start-Sleep -Milliseconds 500
    }
    $colorFields = Save-ReferenceView -Name 'custom-color-picker-fields' -Root $root -Handle $handle -Output $Output
    $hexField = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, 'RGB hex'))
    if ($null -eq $hexField) { throw 'Native color hex field was not exposed.' }
    $hexField.SetFocus()
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    Start-Sleep -Milliseconds 500
    $hexFocused = Save-ReferenceView -Name 'custom-color-picker-hex-focused' -Root $root -Handle $handle -Output $Output
    $colorModel = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, 'Color model'))
    if ($null -eq $colorModel) { throw 'Native color-model selector was not exposed.' }
    $colorModel.SetFocus()
    Start-Sleep -Milliseconds 500
    $modelFocused = Save-ReferenceView -Name 'custom-color-picker-model-focused' -Root $root -Handle $handle -Output $Output
    $brightnessSlider = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, 'Value (Brightness)'))
    $brightnessRange = $null
    if ($null -eq $brightnessSlider -or -not $brightnessSlider.TryGetCurrentPattern(
        [System.Windows.Automation.RangeValuePattern]::Pattern, [ref]$brightnessRange)) {
        throw 'Native brightness slider did not expose its range.'
    }
    $brightnessSlider.SetFocus()
    $keyTrace = @()
    foreach ($step in @(
        @{ Key = '{HOME}'; Name = 'home' }, @{ Key = '{END}'; Name = 'end' },
        @{ Key = '{PGDN}'; Name = 'page-down' }, @{ Key = '{PGUP}'; Name = 'page-up' })) {
        [System.Windows.Forms.SendKeys]::SendWait($step.Key)
        Start-Sleep -Milliseconds 300
        $keyTrace += [ordered]@{ key = $step.Name; value = $brightnessRange.Current.Value;
            minimum = $brightnessRange.Current.Minimum; maximum = $brightnessRange.Current.Maximum }
    }
    $keyTrace | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'color-brightness-key-trace.json')
    if ($keyTrace[0]['value'] -ne $brightnessRange.Current.Minimum -or $keyTrace[1]['value'] -ne $brightnessRange.Current.Maximum) {
        throw 'Native brightness Home/End did not reach the captured range bounds.'
    }
    $redField = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, 'Red'))
    $redValue = $null; $hexValue = $null
    if ($null -eq $redField -or -not $redField.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$redValue) -or
        -not $hexField.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$hexValue)) {
        throw 'Native color input values were not exposed.'
    }
    $inputTrace = @()
    function Record-ColorInput([string]$Step) {
        [ordered]@{ step = $Step; red = $redValue.Current.Value; hex = $hexValue.Current.Value;
            brightness = $brightnessRange.Current.Value }
    }
    $inputTrace += Record-ColorInput 'initial'
    $redField.SetFocus(); $redValue.SetValue('999'); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-out-of-range'
    $hexField.SetFocus(); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-after-blur'
    $redField.SetFocus(); $redValue.SetValue(''); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-cleared'
    $hexField.SetFocus(); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-clear-after-blur'
    $hexValue.SetValue(''); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'hex-cleared'
    $redField.SetFocus(); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'hex-clear-after-blur'
    $hexField.SetFocus(); $hexValue.SetValue($inputTrace[0]['hex']); Start-Sleep -Milliseconds 300
    $redField.SetFocus(); $redValue.SetValue('12'); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-valid-intermediate'
    $redValue.SetValue('999'); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-invalid-after-valid'
    $hexField.SetFocus(); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'red-invalid-after-valid-blurred'
    $hexValue.SetValue('#12'); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'short-hex'
    $redField.SetFocus(); Start-Sleep -Milliseconds 300
    $inputTrace += Record-ColorInput 'short-hex-after-blur'
    $inputTrace | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'color-input-draft-trace.json')
    if ($inputTrace[2]['red'] -ne $inputTrace[0]['red'] -or $inputTrace[4]['red'] -ne $inputTrace[0]['red'] -or
        $inputTrace[6]['hex'] -ne '#000000' -or $inputTrace[6]['brightness'] -ne 0 -or
        $inputTrace[9]['red'] -ne $inputTrace[0]['red'] -or $inputTrace[11]['hex'] -ne '#000012') {
        throw 'Native color input draft trace did not match the captured blur and short-Hex behavior.'
    }
    Invoke-ReferenceAction -Name 'Cancel' -Root $root
    Start-Sleep -Seconds 1
    function Scroll-ReferencePanel {
        param([double]$Percent)
        $candidates = @()
        foreach ($element in $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
            $pattern = $null
            if (-not $element.Current.IsOffscreen -and $element.Current.BoundingRectangle.Width -ge 600 -and
                $element.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$pattern) -and
                $pattern.Current.VerticallyScrollable -and -not $pattern.Current.HorizontallyScrollable) {
                $candidates += [pscustomobject]@{ Pattern = $pattern; Height = $element.Current.BoundingRectangle.Height }
            }
        }
        if ($candidates.Count -eq 0) { throw 'No visible panel scroll provider was exposed.' }
        $selected = $candidates | Sort-Object -Property Height -Descending | Select-Object -First 1
        # MAUI updates the native extent after newly exposed content is laid
        # out. Reapply the requested endpoint after those bounded layout turns.
        for ($settle = 0; $settle -lt 4; $settle++) {
            $selected.Pattern.SetScrollPercent([System.Windows.Automation.ScrollPattern]::NoScroll, $Percent)
            Start-Sleep -Milliseconds 700
        }
    }
    Scroll-ReferencePanel -Percent 100
    $connection = Save-ReferenceView -Name 'account-connection-actions' -Root $root -Handle $handle -Output $Output
    foreach ($name in @('Sign In Again', 'Remove Account')) {
        $action = @($connection.Rows | Where-Object { $_.type -eq 'ControlType.Button' -and $_.name -eq $name -and -not $_.offscreen })
        if ($action.Count -ne 1 -or $action[0].enabled) { throw "Demo connection action not visible and disabled: $name" }
    }
    Invoke-ReferenceAction -Name 'Close' -Root $root
    Start-Sleep -Seconds 1
    Invoke-ReferenceAction -Name 'Settings' -Root $root
    Start-Sleep -Seconds 2
    $global = Save-ReferenceView -Name 'global-settings-matched-size' -Root $root -Handle $handle -Output $Output
    if (-not ($global.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -eq 'App Updates' })) {
        throw 'Global settings top was not exposed.'
    }
    # Cover the remaining settings cards at overlapping positions. Export all
    # text/control bounds with each image so comparisons can use card-relative
    # coordinates rather than assuming the same total platform scroll extent.
    foreach ($percent in @(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100)) {
        Scroll-ReferencePanel -Percent $percent
        $sweep = Save-ReferenceView -Name ('global-settings-sweep-' + $percent) -Root $root -Handle $handle -Output $Output
    }
    # Find the middle control by its exposed role/name rather than assuming
    # a fixed content offset; compact wrapping changes total scroll extent.
    $quietCaptured = $false
    foreach ($percent in @(20, 25, 30, 35, 40, 45, 50, 55)) {
        Scroll-ReferencePanel -Percent $percent
        $visibleElements = @($root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { -not $_.Current.IsOffscreen })
        $startTime = @($visibleElements | Where-Object { $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $_.Current.Name -like 'Quiet Hours Start Time:*' })
        $endTime = @($visibleElements | Where-Object { $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $_.Current.Name -like 'Quiet Hours End Time:*' })
        $summary = @($visibleElements | Where-Object { $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Text -and $_.Current.Name -match '^\d.*[0-9]+ hours' })
        if ($startTime.Count -eq 1 -and $endTime.Count -eq 1 -and $summary.Count -eq 1) {
            $quiet = Save-ReferenceView -Name 'global-settings-quiet-hours' -Root $root -Handle $handle -Output $Output
            $quietCaptured = $true; break
        }
    }
    if (-not $quietCaptured) { throw 'Quiet-hours time buttons and summary were not simultaneously exposed.' }
    # Capture the actual off palette and disabled time handles in the fresh demo.
    # A native ToggleSwitch exposes TogglePattern rather than InvokePattern.
    $quietSwitch = @($root.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) | Where-Object {
        $_.Current.Name -eq 'Enable Quiet Hours' -and -not $_.Current.IsOffscreen
    })
    if ($quietSwitch.Count -ne 1) { throw 'Quiet-hours switch was not uniquely visible.' }
    $quietToggle = $null
    if (-not $quietSwitch[0].TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$quietToggle)) {
        throw 'Quiet-hours switch did not expose TogglePattern.'
    }
    if ($quietToggle.Current.ToggleState -ne [System.Windows.Automation.ToggleState]::On) { throw 'Expected demo quiet hours to start enabled.' }
    $quietToggle.Toggle()
    [ReferenceWindowNative]::MovePointer($away.X, $away.Y)
    Start-Sleep -Seconds 1
    if ($quietToggle.Current.ToggleState -ne [System.Windows.Automation.ToggleState]::Off) { throw 'Quiet hours did not turn off.' }
    $quietOff = Save-ReferenceView -Name 'global-settings-quiet-hours-off' -Root $root -Handle $handle -Output $Output
    foreach ($timeName in @('Quiet Hours Start Time:*', 'Quiet Hours End Time:*')) {
        $disabledTime = @($quietOff.Rows | Where-Object { $_.name -like $timeName -and -not $_.offscreen })
        if ($disabledTime.Count -ne 1 -or $disabledTime[0].enabled) { throw "Expected disabled quiet-hours time target: $timeName" }
    }
    $quietToggle.Toggle()
    Start-Sleep -Milliseconds 500
    if ($quietToggle.Current.ToggleState -ne [System.Windows.Automation.ToggleState]::On) { throw 'Quiet hours did not restore.' }
    Scroll-ReferencePanel -Percent 100
    $footer = Save-ReferenceView -Name 'global-settings-footer' -Root $root -Handle $handle -Output $Output
    if (-not ($footer.Rows | Where-Object { $_.type -eq 'ControlType.Button' -and $_.name -eq 'Send Test Notification' -and -not $_.offscreen })) {
        throw 'Global settings footer was not exposed.'
    }
    Invoke-ReferenceAction -Name 'Close' -Root $root
    Start-Sleep -Seconds 1
    Scroll-ReferencePanel -Percent 40
    Invoke-ReferenceAction -Name 'Exit demo' -Root $root
    Start-Sleep -Seconds 2
    $empty = Save-ReferenceView -Name 'empty-dashboard' -Root $root -Handle $handle -Output $Output
    # These are untouched connection forms in fresh storage. Never invoke a
    # sign-in, submit credentials, or begin provider authorization in this probe.
    foreach ($provider in @('OpenAI Codex', 'GitHub Copilot', 'Claude', 'Devin')) {
        Invoke-ReferenceAction -Name 'Add account' -Root $root
        Start-Sleep -Seconds 1
        $chooser = Save-ReferenceView -Name 'provider-chooser' -Root $root -Handle $handle -Output $Output
        Invoke-ReferenceAction -Name $provider -Root $root
        Start-Sleep -Seconds 1
        $slug = $provider.ToLowerInvariant().Replace(' ', '-')
        $form = Save-ReferenceView -Name ('connect-' + $slug) -Root $root -Handle $handle -Output $Output
        if (-not ($form.Rows | Where-Object { $_.type -eq 'ControlType.Text' -and $_.name -eq ('Connect ' + $provider) })) {
            throw "Connection form heading not exposed: $provider"
        }
        if ($provider -eq 'GitHub Copilot') {
            Invoke-ReferenceAction -Name 'Use an access token instead' -Root $root
            Start-Sleep -Seconds 1
            $advanced = Save-ReferenceView -Name 'connect-github-advanced' -Root $root -Handle $handle -Output $Output
            if (-not ($advanced.Rows | Where-Object { $_.name -eq 'Use browser sign-in instead' })) {
                throw 'Advanced GitHub form did not appear.'
            }
        }
        Invoke-ReferenceAction -Name 'Cancel' -Root $root
        Start-Sleep -Seconds 1
    }

} catch {
    [ordered]@{ message = $_.Exception.Message; stack = $_.ScriptStackTrace;
        position = $_.InvocationInfo.PositionMessage } | ConvertTo-Json |
        Set-Content -Encoding UTF8 (Join-Path $Output 'failure.json')
    throw
} finally {
    if ($null -ne $app -and -not $app.HasExited) { $app.Kill(); $app.WaitForExit() }
    # Only screenshots/geometry leave this fresh runner, never its generated state.
    if (Test-Path -LiteralPath $data) { Remove-Item -LiteralPath $data -Recurse -Force }
}
