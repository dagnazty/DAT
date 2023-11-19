function Get-SystemInformation {
    Write-Host "Gathering Operating System Information..."
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, InstallDate

    Write-Host "Gathering CPU Information..."
    $cpuInfo = Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed

    Write-Host "Gathering Memory Information..."
    $memoryInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum

    Write-Host "Gathering Disk Information..."
    $diskInfo = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, VolumeName, @{Name="Size(GB)"; Expression={$_.Size / 1GB -as [int]}}, @{Name="FreeSpace(GB)"; Expression={$_.FreeSpace / 1GB -as [int]}}

    Write-Host "Gathering Network Information..."
    $networkInfo = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -ne $null} | Select-Object Description, IPAddress, IPSubnet, DefaultIPGateway

    Write-Host "Gathering User Account Information..."
    $userAccounts = Get-CimInstance Win32_UserAccount | Select-Object Name, Domain, Disabled, PasswordRequired, PasswordChangeable

    Write-Host "Gathering System Services Information..."
    $systemServices = Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, DisplayName, Status

    Write-Host "Gathering Installed Software Information..."
    $installedSoftware = Get-CimInstance Win32_Product | Select-Object Name, Version, InstallDate

    Write-Host "Gathering Security and Update Status..."
    $securityUpdateStatus = Get-SecurityUpdateStatus

    Write-Host "Gathering Event Log Summary..."
    $eventLogSummary = Get-EventLogSummary

    $hardwareInventory = Get-HardwareInventory

    $softwareLicensing = Get-SoftwareLicensing

    Write-Host "Gathering Performance Metrics..."
    $performanceMetrics = Get-PerformanceMetrics

    Write-Host "Gathering System Uptime..."
    $systemUptime = Get-SystemUptime

    Write-Host "Gathering Running Processes..."
    $runningProcesses = Get-RunningProcesses

    Write-Host "Gathering Windows Update History..."
    $windowsUpdateHistory = Get-WindowsUpdateHistory

    Write-Host "Gathering Drivers Information..."
    $driversInformation = Get-DriversInformation
    
    return [PSCustomObject]@{
        OSInfo = $osInfo
        CPUInfo = $cpuInfo
        MemoryInfo = $memoryInfo
        DiskInfo = $diskInfo
        NetworkInfo = $networkInfo
        UserAccounts = $userAccounts
        SystemServices = $systemServices
        InstalledSoftware = $installedSoftware
        SecurityUpdateStatus = $securityUpdateStatus
        EventLogSummary = $eventLogSummary
        HardwareInventory = $hardwareInventory
        SoftwareLicensing = $softwareLicensing
        PerformanceMetrics = $performanceMetrics
        SystemUptime = $systemUptime
        RunningProcesses = $runningProcesses
        WindowsUpdateHistory = $windowsUpdateHistory
        DriversInformation = $driversInformation
    }
}
