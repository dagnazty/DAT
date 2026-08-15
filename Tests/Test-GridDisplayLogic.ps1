# Test script for Grid Display Logic
# Simulates the logic in DAT_GUI_Advanced.ps1 that processes audit results for the grid

$selectedFunctions = @("RunningProcesses")
$auditResults = @{
    "RunningProcesses" = @{
        Status = "Success"
        Data = @(
            [PSCustomObject]@{ Name = "Process1"; ID = 100 },
            [PSCustomObject]@{ Name = "Process2"; ID = 101 },
            [PSCustomObject]@{ Name = "Process3"; ID = 102 },
            [PSCustomObject]@{ Name = "Process4"; ID = 103 },
            [PSCustomObject]@{ Name = "Process5"; ID = 104 },
            [PSCustomObject]@{ Name = "Process6"; ID = 105 } # Should trigger "more items"
        )
        Count = 6
    }
}

Write-Host "Testing Grid Display Logic..."

# --- COPIED LOGIC FROM DAT_GUI_Advanced.ps1 ---
$allData = @()
foreach ($func in $selectedFunctions) {
    $result = $auditResults[$func]
    if ($result.Status -eq "Success") {
        if ($result.Data -is [System.Collections.IEnumerable] -and $result.Data -isnot [string] -and $result.Count -gt 1) {
            $itemCount = 0
            foreach ($item in $result.Data) {
                if ($itemCount -ge 5) {
                    $allData += [PSCustomObject]@{
                        Function = $func
                        Status = "..."
                        Info = "($($result.Count - 5) more items - see CSV export)"
                    }
                    break
                }
                $itemData = [PSCustomObject]@{
                    Function = $func
                    Status = "Success"
                }
                foreach ($prop in $item.PSObject.Properties) {
                    $itemData | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                }
                $allData += $itemData
                $itemCount++
            }
        } else {
            # Single item logic (omitted for brevity as we are testing multi-item)
        }
    }
}
# --- END COPIED LOGIC ---

Write-Host "Total items in allData: $($allData.Count)"
if ($allData.Count -eq 6) {
    Write-Host "SUCCESS: Correct number of items generated (5 processes + 1 summary)."
    $allData | Format-Table
} else {
    Write-Error "FAILURE: Expected 6 items, got $($allData.Count)."
}
