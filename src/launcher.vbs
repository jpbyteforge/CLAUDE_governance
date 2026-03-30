' DocIngestUSB — Zero-window launcher with diagnostic logging
' wscript.exe creates NO console window at all (unlike powershell -WindowStyle Hidden)
' -ExecutionPolicy Bypass: process-scope only, does not alter system or user policy

Const LOG_MAX_BYTES = 102400  ' 100 KB — rotate before appending if exceeded

Dim fso, scriptDir, syncPath, logDir, logPath, logRotated
Set fso   = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
syncPath  = scriptDir & "\sync.ps1"
logDir    = fso.GetParentFolderName(scriptDir)
logPath   = logDir & "\launcher_log.txt"

' Rotate log if over size cap (keep one archive copy)
On Error Resume Next
If fso.FileExists(logPath) Then
    If fso.GetFile(logPath).Size > LOG_MAX_BYTES Then
        Dim rotPath : rotPath = logDir & "\launcher_log.1.txt"
        If fso.FileExists(rotPath) Then fso.DeleteFile rotPath
        fso.MoveFile logPath, rotPath
    End If
End If
Err.Clear

' Always log invocation — if this entry is absent after logon, the launcher never ran
Dim logFile : Set logFile = fso.OpenTextFile(logPath, 8, True)
If Err.Number = 0 Then
    logFile.WriteLine Now() & " | INVOKE | " & syncPath
    logFile.Close
End If
Err.Clear

' Launch PowerShell hidden, no wait
' -ExecutionPolicy Bypass: process-scope override (owner decision 2026-03-30)
' 0 = vbHide (no window created), False = don't wait for process to finish
Dim shell : Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & syncPath & """", 0, False
If Err.Number <> 0 Then
    Dim errFile : Set errFile = fso.OpenTextFile(logPath, 8, True)
    If Err.Number = 0 Then
        errFile.WriteLine Now() & " | LAUNCH_ERROR | " & Err.Description & " (0x" & Hex(Err.Number) & ")"
        errFile.Close
    End If
End If
