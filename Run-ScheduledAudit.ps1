param (
    [Parameter(Mandatory)]
    [string]$TaskName,
    [string]$OutputDirectory = "$env:USERPROFILE\Documents\DAT_Scheduled",
    [string]$CsvPath = "",
    [string]$HtmlPath = "",
    [switch]$EnableEmailAlerts,
    [string[]]$AlertChannels = @("EventLog"),
    [string[]]$EnabledChecks = @("SystemUptime", "PerformanceMetrics", "SecurityUpdateStatus")
)

# Ensure output directory exists
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

# Load configuration and functions
$configPath = "$PSScriptRoot\Config\DefaultConfig.json"
$config = $null
if (Test-Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not load configuration: $_"
    }
}

# Dot source required functions
. "$PSScriptRoot\Functions\Get-Configuration.ps1"
. "$PSScriptRoot\Functions\Send-Alert.ps1"

# Load enabled check functions
$functionMap = @{
    "SystemUptime" = "Get-SystemUptime"
    "RunningProcesses" = "Get-RunningProcesses"
    "PerformanceMetrics" = "Get-PerformanceMetrics"
    "HardwareInventory" = "Get-HardwareInventory"
    "EventLogSummary" = "Get-EventLogSummary"
    "SecurityUpdateStatus" = "Get-SecurityUpdateStatus"
    "SoftwareLicensing" = "Get-SoftwareLicensing"
    "WindowsUpdateHistory" = "Get-WindowsUpdateHistory"
    "DriversInformation" = "Get-DriversInformation"
    "BackupStatus" = "Get-BackupStatus"
    "OpenPorts" = "Get-OpenPorts"
    "UserGroups" = "Get-UserGroupMemberships"
    "RegistryScan" = "Scan-SuspiciousRegistryEntries"
    "DiskHealth" = "Get-DiskHealth"
    "FirewallStatus" = "Get-FirewallStatus"
    "BitLockerStatus" = "Get-BitLockerStatus"
    "InstalledSoftware" = "Get-InstalledSoftware"
    "PendingReboot" = "Get-PendingReboot"
    "Autoruns" = "Get-AutorunEntries"
    "ServicesAudit" = "Get-ServicesAudit"
    "DefenderHealth" = "Get-DefenderHealth"
    "InsecureProtocols" = "Get-InsecureProtocols"
    "CertificateExpiry" = "Get-CertificateExpiry"
    "FailedLogons" = "Get-FailedLogons"
    "USBHistory" = "Get-USBHistory"
    "PrivilegedAccounts" = "Get-PrivilegedAccounts"
    "SharesAudit" = "Get-SharesAudit"
}

# Load required functions
foreach ($check in $EnabledChecks) {
    if ($functionMap.ContainsKey($check)) {
        $functionFile = "$PSScriptRoot\Functions\$($functionMap[$check]).ps1"
        if (Test-Path $functionFile) {
            . $functionFile
        }
    }
}

# Generate timestamp for this run
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runIdentifier = "${TaskName}_$timestamp"

# Initialize results collection
$auditResults = @{}
$alertsTriggered = @()

Write-Host "Starting scheduled audit: $TaskName at $(Get-Date)"

# Execute enabled checks
foreach ($check in $EnabledChecks) {
    Write-Host "Running check: $check"

    try {
        $functionName = $functionMap[$check]

        # Execute the function
        $result = & $functionName

        # Store result
        $auditResults[$check] = $result

        # Check for issues that should trigger alerts
        $alertTriggered = $false

        switch ($check) {
            "SecurityUpdateStatus" {
                if ($result.DefenderStatus -and -not $result.DefenderStatus.RealTimeProtectionEnabled) {
                    $alertsTriggered += @{
                        Severity = "Critical"
                        Subject = "Windows Defender Real-time Protection Disabled"
                        Message = "Windows Defender real-time protection is disabled on $($env:COMPUTERNAME)"
                    }
                    $alertTriggered = $true
                }
            }
            "PerformanceMetrics" {
                $cpuThreshold = if ($config) { $config.thresholds.cpuUsageCritical } else { 90 }
                if ($result.CPUUsagePercent -gt $cpuThreshold) {
                    $alertsTriggered += @{
                        Severity = "Warning"
                        Subject = "High CPU Usage Detected"
                        Message = "CPU usage is $($result.CPUUsagePercent)% on $($env:COMPUTERNAME) (threshold: $cpuThreshold%)"
                    }
                    $alertTriggered = $true
                }

                $memoryThreshold = if ($config) { $config.thresholds.memoryUsageCritical } else { 95 }
                if ($result.MemoryUsagePercent -gt $memoryThreshold) {
                    $alertsTriggered += @{
                        Severity = "Warning"
                        Subject = "High Memory Usage Detected"
                        Message = "Memory usage is $($result.MemoryUsagePercent)% on $($env:COMPUTERNAME) (threshold: $memoryThreshold%)"
                    }
                    $alertTriggered = $true
                }
            }
            "FirewallStatus" {
                $disabledProfiles = @($result | Where-Object { $_.Status -eq "DISABLED" })
                if ($disabledProfiles.Count -gt 0) {
                    $profileNames = ($disabledProfiles | ForEach-Object { $_.Profile }) -join ", "
                    $alertsTriggered += @{
                        Severity = "Critical"
                        Subject = "Windows Firewall Profile Disabled"
                        Message = "Firewall disabled for profile(s): $profileNames on $($env:COMPUTERNAME)"
                    }
                    $alertTriggered = $true
                }
            }
            "DefenderHealth" {
                if ($result.RealTimeProtectionEnabled -eq $false) {
                    $alertsTriggered += @{
                        Severity = "Critical"
                        Subject = "Defender Real-time Protection Disabled"
                        Message = "Windows Defender real-time protection is disabled on $($env:COMPUTERNAME)"
                    }
                    $alertTriggered = $true
                }
                elseif ($result.SignatureAgeDays -gt 7) {
                    $alertsTriggered += @{
                        Severity = "Warning"
                        Subject = "Defender Signatures Outdated"
                        Message = "Defender signatures are $($result.SignatureAgeDays) days old on $($env:COMPUTERNAME)"
                    }
                    $alertTriggered = $true
                }
            }
            "FailedLogons" {
                $bruteForce = @($result | Where-Object { $_.Status -eq "POSSIBLE BRUTE FORCE" })
                if ($bruteForce.Count -gt 0) {
                    $accounts = ($bruteForce | ForEach-Object { "$($_.Account) ($($_.FailedCount)x from $($_.SourceIP))" }) -join ", "
                    $alertsTriggered += @{
                        Severity = "Critical"
                        Subject = "Possible Brute Force Attack"
                        Message = "High failed-logon counts on $($env:COMPUTERNAME): $accounts"
                    }
                    $alertTriggered = $true
                }
            }
            "PendingReboot" {
                if ($result.RebootPending) {
                    $alertsTriggered += @{
                        Severity = "Warning"
                        Subject = "Reboot Pending"
                        Message = "$($env:COMPUTERNAME) has a pending reboot (CBS: $($result.ComponentServicing), WU: $($result.WindowsUpdate), FileRename: $($result.PendingFileRename))"
                    }
                    $alertTriggered = $true
                }
            }
            "EventLogSummary" {
                $errorThreshold = if ($config) { $config.thresholds.eventLogErrorsMax } else { 10 }
                $totalErrors = ($result.SystemLogs | Where-Object { $_.EntryType -eq "Error" }).Count +
                              ($result.ApplicationLogs | Where-Object { $_.EntryType -eq "Error" }).Count

                if ($totalErrors -gt $errorThreshold) {
                    $alertsTriggered += @{
                        Severity = "Warning"
                        Subject = "High Error Count in Event Logs"
                        Message = "$totalErrors errors found in event logs on $($env:COMPUTERNAME) (threshold: $errorThreshold)"
                    }
                    $alertTriggered = $true
                }
            }
        }

        if (-not $alertTriggered) {
            Write-Host "[OK] $check completed successfully"
        }

    } catch {
        Write-Error "Failed to execute $check`: $_"
        $auditResults[$check] = [PSCustomObject]@{
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

# Generate CSV export if requested
if ($CsvPath) {
    $actualCsvPath = if ($CsvPath -eq "auto") {
        "$OutputDirectory\$runIdentifier.csv"
    } else {
        $CsvPath
    }

    # Flatten results for CSV export
    $csvData = @()
    foreach ($check in $auditResults.Keys) {
        $result = $auditResults[$check]
        if ($result -is [PSCustomObject] -and -not $result.PSObject.Properties['Error']) {
            $csvData += [PSCustomObject]@{
                CheckName = $check
                Timestamp = Get-Date
                Hostname = $env:COMPUTERNAME
                Data = ($result | ConvertTo-Json -Compress)
            }
        }
    }

    if ($csvData) {
        $csvData | Export-Csv -Path $actualCsvPath -NoTypeInformation
        Write-Host "CSV results exported to: $actualCsvPath"
    }
}

# Generate HTML report if requested
if ($HtmlPath) {
    $actualHtmlPath = if ($HtmlPath -eq "auto") {
        "$OutputDirectory\$runIdentifier.html"
    } else {
        $HtmlPath
    }

    # Load HTML report function if available
    $htmlFunctionPath = "$PSScriptRoot\Functions\New-HTMLReport.ps1"
    if (Test-Path $htmlFunctionPath) {
        . $htmlFunctionPath
        New-HTMLReport -OutputPath $actualHtmlPath -AuditData $auditResults
    }
}

# Send alerts if any were triggered and alerting is enabled
if ($alertsTriggered -and ($EnableEmailAlerts -or $AlertChannels)) {
    foreach ($alert in $alertsTriggered) {
        $channels = if ($EnableEmailAlerts) { $AlertChannels + "Email" } else { $AlertChannels }
        Send-Alert -Subject $alert.Subject -Message $alert.Message -Severity $alert.Severity -Channels $channels -Config $config
    }
}

# Log completion
$completionMessage = "Scheduled audit '$TaskName' completed at $(Get-Date). Processed $($EnabledChecks.Count) checks."
if ($alertsTriggered) {
    $completionMessage += " $($alertsTriggered.Count) alerts triggered."
}

Write-Host $completionMessage

# Log to file
$logPath = "$OutputDirectory\AuditLog.txt"
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $completionMessage"
Add-Content -Path $logPath -Value $logEntry

# Clean up old files (keep last 30 days)
$oldFiles = Get-ChildItem -Path $OutputDirectory -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }

if ($oldFiles) {
    $oldFiles | Remove-Item -Force
    Write-Host "Cleaned up $($oldFiles.Count) old files"
}

Write-Host "Scheduled audit completed successfully."
