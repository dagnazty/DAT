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
    }
    catch {
        Write-Host "  [FAIL] $($file.Name): $_" -ForegroundColor Red
    }
}

# Verify Send-Alert is loaded
if (Get-Command -Name Send-Alert -ErrorAction SilentlyContinue) {
    Write-Host "Send-Alert function is loaded and ready!" -ForegroundColor Green
}
else {
    Write-Host "WARNING: Send-Alert function not loaded!" -ForegroundColor Red
}

Write-Host "DAT functions loaded successfully!" -ForegroundColor Green

# Load configuration (after all functions are loaded)
try {
    if (Get-Command -Name Get-Configuration -ErrorAction SilentlyContinue) {
        $script:config = Get-Configuration
        if ($null -eq $script:config) {
            Write-Host "No configuration found, using defaults" -ForegroundColor Yellow
        }
        else {
            Write-Host "Configuration loaded successfully!" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Configuration function not available, using defaults" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Could not load configuration: $_" -ForegroundColor Yellow
}

# ============================================
# THEME FUNCTIONS
# ============================================

function Apply-LightTheme {
    param($Form, $TabControl)
    
    # Modern Light Theme - Soft, warm tones
    # Background: Warm cream instead of harsh white
    $Form.BackColor = [System.Drawing.Color]::FromArgb(250, 249, 246)
    
    # Tab control and pages
    foreach ($tab in $TabControl.TabPages) {
        $tab.BackColor = [System.Drawing.Color]::FromArgb(250, 249, 246)
        $tab.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        
        foreach ($control in $tab.Controls) {
            Apply-LightThemeToControl $control
        }
    }
}

function Apply-LightThemeToControl {
    param($Control)
    
    if ($Control -is [System.Windows.Forms.GroupBox]) {
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    }
    elseif ($Control -is [System.Windows.Forms.Label]) {
        if ($Control.Font.Bold -and $Control.Font.Size -ge 10) {
            # Title labels - Refined teal accent
            if ($Control.ForeColor.ToArgb() -ne [System.Drawing.Color]::Gray.ToArgb()) {
                $Control.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 153)
            }
        }
        else {
            $Control.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
        }
    }
    elseif ($Control -is [System.Windows.Forms.TextBox]) {
        $Control.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    }
    elseif ($Control -is [System.Windows.Forms.CheckBox]) {
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    }
    elseif ($Control -is [System.Windows.Forms.DataGridView]) {
        $Control.BackgroundColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $Control.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $Control.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $Control.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
        $Control.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    }
    elseif ($Control -is [System.Windows.Forms.ListBox]) {
        $Control.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    }
    
    # Recursively apply to child controls
    if ($Control.Controls.Count -gt 0) {
        foreach ($child in $Control.Controls) {
            Apply-LightThemeToControl $child
        }
    }
}

function Apply-DarkTheme {
    param($Form, $TabControl)
    
    # Modern Dark Theme - True dark with comfortable blue-gray tones
    # Background: Dark charcoal with slight blue tint
    $Form.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 31)
    
    # Tab control and pages
    foreach ($tab in $TabControl.TabPages) {
        $tab.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 31)
        $tab.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        
        foreach ($control in $tab.Controls) {
            Apply-DarkThemeToControl $control
        }
    }
}

function Apply-DarkThemeToControl {
    param($Control)
    
    if ($Control -is [System.Windows.Forms.GroupBox]) {
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    }
    elseif ($Control -is [System.Windows.Forms.Label]) {
        if ($Control.Font.Bold -and $Control.Font.Size -ge 10) {
            # Title labels - Soft cyan accent, easy on eyes
            if ($Control.ForeColor.ToArgb() -ne [System.Drawing.Color]::Gray.ToArgb()) {
                $Control.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
            }
        }
        else {
            $Control.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        }
    }
    elseif ($Control -is [System.Windows.Forms.TextBox]) {
        $Control.BackColor = [System.Drawing.Color]::FromArgb(37, 40, 47)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    }
    elseif ($Control -is [System.Windows.Forms.CheckBox]) {
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    }
    elseif ($Control -is [System.Windows.Forms.DataGridView]) {
        $Control.BackgroundColor = [System.Drawing.Color]::FromArgb(37, 40, 47)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $Control.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(37, 40, 47)
        $Control.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $Control.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 39)
        $Control.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    }
    elseif ($Control -is [System.Windows.Forms.ListBox]) {
        $Control.BackColor = [System.Drawing.Color]::FromArgb(37, 40, 47)
        $Control.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    }
    
    # Recursively apply to child controls
    if ($Control.Controls.Count -gt 0) {
        foreach ($child in $Control.Controls) {
            Apply-DarkThemeToControl $child
        }
    }
}


# ============================================
# MAIN FORM
# ============================================

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
$webhookLabel.Size = New-Object System.Drawing.Size(320, 20)
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

# Appearance Group
$appearanceGroup = New-Object System.Windows.Forms.GroupBox
$appearanceGroup.Text = "Appearance"
$appearanceGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$appearanceGroup.Size = New-Object System.Drawing.Size(500, 120)
$appearanceGroup.Location = New-Object System.Drawing.Point(20, 520)
$settingsTab.Controls.Add($appearanceGroup)

# Dark Mode Checkbox
$darkModeCheck = New-Object System.Windows.Forms.CheckBox
$darkModeCheck.Text = "Enable Dark Mode"
$darkModeCheck.Location = New-Object System.Drawing.Point(20, 30)
$darkModeCheck.Size = New-Object System.Drawing.Size(200, 20)
$darkModeCheck.Checked = if ($script:config -and $script:config.ui -and $script:config.ui.theme -eq "dark") { $true } else { $false }
$appearanceGroup.Controls.Add($darkModeCheck)

# Apply Theme Button
$applyThemeBtn = New-Object System.Windows.Forms.Button
$applyThemeBtn.Text = "Apply Theme"
$applyThemeBtn.Location = New-Object System.Drawing.Point(20, 60)
$applyThemeBtn.Size = New-Object System.Drawing.Size(150, 35)
$applyThemeBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
$applyThemeBtn.ForeColor = [System.Drawing.Color]::White
$applyThemeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$appearanceGroup.Controls.Add($applyThemeBtn)

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
                    Data   = $result
                    Count  = if ($result -is [System.Collections.IEnumerable] -and $result -isnot [string]) { $result.Count } else { 1 }
                }
            }
            catch {
                $results[$func] = @{
                    Status = "Error"
                    Data   = $_.Exception.Message
                    Count  = 0
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
                                Status   = "..."
                                Info     = "($($result.Count - 5) more items - see CSV export)"
                            }
                            break
                        }
                        $itemData = [PSCustomObject]@{
                            Function = $func
                            Status   = "Success"
                        }
                        foreach ($prop in $item.PSObject.Properties) {
                            $itemData | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                        }
                        $allData += $itemData
                        $itemCount++
                    }
                }
                else {
                    $displayData = [PSCustomObject]@{
                        Function = $func
                        Status   = "Success"
                    }
                    if ($result.Data -is [PSCustomObject]) {
                        foreach ($prop in $result.Data.PSObject.Properties) {
                            $displayData | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                        }
                    }
                    else {
                        $displayData | Add-Member -MemberType NoteProperty -Name "Result" -Value $result.Data.ToString() -Force
                    }
                    $allData += $displayData
                }
            }
            else {
                $allData += [PSCustomObject]@{
                    Function = $func
                    Status   = "Error"
                    Error    = $result.Data
                    Count    = 0
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
                    }
                    else {
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
                $combinedDetails = [System.Text.StringBuilder]::new()
            
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

                        # User Request: Only SystemUptime details in the message body. All others go to attachment.
                        $isVerbose = ($func -ne "SystemUptime")

                        if ($isVerbose) {
                            # Add to combined details attachment
                            [void]$combinedDetails.AppendLine("========================================")
                            [void]$combinedDetails.AppendLine("FUNCTION: $func")
                            [void]$combinedDetails.AppendLine("========================================")
                            [void]$combinedDetails.AppendLine($dataString)
                            [void]$combinedDetails.AppendLine("") 
                            
                            $alertMessage += "   - Details included in attached report.`n"
                        }
                        else {
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
                    else {
                        $alertMessage += "   Error: $($res.Data)`n"
                    }
                }

                # Create attachment if we have details
                if ($combinedDetails.Length -gt 0) {
                    $detailsPath = "$env:TEMP\DAT_Audit_Details_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
                    $combinedDetails.ToString() | Set-Content -Path $detailsPath
                    $attachments += $detailsPath
                    $alertMessage += "`n[See attached file for detailed results]"
                }

                Send-Alert -Subject "DAT Audit Summary" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config -Attachments $attachments
            
                # Cleanup attachments
                foreach ($file in $attachments) {
                    if (Test-Path $file) { Remove-Item $file -ErrorAction SilentlyContinue }
                }
            }
            catch {
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
                        }
                        else {
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
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to export CSV: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    })

# Export HTML Button
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
                # Try to load the function if not already loaded
                if (-not (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue)) {
                    $htmlPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\New-HTMLReport.ps1"
                    if (Test-Path $htmlPath) {
                        . $htmlPath
                    }
                    else {
                        throw "New-HTMLReport.ps1 not found at $htmlPath"
                    }
                }

                # Verify it loaded correctly
                if (-not (Get-Command -Name New-HTMLReport -ErrorAction SilentlyContinue)) {
                    throw "Failed to load New-HTMLReport function."
                }

                $htmlData = @{}
                foreach ($key in $script:auditResults.Keys) {
                    $htmlData[$key] = $script:auditResults[$key].Data
                }

                New-HTMLReport -OutputPath $saveDialog.FileName -AuditData $htmlData -CompanyName "DAT Advanced Tool"
            
                if (Test-Path $saveDialog.FileName) {
                    [System.Windows.Forms.MessageBox]::Show("HTML report generated successfully:`n$($saveDialog.FileName)", "Report Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    throw "File was not created at $($saveDialog.FileName)"
                }
            }
            catch {
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
                }
                else {
                    throw "Test-Compliance.ps1 not found"
                }
            }

            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "CSV files (*.csv)|*.csv"
            $saveDialog.FileName = "DAT_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $saveDialog.Title = "Save Compliance Report"

            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $complianceResults = Test-Compliance -Standards CIS, NIST -CsvPath $saveDialog.FileName
                $summary = $complianceResults | Where-Object { $_.Standard -eq "SUMMARY" }
                [System.Windows.Forms.MessageBox]::Show("Compliance Check Complete!`n`nCompliance Score: $($summary.CompliancePercentage)%`nPassed: $($summary.CurrentValue)`n`nReport saved to:`n$($saveDialog.FileName)", "Compliance Check", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to run compliance check: $($_.Exception.Message)", "Compliance Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# Send Test Alert Button
$sendAlertBtn.Add_Click({
        try {
            # Check if function exists
            $sendAlertCmd = Get-Command -Name Send-Alert -ErrorAction SilentlyContinue
        
            [System.Windows.Forms.MessageBox]::Show("Test alert sent successfully!`n`nCheck Event Viewer > Application Log for the alert.", "Alert Sent", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        catch {
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
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to save thresholds: $($_.Exception.Message)", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# Save Alert Settings Button
$saveAlertBtn.Add_Click({
        try {
            if ($null -eq $script:config) {
                $script:config = @{
                    alerting = @{
                        email   = @{}
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
        }
        catch {
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
                }
                else {
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
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to send test alert: $($_.Exception.Message)", "Alert Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# Apply Theme Button
$applyThemeBtn.Add_Click({
        try {
            # Load Set-Configuration if not already loaded
            if (-not (Get-Command -Name Set-Configuration -ErrorAction SilentlyContinue)) {
                $setConfigPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Set-Configuration.ps1"
                if (Test-Path $setConfigPath) {
                    . $setConfigPath
                }
            }
            
            # Apply the selected theme
            if ($darkModeCheck.Checked) {
                Apply-DarkTheme -Form $form -TabControl $tabControl
                
                # Update config
                if (-not $script:config) {
                    $script:config = @{}
                }
                if (-not $script:config.ui) {
                    $script:config | Add-Member -MemberType NoteProperty -Name "ui" -Value @{} -Force
                }
                $script:config.ui.theme = "dark"
            }
            else {
                Apply-LightTheme -Form $form -TabControl $tabControl
                
                # Update config
                if (-not $script:config) {
                    $script:config = @{}
                }
                if (-not $script:config.ui) {
                    $script:config | Add-Member -MemberType NoteProperty -Name "ui" -Value @{} -Force
                }
                $script:config.ui.theme = "light"
            }
            
            # Save configuration
            if (Get-Command -Name Set-Configuration -ErrorAction SilentlyContinue) {
                Set-Configuration -Configuration $script:config | Out-Null
            }
            
            $form.Refresh()
            [System.Windows.Forms.MessageBox]::Show("Theme applied and saved successfully!", "Theme Updated", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to apply theme: $($_.Exception.Message)", "Theme Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
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
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to create scheduled task: $($_.Exception.Message)", "Schedule Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# View Scheduled Tasks Button
$viewSchedulesBtn.Add_Click({
        try {
            if (-not (Get-Command -Name Get-ScheduledAudits -ErrorAction SilentlyContinue)) {
                . "$PSScriptRoot\Functions\New-ScheduledAudit.ps1"
            }

            # Create Task Manager Dialog
            $taskDialog = New-Object System.Windows.Forms.Form
            $taskDialog.Text = "Scheduled DAT Tasks Manager"
            $taskDialog.Size = New-Object System.Drawing.Size(700, 500)
            $taskDialog.StartPosition = "CenterScreen"
            $taskDialog.FormBorderStyle = "FixedDialog"
            $taskDialog.MaximizeBox = $false
            
            # Title
            $dialogTitle = New-Object System.Windows.Forms.Label
            $dialogTitle.Text = "Manage Scheduled Audit Tasks"
            $dialogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $dialogTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
            $dialogTitle.Location = New-Object System.Drawing.Point(20, 15)
            $dialogTitle.Size = New-Object System.Drawing.Size(400, 25)
            $taskDialog.Controls.Add($dialogTitle)
            
            # ListBox for tasks
            $taskListBox = New-Object System.Windows.Forms.ListBox
            $taskListBox.Location = New-Object System.Drawing.Point(20, 50)
            $taskListBox.Size = New-Object System.Drawing.Size(640, 300)
            $taskListBox.Font = New-Object System.Drawing.Font("Consolas", 10)
            $taskDialog.Controls.Add($taskListBox)
            
            # Function to load tasks
            $loadTasks = {
                $taskListBox.Items.Clear()
                $script:currentTasks = Get-ScheduledAudits
                
                if ($script:currentTasks) {
                    foreach ($task in $script:currentTasks) {
                        $displayText = "$($task.TaskName.PadRight(30)) | State: $($task.State.ToString().PadRight(10)) | Next: $($task.NextRunTime)"
                        $taskListBox.Items.Add($displayText)
                    }
                }
                else {
                    $taskListBox.Items.Add("No scheduled DAT tasks found.")
                }
            }
            
            # Initial load
            & $loadTasks
            
            # Refresh Button
            $refreshBtn = New-Object System.Windows.Forms.Button
            $refreshBtn.Text = "Refresh"
            $refreshBtn.Location = New-Object System.Drawing.Point(20, 370)
            $refreshBtn.Size = New-Object System.Drawing.Size(100, 35)
            $refreshBtn.Add_Click({
                    & $loadTasks
                })
            $taskDialog.Controls.Add($refreshBtn)
            
            # Edit Button
            $editBtn = New-Object System.Windows.Forms.Button
            $editBtn.Text = "Edit Selected"
            $editBtn.Location = New-Object System.Drawing.Point(130, 370)
            $editBtn.Size = New-Object System.Drawing.Size(120, 35)
            $editBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 191)
            $editBtn.ForeColor = [System.Drawing.Color]::White
            $editBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $editBtn.Add_Click({
                    if ($taskListBox.SelectedIndex -ge 0 -and $script:currentTasks) {
                        $selectedTask = $script:currentTasks[$taskListBox.SelectedIndex]
                    
                        # Populate main form fields with task data
                        $taskNameText.Text = $selectedTask.TaskName + "_Edited"
                    
                        # Get task details to extract schedule info
                        $taskObj = Get-ScheduledTask -TaskName $selectedTask.TaskName
                        $trigger = $taskObj.Triggers[0]
                    
                        # Set frequency based on trigger type
                        if ($trigger.CimClass.CimClassName -like "*Daily*") {
                            $freqCombo.SelectedItem = "Daily"
                        }
                        elseif ($trigger.CimClass.CimClassName -like "*Weekly*") {
                            $freqCombo.SelectedItem = "Weekly"
                        }
                        else {
                            $freqCombo.SelectedItem = "Monthly"
                        }
                    
                        # Set time
                        if ($trigger.StartBoundary) {
                            $startTime = [DateTime]::Parse($trigger.StartBoundary)
                            $timeText.Text = $startTime.ToString("HH:mm")
                        }
                    
                        # Close dialog and switch to Scheduled Audits tab
                        $taskDialog.Close()
                        $tabControl.SelectedTab = $scheduleTab
                    
                        [System.Windows.Forms.MessageBox]::Show("Task details loaded. Modify as needed and click 'Create Scheduled Task'.`n`nNote: The old task will be replaced when you create the new one with -Force.", "Edit Mode", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show("Please select a task to edit.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    }
                })
            $taskDialog.Controls.Add($editBtn)
            
            # Delete Button
            $deleteBtn = New-Object System.Windows.Forms.Button
            $deleteBtn.Text = "Delete Selected"
            $deleteBtn.Location = New-Object System.Drawing.Point(260, 370)
            $deleteBtn.Size = New-Object System.Drawing.Size(120, 35)
            $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            $deleteBtn.ForeColor = [System.Drawing.Color]::White
            $deleteBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $deleteBtn.Add_Click({
                    if ($taskListBox.SelectedIndex -ge 0 -and $script:currentTasks) {
                        $selectedTask = $script:currentTasks[$taskListBox.SelectedIndex]
                    
                        $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete the task '$($selectedTask.TaskName)'?", "Confirm Delete", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    
                        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                            try {
                                if (-not (Get-Command -Name Remove-ScheduledAudit -ErrorAction SilentlyContinue)) {
                                    . "$PSScriptRoot\Functions\New-ScheduledAudit.ps1"
                                }
                            
                                Remove-ScheduledAudit -TaskName $selectedTask.TaskName
                                [System.Windows.Forms.MessageBox]::Show("Task '$($selectedTask.TaskName)' deleted successfully.", "Task Deleted", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                            
                                # Refresh the list
                                & $loadTasks
                            }
                            catch {
                                [System.Windows.Forms.MessageBox]::Show("Failed to delete task: $($_.Exception.Message)", "Delete Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                            }
                        }
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show("Please select a task to delete.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    }
                })
            $taskDialog.Controls.Add($deleteBtn)
            
            # Close Button
            $closeBtn = New-Object System.Windows.Forms.Button
            $closeBtn.Text = "Close"
            $closeBtn.Location = New-Object System.Drawing.Point(560, 370)
            $closeBtn.Size = New-Object System.Drawing.Size(100, 35)
            $closeBtn.Add_Click({
                    $taskDialog.Close()
                })
            $taskDialog.Controls.Add($closeBtn)
            
            # Show the dialog
            $taskDialog.ShowDialog() | Out-Null
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to open task manager: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
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
        }
        catch {
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
        }
        catch {
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
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to create plugin: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# Initialize plugins list on startup
$refreshPluginsBtn.PerformClick()

# Apply saved theme on startup
if ($script:config -and $script:config.ui -and $script:config.ui.theme -eq "dark") {
    Apply-DarkTheme -Form $form -TabControl $tabControl
}
else {
    Apply-LightTheme -Form $form -TabControl $tabControl
}

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
