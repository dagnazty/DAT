function Get-OpenPorts {
    param (
        [string]$CsvPath = ""
    )

    try {
        $ports = Get-NetTCPConnection -ErrorAction Stop |
            Where-Object { $_.State -eq 'Listen' } |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess,
                @{Name="ProcessName"; Expression={try {(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName} catch {"Unknown"}}} |
            Sort-Object LocalPort -Unique

        if ($CsvPath) {
            $ports | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Open ports exported to: $CsvPath"
        }

        return $ports
    } catch {
        Write-Warning "Could not retrieve open ports: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve open ports information"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Open ports error exported to: $CsvPath"
        }

        return $result
    }
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-OpenPorts -CsvPath $CsvPath
}
