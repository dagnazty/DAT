function Get-FirewallStatus {
    param (
        [string]$CsvPath = ""
    )

    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop

        $results = foreach ($fwProfile in $profiles) {
            [PSCustomObject]@{
                Profile               = $fwProfile.Name
                Enabled               = $fwProfile.Enabled
                DefaultInboundAction  = $fwProfile.DefaultInboundAction.ToString()
                DefaultOutboundAction = $fwProfile.DefaultOutboundAction.ToString()
                AllowInboundRules     = $fwProfile.AllowInboundRules.ToString()
                LogBlocked            = $fwProfile.LogBlocked.ToString()
                Status                = if ($fwProfile.Enabled) { "OK" } else { "DISABLED" }
            }
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Firewall status exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not retrieve firewall status: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve firewall status: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
