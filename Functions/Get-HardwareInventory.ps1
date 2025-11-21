function Get-HardwareInventory {
    param (
        [string]$CsvPath = ""
    )

    Write-Host "Gathering Hardware Inventory..."

    $graphicsCards = Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, VideoProcessor
    $soundDevices = Get-CimInstance Win32_SoundDevice | Select-Object Name, Manufacturer, Status
    $networkAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionID } |
        Select-Object Name, NetConnectionID, @{Name="SpeedMbps"; Expression={if ($_.Speed) {[math]::Round($_.Speed / 1000000, 2)} else {0}}}

    $usbDevices = Get-WmiObject Win32_USBControllerDevice | ForEach-Object {
        [Wmi]$_.Dependent
    } | Select-Object Name, Manufacturer, DeviceID

    $result = [PSCustomObject]@{
        GraphicsCards = $graphicsCards
        SoundDevices = $soundDevices
        NetworkAdapters = $networkAdapters
        USBDevices = $usbDevices
    }

    if ($CsvPath) {
        # Create directory if it doesn't exist
        $directory = Split-Path -Path $CsvPath -Parent
        if ([string]::IsNullOrEmpty($directory)) {
            $directory = "."
        }
        if (-not (Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        # Export each hardware section to separate CSV files
        $result.PSObject.Properties | ForEach-Object {
            $sectionName = $_.Name
            $sectionData = $_.Value

            if ($null -ne $sectionData -and $sectionData.Count -gt 0) {
                $sectionFileName = "Hardware_$sectionName.csv"
                $sectionFilePath = Join-Path -Path $directory -ChildPath $sectionFileName
                $sectionData | Export-Csv -Path $sectionFilePath -NoTypeInformation
                Write-Host "Exported $sectionName to: $sectionFilePath"
            }
        }
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-HardwareInventory -CsvPath $CsvPath
}
