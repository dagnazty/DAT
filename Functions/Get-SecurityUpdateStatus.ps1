function Get-SecurityUpdateStatus {
    param (
        [string]$CsvPath = ""
    )

    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue |
            Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled,
                RealTimeProtectionEnabled, BehaviorMonitorEnabled
    } catch {
        Write-Warning "Windows Defender status could not be retrieved: $_"
        $defenderStatus = [PSCustomObject]@{
            AMServiceEnabled = $false
            AntispywareEnabled = $false
            AntivirusEnabled = $false
            RealTimeProtectionEnabled = $false
            BehaviorMonitorEnabled = $false
        }
    }

    $installedUpdates = Get-HotFix |
        Select-Object Description, HotFixID,
            @{Name="InstalledDate"; Expression={if ($_.InstalledOn) {$_.InstalledOn.ToString("yyyy-MM-dd")} else {"Unknown"}}}

    try {
        $firewallStatus = Get-NetFirewallProfile -ErrorAction SilentlyContinue |
            Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    } catch {
        Write-Warning "Firewall status could not be retrieved: $_"
        $firewallStatus = [PSCustomObject]@{
            Name = "Firewall"
            Enabled = $false
            DefaultInboundAction = "Unknown"
            DefaultOutboundAction = "Unknown"
        }
    }

    $result = [PSCustomObject]@{
        DefenderStatus = $defenderStatus
        InstalledUpdates = $installedUpdates
        FirewallStatus = $firewallStatus
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

        # Export each security section to separate CSV files
        $defenderPath = Join-Path -Path $directory -ChildPath "Security_DefenderStatus.csv"
        $defenderStatus | Export-Csv -Path $defenderPath -NoTypeInformation
        Write-Host "Exported Defender status to: $defenderPath"

        $updatesPath = Join-Path -Path $directory -ChildPath "Security_InstalledUpdates.csv"
        $installedUpdates | Export-Csv -Path $updatesPath -NoTypeInformation
        Write-Host "Exported installed updates to: $updatesPath"

        $firewallPath = Join-Path -Path $directory -ChildPath "Security_FirewallStatus.csv"
        $firewallStatus | Export-Csv -Path $firewallPath -NoTypeInformation
        Write-Host "Exported firewall status to: $firewallPath"
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-SecurityUpdateStatus -CsvPath $CsvPath
}
