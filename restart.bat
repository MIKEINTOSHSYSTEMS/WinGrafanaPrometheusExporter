@echo off
echo Restarting Windows Monitoring Stack...
call stop.bat
timeout /t 5 /nobreak >nul
call start.bat