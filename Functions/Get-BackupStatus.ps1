function Get-BackupStatus {
    param (
        [string]$CsvPath = ""
    )

    try {
        $backupStatus = Get-WBBackupSet -ErrorAction Stop |
            Select-Object BackupSetID, BackupTime, BackupTarget, VersionId

        if ($CsvPath) {
            $backupStatus | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Backup status exported to: $CsvPath"
        }

        return $backupStatus
    } catch {
        $errorMessage = "Backup status could not be determined or Windows Backup is not configured."
        Write-Warning $errorMessage

        $result = [PSCustomObject]@{
            Status = "Not Available"
            Error = $errorMessage
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Backup status error exported to: $CsvPath"
        }

        return $result
    }
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-BackupStatus -CsvPath $CsvPath
}
