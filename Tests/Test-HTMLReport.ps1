# Test Script for New-HTMLReport

$scriptRoot = "d:\Scripts\DAT"
$functionPath = "$scriptRoot\Functions\New-HTMLReport.ps1"

Write-Host "Loading function from: $functionPath"
. $functionPath

# Create dummy data
$auditData = @{
    "SystemUptime" = [PSCustomObject]@{
        Days = 10
        Hours = 5
        Minutes = 30
        LastBootTime = (Get-Date).AddDays(-10)
    }
    "RunningProcesses" = @(
        [PSCustomObject]@{ Name = "svchost"; Id = 1001; CPU = 0.5 },
        [PSCustomObject]@{ Name = "explorer"; Id = 2002; CPU = 1.2 },
        [PSCustomObject]@{ Name = "powershell"; Id = 3003; CPU = 0.1 }
    )
    "SimpleString" = "This is a simple string result."
    "EmptyList" = @()
}

$outputPath = "$env:TEMP\DAT_Test_Report.html"

Write-Host "Generating report at: $outputPath"
try {
    New-HTMLReport -OutputPath $outputPath -AuditData $auditData -CompanyName "Test Company"
    
    if (Test-Path $outputPath) {
        Write-Host "SUCCESS: Report created." -ForegroundColor Green
        $content = Get-Content $outputPath -Raw
        if ($content.Length -gt 100) {
             Write-Host "SUCCESS: Report has content ($($content.Length) bytes)." -ForegroundColor Green
        } else {
             Write-Host "ERROR: Report is empty or too small." -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: Report file not found." -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: Failed to generate report. $_" -ForegroundColor Red
}
