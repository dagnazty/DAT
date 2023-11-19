function Get-UserGroupMemberships {
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
        }
    }

    return $userGroups
}

Get-UserGroupMemberships | Format-Table -AutoSize
