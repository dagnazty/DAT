function Get-HardwareInventory {
    Write-Host "Gathering Hardware Inventory..."

    $graphicsCards = Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, VideoProcessor
    $soundDevices = Get-CimInstance Win32_SoundDevice | Select-Object Name, Manufacturer, Status
    $networkAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionID } | Select-Object Name, NetConnectionID, Speed

    $usbDevices = Get-WmiObject Win32_USBControllerDevice | ForEach-Object { 
        [Wmi]$_.Dependent 
    } | Select-Object Name, Manufacturer, DeviceID

    return [PSCustomObject]@{
        GraphicsCards = $graphicsCards
        SoundDevices = $soundDevices
        NetworkAdapters = $networkAdapters
        USBDevices = $usbDevices
    }
}
