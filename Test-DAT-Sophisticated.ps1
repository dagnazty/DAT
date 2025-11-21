# DAT Sophisticated Features - Comprehensive Test Run
# This script demonstrates all the advanced features of the DAT tool

param (
    [switch]$FullTest,
    [switch]$QuickTest,
    [switch]$CleanUp
)

$testResults = @()
$testOutputDir = "TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$testStartTime = Get-Date

Write-Host "🚀 Starting DAT Sophisticated Features Test Run" -ForegroundColor Cyan
Write-Host "Output Directory: $testOutputDir" -ForegroundColor Yellow
Write-Host "Started at: $testStartTime" -ForegroundColor Yellow
Write-Host ""

# Create test directory
New-Item -ItemType Directory -Path $testOutputDir -Force | Out-Null

function Write-TestResult {
    param (
        [string]$TestName,
        [string]$Status,
        [string]$Details = "",
        [string]$OutputPath = ""
    )

    $result = [PSCustomObject]@{
        TestName = $TestName
        Status = $Status
        Details = $Details
        OutputPath = $OutputPath
        Timestamp = Get-Date
    }

    $script:testResults += $result

    $statusColor = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
        default { "White" }
    }

    Write-Host "[$Status] $TestName" -ForegroundColor $statusColor
    if ($Details) { Write-Host "      $Details" -ForegroundColor Gray }
    if ($OutputPath) { Write-Host "      Output: $OutputPath" -ForegroundColor Blue }
    Write-Host ""
}

# Clean up old test files if requested
if ($CleanUp) {
    Write-Host "🧹 Cleaning up old test files..." -ForegroundColor Yellow
    Get-ChildItem -Path "." -Filter "TestResults_*" -Directory | Remove-Item -Recurse -Force
    Write-Host "Cleanup completed." -ForegroundColor Green
    exit
}

# Load essential functions
Write-Host "📚 Loading DAT functions..." -ForegroundColor Cyan
$essentialFunctions = @(
    "Get-SystemUptime.ps1",
    "Get-RunningProcesses.ps1",
    "Get-PerformanceMetrics.ps1",
    "Get-Configuration.ps1",
    "Test-Compliance.ps1",
    "New-HTMLReport.ps1",
    "Send-Alert.ps1"
)

foreach ($func in $essentialFunctions) {
    $filePath = "Functions\$func"
    if (Test-Path $filePath) {
        try {
            . $filePath
            Write-Host "✓ Loaded $func" -ForegroundColor Green
        } catch {
            Write-TestResult -TestName "Load $func" -Status "FAIL" -Details "$($_.Exception.Message)"
        }
    } else {
        Write-TestResult -TestName "Load $func" -Status "SKIP" -Details "File not found"
    }
}
Write-Host ""

# Test 1: Individual Function Execution with CSV Export
Write-Host "🧪 Test 1: Individual Function Execution" -ForegroundColor Cyan
$functionsToTest = @(
    @{Name="Get-SystemUptime"; Function="Get-SystemUptime"},
    @{Name="Get-RunningProcesses"; Function="Get-RunningProcesses"},
    @{Name="Get-PerformanceMetrics"; Function="Get-PerformanceMetrics"},
    @{Name="Get-HardwareInventory"; Function="Get-HardwareInventory"}
)

foreach ($test in $functionsToTest) {
    try {
        $outputPath = "$testOutputDir\$($test.Name).csv"
        $result = & $test.Function -CsvPath $outputPath
        if (Test-Path $outputPath) {
            Write-TestResult -TestName $test.Name -Status "PASS" -OutputPath $outputPath
        } else {
            Write-TestResult -TestName $test.Name -Status "FAIL" -Details "CSV file not created"
        }
    } catch {
        Write-TestResult -TestName $test.Name -Status "FAIL" -Details $_.Exception.Message
    }
}

# Test 2: Configuration System
Write-Host "⚙️ Test 2: Configuration System" -ForegroundColor Cyan
try {
    $config = Get-Configuration
    if ($config) {
        Write-TestResult -TestName "Load Configuration" -Status "PASS" -Details "Configuration loaded successfully"

        # Test threshold checking
        $cpuThreshold = Get-ThresholdValue -ThresholdName "cpuUsageWarning" -Config $config
        if ($cpuThreshold -is [int]) {
            Write-TestResult -TestName "Threshold Configuration" -Status "PASS" -Details "CPU threshold: $cpuThreshold%"
        } else {
            Write-TestResult -TestName "Threshold Configuration" -Status "FAIL" -Details "Invalid threshold value"
        }
    } else {
        Write-TestResult -TestName "Load Configuration" -Status "SKIP" -Details "No configuration file found, using defaults"
    }
} catch {
    Write-TestResult -TestName "Configuration System" -Status "FAIL" -Details $_.Exception.Message
}

# Test 3: Compliance Framework
Write-Host "📋 Test 3: Compliance Framework" -ForegroundColor Cyan
try {
    $compliancePath = "$testOutputDir\ComplianceReport.csv"
    $complianceResults = Test-Compliance -CsvPath $compliancePath -Standards CIS

    if ($complianceResults) {
        $cisChecks = $complianceResults | Where-Object { $_.Standard -eq "CIS" }
        $compliantCount = ($cisChecks | Where-Object { $_.Compliant -eq $true }).Count
        $totalChecks = $cisChecks.Count

        Write-TestResult -TestName "CIS Compliance Check" -Status "PASS" -Details "$compliantCount/$totalChecks checks passed" -OutputPath $compliancePath
    } else {
        Write-TestResult -TestName "Compliance Framework" -Status "FAIL" -Details "No compliance results returned"
    }
} catch {
    Write-TestResult -TestName "Compliance Framework" -Status "FAIL" -Details $_.Exception.Message
}

# Test 4: Plugin System
Write-Host "🔌 Test 4: Plugin System" -ForegroundColor Cyan
try {
    $availablePlugins = Get-AvailablePlugins
    if ($availablePlugins) {
        Write-TestResult -TestName "Plugin Discovery" -Status "PASS" -Details "Found $($availablePlugins.Count) plugins"

        # Test custom security plugin if available
        $securityPlugin = $availablePlugins | Where-Object { $_.Name -eq "Custom-SecurityScan" }
        if ($securityPlugin) {
            $pluginOutput = "$testOutputDir\SecurityScan_Plugin.csv"
            $pluginResult = Invoke-Plugin -PluginName "Custom-SecurityScan" -Parameters @{CsvPath=$pluginOutput}
            if (Test-Path $pluginOutput) {
                Write-TestResult -TestName "Custom Security Plugin" -Status "PASS" -OutputPath $pluginOutput
            } else {
                Write-TestResult -TestName "Custom Security Plugin" -Status "FAIL" -Details "Plugin output not created"
            }
        } else {
            Write-TestResult -TestName "Custom Security Plugin" -Status "SKIP" -Details "Security plugin not found"
        }
    } else {
        Write-TestResult -TestName "Plugin Discovery" -Status "SKIP" -Details "No plugins found"
    }
} catch {
    Write-TestResult -TestName "Plugin System" -Status "FAIL" -Details $_.Exception.Message
}

# Test 5: HTML Report Generation
Write-Host "📊 Test 5: HTML Report Generation" -ForegroundColor Cyan
try {
    # Gather sample data for HTML report
    $sampleData = @{
        SystemUptime = Get-SystemUptime
        PerformanceMetrics = Get-PerformanceMetrics
        SecurityUpdateStatus = Get-SecurityUpdateStatus
        ComplianceResults = Test-Compliance -Standards CIS | Select-Object -First 5
    }

    $htmlPath = "$testOutputDir\ComprehensiveReport.html"
    New-HTMLReport -OutputPath $htmlPath -AuditData $sampleData -CompanyName "DAT Test Environment"

    if (Test-Path $htmlPath) {
        Write-TestResult -TestName "HTML Report Generation" -Status "PASS" -OutputPath $htmlPath
    } else {
        Write-TestResult -TestName "HTML Report Generation" -Status "FAIL" -Details "HTML file not created"
    }
} catch {
    Write-TestResult -TestName "HTML Report Generation" -Status "FAIL" -Details $_.Exception.Message
}

# Test 6: Alerting System
Write-Host "🚨 Test 6: Alerting System" -ForegroundColor Cyan
try {
    # Test event log alerting (safe test)
    Send-Alert -Subject "DAT Test Alert" -Message "This is a test alert from the DAT testing framework" -Channels EventLog -Severity Info
    Write-TestResult -TestName "Event Log Alerting" -Status "PASS" -Details "Test alert sent to Event Log"

    # Test alert system (without external channels)
    Test-AlertSystem
    Write-TestResult -TestName "Alert System Test" -Status "PASS" -Details "Alert system test completed"
} catch {
    Write-TestResult -TestName "Alerting System" -Status "FAIL" -Details $_.Exception.Message
}

# Test 7: Scheduled Audit System (Quick test)
Write-Host "📅 Test 7: Scheduled Audit System" -ForegroundColor Cyan
try {
    # List existing scheduled audits
    $scheduledTasks = Get-ScheduledAudits
    Write-TestResult -TestName "Scheduled Task Discovery" -Status "PASS" -Details "Found $($scheduledTasks.Count) scheduled tasks"

    # Create a test scheduled task (commented out to avoid actually creating it)
    # New-ScheduledAudit -TaskName "DAT_Test_Run" -Frequency Daily -Time "23:59" -EnabledChecks SystemUptime -Force
    Write-TestResult -TestName "Scheduled Task Creation" -Status "SKIP" -Details "Task creation skipped in test mode"
} catch {
    Write-TestResult -TestName "Scheduled Audit System" -Status "FAIL" -Details $_.Exception.Message
}

# Generate Test Summary Report
Write-Host "📋 Generating Test Summary..." -ForegroundColor Cyan
$testEndTime = Get-Date
$duration = $testEndTime - $testStartTime

$summary = "DAT Sophisticated Features - Test Results Summary
=================================================

Test Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $($duration.TotalSeconds.ToString('F2')) seconds
Total Tests: $($testResults.Count)
Passed: $(($testResults | Where-Object { $_.Status -eq 'PASS' }).Count)
Failed: $(($testResults | Where-Object { $_.Status -eq 'FAIL' }).Count)
Skipped: $(($testResults | Where-Object { $_.Status -eq 'SKIP' }).Count)

Detailed Results:"

foreach ($result in $testResults) {
    $summary += "`n$($result.Status) - $($result.TestName)"
    if ($result.Details) { $summary += ": $($result.Details)" }
    if ($result.OutputPath) { $summary += " -> $($result.OutputPath)" }
}

$summaryPath = "$testOutputDir\TestSummary.txt"
$summary | Out-File -FilePath $summaryPath -Encoding UTF8

# Display summary
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "📋 TEST SUMMARY" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta
Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "✓ Passed: $(($testResults | Where-Object { $_.Status -eq 'PASS' }).Count)" -ForegroundColor Green
Write-Host "✗ Failed: $(($testResults | Where-Object { $_.Status -eq 'FAIL' }).Count)" -ForegroundColor Red
Write-Host "⏭️ Skipped: $(($testResults | Where-Object { $_.Status -eq 'SKIP' }).Count)" -ForegroundColor Yellow
Write-Host "Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Cyan
Write-Host "Output Directory: $testOutputDir" -ForegroundColor Blue
Write-Host "Summary Report: $summaryPath" -ForegroundColor Blue
Write-Host "="*60 -ForegroundColor Magenta

# Show key files created
Write-Host "`n📁 Files Created:" -ForegroundColor Cyan
Get-ChildItem -Path $testOutputDir | ForEach-Object {
    $size = if ($_.PSIsContainer) { "(Directory)" } else { "($([math]::Round($_.Length/1KB, 2)) KB)" }
    Write-Host "  • $($_.Name) $size" -ForegroundColor Gray
}

Write-Host "`n🎉 DAT Sophisticated Features Test Complete!" -ForegroundColor Green
Write-Host "Review the results in: $testOutputDir" -ForegroundColor Yellow

# Quick test mode - just run essential tests
if ($QuickTest -and -not $FullTest) {
    Write-Host "`n⚡ Quick Test Mode - Limited tests completed" -ForegroundColor Yellow
}

# Full test mode confirmation
if ($FullTest) {
    Write-Host "`n🔬 Full Test Mode - All features tested" -ForegroundColor Green
}

# Quick test mode
if ($QuickTest -and -not $FullTest) {
    Write-Host "`n⚡ Quick Test Mode - Limited tests completed" -ForegroundColor Yellow
}
