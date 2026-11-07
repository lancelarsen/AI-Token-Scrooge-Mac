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
        $pattern = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern)) {
            $range = $pattern.DocumentRange
            foreach ($attribute in @('FontName', 'FontSize', 'FontWeight')) {
                $field = [System.Windows.Automation.TextPattern].GetField($attribute + 'Attribute')
                $value = $range.GetAttributeValue($field.GetValue($null))
                if ($value -is [string] -or $value -is [double] -or $value -is [int]) { $row[$attribute] = $value }
            }
        }
        $scroll = $null
        if ($element.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$scroll)) {
            $row['verticalScrollable'] = $scroll.Current.VerticallyScrollable
            $row['horizontalScrollable'] = $scroll.Current.HorizontallyScrollable
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
    param([string]$Name, [System.Windows.Automation.AutomationElement]$Root)
    $condition = [System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, $Name),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button))
    $targets = @($Root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition) | Where-Object {
        -not $_.Current.IsOffscreen -and $_.Current.BoundingRectangle.Height -ge 40
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
    [ordered]@{ release = 'v2026.11.6.006'; source = 'eb042cb1fd9f44e896c2126738121ae8c80d80b0';
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
        $_.type -eq 'ControlType.Button' -and $_.name.StartsWith('Hide OpenAI / Personal') -and -not $_.offscreen
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

} finally {
    if ($null -ne $app -and -not $app.HasExited) { $app.Kill(); $app.WaitForExit() }
    # Only screenshots/geometry leave this fresh runner, never its generated state.
    if (Test-Path -LiteralPath $data) { Remove-Item -LiteralPath $data -Recurse -Force }
}
