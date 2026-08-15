# DAT - Graphical User Interface
# PowerShell GUI for the DAT audit tool using Windows Forms

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load all DAT functions
Write-Host "Loading DAT functions for GUI..." -ForegroundColor Cyan
$functionFiles = Get-ChildItem -Path "Functions\*.ps1"
foreach ($file in $functionFiles) {
    try {
        . $file.FullName
    } catch {
        Write-Warning "Failed to load $($file.Name): $_"
    }
}
Write-Host "DAT functions loaded successfully!" -ForegroundColor Green

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DAT - Sophisticated Audit Tool v2.0"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "DAT - Sophisticated Audit Tool"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$titleLabel.Size = New-Object System.Drawing.Size(400, 40)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($titleLabel)

# Subtitle
$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Enterprise Security & Compliance Platform"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitleLabel.ForeColor = [System.Drawing.Color]::Gray
$subtitleLabel.Size = New-Object System.Drawing.Size(400, 30)
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 55)
$form.Controls.Add($subtitleLabel)

# Function Selection Group Box
$functionGroup = New-Object System.Windows.Forms.GroupBox
$functionGroup.Text = "Available Audit Functions"
$functionGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$functionGroup.Size = New-Object System.Drawing.Size(300, 400)
$functionGroup.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($functionGroup)

# Checkboxes for functions
$functions = @(
    "SystemUptime",
    "RunningProcesses",
    "PerformanceMetrics",
    "HardwareInventory",
    "EventLogSummary",
    "SecurityUpdateStatus",
    "SoftwareLicensing",
    "WindowsUpdateHistory",
    "DriversInformation",
    "BackupStatus",
    "OpenPorts",
    "UserGroups",
    "RegistryScan",
    "DiskHealth"
)

$checkboxes = @()
$yPos = 30
foreach ($func in $functions) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $func -replace '([A-Z])', ' $1'  # Add spaces before capitals
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $checkbox.Size = New-Object System.Drawing.Size(250, 25)
    $checkbox.Location = New-Object System.Drawing.Point(20, $yPos)
    $checkbox.Checked = $false
    $functionGroup.Controls.Add($checkbox)
    $checkboxes += $checkbox
    $yPos += 25
}

# Select All / Clear All buttons
$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Select All"
$selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$selectAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$buttonYPos = $yPos + 10
$selectAllBtn.Location = New-Object System.Drawing.Point(20, $buttonYPos)
$selectAllBtn.Add_Click({
    foreach ($cb in $checkboxes) {
        $cb.Checked = $true
    }
})
$functionGroup.Controls.Add($selectAllBtn)

$clearAllBtn = New-Object System.Windows.Forms.Button
$clearAllBtn.Text = "Clear All"
$clearAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$clearAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$clearAllBtn.Location = New-Object System.Drawing.Point(110, $buttonYPos)
$clearAllBtn.Add_Click({
    foreach ($cb in $checkboxes) {
        $cb.Checked = $false
    }
})
$functionGroup.Controls.Add($clearAllBtn)

# Run Audit Button
$runAuditBtn = New-Object System.Windows.Forms.Button
$runAuditBtn.Text = "Run Selected Audits"
$runAuditBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$runAuditBtn.Size = New-Object System.Drawing.Size(200, 40)
$runAuditBtn.Location = New-Object System.Drawing.Point(350, 100)
$runAuditBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$runAuditBtn.ForeColor = [System.Drawing.Color]::White
$runAuditBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($runAuditBtn)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(400, 25)
$progressBar.Location = New-Object System.Drawing.Point(350, 160)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to run audits..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.Size = New-Object System.Drawing.Size(400, 25)
$statusLabel.Location = New-Object System.Drawing.Point(350, 195)
$form.Controls.Add($statusLabel)

# Results DataGridView
$resultsGrid = New-Object System.Windows.Forms.DataGridView
$resultsGrid.Size = New-Object System.Drawing.Size(600, 350)
$resultsGrid.Location = New-Object System.Drawing.Point(350, 230)
$resultsGrid.AllowUserToAddRows = $false
$resultsGrid.AllowUserToDeleteRows = $false
$resultsGrid.ReadOnly = $true
$resultsGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$resultsGrid.BackgroundColor = [System.Drawing.Color]::White
$form.Controls.Add($resultsGrid)

# Export to CSV Button
$exportCsvBtn = New-Object System.Windows.Forms.Button
$exportCsvBtn.Text = "Export to CSV"
$exportCsvBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportCsvBtn.Size = New-Object System.Drawing.Size(120, 35)
$exportCsvBtn.Location = New-Object System.Drawing.Point(830, 590)
$exportCsvBtn.Enabled = $false
$form.Controls.Add($exportCsvBtn)

# Generate HTML Report Button
$exportHtmlBtn = New-Object System.Windows.Forms.Button
$exportHtmlBtn.Text = "HTML Report"
$exportHtmlBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportHtmlBtn.Size = New-Object System.Drawing.Size(120, 35)
$exportHtmlBtn.Location = New-Object System.Drawing.Point(700, 590)
$exportHtmlBtn.Enabled = $false
$form.Controls.Add($exportHtmlBtn)

# Run Audit Button Click Event
$runAuditBtn.Add_Click({
    $selectedFunctions = @()
    foreach ($i in 0..($checkboxes.Count - 1)) {
        if ($checkboxes[$i].Checked) {
            $selectedFunctions += $functions[$i]
        }
    }

    if ($selectedFunctions.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one audit function to run.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    # Disable buttons during execution
    $runAuditBtn.Enabled = $false
    $exportCsvBtn.Enabled = $false
    $exportHtmlBtn.Enabled = $false

    # Clear previous results
    $resultsGrid.DataSource = $null
    $resultsGrid.Columns.Clear()

    $statusLabel.Text = "Running audits..."
    $progressBar.Value = 0

    # Run audits directly (not in background job to avoid scope issues)
    $results = @{}
    $totalFunctions = $selectedFunctions.Count
    $currentIndex = 0

    foreach ($func in $selectedFunctions) {
        $currentIndex++
        $progressPercent = [math]::Round(($currentIndex / $totalFunctions) * 90)
        $progressBar.Value = $progressPercent
        $statusLabel.Text = "Running $func... ($currentIndex of $totalFunctions)"
        $form.Refresh()

        try {
            $functionName = switch ($func) {
                "SystemUptime" { "Get-SystemUptime" }
                "RunningProcesses" { "Get-RunningProcesses" }
                "PerformanceMetrics" { "Get-PerformanceMetrics" }
                "HardwareInventory" { "Get-HardwareInventory" }
                "EventLogSummary" { "Get-EventLogSummary" }
                "SecurityUpdateStatus" { "Get-SecurityUpdateStatus" }
                "SoftwareLicensing" { "Get-SoftwareLicensing" }
                "WindowsUpdateHistory" { "Get-WindowsUpdateHistory" }
                "DriversInformation" { "Get-DriversInformation" }
                "BackupStatus" { "Get-BackupStatus" }
                "OpenPorts" { "Get-OpenPorts" }
                "UserGroups" { "Get-UserGroupMemberships" }
                "RegistryScan" { "Scan-SuspiciousRegistryEntries" }
                "DiskHealth" { "Get-DiskHealth" }
            }

            $result = & $functionName
            $results[$func] = @{
                Status = "Success"
                Data = $result
                Count = if ($result -is [System.Collections.IEnumerable] -and $result -isnot [string]) { $result.Count } else { 1 }
            }
        } catch {
            $results[$func] = @{
                Status = "Error"
                Data = $_.Exception.Message
                Count = 0
            }
        }
    }

    $auditResults = $results

    # Process results for display
    $allData = @()
    foreach ($func in $selectedFunctions) {
        $result = $auditResults[$func]
        if ($result.Status -eq "Success") {
            if ($result.Data -is [System.Collections.IEnumerable] -and $result.Data -isnot [string] -and $result.Count -gt 1) {
                # Multiple items - show first few in grid
                $itemCount = 0
                foreach ($item in $result.Data) {
                    if ($itemCount -ge 5) {
                        # Show summary row after 5 items
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

                    # Add all properties from the original object
                    foreach ($prop in $item.PSObject.Properties) {
                        $itemData | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                    }

                    $allData += $itemData
                    $itemCount++
                }
            } else {
                # Single object - show all properties
                $displayData = [PSCustomObject]@{
                    Function = $func
                    Status = "Success"
                }

                # Add all properties from the result
                if ($result.Data -is [PSCustomObject]) {
                    foreach ($prop in $result.Data.PSObject.Properties) {
                        $displayData | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                    }
                } else {
                    $displayData | Add-Member -MemberType NoteProperty -Name "Result" -Value $result.Data.ToString() -Force
                }

                $allData += $displayData
            }
        } else {
            $allData += [PSCustomObject]@{
                Function = $func
                Status = "Error"
                Error = $result.Data
                Count = 0
            }
        }
    }

    # Display results in grid
    $resultsGrid.Rows.Clear()
    $resultsGrid.Columns.Clear()
    
    if ($allData.Count -gt 0) {
        # Get all unique column names from all objects
        $allColumns = @{}
        foreach ($item in $allData) {
            foreach ($prop in $item.PSObject.Properties) {
                $allColumns[$prop.Name] = $true
            }
        }
        
        # Add columns to grid
        foreach ($colName in $allColumns.Keys) {
            $column = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $column.Name = $colName
            $column.HeaderText = $colName
            $column.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
            $resultsGrid.Columns.Add($column) | Out-Null
        }
        
        # Add rows to grid
        foreach ($item in $allData) {
            $row = New-Object System.Windows.Forms.DataGridViewRow
            $row.CreateCells($resultsGrid)
            
            $colIndex = 0
            foreach ($colName in $allColumns.Keys) {
                $value = $item.$colName
                if ($null -ne $value) {
                    $row.Cells[$colIndex].Value = $value.ToString()
                } else {
                    $row.Cells[$colIndex].Value = ""
                }
                $colIndex++
            }
            
            $resultsGrid.Rows.Add($row) | Out-Null
        }
        
        $resultsGrid.AutoResizeColumns()
    }

    $statusLabel.Text = "Audit completed! Found $($allData.Count) result items."
    $progressBar.Value = 100

    # Store results for export
    $script:auditResults = $auditResults
    $script:allData = $allData

    # Enable export buttons
    $exportCsvBtn.Enabled = $true
    $exportHtmlBtn.Enabled = $true
    $runAuditBtn.Enabled = $true
})

# Export to CSV Button Click Event
$exportCsvBtn.Add_Click({
    if (-not $script:auditResults) {
        [System.Windows.Forms.MessageBox]::Show("No data to export. Please run an audit first.", "No Data", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveDialog.FileName = "DAT_Audit_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $saveDialog.Title = "Save Audit Results to CSV"

    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            # Export each function's results to separate CSV files or combined
            $exportPath = $saveDialog.FileName
            $directory = Split-Path -Path $exportPath -Parent
            $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($exportPath)

            $exportedFiles = @()

            foreach ($func in $script:auditResults.Keys) {
                $result = $script:auditResults[$func]
                
                if ($result.Status -eq "Success" -and $result.Data) {
                    $funcFileName = Join-Path -Path $directory -ChildPath "$baseFileName`_$func.csv"
                    
                    # Export the actual data
                    if ($result.Data -is [System.Collections.IEnumerable] -and $result.Data -isnot [string]) {
                        $result.Data | Export-Csv -Path $funcFileName -NoTypeInformation
                    } else {
                        # Single object - wrap it in array for CSV export
                        @($result.Data) | Export-Csv -Path $funcFileName -NoTypeInformation
                    }
                    
                    $exportedFiles += $funcFileName
                }
            }

            $message = "Results exported successfully!`n`nExported $($exportedFiles.Count) files:`n"
            foreach ($file in $exportedFiles) {
                $message += "`n• $(Split-Path -Path $file -Leaf)"
            }

            [System.Windows.Forms.MessageBox]::Show($message, "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to export CSV: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

# Export to HTML Button Click Event
$exportHtmlBtn.Add_Click({
    if (-not $script:auditResults) {
        [System.Windows.Forms.MessageBox]::Show("No data to export. Please run an audit first.", "No Data", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "HTML files (*.html)|*.html"
    $saveDialog.FileName = "DAT_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $saveDialog.Title = "Save Audit Report as HTML"

    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            # Check if New-HTMLReport function exists, if not load it
            if (-not (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue)) {
                . "$PSScriptRoot\Functions\New-HTMLReport.ps1"
            }

            # Convert results to format expected by HTML report function
            $htmlData = @{}
            foreach ($key in $script:auditResults.Keys) {
                $htmlData[$key] = $script:auditResults[$key].Data
            }

            # Generate HTML report
            if (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue) {
                New-HTMLReport -OutputPath $saveDialog.FileName -AuditData $htmlData -CompanyName "DAT Audit Tool"
                [System.Windows.Forms.MessageBox]::Show("HTML report generated successfully:`n$($saveDialog.FileName)", "Report Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                # Fallback: Create simple HTML report manually
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $hostname = $env:COMPUTERNAME
                
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DAT Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #333; }
        .header { background: #667eea; color: white; padding: 20px; border-radius: 5px; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: bold; }
        tr:hover { background-color: #f8f9fa; }
    </style>
</head>
<body>
    <div class="header">
        <h1>DAT - System Audit Report</h1>
        <p>Generated: $timestamp | Host: $hostname</p>
    </div>
"@
                
                foreach ($key in $script:auditResults.Keys) {
                    $result = $script:auditResults[$key]
                    $html += @"
    <div class="section">
        <h2>$key</h2>
        <p>Status: $($result.Status)</p>
"@
                    
                    if ($result.Status -eq "Success" -and $result.Data) {
                        $html += "<table><thead><tr>"
                        
                        # Get properties from first item
                        if ($result.Data -is [System.Collections.IEnumerable] -and $result.Data -isnot [string]) {
                            $firstItem = $result.Data | Select-Object -First 1
                            if ($firstItem) {
                                foreach ($prop in $firstItem.PSObject.Properties) {
                                    $html += "<th>$($prop.Name)</th>"
                                }
                                $html += "</tr></thead><tbody>"
                                
                                foreach ($item in $result.Data) {
                                    $html += "<tr>"
                                    foreach ($prop in $item.PSObject.Properties) {
                                        $html += "<td>$($prop.Value)</td>"
                                    }
                                    $html += "</tr>"
                                }
                            }
                        } else {
                            # Single object
                            foreach ($prop in $result.Data.PSObject.Properties) {
                                $html += "<th>$($prop.Name)</th>"
                            }
                            $html += "</tr></thead><tbody><tr>"
                            foreach ($prop in $result.Data.PSObject.Properties) {
                                $html += "<td>$($prop.Value)</td>"
                            }
                            $html += "</tr>"
                        }
                        
                        $html += "</tbody></table>"
                    }
                    
                    $html += "</div>"
                }
                
                $html += "</body></html>"
                
                $html | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
                [System.Windows.Forms.MessageBox]::Show("HTML report generated successfully (fallback mode):`n$($saveDialog.FileName)", "Report Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to generate HTML report: $($_.Exception.Message)`n`nStack Trace: $($_.ScriptStackTrace)", "Report Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

# About Button
$aboutBtn = New-Object System.Windows.Forms.Button
$aboutBtn.Text = "About"
$aboutBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$aboutBtn.Size = New-Object System.Drawing.Size(60, 25)
$aboutBtn.Location = New-Object System.Drawing.Point(920, 20)
$aboutBtn.Add_Click({
    $aboutText = @"
DAT - Sophisticated Audit Tool v2.0

A comprehensive enterprise security and compliance platform featuring:

• 14+ Built-in audit functions
• CSV and HTML export capabilities
• Compliance checking (CIS, NIST)
• Plugin architecture for extensibility
• Scheduled automation
• Multi-channel alerting

Created with PowerShell for enterprise environments.
"@
    [System.Windows.Forms.MessageBox]::Show($aboutText, "About DAT", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($aboutBtn)

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
