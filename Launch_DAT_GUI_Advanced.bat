@echo off
echo ========================================
echo   DAT - Advanced Audit Tool GUI
echo ========================================
echo.
echo Starting DAT Advanced GUI with all features...
echo.
echo Features:
echo  - Run Audits
echo  - Settings ^& Configuration
echo  - Scheduled Audits
echo  - Plugin Management
echo  - Compliance Checks
echo  - Alert System
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0DAT_GUI_Advanced.ps1"
echo.
echo GUI closed. Press any key to exit...
pause > nul
