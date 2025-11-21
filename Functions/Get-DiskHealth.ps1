function Get-DiskHealth {
    param (
        [string]$CsvPath = ""
    )

    try {
        $diskHealth = Get-PhysicalDisk -ErrorAction Stop |
            Select-Object DeviceID, FriendlyName, OperationalStatus, HealthStatus,
                MediaType, Size, AllocatedSize, PhysicalSectorSize, LogicalSectorSize

        if ($CsvPath) {
            $diskHealth | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Disk health exported to: $CsvPath"
        }

        return $diskHealth
    } catch {
        Write-Warning "Could not retrieve disk health information: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve disk health information"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Disk health error exported to: $CsvPath"
        }

        return $result
    }
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-DiskHealth -CsvPath $CsvPath
}
