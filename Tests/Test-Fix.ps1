# Test-Fix.ps1
$ErrorActionPreference = "Continue"

Write-Host "1. Loading Configuration..."
. "$PSScriptRoot\..\Functions\Get-Configuration.ps1"
$config = Get-Configuration

if ($config) {
    Write-Host "   [PASS] Configuration loaded successfully."
    Write-Host "   Webhook URL: $($config.alerting.webhook.url)"
} else {
    Write-Error "   [FAIL] Configuration failed to load."
}

Write-Host "`n2. Testing Send-Alert (Webhook)..."
. "$PSScriptRoot\..\Functions\Send-Alert.ps1"

try {
    Send-Alert -Subject "DAT Fix Verification" -Message "Testing webhook fix and event log handling." -Channels "Webhook" -Severity "Info" -Config $config
    Write-Host "   [PASS] Send-Alert executed without error."
} catch {
    Write-Error "   [FAIL] Send-Alert failed: $_"
}

Write-Host "`n3. Testing Send-Alert (EventLog - Non-Admin)..."
try {
    Send-Alert -Subject "DAT Fix Verification" -Message "Testing event log handling." -Channels "EventLog" -Severity "Info"
    Write-Host "   [PASS] Send-Alert (EventLog) executed (check for warnings above)."
} catch {
    Write-Error "   [FAIL] Send-Alert (EventLog) failed: $_"
}
