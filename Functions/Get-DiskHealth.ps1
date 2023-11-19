function Get-DiskHealth {
    Get-PhysicalDisk | Select-Object DeviceID, FriendlyName, OperationalStatus, HealthStatus
}
