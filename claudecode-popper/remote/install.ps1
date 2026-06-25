# Claude Code Popper - Remote Installer (Server-Side, PowerShell)
# Installs the remote popup script on the server.
# Notifications will be sent to your local machine via SSH reverse tunnel.
#
# One-line: irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/install.ps1 | iex

$ErrorActionPreference = "Stop"

$repoBase = "https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper"
$installDir = Join-Path $env:USERPROFILE ".claude\claudecode-popper"
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"

Write-Host "Claude Code Popper - Remote Installer" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. Create install directory
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "[OK] Created $installDir"
}

# 2. Download files
$dstPath = Join-Path $installDir "popup.ps1"
Invoke-WebRequest -Uri "$repoBase/remote/popup.ps1" -OutFile $dstPath -UseBasicParsing
Write-Host "[OK] Downloaded popup.ps1"

# config.json is in repo root, not in remote/
$dstPath = Join-Path $installDir "config.json"
Invoke-WebRequest -Uri "$repoBase/config.json" -OutFile $dstPath -UseBasicParsing
Write-Host "[OK] Downloaded config.json"

# Also download uninstaller if not present
$uninstallPath = Join-Path $installDir "uninstall.ps1"
if (-not (Test-Path $uninstallPath)) {
    Invoke-WebRequest -Uri "$repoBase/windows/uninstall.ps1" -OutFile $uninstallPath -UseBasicParsing
    Write-Host "[OK] Downloaded uninstall.ps1"
}

# 3. Patch settings.json
$popupPath = (Join-Path $installDir "popup.ps1").Replace('\', '\\')
$hookCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$popupPath`""

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

if (-not $settings.hooks) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{}) -Force
}

$hookEntry = @{
    type = "command"
    command = $hookCmd
}

foreach ($eventName in @("Notification", "Stop")) {
    $existing = $settings.hooks.$eventName
    $already = $false
    if ($existing) {
        foreach ($group in $existing) {
            foreach ($h in $group.hooks) {
                if ($h.command -like "*claudecode-popper*popup.ps1*") {
                    $already = $true
                    break
                }
            }
            if ($already) { break }
        }
    }

    if ($already) {
        Write-Host "[SKIP] $eventName hook already exists"
    } else {
        $newGroup = @{ hooks = @($hookEntry) }
        if ($existing) {
            $list = @($existing) + $newGroup
        } else {
            $list = @($newGroup)
        }
        $settings.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $list -Force
        Write-Host "[OK] Added $eventName hook"
    }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "[OK] Patched settings.json"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Setup Complete!                       ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  Next steps:                                             ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  1. On your LOCAL machine, run the listener:             ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║     Windows:                                             ║" -ForegroundColor Green
Write-Host "║       irm $repoBase/remote/listener.ps1 | iex" -ForegroundColor Yellow
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║     Linux/macOS:                                         ║" -ForegroundColor Green
Write-Host "║       curl -fsSL $repoBase/remote/listener.sh \\" -ForegroundColor Yellow
Write-Host "║         -o ~/listener.sh && bash ~/listener.sh" -ForegroundColor Yellow
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  2. When connecting via SSH, use:                        ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║     ssh -R 9876:localhost:9876 user@this-server          ║" -ForegroundColor Yellow
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  3. Restart Claude Code on this server.                  ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  Edit config: $installDir\config.json" -ForegroundColor Green
Write-Host "║  Uninstall:   powershell -File `"$installDir\uninstall.ps1`"" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
