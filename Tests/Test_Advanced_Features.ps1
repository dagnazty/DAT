# Test Script for DAT Advanced Features
# This script demonstrates all the sophisticated features you've built

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DAT Advanced Features Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Configuration Management
Write-Host "[1/7] Testing Configuration Management..." -ForegroundColor Yellow
try {
    . .\Functions\Get-Configuration.ps1
    $config = Get-Configuration
    if ($config) {
        Write-Host "✅ Configuration loaded successfully!" -ForegroundColor Green
        Write-Host "   - CPU Warning Threshold: $($config.thresholds.cpuUsageWarning)%" -ForegroundColor Gray
        Write-Host "   - Memory Warning Threshold: $($config.thresholds.memoryUsageWarning)%" -ForegroundColor Gray
        Write-Host "   - Alerting Enabled: $($config.alerting.enabled)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Configuration not found, using defaults" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Configuration test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Alerting System
Write-Host "[2/7] Testing Alerting System..." -ForegroundColor Yellow
try {
    . .\Functions\Send-Alert.ps1
    Send-Alert -Subject "DAT Test Alert" -Message "This is a test alert from the advanced features test suite" -Channels EventLog -Severity Info
    Write-Host "✅ Alert sent successfully!" -ForegroundColor Green
    Write-Host "   - Check Event Viewer > Application Log for the alert" -ForegroundColor Gray
} catch {
    Write-Host "❌ Alert test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Compliance Framework
Write-Host "[3/7] Testing Compliance Framework..." -ForegroundColor Yellow
try {
    . .\Functions\Test-Compliance.ps1
    $complianceFile = "Test_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $complianceResults = Test-Compliance -Standards CIS,NIST -CsvPath $complianceFile
    $summary = $complianceResults | Where-Object { $_.Standard -eq "SUMMARY" }
    if ($summary) {
        Write-Host "✅ Compliance check completed!" -ForegroundColor Green
        Write-Host "   - Compliance Score: $($summary.CompliancePercentage)%" -ForegroundColor Gray
        Write-Host "   - Checks Passed: $($summary.CurrentValue)" -ForegroundColor Gray
        Write-Host "   - Report saved to: $complianceFile" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Compliance test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: HTML Report Generation
Write-Host "[4/7] Testing HTML Report Generation..." -ForegroundColor Yellow
try {
    . .\Functions\New-HTMLReport.ps1
    . .\Functions\Get-SystemUptime.ps1
    . .\Functions\Get-PerformanceMetrics.ps1
    
    $uptimeData = Get-SystemUptime
    $perfData = Get-PerformanceMetrics
    
    $auditData = @{
        SystemUptime = $uptimeData
        PerformanceMetrics = $perfData
    }
    
    $htmlFile = "Test_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    New-HTMLReport -OutputPath $htmlFile -AuditData $auditData -CompanyName "DAT Advanced Test"
    
    Write-Host "✅ HTML report generated successfully!" -ForegroundColor Green
    Write-Host "   - Report saved to: $htmlFile" -ForegroundColor Gray
} catch {
    Write-Host "❌ HTML report test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Plugin System
Write-Host "[5/7] Testing Plugin System..." -ForegroundColor Yellow
try {
    . .\Functions\Invoke-Plugin.ps1
    $plugins = Get-AvailablePlugins
    if ($plugins) {
        Write-Host "✅ Plugin system working!" -ForegroundColor Green
        Write-Host "   - Found $($plugins.Count) plugin(s):" -ForegroundColor Gray
        foreach ($plugin in $plugins) {
            Write-Host "     • $($plugin.Name) - $($plugin.Description)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  No plugins found (this is OK)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Plugin test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Scheduled Audit Creation
Write-Host "[6/7] Testing Scheduled Audit System..." -ForegroundColor Yellow
try {
    . .\Functions\New-ScheduledAudit.ps1
    
    # Check for existing scheduled tasks
    $existingTasks = Get-ScheduledAudits
    if ($existingTasks) {
        Write-Host "✅ Scheduled audit system working!" -ForegroundColor Green
        Write-Host "   - Found $($existingTasks.Count) scheduled task(s):" -ForegroundColor Gray
        foreach ($task in $existingTasks) {
            Write-Host "     • $($task.TaskName) - State: $($task.State) - Next: $($task.NextRunTime)" -ForegroundColor Gray
        }
    } else {
        Write-Host "✅ Scheduled audit system ready (no tasks created yet)" -ForegroundColor Green
        Write-Host "   - Use New-ScheduledAudit to create scheduled tasks" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Scheduled audit test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 7: Individual Audit Functions
Write-Host "[7/7] Testing Individual Audit Functions..." -ForegroundColor Yellow
try {
    . .\Functions\Get-SystemUptime.ps1
    $uptime = Get-SystemUptime
    if ($uptime) {
        Write-Host "✅ Audit functions working!" -ForegroundColor Green
        Write-Host "   - System Uptime: $($uptime.UptimeDays) days" -ForegroundColor Gray
        Write-Host "   - Last Boot: $($uptime.LastBootTime)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Audit function test failed: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Suite Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All advanced features have been tested." -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Launch Advanced GUI: .\Launch_DAT_GUI_Advanced.bat" -ForegroundColor White
Write-Host "  2. Configure Settings: Edit Config\DefaultConfig.json" -ForegroundColor White
Write-Host "  3. Set up Alerts: Add SMTP server and webhook URL" -ForegroundColor White
Write-Host "  4. Create Schedule: Use GUI or New-ScheduledAudit" -ForegroundColor White
Write-Host "  5. Run Compliance: Use GUI Compliance Check button" -ForegroundColor White
Write-Host ""
Write-Host "For detailed documentation, see README_COMPLETE.md" -ForegroundColor Cyan
Write-Host ""
