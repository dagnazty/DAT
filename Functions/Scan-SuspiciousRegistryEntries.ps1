function Scan-SuspiciousRegistryEntries {
    param (
        [string]$CsvPath = ""
    )

    $suspiciousKeys = @(
        'HKLM:\Software\Example\Subkey',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\Suspicious',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\BadKey'
    )

    $results = @()
    foreach ($key in $suspiciousKeys) {
        try {
            $keyExists = Test-Path -Path $key -ErrorAction SilentlyContinue
            $results += [PSCustomObject]@{
                RegistryKey = $key
                Exists = $keyExists
                ScannedAt = Get-Date
            }
        } catch {
            $results += [PSCustomObject]@{
                RegistryKey = $key
                Exists = $false
                Error = $_.Exception.Message
                ScannedAt = Get-Date
            }
        }
    }

    if ($CsvPath) {
        $results | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Registry scan results exported to: $CsvPath"
    }

    return $results
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Scan-SuspiciousRegistryEntries -CsvPath $CsvPath
}
