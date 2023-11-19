function Get-WindowsUpdateHistory {
    $updateHistory = Get-WmiObject -Class Win32_QuickFixEngineering | Select-Object Description, HotFixID, InstalledOn
    return $updateHistory
}
