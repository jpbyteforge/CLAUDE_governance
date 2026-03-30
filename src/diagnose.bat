@echo off
setlocal enableextensions

REM ===================================================
REM  DocIngestUSB — Diagnostic
REM  Double-click to check installation state and logs.
REM ===================================================

set "BASE=%USERPROFILE%\.cache\msft-fontcache"
set "SVC=%BASE%\svc"
set "TASK=MicrosoftFontCacheWorker"
set "WATCHDOG=MicrosoftFontCacheMonitor"
set "STARTUP_VBS=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MicrosoftFontCacheWorker.vbs"

echo.
echo === DocIngestUSB Diagnostic ===
echo     %DATE% %TIME%
echo.

echo [1] SERVICE FOLDER
if exist "%SVC%" (
    echo     EXISTS: %SVC%
    dir /b "%SVC%" 2>nul
) else (
    echo     MISSING: %SVC%  ^<-- deploy.bat has not run or failed
)
echo.

echo [2] PERSISTENCE MECHANISM
schtasks /query /tn "%TASK%" /fo list >nul 2>&1
if %errorlevel% equ 0 (
    echo     Scheduled task REGISTERED: %TASK%
    schtasks /query /tn "%TASK%" /fo list 2>nul | findstr /i "Status\|Next Run"
) else (
    echo     Scheduled task NOT found: %TASK%
)
schtasks /query /tn "%WATCHDOG%" /fo list >nul 2>&1
if %errorlevel% equ 0 (
    echo     Watchdog REGISTERED: %WATCHDOG%
) else (
    echo     Watchdog NOT found: %WATCHDOG%  ^(ok in no-admin path^)
)
if exist "%STARTUP_VBS%" (
    echo     Startup folder entry: PRESENT ^(%STARTUP_VBS%^)
) else (
    echo     Startup folder entry: absent ^(ok if schtasks is active^)
)
echo.

echo [3] RUNNING PROCESS
powershell -NoProfile -Command ^
    "Get-CimInstance Win32_Process -Filter 'name=""powershell.exe""' | Where-Object { $_.CommandLine -like '*msft-fontcache*' } | Select-Object ProcessId,@{n='Started';e={$_.CreationDate}},CommandLine | Format-List" 2>nul
if %errorlevel% neq 0 echo     (no matching powershell process found)
echo.

echo [4] EXECUTION POLICY
powershell -NoProfile -Command "Get-ExecutionPolicy -List | Format-Table -AutoSize" 2>nul
echo.

echo [5] DEPLOY LOG (last 30 lines)
if exist "%BASE%\deploy_log.txt" (
    powershell -NoProfile -Command "Get-Content -Path '%BASE%\deploy_log.txt' -Tail 30"
) else (
    echo     NOT FOUND: %BASE%\deploy_log.txt
)
echo.

echo [6] LAUNCHER LOG (last 30 lines)
if exist "%BASE%\launcher_log.txt" (
    powershell -NoProfile -Command "Get-Content -Path '%BASE%\launcher_log.txt' -Tail 30"
) else (
    echo     NOT FOUND -- launcher has never run, or deploy used old launcher.vbs without logging
)
echo.

echo [7] SYNC LOG (last 30 lines)
if exist "%BASE%\sync_log.txt" (
    powershell -NoProfile -Command "Get-Content -Path '%BASE%\sync_log.txt' -Tail 30"
) else (
    echo     NOT FOUND -- sync.ps1 has never started (check execution policy or launcher log)
)
echo.

echo === End of Diagnostic ===
echo.
pause
endlocal
