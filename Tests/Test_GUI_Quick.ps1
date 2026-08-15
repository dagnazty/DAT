# Quick GUI Test - Verifies functions are accessible
Write-Host "Testing DAT GUI Function Accessibility" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Load functions like the GUI does
Write-Host "Loading functions..." -ForegroundColor Yellow
$functionFiles = Get-ChildItem -Path "Functions\*.ps1"
$loadedCount = 0
$failedCount = 0

foreach ($file in $functionFiles) {
    try {
        . $file.FullName
        $loadedCount++
        Write-Host "✓ $($file.BaseName)" -ForegroundColor Green
    } catch {
        $failedCount++
        Write-Host "✗ $($file.BaseName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Loaded: $loadedCount functions" -ForegroundColor Green
Write-Host "Failed: $failedCount functions" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Test calling functions
Write-Host "Testing function calls..." -ForegroundColor Yellow

Write-Host "Testing SystemUptime..." -ForegroundColor Gray -NoNewline
try {
    $result = Get-SystemUptime
    if ($result) {
        Write-Host " ✓ SUCCESS (returned data)" -ForegroundColor Green
    } else {
        Write-Host " ⚠ SUCCESS (no data)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Testing RunningProcesses..." -ForegroundColor Gray -NoNewline
try {
    $result = Get-RunningProcesses
    if ($result) {
        Write-Host " ✓ SUCCESS (returned data)" -ForegroundColor Green
    } else {
        Write-Host " ⚠ SUCCESS (no data)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Testing PerformanceMetrics..." -ForegroundColor Gray -NoNewline
try {
    $result = Get-PerformanceMetrics
    if ($result) {
        Write-Host " ✓ SUCCESS (returned data)" -ForegroundColor Green
    } else {
        Write-Host " ⚠ SUCCESS (no data)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "GUI function test complete!" -ForegroundColor Cyan
Write-Host "If all tests passed, the GUI should work correctly." -ForegroundColor White