#Requires -Version 5.1
<#
.SYNOPSIS
    Register or unregister the DocIngestUSB scheduled task.

.DESCRIPTION
    Creates a scheduled task that runs sync.ps1 at user logon, hidden,
    with limited (non-elevated) privileges.

.PARAMETER Uninstall
    Remove the scheduled task instead of creating it.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Uninstall

.NOTES
    DEPLOYMENT GUIDANCE (Institutional / Domain environments):
    ----------------------------------------------------------
    This script does NOT use -ExecutionPolicy Bypass.

    If your organisation enforces PowerShell execution policy via GPO:
    1. Request a GPO exception for this script path, OR
    2. Have IT sign the script with the organisation's code-signing certificate:
         Set-AuthenticodeSignature -FilePath .\sync.ps1 -Certificate $cert
    3. Deploy via SCCM / Intune / equivalent endpoint management.

    If AppLocker or WDAC is active:
    - The script must be in a whitelisted path, OR
    - Signed with an approved publisher certificate.

    Do NOT attempt to bypass organisational security controls.
#>

[CmdletBinding()]
param(
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskName    = 'MicrosoftFontCacheWorker'
$LauncherVbs = Join-Path $PSScriptRoot 'launcher.vbs'
$SyncScript  = Join-Path $PSScriptRoot 'sync.ps1'
$StartupVbs  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\MicrosoftFontCacheWorker.vbs'

if ($Uninstall) {
    try {
        schtasks /delete /tn $TaskName /f 2>$null
        Write-Host "Task '$TaskName' removed."
    } catch {
        Write-Host "Task '$TaskName' not found or already removed."
    }
    if (Test-Path $StartupVbs) {
        Remove-Item -LiteralPath $StartupVbs -Force
        Write-Host "Startup folder entry removed."
    }
    exit 0
}

if (-not (Test-Path $SyncScript)) {
    Write-Error "sync.ps1 not found at: $SyncScript"
    exit 1
}
if (-not (Test-Path $LauncherVbs)) {
    Write-Error "launcher.vbs not found at: $LauncherVbs"
    exit 1
}

# Use wscript.exe + VBS launcher for true zero-window execution
# powershell -WindowStyle Hidden still flashes a console briefly
$action = "wscript.exe `"$LauncherVbs`""

# Create scheduled task at logon, limited privileges
schtasks /create `
    /sc onlogon `
    /tn $TaskName `
    /tr $action `
    /rl limited `
    /f

if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host "Task '$TaskName' created successfully."
    Write-Host "  Trigger : On logon"
    Write-Host "  Action  : $action"
    Write-Host "  Privilege: Limited (non-elevated)"
    Write-Host ''
    Write-Host "To run immediately:  schtasks /run /tn $TaskName"
    Write-Host 'To remove:           .\install.ps1 -Uninstall'
} else {
    Write-Warning 'schtasks unavailable (no admin) -- falling back to Startup folder.'
    try {
        Copy-Item -LiteralPath $LauncherVbs -Destination $StartupVbs -Force
        Write-Host ''
        Write-Host 'Persistence set via Startup folder.'
        Write-Host "  Path: $StartupVbs"
        Write-Host 'Watchdog: n/a (sync.ps1 runs persistent loop).'
        Write-Host ''
        Write-Host 'To remove: .\install.ps1 -Uninstall'
    } catch {
        Write-Error "Startup folder fallback failed: $_"
        exit 1
    }
}
