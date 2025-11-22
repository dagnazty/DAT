# Test script for Uptime Webhook Verification

# Load necessary functions
. "$PSScriptRoot\Functions\Send-Alert.ps1"

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
$selectedFunctions = @("SystemUptime")
$auditResults = @{
    "SystemUptime" = @{
        Status = "Success"
        Data = [PSCustomObject]@{
            Days = 12
            Hours = 4
            Minutes = 30
            Seconds = 15
            TotalHours = 292.5
            TotalDays = 12.19
            LastBootTime = (Get-Date).AddDays(-12)
        }
        Count = 1
    }
}

Write-Host "Simulating Audit Completion Alert with Uptime..."

# --- COPIED LOGIC FROM DAT_GUI_Advanced.ps1 (Updated) ---
$alertMessage = "Audit Run Completed on $env:COMPUTERNAME`n`n"
$alertMessage += "Total Functions: $($selectedFunctions.Count)`n"

foreach ($func in $selectedFunctions) {
    $res = $auditResults[$func]
    $status = $res.Status
    $alertMessage += "- $func`: $status`n"
    
    if ($func -eq "SystemUptime" -and $status -eq "Success") {
        $uptime = $res.Data
        $alertMessage += "   - Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes`n"
        $alertMessage += "   - Last Boot: $($uptime.LastBootTime)`n"
    }
}

# Send Alert
try {
    Send-Alert -Subject "DAT Audit Summary (Uptime Test)" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config
} catch {
    Write-Host "Caught expected error: $_"
}
