# DAT Sophisticated Features - Live Demo
# This script demonstrates the key sophisticated features of DAT

Write-Host "🎯 DAT Sophisticated Features Demo" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

# Demo 1: Individual Function with CSV Export
Write-Host "📊 Demo 1: Individual Function with CSV Export" -ForegroundColor Yellow
Write-Host "Running Get-SystemUptime with CSV export..." -ForegroundColor Gray

try {
    # Load the function
    . ".\Functions\Get-SystemUptime.ps1"

    # Run with CSV export
    $result = Get-SystemUptime -CsvPath "Demo_SystemUptime.csv"

    # Display result
    Write-Host "✓ System Uptime Function Results:" -ForegroundColor Green
    $result | Format-Table -AutoSize

    # Check if CSV was created
    if (Test-Path "Demo_SystemUptime.csv") {
        Write-Host "✓ CSV file created: Demo_SystemUptime.csv" -ForegroundColor Green
        Write-Host "Sample CSV content:" -ForegroundColor Gray
        Get-Content "Demo_SystemUptime.csv" | Select-Object -First 2
    }
} catch {
    Write-Host "✗ Error in Demo 1: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + "-" * 50 -ForegroundColor Gray

# Demo 2: Configuration System
Write-Host "⚙️ Demo 2: Configuration System" -ForegroundColor Yellow
Write-Host "Loading and displaying configuration..." -ForegroundColor Gray

try {
    . ".\Functions\Get-Configuration.ps1"

    $config = Get-Configuration
    if ($config) {
        Write-Host "✓ Configuration loaded successfully" -ForegroundColor Green
        Write-Host "CPU Warning Threshold: $($config.thresholds.cpuUsageWarning)%" -ForegroundColor White
        Write-Host "Memory Warning Threshold: $($config.thresholds.memoryUsageWarning)%" -ForegroundColor White
        Write-Host "Enabled Checks: $($config.audit.enabledChecks -join ', ')" -ForegroundColor White
    } else {
        Write-Host "⚠ No configuration file found, using defaults" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error in Demo 2: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + "-" * 50 -ForegroundColor Gray

# Demo 3: Plugin System
Write-Host "🔌 Demo 3: Plugin System" -ForegroundColor Yellow
Write-Host "Discovering and listing available plugins..." -ForegroundColor Gray

try {
    . ".\Functions\Invoke-Plugin.ps1"

    $plugins = Get-AvailablePlugins
    if ($plugins.Count -gt 0) {
        Write-Host "✓ Found $($plugins.Count) plugins:" -ForegroundColor Green
        foreach ($plugin in $plugins) {
            Write-Host "  • $($plugin.Name) - $($plugin.Description)" -ForegroundColor White
        }

        # Try to run the custom security scan plugin
        $securityPlugin = $plugins | Where-Object { $_.Name -eq "Custom-SecurityScan" }
        if ($securityPlugin) {
            Write-Host "Running Custom Security Scan plugin..." -ForegroundColor Gray
            $pluginResult = Invoke-Plugin -PluginName "Custom-SecurityScan" -Parameters @{CsvPath="Demo_SecurityScan.csv"}
            if (Test-Path "Demo_SecurityScan.csv") {
                Write-Host "✓ Plugin executed successfully, results saved to CSV" -ForegroundColor Green
            }
        } else {
            Write-Host "⚠ Custom Security Scan plugin not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ No plugins found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error in Demo 3: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + "-" * 50 -ForegroundColor Gray

# Demo 4: Alerting System
Write-Host "🚨 Demo 4: Alerting System" -ForegroundColor Yellow
Write-Host "Sending test alert..." -ForegroundColor Gray

try {
    . ".\Functions\Send-Alert.ps1"

    Send-Alert -Subject "DAT Demo Alert" -Message "This is a test alert from the DAT demo script" -Channels EventLog -Severity Info
    Write-Host "✓ Test alert sent to Event Log" -ForegroundColor Green
} catch {
    Write-Host "✗ Error in Demo 4: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + "-" * 50 -ForegroundColor Gray

# Demo 5: Show Generated Files
Write-Host "📁 Demo 5: Generated Files" -ForegroundColor Yellow
Write-Host "Files created during this demo:" -ForegroundColor Gray

$demoFiles = Get-ChildItem -Path "." -Filter "Demo_*.csv" -File
if ($demoFiles) {
    foreach ($file in $demoFiles) {
        $size = "$([math]::Round($file.Length / 1KB, 2)) KB"
        Write-Host "  • $($file.Name) ($size)" -ForegroundColor White
    }
} else {
    Write-Host "  No demo files found" -ForegroundColor Gray
}

Write-Host "`n" + "=" * 50 -ForegroundColor Cyan
Write-Host "🎉 DAT Sophisticated Features Demo Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Key Features Demonstrated:" -ForegroundColor White
Write-Host "• ✓ Individual function execution with CSV export" -ForegroundColor Green
Write-Host "• ✓ Configuration management system" -ForegroundColor Green
Write-Host "• ✓ Extensible plugin architecture" -ForegroundColor Green
Write-Host "• ✓ Intelligent alerting system" -ForegroundColor Green
Write-Host "• ✓ Professional reporting capabilities" -ForegroundColor Green
Write-Host ""
Write-Host "Additional Features Available:" -ForegroundColor Yellow
Write-Host "• Compliance checking (CIS, NIST standards)" -ForegroundColor Gray
Write-Host "• HTML report generation with charts" -ForegroundColor Gray
Write-Host "• Scheduled audit automation" -ForegroundColor Gray
Write-Host "• Multi-channel alerting (Email, Webhooks)" -ForegroundColor Gray
Write-Host "• Enterprise-grade security scanning" -ForegroundColor Gray
