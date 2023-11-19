function Get-BackupStatus {
    try {
        $backupStatus = Get-WBBackupSet
        return $backupStatus
    } catch {
        return "Backup status could not be determined or Windows Backup is not configured."
    }
}
