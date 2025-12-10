@echo off
:: NSSM Service Management Interface with Auto-Elevation
:: Advanced control for services

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
:menu
cls
title NSSM Service Manager - MIKEINTOSH SYSTEMS
color 0F

echo ============================================
echo    NSSM SERVICE MANAGER (Administrator)
echo    MIKEINTOSH SYSTEMS
echo ============================================
echo.
echo Running as: Administrator ✓
echo.
echo Select service to manage:
echo.
echo [1] windows_exporter
echo [2] Prometheus
echo [3] Both services
echo.
echo [4] Check service status
echo [5] Edit service configuration (GUI)
echo [6] View service logs
echo [7] Install missing services
echo [8] Remove services
echo [9] Back to main menu
echo [0] Exit
echo.
set /p choice="Enter choice (0-9): "

set "NSSM_PATH=%~dp0svc\nssm.exe"
set "SCRIPT_DIR=%~dp0"

:: Validate NSSM exists
if not exist "%NSSM_PATH%" (
    echo.
    echo [ERROR] nssm.exe not found in svc folder!
    echo Please run download-nssm.bat first.
    echo.
    pause
    goto menu
)

if "%choice%"=="1" set "SERVICE=windows_exporter" && goto service_menu
if "%choice%"=="2" set "SERVICE=Prometheus" && goto service_menu
if "%choice%"=="3" goto both_services
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto edit_config
if "%choice%"=="6" goto view_logs
if "%choice%"=="7" goto install_services
if "%choice%"=="8" goto remove_services
if "%choice%"=="9" goto main_menu
if "%choice%"=="0" exit

goto menu

:service_menu
cls
echo ============================================
echo    Managing: %SERVICE% (Administrator)
echo ============================================
echo.
echo Current status:
sc query %SERVICE% | findstr "STATE"
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
if %errorLevel% neq 0 (
    echo [WARNING] NSSM failed, trying sc.exe...
    sc start %SERVICE%
)
echo.
echo Current status:
sc query %SERVICE% | findstr "STATE"
echo.
pause
goto service_menu

:stop_service
echo.
echo Stopping %SERVICE%...
"%NSSM_PATH%" stop %SERVICE%
if %errorLevel% neq 0 (
    echo [WARNING] NSSM failed, trying sc.exe...
    sc stop %SERVICE%
)
echo.
echo Current status:
sc query %SERVICE% | findstr "STATE"
echo.
pause
goto service_menu

:restart_service
echo.
echo Restarting %SERVICE%...
echo - Stopping...
"%NSSM_PATH%" stop %SERVICE%
timeout /t 2 /nobreak >nul
echo - Starting...
"%NSSM_PATH%" start %SERVICE%
echo.
echo Current status:
sc query %SERVICE% | findstr "STATE"
echo.
pause
goto service_menu

:install_service
echo.
echo Installing %SERVICE%...
if "%SERVICE%"=="windows_exporter" (
    echo Installing windows_exporter service...
    "%NSSM_PATH%" install windows_exporter "%SCRIPT_DIR%windows_exporter\windows_exporter.exe"
    if %errorLevel% equ 0 (
        "%NSSM_PATH%" set windows_exporter DisplayName "windows_exporter - Prometheus Metrics"
        "%NSSM_PATH%" set windows_exporter Description "Exports Windows metrics to Prometheus"
        "%NSSM_PATH%" set windows_exporter Start SERVICE_AUTO_START
        "%NSSM_PATH%" set windows_exporter AppStdout "%SCRIPT_DIR%logs\windows_exporter.log"
        "%NSSM_PATH%" set windows_exporter AppStderr "%SCRIPT_DIR%logs\windows_exporter.error.log"
        echo [✓] windows_exporter installed successfully.
    ) else (
        echo [ERROR] Failed to install windows_exporter.
    )
) else if "%SERVICE%"=="Prometheus" (
    echo Installing Prometheus service...
    "%NSSM_PATH%" install Prometheus "%SCRIPT_DIR%Prometheus\prometheus.exe" "--config.file=%SCRIPT_DIR%Prometheus\prometheus.yml" "--storage.tsdb.path=%SCRIPT_DIR%Prometheus\data" "--web.listen-address=:9090"
    if %errorLevel% equ 0 (
        "%NSSM_PATH%" set Prometheus DisplayName "Prometheus - Monitoring Server"
        "%NSSM_PATH%" set Prometheus Description "Prometheus time-series database and monitoring system"
        "%NSSM_PATH%" set Prometheus Start SERVICE_AUTO_START
        "%NSSM_PATH%" set Prometheus AppStdout "%SCRIPT_DIR%logs\prometheus.log"
        "%NSSM_PATH%" set Prometheus AppStderr "%SCRIPT_DIR%logs\prometheus.error.log"
        echo [✓] Prometheus installed successfully.
    ) else (
        echo [ERROR] Failed to install Prometheus.
    )
)
echo.
pause
goto service_menu

:remove_service
echo.
echo Removing %SERVICE%...
set /p confirm="Type 'YES' to confirm removal of %SERVICE%: "
if not "%confirm%"=="YES" (
    echo Removal cancelled.
    goto service_menu
)

"%NSSM_PATH%" remove %SERVICE% confirm
if %errorLevel% neq 0 (
    echo [WARNING] NSSM removal failed, trying sc.exe...
    sc delete %SERVICE%
)
echo.
echo %SERVICE% has been removed.
echo.
pause
goto menu

:both_services
cls
echo ============================================
echo    Managing Both Services
echo ============================================
echo.
echo [1] Start both services
echo [2] Stop both services
echo [3] Restart both services
echo [4] Check status of both
echo [5] Back to main menu
echo.
set /p both_choice="Enter choice (1-5): "

if "%both_choice%"=="1" (
    echo.
    echo Starting both services...
    "%NSSM_PATH%" start windows_exporter
    "%NSSM_PATH%" start Prometheus
) else if "%both_choice%"=="2" (
    echo.
    echo Stopping both services...
    "%NSSM_PATH%" stop windows_exporter
    "%NSSM_PATH%" stop Prometheus
) else if "%both_choice%"=="3" (
    echo.
    echo Restarting both services...
    "%NSSM_PATH%" stop windows_exporter
    "%NSSM_PATH%" stop Prometheus
    timeout /t 2 /nobreak >nul
    "%NSSM_PATH%" start windows_exporter
    "%NSSM_PATH%" start Prometheus
) else if "%both_choice%"=="4" (
    echo.
    echo Current status:
    echo windows_exporter:
    sc query windows_exporter | findstr "STATE"
    echo.
    echo Prometheus:
    sc query Prometheus | findstr "STATE"
) else if "%both_choice%"=="5" (
    goto menu
)

echo.
pause
goto both_services

:check_status
cls
echo ============================================
echo    SERVICE STATUS
echo ============================================
echo.
echo [1] windows_exporter
sc query windows_exporter >nul 2>&1
if %errorLevel% equ 0 (
    echo Status:
    sc query windows_exporter | findstr "STATE"
    echo.
    echo NSSM Status:
    "%NSSM_PATH%" status windows_exporter
) else (
    echo windows_exporter: NOT INSTALLED
)
echo.

echo [2] Prometheus
sc query Prometheus >nul 2>&1
if %errorLevel% equ 0 (
    echo Status:
    sc query Prometheus | findstr "STATE"
    echo.
    echo NSSM Status:
    "%NSSM_PATH%" status Prometheus
) else (
    echo Prometheus: NOT INSTALLED
)
echo.

echo [3] Grafana
echo Grafana Docker Container:
docker ps --filter "name=grafana" --format "{{.Names}}: {{.Status}}" 2>nul
if %errorLevel% neq 0 (
    echo Grafana: NOT RUNNING or Docker not available
)
echo.
pause
goto menu

:edit_config
cls
echo ============================================
echo    EDIT SERVICE CONFIGURATION (GUI)
echo ============================================
echo.
echo This will open NSSM GUI for service configuration.
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
:: Create logs directory if it doesn't exist
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

echo Available logs:
echo.
set "log_count=0"
if exist "%SCRIPT_DIR%logs\windows_exporter.log" (
    set /a log_count+=1
    echo [%log_count%] windows_exporter.log
)
if exist "%SCRIPT_DIR%logs\prometheus.log" (
    set /a log_count+=1
    echo [%log_count%] prometheus.log
)
if exist "%SCRIPT_DIR%logs\windows_exporter.error.log" (
    set /a log_count+=1
    echo [%log_count%] windows_exporter.error.log
)
if exist "%SCRIPT_DIR%logs\prometheus.error.log" (
    set /a log_count+=1
    echo [%log_count%] prometheus.error.log
)

set /a log_count+=1
echo [%log_count%] Create/edit log directory
set /a log_count+=1
echo [%log_count%] Back to main menu
echo.
set /p log_choice="Select option (1-%log_count%): "

set "option_count=0"
if exist "%SCRIPT_DIR%logs\windows_exporter.log" (
    set /a option_count+=1
    if "%log_choice%"=="%option_count%" notepad "%SCRIPT_DIR%logs\windows_exporter.log" && goto view_logs
)
if exist "%SCRIPT_DIR%logs\prometheus.log" (
    set /a option_count+=1
    if "%log_choice%"=="%option_count%" notepad "%SCRIPT_DIR%logs\prometheus.log" && goto view_logs
)
if exist "%SCRIPT_DIR%logs\windows_exporter.error.log" (
    set /a option_count+=1
    if "%log_choice%"=="%option_count%" notepad "%SCRIPT_DIR%logs\windows_exporter.error.log" && goto view_logs
)
if exist "%SCRIPT_DIR%logs\prometheus.error.log" (
    set /a option_count+=1
    if "%log_choice%"=="%option_count%" notepad "%SCRIPT_DIR%logs\prometheus.error.log" && goto view_logs
)

set /a option_count+=1
if "%log_choice%"=="%option_count%" (
    explorer "%SCRIPT_DIR%logs"
    goto view_logs
)

set /a option_count+=1
if "%log_choice%"=="%option_count%" goto menu

goto view_logs

:install_services
cls
echo ============================================
echo    INSTALL MISSING SERVICES
echo ============================================
echo.
echo This will check and install any missing services.
echo.
echo Checking services...
echo.

:: Check windows_exporter
sc query windows_exporter >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] windows_exporter not installed. Installing...
    if exist "%SCRIPT_DIR%windows_exporter\windows_exporter.exe" (
        "%NSSM_PATH%" install windows_exporter "%SCRIPT_DIR%windows_exporter\windows_exporter.exe"
        if %errorLevel% equ 0 (
            "%NSSM_PATH%" set windows_exporter DisplayName "windows_exporter - Prometheus Metrics"
            "%NSSM_PATH%" set windows_exporter Description "Exports Windows metrics to Prometheus"
            "%NSSM_PATH%" set windows_exporter Start SERVICE_AUTO_START
            echo [✓] windows_exporter installed.
        ) else (
            echo [ERROR] Failed to install windows_exporter.
        )
    ) else (
        echo [ERROR] windows_exporter.exe not found!
    )
) else (
    echo [✓] windows_exporter already installed.
)

:: Check Prometheus
sc query Prometheus >nul 2>&1
if %errorLevel% equ 1060 (
    echo [ ] Prometheus not installed. Installing...
    if exist "%SCRIPT_DIR%Prometheus\prometheus.exe" (
        "%NSSM_PATH%" install Prometheus "%SCRIPT_DIR%Prometheus\prometheus.exe" "--config.file=%SCRIPT_DIR%Prometheus\prometheus.yml" "--storage.tsdb.path=%SCRIPT_DIR%Prometheus\data" "--web.listen-address=:9090"
        if %errorLevel% equ 0 (
            "%NSSM_PATH%" set Prometheus DisplayName "Prometheus - Monitoring Server"
            "%NSSM_PATH%" set Prometheus Description "Prometheus time-series database and monitoring system"
            "%NSSM_PATH%" set Prometheus Start SERVICE_AUTO_START
            echo [✓] Prometheus installed.
        ) else (
            echo [ERROR] Failed to install Prometheus.
        )
    ) else (
        echo [ERROR] prometheus.exe not found! Run onetimefetch.bat first.
    )
) else (
    echo [✓] Prometheus already installed.
)

echo.
echo Installation complete.
echo.
pause
goto menu

:remove_services
cls
echo ============================================
echo    REMOVE ALL SERVICES
echo ============================================
echo.
echo WARNING: This will remove ALL monitoring services!
echo.
set /p confirm="Type 'REMOVE-ALL' to confirm: "
if not "%confirm%"=="REMOVE-ALL" (
    echo Removal cancelled.
    goto menu
)

echo.
echo Removing services...
echo.

:: Remove windows_exporter
"%NSSM_PATH%" remove windows_exporter confirm >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] windows_exporter removed.
) else (
    sc delete windows_exporter >nul 2>&1
    if %errorLevel% equ 0 (
        echo [✓] windows_exporter removed (sc.exe).
    ) else (
        echo [INFO] windows_exporter may not exist.
    )
)

:: Remove Prometheus
"%NSSM_PATH%" remove Prometheus confirm >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] Prometheus removed.
) else (
    sc delete Prometheus >nul 2>&1
    if %errorLevel% equ 0 (
        echo [✓] Prometheus removed (sc.exe).
    ) else (
        echo [INFO] Prometheus may not exist.
    )
)

echo.
echo All services have been removed.
echo Use "Install missing services" option to reinstall.
echo.
pause
goto menu

:main_menu
:: Return to launch.bat if it exists
if exist "%SCRIPT_DIR%launch.bat" (
    start /b "" "%SCRIPT_DIR%launch.bat"
) else (
    echo.
    echo Returning to command line...
    timeout /t 2 /nobreak >nul
)
exit