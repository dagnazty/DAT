# Test Script for Alert Logic

$alertMessage = "Audit Run Completed`n`n"
$attachments = @()

# Mock Data
$auditResults = @{
    "SmallResult"  = @{
        Status = "Success"
        Data   = @(
            [PSCustomObject]@{ Name = "Item1"; Value = "Value1" },
            [PSCustomObject]@{ Name = "Item2"; Value = "Value2" }
        )
        Count  = 2
    }
    "LargeResult"  = @{
        Status = "Success"
        Data   = 1..10 | ForEach-Object { [PSCustomObject]@{ Name = "Item$_"; Value = "Value$_" } }
        Count  = 10
    }
    "StringResult" = @{
        Status = "Success"
        Data   = "This is a simple string result."
        Count  = 1
    }
}

$selectedFunctions = $auditResults.Keys

Write-Host "Running Alert Logic Simulation..."

foreach ($func in $selectedFunctions) {
    $res = $auditResults[$func]
    $status = $res.Status
    $alertMessage += "- $func`: $status`n"
    
    if ($status -eq "Success") {
        $data = $res.Data
        $count = $res.Count
        
        # Threshold for embedding vs attaching
        if ($count -le 5) {
            # Small result: Embed in message
            if ($data -is [string]) {
                $alertMessage += "   Result: $data`n"
            }
            elseif ($data -is [PSCustomObject] -or $data -is [System.Collections.IDictionary]) {
                $alertMessage += ($data | Format-List | Out-String).Trim() + "`n"
            }
            elseif ($data -is [System.Collections.IEnumerable]) {
                foreach ($item in $data) {
                    if ($item -is [string]) {
                        $alertMessage += "   - $item`n"
                    }
                    else {
                        $alertMessage += ($item | Format-List | Out-String).Trim() + "`n"
                    }
                }
            }
            else {
                $alertMessage += "   Result: $data`n"
            }
        }
        else {
            # Large result: Attach as file
            $attachmentPath = "$env:TEMP\DAT_${func}_Test.txt"
            if ($data -is [string]) {
                $data | Set-Content -Path $attachmentPath
            }
            else {
                $data | Format-Table -AutoSize | Out-String | Set-Content -Path $attachmentPath
            }
            $attachments += $attachmentPath
            $alertMessage += "   - Detailed results ($count items) attached as file.`n"
        }
    }
}

Write-Host "`n--- Alert Message Content ---" -ForegroundColor Cyan
Write-Host $alertMessage
Write-Host "`n--- Attachments ---" -ForegroundColor Cyan
$attachments | ForEach-Object { Write-Host $_ }

# Cleanup
$attachments | ForEach-Object { if (Test-Path $_) { Remove-Item $_ } }
