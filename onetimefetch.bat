@echo off
setlocal enabledelayedexpansion

echo ============================================
echo    Prometheus Binary Downloader
echo    Version: 3.8.0 for Windows
echo ============================================
echo.

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Please run this script as Administrator!
    echo Right-click -> Run as administrator
    echo.
    pause
    exit /b 1
)

:: Set variables
set "PROMETHEUS_VERSION=3.8.0"
set "DOWNLOAD_URL=https://github.com/prometheus/prometheus/releases/download/v%PROMETHEUS_VERSION%/prometheus-%PROMETHEUS_VERSION%.windows-amd64.zip"
set "ZIP_FILE=prometheus-%PROMETHEUS_VERSION%.windows-amd64.zip"
set "EXTRACT_DIR=temp_prometheus"
set "TARGET_DIR=Prometheus"
set "TEMP_DIR=%TEMP%\prometheus_download"

:: Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

echo [INFO] Checking existing Prometheus files...
echo.

:: Check if files already exist in target directory
set "files_exist=0"
if exist "..\..\%TARGET_DIR%\prometheus.exe" (
    echo [✓] prometheus.exe already exists in %TARGET_DIR%\
    set "files_exist=1"
) else (
    echo [ ] prometheus.exe not found in %TARGET_DIR%\
)

if exist "..\..\%TARGET_DIR%\promtool.exe" (
    echo [✓] promtool.exe already exists in %TARGET_DIR%\
    set "files_exist=1"
) else (
    echo [ ] promtool.exe not found in %TARGET_DIR%\
)

echo.

if "%files_exist%"=="1" (
    echo ============================================
    echo [INFO] Prometheus files already exist!
    echo [INFO] To update, delete the existing files first.
    echo [INFO] Please continue with start.bat
    echo ============================================
    pause
    exit /b 0
)

echo [INFO] Prometheus files not found. Starting download...
echo [INFO] Downloading Prometheus v%PROMETHEUS_VERSION%...
echo.

:: Download Prometheus zip file
powershell -Command "& {
    $ErrorActionPreference = 'Stop'
    try {
        Write-Host '[INFO] Downloading from: %DOWNLOAD_URL%' -ForegroundColor Cyan
        Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing
        Write-Host '[✓] Download completed successfully!' -ForegroundColor Green
    }
    catch {
        Write-Host '[ERROR] Download failed!' -ForegroundColor Red
        Write-Host 'Error details: $_' -ForegroundColor Red
        exit 1
    }
}"

if errorlevel 1 (
    echo [ERROR] Download failed. Please check your internet connection.
    pause
    exit /b 1
)

echo.
echo [INFO] Extracting files...
echo.

:: Extract zip file
powershell -Command "& {
    $ErrorActionPreference = 'Stop'
    try {
        if (Test-Path '%EXTRACT_DIR%') {
            Remove-Item -Path '%EXTRACT_DIR%' -Recurse -Force
        }
        Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force
        Write-Host '[✓] Extraction completed!' -ForegroundColor Green
    }
    catch {
        Write-Host '[ERROR] Extraction failed!' -ForegroundColor Red
        Write-Host 'Error details: $_' -ForegroundColor Red
        exit 1
    }
}"

if errorlevel 1 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)

echo.
echo [INFO] Copying required files to %TARGET_DIR%...
echo.

:: Find the extracted folder (it might have version in name)
for /d %%d in ("%EXTRACT_DIR%\*") do (
    set "EXTRACTED_FOLDER=%%d"
)

:: Copy only required files
set "SOURCE_PATH=%EXTRACTED_FOLDER%"
set "DEST_PATH=..\..\%TARGET_DIR%"

:: Ensure target directory exists
if not exist "%DEST_PATH%" mkdir "%DEST_PATH%"

:: Copy prometheus.exe
if exist "%SOURCE_PATH%\prometheus.exe" (
    copy "%SOURCE_PATH%\prometheus.exe" "%DEST_PATH%\prometheus.exe" >nul
    echo [✓] Copied prometheus.exe
) else (
    echo [ERROR] prometheus.exe not found in extracted files!
    goto cleanup
)

:: Copy promtool.exe
if exist "%SOURCE_PATH%\promtool.exe" (
    copy "%SOURCE_PATH%\promtool.exe" "%DEST_PATH%\promtool.exe" >nul
    echo [✓] Copied promtool.exe
) else (
    echo [ERROR] promtool.exe not found in extracted files!
    goto cleanup
)

:: Copy LICENSE and NOTICE files (optional)
if exist "%SOURCE_PATH%\LICENSE" (
    copy "%SOURCE_PATH%\LICENSE" "%DEST_PATH%\LICENSE" >nul
    echo [✓] Copied LICENSE
)

if exist "%SOURCE_PATH%\NOTICE" (
    copy "%SOURCE_PATH%\NOTICE" "%DEST_PATH%\NOTICE" >nul
    echo [✓] Copied NOTICE
)

echo.
echo [INFO] Verifying copied files...
echo.

:: Verify files were copied
set "verify_failed=0"
if not exist "%DEST_PATH%\prometheus.exe" (
    echo [ERROR] prometheus.exe was not copied successfully!
    set "verify_failed=1"
)

if not exist "%DEST_PATH%\promtool.exe" (
    echo [ERROR] promtool.exe was not copied successfully!
    set "verify_failed=1"
)

if "%verify_failed%"=="1" (
    echo.
    echo [ERROR] File verification failed!
    goto cleanup
)

echo [✓] All files verified successfully!
echo.

:: Get file sizes
for %%f in ("%DEST_PATH%\prometheus.exe") do set "prometheus_size=%%~zf"
for %%f in ("%DEST_PATH%\promtool.exe") do set "promtool_size=%%~zf"

set /a prometheus_mb=prometheus_size/1048576
set /a promtool_mb=promtool_size/1048576

echo [INFO] File sizes:
echo        prometheus.exe: %prometheus_mb% MB
echo        promtool.exe: %promtool_mb% MB
echo.

:cleanup
echo [INFO] Cleaning up temporary files...
echo.

:: Clean up temporary files
if exist "%ZIP_FILE%" del "%ZIP_FILE%"
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%"

:: Return to original directory
cd /d "%~dp0"

echo ============================================
echo [SUCCESS] Prometheus binaries downloaded and
echo          extracted successfully!
echo.
echo [NEXT] Please run start.bat to begin
echo        the monitoring stack installation.
echo ============================================
echo.

:: Display success message with ASCII art
echo       ___          _            
echo      / _ \ _ __ __| |_ __ ___   
echo     | | | | '__/ _^| | '_ ^| _ \  
echo     | |_| | | | (_| | | | |  __/  
echo      \___/|_|  \__,_|_| |_|\___| 
echo.
echo      Prometheus Ready!
echo.

pause
exit /b 0