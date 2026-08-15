function Get-SharesAudit {
    param (
        [string]$CsvPath = ""
    )

    try {
        $defaultShares = @("ADMIN$", "C$", "D$", "E$", "IPC$", "print$")
        $shares = Get-SmbShare -ErrorAction Stop

        $results = foreach ($share in $shares) {
            $everyoneAccess = "-"
            $risk = "OK"

            try {
                $access = Get-SmbShareAccess -Name $share.Name -ErrorAction Stop
                $everyone = $access | Where-Object { $_.AccountName -match "Everyone|Todos|Tout le monde" }
                if ($everyone) {
                    $everyoneAccess = ($everyone | ForEach-Object { $_.AccessRight.ToString() }) -join ", "
                    if (($defaultShares -notcontains $share.Name) -and ($everyoneAccess -match "Full|Change")) {
                        $risk = "WARNING"
                    }
                }
            } catch {
                $everyoneAccess = "Could not read ACL"
            }

            [PSCustomObject]@{
                Name           = $share.Name
                Path           = $share.Path
                Description    = $share.Description
                DefaultShare   = ($defaultShares -contains $share.Name)
                EveryoneAccess = $everyoneAccess
                Risk           = $risk
            }
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Shares audit exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not audit shares: $_"
        $result = [PSCustomObject]@{
            Error = "Could not audit SMB shares: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
