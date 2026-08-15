function Get-InstalledSoftware {
    param (
        [string]$CsvPath = ""
    )

    try {
        $uninstallPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $software = Get-ItemProperty -Path $uninstallPaths -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.DisplayName
                    Version     = $_.DisplayVersion
                    Publisher   = $_.Publisher
                    InstallDate = $_.InstallDate
                    SizeMB      = if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1024, 1) } else { $null }
                }
            } |
            Sort-Object Name -Unique

        if ($CsvPath) {
            $software | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Installed software exported to: $CsvPath"
        }

        return $software
    } catch {
        Write-Warning "Could not retrieve installed software: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve installed software: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
