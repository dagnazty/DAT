# Test Script for Refined Alert Logic (SystemUptime Only in Message)

$alertMessage = "Audit Run Completed`n`n"
$attachments = @()
$combinedDetails = [System.Text.StringBuilder]::new()

# Mock Data
$auditResults = @{
    "SystemUptime"      = @{
        Status = "Success"
        Data   = [PSCustomObject]@{ Days = 1; Hours = 2; Minutes = 30 }
        Count  = 1
    }
    "HardwareInventory" = @{
        Status = "Success"
        Data   = [PSCustomObject]@{ 
            GraphicsCards   = "AMD Radeon RX 6700 XT"
            SoundDevices    = "Virtual Audio Cable, USB Audio Device"
            NetworkAdapters = "Realtek PCIe GBE Family Controller"
            USBDevices      = "USB Root Hub, Generic USB Hub"
            ExtraInfo       = "x" * 600 
        }
        Count  = 1
    }
    "EventLogSummary"   = @{
        Status = "Success"
        Data   = 1..10 | ForEach-Object { [PSCustomObject]@{ Time = Get-Date; Source = "Test"; Message = "Event $_" } }
        Count  = 10
    }
    "SmallFunction"     = @{
        Status = "Success"
        Data   = "Small Result"
        Count  = 1
    }
}

$selectedFunctions = $auditResults.Keys

Write-Host "Running Refined Alert Logic Simulation..."

foreach ($func in $selectedFunctions) {
    $res = $auditResults[$func]
    $status = $res.Status
    $alertMessage += "- $func`: $status`n"
    
    if ($status -eq "Success") {
        $data = $res.Data
        $count = $res.Count
        
        # Convert data to string for analysis and potential attachment
        $dataString = if ($data -is [string]) { 
            $data 
        }
        elseif ($data -is [System.Collections.IEnumerable] -and $data -isnot [string]) {
            ($data | Format-Table -AutoSize | Out-String).Trim()
        }
        else {
            ($data | Format-List | Out-String).Trim()
        }

        # New Logic: Only SystemUptime is concise. Everything else is verbose.
        $isVerbose = ($func -ne "SystemUptime")

        if ($isVerbose) {
            Write-Host "   -> Detected VERBOSE: $func (Count: $count, Length: $($dataString.Length))" -ForegroundColor Cyan
            # Add to combined details attachment
            [void]$combinedDetails.AppendLine("========================================")
            [void]$combinedDetails.AppendLine("FUNCTION: $func")
            [void]$combinedDetails.AppendLine("========================================")
            [void]$combinedDetails.AppendLine($dataString)
            [void]$combinedDetails.AppendLine("") # Empty line
            
            $alertMessage += "   - Details included in attached report.`n"
        }
        else {
            Write-Host "   -> Detected CONCISE: $func (Count: $count, Length: $($dataString.Length))" -ForegroundColor Green
            # Small result: Embed in message
            if ($data -is [string]) {
                $alertMessage += "   Result: $data`n"
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
                $alertMessage += ($data | Format-List | Out-String).Trim() + "`n"
            }
        }
    }
}

# Create attachment if we have details
if ($combinedDetails.Length -gt 0) {
    $detailsPath = "$env:TEMP\DAT_Audit_Details_TEST.txt"
    $combinedDetails.ToString() | Set-Content -Path $detailsPath
    $attachments += $detailsPath
    $alertMessage += "`n[See attached file for detailed results]"
}

Write-Host "`n--- Alert Message Content ---" -ForegroundColor Yellow
Write-Host $alertMessage
Write-Host "`n--- Attachments ---" -ForegroundColor Yellow
$attachments | ForEach-Object { 
    Write-Host "File: $_"
    if (Test-Path $_) {
        Write-Host "Content Preview (First 5 lines):"
        Get-Content $_ -TotalCount 5
    }
}

# Cleanup
$attachments | ForEach-Object { if (Test-Path $_) { Remove-Item $_ } }
