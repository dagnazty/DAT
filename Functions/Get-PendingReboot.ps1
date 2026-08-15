function Get-PendingReboot {
    param (
        [string]$CsvPath = ""
    )

    try {
        $cbsPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        $wuPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

        $fileRenamePending = $false
        $sessionManager = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -ErrorAction SilentlyContinue
        if ($sessionManager -and $sessionManager.PendingFileRenameOperations) {
            $fileRenamePending = $true
        }

        $computerRenamePending = $false
        $activeName = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -ErrorAction SilentlyContinue).ComputerName
        $pendingName = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -ErrorAction SilentlyContinue).ComputerName
        if ($activeName -and $pendingName -and ($activeName -ne $pendingName)) {
            $computerRenamePending = $true
        }

        $rebootPending = $cbsPending -or $wuPending -or $fileRenamePending -or $computerRenamePending

        $result = [PSCustomObject]@{
            RebootPending         = $rebootPending
            ComponentServicing    = $cbsPending
            WindowsUpdate         = $wuPending
            PendingFileRename     = $fileRenamePending
            ComputerRenamePending = $computerRenamePending
            Status                = if ($rebootPending) { "REBOOT PENDING" } else { "OK" }
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Pending reboot status exported to: $CsvPath"
        }

        return $result
    } catch {
        Write-Warning "Could not check pending reboot: $_"
        $result = [PSCustomObject]@{
            Error = "Could not check pending reboot: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
