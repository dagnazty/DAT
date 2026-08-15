function Get-AutorunEntries {
    param (
        [string]$CsvPath = ""
    )

    try {
        $entries = @()

        # Registry run keys
        $runKeys = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Location = "HKLM Run" },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Location = "HKLM RunOnce" },
            @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Location = "HKLM Run (32-bit)" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Location = "HKCU Run" },
            @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Location = "HKCU RunOnce" }
        )

        foreach ($key in $runKeys) {
            $props = Get-ItemProperty -Path $key.Path -ErrorAction SilentlyContinue
            if ($props) {
                foreach ($prop in $props.PSObject.Properties) {
                    if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                        $entries += [PSCustomObject]@{
                            Type     = "Registry"
                            Location = $key.Location
                            Name     = $prop.Name
                            Command  = $prop.Value
                        }
                    }
                }
            }
        }

        # Startup folders
        $startupFolders = @(
            @{ Path = [Environment]::GetFolderPath("Startup"); Location = "User Startup Folder" },
            @{ Path = [Environment]::GetFolderPath("CommonStartup"); Location = "Common Startup Folder" }
        )

        foreach ($folder in $startupFolders) {
            if ($folder.Path -and (Test-Path $folder.Path)) {
                foreach ($file in (Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue)) {
                    if ($file.Name -ne "desktop.ini") {
                        $entries += [PSCustomObject]@{
                            Type     = "Startup Folder"
                            Location = $folder.Location
                            Name     = $file.Name
                            Command  = $file.FullName
                        }
                    }
                }
            }
        }

        # Non-Microsoft scheduled tasks
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object { $_.TaskPath -notlike "\Microsoft\*" -and $_.State -ne "Disabled" }
        foreach ($task in $tasks) {
            $action = ($task.Actions | Where-Object { $_.Execute } | ForEach-Object { "$($_.Execute) $($_.Arguments)".Trim() }) -join "; "
            $entries += [PSCustomObject]@{
                Type     = "Scheduled Task"
                Location = $task.TaskPath
                Name     = $task.TaskName
                Command  = $action
            }
        }

        if ($CsvPath) {
            $entries | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Autorun entries exported to: $CsvPath"
        }

        return $entries
    } catch {
        Write-Warning "Could not retrieve autorun entries: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve autorun entries: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
