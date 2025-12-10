@echo off
:: Windows Monitoring Stack - Start Script
:: This script will auto-elevate to Administrator if needed

:: Check if we're running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Not running as Administrator. Attempting to elevate...
    echo.
    
    :: Get the batch file location
    set "batchPath=%~f0"
    set "batchArgs=%*"
    
    :: Re-launch as Administrator
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%batchPath%\" %batchArgs%\"' -Verb RunAs"
    
    exit /b 0
)

:: ========== RUNNING AS ADMINISTRATOR ==========
title Windows Monitoring Stack - Starting...
color 0A

echo ============================================
echo    Windows Server Monitoring Stack
echo    Starting all services...
echo ============================================
echo.

:: Check if Prometheus files exist
if not exist "Prometheus\prometheus.exe" (
    echo [ERROR] Prometheus files not found!
    echo.
    echo Please run onetimefetch.bat first to download Prometheus.
    echo.
    pause
    exit /b 1
)

if not exist "windows_exporter\windows_exporter.exe" (
    echo [ERROR] windows_exporter.exe not found!
    echo.
    echo Please ensure windows_exporter is in the windows_exporter folder.
    echo.
    pause
    exit /b 1
)

echo [INFO] Checking current service status...
echo.

:: Check if services exist, install if not
echo === Windows Services ===

:: Check windows_exporter service
sc query windows_exporter >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] windows_exporter service not found. Installing...
    
    :: Install windows_exporter as service
    sc create windows_exporter binpath="%~dp0windows_exporter\windows_exporter.exe" start=auto displayname="windows_exporter" error=normal
    if %errorLevel% equ 0 (
        echo [✓] windows_exporter service installed.
    ) else (
        echo [ERROR] Failed to install windows_exporter service.
        pause
        exit /b 1
    )
) else (
    echo [✓] windows_exporter service found.
)

:: Check Prometheus service
sc query Prometheus >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] Prometheus service not found. Installing...
    
    :: Install Prometheus as service
    sc create Prometheus binpath="%~dp0Prometheus\prometheus.exe --config.file=%~dp0Prometheus\prometheus.yml" start=auto displayname="Prometheus" error=normal
    if %errorLevel% equ 0 (
        echo [✓] Prometheus service installed.
    ) else (
        echo [ERROR] Failed to install Prometheus service.
        pause
        exit /b 1
    )
) else (
    echo [✓] Prometheus service found.
)

echo.
echo [INFO] Starting services...
echo.

:: Start windows_exporter
echo - Starting windows_exporter...
sc start windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter started successfully.
) else (
    sc query windows_exporter | findstr "STATE" | findstr "RUNNING" >nul
    if %errorLevel% equ 0 (
        echo   [✓] windows_exporter is already running.
    ) else (
        echo   [ERROR] Failed to start windows_exporter.
    )
)

:: Start Prometheus
echo - Starting Prometheus...
sc start Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus started successfully.
) else (
    sc query Prometheus | findstr "STATE" | findstr "RUNNING" >nul
    if %errorLevel% equ 0 (
        echo   [✓] Prometheus is already running.
    ) else (
        echo   [ERROR] Failed to start Prometheus.
    )
)

echo.
echo [INFO] Starting Grafana with Docker...
echo.

:: Start Grafana
cd /d "%~dp0Grafana"
echo - Starting Grafana container...
docker-compose up -d

if %errorLevel% equ 0 (
    echo   [✓] Grafana started successfully.
) else (
    echo   [ERROR] Failed to start Grafana.
    echo   [INFO] Checking if Docker is running...
    docker ps >nul 2>&1
    if %errorLevel% neq 0 (
        echo   [ERROR] Docker is not running. Please start Docker Desktop.
    )
)

:: Wait a moment for services to fully start
timeout /t 3 /nobreak >nul

echo.
echo ============================================
echo [SUCCESS] Monitoring stack started!
echo ============================================
echo.
echo Access URLs:
echo   Grafana Dashboard:    http://localhost:3000
echo   Prometheus Console:   http://localhost:9090
echo   windows_exporter:     http://localhost:9182/metrics
echo.
echo Grafana Login: admin / admin
echo Dashboard ID to import: 24390
echo.
echo To stop all services, run: stop.bat
echo To check status, run: status.bat
echo ============================================
echo.

:: Show service status
cd /d "%~dp0"
call :ShowServiceStatus

echo.
echo Press any key to continue...
pause >nul
exit /b 0

:: ========== FUNCTIONS ==========
:ShowServiceStatus
echo Current Service Status:
echo ------------------------

:: Check windows_exporter
sc query windows_exporter | findstr "STATE" >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query windows_exporter ^| findstr "STATE"') do (
        echo windows_exporter: %%a
    )
) else (
    echo windows_exporter: NOT INSTALLED
)

:: Check Prometheus
sc query Prometheus | findstr "STATE" >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query Prometheus ^| findstr "STATE"') do (
        echo Prometheus:      %%a
    )
) else (
    echo Prometheus:      NOT INSTALLED
)

:: Check Grafana
docker ps --filter "name=grafana" --format "table {{.Names}}\t{{.Status}}" | findstr "grafana" >nul
if %errorLevel% equ 0 (
    for /f "tokens=1,2" %%a in ('docker ps --filter "name=grafana" --format "{{.Names}} {{.Status}}"') do (
        echo Grafana:         %%b
    )
) else (
    echo Grafana:         NOT RUNNING
)
goto :eof