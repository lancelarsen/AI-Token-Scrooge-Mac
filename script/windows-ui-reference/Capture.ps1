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
}
'@
[ReferenceWindowNative]::SetProcessDPIAware() | Out-Null
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
        $rows += $row
    }
    $rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $Output 'dashboard-elements.json')
    $rect = New-Object ReferenceWindowNative+Rect
    if (-not [ReferenceWindowNative]::GetWindowRect($handle, [ref]$rect)) { throw 'Could not read native window bounds.' }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -lt 600 -or $height -lt 400) { throw 'Unexpected reference window dimensions.' }
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
        $bitmap.Save((Join-Path $Output 'dashboard.png'), [System.Drawing.Imaging.ImageFormat]::Png)
        $colors = New-Object 'System.Collections.Generic.HashSet[int]'
        for ($x = 0; $x -lt $width; $x += 17) {
            for ($y = 0; $y -lt $height; $y += 17) { [void]$colors.Add($bitmap.GetPixel($x, $y).ToArgb()) }
        }
        if ($colors.Count -lt 8) { throw 'The runner returned a blank/unrendered desktop capture.' }
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
    if (-not ($rows | Where-Object { $_.name -match 'Reset Horizon|Reset horizon' })) { throw 'The captured window did not expose the demo dashboard.' }
    [ordered]@{ release = 'v2026.11.6.006'; source = 'eb042cb1fd9f44e896c2126738121ae8c80d80b0';
        width = $width; height = $height; elements = $rows.Count; session = $app.SessionId;
        scope = 'Isolated demo rendering only; no live provider or authentication verification.' } |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $Output 'capture.json')
} finally {
    if ($null -ne $app -and -not $app.HasExited) { $app.Kill(); $app.WaitForExit() }
    # Only screenshots/geometry leave this fresh runner, never its generated state.
    if (Test-Path -LiteralPath $data) { Remove-Item -LiteralPath $data -Recurse -Force }
}
