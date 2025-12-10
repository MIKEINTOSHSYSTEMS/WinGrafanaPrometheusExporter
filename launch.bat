@echo off
:: Windows Monitoring Stack - Launcher
:: User-friendly interface for the monitoring stack

:menu
cls
title Windows Server Monitoring Launcher
color 0F

echo ============================================
echo    WINDOWS SERVER MONITORING LAUNCHER
echo    MIKEINTOSH SYSTEMS
echo ============================================
echo.
echo Please select an option:
echo.
echo [1] Complete Installation (First time)
echo [2] Start Monitoring Stack
echo [3] Stop Monitoring Stack
echo [4] Restart Monitoring Stack
echo [5] Check Status
echo [6] Uninstall (Remove services)
echo [7] Exit
echo.
set /p choice="Enter choice (1-7): "

if "%choice%"=="1" goto complete
if "%choice%"=="2" goto start
if "%choice%"=="3" goto stop
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto status
if "%choice%"=="6" goto uninstall
if "%choice%"=="7" exit

goto menu

:complete
echo.
echo Running complete installation...
echo.
echo Step 1: Download Prometheus (if needed)...
call onetimefetch.bat
echo.
echo Step 2: Starting monitoring stack...
call start.bat
goto menu

:start
call start.bat
goto menu

:stop
call stop.bat
goto menu

:restart
call restart.bat
goto menu

:status
call status.bat
goto menu

:uninstall
call uninstall.bat
goto menu