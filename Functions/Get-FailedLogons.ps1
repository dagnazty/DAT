function Get-FailedLogons {
    param (
        [string]$CsvPath = "",
        [int]$Hours = 24
    )

    try {
        $events = @()
        try {
            $events = @(Get-WinEvent -FilterHashtable @{
                LogName = "Security"
                Id = 4625
                StartTime = (Get-Date).AddHours(-$Hours)
            } -ErrorAction Stop)
        } catch {
            if ($_.Exception.Message -match "No events were found") {
                $events = @()
            } else {
                throw
            }
        }

        if ($events.Count -eq 0) {
            $result = [PSCustomObject]@{
                Account       = "-"
                SourceIP      = "-"
                FailedCount   = 0
                Status        = "No failed logons in last $Hours hours"
            }
        } else {
            $grouped = $events | ForEach-Object {
                [PSCustomObject]@{
                    Account   = $_.Properties[5].Value
                    Domain    = $_.Properties[6].Value
                    LogonType = $_.Properties[10].Value
                    SourceIP  = $_.Properties[19].Value
                    Time      = $_.TimeCreated
                }
            } | Group-Object Account, SourceIP

            $result = foreach ($g in ($grouped | Sort-Object Count -Descending)) {
                $first = $g.Group | Sort-Object Time | Select-Object -First 1
                $last = $g.Group | Sort-Object Time | Select-Object -Last 1
                [PSCustomObject]@{
                    Account     = $first.Account
                    SourceIP    = $first.SourceIP
                    LogonType   = $first.LogonType
                    FailedCount = $g.Count
                    FirstSeen   = $first.Time
                    LastSeen    = $last.Time
                    Status      = if ($g.Count -ge 10) { "POSSIBLE BRUTE FORCE" } else { "Review" }
                }
            }
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Failed logons exported to: $CsvPath"
        }

        return $result
    } catch {
        Write-Warning "Could not retrieve failed logons: $_"
        $result = [PSCustomObject]@{
            Error = "Could not read Security event log (requires admin rights): $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
