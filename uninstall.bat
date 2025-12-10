@echo off
:: Windows Monitoring Stack - Uninstall Script with NSSM

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
title Windows Monitoring Stack - Uninstalling (NSSM)...
color 0C

echo ============================================
echo    WARNING: UNINSTALL MONITORING STACK
echo    Using NSSM for service removal
echo ============================================
echo.
echo This will:
echo 1. Stop all services
echo 2. Remove Windows services (NSSM)
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
echo [INFO] Uninstalling monitoring stack with NSSM...
echo.

set "NSSM_PATH=%~dp0svc\nssm.exe"
set "SCRIPT_DIR=%~dp0"

:: Stop services first
echo - Stopping services...
cd /d "%SCRIPT_DIR%Grafana"
docker-compose down >nul 2>&1

:: Remove services with NSSM
echo - Removing Windows services with NSSM...

:: Remove windows_exporter
"%NSSM_PATH%" remove windows_exporter confirm >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter service removed (NSSM).
) else (
    sc delete windows_exporter >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [✓] windows_exporter service removed (sc.exe).
    ) else (
        echo   [INFO] windows_exporter service may not exist.
    )
)

:: Remove Prometheus
"%NSSM_PATH%" remove Prometheus confirm >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus service removed (NSSM).
) else (
    sc delete Prometheus >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [✓] Prometheus service removed (sc.exe).
    ) else (
        echo   [INFO] Prometheus service may not exist.
    )
)

:: Remove Docker volumes
echo - Cleaning up Docker...
docker volume rm grafana_grafana_storage >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Docker volumes removed.
) else (
    echo   [INFO] Docker volumes may not exist.
)

:: Remove logs directory
if exist "%SCRIPT_DIR%logs" (
    rmdir /s /q "%SCRIPT_DIR%logs" 2>nul
    echo   [✓] Logs directory removed.
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