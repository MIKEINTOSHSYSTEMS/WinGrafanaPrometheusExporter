@echo off
:: Windows Monitoring Stack - Stop Script with NSSM

:: Check if we're running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Not running as Administrator. Attempting to elevate...
    echo.
    
    set "batchPath=%~f0"
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%batchPath%\"' -Verb RunAs"
    exit /b 0
)

:: ========== RUNNING AS ADMINISTRATOR ==========
title Windows Monitoring Stack - Stopping (NSSM)...
color 0C

echo ============================================
echo    Windows Server Monitoring Stack
echo    Stopping all services (NSSM)...
echo ============================================
echo.

set "NSSM_PATH=%~dp0svc\nssm.exe"
set "SCRIPT_DIR=%~dp0"

echo [INFO] Stopping services...
echo.

:: Stop Grafana first
echo - Stopping Grafana...
cd /d "%SCRIPT_DIR%Grafana"
docker-compose down
if %errorLevel% equ 0 (
    echo   [✓] Grafana stopped.
) else (
    echo   [INFO] Grafana may already be stopped.
)

:: Stop Prometheus with NSSM
echo - Stopping Prometheus...
"%NSSM_PATH%" stop Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus stopped (NSSM).
) else (
    sc stop Prometheus >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [✓] Prometheus stopped (sc.exe).
    ) else (
        sc query Prometheus | findstr "STATE" | findstr "STOPPED" >nul
        if %errorLevel% equ 0 (
            echo   [✓] Prometheus is already stopped.
        ) else (
            echo   [INFO] Prometheus may not be installed.
        )
    )
)

:: Stop windows_exporter with NSSM
echo - Stopping windows_exporter...
"%NSSM_PATH%" stop windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter stopped (NSSM).
) else (
    sc stop windows_exporter >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [✓] windows_exporter stopped (sc.exe).
    ) else (
        sc query windows_exporter | findstr "STATE" | findstr "STOPPED" >nul
        if %errorLevel% equ 0 (
            echo   [✓] windows_exporter is already stopped.
        ) else (
            echo   [INFO] windows_exporter may not be installed.
        )
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