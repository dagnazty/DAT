function Get-DefenderHealth {
    param (
        [string]$CsvPath = ""
    )

    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop

        $issues = @()
        if (-not $mp.RealTimeProtectionEnabled) { $issues += "Real-time protection disabled" }
        if (-not $mp.AntivirusEnabled) { $issues += "Antivirus disabled" }
        if ($mp.AntivirusSignatureAge -gt 7) { $issues += "Signatures $($mp.AntivirusSignatureAge) days old" }

        $result = [PSCustomObject]@{
            AntivirusEnabled           = $mp.AntivirusEnabled
            RealTimeProtectionEnabled  = $mp.RealTimeProtectionEnabled
            BehaviorMonitorEnabled     = $mp.BehaviorMonitorEnabled
            TamperProtectionEnabled    = $mp.IsTamperProtected
            SignatureAgeDays           = $mp.AntivirusSignatureAge
            SignatureLastUpdated       = $mp.AntivirusSignatureLastUpdated
            LastQuickScan              = $mp.QuickScanEndTime
            LastFullScan               = $mp.FullScanEndTime
            Status                     = if ($issues.Count -eq 0) { "OK" } else { $issues -join "; " }
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Defender health exported to: $CsvPath"
        }

        return $result
    } catch {
        Write-Warning "Could not retrieve Defender health: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve Defender health: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
