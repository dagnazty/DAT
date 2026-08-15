# Test script for Webhook Content Update Verification

# Load necessary functions
. "$PSScriptRoot\..\Functions\Send-Alert.ps1"

# Mock Config
$script:config = @{
    alerting = @{
        enabled = $true
        webhook = @{
            url = "https://discord.com/api/webhooks/1234567890" # Fake URL
            method = "Post"
        }
    }
}

# Mock Audit Results
$selectedFunctions = @("PerformanceMetrics", "RunningProcesses")
$auditResults = @{
    "PerformanceMetrics" = @{
        Status = "Success"
        Data = [PSCustomObject]@{
            CPUUsagePercent = 45.5
            MemoryUsagePercent = 60.2
        }
        Count = 1
    }
    "RunningProcesses" = @{
        Status = "Success"
        Data = @(
            [PSCustomObject]@{ Name = "Chrome"; Id = 1234; CPU = 15.5 },
            [PSCustomObject]@{ Name = "PowerShell"; Id = 5678; CPU = 5.2 },
            [PSCustomObject]@{ Name = "System"; Id = 4; CPU = 2.1 },
            [PSCustomObject]@{ Name = "Explorer"; Id = 9999; CPU = 1.5 },
            [PSCustomObject]@{ Name = "Discord"; Id = 7777; CPU = 1.0 },
            [PSCustomObject]@{ Name = "Notepad"; Id = 1111; CPU = 0.1 }
        )
        Count = 6
    }
}

Write-Host "Simulating Audit Completion Alert with Processes..."

# --- COPIED LOGIC FROM DAT_GUI_Advanced.ps1 (Updated) ---
$alertMessage = "Audit Run Completed on $env:COMPUTERNAME`n`n"
$alertMessage += "Total Functions: $($selectedFunctions.Count)`n"

foreach ($func in $selectedFunctions) {
    $res = $auditResults[$func]
    $status = $res.Status
    $alertMessage += "- $func`: $status`n"
    
    if ($func -eq "PerformanceMetrics" -and $status -eq "Success") {
        $metrics = $res.Data
        $alertMessage += "   - CPU: $($metrics.CPUUsagePercent)%`n"
        $alertMessage += "   - Memory: $($metrics.MemoryUsagePercent)%`n"
    }

    if ($func -eq "RunningProcesses" -and $status -eq "Success") {
        $processes = $res.Data
        if ($processes) {
            $alertMessage += "   - Top 5 Processes by CPU:`n"
            $topProcesses = $processes | Sort-Object CPU -Descending | Select-Object -First 5
            foreach ($proc in $topProcesses) {
                $alertMessage += "     - $($proc.Name) (ID: $($proc.Id), CPU: $($proc.CPU))`n"
            }
            if ($processes.Count -gt 5) {
                $alertMessage += "     - ... and $($processes.Count - 5) more.`n"
            }
        }
    }
}

# Send Alert
try {
    Send-Alert -Subject "DAT Audit Summary (Test v2)" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config
} catch {
    Write-Host "Caught expected error: $_"
}
