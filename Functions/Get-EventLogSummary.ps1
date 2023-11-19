function Get-EventLogSummary {
    $systemLogs = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10
    $applicationLogs = Get-EventLog -LogName Application -EntryType Error,Warning -Newest 10

    return [PSCustomObject]@{
        SystemLogs = $systemLogs
        ApplicationLogs = $applicationLogs
    }
}
