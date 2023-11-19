. ".\Functions\Get-PerformanceMetrics.ps1"
. ".\Functions\Get-SystemUptime.ps1"
. ".\Functions\Get-RunningProcesses.ps1"
. ".\Functions\Get-WindowsUpdateHistory.ps1"
. ".\Functions\Get-DriversInformation.ps1"
. ".\Functions\Get-HardwareInventory.ps1"
. ".\Functions\Get-SoftwareLicensing.ps1"
. ".\Functions\Get-SystemInformation.ps1"
. ".\Functions\Get-SecurityUpdateStatus.ps1"
. ".\Functions\Get-EventLogSummary.ps1"
. ".\Functions\Format-AndLogInformation.ps1"
. ".\Functions\LogAndDisplay.ps1"
. ".\Functions\Get-BackupStatus.ps1"
. ".\Functions\Get-OpenPorts.ps1"
. ".\Functions\Get-UserGroups.ps1"
. ".\Functions\Scan-SuspiciousRegistryEntries.ps1"
. ".\Functions\Get-DiskHealth.ps1"

function Show-Menu {
    param (
        [string]$Title = "dag's Audit Tool - Interactive Mode"
    )
    Clear-Host
    Write-Host "================ $Title ================"

    Write-Host "1: Operating System Information"
    Write-Host "2: CPU Information"
    Write-Host "3: Memory Information"
    Write-Host "4: Disk Information"
    Write-Host "5: Network Information"
    Write-Host "6: User Accounts"
    Write-Host "7: System Services"
    Write-Host "8: Installed Software"
    Write-Host "9: Hardware Inventory"
    Write-Host "10: Software Licensing"
    Write-Host "11: Event Log Summary"
    Write-Host "12: Security and Update Status"
    Write-Host "13: Performance Metrics"
    Write-Host "14: System Uptime"
    Write-Host "15: Running Processes"
    Write-Host "16: Windows Update History"
    Write-Host "17: Drivers Information"
    Write-Host "18: Backup Status" 
    Write-Host "19: Open Network Ports"
    Write-Host "20: User Groups"
    Write-Host "21: Scan for Suspicious Registry Entries"  
    Write-Host "22: HDD/SSD Health" 
    Write-Host "23: Full System Audit"
    Write-Host "Q: Quit"
}

function Run-InteractiveAudit {
    $LogFilePath = "$env:USERPROFILE\Documents\SystemAuditLog.txt"

    do {
        Show-Menu
        $input = Read-Host "Please make a selection"
        switch ($input) {
            '1' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty OSInfo) }
            '2' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty CPUInfo) }
            '3' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty MemoryInfo) }
            '4' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty DiskInfo) }
            '5' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty NetworkInfo) }
            '6' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty UserAccounts) }
            '7' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty SystemServices) }
            '8' { LogAndDisplay (Get-SystemInformation | Select-Object -ExpandProperty InstalledSoftware) }
            '9' { 
                        $hardwareInventory = Get-HardwareInventory

                        Write-Host "`n=== Graphics Cards ==="
                        LogAndDisplay $hardwareInventory.GraphicsCards

                        Write-Host "`n=== Sound Devices ==="
                        LogAndDisplay $hardwareInventory.SoundDevices

                        Write-Host "`n=== Network Adapters ==="
                        LogAndDisplay $hardwareInventory.NetworkAdapters

                        Write-Host "`n=== USB Devices ==="
                        LogAndDisplay $hardwareInventory.USBDevices
                    }
            '10' { LogAndDisplay (Get-SoftwareLicensing) }
            '11' { 
                Write-Host "Gathering Event Log Summary..."
                $eventLogSummary = Get-EventLogSummary

                Write-Host "`n=== System Logs ==="
                $eventLogSummary.SystemLogs | ForEach-Object {
                    $logEntry = $_ | Format-List | Out-String -Width 4096
                    Add-Content -Path $LogFilePath -Value $logEntry
                    Write-Host $logEntry
                }

                Write-Host "`n=== Application Logs ==="
                $eventLogSummary.ApplicationLogs | ForEach-Object {
                    $logEntry = $_ | Format-List | Out-String -Width 4096
                    Add-Content -Path $LogFilePath -Value $logEntry
                    Write-Host $logEntry
                }
            }
            '12' { 
                Write-Host "Gathering Security and Update Status..."
                $securityUpdateStatus = Get-SecurityUpdateStatus
                LogAndDisplay $securityUpdateStatus   
            }
            '13' {
                Write-Host "Gathering Performance Metrics..."
                $performanceMetrics = Get-PerformanceMetrics
                LogAndDisplay $performanceMetrics
            }
            '14' {
                Write-Host "Gathering System Uptime..."
                $systemUptime = Get-SystemUptime
                LogAndDisplay $systemUptime
            }
            '15' {
                Write-Host "Gathering Running Processes..."
                $runningProcesses = Get-RunningProcesses
                LogAndDisplay $runningProcesses
            }
            '16' {
                Write-Host "Gathering Windows Update History..."
                $windowsUpdateHistory = Get-WindowsUpdateHistory
                LogAndDisplay $windowsUpdateHistory
            }
            '17' {
                Write-Host "Gathering Drivers Information..."
                $driversInformation = Get-DriversInformation
                LogAndDisplay $driversInformation
            }
            '18' {
                Write-Host "Gathering Backup Status..."
                $backupStatus = Get-BackupStatus
                LogAndDisplay $backupStatus
            }
            '19' {
                Write-Host "Gathering Open Network Ports..."
                $openPorts = Get-OpenPorts
                LogAndDisplay $openPorts
            }
            '20' {
                Write-Host "Gathering Users and their Groups..."
                $usedGroups = Get-UserGroupMemberships
                LogAndDisplay $usedGroups
            }
            '21' {
                Write-Host "Scanning for Suspicious Registry Entries..."
                $susReg = Scan-SuspiciousRegistryEntries
                LogAndDisplay $susReg
            }
            '22' {
                Write-Host "Gathering Disk Health..."
                $diskHealth = Get-DiskHealth
                LogAndDisplay $diskHealth
            }                                          
            '23' {
                Write-Host "Performing Full System Audit..."
            
                $auditReport = Get-SystemInformation
            
                $auditReport.PSObject.Properties | ForEach-Object {
                    $sectionName = $_.Name
                    $sectionData = $_.Value
            
                    Write-Host "`n=== $sectionName ==="
            
                    if ($sectionName -eq "HardwareInventory") {
                        $sectionData.PSObject.Properties | ForEach-Object {
                            $hardwareSectionName = $_.Name
                            $hardwareSectionData = $_.Value
            
                            Write-Host "`n===$hardwareSectionName==="
                            LogAndDisplay $hardwareSectionData
                        }
                    } elseif ($sectionName -eq "EventLogSummary") {
                        "SystemLogs", "ApplicationLogs" | ForEach-Object {
                            $logType = $_
                            Write-Host "`n===$logType==="
                            $sectionData.$logType | ForEach-Object {
                                $logEntry = $_ | Format-List | Out-String -Width 4096
                                Add-Content -Path $LogFilePath -Value $logEntry
                                Write-Host $logEntry
                            }
                        }
                    } else {
                        LogAndDisplay $sectionData
                    }
                }
            
                Write-Host "Gathering Backup Status..."
                LogAndDisplay (Get-BackupStatus)
                Write-Host "Gathering Open Network Ports..."
                LogAndDisplay (Get-OpenPorts)
                Write-Host "Gathering Users and their Groups..."
                LogAndDisplay (Get-UserGroupMemberships)
                Write-Host "Scanning for Suspicious Registry Entries..."
                LogAndDisplay (Scan-SuspiciousRegistryEntries)
                Write-Host "Gathering Disk Health..."
                LogAndDisplay (Get-DiskHealth)
            }
            'Q' {
                return
            }
            default {
                Write-Host "Invalid selection, please try again."
            }
        }
        if ($input -ne 'Q') {
            Write-Host "Log file saved to: $LogFilePath"
            Write-Host "Press any key to continue ..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    } while ($input -ne 'Q')
}

Run-InteractiveAudit
