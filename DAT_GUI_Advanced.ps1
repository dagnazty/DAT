# DAT - Advanced Graphical User Interface with Settings
# PowerShell GUI for the DAT audit tool with all sophisticated features

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Store script root for later use
$script:ScriptRoot = $PSScriptRoot
if (-not $script:ScriptRoot) {
    $script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

Write-Host "Script Root: $script:ScriptRoot" -ForegroundColor Yellow

# Load all DAT functions
Write-Host "Loading DAT functions for Advanced GUI..." -ForegroundColor Cyan
$functionPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions"
Write-Host "Function Path: $functionPath" -ForegroundColor Yellow

if (-not (Test-Path $functionPath)) {
    Write-Host "ERROR: Functions directory not found at $functionPath" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    $functionPath = ".\Functions"
}

$functionFiles = Get-ChildItem -Path "$functionPath\*.ps1" -ErrorAction SilentlyContinue
Write-Host "Found $($functionFiles.Count) function files" -ForegroundColor Yellow

foreach ($file in $functionFiles) {
    try {
        . $file.FullName
        Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $($file.Name): $_" -ForegroundColor Red
    }
}

# Verify Send-Alert is loaded
if (Get-Command -Name Send-Alert -ErrorAction SilentlyContinue) {
    Write-Host "Send-Alert function is loaded and ready!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Send-Alert function not loaded!" -ForegroundColor Red
}

Write-Host "DAT functions loaded successfully!" -ForegroundColor Green

# Load configuration (after all functions are loaded)
try {
    if (Get-Command -Name Get-Configuration -ErrorAction SilentlyContinue) {
        $script:config = Get-Configuration
        if ($null -eq $script:config) {
            Write-Host "No configuration found, using defaults" -ForegroundColor Yellow
        } else {
            Write-Host "Configuration loaded successfully!" -ForegroundColor Green
        }
    } else {
        Write-Host "Configuration function not available, using defaults" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not load configuration: $_" -ForegroundColor Yellow
}

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DAT - Advanced Audit Tool v2.0"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Create TabControl for different sections
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(1160, 730)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($tabControl)

# ============================================
# TAB 1: AUDIT FUNCTIONS
# ============================================
$auditTab = New-Object System.Windows.Forms.TabPage
$auditTab.Text = "Run Audits"
$auditTab.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$tabControl.TabPages.Add($auditTab)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "System Audit Functions"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$titleLabel.Size = New-Object System.Drawing.Size(400, 30)
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$auditTab.Controls.Add($titleLabel)

# Function Selection Group Box
$functionGroup = New-Object System.Windows.Forms.GroupBox
$functionGroup.Text = "Available Audit Functions"
$functionGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$functionGroup.Size = New-Object System.Drawing.Size(300, 450)
$functionGroup.Location = New-Object System.Drawing.Point(20, 50)
$auditTab.Controls.Add($functionGroup)

# Checkboxes for functions
$functions = @(
    "SystemUptime", "RunningProcesses", "PerformanceMetrics", "HardwareInventory",
    "EventLogSummary", "SecurityUpdateStatus", "SoftwareLicensing", "WindowsUpdateHistory",
    "DriversInformation", "BackupStatus", "OpenPorts", "UserGroups", "RegistryScan", "DiskHealth"
)

$checkboxes = @()
$yPos = 30
foreach ($func in $functions) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $func -replace '([A-Z])', ' $1'
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $checkbox.Size = New-Object System.Drawing.Size(250, 25)
    $checkbox.Location = New-Object System.Drawing.Point(20, $yPos)
    $checkbox.Checked = $false
    $functionGroup.Controls.Add($checkbox)
    $checkboxes += $checkbox
    $yPos += 25
}

# Select All / Clear All buttons
$buttonYPos = $yPos + 10
$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Select All"
$selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$selectAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$selectAllBtn.Location = New-Object System.Drawing.Point(20, $buttonYPos)
$selectAllBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $true }
})
$functionGroup.Controls.Add($selectAllBtn)

$clearAllBtn = New-Object System.Windows.Forms.Button
$clearAllBtn.Text = "Clear All"
$clearAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$clearAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$clearAllBtn.Location = New-Object System.Drawing.Point(110, $buttonYPos)
$clearAllBtn.Add_Click({
    foreach ($cb in $checkboxes) { $cb.Checked = $false }
})
$functionGroup.Controls.Add($clearAllBtn)

# Run Audit Button
$runAuditBtn = New-Object System.Windows.Forms.Button
$runAuditBtn.Text = "Run Selected Audits"
$runAuditBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$runAuditBtn.Size = New-Object System.Drawing.Size(220, 45)
$runAuditBtn.Location = New-Object System.Drawing.Point(350, 50)
$runAuditBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$runAuditBtn.ForeColor = [System.Drawing.Color]::White
$runAuditBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$auditTab.Controls.Add($runAuditBtn)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(550, 25)
$progressBar.Location = New-Object System.Drawing.Point(350, 110)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$auditTab.Controls.Add($progressBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to run audits..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.Size = New-Object System.Drawing.Size(550, 25)
$statusLabel.Location = New-Object System.Drawing.Point(350, 145)
$auditTab.Controls.Add($statusLabel)

# Results DataGridView
$resultsGrid = New-Object System.Windows.Forms.DataGridView
$resultsGrid.Size = New-Object System.Drawing.Size(780, 400)
$resultsGrid.Location = New-Object System.Drawing.Point(350, 180)
$resultsGrid.AllowUserToAddRows = $false
$resultsGrid.AllowUserToDeleteRows = $false
$resultsGrid.ReadOnly = $true
$resultsGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells
$resultsGrid.BackgroundColor = [System.Drawing.Color]::White
$auditTab.Controls.Add($resultsGrid)

# Export Buttons
$exportCsvBtn = New-Object System.Windows.Forms.Button
$exportCsvBtn.Text = "Export to CSV"
$exportCsvBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportCsvBtn.Size = New-Object System.Drawing.Size(140, 40)
$exportCsvBtn.Location = New-Object System.Drawing.Point(350, 595)
$exportCsvBtn.Enabled = $false
$auditTab.Controls.Add($exportCsvBtn)

$exportHtmlBtn = New-Object System.Windows.Forms.Button
$exportHtmlBtn.Text = "HTML Report"
$exportHtmlBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportHtmlBtn.Size = New-Object System.Drawing.Size(140, 40)
$exportHtmlBtn.Location = New-Object System.Drawing.Point(500, 595)
$exportHtmlBtn.Enabled = $false
$auditTab.Controls.Add($exportHtmlBtn)

# Run Compliance Check Button
$complianceBtn = New-Object System.Windows.Forms.Button
$complianceBtn.Text = "Compliance Check"
$complianceBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$complianceBtn.Size = New-Object System.Drawing.Size(140, 40)
$complianceBtn.Location = New-Object System.Drawing.Point(650, 595)
$auditTab.Controls.Add($complianceBtn)

# Send Alert Button
$sendAlertBtn = New-Object System.Windows.Forms.Button
$sendAlertBtn.Text = "Send Test Alert"
$sendAlertBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$sendAlertBtn.Size = New-Object System.Drawing.Size(140, 40)
$sendAlertBtn.Location = New-Object System.Drawing.Point(800, 595)
$auditTab.Controls.Add($sendAlertBtn)

# ============================================
# TAB 2: SETTINGS / CONFIGURATION
# ============================================
$settingsTab = New-Object System.Windows.Forms.TabPage
$settingsTab.Text = "Settings"
$settingsTab.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$tabControl.TabPages.Add($settingsTab)

# Settings Title
$settingsTitle = New-Object System.Windows.Forms.Label
$settingsTitle.Text = "Configuration & Settings"
$settingsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$settingsTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$settingsTitle.Size = New-Object System.Drawing.Size(400, 30)
$settingsTitle.Location = New-Object System.Drawing.Point(20, 10)
$settingsTab.Controls.Add($settingsTitle)

# Thresholds Group
$thresholdsGroup = New-Object System.Windows.Forms.GroupBox
$thresholdsGroup.Text = "Performance Thresholds"
$thresholdsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$thresholdsGroup.Size = New-Object System.Drawing.Size(500, 200)
$thresholdsGroup.Location = New-Object System.Drawing.Point(20, 50)
$settingsTab.Controls.Add($thresholdsGroup)

# CPU Warning Threshold
$cpuWarnLabel = New-Object System.Windows.Forms.Label
$cpuWarnLabel.Text = "CPU Usage Warning (%):"
$cpuWarnLabel.Location = New-Object System.Drawing.Point(20, 30)
$cpuWarnLabel.Size = New-Object System.Drawing.Size(200, 20)
$thresholdsGroup.Controls.Add($cpuWarnLabel)

$cpuWarnText = New-Object System.Windows.Forms.TextBox
$cpuWarnText.Location = New-Object System.Drawing.Point(230, 27)
$cpuWarnText.Size = New-Object System.Drawing.Size(100, 20)
$cpuWarnText.Text = if ($script:config) { $script:config.thresholds.cpuUsageWarning } else { "70" }
$thresholdsGroup.Controls.Add($cpuWarnText)

# CPU Critical Threshold
$cpuCritLabel = New-Object System.Windows.Forms.Label
$cpuCritLabel.Text = "CPU Usage Critical (%):"
$cpuCritLabel.Location = New-Object System.Drawing.Point(20, 60)
$cpuCritLabel.Size = New-Object System.Drawing.Size(200, 20)
$thresholdsGroup.Controls.Add($cpuCritLabel)

$cpuCritText = New-Object System.Windows.Forms.TextBox
$cpuCritText.Location = New-Object System.Drawing.Point(230, 57)
$cpuCritText.Size = New-Object System.Drawing.Size(100, 20)
$cpuCritText.Text = if ($script:config) { $script:config.thresholds.cpuUsageCritical } else { "90" }
$thresholdsGroup.Controls.Add($cpuCritText)

# Memory Warning Threshold
$memWarnLabel = New-Object System.Windows.Forms.Label
$memWarnLabel.Text = "Memory Usage Warning (%):"
$memWarnLabel.Location = New-Object System.Drawing.Point(20, 90)
$memWarnLabel.Size = New-Object System.Drawing.Size(200, 20)
$thresholdsGroup.Controls.Add($memWarnLabel)

$memWarnText = New-Object System.Windows.Forms.TextBox
$memWarnText.Location = New-Object System.Drawing.Point(230, 87)
$memWarnText.Size = New-Object System.Drawing.Size(100, 20)
$memWarnText.Text = if ($script:config) { $script:config.thresholds.memoryUsageWarning } else { "80" }
$thresholdsGroup.Controls.Add($memWarnText)

# Memory Critical Threshold
$memCritLabel = New-Object System.Windows.Forms.Label
$memCritLabel.Text = "Memory Usage Critical (%):"
$memCritLabel.Location = New-Object System.Drawing.Point(20, 120)
$memCritLabel.Size = New-Object System.Drawing.Size(200, 20)
$thresholdsGroup.Controls.Add($memCritLabel)

$memCritText = New-Object System.Windows.Forms.TextBox
$memCritText.Location = New-Object System.Drawing.Point(230, 117)
$memCritText.Size = New-Object System.Drawing.Size(100, 20)
$memCritText.Text = if ($script:config) { $script:config.thresholds.memoryUsageCritical } else { "95" }
$thresholdsGroup.Controls.Add($memCritText)

# Save Thresholds Button
$saveThresholdsBtn = New-Object System.Windows.Forms.Button
$saveThresholdsBtn.Text = "Save Thresholds"
$saveThresholdsBtn.Location = New-Object System.Drawing.Point(230, 150)
$saveThresholdsBtn.Size = New-Object System.Drawing.Size(150, 30)
$thresholdsGroup.Controls.Add($saveThresholdsBtn)

# Alerting Group
$alertingGroup = New-Object System.Windows.Forms.GroupBox
$alertingGroup.Text = "Alerting Configuration"
$alertingGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$alertingGroup.Size = New-Object System.Drawing.Size(500, 250)
$alertingGroup.Location = New-Object System.Drawing.Point(20, 260)
$settingsTab.Controls.Add($alertingGroup)

# Enable Alerting Checkbox
$enableAlertingCheck = New-Object System.Windows.Forms.CheckBox
$enableAlertingCheck.Text = "Enable Alerting System"
$enableAlertingCheck.Location = New-Object System.Drawing.Point(20, 30)
$enableAlertingCheck.Size = New-Object System.Drawing.Size(200, 20)
$enableAlertingCheck.Checked = if ($script:config) { $script:config.alerting.enabled } else { $false }
$alertingGroup.Controls.Add($enableAlertingCheck)

# Email Settings
$emailLabel = New-Object System.Windows.Forms.Label
$emailLabel.Text = "Email Settings:"
$emailLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$emailLabel.Location = New-Object System.Drawing.Point(20, 60)
$emailLabel.Size = New-Object System.Drawing.Size(200, 20)
$alertingGroup.Controls.Add($emailLabel)

$smtpLabel = New-Object System.Windows.Forms.Label
$smtpLabel.Text = "SMTP Server:"
$smtpLabel.Location = New-Object System.Drawing.Point(40, 85)
$smtpLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($smtpLabel)

$smtpText = New-Object System.Windows.Forms.TextBox
$smtpText.Location = New-Object System.Drawing.Point(150, 82)
$smtpText.Size = New-Object System.Drawing.Size(200, 20)
$smtpText.Text = if ($script:config) { $script:config.alerting.email.smtpServer } else { "smtp.company.com" }
$alertingGroup.Controls.Add($smtpText)

$emailToLabel = New-Object System.Windows.Forms.Label
$emailToLabel.Text = "To Email:"
$emailToLabel.Location = New-Object System.Drawing.Point(40, 115)
$emailToLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($emailToLabel)

$emailToText = New-Object System.Windows.Forms.TextBox
$emailToText.Location = New-Object System.Drawing.Point(150, 112)
$emailToText.Size = New-Object System.Drawing.Size(200, 20)
$emailToText.Text = if ($script:config -and $script:config.alerting.email.to) { $script:config.alerting.email.to -join ";" } else { "admin@company.com" }
$alertingGroup.Controls.Add($emailToText)

# Webhook Settings
$webhookLabel = New-Object System.Windows.Forms.Label
$webhookLabel.Text = "Webhook URL (Discord/Slack/Teams):"
$webhookLabel.Location = New-Object System.Drawing.Point(40, 145)
$webhookLabel.Size = New-Object System.Drawing.Size(220, 20)
$alertingGroup.Controls.Add($webhookLabel)

$webhookText = New-Object System.Windows.Forms.TextBox
$webhookText.Location = New-Object System.Drawing.Point(40, 170)
$webhookText.Size = New-Object System.Drawing.Size(430, 20)
$webhookText.Text = if ($script:config) { $script:config.alerting.webhook.url } else { "https://discord.com/api/webhooks/..." }
$alertingGroup.Controls.Add($webhookText)

# Save Alert Settings Button
$saveAlertBtn = New-Object System.Windows.Forms.Button
$saveAlertBtn.Text = "Save Alert Settings"
$saveAlertBtn.Location = New-Object System.Drawing.Point(40, 205)
$saveAlertBtn.Size = New-Object System.Drawing.Size(150, 30)
$alertingGroup.Controls.Add($saveAlertBtn)

# Test Alert Button
$testAlertBtn = New-Object System.Windows.Forms.Button
$testAlertBtn.Text = "Test Alert"
$testAlertBtn.Location = New-Object System.Drawing.Point(200, 205)
$testAlertBtn.Size = New-Object System.Drawing.Size(120, 30)
$alertingGroup.Controls.Add($testAlertBtn)

# ============================================
# TAB 3: SCHEDULING
# ============================================
$scheduleTab = New-Object System.Windows.Forms.TabPage
$scheduleTab.Text = "Scheduled Audits"
$scheduleTab.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$tabControl.TabPages.Add($scheduleTab)

# Schedule Title
$scheduleTitle = New-Object System.Windows.Forms.Label
$scheduleTitle.Text = "Scheduled Audit Configuration"
$scheduleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$scheduleTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$scheduleTitle.Size = New-Object System.Drawing.Size(400, 30)
$scheduleTitle.Location = New-Object System.Drawing.Point(20, 10)
$scheduleTab.Controls.Add($scheduleTitle)

# Schedule Settings Group
$scheduleGroup = New-Object System.Windows.Forms.GroupBox
$scheduleGroup.Text = "Create Scheduled Audit"
$scheduleGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$scheduleGroup.Size = New-Object System.Drawing.Size(500, 300)
$scheduleGroup.Location = New-Object System.Drawing.Point(20, 50)
$scheduleTab.Controls.Add($scheduleGroup)

# Task Name
$taskNameLabel = New-Object System.Windows.Forms.Label
$taskNameLabel.Text = "Task Name:"
$taskNameLabel.Location = New-Object System.Drawing.Point(20, 30)
$taskNameLabel.Size = New-Object System.Drawing.Size(100, 20)
$scheduleGroup.Controls.Add($taskNameLabel)

$taskNameText = New-Object System.Windows.Forms.TextBox
$taskNameText.Location = New-Object System.Drawing.Point(130, 27)
$taskNameText.Size = New-Object System.Drawing.Size(250, 20)
$taskNameText.Text = "DAT_Daily_Audit"
$scheduleGroup.Controls.Add($taskNameText)

# Frequency
$freqLabel = New-Object System.Windows.Forms.Label
$freqLabel.Text = "Frequency:"
$freqLabel.Location = New-Object System.Drawing.Point(20, 60)
$freqLabel.Size = New-Object System.Drawing.Size(100, 20)
$scheduleGroup.Controls.Add($freqLabel)

$freqCombo = New-Object System.Windows.Forms.ComboBox
$freqCombo.Location = New-Object System.Drawing.Point(130, 57)
$freqCombo.Size = New-Object System.Drawing.Size(150, 20)
$freqCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$freqCombo.Items.AddRange(@("Daily", "Weekly", "Monthly"))
$freqCombo.SelectedIndex = 0
$scheduleGroup.Controls.Add($freqCombo)

# Time
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "Time:"
$timeLabel.Location = New-Object System.Drawing.Point(20, 90)
$timeLabel.Size = New-Object System.Drawing.Size(100, 20)
$scheduleGroup.Controls.Add($timeLabel)

$timeText = New-Object System.Windows.Forms.TextBox
$timeText.Location = New-Object System.Drawing.Point(130, 87)
$timeText.Size = New-Object System.Drawing.Size(100, 20)
$timeText.Text = "09:00"
$scheduleGroup.Controls.Add($timeText)

# Enable Email Alerts for Schedule
$scheduleEmailCheck = New-Object System.Windows.Forms.CheckBox
$scheduleEmailCheck.Text = "Send email alerts for this schedule"
$scheduleEmailCheck.Location = New-Object System.Drawing.Point(130, 120)
$scheduleEmailCheck.Size = New-Object System.Drawing.Size(300, 20)
$scheduleGroup.Controls.Add($scheduleEmailCheck)

# Create Schedule Button
$createScheduleBtn = New-Object System.Windows.Forms.Button
$createScheduleBtn.Text = "Create Scheduled Task"
$createScheduleBtn.Location = New-Object System.Drawing.Point(130, 150)
$createScheduleBtn.Size = New-Object System.Drawing.Size(180, 35)
$createScheduleBtn.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$createScheduleBtn.ForeColor = [System.Drawing.Color]::White
$createScheduleBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$scheduleGroup.Controls.Add($createScheduleBtn)

# View Scheduled Tasks Button
$viewSchedulesBtn = New-Object System.Windows.Forms.Button
$viewSchedulesBtn.Text = "View Scheduled Tasks"
$viewSchedulesBtn.Location = New-Object System.Drawing.Point(130, 195)
$viewSchedulesBtn.Size = New-Object System.Drawing.Size(180, 35)
$scheduleGroup.Controls.Add($viewSchedulesBtn)

# ============================================
# TAB 4: PLUGINS
# ============================================
$pluginsTab = New-Object System.Windows.Forms.TabPage
$pluginsTab.Text = "Plugins"
$pluginsTab.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$tabControl.TabPages.Add($pluginsTab)

# Plugins Title
$pluginsTitle = New-Object System.Windows.Forms.Label
$pluginsTitle.Text = "Plugin Management"
$pluginsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$pluginsTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$pluginsTitle.Size = New-Object System.Drawing.Size(400, 30)
$pluginsTitle.Location = New-Object System.Drawing.Point(20, 10)
$pluginsTab.Controls.Add($pluginsTitle)

# Available Plugins List
$pluginsListBox = New-Object System.Windows.Forms.ListBox
$pluginsListBox.Location = New-Object System.Drawing.Point(20, 50)
$pluginsListBox.Size = New-Object System.Drawing.Size(400, 300)
$pluginsListBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$pluginsTab.Controls.Add($pluginsListBox)

# Refresh Plugins Button
$refreshPluginsBtn = New-Object System.Windows.Forms.Button
$refreshPluginsBtn.Text = "Refresh Plugins"
$refreshPluginsBtn.Location = New-Object System.Drawing.Point(20, 360)
$refreshPluginsBtn.Size = New-Object System.Drawing.Size(150, 35)
$pluginsTab.Controls.Add($refreshPluginsBtn)

# Run Plugin Button
$runPluginBtn = New-Object System.Windows.Forms.Button
$runPluginBtn.Text = "Run Selected Plugin"
$runPluginBtn.Location = New-Object System.Drawing.Point(180, 360)
$runPluginBtn.Size = New-Object System.Drawing.Size(150, 35)
$runPluginBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$runPluginBtn.ForeColor = [System.Drawing.Color]::White
$runPluginBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$pluginsTab.Controls.Add($runPluginBtn)

# Create New Plugin Button
$createPluginBtn = New-Object System.Windows.Forms.Button
$createPluginBtn.Text = "Create New Plugin"
$createPluginBtn.Location = New-Object System.Drawing.Point(340, 360)
$createPluginBtn.Size = New-Object System.Drawing.Size(150, 35)
$pluginsTab.Controls.Add($createPluginBtn)

# Plugin Output
$pluginOutputLabel = New-Object System.Windows.Forms.Label
$pluginOutputLabel.Text = "Plugin Output:"
$pluginOutputLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$pluginOutputLabel.Location = New-Object System.Drawing.Point(450, 50)
$pluginOutputLabel.Size = New-Object System.Drawing.Size(200, 20)
$pluginsTab.Controls.Add($pluginOutputLabel)

$pluginOutputBox = New-Object System.Windows.Forms.TextBox
$pluginOutputBox.Location = New-Object System.Drawing.Point(450, 80)
$pluginOutputBox.Size = New-Object System.Drawing.Size(650, 270)
$pluginOutputBox.Multiline = $true
$pluginOutputBox.ScrollBars = "Vertical"
$pluginOutputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$pluginOutputBox.ReadOnly = $true
$pluginsTab.Controls.Add($pluginOutputBox)

# ============================================
# EVENT HANDLERS
# ============================================

# Run Audit Button Click Event (from Tab 1)
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

    $runAuditBtn.Enabled = $false
    $exportCsvBtn.Enabled = $false
    $exportHtmlBtn.Enabled = $false

    $resultsGrid.Rows.Clear()
    $resultsGrid.Columns.Clear()
    $statusLabel.Text = "Running audits..."
    $progressBar.Value = 0

    # Run audits
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
                $displayData = [PSCustomObject]@{
                    Function = $func
                    Status = "Success"
                }
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
        $allColumns = @{}
        foreach ($item in $allData) {
            foreach ($prop in $item.PSObject.Properties) {
                $allColumns[$prop.Name] = $true
            }
        }
        
        foreach ($colName in $allColumns.Keys) {
            $column = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $column.Name = $colName
            $column.HeaderText = $colName
            $column.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
            $resultsGrid.Columns.Add($column) | Out-Null
        }
        
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

    $script:auditResults = $auditResults
    $script:allData = $allData

    # Send Webhook Alert if enabled
    if ($script:config -and $script:config.alerting.enabled -and $script:config.alerting.webhook.url) {
        try {
            # Ensure Send-Alert is loaded
            if (-not (Get-Command -Name Send-Alert -ErrorAction SilentlyContinue)) {
                $alertPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Send-Alert.ps1"
                if (Test-Path $alertPath) {
                    . $alertPath
                }
            }

            $alertMessage = "Audit Run Completed on $env:COMPUTERNAME`n`n"
            $alertMessage += "Total Functions: $($selectedFunctions.Count)`n"
            $attachments = @()
            
            foreach ($func in $selectedFunctions) {
                $res = $auditResults[$func]
                $status = $res.Status
                $alertMessage += "- $func`: $status`n"
                
                if ($func -eq "PerformanceMetrics" -and $status -eq "Success") {
                    $metrics = $res.Data
                    $alertMessage += "   - CPU: $($metrics.CPUUsagePercent)%`n"
                    $alertMessage += "   - Memory: $($metrics.MemoryUsagePercent)%`n"
                }

                if ($func -eq "SystemUptime" -and $status -eq "Success") {
                    $uptime = $res.Data
                    $alertMessage += "   - Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes`n"
                    $alertMessage += "   - Last Boot: $($uptime.LastBootTime)`n"
                }

                if ($func -eq "RunningProcesses" -and $status -eq "Success") {
                    $processes = $res.Data
                    if ($processes) {
                        $procFilePath = "$env:TEMP\DAT_RunningProcesses_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
                        $processes | Format-Table -AutoSize | Out-String | Set-Content -Path $procFilePath
                        $attachments += $procFilePath
                        $alertMessage += "   - Running Processes list attached as file.`n"
                    }
                }
            }

            Send-Alert -Subject "DAT Audit Summary" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config -Attachments $attachments
            
            # Cleanup attachments
            foreach ($file in $attachments) {
                if (Test-Path $file) { Remove-Item $file -ErrorAction SilentlyContinue }
            }
        } catch {
            $statusLabel.Text = "Audit completed. Alert failed: $($_.Exception.Message)"
        }
    }

    $exportCsvBtn.Enabled = $true
    $exportHtmlBtn.Enabled = $true
    $runAuditBtn.Enabled = $true
})

# Export CSV Button
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
            $exportPath = $saveDialog.FileName
            $directory = Split-Path -Path $exportPath -Parent
            $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($exportPath)
            $exportedFiles = @()

            foreach ($func in $script:auditResults.Keys) {
                $result = $script:auditResults[$func]
                if ($result.Status -eq "Success" -and $result.Data) {
                    $funcFileName = Join-Path -Path $directory -ChildPath "$baseFileName`_$func.csv"
                    if ($result.Data -is [System.Collections.IEnumerable] -and $result.Data -isnot [string]) {
                        $result.Data | Export-Csv -Path $funcFileName -NoTypeInformation
                    } else {
                        @($result.Data) | Export-Csv -Path $funcFileName -NoTypeInformation
                    }
                    $exportedFiles += $funcFileName
                }
            }

            $message = "Results exported successfully!`n`nExported $($exportedFiles.Count) files:`n"
            foreach ($file in $exportedFiles) {
                $message += "`n- $(Split-Path -Path $file -Leaf)"
            }
            [System.Windows.Forms.MessageBox]::Show($message, "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to export CSV: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

# Export HTML Button
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
            if (-not (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue)) {
                $htmlPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\New-HTMLReport.ps1"
                if (Test-Path $htmlPath) {
                    . $htmlPath
                }
            }

            $htmlData = @{}
            foreach ($key in $script:auditResults.Keys) {
                $htmlData[$key] = $script:auditResults[$key].Data
            }

            if (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue) {
                New-HTMLReport -OutputPath $saveDialog.FileName -AuditData $htmlData -CompanyName "DAT Advanced Tool"
            }
            [System.Windows.Forms.MessageBox]::Show("HTML report generated successfully:`n$($saveDialog.FileName)", "Report Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to generate HTML report: $($_.Exception.Message)", "Report Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

# Compliance Check Button
$complianceBtn.Add_Click({
    try {
        if (-not (Get-Command -Name Test-Compliance -ErrorAction SilentlyContinue)) {
            $compliancePath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Test-Compliance.ps1"
            if (Test-Path $compliancePath) {
                . $compliancePath
            } else {
                throw "Test-Compliance.ps1 not found"
            }
        }

        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "CSV files (*.csv)|*.csv"
        $saveDialog.FileName = "DAT_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $saveDialog.Title = "Save Compliance Report"

        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $complianceResults = Test-Compliance -Standards CIS,NIST -CsvPath $saveDialog.FileName
            $summary = $complianceResults | Where-Object { $_.Standard -eq "SUMMARY" }
            [System.Windows.Forms.MessageBox]::Show("Compliance Check Complete!`n`nCompliance Score: $($summary.CompliancePercentage)%`nPassed: $($summary.CurrentValue)`n`nReport saved to:`n$($saveDialog.FileName)", "Compliance Check", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to run compliance check: $($_.Exception.Message)", "Compliance Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Send Test Alert Button
$sendAlertBtn.Add_Click({
    try {
        # Check if function exists
        $sendAlertCmd = Get-Command -Name Send-Alert -ErrorAction SilentlyContinue
        if (-not $sendAlertCmd) {
            # Try to load it
            $alertPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Send-Alert.ps1"
            if (Test-Path $alertPath) {
                . $alertPath
                $sendAlertCmd = Get-Command -Name Send-Alert -ErrorAction SilentlyContinue
            }
            
            if (-not $sendAlertCmd) {
                throw "Send-Alert function could not be loaded. Path checked: $alertPath"
            }
        }

        # Call the function
        & $sendAlertCmd -Subject "DAT Test Alert" -Message "This is a test alert from DAT Advanced GUI" -Channels @("EventLog") -Severity Info
        
        [System.Windows.Forms.MessageBox]::Show("Test alert sent successfully!`n`nCheck Event Viewer > Application Log for the alert.", "Alert Sent", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorDetails = "Error: $($_.Exception.Message)`n`nScript Root: $script:ScriptRoot`n`nFunction Path: $(Join-Path -Path $script:ScriptRoot -ChildPath 'Functions\Send-Alert.ps1')"
        [System.Windows.Forms.MessageBox]::Show($errorDetails, "Alert Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Save Thresholds Button
$saveThresholdsBtn.Add_Click({
    try {
        if ($null -eq $script:config) {
            $script:config = @{
                thresholds = @{}
            }
        }

        $script:config.thresholds.cpuUsageWarning = [int]$cpuWarnText.Text
        $script:config.thresholds.cpuUsageCritical = [int]$cpuCritText.Text
        $script:config.thresholds.memoryUsageWarning = [int]$memWarnText.Text
        $script:config.thresholds.memoryUsageCritical = [int]$memCritText.Text

        $configPath = "Config\DefaultConfig.json"
        $script:config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show("Thresholds saved successfully!", "Settings Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to save thresholds: $($_.Exception.Message)", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Save Alert Settings Button
$saveAlertBtn.Add_Click({
    try {
        if ($null -eq $script:config) {
            $script:config = @{
                alerting = @{
                    email = @{}
                    webhook = @{}
                }
            }
        }

        $script:config.alerting.enabled = $enableAlertingCheck.Checked
        $script:config.alerting.email.smtpServer = $smtpText.Text
        $script:config.alerting.email.to = $emailToText.Text -split ";"
        $script:config.alerting.webhook.url = $webhookText.Text

        $configPath = "Config\DefaultConfig.json"
        $script:config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

        [System.Windows.Forms.MessageBox]::Show("Alert settings saved successfully!", "Settings Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to save alert settings: $($_.Exception.Message)", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Test Alert Button (Settings Tab)
$testAlertBtn.Add_Click({
    try {
        if (-not (Get-Command -Name Send-Alert -ErrorAction SilentlyContinue)) {
            $alertPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Send-Alert.ps1"
            if (Test-Path $alertPath) {
                . $alertPath
            } else {
                throw "Send-Alert.ps1 not found"
            }
        }

        $channels = @("EventLog")
        if ($enableAlertingCheck.Checked -and $smtpText.Text) {
            $channels += "Email"
        }
        if ($webhookText.Text -and $webhookText.Text -ne "https://hooks.slack.com/services/...") {
            $channels += "Webhook"
        }

        Send-Alert -Subject "DAT Test Alert" -Message "Testing alert configuration from Settings tab" -Channels $channels -Severity Info -Config $script:config
        [System.Windows.Forms.MessageBox]::Show("Test alert sent!`n`nChannels: $($channels -join ', ')", "Alert Test", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to send test alert: $($_.Exception.Message)", "Alert Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Create Schedule Button
$createScheduleBtn.Add_Click({
    try {
        if (-not (Get-Command -Name New-ScheduledAudit -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Functions\New-ScheduledAudit.ps1"
        }

        $taskName = $taskNameText.Text
        $frequency = $freqCombo.SelectedItem
        $time = $timeText.Text

        $enabledChecks = @()
        foreach ($i in 0..($checkboxes.Count - 1)) {
            if ($checkboxes[$i].Checked) {
                $enabledChecks += $functions[$i]
            }
        }

        if ($enabledChecks.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one audit function for the scheduled task.", "No Functions Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        New-ScheduledAudit -TaskName $taskName -Frequency $frequency -Time $time -EnabledChecks $enabledChecks -Force

        [System.Windows.Forms.MessageBox]::Show("Scheduled task created successfully!`n`nTask Name: $taskName`nFrequency: $frequency`nTime: $time`nFunctions: $($enabledChecks.Count)", "Schedule Created", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create scheduled task: $($_.Exception.Message)", "Schedule Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# View Scheduled Tasks Button
$viewSchedulesBtn.Add_Click({
    try {
        if (-not (Get-Command -Name Get-ScheduledAudits -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Functions\New-ScheduledAudit.ps1"
        }

        $tasks = Get-ScheduledAudits
        if ($tasks) {
            $message = "Scheduled DAT Tasks:`n`n"
            foreach ($task in $tasks) {
                $message += "- $($task.TaskName) - $($task.State) - Next: $($task.NextRunTime)`n"
            }
            [System.Windows.Forms.MessageBox]::Show($message, "Scheduled Tasks", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            [System.Windows.Forms.MessageBox]::Show("No scheduled DAT tasks found.", "No Tasks", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to retrieve scheduled tasks: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Refresh Plugins Button
$refreshPluginsBtn.Add_Click({
    try {
        if (-not (Get-Command -Name Get-AvailablePlugins -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Functions\Invoke-Plugin.ps1"
        }

        $pluginsListBox.Items.Clear()
        $plugins = Get-AvailablePlugins
        foreach ($plugin in $plugins) {
            $pluginsListBox.Items.Add("$($plugin.Name) - $($plugin.Description)")
        }
        $script:availablePlugins = $plugins
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load plugins: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Run Plugin Button
$runPluginBtn.Add_Click({
    if ($pluginsListBox.SelectedIndex -eq -1) {
        [System.Windows.Forms.MessageBox]::Show("Please select a plugin to run.", "No Plugin Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    try {
        if (-not (Get-Command -Name Invoke-Plugin -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Functions\Invoke-Plugin.ps1"
        }

        $selectedPlugin = $script:availablePlugins[$pluginsListBox.SelectedIndex]
        $pluginOutput = Invoke-Plugin -PluginName $selectedPlugin.Name -Parameters @{}
        $pluginOutputBox.Text = $pluginOutput | Out-String
        [System.Windows.Forms.MessageBox]::Show("Plugin executed successfully!", "Plugin Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to run plugin: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Create New Plugin Button
$createPluginBtn.Add_Click({
    try {
        if (-not (Get-Command -Name New-PluginTemplate -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\Functions\Invoke-Plugin.ps1"
        }

        $pluginName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter plugin name:", "Create Plugin", "MyCustomPlugin")
        if ($pluginName) {
            New-PluginTemplate -PluginName $pluginName -Description "Custom plugin created from GUI"
            [System.Windows.Forms.MessageBox]::Show("Plugin template created!`n`nEdit Plugins\$pluginName.ps1 to implement your custom logic.", "Plugin Created", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            $refreshPluginsBtn.PerformClick()
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create plugin: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Initialize plugins list on startup
$refreshPluginsBtn.PerformClick()

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
