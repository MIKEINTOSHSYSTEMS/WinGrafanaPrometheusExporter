@echo off
:: Windows Monitoring Stack - Stop Script
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
title Windows Monitoring Stack - Stopping...
color 0C

echo ============================================
echo    Windows Server Monitoring Stack
echo    Stopping all services...
echo ============================================
echo.

echo [INFO] Stopping services...
echo.

:: Stop Grafana first
echo - Stopping Grafana...
cd /d "%~dp0Grafana"
docker-compose down
if %errorLevel% equ 0 (
    echo   [✓] Grafana stopped.
) else (
    echo   [INFO] Grafana may already be stopped.
)

:: Stop Prometheus
echo - Stopping Prometheus...
sc stop Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus stopped.
) else (
    sc query Prometheus | findstr "STATE" | findstr "STOPPED" >nul
    if %errorLevel% equ 0 (
        echo   [✓] Prometheus is already stopped.
    ) else (
        echo   [INFO] Prometheus may not be installed.
    )
)

:: Stop windows_exporter
echo - Stopping windows_exporter...
sc stop windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter stopped.
) else (
    sc query windows_exporter | findstr "STATE" | findstr "STOPPED" >nul
    if %errorLevel% equ 0 (
        echo   [✓] windows_exporter is already stopped.
    ) else (
        echo   [INFO] windows_exporter may not be installed.
    )
)

echo.
echo ============================================
echo [SUCCESS] All services stopped!
echo ============================================
echo.
echo To start services again, run: start.bat
echo ============================================
echo.
pause