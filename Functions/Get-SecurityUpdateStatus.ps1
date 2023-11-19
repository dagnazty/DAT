function Get-SecurityUpdateStatus {
    $defenderStatus = Get-MpComputerStatus | Select-Object -Property AMServiceEnabled, AntispywareEnabled

    $installedUpdates = Get-HotFix | Select-Object -Property Description, HotFixID, InstalledOn

    $firewallStatus = Get-NetFirewallProfile | Select-Object -Property Name, Enabled

    return [PSCustomObject]@{
        DefenderStatus = $defenderStatus
        InstalledUpdates = $installedUpdates
        FirewallStatus = $firewallStatus
    }
}
