# Claude Code Popper - Remote Listener (Local Machine, Windows)
# Listens on a TCP port for notifications from remote server via SSH reverse tunnel.
# Shows WPF popup dialog on your local Windows desktop.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File listener.ps1 [-Port 9876]
#
# Setup:
#   1. Start this listener in a terminal on your local Windows machine
#   2. SSH to server with reverse tunnel: ssh -R 9876:localhost:9876 user@server
#   3. Use Claude Code on the server — popups appear locally on Windows

param(
    [int]$Port = 9876
)

Add-Type -AssemblyName PresentationFramework

function Show-Popup {
    param(
        [string]$Title = "Claude Code",
        [string]$Message = "任务完成"
    )

    [System.Media.SystemSounds]::Exclamation.Play()

    $window = New-Object System.Windows.Window
    $window.Title = $Title
    $window.Width = 400
    $window.Height = 200
    $window.Topmost = $true
    $window.WindowStartupLocation = "CenterScreen"

    $text = New-Object System.Windows.Controls.TextBlock
    $text.Text = $Message
    $text.FontSize = 24
    $text.TextAlignment = "Center"
    $text.VerticalAlignment = "Center"

    $window.Content = $text
    $window.Add_KeyDown({ $window.Close() })

    $window.ShowDialog() | Out-Null
}

Write-Host "======================================================="
Write-Host "Claude Code Popper - Remote Listener"
Write-Host "======================================================="
Write-Host "Listening on port: $Port"
Write-Host "OS: Windows"
Write-Host ""
Write-Host "Setup SSH tunnel on your server:"
Write-Host "  ssh -R ${Port}:localhost:${Port} user@server"
Write-Host ""
Write-Host "Press Ctrl+C to stop."
Write-Host ""

try {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
    $listener.Start()
    Write-Host "[INFO] Listener started on port $Port"

    while ($true) {
        if (-not $listener.Pending()) {
            Start-Sleep -Milliseconds 200
            continue
        }

        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $msg = $reader.ReadLine()
        $reader.Close()
        $stream.Close()
        $client.Close()

        if ([string]::IsNullOrEmpty($msg)) { continue }

        # Parse protocol: TITLE|||MESSAGE
        if ($msg -match '^(.+?)\|\|\|(.+)$') {
            $title = $Matches[1]
            $message = $Matches[2]
        } else {
            $title = "Claude Code"
            $message = $msg
        }

        # Show popup
        Show-Popup -Title $title -Message $message

        # Log
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] $title`: $message"
    }
} finally {
    if ($listener) { $listener.Stop() }
    Write-Host "[INFO] Listener stopped."
}
