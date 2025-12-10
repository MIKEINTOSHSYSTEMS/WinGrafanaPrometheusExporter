@echo off
:: Windows Monitoring Stack - Start Script with NSSM
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
title Windows Monitoring Stack - Starting with NSSM...
color 0A

echo ============================================
echo    Windows Server Monitoring Stack
echo    Starting all services (NSSM)...
echo ============================================
echo.

:: Set paths
set "NSSM_PATH=%~dp0svc\nssm.exe"
set "SCRIPT_DIR=%~dp0"

:: Check if NSSM exists
if not exist "%NSSM_PATH%" (
    echo [ERROR] nssm.exe not found in svc folder!
    echo Please download NSSM from: https://nssm.cc/download
    echo And place nssm.exe in the svc folder.
    echo.
    pause
    exit /b 1
)

:: Check if required files exist
if not exist "%SCRIPT_DIR%Prometheus\prometheus.exe" (
    echo [ERROR] Prometheus files not found!
    echo.
    echo Please run onetimefetch.bat first to download Prometheus.
    echo.
    pause
    exit /b 1
)

if not exist "%SCRIPT_DIR%windows_exporter\windows_exporter.exe" (
    echo [ERROR] windows_exporter.exe not found!
    echo.
    pause
    exit /b 1
)

echo [INFO] Using NSSM for service management...
echo.

:: ========== INSTALL/START WINDOWS_EXPORTER ==========
echo === windows_exporter Service ===
echo.

:: Check if service exists
sc query windows_exporter >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] Service not found. Installing with NSSM...
    echo.
    
    :: Install windows_exporter with NSSM
    "%NSSM_PATH%" install windows_exporter "%SCRIPT_DIR%windows_exporter\windows_exporter.exe"
    
    if %errorLevel% equ 0 (
        :: Configure service with NSSM
        "%NSSM_PATH%" set windows_exporter DisplayName "windows_exporter - Prometheus Metrics"
        "%NSSM_PATH%" set windows_exporter Description "Exports Windows metrics to Prometheus"
        "%NSSM_PATH%" set windows_exporter Start SERVICE_AUTO_START
        "%NSSM_PATH%" set windows_exporter AppStdout "%SCRIPT_DIR%logs\windows_exporter.log"
        "%NSSM_PATH%" set windows_exporter AppStderr "%SCRIPT_DIR%logs\windows_exporter.error.log"
        "%NSSM_PATH%" set windows_exporter AppRotateFiles 1
        "%NSSM_PATH%" set windows_exporter AppRotateBytes 1048576
        "%NSSM_PATH%" set windows_exporter AppRotateOnline 1
        
        echo [✓] windows_exporter service installed with NSSM.
    ) else (
        echo [ERROR] Failed to install windows_exporter service.
        pause
        exit /b 1
    )
) else (
    echo [✓] windows_exporter service already exists.
)

:: Start windows_exporter
echo - Starting windows_exporter...
"%NSSM_PATH%" start windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] windows_exporter started successfully.
) else (
    sc query windows_exporter | findstr "STATE" | findstr "RUNNING" >nul
    if %errorLevel% equ 0 (
        echo   [✓] windows_exporter is already running.
    ) else (
        echo   [WARNING] Could not start windows_exporter. Trying sc.exe...
        sc start windows_exporter >nul 2>&1
        if %errorLevel% equ 0 (
            echo   [✓] windows_exporter started with sc.exe.
        )
    )
)

:: ========== INSTALL/START PROMETHEUS ==========
echo.
echo === Prometheus Service ===
echo.

:: Check if service exists
sc query Prometheus >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] Service not found. Installing with NSSM...
    echo.
    
    :: Install Prometheus with NSSM
    "%NSSM_PATH%" install Prometheus "%SCRIPT_DIR%Prometheus\prometheus.exe" "--config.file=%SCRIPT_DIR%Prometheus\prometheus.yml" "--storage.tsdb.path=%SCRIPT_DIR%Prometheus\data" "--web.listen-address=:9090"
    
    if %errorLevel% equ 0 (
        :: Configure service with NSSM
        "%NSSM_PATH%" set Prometheus DisplayName "Prometheus - Monitoring Server"
        "%NSSM_PATH%" set Prometheus Description "Prometheus time-series database and monitoring system"
        "%NSSM_PATH%" set Prometheus Start SERVICE_AUTO_START
        "%NSSM_PATH%" set Prometheus AppStdout "%SCRIPT_DIR%logs\prometheus.log"
        "%NSSM_PATH%" set Prometheus AppStderr "%SCRIPT_DIR%logs\prometheus.error.log"
        "%NSSM_PATH%" set Prometheus AppRotateFiles 1
        "%NSSM_PATH%" set Prometheus AppRotateBytes 1048576
        "%NSSM_PATH%" set Prometheus AppRotateOnline 1
        "%NSSM_PATH%" set Prometheus AppEnvironmentExtra "PROMETHEUS_CONFIG=%SCRIPT_DIR%Prometheus\prometheus.yml"
        
        echo [✓] Prometheus service installed with NSSM.
    ) else (
        echo [ERROR] Failed to install Prometheus service.
        pause
        exit /b 1
    )
) else (
    echo [✓] Prometheus service already exists.
)

:: Start Prometheus
echo - Starting Prometheus...
"%NSSM_PATH%" start Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo   [✓] Prometheus started successfully.
) else (
    sc query Prometheus | findstr "STATE" | findstr "RUNNING" >nul
    if %errorLevel% equ 0 (
        echo   [✓] Prometheus is already running.
    ) else (
        echo   [WARNING] Could not start Prometheus. Trying sc.exe...
        sc start Prometheus >nul 2>&1
        if %errorLevel% equ 0 (
            echo   [✓] Prometheus started with sc.exe.
        )
    )
)

:: ========== START GRAFANA ==========
echo.
echo === Grafana Service ===
echo.

:: Start Grafana
cd /d "%SCRIPT_DIR%Grafana"
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

:: Create logs directory if it doesn't exist
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

:: Wait a moment for services to fully start
timeout /t 3 /nobreak >nul

echo.
echo ============================================
echo [SUCCESS] Monitoring stack started with NSSM!
echo ============================================
echo.
echo Service Management with NSSM:
echo   To stop a service:   nssm stop <service_name>
echo   To start a service:  nssm start <service_name>
echo   To restart:          nssm restart <service_name>
echo   To edit:             nssm edit <service_name>
echo.
echo Access URLs:
echo   Grafana Dashboard:    http://localhost:3000
echo   Prometheus Console:   http://localhost:9090
echo   windows_exporter:     http://localhost:9182/metrics
echo.
echo Logs directory: %SCRIPT_DIR%logs
echo.
echo Grafana Login: admin / admin
echo Dashboard ID to import: 24390
echo ============================================
echo.

:: Show service status
echo Current Service Status:
echo ------------------------
call :ShowServiceStatus

echo.
echo Press any key to continue...
pause >nul
exit /b 0

:: ========== FUNCTIONS ==========
:ShowServiceStatus
:: Check windows_exporter
sc query windows_exporter | findstr "STATE" >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query windows_exporter ^| findstr "STATE"') do (
        echo windows_exporter: %%a (NSSM)
    )
) else (
    echo windows_exporter: NOT INSTALLED
)

:: Check Prometheus
sc query Prometheus | findstr "STATE" >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query Prometheus ^| findstr "STATE"') do (
        echo Prometheus:      %%a (NSSM)
    )
) else (
    echo Prometheus:      NOT INSTALLED
)

:: Check Grafana
docker ps --filter "name=grafana" --format "table {{.Names}}\t{{.Status}}" | findstr "grafana" >nul
if %errorLevel% equ 0 (
    for /f "tokens=1,2" %%a in ('docker ps --filter "name=grafana" --format "{{.Names}} {{.Status}}"') do (
        echo Grafana:         %%b (Docker)
    )
) else (
    echo Grafana:         NOT RUNNING
)
goto :eof