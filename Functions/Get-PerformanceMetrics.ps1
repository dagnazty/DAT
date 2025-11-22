function Get-PerformanceMetrics {
    param (
        [string]$CsvPath = ""
    )

    try {
        $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $memoryUsage = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $diskIO = Get-Counter '\PhysicalDisk(_Total)\Disk Transfers/sec' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
        $networkIO = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
    }
    catch {
        Write-Warning "Some performance counters could not be retrieved: $_"
        # Provide default values if counters fail
        $cpuUsage = [PSCustomObject]@{CookedValue = 0 }
        $memoryUsage = [PSCustomObject]@{CookedValue = 0 }
        $diskIO = [PSCustomObject]@{CookedValue = 0 }
        $networkIO = [PSCustomObject]@{CookedValue = 0 }
    }

    $result = [PSCustomObject]@{
        Timestamp            = Get-Date
        CPUUsagePercent      = [math]::Round($cpuUsage.CookedValue, 2)
        MemoryUsagePercent   = [math]::Round($memoryUsage.CookedValue, 2)
        DiskIOPerSec         = [math]::Round($diskIO.CookedValue, 2)
        NetworkIOBytesPerSec = if ($networkIO -is [System.Array]) {
            [math]::Round(($networkIO | Measure-Object -Property CookedValue -Sum).Sum, 2)
        }
        else {
            [math]::Round($networkIO.CookedValue, 2)
        }
    }

    if ($CsvPath) {
        $result | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Performance metrics exported to: $CsvPath"
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-PerformanceMetrics -CsvPath $CsvPath
}
