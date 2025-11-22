# Test Script for Test-Compliance

$scriptRoot = "d:\Scripts\DAT"
$functionPath = "$scriptRoot\Functions\Test-Compliance.ps1"

Write-Host "Loading function from: $functionPath"
. $functionPath

try {
    Write-Host "Running Test-Compliance..."
    $results = Test-Compliance -Standards "CIS", "NIST"
    
    Write-Host "Results Count: $($results.Count)"
    
    $summary = $results | Where-Object { $_.Standard -eq "SUMMARY" }
    if ($summary) {
        Write-Host "SUCCESS: Summary object found." -ForegroundColor Green
        Write-Host "Compliance Score: $($summary.CompliancePercentage)%"
        Write-Host "Status: $($summary.Status)"
    }
    else {
        Write-Host "ERROR: Summary object missing." -ForegroundColor Red
    }

    foreach ($res in $results) {
        if ($res.Standard -ne "SUMMARY") {
            Write-Host " - $($res.Check): $($res.Status)"
        }
    }

}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
