@echo off
:: NSSM Service Management Interface
:: Advanced control for services

:menu
cls
title NSSM Service Manager - MIKEINTOSH SYSTEMS
color 0F

echo ============================================
echo    NSSM SERVICE MANAGER
echo    MIKEINTOSH SYSTEMS
echo ============================================
echo.
echo Select service to manage:
echo.
echo [1] windows_exporter
echo [2] Prometheus
echo [3] Both services
echo.
echo [4] Check service status
echo [5] Edit service configuration
echo [6] View service logs
echo [7] Back to main menu
echo [8] Exit
echo.
set /p choice="Enter choice (1-8): "

set "NSSM_PATH=%~dp0svc\nssm.exe"

if "%choice%"=="1" set "SERVICE=windows_exporter" && goto service_menu
if "%choice%"=="2" set "SERVICE=Prometheus" && goto service_menu
if "%choice%"=="3" goto both_services
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto edit_config
if "%choice%"=="6" goto view_logs
if "%choice%"=="7" goto main_menu
if "%choice%"=="8" exit

goto menu

:service_menu
cls
echo ============================================
echo    Managing: %SERVICE%
echo ============================================
echo.
echo [1] Start %SERVICE%
echo [2] Stop %SERVICE%
echo [3] Restart %SERVICE%
echo [4] Install %SERVICE%
echo [5] Remove %SERVICE%
echo [6] Back to main menu
echo.
set /p action="Enter action (1-6): "

if "%action%"=="1" goto start_service
if "%action%"=="2" goto stop_service
if "%action%"=="3" goto restart_service
if "%action%"=="4" goto install_service
if "%action%"=="5" goto remove_service
if "%action%"=="6" goto menu

goto service_menu

:start_service
echo.
echo Starting %SERVICE%...
"%NSSM_PATH%" start %SERVICE%
echo.
pause
goto service_menu

:stop_service
echo.
echo Stopping %SERVICE%...
"%NSSM_PATH%" stop %SERVICE%
echo.
pause
goto service_menu

:restart_service
echo.
echo Restarting %SERVICE%...
"%NSSM_PATH%" restart %SERVICE%
echo.
pause
goto service_menu

:install_service
echo.
echo Installing %SERVICE%...
if "%SERVICE%"=="windows_exporter" (
    "%NSSM_PATH%" install %SERVICE% "%~dp0windows_exporter\windows_exporter.exe"
) else if "%SERVICE%"=="Prometheus" (
    "%NSSM_PATH%" install %SERVICE% "%~dp0Prometheus\prometheus.exe" "--config.file=%~dp0Prometheus\prometheus.yml" "--storage.tsdb.path=%~dp0Prometheus\data" "--web.listen-address=:9090"
)
echo.
pause
goto service_menu

:remove_service
echo.
echo Removing %SERVICE%...
"%NSSM_PATH%" remove %SERVICE% confirm
echo.
pause
goto menu

:both_services
echo.
echo Managing both services...
echo.
echo 1. Starting both services...
"%NSSM_PATH%" start windows_exporter
"%NSSM_PATH%" start Prometheus
echo.
echo 2. Checking status...
sc query windows_exporter | findstr "STATE"
sc query Prometheus | findstr "STATE"
echo.
pause
goto menu

:check_status
cls
echo ============================================
echo    SERVICE STATUS
echo ============================================
echo.
echo windows_exporter:
sc query windows_exporter | findstr "STATE"
echo.
echo Prometheus:
sc query Prometheus | findstr "STATE"
echo.
echo Grafana:
docker ps --filter "name=grafana" --format "{{.Names}}: {{.Status}}"
echo.
pause
goto menu

:edit_config
cls
echo ============================================
echo    EDIT SERVICE CONFIGURATION
echo ============================================
echo.
echo Select service to edit:
echo.
echo [1] windows_exporter
echo [2] Prometheus
echo [3] Back
echo.
set /p edit_choice="Enter choice (1-3): "

if "%edit_choice%"=="1" (
    "%NSSM_PATH%" edit windows_exporter
) else if "%edit_choice%"=="2" (
    "%NSSM_PATH%" edit Prometheus
) else if "%edit_choice%"=="3" (
    goto menu
)
goto edit_config

:view_logs
cls
echo ============================================
echo    VIEW SERVICE LOGS
echo ============================================
echo.
echo Available logs:
echo.
if exist "%~dp0logs\windows_exporter.log" echo [1] windows_exporter.log
if exist "%~dp0logs\prometheus.log" echo [2] prometheus.log
if exist "%~dp0logs\windows_exporter.error.log" echo [3] windows_exporter.error.log
if exist "%~dp0logs\prometheus.error.log" echo [4] prometheus.error.log
echo [5] Back
echo.
set /p log_choice="Select log to view (1-5): "

if "%log_choice%"=="1" notepad "%~dp0logs\windows_exporter.log"
if "%log_choice%"=="2" notepad "%~dp0logs\prometheus.log"
if "%log_choice%"=="3" notepad "%~dp0logs\windows_exporter.error.log"
if "%log_choice%"=="4" notepad "%~dp0logs\prometheus.error.log"
if "%log_choice%"=="5" goto menu

goto view_logs

:main_menu
start /b "" "%~dp0launch.bat"
exit