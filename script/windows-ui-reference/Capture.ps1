param(
    [Parameter(Mandatory)][string]$Release,
    [Parameter(Mandatory)][string]$Output
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Output | Out-Null
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ReferenceWindowNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle, out Rect rect);
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
    $app = [System.Diagnostics.Process]::Start($start)
    $deadline = [DateTime]::UtcNow.AddSeconds(40)
    while ($app.MainWindowHandle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline) {
        if ($app.HasExited) { throw "Reference app exited before showing a window (exit $($app.ExitCode))." }
        Start-Sleep -Milliseconds 500
        $app.Refresh()
    }
    if ($app.MainWindowHandle -eq [IntPtr]::Zero) { throw 'No native reference window became available.' }
    [ReferenceWindowNative]::ShowWindow($app.MainWindowHandle, 9) | Out-Null
    [ReferenceWindowNative]::SetForegroundWindow($app.MainWindowHandle) | Out-Null
    Start-Sleep -Seconds 3
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($app.MainWindowHandle)
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
    if (-not [ReferenceWindowNative]::GetWindowRect($app.MainWindowHandle, [ref]$rect)) { throw 'Could not read native window bounds.' }
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
