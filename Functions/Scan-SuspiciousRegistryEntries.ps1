function Scan-SuspiciousRegistryEntries {
    $suspiciousKey = Get-ItemProperty 'HKLM:\Software\Example\Subkey' -ErrorAction SilentlyContinue
    $isSuspiciousKeyPresent = $null -ne $suspiciousKey

    return [PSCustomObject]@{
        SuspiciousRegistryKeyPresent = $isSuspiciousKeyPresent
    }
}
