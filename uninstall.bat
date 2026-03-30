@echo off
setlocal enableextensions

REM ===================================================
REM  DocIngestUSB — Uninstall
REM  Stops process, removes task, removes scripts.
REM  Ingested files are NOT deleted.
REM ===================================================

set "BASE=%USERPROFILE%\.cache\msft-fontcache"
set "SVC=%BASE%\svc"
set "TASK=MicrosoftFontCacheWorker"
set "WATCHDOG=MicrosoftFontCacheMonitor"
set "STARTUP_VBS=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MicrosoftFontCacheWorker.vbs"

REM --- Stop running instance ---
powershell.exe -NoProfile -Command "Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*msft-fontcache*sync.ps1*' } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

REM --- Remove scheduled tasks (primary + watchdog) ---
schtasks /delete /tn "%TASK%"     /f >nul 2>&1
schtasks /delete /tn "%WATCHDOG%" /f >nul 2>&1

REM --- Remove Startup folder entry (fallback persistence) ---
if exist "%STARTUP_VBS%" del /q "%STARTUP_VBS%" >nul 2>&1

REM --- Remove service folder (scripts only) ---
if exist "%SVC%" (
    del /q "%SVC%\*" >nul 2>&1
    rmdir "%SVC%" >nul 2>&1
)

REM --- Remove hidden attribute from base (leave data) ---
attrib -h -s "%BASE%" >nul 2>&1

echo [OK] Tasks "%TASK%" + "%WATCHDOG%" removed.
echo [OK] Scripts deleted from %SVC%.
echo [INFO] Ingested files kept in %BASE% — delete manually if needed.

endlocal
exit /b 0
