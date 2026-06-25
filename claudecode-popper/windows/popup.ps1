# Claude Code Popup Notification - Windows
# Reads config from config.json in the same directory.

param(
    [string]$HookTitle,
    [string]$HookMessage
)

Add-Type -AssemblyName PresentationFramework

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"
$hookName = $env:CLAUDE_HOOK_NAME  # "Notification" or "Stop"

# Defaults
$title = "Claude Code"
$message = "任务完成"
$sound = $true

# Load config if exists
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $section = if ($hookName -eq "Notification") { $config.notification } else { $config.stop }
        if ($section) {
            if ($section.title)   { $title = $section.title }
            if ($section.message) { $message = $section.message }
            if ($null -ne $section.sound) { $sound = $section.sound }
        }
    } catch {}
}

# Args override config
if ($HookTitle)   { $title = $HookTitle }
if ($HookMessage) { $message = $HookMessage }

# Play sound
if ($sound) {
    [System.Media.SystemSounds]::Exclamation.Play()
}

# Create window
$window = New-Object System.Windows.Window
$window.Title = $title
$window.Width = 400
$window.Height = 200
$window.Topmost = $true
$window.WindowStartupLocation = "CenterScreen"

$text = New-Object System.Windows.Controls.TextBlock
$text.Text = $message
$text.FontSize = 24
$text.TextAlignment = "Center"
$text.VerticalAlignment = "Center"

$window.Content = $text
$window.Add_KeyDown({ $window.Close() })

$window.ShowDialog() | Out-Null
