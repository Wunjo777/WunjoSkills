# Claude Code Popup Notification - Remote (Server-Side, PowerShell)
# Sends notification via TCP to local machine through SSH reverse tunnel.
# Falls back to local WPF popup if TCP send fails and fallback_to_local is true.

param(
    [string]$HookTitle,
    [string]$HookMessage
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"
$hookName = $env:CLAUDE_HOOK_NAME  # "Notification" or "Stop"

# Defaults
$title = "Claude Code"
$message = "任务完成"
$sound = $true
$remotePort = 9876
$fallbackLocal = $true

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
        if ($config.remote) {
            if ($config.remote.port) { $remotePort = $config.remote.port }
            if ($null -ne $config.remote.fallback_to_local) { $fallbackLocal = $config.remote.fallback_to_local }
        }
    } catch {}
}

# Env var overrides config
if ($env:CLAUDE_REMOTE_PORT) { $remotePort = [int]$env:CLAUDE_REMOTE_PORT }

# Args override config
if ($HookTitle)   { $title = $HookTitle }
if ($HookMessage) { $message = $HookMessage }

# Try to send via TCP
$sent = $false
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect("localhost", $remotePort)
    $stream = $tcpClient.GetStream()
    $msg = "${title}|||${message}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg + "`n")
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
    $stream.Close()
    $tcpClient.Close()
    $sent = $true
} catch {
    $sent = $false
}

if ($sent) { exit 0 }

# TCP send failed
if ($fallbackLocal) {
    Add-Type -AssemblyName PresentationFramework

    if ($sound) {
        [System.Media.SystemSounds]::Exclamation.Play()
    }

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
} else {
    Write-Host "[Claude Code Popper] Remote send failed (port $remotePort). Is listener running locally?"
}
