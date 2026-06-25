# Claude Code Popper - Windows Uninstaller
# One-line: irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/windows/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

$installDir = Join-Path $env:USERPROFILE ".claude\claudecode-popper"
$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"

Write-Host "Claude Code Popper - Windows Uninstaller" -ForegroundColor Cyan

# 1. Remove hooks from settings.json
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    foreach ($eventName in @("Notification", "Stop")) {
        $existing = $settings.hooks.$eventName
        if ($existing) {
            $filtered = @()
            foreach ($group in $existing) {
                $keep = $true
                foreach ($h in $group.hooks) {
                    if ($h.command -like "*claudecode-popper*popup.ps1*") {
                        $keep = $false
                        break
                    }
                }
                if ($keep) { $filtered += $group }
            }
            if ($filtered.Count -eq 0) {
                $settings.hooks.PSObject.Properties.Remove($eventName)
                Write-Host "[OK] Removed $eventName hook"
            } else {
                $settings.hooks.$eventName = $filtered
                Write-Host "[OK] Removed $eventName hook (kept other hooks)"
            }
        }
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "[OK] Patched settings.json"
}

# 2. Remove install directory
if (Test-Path $installDir) {
    Remove-Item -Recurse -Force $installDir
    Write-Host "[OK] Removed $installDir"
}

Write-Host ""
Write-Host "Done! Restart Claude Code." -ForegroundColor Green
