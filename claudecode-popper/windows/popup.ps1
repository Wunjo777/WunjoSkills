# Claude Code Popup Notification - Windows
# Reads config from config.json in the same directory.
# Supports remote mode: TCP tunnel or ntfy.sh push.

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
$remoteMode = $null
$remotePort = $null
$fallbackLocal = $true
$ntfyServer = "https://ntfy.sh"
$ntfyTopic = ""
$ntfyToken = ""
$ntfyPriority = "high"
$ntfyTags = "robot_face"
$ntfyClick = ""

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
            if ($config.remote.mode) { $remoteMode = $config.remote.mode }
            if ($config.remote.port) { $remotePort = $config.remote.port }
            if ($null -ne $config.remote.fallback_to_local) { $fallbackLocal = $config.remote.fallback_to_local }
        }
        if ($config.ntfy) {
            if ($config.ntfy.server)   { $ntfyServer = $config.ntfy.server }
            if ($config.ntfy.topic)    { $ntfyTopic = $config.ntfy.topic }
            if ($config.ntfy.token)    { $ntfyToken = $config.ntfy.token }
            if ($config.ntfy.priority) { $ntfyPriority = $config.ntfy.priority }
            if ($config.ntfy.click)    { $ntfyClick = $config.ntfy.click }
            if ($config.ntfy.tags) {
                if ($config.ntfy.tags -is [array]) {
                    $ntfyTags = $config.ntfy.tags -join ","
                } else {
                    $ntfyTags = $config.ntfy.tags
                }
            }
        }
    } catch {}
}

# Env var overrides config
if ($env:CLAUDE_REMOTE_MODE) { $remoteMode = $env:CLAUDE_REMOTE_MODE }
if ($env:CLAUDE_REMOTE_PORT) { $remotePort = [int]$env:CLAUDE_REMOTE_PORT }
if ($env:CLAUDE_NTFY_TOPIC)  { $ntfyTopic = $env:CLAUDE_NTFY_TOPIC }
if ($env:CLAUDE_NTFY_SERVER) { $ntfyServer = $env:CLAUDE_NTFY_SERVER }

# Args override config
if ($HookTitle)   { $title = $HookTitle }
if ($HookMessage) { $message = $HookMessage }

# --- ntfy mode ---
function Send-Ntfy {
    if ([string]::IsNullOrEmpty($ntfyTopic)) {
        Write-Host "[Claude Code Popper] ntfy.topic not configured."
        return $false
    }
    try {
        $headers = @{
            "Title"    = $title
            "Priority" = $ntfyPriority
            "Tags"     = $ntfyTags
        }
        if ($ntfyToken) { $headers["Authorization"] = "Bearer $ntfyToken" }
        if ($ntfyClick) { $headers["Click"] = $ntfyClick }
        if (-not $sound) { $headers["X-Disable"] = "yes" }

        $uri = "$ntfyServer/$ntfyTopic"
        $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $message -UseBasicParsing -ErrorAction Stop
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300)
    } catch {
        return $false
    }
}

# --- tunnel mode ---
function Send-Tunnel {
    if (-not $remotePort) { return $false }
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
        return $true
    } catch {
        return $false
    }
}

# --- route by mode ---
$sent = $false
if ($remoteMode -eq "ntfy") {
    $sent = Send-Ntfy
    if (-not $sent) {
        if (-not $fallbackLocal) {
            Write-Host "[Claude Code Popper] ntfy send failed (server=$ntfyServer topic=$ntfyTopic)."
            exit 1
        }
    }
} elseif ($remotePort) {
    $sent = Send-Tunnel
    if (-not $sent) {
        if (-not $fallbackLocal) {
            Write-Host "[Claude Code Popper] Remote send failed (port $remotePort). Is listener running locally?"
            exit 1
        }
    }
}

if ($sent) { exit 0 }

# --- fallback: local notification ---
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
