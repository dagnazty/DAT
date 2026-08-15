# DAT - Standalone Function Examples
# This script demonstrates how to use each audit function independently

# Load all functions
. ".\Functions\Export-ToCSV.ps1"
. ".\Functions\Get-SystemUptime.ps1"
. ".\Functions\Get-RunningProcesses.ps1"
. ".\Functions\Get-PerformanceMetrics.ps1"
. ".\Functions\Get-HardwareInventory.ps1"
. ".\Functions\Get-EventLogSummary.ps1"
. ".\Functions\Get-SecurityUpdateStatus.ps1"
. ".\Functions\Get-SoftwareLicensing.ps1"
. ".\Functions\Get-WindowsUpdateHistory.ps1"
. ".\Functions\Get-DriversInformation.ps1"
. ".\Functions\Get-BackupStatus.ps1"
. ".\Functions\Get-OpenPorts.ps1"
. ".\Functions\Get-UserGroups.ps1"
. ".\Functions\Scan-SuspiciousRegistryEntries.ps1"
. ".\Functions\Get-DiskHealth.ps1"

# Example 1: Run a single function and display results
Write-Host "=== Example 1: Get System Uptime ==="
$result = Get-SystemUptime
$result

# Example 2: Run a function and export to CSV
Write-Host "`n=== Example 2: Get System Uptime with CSV Export ==="
Get-SystemUptime -CsvPath "SystemUptime.csv"

# Example 3: Run multiple functions with CSV export
Write-Host "`n=== Example 3: Run Multiple Functions with CSV Export ==="
$exportPath = "AuditResults_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $exportPath -Force | Out-Null

Get-RunningProcesses -CsvPath "$exportPath\RunningProcesses.csv"
Get-PerformanceMetrics -CsvPath "$exportPath\PerformanceMetrics.csv"
Get-HardwareInventory -CsvPath "$exportPath\HardwareInventory.csv"

Write-Host "Results exported to: $exportPath"

# Example 4: Run a function that returns complex data
Write-Host "`n=== Example 4: Get Hardware Inventory (Complex Data) ==="
$hardware = Get-HardwareInventory
Write-Host "Graphics Cards:"
$hardware.GraphicsCards | Format-Table -AutoSize
Write-Host "Network Adapters:"
$hardware.NetworkAdapters | Format-Table -AutoSize
