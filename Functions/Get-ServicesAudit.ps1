function Get-ServicesAudit {
    param (
        [string]$CsvPath = ""
    )

    try {
        $standardAccounts = @(
            "LocalSystem",
            "NT AUTHORITY\LocalService", "NT AUTHORITY\LocalSystem", "NT AUTHORITY\NetworkService",
            "NT Authority\LocalService", "NT Authority\NetworkService"
        )

        $services = Get-CimInstance -ClassName Win32_Service -ErrorAction Stop
        $findings = @()

        foreach ($svc in $services) {
            $issues = @()

            # Unquoted service path containing spaces (privilege escalation risk)
            $path = $svc.PathName
            if ($path -and $path -notmatch '^"' -and $path -match '\.exe') {
                $exePart = ($path -split '\.exe')[0] + ".exe"
                if ($exePart -match '\s') {
                    $issues += "Unquoted service path with spaces"
                }
            }

            # Non-standard service account
            if ($svc.StartName -and ($standardAccounts -notcontains $svc.StartName)) {
                $issues += "Runs as non-standard account"
            }

            # Auto-start service that is not running
            if ($svc.StartMode -eq "Auto" -and $svc.State -ne "Running" -and -not $svc.DelayedAutoStart) {
                $issues += "Auto-start service is stopped"
            }

            if ($issues.Count -gt 0) {
                $findings += [PSCustomObject]@{
                    Name      = $svc.Name
                    DisplayName = $svc.DisplayName
                    State     = $svc.State
                    StartMode = $svc.StartMode
                    Account   = $svc.StartName
                    Issue     = $issues -join "; "
                    Path      = $svc.PathName
                }
            }
        }

        if ($findings.Count -eq 0) {
            $findings = @([PSCustomObject]@{
                Name  = "-"
                Issue = "No service issues found"
            })
        }

        if ($CsvPath) {
            $findings | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Services audit exported to: $CsvPath"
        }

        return $findings
    } catch {
        Write-Warning "Could not audit services: $_"
        $result = [PSCustomObject]@{
            Error = "Could not audit services: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
