@echo off
:: Windows Monitoring Stack - Status Check
:: This script shows service status (doesn't need admin to check)

title Windows Monitoring Stack - Status
color 0B

echo ============================================
echo    Windows Monitoring Stack Status
echo    %date% %time%
echo ============================================
echo.

echo === Windows Services ===
echo.

:: Check windows_exporter service
sc query windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query windows_exporter ^| findstr "STATE"') do (
        echo windows_exporter: %%a
    )
) else (
    echo windows_exporter: NOT INSTALLED
)

:: Check Prometheus service
sc query Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query Prometheus ^| findstr "STATE"') do (
        echo Prometheus:      %%a
    )
) else (
    echo Prometheus:      NOT INSTALLED
)

echo.
echo === Docker Containers ===
echo.

:: Check Grafana container
docker ps --filter "name=grafana" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul
if %errorLevel% neq 0 (
    echo Docker is not running or Grafana container not found.
)

echo.
echo === Port Availability ===
echo.

:: Function to check port
setlocal enabledelayedexpansion
for %%p in (9182 9090 3000) do (
    set "service="
    if %%p==9182 set "service=windows_exporter"
    if %%p==9090 set "service=Prometheus"
    if %%p==3000 set "service=Grafana"
    
    echo - !service! (port %%p):
    powershell -Command "Test-NetConnection -ComputerName localhost -Port %%p -WarningAction SilentlyContinue | Select-Object -ExpandProperty TcpTestSucceeded" 2>nul
    if errorlevel 1 echo   ERROR: Could not test port
    echo.
)

echo ============================================
echo [QUICK COMMANDS]
echo   start.bat    - Start all services
echo   stop.bat     - Stop all services
echo   restart.bat  - Restart all services
echo   status.bat   - Check status (this)
echo ============================================
echo.
pause