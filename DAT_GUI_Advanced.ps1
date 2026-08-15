# DAT - Advanced Graphical User Interface
# PowerShell GUI for the DAT audit tool, branded around the DAT skull mark.
# Themes: "Reaper" (dark, default) and "Bone" (light) - both monochrome black/white,
# with blood red reserved for destructive/critical actions.

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
# BRAND PALETTE
# ============================================

# Reaper (dark) palette
$script:ReaperBg     = [System.Drawing.Color]::FromArgb(12, 12, 14)     # near black
$script:ReaperPanel  = [System.Drawing.Color]::FromArgb(23, 23, 27)     # charcoal panel
$script:ReaperField  = [System.Drawing.Color]::FromArgb(32, 32, 37)     # input fields
$script:ReaperBorder = [System.Drawing.Color]::FromArgb(64, 64, 70)
$script:ReaperText   = [System.Drawing.Color]::FromArgb(236, 233, 226)  # bone white
$script:ReaperDim    = [System.Drawing.Color]::FromArgb(148, 146, 140)

# Bone (light) palette
$script:BoneBg     = [System.Drawing.Color]::FromArgb(244, 242, 237)    # bone white
$script:BonePanel  = [System.Drawing.Color]::FromArgb(252, 251, 248)
$script:BoneField  = [System.Drawing.Color]::FromArgb(255, 255, 255)
$script:BoneBorder = [System.Drawing.Color]::FromArgb(180, 178, 172)
$script:BoneText   = [System.Drawing.Color]::FromArgb(18, 18, 20)       # near black
$script:BoneDim    = [System.Drawing.Color]::FromArgb(105, 103, 98)

# Shared
$script:BloodRed = [System.Drawing.Color]::FromArgb(170, 32, 38)        # destructive / critical only

$script:ThemeIsDark = $true

# ============================================
# THEME FUNCTIONS
# ============================================

function Set-ThemedButton {
    param($Button, [bool]$Dark)

    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 1
    $Button.UseVisualStyleBackColor = $false

    switch ("$($Button.Tag)") {
        'primary' {
            if ($Dark) {
                $Button.BackColor = $script:ReaperText
                $Button.ForeColor = $script:ReaperBg
                $Button.FlatAppearance.BorderColor = $script:ReaperText
            }
            else {
                $Button.BackColor = $script:BoneText
                $Button.ForeColor = $script:BoneBg
                $Button.FlatAppearance.BorderColor = $script:BoneText
            }
        }
        'danger' {
            $Button.BackColor = $script:BloodRed
            $Button.ForeColor = [System.Drawing.Color]::White
            $Button.FlatAppearance.BorderColor = $script:BloodRed
        }
        default {
            if ($Dark) {
                $Button.BackColor = $script:ReaperPanel
                $Button.ForeColor = $script:ReaperText
                $Button.FlatAppearance.BorderColor = $script:ReaperBorder
            }
            else {
                $Button.BackColor = $script:BonePanel
                $Button.ForeColor = $script:BoneText
                $Button.FlatAppearance.BorderColor = $script:BoneBorder
            }
        }
    }
}

function Apply-ThemeToControl {
    param($Control, [bool]$Dark)

    if ($Dark) {
        $bg = $script:ReaperBg; $panel = $script:ReaperPanel; $field = $script:ReaperField
        $text = $script:ReaperText; $dim = $script:ReaperDim; $border = $script:ReaperBorder
    }
    else {
        $bg = $script:BoneBg; $panel = $script:BonePanel; $field = $script:BoneField
        $text = $script:BoneText; $dim = $script:BoneDim; $border = $script:BoneBorder
    }

    if ($Control -is [System.Windows.Forms.GroupBox]) {
        $Control.ForeColor = $dim
    }
    elseif ($Control -is [System.Windows.Forms.Label]) {
        if ("$($Control.Tag)" -eq 'category') {
            # Category headers in the audit check list
            $Control.ForeColor = $dim
        }
        else {
            $Control.ForeColor = $text
        }
    }
    elseif ($Control -is [System.Windows.Forms.Panel]) {
        $Control.BackColor = $bg
    }
    elseif ($Control -is [System.Windows.Forms.TextBox]) {
        $Control.BackColor = $field
        $Control.ForeColor = $text
        $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    }
    elseif ($Control -is [System.Windows.Forms.CheckBox]) {
        $Control.ForeColor = $text
    }
    elseif ($Control -is [System.Windows.Forms.Button]) {
        Set-ThemedButton -Button $Control -Dark $Dark
    }
    elseif ($Control -is [System.Windows.Forms.ComboBox]) {
        $Control.BackColor = $field
        $Control.ForeColor = $text
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    }
    elseif ($Control -is [System.Windows.Forms.DataGridView]) {
        $Control.EnableHeadersVisualStyles = $false
        $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $Control.BackgroundColor = $panel
        $Control.GridColor = $border
        $Control.ForeColor = $text
        $Control.DefaultCellStyle.BackColor = $panel
        $Control.DefaultCellStyle.ForeColor = $text
        $Control.DefaultCellStyle.SelectionBackColor = $border
        $Control.DefaultCellStyle.SelectionForeColor = $text
        $Control.ColumnHeadersDefaultCellStyle.BackColor = $bg
        $Control.ColumnHeadersDefaultCellStyle.ForeColor = $dim
        $Control.RowHeadersDefaultCellStyle.BackColor = $bg
        $Control.RowHeadersDefaultCellStyle.ForeColor = $dim
    }
    elseif ($Control -is [System.Windows.Forms.ListBox]) {
        $Control.BackColor = $field
        $Control.ForeColor = $text
        $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    }

    # Recursively apply to child controls
    if ($Control.Controls.Count -gt 0) {
        foreach ($child in $Control.Controls) {
            Apply-ThemeToControl $child -Dark $Dark
        }
    }
}

function Apply-DarkTheme {
    param($Form, $TabControl)

    $script:ThemeIsDark = $true
    $Form.BackColor = $script:ReaperBg

    foreach ($tab in $TabControl.TabPages) {
        $tab.BackColor = $script:ReaperBg
        $tab.ForeColor = $script:ReaperText

        foreach ($control in $tab.Controls) {
            Apply-ThemeToControl $control -Dark $true
        }
    }
    $TabControl.Invalidate()
}

function Apply-LightTheme {
    param($Form, $TabControl)

    $script:ThemeIsDark = $false
    $Form.BackColor = $script:BoneBg

    foreach ($tab in $TabControl.TabPages) {
        $tab.BackColor = $script:BoneBg
        $tab.ForeColor = $script:BoneText

        foreach ($control in $tab.Controls) {
            Apply-ThemeToControl $control -Dark $false
        }
    }
    $TabControl.Invalidate()
}

function Apply-ThemeToDialog {
    param($Dialog)

    if ($script:ThemeIsDark) {
        $Dialog.BackColor = $script:ReaperBg
    }
    else {
        $Dialog.BackColor = $script:BoneBg
    }
    foreach ($control in $Dialog.Controls) {
        Apply-ThemeToControl $control -Dark $script:ThemeIsDark
    }
}

# ============================================
# MAIN FORM
# ============================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "DAT - dag's Audit Tool"
$form.Size = New-Object System.Drawing.Size(1200, 886)
$form.MinimumSize = New-Object System.Drawing.Size(1200, 886)
$form.StartPosition = "CenterScreen"
$form.BackColor = $script:ReaperBg

# ============================================
# HEADER - skull mark banner (always black, both themes)
# ============================================

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(1200, 86)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 6)
$form.Controls.Add($headerPanel)

$logoImage = $null
$logoPath = Join-Path -Path $script:ScriptRoot -ChildPath "Assets\dat_logo_dark.png"
if (Test-Path $logoPath) {
    try {
        $logoImage = [System.Drawing.Image]::FromFile($logoPath)

        $logoBox = New-Object System.Windows.Forms.PictureBox
        $logoBox.Image = $logoImage
        $logoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $logoBox.Size = New-Object System.Drawing.Size(64, 64)
        $logoBox.Location = New-Object System.Drawing.Point(20, 11)
        $logoBox.BackColor = [System.Drawing.Color]::Transparent
        $headerPanel.Controls.Add($logoBox)

        # Window icon derived from the mark
        $iconBitmap = New-Object System.Drawing.Bitmap($logoImage, 64, 64)
        $form.Icon = [System.Drawing.Icon]::FromHandle($iconBitmap.GetHicon())
    }
    catch {
        Write-Host "Could not load logo: $_" -ForegroundColor Yellow
    }
}

$brandTitle = New-Object System.Windows.Forms.Label
$brandTitle.Text = "DAG'S AUDIT TOOL"
$brandTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$brandTitle.ForeColor = $script:ReaperText
$brandTitle.BackColor = [System.Drawing.Color]::Transparent
$brandTitle.AutoSize = $true
$brandTitle.Location = New-Object System.Drawing.Point(98, 14)
$headerPanel.Controls.Add($brandTitle)

$brandSub = New-Object System.Windows.Forms.Label
$brandSub.Text = "SYSTEM AUDIT  //  COMPLIANCE  //  ALERTING          v2.0"
$brandSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$brandSub.ForeColor = $script:ReaperDim
$brandSub.BackColor = [System.Drawing.Color]::Transparent
$brandSub.AutoSize = $true
$brandSub.Location = New-Object System.Drawing.Point(101, 54)
$headerPanel.Controls.Add($brandSub)

# Thin bone-white rule under the header
$headerRule = New-Object System.Windows.Forms.Panel
$headerRule.Size = New-Object System.Drawing.Size(1200, 2)
$headerRule.Location = New-Object System.Drawing.Point(0, 84)
$headerRule.Dock = [System.Windows.Forms.DockStyle]::Bottom
$headerRule.BackColor = $script:ReaperText
$headerPanel.Controls.Add($headerRule)

# ============================================
# TAB CONTROL (owner-drawn for theming)
# ============================================

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(1160, 740)
$tabControl.Location = New-Object System.Drawing.Point(10, 96)
$tabControl.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Right,Bottom"
$tabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
$tabControl.ItemSize = New-Object System.Drawing.Size(170, 34)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$tabControl.Add_DrawItem({
        param($sender, $e)

        if ($script:ThemeIsDark) {
            $bgColor = $script:ReaperBg; $selBg = $script:ReaperPanel
            $fgColor = $script:ReaperDim; $selFg = $script:ReaperText
            $rule = $script:ReaperText
        }
        else {
            $bgColor = $script:BoneBg; $selBg = $script:BonePanel
            $fgColor = $script:BoneDim; $selFg = $script:BoneText
            $rule = $script:BoneText
        }

        $rect = $sender.GetTabRect($e.Index)
        $selected = ($sender.SelectedIndex -eq $e.Index)

        if ($selected) { $fill = $selBg; $textColor = $selFg } else { $fill = $bgColor; $textColor = $fgColor }

        $brush = New-Object System.Drawing.SolidBrush($fill)
        $e.Graphics.FillRectangle($brush, $rect)
        $brush.Dispose()

        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $textBrush = New-Object System.Drawing.SolidBrush($textColor)
        $e.Graphics.DrawString($sender.TabPages[$e.Index].Text, $sender.Font, $textBrush, [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height), $sf)
        $textBrush.Dispose()
        $sf.Dispose()

        if ($selected) {
            $ruleBrush = New-Object System.Drawing.SolidBrush($rule)
            $e.Graphics.FillRectangle($ruleBrush, $rect.X, $rect.Bottom - 3, $rect.Width, 3)
            $ruleBrush.Dispose()
        }
    })
$form.Controls.Add($tabControl)

# ============================================
# TAB 1: AUDIT FUNCTIONS
# ============================================
$auditTab = New-Object System.Windows.Forms.TabPage
$auditTab.Text = "Run Audits"
$tabControl.TabPages.Add($auditTab)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "System Audit Functions"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Size = New-Object System.Drawing.Size(400, 30)
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$auditTab.Controls.Add($titleLabel)

# Function Selection Group Box
$functionGroup = New-Object System.Windows.Forms.GroupBox
$functionGroup.Text = "Available Audit Functions"
$functionGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$functionGroup.Size = New-Object System.Drawing.Size(300, 615)
$functionGroup.Location = New-Object System.Drawing.Point(20, 50)
$auditTab.Controls.Add($functionGroup)

# Audit checks grouped by category
$functionCategories = [ordered]@{
    "SYSTEM HEALTH"     = @("SystemUptime", "PerformanceMetrics", "DiskHealth", "BackupStatus", "PendingReboot", "EventLogSummary")
    "INVENTORY"         = @("HardwareInventory", "InstalledSoftware", "SoftwareLicensing", "DriversInformation", "RunningProcesses", "WindowsUpdateHistory")
    "SECURITY POSTURE"  = @("SecurityUpdateStatus", "DefenderHealth", "FirewallStatus", "BitLockerStatus", "InsecureProtocols", "CertificateExpiry")
    "THREAT HUNTING"    = @("Autoruns", "ServicesAudit", "RegistryScan", "OpenPorts", "FailedLogons", "USBHistory")
    "ACCOUNTS & ACCESS" = @("UserGroups", "PrivilegedAccounts", "SharesAudit")
}
$functions = @($functionCategories.Values | ForEach-Object { $_ })

# Scrollable panel holding the categorized checkboxes
$functionPanel = New-Object System.Windows.Forms.Panel
$functionPanel.Location = New-Object System.Drawing.Point(10, 22)
$functionPanel.Size = New-Object System.Drawing.Size(280, 540)
$functionPanel.AutoScroll = $true
$functionGroup.Controls.Add($functionPanel)

$checkboxes = @()
$yPos = 5
foreach ($category in $functionCategories.Keys) {
    $catLabel = New-Object System.Windows.Forms.Label
    $catLabel.Text = $category
    $catLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $catLabel.Size = New-Object System.Drawing.Size(240, 18)
    $catLabel.Location = New-Object System.Drawing.Point(8, $yPos)
    $catLabel.Tag = 'category'
    $functionPanel.Controls.Add($catLabel)
    $yPos += 20

    foreach ($func in $functionCategories[$category]) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $displayName = ($func -creplace '(?<=[a-z])([A-Z])', ' $1') -creplace '([A-Z]+)([A-Z][a-z])', '$1 $2'
        $checkbox.Text = $displayName
        $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $checkbox.Size = New-Object System.Drawing.Size(230, 22)
        $checkbox.Location = New-Object System.Drawing.Point(20, $yPos)
        $checkbox.Checked = $false
        $functionPanel.Controls.Add($checkbox)
        $checkboxes += $checkbox
        $yPos += 23
    }
    $yPos += 8
}

# Select All / Clear All buttons
$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Select All"
$selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$selectAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$selectAllBtn.Location = New-Object System.Drawing.Point(20, 572)
$selectAllBtn.Add_Click({
        foreach ($cb in $checkboxes) { $cb.Checked = $true }
    })
$functionGroup.Controls.Add($selectAllBtn)

$clearAllBtn = New-Object System.Windows.Forms.Button
$clearAllBtn.Text = "Clear All"
$clearAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$clearAllBtn.Size = New-Object System.Drawing.Size(80, 30)
$clearAllBtn.Location = New-Object System.Drawing.Point(110, 572)
$clearAllBtn.Add_Click({
        foreach ($cb in $checkboxes) { $cb.Checked = $false }
    })
$functionGroup.Controls.Add($clearAllBtn)

# Run Audit Button
$runAuditBtn = New-Object System.Windows.Forms.Button
$runAuditBtn.Text = "RUN SELECTED AUDITS"
$runAuditBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$runAuditBtn.Size = New-Object System.Drawing.Size(220, 45)
$runAuditBtn.Location = New-Object System.Drawing.Point(350, 50)
$runAuditBtn.Tag = 'primary'
$auditTab.Controls.Add($runAuditBtn)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(550, 25)
$progressBar.Location = New-Object System.Drawing.Point(350, 110)
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Right"
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
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Right"
$auditTab.Controls.Add($statusLabel)

# Results DataGridView
$resultsGrid = New-Object System.Windows.Forms.DataGridView
$resultsGrid.Size = New-Object System.Drawing.Size(780, 400)
$resultsGrid.Location = New-Object System.Drawing.Point(350, 180)
$resultsGrid.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Right,Bottom"
$resultsGrid.AllowUserToAddRows = $false
$resultsGrid.AllowUserToDeleteRows = $false
$resultsGrid.ReadOnly = $true
$resultsGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells
$auditTab.Controls.Add($resultsGrid)

# Export Buttons
$exportCsvBtn = New-Object System.Windows.Forms.Button
$exportCsvBtn.Text = "Export to CSV"
$exportCsvBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportCsvBtn.Size = New-Object System.Drawing.Size(140, 40)
$exportCsvBtn.Location = New-Object System.Drawing.Point(350, 595)
$exportCsvBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$exportCsvBtn.Enabled = $false
$auditTab.Controls.Add($exportCsvBtn)

$exportHtmlBtn = New-Object System.Windows.Forms.Button
$exportHtmlBtn.Text = "HTML Report"
$exportHtmlBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$exportHtmlBtn.Size = New-Object System.Drawing.Size(140, 40)
$exportHtmlBtn.Location = New-Object System.Drawing.Point(500, 595)
$exportHtmlBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$exportHtmlBtn.Enabled = $false
$auditTab.Controls.Add($exportHtmlBtn)

# Run Compliance Check Button
$complianceBtn = New-Object System.Windows.Forms.Button
$complianceBtn.Text = "Compliance Check"
$complianceBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$complianceBtn.Size = New-Object System.Drawing.Size(140, 40)
$complianceBtn.Location = New-Object System.Drawing.Point(650, 595)
$complianceBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$auditTab.Controls.Add($complianceBtn)

# Send Alert Button
$sendAlertBtn = New-Object System.Windows.Forms.Button
$sendAlertBtn.Text = "Send Test Alert"
$sendAlertBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$sendAlertBtn.Size = New-Object System.Drawing.Size(140, 40)
$sendAlertBtn.Location = New-Object System.Drawing.Point(800, 595)
$sendAlertBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$auditTab.Controls.Add($sendAlertBtn)

# ============================================
# TAB 2: SETTINGS / CONFIGURATION
# ============================================
$settingsTab = New-Object System.Windows.Forms.TabPage
$settingsTab.Text = "Settings"
$tabControl.TabPages.Add($settingsTab)

# Settings Title
$settingsTitle = New-Object System.Windows.Forms.Label
$settingsTitle.Text = "Configuration & Settings"
$settingsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
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
$cpuWarnText.Text = if ($script:config -and $script:config.thresholds.cpuUsageWarning) { $script:config.thresholds.cpuUsageWarning } else { "70" }
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
$cpuCritText.Text = if ($script:config -and $script:config.thresholds.cpuUsageCritical) { $script:config.thresholds.cpuUsageCritical } else { "90" }
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
$memWarnText.Text = if ($script:config -and $script:config.thresholds.memoryUsageWarning) { $script:config.thresholds.memoryUsageWarning } else { "80" }
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
$memCritText.Text = if ($script:config -and $script:config.thresholds.memoryUsageCritical) { $script:config.thresholds.memoryUsageCritical } else { "95" }
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
$alertingGroup.Size = New-Object System.Drawing.Size(1090, 300)
$alertingGroup.Location = New-Object System.Drawing.Point(20, 260)
$settingsTab.Controls.Add($alertingGroup)

$emailCfg = if ($script:config -and $script:config.alerting -and $script:config.alerting.email) { $script:config.alerting.email } else { $null }

# Enable Alerting Checkbox
$enableAlertingCheck = New-Object System.Windows.Forms.CheckBox
$enableAlertingCheck.Text = "Enable Alerting System"
$enableAlertingCheck.Location = New-Object System.Drawing.Point(20, 26)
$enableAlertingCheck.Size = New-Object System.Drawing.Size(250, 20)
$enableAlertingCheck.Checked = if ($script:config) { $script:config.alerting.enabled } else { $false }
$alertingGroup.Controls.Add($enableAlertingCheck)

# ---- Left column: Email (SMTP) ----
$emailLabel = New-Object System.Windows.Forms.Label
$emailLabel.Text = "Email (SMTP):"
$emailLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$emailLabel.Location = New-Object System.Drawing.Point(20, 54)
$emailLabel.Size = New-Object System.Drawing.Size(200, 20)
$alertingGroup.Controls.Add($emailLabel)

$emailFieldX = 150
$emailFieldW = 250

# From
$emailFromLabel = New-Object System.Windows.Forms.Label
$emailFromLabel.Text = "From:"
$emailFromLabel.Location = New-Object System.Drawing.Point(40, 82)
$emailFromLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($emailFromLabel)

$emailFromText = New-Object System.Windows.Forms.TextBox
$emailFromText.Location = New-Object System.Drawing.Point($emailFieldX, 80)
$emailFromText.Size = New-Object System.Drawing.Size($emailFieldW, 20)
$emailFromText.Text = if ($emailCfg -and $emailCfg.from) { $emailCfg.from } else { "" }
$alertingGroup.Controls.Add($emailFromText)

# To
$emailToLabel = New-Object System.Windows.Forms.Label
$emailToLabel.Text = "To (; separated):"
$emailToLabel.Location = New-Object System.Drawing.Point(40, 110)
$emailToLabel.Size = New-Object System.Drawing.Size(105, 20)
$alertingGroup.Controls.Add($emailToLabel)

$emailToText = New-Object System.Windows.Forms.TextBox
$emailToText.Location = New-Object System.Drawing.Point($emailFieldX, 108)
$emailToText.Size = New-Object System.Drawing.Size($emailFieldW, 20)
$emailToText.Text = if ($emailCfg -and $emailCfg.to) { $emailCfg.to -join ";" } else { "" }
$alertingGroup.Controls.Add($emailToText)

# SMTP Server
$smtpLabel = New-Object System.Windows.Forms.Label
$smtpLabel.Text = "SMTP Server:"
$smtpLabel.Location = New-Object System.Drawing.Point(40, 138)
$smtpLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($smtpLabel)

$smtpText = New-Object System.Windows.Forms.TextBox
$smtpText.Location = New-Object System.Drawing.Point($emailFieldX, 136)
$smtpText.Size = New-Object System.Drawing.Size($emailFieldW, 20)
$smtpText.Text = if ($emailCfg -and $emailCfg.smtpServer) { $emailCfg.smtpServer } else { "smtp.mail.me.com" }
$alertingGroup.Controls.Add($smtpText)

# Port + SSL
$portLabel = New-Object System.Windows.Forms.Label
$portLabel.Text = "Port:"
$portLabel.Location = New-Object System.Drawing.Point(40, 166)
$portLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($portLabel)

$emailPortText = New-Object System.Windows.Forms.TextBox
$emailPortText.Location = New-Object System.Drawing.Point($emailFieldX, 164)
$emailPortText.Size = New-Object System.Drawing.Size(60, 20)
$emailPortText.Text = if ($emailCfg -and $emailCfg.port) { "$($emailCfg.port)" } else { "587" }
$alertingGroup.Controls.Add($emailPortText)

$emailSslCheck = New-Object System.Windows.Forms.CheckBox
$emailSslCheck.Text = "Use SSL/TLS"
$emailSslCheck.Location = New-Object System.Drawing.Point(225, 165)
$emailSslCheck.Size = New-Object System.Drawing.Size(120, 20)
$emailSslCheck.Checked = if ($emailCfg -and $null -ne $emailCfg.useSSL) { [bool]$emailCfg.useSSL } else { $true }
$alertingGroup.Controls.Add($emailSslCheck)

# Username
$emailUserLabel = New-Object System.Windows.Forms.Label
$emailUserLabel.Text = "Username:"
$emailUserLabel.Location = New-Object System.Drawing.Point(40, 194)
$emailUserLabel.Size = New-Object System.Drawing.Size(100, 20)
$alertingGroup.Controls.Add($emailUserLabel)

$emailUserText = New-Object System.Windows.Forms.TextBox
$emailUserText.Location = New-Object System.Drawing.Point($emailFieldX, 192)
$emailUserText.Size = New-Object System.Drawing.Size($emailFieldW, 20)
$emailUserText.Text = if ($emailCfg -and $emailCfg.username) { $emailCfg.username } else { "" }
$alertingGroup.Controls.Add($emailUserText)

# App Password
$emailPassLabel = New-Object System.Windows.Forms.Label
$emailPassLabel.Text = "App Password:"
$emailPassLabel.Location = New-Object System.Drawing.Point(40, 222)
$emailPassLabel.Size = New-Object System.Drawing.Size(105, 20)
$alertingGroup.Controls.Add($emailPassLabel)

$emailPassText = New-Object System.Windows.Forms.TextBox
$emailPassText.Location = New-Object System.Drawing.Point($emailFieldX, 220)
$emailPassText.Size = New-Object System.Drawing.Size($emailFieldW, 20)
$emailPassText.UseSystemPasswordChar = $true
# Placeholder shown when a credential is already saved
$script:credentialPath = Join-Path -Path $script:ScriptRoot -ChildPath "Config\smtp.cred.xml"
if ($emailCfg -and $emailCfg.credentialPath -and (Test-Path $emailCfg.credentialPath)) {
    $emailPassText.Text = "********"
}
$alertingGroup.Controls.Add($emailPassText)

# Hint
$emailHintLabel = New-Object System.Windows.Forms.Label
$emailHintLabel.Text = "iCloud/Gmail/Outlook require an app-specific password, not your normal password."
$emailHintLabel.Location = New-Object System.Drawing.Point(40, 248)
$emailHintLabel.Size = New-Object System.Drawing.Size(370, 34)
$alertingGroup.Controls.Add($emailHintLabel)

# ---- Right column: Webhook ----
$webhookLabel = New-Object System.Windows.Forms.Label
$webhookLabel.Text = "Webhook URL (Discord/Slack/Teams):"
$webhookLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$webhookLabel.Location = New-Object System.Drawing.Point(560, 54)
$webhookLabel.Size = New-Object System.Drawing.Size(320, 20)
$alertingGroup.Controls.Add($webhookLabel)

$webhookText = New-Object System.Windows.Forms.TextBox
$webhookText.Location = New-Object System.Drawing.Point(560, 80)
$webhookText.Size = New-Object System.Drawing.Size(500, 20)
$webhookText.Text = if ($script:config -and $script:config.alerting.webhook) { $script:config.alerting.webhook.url } else { "https://discord.com/api/webhooks/..." }
$alertingGroup.Controls.Add($webhookText)

# iCloud quick-setup reference
$icloudNote = New-Object System.Windows.Forms.Label
$icloudNote.Text = "iCloud setup:" + [char]10 +
    "  Server smtp.mail.me.com  -  Port 587  -  SSL/TLS on" + [char]10 +
    "  Username = full @icloud.com address" + [char]10 +
    "  App password: appleid.apple.com > Sign-In & Security >" + [char]10 +
    "  App-Specific Passwords > generate one, paste it above." + [char]10 +
    "  From must be your iCloud address (or a verified alias)."
$icloudNote.Location = New-Object System.Drawing.Point(560, 120)
$icloudNote.Size = New-Object System.Drawing.Size(510, 110)
$alertingGroup.Controls.Add($icloudNote)

# Save Alert Settings Button
$saveAlertBtn = New-Object System.Windows.Forms.Button
$saveAlertBtn.Text = "Save Alert Settings"
$saveAlertBtn.Location = New-Object System.Drawing.Point(560, 245)
$saveAlertBtn.Size = New-Object System.Drawing.Size(160, 35)
$saveAlertBtn.Tag = 'primary'
$alertingGroup.Controls.Add($saveAlertBtn)

# Test Alert Button
$testAlertBtn = New-Object System.Windows.Forms.Button
$testAlertBtn.Text = "Send Test Alert"
$testAlertBtn.Location = New-Object System.Drawing.Point(730, 245)
$testAlertBtn.Size = New-Object System.Drawing.Size(160, 35)
$alertingGroup.Controls.Add($testAlertBtn)

# Appearance Group
$appearanceGroup = New-Object System.Windows.Forms.GroupBox
$appearanceGroup.Text = "Appearance"
$appearanceGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$appearanceGroup.Size = New-Object System.Drawing.Size(500, 110)
$appearanceGroup.Location = New-Object System.Drawing.Point(20, 575)
$settingsTab.Controls.Add($appearanceGroup)

# Dark Mode Checkbox
$darkModeCheck = New-Object System.Windows.Forms.CheckBox
$darkModeCheck.Text = "Reaper theme (dark) - uncheck for Bone (light)"
$darkModeCheck.Location = New-Object System.Drawing.Point(20, 30)
$darkModeCheck.Size = New-Object System.Drawing.Size(350, 20)
$darkModeCheck.Checked = if ($script:config -and $script:config.ui -and $script:config.ui.theme -eq "light") { $false } else { $true }
$appearanceGroup.Controls.Add($darkModeCheck)

# Apply Theme Button
$applyThemeBtn = New-Object System.Windows.Forms.Button
$applyThemeBtn.Text = "Apply Theme"
$applyThemeBtn.Location = New-Object System.Drawing.Point(20, 60)
$applyThemeBtn.Size = New-Object System.Drawing.Size(150, 35)
$applyThemeBtn.Tag = 'primary'
$appearanceGroup.Controls.Add($applyThemeBtn)

# ============================================
# TAB 3: SCHEDULING
# ============================================
$scheduleTab = New-Object System.Windows.Forms.TabPage
$scheduleTab.Text = "Scheduled Audits"
$tabControl.TabPages.Add($scheduleTab)

# Schedule Title
$scheduleTitle = New-Object System.Windows.Forms.Label
$scheduleTitle.Text = "Scheduled Audit Configuration"
$scheduleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
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
$createScheduleBtn.Tag = 'primary'
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
$tabControl.TabPages.Add($pluginsTab)

# Plugins Title
$pluginsTitle = New-Object System.Windows.Forms.Label
$pluginsTitle.Text = "Plugin Management"
$pluginsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$pluginsTitle.Size = New-Object System.Drawing.Size(400, 30)
$pluginsTitle.Location = New-Object System.Drawing.Point(20, 10)
$pluginsTab.Controls.Add($pluginsTitle)

# Left column (x 20-420): plugin list with its buttons below.
# Right column (x 450+): output pane. Neither may cross the 450 boundary.

# Available Plugins List
$pluginsListBox = New-Object System.Windows.Forms.ListBox
$pluginsListBox.Location = New-Object System.Drawing.Point(20, 50)
$pluginsListBox.Size = New-Object System.Drawing.Size(400, 545)
$pluginsListBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$pluginsListBox.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Bottom"
$pluginsTab.Controls.Add($pluginsListBox)

# Refresh Plugins Button
$refreshPluginsBtn = New-Object System.Windows.Forms.Button
$refreshPluginsBtn.Text = "Refresh Plugins"
$refreshPluginsBtn.Location = New-Object System.Drawing.Point(20, 605)
$refreshPluginsBtn.Size = New-Object System.Drawing.Size(185, 35)
$refreshPluginsBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$pluginsTab.Controls.Add($refreshPluginsBtn)

# Run Plugin Button
$runPluginBtn = New-Object System.Windows.Forms.Button
$runPluginBtn.Text = "Run Selected Plugin"
$runPluginBtn.Location = New-Object System.Drawing.Point(235, 605)
$runPluginBtn.Size = New-Object System.Drawing.Size(185, 35)
$runPluginBtn.Tag = 'primary'
$runPluginBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
$pluginsTab.Controls.Add($runPluginBtn)

# Create New Plugin Button
$createPluginBtn = New-Object System.Windows.Forms.Button
$createPluginBtn.Text = "Create New Plugin"
$createPluginBtn.Location = New-Object System.Drawing.Point(20, 650)
$createPluginBtn.Size = New-Object System.Drawing.Size(400, 35)
$createPluginBtn.Anchor = [System.Windows.Forms.AnchorStyles]"Left,Bottom"
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
$pluginOutputBox.Size = New-Object System.Drawing.Size(650, 605)
$pluginOutputBox.Anchor = [System.Windows.Forms.AnchorStyles]"Top,Left,Right,Bottom"
$pluginOutputBox.Multiline = $true
$pluginOutputBox.ScrollBars = "Vertical"
$pluginOutputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$pluginOutputBox.ReadOnly = $true
$pluginsTab.Controls.Add($pluginOutputBox)

# ============================================
# EVENT HANDLERS
# ============================================

# Poll timer that marshals background audit progress onto the UI thread
$script:AuditTimer = New-Object System.Windows.Forms.Timer
$script:AuditTimer.Interval = 200
$script:AuditTimer.Add_Tick({
        $sync = $script:AuditSync
        if (-not $sync) { return }

        $progressBar.Value = [math]::Max(0, [math]::Min([int]$sync.Progress, 100))
        if ($sync.Status) { $statusLabel.Text = $sync.Status }

        if ($sync.Done) {
            $script:AuditTimer.Stop()
            try { [void]$script:AuditPS.EndInvoke($script:AuditHandle) } catch { }
            if ($script:AuditPS) { $script:AuditPS.Dispose() }
            $script:AuditPS = $null
            $script:AuditSync = $null
            Complete-AuditRun -AuditResults $sync.Results -SelectedFunctions $script:AuditSelected
        }
    })

# Stop any in-flight audit when the window closes
$form.Add_FormClosing({
        if ($script:AuditPS) {
            $script:AuditTimer.Stop()
            try { $script:AuditPS.Stop() } catch { }
            try { $script:AuditPS.Dispose() } catch { }
            $script:AuditPS = $null
            $script:AuditSync = $null
        }
    })

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

        # Run audits in a background runspace so the UI stays responsive
        $sync = [hashtable]::Synchronized(@{ Progress = 0; Status = "Starting audit run..."; Done = $false; Results = $null })
        $script:AuditSync = $sync
        $script:AuditSelected = $selectedFunctions

        $ps = [powershell]::Create()
        [void]$ps.AddScript({
                param($ScriptRoot, $Selected, $Sync)

                $functionMap = @{
                    "SystemUptime"         = "Get-SystemUptime"
                    "RunningProcesses"     = "Get-RunningProcesses"
                    "PerformanceMetrics"   = "Get-PerformanceMetrics"
                    "HardwareInventory"    = "Get-HardwareInventory"
                    "EventLogSummary"      = "Get-EventLogSummary"
                    "SecurityUpdateStatus" = "Get-SecurityUpdateStatus"
                    "SoftwareLicensing"    = "Get-SoftwareLicensing"
                    "WindowsUpdateHistory" = "Get-WindowsUpdateHistory"
                    "DriversInformation"   = "Get-DriversInformation"
                    "BackupStatus"         = "Get-BackupStatus"
                    "OpenPorts"            = "Get-OpenPorts"
                    "UserGroups"           = "Get-UserGroupMemberships"
                    "RegistryScan"         = "Scan-SuspiciousRegistryEntries"
                    "DiskHealth"           = "Get-DiskHealth"
                    "FirewallStatus"       = "Get-FirewallStatus"
                    "BitLockerStatus"      = "Get-BitLockerStatus"
                    "InstalledSoftware"    = "Get-InstalledSoftware"
                    "PendingReboot"        = "Get-PendingReboot"
                    "Autoruns"             = "Get-AutorunEntries"
                    "ServicesAudit"        = "Get-ServicesAudit"
                    "DefenderHealth"       = "Get-DefenderHealth"
                    "InsecureProtocols"    = "Get-InsecureProtocols"
                    "CertificateExpiry"    = "Get-CertificateExpiry"
                    "FailedLogons"         = "Get-FailedLogons"
                    "USBHistory"           = "Get-USBHistory"
                    "PrivilegedAccounts"   = "Get-PrivilegedAccounts"
                    "SharesAudit"          = "Get-SharesAudit"
                }

                # The runspace starts empty - load the audit functions into it
                foreach ($file in (Get-ChildItem -Path (Join-Path -Path $ScriptRoot -ChildPath "Functions\*.ps1") -ErrorAction SilentlyContinue)) {
                    try { . $file.FullName } catch { }
                }

                $results = @{}
                $total = $Selected.Count
                $i = 0
                foreach ($func in $Selected) {
                    $i++
                    $Sync.Progress = [math]::Round(($i / $total) * 90)
                    $Sync.Status = "Running $func... ($i of $total)"

                    try {
                        $result = & $functionMap[$func]
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

                $Sync.Results = $results
                $Sync.Done = $true
            })
        [void]$ps.AddArgument($script:ScriptRoot)
        [void]$ps.AddArgument($selectedFunctions)
        [void]$ps.AddArgument($sync)

        $script:AuditPS = $ps
        $script:AuditHandle = $ps.BeginInvoke()
        $script:AuditTimer.Start()
    })

# Completion of an audit run - called on the UI thread by the poll timer
function Complete-AuditRun {
    param($AuditResults, $SelectedFunctions)

    $auditResults = $AuditResults
    $selectedFunctions = $SelectedFunctions

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

        # Send alerts (webhook and/or email) when alerting is enabled and configured.
        # Email counts as "configured" only once a credential has been saved.
        $webhookConfigured = $script:config -and $script:config.alerting.webhook -and $script:config.alerting.webhook.url
        $emailConfigured = $script:config -and $script:config.alerting.email -and $script:config.alerting.email.smtpServer -and (Test-Path $script:credentialPath)
        if ($script:config -and $script:config.alerting.enabled -and ($webhookConfigured -or $emailConfigured)) {
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

                # Send each channel independently so one failing (e.g. a bad
                # SMTP credential) never blocks the other from going out.
                $sent = @()
                $failed = @()
                if ($webhookConfigured) {
                    try {
                        Send-Alert -Subject "DAT Audit Summary" -Message $alertMessage -Channels "Webhook" -Severity "Info" -Config $script:config -Attachments $attachments
                        $sent += "Discord"
                    }
                    catch { $failed += "webhook - $($_.Exception.Message)" }
                }
                if ($emailConfigured) {
                    try {
                        Send-Alert -Subject "DAT Audit Summary" -Message $alertMessage -Channels "Email" -Severity "Info" -Config $script:config -Attachments $attachments
                        $sent += "Email"
                    }
                    catch { $failed += "email - $($_.Exception.Message)" }
                }

                # Cleanup attachments
                foreach ($file in $attachments) {
                    if (Test-Path $file) { Remove-Item $file -ErrorAction SilentlyContinue }
                }

                if ($failed.Count -gt 0) {
                    $statusLabel.Text = "Audit completed. Sent: $($sent -join ', '). Failed: $($failed -join '; ')"
                }
                elseif ($sent.Count -gt 0) {
                    $statusLabel.Text = "Audit completed! Alerts sent: $($sent -join ', ')."
                }
            }
            catch {
                $statusLabel.Text = "Audit completed. Alert failed: $($_.Exception.Message)"
            }
        }

        $exportCsvBtn.Enabled = $true
        $exportHtmlBtn.Enabled = $true
        $runAuditBtn.Enabled = $true
}

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
            # Only attempt email if it's actually set up (saved credential)
            if ($script:config -and $script:config.alerting.enabled -and $script:config.alerting.email.smtpServer -and (Test-Path $script:credentialPath)) {
                $channels += "Email"
            }
            if ($script:config -and $script:config.alerting.webhook.url) {
                $channels += "Webhook"
            }

            Send-Alert -Subject "DAT Test Alert" -Message "Test alert sent from the Run Audits tab on $env:COMPUTERNAME" -Channels $channels -Severity Info -Config $script:config
            [System.Windows.Forms.MessageBox]::Show("Test alert sent!`n`nChannels: $($channels -join ', ')", "Alert Sent", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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

            $configPath = Join-Path -Path $script:ScriptRoot -ChildPath "Config\DefaultConfig.json"
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

            # Normalize the config into a plain hashtable so we can add the new
            # email keys whether config came from JSON (PSCustomObject) or not
            $emailHash = @{
                from       = $emailFromText.Text.Trim()
                to         = @($emailToText.Text -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                smtpServer = $smtpText.Text.Trim()
                port       = [int]($emailPortText.Text.Trim())
                useSSL     = $emailSslCheck.Checked
                username   = $emailUserText.Text.Trim()
            }

            # Save the app password as a DPAPI-encrypted PSCredential file.
            # The password is only ever written encrypted, never into the JSON.
            # DPAPI ties it to this Windows user on this machine.
            $passEntered = $emailPassText.Text
            if ($passEntered -and $passEntered -ne "********") {
                if (-not $emailHash.username) {
                    throw "Enter the SMTP username (your email address) before saving the app password."
                }
                $secure = ConvertTo-SecureString $passEntered -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential($emailHash.username, $secure)
                $cred | Export-Clixml -Path $script:credentialPath
                $emailPassText.Text = "********"
            }
            if (Test-Path $script:credentialPath) {
                $emailHash.credentialPath = $script:credentialPath
            }

            $configHash = @{
                ui       = if ($script:config -and $script:config.ui) { @{ theme = "$($script:config.ui.theme)" } } else { @{ theme = "dark" } }
                alerting = @{
                    enabled = $enableAlertingCheck.Checked
                    email   = $emailHash
                    webhook = @{ url = $webhookText.Text.Trim() }
                }
            }
            $script:config = [PSCustomObject]$configHash

            $configPath = Join-Path -Path $script:ScriptRoot -ChildPath "Config\DefaultConfig.json"
            $configHash | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

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

            # Warn if there are unsaved SMTP changes - the test uses saved config
            if (($emailPassText.Text -and $emailPassText.Text -ne "********")) {
                [System.Windows.Forms.MessageBox]::Show("You have an unsaved app password. Click 'Save Alert Settings' first, then test.", "Save First", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }

            $channels = @("EventLog")
            # Only attempt email if it's actually set up (saved credential).
            # A pre-filled SMTP server field alone is not "configured".
            $emailReady = $enableAlertingCheck.Checked -and $smtpText.Text -and (Test-Path $script:credentialPath)
            if ($emailReady) {
                $channels += "Email"
            }
            if ($webhookText.Text -and $webhookText.Text -ne "https://hooks.slack.com/services/..." -and $webhookText.Text -notlike "*YOUR_ID*") {
                $channels += "Webhook"
            }

            Send-Alert -Subject "DAT Test Alert" -Message "Testing alert configuration from Settings tab" -Channels $channels -Severity Info -Config $script:config
            $inboxNote = if ($emailReady) { "`n`nCheck your inbox (and Junk) for the email." } else { "" }
            [System.Windows.Forms.MessageBox]::Show("Test alert sent!`n`nChannels: $($channels -join ', ')$inboxNote", "Alert Test", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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

            New-ScheduledAudit -TaskName $taskName -Frequency $frequency -Time $time -EnabledChecks $enabledChecks -EnableEmailAlerts:($scheduleEmailCheck.Checked) -Force

            $emailNote = if ($scheduleEmailCheck.Checked) { "Enabled" } else { "Disabled" }
            [System.Windows.Forms.MessageBox]::Show("Scheduled task created successfully!`n`nTask Name: $taskName`nFrequency: $frequency`nTime: $time`nFunctions: $($enabledChecks.Count)`nEmail Alerts: $emailNote", "Schedule Created", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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
            if ($form.Icon) { $taskDialog.Icon = $form.Icon }

            # Title
            $dialogTitle = New-Object System.Windows.Forms.Label
            $dialogTitle.Text = "Manage Scheduled Audit Tasks"
            $dialogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
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
            $editBtn.Tag = 'primary'
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
            $deleteBtn.Tag = 'danger'
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

            # Match the main window theme
            Apply-ThemeToDialog -Dialog $taskDialog

            # Show the dialog
            $taskDialog.ShowDialog() | Out-Null
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to open task manager: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# Plugin list refresh - a plain function, NOT PerformClick: WinForms silently
# ignores PerformClick on controls that are not currently visible (hidden tab)
function Update-PluginsList {
    try {
        if (-not (Get-Command -Name Get-AvailablePlugins -ErrorAction SilentlyContinue)) {
            . (Join-Path -Path $script:ScriptRoot -ChildPath "Functions\Invoke-Plugin.ps1")
        }

        $pluginsListBox.Items.Clear()
        $plugins = @(Get-AvailablePlugins)
        foreach ($plugin in $plugins) {
            [void]$pluginsListBox.Items.Add("$($plugin.Name) - $($plugin.Description)")
        }
        if ($plugins.Count -eq 0) {
            [void]$pluginsListBox.Items.Add("(no plugins found in the Plugins folder)")
        }
        $script:availablePlugins = $plugins
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load plugins: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Refresh Plugins Button
$refreshPluginsBtn.Add_Click({ Update-PluginsList })

# Run Plugin Button
$runPluginBtn.Add_Click({
        if ($pluginsListBox.SelectedIndex -eq -1 -or -not $script:availablePlugins -or $script:availablePlugins.Count -eq 0) {
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
                Update-PluginsList
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to create plugin: $($_.Exception.Message)", "Plugin Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

# WinForms records anchor offsets against the tab page's size at first layout,
# but hidden tab pages sit at a default 200x100 until first shown - which
# corrupts Bottom/Right-anchored controls on any tab the user hasn't opened.
# Fix: remember the designed bounds, size every page for real, then re-assert
# the bounds so anchor offsets are recorded against the true page size.
# Capture design bounds FIRST - creating the handle below is what applies
# the corrupt offsets, so capturing later would record the mangled values
$defaultAnchor = [System.Windows.Forms.AnchorStyles]"Top,Left"
$anchoredControls = @()
foreach ($page in $tabControl.TabPages) {
    foreach ($ctrl in $page.Controls) {
        if ($ctrl.Anchor -ne $defaultAnchor) {
            $anchoredControls += , @($ctrl, $ctrl.Bounds)
        }
    }
}
$null = $tabControl.Handle
# Selecting each page once is the only reliable way to make the TabControl
# size it (TabPage ignores direct Bounds assignment)
for ($i = 0; $i -lt $tabControl.TabPages.Count; $i++) {
    $tabControl.SelectedIndex = $i
}
$tabControl.SelectedIndex = 0
# Cycle the Anchor property - its setter is what re-records the anchor
# offsets, a plain Bounds assignment gets overridden by the stale ones
foreach ($entry in $anchoredControls) {
    $ctrl = $entry[0]
    $savedAnchor = $ctrl.Anchor
    $ctrl.Anchor = $defaultAnchor
    $ctrl.Bounds = $entry[1]
    $ctrl.Anchor = $savedAnchor
}

# Initialize plugins list on startup
Update-PluginsList

# Apply saved theme on startup (Reaper/dark is the default)
if ($script:config -and $script:config.ui -and $script:config.ui.theme -eq "light") {
    Apply-LightTheme -Form $form -TabControl $tabControl
}
else {
    Apply-DarkTheme -Form $form -TabControl $tabControl
}

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
