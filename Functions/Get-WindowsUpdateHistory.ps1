function Get-WindowsUpdateHistory {
    param (
        [string]$CsvPath = ""
    )

    $updateHistory = Get-WmiObject -Class Win32_QuickFixEngineering |
        Select-Object Description, HotFixID, InstalledOn,
            @{Name="InstalledDate"; Expression={if ($_.InstalledOn) {$_.InstalledOn.ToString("yyyy-MM-dd")} else {"Unknown"}}}

    if ($CsvPath) {
        $updateHistory | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Windows Update History exported to: $CsvPath"
    }

    return $updateHistory
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-WindowsUpdateHistory -CsvPath $CsvPath
}
