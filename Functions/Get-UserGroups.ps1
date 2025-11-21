function Get-UserGroupMemberships {
    param (
        [string]$CsvPath = ""
    )

    $users = Get-LocalUser
    $userGroups = foreach ($user in $users) {
        $userName = $user.Name
        try {
            $groups = Get-LocalGroup | Where-Object { $_ | Get-LocalGroupMember | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue -contains $userName }
            $groupsList = $groups.Name -join ', '
        } catch {
            $groupsList = "Unable to retrieve group memberships"
        }

        [PSCustomObject]@{
            UserName = $userName
            GroupMemberships = $groupsList
            Enabled = $user.Enabled
            Description = $user.Description
        }
    }

    if ($CsvPath) {
        $userGroups | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "User groups exported to: $CsvPath"
    }

    return $userGroups
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-UserGroupMemberships -CsvPath $CsvPath
}
