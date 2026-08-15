$ErrorActionPreference = "Stop"
try {
    $TaskName = "DAT_Debug_Task_Low"
    $Time = "12:00"
    
    $triggerTime = [DateTime]::ParseExact($Time, "HH:mm", $null)
    $trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime
    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command Write-Host 'Hello'"
    
    Write-Host "Registering task (Low privileges)..."
    # Removed -RunLevel Highest
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description "Debug Task Low" -Force | Out-Null
    
    Write-Host "Task registered successfully."
    
    $task = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Task State: $($task.State)"
    
    Write-Host "Unregistering task..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task unregistered."
}
catch {
    Write-Host "ERROR OCCURRED:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
