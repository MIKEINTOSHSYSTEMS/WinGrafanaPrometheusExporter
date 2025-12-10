@echo off
:: Download NSSM if not present

set "NSSM_URL=https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip"
set "DOWNLOAD_DIR=%~dp0svc"
set "ZIP_FILE=%DOWNLOAD_DIR%\nssm.zip"

echo ============================================
echo    Downloading NSSM (Non-Sucking Service Manager)
echo ============================================
echo.

if exist "%DOWNLOAD_DIR%\nssm.exe" (
    echo NSSM already exists in svc folder.
    echo.
    pause
    exit /b 0
)

echo Creating svc directory...
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

echo Downloading NSSM...
powershell -Command "Invoke-WebRequest -Uri '%NSSM_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

if not exist "%ZIP_FILE%" (
    echo Download failed!
    pause
    exit /b 1
)

echo Extracting NSSM...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%DOWNLOAD_DIR%\temp' -Force"

:: Find and copy nssm.exe (it could be in different paths)
if exist "%DOWNLOAD_DIR%\temp\nssm-2.24-101-g897c7ad\win64\nssm.exe" (
    copy "%DOWNLOAD_DIR%\temp\nssm-2.24-101-g897c7ad\win64\nssm.exe" "%DOWNLOAD_DIR%\nssm.exe"
) else if exist "%DOWNLOAD_DIR%\temp\nssm.exe" (
    copy "%DOWNLOAD_DIR%\temp\nssm.exe" "%DOWNLOAD_DIR%\nssm.exe"
) else (
    echo Could not find nssm.exe in the downloaded archive.
    dir "%DOWNLOAD_DIR%\temp"
    pause
    exit /b 1
)

:: Cleanup
del "%ZIP_FILE%" 2>nul
rmdir /s /q "%DOWNLOAD_DIR%\temp" 2>nul

echo.
echo [SUCCESS] NSSM downloaded and extracted to svc folder!
echo.
echo You can now use start.bat which will use NSSM for
echo better service management.
echo.
pause