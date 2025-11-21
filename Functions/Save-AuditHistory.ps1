# Historical Data Storage and Analysis
# Stores audit results over time and provides trend analysis

function Save-AuditHistory {
    <#
    .SYNOPSIS
    Saves audit results to historical database for trend analysis.
    
    .DESCRIPTION
    Stores audit results in a SQLite database or CSV files for historical tracking and trend analysis.
    
    .PARAMETER AuditData
    Hashtable of audit results to store.
    
    .PARAMETER DatabasePath
    Path to the history database directory (default: .\History\).
    
    .PARAMETER RetentionDays
    Number of days to retain historical data (default: 90).
    
    .EXAMPLE
    Save-AuditHistory -AuditData $auditResults
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$AuditData,
        
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath = ".\History",
        
        [Parameter(Mandatory=$false)]
        [int]$RetentionDays = 90
    )
    
    # Create history directory if it doesn't exist
    if (-not (Test-Path $DatabasePath)) {
        New-Item -Path $DatabasePath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date
    $dateString = $timestamp.ToString("yyyyMMdd_HHmmss")
    
    Write-Host "Saving audit history..." -ForegroundColor Cyan
    
    foreach ($funcName in $AuditData.Keys) {
        $funcData = $AuditData[$funcName]
        
        # Create function-specific history file
        $historyFile = Join-Path -Path $DatabasePath -ChildPath "$funcName`_History.csv"
        
        # Prepare data with timestamp
        $historyEntry = @{
            Timestamp = $timestamp
            Status = $funcData.Status
            Data = $funcData.Data | ConvertTo-Json -Compress
        }
        
        # Append to history file
        $historyEntry | Export-Csv -Path $historyFile -NoTypeInformation -Append
        
        Write-Host "  - Saved $funcName history" -ForegroundColor Gray
    }
    
    # Clean up old history (retention policy)
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Write-Host "Cleaning up history older than $RetentionDays days..." -ForegroundColor Yellow
    
    $historyFiles = Get-ChildItem -Path $DatabasePath -Filter "*_History.csv"
    foreach ($file in $historyFiles) {
        try {
            $history = Import-Csv -Path $file.FullName
            $recentHistory = $history | Where-Object { [DateTime]$_.Timestamp -gt $cutoffDate }
            
            if ($recentHistory.Count -lt $history.Count) {
                $removed = $history.Count - $recentHistory.Count
                $recentHistory | Export-Csv -Path $file.FullName -NoTypeInformation
                Write-Host "  - Removed $removed old entries from $($file.Name)" -ForegroundColor Gray
            }
        } catch {
            Write-Warning "Failed to clean up $($file.Name): $_"
        }
    }
    
    Write-Host "Audit history saved successfully!" -ForegroundColor Green
}

function Get-AuditTrends {
    <#
    .SYNOPSIS
    Analyzes historical audit data for trends.
    
    .DESCRIPTION
    Retrieves and analyzes historical audit data to identify trends, patterns, and anomalies.
    
    .PARAMETER FunctionName
    Name of the audit function to analyze (e.g., "Get-PerformanceMetrics").
    
    .PARAMETER DatabasePath
    Path to the history database directory (default: .\History\).
    
    .PARAMETER Days
    Number of days of history to analyze (default: 30).
    
    .PARAMETER CsvPath
    Optional path to export trend analysis to CSV.
    
    .EXAMPLE
    Get-AuditTrends -FunctionName "Get-PerformanceMetrics" -Days 30
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath = ".\History",
        
        [Parameter(Mandatory=$false)]
        [int]$Days = 30,
        
        [Parameter(Mandatory=$false)]
        [string]$CsvPath = ""
    )
    
    $historyFile = Join-Path -Path $DatabasePath -ChildPath "$FunctionName`_History.csv"
    
    if (-not (Test-Path $historyFile)) {
        Write-Host "No historical data found for $FunctionName" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Trend Analysis: $FunctionName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Load history
    $history = Import-Csv -Path $historyFile
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $recentHistory = $history | Where-Object { [DateTime]$_.Timestamp -gt $cutoffDate }
    
    Write-Host "Analyzing $($recentHistory.Count) data points from the last $Days days..." -ForegroundColor Yellow
    Write-Host ""
    
    # Parse data and calculate trends
    $trends = @()
    
    foreach ($entry in $recentHistory) {
        try {
            $data = $entry.Data | ConvertFrom-Json
            
            # Extract numeric metrics for trend analysis
            $metrics = @{}
            foreach ($prop in $data.PSObject.Properties) {
                if ($prop.Value -is [int] -or $prop.Value -is [double] -or $prop.Value -is [long]) {
                    $metrics[$prop.Name] = $prop.Value
                }
            }
            
            $trendEntry = [PSCustomObject]@{
                Timestamp = [DateTime]$entry.Timestamp
                Status = $entry.Status
            }
            
            foreach ($key in $metrics.Keys) {
                $trendEntry | Add-Member -MemberType NoteProperty -Name $key -Value $metrics[$key]
            }
            
            $trends += $trendEntry
        } catch {
            Write-Warning "Failed to parse entry: $_"
        }
    }
    
    if ($trends.Count -eq 0) {
        Write-Host "No trend data available for analysis." -ForegroundColor Yellow
        return $null
    }
    
    # Calculate statistics
    Write-Host "Trend Statistics:" -ForegroundColor Green
    Write-Host ""
    
    $numericProperties = $trends[0].PSObject.Properties | Where-Object { $_.Value -is [int] -or $_.Value -is [double] -or $_.Value -is [long] }
    
    $statistics = @()
    foreach ($prop in $numericProperties) {
        $propName = $prop.Name
        $values = $trends | ForEach-Object { $_.$propName }
        
        $min = ($values | Measure-Object -Minimum).Minimum
        $max = ($values | Measure-Object -Maximum).Maximum
        $avg = ($values | Measure-Object -Average).Average
        
        $stat = [PSCustomObject]@{
            Metric = $propName
            Minimum = $min
            Maximum = $max
            Average = [math]::Round($avg, 2)
            Current = $values[-1]
            Trend = if ($values[-1] -gt $avg) { "Above Average" } elseif ($values[-1] -lt $avg) { "Below Average" } else { "Average" }
        }
        
        $statistics += $stat
        
        Write-Host "  $propName" -ForegroundColor Cyan
        Write-Host "    Min: $min | Max: $max | Avg: $([math]::Round($avg, 2)) | Current: $($values[-1])" -ForegroundColor Gray
        Write-Host "    Trend: $($stat.Trend)" -ForegroundColor $(if ($stat.Trend -eq "Above Average") { "Yellow" } else { "Gray" })
        Write-Host ""
    }
    
    # Export if requested
    if ($CsvPath) {
        try {
            $statistics | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Trend analysis exported to: $CsvPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to export trend analysis: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    
    return $statistics
}

function Get-AuditHistory {
    <#
    .SYNOPSIS
    Retrieves historical audit data.
    
    .DESCRIPTION
    Retrieves historical audit data for a specific function or all functions.
    
    .PARAMETER FunctionName
    Name of the audit function to retrieve history for. If not specified, retrieves all.
    
    .PARAMETER DatabasePath
    Path to the history database directory (default: .\History\).
    
    .PARAMETER Days
    Number of days of history to retrieve (default: 30).
    
    .EXAMPLE
    Get-AuditHistory -FunctionName "Get-SystemUptime" -Days 7
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$FunctionName = "",
        
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath = ".\History",
        
        [Parameter(Mandatory=$false)]
        [int]$Days = 30
    )
    
    if (-not (Test-Path $DatabasePath)) {
        Write-Host "No history database found at $DatabasePath" -ForegroundColor Yellow
        return $null
    }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    
    if ($FunctionName) {
        $historyFile = Join-Path -Path $DatabasePath -ChildPath "$FunctionName`_History.csv"
        if (Test-Path $historyFile) {
            $history = Import-Csv -Path $historyFile
            return $history | Where-Object { [DateTime]$_.Timestamp -gt $cutoffDate }
        } else {
            Write-Host "No history found for $FunctionName" -ForegroundColor Yellow
            return $null
        }
    } else {
        # Get all history files
        $historyFiles = Get-ChildItem -Path $DatabasePath -Filter "*_History.csv"
        $allHistory = @()
        
        foreach ($file in $historyFiles) {
            $funcName = $file.BaseName -replace '_History$', ''
            $history = Import-Csv -Path $file.FullName
            $recentHistory = $history | Where-Object { [DateTime]$_.Timestamp -gt $cutoffDate }
            
            foreach ($entry in $recentHistory) {
                $entry | Add-Member -MemberType NoteProperty -Name "FunctionName" -Value $funcName -Force
                $allHistory += $entry
            }
        }
        
        return $allHistory
    }
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name -or $MyInvocation.Line -match '^\.\s') {
    Write-Host "Audit History and Trend Analysis Tool" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Functions:" -ForegroundColor Yellow
    Write-Host "  Save-AuditHistory   - Save audit results to history database" -ForegroundColor Gray
    Write-Host "  Get-AuditTrends     - Analyze trends in historical data" -ForegroundColor Gray
    Write-Host "  Get-AuditHistory    - Retrieve historical audit data" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example Usage:" -ForegroundColor Yellow
    Write-Host "  Get-AuditTrends -FunctionName 'Get-PerformanceMetrics' -Days 30" -ForegroundColor Gray
    Write-Host ""
}
