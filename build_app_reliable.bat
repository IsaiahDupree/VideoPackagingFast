@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - Reliable Build Solution
echo ===================================================
echo.

REM Check for PowerShell
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell is not installed or not in PATH.
    echo Please install PowerShell before continuing.
    pause
    exit /b 1
)

echo Attempting to build the application package...
echo.

REM First try the direct packaging approach (most reliable)
echo [1/2] Trying direct packaging method...
powershell -ExecutionPolicy Bypass -File "direct_package.ps1"

REM Check if we have a successful package
if exist "installers\VideoProcessor_Windows_Latest.zip" (
    echo.
    echo Direct packaging completed successfully!
    echo The application package is available at:
    echo   installers\VideoProcessor_Windows_Latest.zip
    echo.
    goto :success
) else (
    echo.
    echo Direct packaging did not produce the expected output.
    echo Trying alternative build method...
    echo.
)

REM Try the PyInstaller approach as fallback
echo [2/2] Trying PyInstaller build method...
powershell -ExecutionPolicy Bypass -File "one_click_installer.ps1"

REM Check if we have a successful package from the fallback method
if exist "installers\VideoProcessor_Windows_Latest.zip" (
    echo.
    echo PyInstaller build completed successfully!
    echo The application package is available at:
    echo   installers\VideoProcessor_Windows_Latest.zip
    echo.
    goto :success
) else (
    echo.
    echo All build methods failed to produce the expected output.
    echo Please check the log files in the build_logs directory for details.
    echo.
    goto :failure
)

:success
echo ===================================================
echo Build process completed successfully!
echo ===================================================
exit /b 0

:failure
echo ===================================================
echo Build process failed.
echo ===================================================
exit /b 1

pause
