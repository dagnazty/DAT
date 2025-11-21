# DAT - Desktop Audit Tool

**dag's Audit Tool** is a comprehensive PowerShell-based security and compliance auditing platform for Windows environments. It provides both an advanced GUI and command-line interface for in-depth system analysis, compliance checking, and automated monitoring.

---

## 🚀 **Quick Start**

### **Launch Advanced GUI (Recommended)**
```cmd
.\Launch_DAT_GUI_Advanced.bat
```

### **Launch Interactive CLI**
```cmd
.\Launch_DAT.bat
```

### **Run Tests**
```powershell
.\Test_Advanced_Features.ps1
```

---

## ✨ **Key Features**

### **Core Audit Functions (14)**
- ✅ **System Uptime** - Boot time and uptime tracking
- ✅ **Running Processes** - Active process monitoring
- ✅ **Performance Metrics** - CPU, Memory, Disk usage
- ✅ **Hardware Inventory** - Complete hardware details
- ✅ **Event Log Summary** - Event log analysis
- ✅ **Security Update Status** - Windows Update status
- ✅ **Software Licensing** - License and activation info
- ✅ **Windows Update History** - Update installation history
- ✅ **Drivers Information** - Driver inventory
- ✅ **Backup Status** - Backup configuration check
- ✅ **Open Network Ports** - Network port scanning
- ✅ **User Groups** - User and group memberships
- ✅ **Registry Scan** - Suspicious registry entry detection
- ✅ **Disk Health** - HDD/SSD health check

### **Advanced Features**
- 🎨 **Advanced GUI** - 4-tab interface with all features
- 📊 **Multi-Format Export** - CSV, HTML, JSON
- 🔒 **Compliance Framework** - CIS & NIST benchmarks
- 🚨 **Multi-Channel Alerting** - Email, Discord, Slack, Teams, Event Log
- 📅 **Scheduled Audits** - Windows Task Scheduler integration
- 🔌 **Plugin System** - Extensible custom checks
- 🌐 **Remote Auditing** - Audit multiple computers
- 📈 **Historical Analysis** - Trend tracking and statistics
- ⚙️ **Configuration Management** - JSON-based settings

---

## 🖥️ **Advanced GUI**

The Advanced GUI provides easy access to all features through 4 organized tabs:

### **Tab 1: Run Audits**
- Select audit functions with checkboxes
- Run audits with real-time progress
- View results in data grid
- Export to CSV (separate files per function)
- Generate HTML reports
- Run compliance checks
- Send test alerts

### **Tab 2: Settings**
- Configure performance thresholds (CPU, Memory)
- Set up email alerts (SMTP configuration)
- Configure webhooks (Discord, Slack, Teams)
- Save and test alert configurations

### **Tab 3: Scheduled Audits**
- Create automated daily/weekly/monthly audits
- Configure task schedules
- View and manage scheduled tasks
- Enable email notifications

### **Tab 4: Plugins**
- View available plugins
- Run custom plugins
- Create new plugins from templates
- Extend functionality

---

## 📋 **Usage**

### **Interactive Mode**
```powershell
.\dat_main.ps1
```

### **Standalone Function Usage**

#### Run a single function:
```powershell
. .\Functions\Get-SystemUptime.ps1
Get-SystemUptime
```

#### Run with CSV export:
```powershell
. .\Functions\Get-SystemUptime.ps1
Get-SystemUptime -CsvPath "SystemUptime.csv"
```

#### Run directly from PowerShell:
```powershell
powershell -Command ". .\Functions\Get-RunningProcesses.ps1; Get-RunningProcesses -CsvPath 'processes.csv'"
```

---

## 🔒 **Compliance Checks**

Run automated compliance checks against industry standards:

```powershell
. .\Functions\Test-Compliance.ps1
Test-Compliance -Standards CIS,NIST -CsvPath "compliance_report.csv"
```

**Supported Standards:**
- **CIS Benchmarks** - Password policies, Firewall, Defender, Audit policies
- **NIST Controls** - Account management, Guest accounts, Password requirements

---

## 🚨 **Alerting System**

Send alerts through multiple channels:

```powershell
. .\Functions\Send-Alert.ps1
Send-Alert -Subject "Alert Title" -Message "Alert message" -Channels EventLog,Email,Webhook -Severity Critical
```

**Supported Channels:**
- 📝 **Event Log** - Windows Application Event Log (always available)
- 📧 **Email** - SMTP email alerts
- 🎮 **Discord** - Rich embedded Discord messages
- 💬 **Slack** - Slack workspace notifications
- 📊 **Microsoft Teams** - Teams channel alerts

**Severity Levels:** Critical, Warning, Info

---

## 📅 **Scheduled Audits**

Create automated audits using Windows Task Scheduler:

```powershell
. .\Functions\New-ScheduledAudit.ps1
New-ScheduledAudit -TaskName "Daily_Security_Audit" -Frequency Daily -Time "09:00" -EnabledChecks SystemUptime,SecurityUpdateStatus,OpenPorts
```

**Frequencies:** Daily, Weekly, Monthly

---

## 🌐 **Remote Auditing**

Audit multiple computers simultaneously:

```powershell
. .\Functions\Invoke-RemoteAudit.ps1
Invoke-RemoteAudit -ComputerName "SERVER01","SERVER02" -AuditFunctions @("Get-SystemUptime","Get-SecurityUpdateStatus") -CsvPath "remote_audit.csv"
```

**Requirements:**
- WinRM enabled on target systems
- Administrator rights
- Network connectivity

---

## 📈 **Historical Analysis**

Track performance and trends over time:

```powershell
. .\Functions\Save-AuditHistory.ps1

# Save audit results
Save-AuditHistory -AuditData $auditResults

# Analyze trends
Get-AuditTrends -FunctionName "Get-PerformanceMetrics" -Days 30 -CsvPath "trends.csv"

# Retrieve history
Get-AuditHistory -FunctionName "Get-SystemUptime" -Days 7
```

---

## 🔌 **Plugin System**

Extend DAT with custom plugins:

```powershell
. .\Functions\Invoke-Plugin.ps1

# List available plugins
Get-AvailablePlugins

# Run a plugin
Invoke-Plugin -PluginName "Custom-SecurityScan"

# Create new plugin
New-PluginTemplate -PluginName "MyCustomCheck" -Description "My custom audit"
```

---

## ⚙️ **Configuration**

Edit `Config\DefaultConfig.json` to customize:

```json
{
  "thresholds": {
    "cpuUsageWarning": 70,
    "cpuUsageCritical": 90,
    "memoryUsageWarning": 80,
    "memoryUsageCritical": 95
  },
  "alerting": {
    "enabled": true,
    "email": {
      "smtpServer": "smtp.company.com",
      "port": 587,
      "from": "audit@company.com",
      "to": ["admin@company.com"]
    },
    "webhook": {
      "url": "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"
    }
  },
  "compliance": {
    "enabled": true,
    "standards": ["CIS", "NIST"]
  }
}
```

---

## 📊 **Export Formats**

### **CSV Export**
```powershell
Get-SystemUptime -CsvPath "uptime.csv"
```
- Separate file per function
- Timestamped filenames
- Excel-compatible

### **HTML Reports**
```powershell
. .\Functions\New-HTMLReport.ps1
New-HTMLReport -OutputPath "report.html" -AuditData $auditResults -CompanyName "Your Company"
```
- Professional formatting
- All audit data in one report
- Print-ready

---

## 🎯 **Common Use Cases**

### **Daily Security Monitoring**
1. Schedule daily audit at 6 AM
2. Include: SecurityUpdateStatus, OpenPorts, RegistryScan
3. Enable Discord alerts
4. Review reports each morning

### **Weekly Compliance Reports**
1. Schedule weekly audit on Mondays
2. Run full compliance check
3. Export to CSV and HTML
4. Send to compliance team

### **On-Demand Investigation**
1. Open Advanced GUI
2. Select specific functions
3. Run audit immediately
4. Export results for analysis

### **Fleet Management**
1. Use remote auditing
2. Audit all servers/workstations
3. Aggregate results
4. Identify issues across fleet

---

## 📁 **File Structure**

```
D:\Scripts\DAT\
├── DAT_GUI_Advanced.ps1          # Advanced GUI
├── Launch_DAT_GUI_Advanced.bat   # GUI launcher
├── dat_main.ps1                  # Interactive CLI
├── Launch_DAT.bat                # CLI launcher
├── Config\
│   └── DefaultConfig.json        # Configuration
├── Functions\
│   ├── Get-*.ps1                 # 14 audit functions
│   ├── Test-Compliance.ps1       # Compliance checks
│   ├── Send-Alert.ps1            # Multi-channel alerts
│   ├── New-ScheduledAudit.ps1    # Task scheduling
│   ├── Invoke-Plugin.ps1         # Plugin system
│   ├── Invoke-RemoteAudit.ps1    # Remote auditing
│   ├── Save-AuditHistory.ps1     # Historical analysis
│   └── New-HTMLReport.ps1        # HTML reports
├── Plugins\
│   └── Custom-SecurityScan.ps1   # Sample plugin
├── History\                      # Historical data
└── Examples.ps1                  # Usage examples
```

---

## 🔧 **Requirements**

- **Windows 10/11** or **Windows Server 2016+**
- **PowerShell 5.1** or higher
- **Administrator rights** (for most functions)
- **.NET Framework 4.5+** (for GUI)

**Optional:**
- SMTP server (for email alerts)
- Discord/Slack/Teams webhook (for chat alerts)
- WinRM enabled (for remote auditing)

---

## 🚀 **Getting Started**

1. **Clone or download** the repository
2. **Open PowerShell** as Administrator
3. **Navigate** to the DAT directory
4. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
5. **Launch the GUI**:
   ```cmd
   .\Launch_DAT_GUI_Advanced.bat
   ```
6. **Configure settings** (Tab 2)
7. **Run your first audit** (Tab 1)

---

## 📚 **Documentation**

- **`DISCORD_WEBHOOK_SETUP.md`** - Discord integration guide
- **`Examples.ps1`** - Code examples
- **`Test_Advanced_Features.ps1`** - Feature testing
- **`Test-SendAlert.ps1`** - Alert system test
- **`Test-DiscordWebhook.ps1`** - Discord webhook test

---

## 🆘 **Troubleshooting**

### **GUI won't launch**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Functions not recognized**
```powershell
# Load function manually
. .\Functions\FunctionName.ps1
```

### **Access denied errors**
Run PowerShell as Administrator

### **Remote auditing fails**
Enable WinRM on target systems:
```powershell
Enable-PSRemoting -Force
```

---

## 🎉 **Features Summary**

| Feature | GUI | CLI | Status |
|---------|-----|-----|--------|
| 14 Audit Functions | ✅ | ✅ | Complete |
| CSV Export | ✅ | ✅ | Complete |
| HTML Reports | ✅ | ✅ | Complete |
| Compliance Checks | ✅ | ✅ | Complete |
| Email Alerts | ✅ | ✅ | Complete |
| Discord Webhooks | ✅ | ✅ | Complete |
| Slack Webhooks | ✅ | ✅ | Complete |
| Teams Webhooks | ✅ | ✅ | Complete |
| Scheduled Audits | ✅ | ✅ | Complete |
| Remote Auditing | ❌ | ✅ | Complete |
| Historical Analysis | ❌ | ✅ | Complete |
| Plugin System | ✅ | ✅ | Complete |
| Configuration | ✅ | ✅ | Complete |

**Total: 25+ Features - All Complete!** 🎉

---

## 🤝 **Contributing**

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Create custom plugins

---

## ⚠️ **Disclaimer**

This tool is provided **'as is'**, without warranty of any kind. Use at your own risk. Always test in a non-production environment first.

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/dagnazty/dags-audit-tool/blob/main/LICENSE) file for details.

---

## 🌟 **What's New**

### **Version 2.0 - Advanced Features**
- ✨ Advanced GUI with 4 tabs
- 🚨 Multi-channel alerting (Email, Discord, Slack, Teams)
- 🔒 CIS & NIST compliance checks
- 📅 Scheduled audit automation
- 🌐 Remote system auditing
- 📈 Historical data and trend analysis
- 🔌 Extensible plugin architecture
- ⚙️ JSON-based configuration

---

**DAT - Your complete enterprise security and compliance platform!** 🚀

For questions or support, please open an issue on GitHub.
