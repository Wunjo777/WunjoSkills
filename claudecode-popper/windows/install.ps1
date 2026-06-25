# Claude Code Popper - Windows Installer
# One-line: irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/windows/install.ps1 | iex

$ErrorActionPreference = "Stop"

$repoBase = "https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master"
$installDir = Join-Path $env:USERPROFILE ".claude\claudecode-popper"
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"

Write-Host "Claude Code Popper - Windows Installer" -ForegroundColor Cyan

# 1. Create install directory
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "[OK] Created $installDir"
}

# 2. Download files
$files = @("popup.ps1", "config.json", "uninstall.ps1")
foreach ($f in $files) {
    $dstPath = Join-Path $installDir $f
    Invoke-WebRequest -Uri "$repoBase/windows/$f" -OutFile $dstPath -UseBasicParsing
    Write-Host "[OK] Downloaded $f"
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
Write-Host "Done! Restart Claude Code to see popups." -ForegroundColor Green
Write-Host "Edit config: $installDir\config.json"
Write-Host "Uninstall:   powershell -File `"$installDir\uninstall.ps1`""
