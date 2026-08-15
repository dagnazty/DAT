function Get-InsecureProtocols {
    param (
        [string]$CsvPath = ""
    )

    try {
        $results = @()

        # SMBv1
        try {
            $smb = Get-SmbServerConfiguration -ErrorAction Stop
            $results += [PSCustomObject]@{
                Setting = "SMBv1 Protocol"
                State   = if ($smb.EnableSMB1Protocol) { "Enabled" } else { "Disabled" }
                Risk    = if ($smb.EnableSMB1Protocol) { "WARNING" } else { "OK" }
                Detail  = "Legacy protocol vulnerable to known exploits (e.g. EternalBlue)"
            }
        } catch {
            $results += [PSCustomObject]@{
                Setting = "SMBv1 Protocol"; State = "Unknown"; Risk = "UNKNOWN"
                Detail  = "Could not query SMB server configuration"
            }
        }

        # RDP enabled / NLA
        $rdpDeny = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -ErrorAction SilentlyContinue).fDenyTSConnections
        $rdpEnabled = ($rdpDeny -eq 0)
        $results += [PSCustomObject]@{
            Setting = "Remote Desktop"
            State   = if ($rdpEnabled) { "Enabled" } else { "Disabled" }
            Risk    = "INFO"
            Detail  = "RDP exposure - verify it is expected"
        }

        if ($rdpEnabled) {
            $nla = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -ErrorAction SilentlyContinue).UserAuthentication
            $results += [PSCustomObject]@{
                Setting = "RDP Network Level Authentication"
                State   = if ($nla -eq 1) { "Enabled" } else { "Disabled" }
                Risk    = if ($nla -eq 1) { "OK" } else { "WARNING" }
                Detail  = "NLA blocks pre-auth attacks against RDP"
            }
        }

        # Legacy TLS server-side
        foreach ($tlsVersion in @("TLS 1.0", "TLS 1.1")) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$tlsVersion\Server"
            $enabled = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).Enabled
            if ($null -eq $enabled) {
                $state = "Not configured (OS default)"
                $risk = "INFO"
            } elseif ($enabled -eq 0) {
                $state = "Disabled"
                $risk = "OK"
            } else {
                $state = "Enabled"
                $risk = "WARNING"
            }
            $results += [PSCustomObject]@{
                Setting = "$tlsVersion (server)"
                State   = $state
                Risk    = $risk
                Detail  = "Deprecated TLS version"
            }
        }

        # LLMNR
        $llmnr = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue).EnableMulticast
        $results += [PSCustomObject]@{
            Setting = "LLMNR"
            State   = if ($llmnr -eq 0) { "Disabled by policy" } else { "Enabled (default)" }
            Risk    = if ($llmnr -eq 0) { "OK" } else { "WARNING" }
            Detail  = "Multicast name resolution enables credential-relay attacks on untrusted networks"
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Insecure protocols audit exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not audit protocols: $_"
        $result = [PSCustomObject]@{
            Error = "Could not audit protocols: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
