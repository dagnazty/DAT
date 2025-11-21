function Get-DriversInformation {
    param (
        [string]$CsvPath = ""
    )

    $drivers = Get-WmiObject Win32_PnPSignedDriver |
        Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate,
            @{Name="IsSigned"; Expression={$_.IsSigned}}

    if ($CsvPath) {
        $drivers | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Drivers information exported to: $CsvPath"
    }

    return $drivers
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-DriversInformation -CsvPath $CsvPath
}
