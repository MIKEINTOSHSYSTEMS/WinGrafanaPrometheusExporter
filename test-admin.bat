@echo off
:: Test script to verify Administrator privileges

net session >nul 2>&1
if %errorLevel% equ 0 (
    echo Running as Administrator ✓
    echo You have the necessary privileges.
) else (
    echo NOT running as Administrator ✗
    echo You need Administrator rights to manage services.
)

echo.
echo Testing NSSM access...
if exist "svc\nssm.exe" (
    svc\nssm.exe status windows_exporter
    echo.
    echo NSSM test completed.
) else (
    echo NSSM not found in svc folder.
)

echo.
pause