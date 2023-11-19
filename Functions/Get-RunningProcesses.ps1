function Get-RunningProcesses {
    $processes = Get-Process | Select-Object Name, Id, CPU, WorkingSet
    return $processes
}
