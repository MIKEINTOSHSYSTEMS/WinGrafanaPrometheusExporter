@echo off
:: Batch file to run PowerShell script as Administrator

echo Checking for Administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator. Starting download...
    powershell -ExecutionPolicy Bypass -File "%~dp0onetimefetch.ps1"
) else (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0onetimefetch.ps1\"' -Verb RunAs"
)
pause