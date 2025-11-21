function Get-EventLogSummary {
    param (
        [string]$CsvPath = "",
        [int]$MaxEntries = 10
    )

    $systemLogs = Get-EventLog -LogName System -EntryType Error,Warning -Newest $MaxEntries |
        Select-Object TimeGenerated, EntryType, Source, EventID, Message
    $applicationLogs = Get-EventLog -LogName Application -EntryType Error,Warning -Newest $MaxEntries |
        Select-Object TimeGenerated, EntryType, Source, EventID, Message

    $result = [PSCustomObject]@{
        SystemLogs = $systemLogs
        ApplicationLogs = $applicationLogs
    }

    if ($CsvPath) {
        # Create directory if it doesn't exist
        $directory = Split-Path -Path $CsvPath -Parent
        if ([string]::IsNullOrEmpty($directory)) {
            $directory = "."
        }
        if (-not (Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        # Export each log type to separate CSV files
        $systemLogPath = Join-Path -Path $directory -ChildPath "EventLog_System.csv"
        $applicationLogPath = Join-Path -Path $directory -ChildPath "EventLog_Application.csv"

        $systemLogs | Export-Csv -Path $systemLogPath -NoTypeInformation
        Write-Host "Exported System logs to: $systemLogPath"

        $applicationLogs | Export-Csv -Path $applicationLogPath -NoTypeInformation
        Write-Host "Exported Application logs to: $applicationLogPath"
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $CsvPath = ""
    $MaxEntries = 10
    
    if ($args.Count -gt 0) {
        for ($i = 0; $i -lt $args.Count; $i++) {
            if ($args[$i] -eq "-CsvPath" -and $i + 1 -lt $args.Count) {
                $CsvPath = $args[$i + 1]
            }
            if ($args[$i] -eq "-MaxEntries" -and $i + 1 -lt $args.Count) {
                $MaxEntries = $args[$i + 1]
            }
        }
    }
    
    Get-EventLogSummary -CsvPath $CsvPath -MaxEntries $MaxEntries
}
