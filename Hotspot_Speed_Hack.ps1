<# : >nul 2>&1
@echo off
title TTL / Hop Limit Configuration Tool

:: 1. Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. If running as Admin, execute the rest of this file as a PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dpnx0"
exit /b
#>

# ==============================================================================
# ===================== POWERSHELL SCRIPT STARTS HERE ==========================
# ==============================================================================

# 3. Get Current State
$currentIpv4 = ((netsh int ipv4 show glob | Select-String "Default Hop Limit") -replace '\D', '')
$currentIpv6 = ((netsh int ipv6 show glob | Select-String "Default Hop Limit") -replace '\D', '')

# 4. Display Menu
Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   TTL / Hop Limit Configuration Tool    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Current IPv4 TTL : $currentIpv4" -ForegroundColor Green
Write-Host "Current IPv6 TTL : $currentIpv6" -ForegroundColor Green
Write-Host "-----------------------------------------" -ForegroundColor Cyan
Write-Host "1. Set TTL to 65  (Hotspot tweak, reverts on reboot)"
Write-Host "2. Set TTL to 128 (Windows default, permanent restore)"
Write-Host "3. Set Custom TTL (Reverts on reboot)"
Write-Host "4. Exit"
Write-Host "-----------------------------------------" -ForegroundColor Cyan

$choice = Read-Host "Select an option (1-4)"
$ttl = 0
$store = "active"

switch ($choice) {
    '1' { $ttl = 65 }
    '2' { 
        $ttl = 128 
        $store = "persistent" 
    }
    '3' { 
        [int]$inputTTL = Read-Host "Enter custom TTL value (1-255)"
        if ($inputTTL -ge 1 -and $inputTTL -le 255) {
            $ttl = $inputTTL
        } else {
            Write-Warning "Invalid TTL value. Must be between 1 and 255."
            Start-Sleep -Seconds 3
            exit
        }
    }
    '4' { exit }
    default { 
        Write-Warning "Invalid selection."
        Start-Sleep -Seconds 2
        exit 
    }
}

# 5. Check if setting is already in place
if ([int]$currentIpv4 -eq $ttl -and [int]$currentIpv6 -eq $ttl) {
    Write-Host "`nThe TTL is already set to $ttl for both IPv4 and IPv6." -ForegroundColor Yellow
    Write-Host "No changes are necessary." -ForegroundColor Yellow
} else {
    # 6. Apply the settings
    Write-Host "`nApplying TTL=$ttl to both IPv4 and IPv6 ($store)..." -ForegroundColor Cyan
    netsh int ipv4 set glob defaultcurhoplimit=$ttl store=$store | Out-Null
    netsh int ipv6 set glob defaultcurhoplimit=$ttl store=$store | Out-Null
    
    Write-Host "Success! Settings updated." -ForegroundColor Green
}

Read-Host "`nPress Enter to exit"