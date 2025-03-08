@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - Direct Packaging Tool
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

echo Starting PowerShell packaging script...
echo.

REM Run PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "direct_package.ps1"

echo.
echo ===================================================
echo Packaging process completed.
echo ===================================================

pause
