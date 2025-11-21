function Get-SystemUptime {
    param (
        [string]$CsvPath = ""
    )

    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime

    $result = [PSCustomObject]@{
        Days = $uptime.Days
        Hours = $uptime.Hours
        Minutes = $uptime.Minutes
        Seconds = $uptime.Seconds
        TotalHours = [math]::Round($uptime.TotalHours, 2)
        TotalDays = [math]::Round($uptime.TotalDays, 2)
        LastBootTime = $os.LastBootUpTime
    }

    if ($CsvPath) {
        $result | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "System uptime exported to: $CsvPath"
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-SystemUptime -CsvPath $CsvPath
}
