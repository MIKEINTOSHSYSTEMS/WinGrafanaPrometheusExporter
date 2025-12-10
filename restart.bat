@echo off
:: Windows Monitoring Stack - Restart Script
:: This script will auto-elevate to Administrator if needed

:: Check if we're running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Not running as Administrator. Attempting to elevate...
    echo.
    
    :: Get the batch file location
    set "batchPath=%~f0"
    
    :: Re-launch as Administrator
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%batchPath%\"' -Verb RunAs"
    
    exit /b 0
)

:: ========== RUNNING AS ADMINISTRATOR ==========
title Windows Monitoring Stack - Restarting...
color 0E

echo ============================================
echo    Windows Server Monitoring Stack
echo    Restarting all services...
echo ============================================
echo.

echo [INFO] Stopping services first...
call stop.bat

echo.
echo [INFO] Waiting 5 seconds...
timeout /t 5 /nobreak >nul

echo.
echo [INFO] Starting services...
call start.bat