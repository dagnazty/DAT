function New-ScheduledAudit {
    param (
        [Parameter(Mandatory)]
        [string]$TaskName,

        [Parameter(Mandatory)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$Frequency,

        [Parameter(Mandatory)]
        [string]$Time,

        [Parameter(Mandatory)]
        [string[]]$EnabledChecks,

        [switch]$EnableEmailAlerts,

        [switch]$Force
    )

    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        throw "Creating scheduled tasks requires administrator privileges. Please run PowerShell as Administrator and try again."
    }

    # Validate time format
    if ($Time -notmatch "^\d{2}:\d{2}$") {
        throw "Time must be in HH:mm format (e.g., 09:00)"
    }

    # Check if task exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        if ($Force) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        else {
            throw "Task '$TaskName' already exists. Use -Force to overwrite."
        }
    }

    # Calculate trigger
    $triggerTime = [DateTime]::ParseExact($Time, "HH:mm", $null)
    $trigger = switch ($Frequency) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At $triggerTime }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -At $triggerTime -DaysOfWeek (Get-Date).DayOfWeek }
        "Monthly" { New-ScheduledTaskTrigger -Monthly -At $triggerTime -DaysOfWeek (Get-Date).DayOfWeek -WeeksOfMonth First }
    }

    # Build action
    $scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Run-ScheduledAudit.ps1"
    
    # Construct arguments string
    $checksString = $EnabledChecks -join "','"
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" -TaskName `"$TaskName`" -EnabledChecks @('$checksString')"
    if ($EnableEmailAlerts) {
        $arguments += " -EnableEmailAlerts"
    }
    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments

    # Register task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description "DAT Scheduled Audit: $TaskName" | Out-Null

    Write-Host "Scheduled task '$TaskName' created successfully."
}

function Get-ScheduledAudits {
    <#
    .SYNOPSIS
    Retrieves all DAT scheduled audit tasks.
    
    .DESCRIPTION
    Filters scheduled tasks to return only those created by the DAT tool.
    Returns TaskName, State, and NextRunTime for each task.
    #>
    
    try {
        # Filter specifically for DAT audit tasks by checking the description
        $tasks = Get-ScheduledTask | Where-Object { 
            $_.Description -like "DAT Scheduled Audit:*" 
        }
        
        if (-not $tasks) {
            return @()
        }
        
        $results = @()
        foreach ($task in $tasks) {
            try {
                $info = $task | Get-ScheduledTaskInfo
                $results += [PSCustomObject]@{
                    TaskName    = $task.TaskName
                    State       = $task.State
                    NextRunTime = $info.NextRunTime
                }
            }
            catch {
                Write-Warning "Could not retrieve info for task: $($task.TaskName)"
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to retrieve scheduled tasks: $_"
        return @()
    }
}

function Remove-ScheduledAudit {
    <#
    .SYNOPSIS
    Removes a DAT scheduled audit task.
    
    .DESCRIPTION
    Deletes a scheduled task created by the DAT tool.
    Requires administrator privileges.
    
    .PARAMETER TaskName
    Name of the scheduled task to remove.
    #>
    
    param (
        [Parameter(Mandatory)]
        [string]$TaskName
    )
    
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        throw "Removing scheduled tasks requires administrator privileges. Please run PowerShell as Administrator and try again."
    }
    
    # Check if task exists
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        throw "Task '$TaskName' not found."
    }
    
    # Remove the task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Scheduled task '$TaskName' removed successfully."
}
