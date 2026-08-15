try {
    Write-Host "Testing CPU Counter..."
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
    Write-Host "CPU Type: $($cpuUsage.GetType().FullName)"
    Write-Host "CPU CookedValue Type: $($cpuUsage.CookedValue.GetType().FullName)"
    Write-Host "CPU Value: $($cpuUsage.CookedValue)"

    Write-Host "`nTesting Network Counter..."
    $networkIO = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples | Select-Object CookedValue
    Write-Host "Network Type: $($networkIO.GetType().FullName)"
    if ($networkIO -is [System.Array]) {
        Write-Host "Network is an Array of size: $($networkIO.Count)"
        Write-Host "Network CookedValue is: $($networkIO.CookedValue)"
    }
    else {
        Write-Host "Network CookedValue: $($networkIO.CookedValue)"
    }

    Write-Host "`nAttempting Round on Network..."
    [math]::Round($networkIO.CookedValue, 2)
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
