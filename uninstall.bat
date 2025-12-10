@echo off
:: Windows Monitoring Stack - Uninstall Script
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
title Windows Monitoring Stack - Uninstalling...
color 0C

echo ============================================
echo    WARNING: UNINSTALL MONITORING STACK
echo ============================================
echo.
echo This will:
echo 1. Stop all services
echo 2. Remove Windows services
echo 3. Remove Docker containers
echo.
echo Configuration files will NOT be deleted.
echo.
set /p confirm="Type 'YES' to confirm uninstall: "
if not "%confirm%"=="YES" (
    echo.
    echo Uninstall cancelled.
    pause
    exit /b 0
)

echo.
echo [INFO] Uninstalling monitoring stack...
echo.

:: Stop services first
echo - Stopping services...
sc stop windows_exporter >nul 2>&1
sc stop Prometheus >nul 2>&1
cd /d "%~dp0Grafana"
docker-compose down >nul 2>&1

:: Remove services
echo - Removing Windows services...
sc delete windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter service removed.
) else (
    echo   [INFO] windows_exporter service may not exist.
)

sc delete Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus service removed.
) else (
    echo   [INFO] Prometheus service may not exist.
)

:: Remove Docker volumes (optional)
echo - Cleaning up Docker...
docker volume rm grafana_grafana_storage >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Docker volumes removed.
) else (
    echo   [INFO] Docker volumes may not exist.
)

echo.
echo ============================================
echo [SUCCESS] Monitoring stack uninstalled!
echo ============================================
echo.
echo Note: Configuration files are preserved.
echo To reinstall, run: start.bat
echo.
echo Press any key to exit...
pause >nul