@echo off
echo ========================================
echo   DAT - Sophisticated Audit Tool GUI
echo ========================================
echo.
echo Starting DAT Graphical User Interface...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0DAT_GUI.ps1"
echo.
echo GUI closed. Press any key to exit...
pause > nul
