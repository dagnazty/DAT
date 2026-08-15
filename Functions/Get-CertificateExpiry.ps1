function Get-CertificateExpiry {
    param (
        [string]$CsvPath = "",
        [int]$WarningDays = 30
    )

    try {
        $certs = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction Stop

        if ($certs.Count -eq 0) {
            $results = [PSCustomObject]@{
                Subject   = "-"
                Status    = "No certificates in LocalMachine\My store"
            }
        } else {
            $results = foreach ($cert in ($certs | Sort-Object NotAfter)) {
                $daysRemaining = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)
                [PSCustomObject]@{
                    Subject       = $cert.Subject
                    Issuer        = $cert.Issuer
                    Thumbprint    = $cert.Thumbprint
                    NotAfter      = $cert.NotAfter
                    DaysRemaining = $daysRemaining
                    HasPrivateKey = $cert.HasPrivateKey
                    Status        = if ($daysRemaining -lt 0) { "EXPIRED" }
                                    elseif ($daysRemaining -le $WarningDays) { "EXPIRING SOON" }
                                    else { "OK" }
                }
            }
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Certificate expiry exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not audit certificates: $_"
        $result = [PSCustomObject]@{
            Error = "Could not audit certificates: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
