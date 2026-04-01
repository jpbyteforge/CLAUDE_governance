$action   = New-ScheduledTaskAction -Execute "wsl.exe" -Argument '-e bash -c "exit"'
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "WSL2 AutoStart" -TaskPath "\Startup\" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
Get-ScheduledTask -TaskName "WSL2 AutoStart" | Select-Object TaskName, State
