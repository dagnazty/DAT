function Get-BitLockerStatus {
    param (
        [string]$CsvPath = ""
    )

    try {
        $volumes = Get-BitLockerVolume -ErrorAction Stop

        $results = foreach ($vol in $volumes) {
            $protectors = ($vol.KeyProtector | ForEach-Object { $_.KeyProtectorType.ToString() }) -join ", "
            [PSCustomObject]@{
                MountPoint           = $vol.MountPoint
                VolumeType           = $vol.VolumeType.ToString()
                ProtectionStatus     = $vol.ProtectionStatus.ToString()
                VolumeStatus         = $vol.VolumeStatus.ToString()
                EncryptionPercentage = $vol.EncryptionPercentage
                EncryptionMethod     = $vol.EncryptionMethod.ToString()
                KeyProtectors        = $protectors
                Status               = if ($vol.ProtectionStatus -eq 'On') { "OK" } else { "NOT PROTECTED" }
            }
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "BitLocker status exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not retrieve BitLocker status: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve BitLocker status (requires admin rights): $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
