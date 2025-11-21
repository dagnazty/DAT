function Get-RunningProcesses {
    param (
        [string]$CsvPath = ""
    )

    $processes = Get-Process | Select-Object Name,
        Id,
        @{Name="CPU"; Expression={[math]::Round($_.CPU, 2)}},
        @{Name="WorkingSetMB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}},
        @{Name="PrivateMemoryMB"; Expression={[math]::Round($_.PrivateMemorySize / 1MB, 2)}},
        StartTime,
        Responding

    if ($CsvPath) {
        $processes | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Running processes exported to: $CsvPath"
    }

    return $processes
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-RunningProcesses -CsvPath $CsvPath
}
