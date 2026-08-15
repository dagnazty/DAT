# Test Send-Alert Function
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Send-Alert Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Loading Send-Alert function..." -ForegroundColor Yellow
try {
    . .\Functions\Send-Alert.ps1
    Write-Host "  [OK] Function file loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Could not load function file: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Checking if function is available..." -ForegroundColor Yellow
$cmd = Get-Command -Name Send-Alert -ErrorAction SilentlyContinue
if ($cmd) {
    Write-Host "  [OK] Send-Alert function is available" -ForegroundColor Green
    Write-Host "  Function Type: $($cmd.CommandType)" -ForegroundColor Gray
    Write-Host "  Module: $($cmd.Module)" -ForegroundColor Gray
} else {
    Write-Host "  [FAIL] Send-Alert function not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Testing Send-Alert with EventLog..." -ForegroundColor Yellow
try {
    Send-Alert -Subject "Test Alert" -Message "This is a test alert from Test-SendAlert.ps1" -Channels @("EventLog") -Severity Info
    Write-Host "  [OK] Alert sent successfully!" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Error sending alert: $_" -ForegroundColor Red
    Write-Host "  Error Details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete - SUCCESS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check Event Viewer to see the alert:" -ForegroundColor Yellow
Write-Host "  1. Open Event Viewer (eventvwr.msc)" -ForegroundColor Gray
Write-Host "  2. Go to Windows Logs > Application" -ForegroundColor Gray
Write-Host "  3. Look for Source: DAT" -ForegroundColor Gray
Write-Host ""
