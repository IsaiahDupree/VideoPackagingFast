@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - One-Click Installer Builder
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

echo Starting PowerShell installer builder...
echo.

REM Run PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "one_click_installer.ps1"

echo.
echo ===================================================
echo Build process completed.
echo ===================================================

pause
