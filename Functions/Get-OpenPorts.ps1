function Get-OpenPorts {
    $ports = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' } | Select-Object -Property LocalPort -Unique
    return $ports
}
