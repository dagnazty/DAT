# Test script for Webhook Integration
# This script simulates the environment within the GUI button click handler

# Load necessary functions
. "$PSScriptRoot\Functions\Send-Alert.ps1"
. "$PSScriptRoot\Functions\Get-PerformanceMetrics.ps1"

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
$script:ScriptRoot = $PSScriptRoot

# Mock Audit Results
$selectedFunctions = @("PerformanceMetrics", "SystemUptime")
$auditResults = @{
    "PerformanceMetrics" = @{
        Status = "Success"
        Data = [PSCustomObject]@{
            CPUUsagePercent = 45.5
            MemoryUsagePercent = 60.2
        }
        Count = 1
    }
    "SystemUptime" = @{
        Status = "Success"
        Data = "12 days, 4 hours"
        Count = 1
    }
}

Write-Host "Simulating Audit Completion Alert..."

# --- COPIED LOGIC FROM GUI ---
if ($script:config -and $script:config.alerting.enabled -and $script:config.alerting.webhook.url) {
    try {
        # Ensure Send-Alert is loaded (already loaded above, but keeping logic)
        if (-not (Get-Command -Name Send-Alert -ErrorAction SilentlyContinue)) {
            $alertPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Send-Alert.ps1"
            if (Test-Path $alertPath) {
                . $alertPath
            }
        }

        $alertMessage = "Audit Run Completed on $env:COMPUTERNAME`n`n"
        $alertMessage += "Total Functions: $($selectedFunctions.Count)`n"
        
        foreach ($func in $selectedFunctions) {
            $res = $auditResults[$func]
            $status = $res.Status
            $alertMessage += "• $func`: $status`n"
            
            if ($func -eq "PerformanceMetrics" -and $status -eq "Success") {
                $metrics = $res.Data
                $alertMessage += "   - CPU: $($metrics.CPUUsagePercent)%`n"
                $alertMessage += "   - Memory: $($metrics.MemoryUsagePercent)%`n"
            }
        }

        Send-Alert -Subject "DAT Audit Summary (Test)" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config
    } catch {
        Write-Error "Alert failed: $($_.Exception.Message)"
    }
}
# --- END COPIED LOGIC ---
