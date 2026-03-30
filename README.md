# DocIngestUSB

Silent USB document ingestion for Windows. Monitors removable drives and copies new PDF, DOCX, and DOC files to a local folder — deduplicated by content hash (SHA-256).

## Features

- **Auto-detection** — detects USB insertion via lightweight polling (no WMI events)
- **Content dedup** — SHA-256 hash prevents duplicate copies, even with different filenames
- **Atomic copy** — temp file + hash verify + rename; no partial files on eject
- **Non-blocking I/O** — USB can be safely ejected at any moment
- **Zero window** — VBScript launcher ensures no console flash
- **Provenance metadata** — `.meta.json` sidecar per file (source path, USB serial, timestamps)
- **Log rotation** — structured audit log with configurable size cap
- **Watchdog** — secondary scheduled task restarts the process if it dies (admin path only)
- **No-admin fallback** — if `schtasks` requires elevation, persists via user Startup folder
- **Portable** — environment variable expansion; no hardcoded paths

## Quick Start

### Deploy (one command)

```cmd
deploy.bat
```

Creates a hidden local folder, copies scripts + config, then attempts to register two scheduled tasks (logon + 5-minute watchdog). Starts immediately.

**No admin?** If `schtasks` is blocked by permissions, `deploy.bat` falls back automatically: copies `launcher.vbs` to the user Startup folder (`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`) and launches directly. No watchdog task in this path — `sync.ps1` runs as a persistent loop and does not need one.

### Uninstall

```cmd
uninstall.bat
```

Stops the process, removes both tasks, deletes scripts. Ingested files are kept.

### Manual test

```powershell
powershell -NoProfile -File .\src\sync.ps1
```

Insert a USB drive. Files appear in the destination folder within seconds. `Ctrl+C` to stop.

## Configuration

Edit `config.json` before deploying:

| Field | Default | Description |
|-------|---------|-------------|
| `destinationPath` | `%USERPROFILE%\.cache\msft-fontcache` | Target folder (supports env vars) |
| `extensions` | `.pdf .docx .doc` | File types to ingest |
| `sleepSeconds` | `30` | Max settle time after USB insertion |
| `rescanMinutes` | `5` | Re-scan interval for already-scanned drives |
| `log.maxSizeMB` | `10` | Max log size before rotation |
| `log.retentionCount` | `3` | Number of rotated logs to keep |
| `fileSizeCapMB` | `500` | Skip files larger than this |

## How It Works

```
[Poll drive letters every 5s]
         |
   New USB detected?
         |
   [Adaptive settle: 2s retries, max 30s]
         |
   [Stream: enumerate → hash → atomic copy]
         |
   [Batch flush hash DB + log]
         |
   [Sleep 5s → loop]
```

1. **Detection** — compares current removable drives against known set (zero disk I/O)
2. **Settle** — retries access every 2s until drive is ready (avg ~3-5s, max 30s)
3. **Streaming scan** — `Get-ChildItem` pipes directly into hash + copy (no array materialization)
4. **Dedup** — in-memory `HashSet<string>` with O(1) lookups; persisted to flat file in batch
5. **Atomic copy** — write to `.tmp`, verify hash, rename; corrupt files auto-cleaned
6. **Metadata** — JSON sidecar records source path, USB serial, original timestamps, hostname

## Project Structure

```
DocIngestUSB/
├── deploy.bat           # Full deploy: copy scripts + register tasks (with no-admin fallback)
├── uninstall.bat        # Clean removal (tasks + Startup folder entry)
├── config.json          # All tunables
└── src/
    ├── sync.ps1         # Core engine (~420 lines, persistent loop)
    ├── launcher.vbs     # Zero-window process launcher (logs invocation to launcher_log.txt)
    ├── install.ps1      # Task-only re-installer (scripts already deployed)
    └── diagnose.bat     # Double-click diagnostic: checks installation, logs, execution policy
```

## Requirements

- Windows 10/11
- PowerShell 5.1+ (ships with Windows)
- No external modules
- Admin rights not required (Startup folder fallback)

## License

Private repository.
