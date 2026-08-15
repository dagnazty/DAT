function Get-PrivilegedAccounts {
    param (
        [string]$CsvPath = "",
        [int]$StaleDays = 90
    )

    try {
        $findings = @()

        # Members of the local Administrators group (ADSI is reliable even with orphaned SIDs)
        try {
            $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
            $members = @($group.Invoke("Members")) | ForEach-Object {
                $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
            }
            foreach ($member in $members) {
                $findings += [PSCustomObject]@{
                    Finding = "Administrators member"
                    Account = $member
                    Detail  = "Member of local Administrators group"
                }
            }
        } catch {
            $findings += [PSCustomObject]@{
                Finding = "Administrators member"
                Account = "-"
                Detail  = "Could not enumerate group: $($_.Exception.Message)"
            }
        }

        # Local account hygiene
        try {
            foreach ($user in (Get-LocalUser -ErrorAction Stop)) {
                if ($user.Enabled -and $user.PasswordExpires -eq $null -and -not $user.PasswordRequired) {
                    $findings += [PSCustomObject]@{
                        Finding = "No password required"
                        Account = $user.Name
                        Detail  = "Enabled account does not require a password"
                    }
                }
                elseif ($user.Enabled -and $user.PasswordExpires -eq $null) {
                    $findings += [PSCustomObject]@{
                        Finding = "Password never expires"
                        Account = $user.Name
                        Detail  = "Enabled account with non-expiring password"
                    }
                }

                if ($user.Enabled -and $user.LastLogon -and $user.LastLogon -lt (Get-Date).AddDays(-$StaleDays)) {
                    $findings += [PSCustomObject]@{
                        Finding = "Stale account"
                        Account = $user.Name
                        Detail  = "Enabled but last logon was $($user.LastLogon)"
                    }
                }
            }
        } catch {
            $findings += [PSCustomObject]@{
                Finding = "Local users"
                Account = "-"
                Detail  = "Could not enumerate local users: $($_.Exception.Message)"
            }
        }

        if ($CsvPath) {
            $findings | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Privileged accounts audit exported to: $CsvPath"
        }

        return $findings
    } catch {
        Write-Warning "Could not audit privileged accounts: $_"
        $result = [PSCustomObject]@{
            Error = "Could not audit privileged accounts: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
