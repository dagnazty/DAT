<#
.SYNOPSIS
Custom-SecurityScan

.DESCRIPTION
Quick security spot-check: Defender real-time protection, firewall profiles, SMBv1, and local admin count.
#>
param (
    [hashtable]$Parameters = @{}
)

$findings = @()

# Defender real-time protection
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    $findings += [PSCustomObject]@{
        Check  = "Defender Real-Time Protection"
        Result = if ($mp.RealTimeProtectionEnabled) { "Enabled" } else { "DISABLED" }
        Status = if ($mp.RealTimeProtectionEnabled) { "OK" } else { "FAIL" }
    }
} catch {
    $findings += [PSCustomObject]@{ Check = "Defender Real-Time Protection"; Result = "Could not query"; Status = "UNKNOWN" }
}

# Firewall profiles
try {
    foreach ($fwProfile in (Get-NetFirewallProfile -ErrorAction Stop)) {
        $findings += [PSCustomObject]@{
            Check  = "Firewall Profile: $($fwProfile.Name)"
            Result = if ($fwProfile.Enabled) { "Enabled" } else { "DISABLED" }
            Status = if ($fwProfile.Enabled) { "OK" } else { "FAIL" }
        }
    }
} catch {
    $findings += [PSCustomObject]@{ Check = "Firewall Profiles"; Result = "Could not query"; Status = "UNKNOWN" }
}

# SMBv1
try {
    $smb = Get-SmbServerConfiguration -ErrorAction Stop
    $findings += [PSCustomObject]@{
        Check  = "SMBv1 Protocol"
        Result = if ($smb.EnableSMB1Protocol) { "ENABLED" } else { "Disabled" }
        Status = if ($smb.EnableSMB1Protocol) { "FAIL" } else { "OK" }
    }
} catch {
    $findings += [PSCustomObject]@{ Check = "SMBv1 Protocol"; Result = "Could not query"; Status = "UNKNOWN" }
}

# Local administrator count
try {
    $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
    $members = @($group.Invoke("Members")) | ForEach-Object {
        $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
    }
    $findings += [PSCustomObject]@{
        Check  = "Local Administrators"
        Result = "$($members.Count) member(s): $($members -join ', ')"
        Status = if ($members.Count -le 3) { "OK" } else { "REVIEW" }
    }
} catch {
    $findings += [PSCustomObject]@{ Check = "Local Administrators"; Result = "Could not query"; Status = "UNKNOWN" }
}

return $findings
