@echo off
echo ===================================================
echo VideoPackagingFast - Complete Windows Build Script
echo ===================================================
echo.

REM Check if Python is installed
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8 or later and try again
    exit /b 1
)

REM Create and activate virtual environment
echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate

REM Install dependencies
echo Installing dependencies...
python -m pip install --upgrade pip
pip install -r requirements.txt

REM Download FFmpeg if not already present
echo Checking for FFmpeg...
if not exist ffmpeg_bin\ffmpeg.exe (
    echo Downloading FFmpeg...
    python download_ffmpeg.py
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to download FFmpeg
        echo Please download FFmpeg manually and place it in ffmpeg_bin\ffmpeg.exe
        exit /b 1
    )
)

REM Clean previous build
echo Cleaning previous build...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

REM Build the executable
echo Building executable with PyInstaller...
pyinstaller VideoProcessor_windows.spec

echo.
echo ===================================================
echo Build completed successfully!
echo The executable is in dist\VideoProcessor\
echo.
echo To create a distributable ZIP file:
echo - Copy the entire dist\VideoProcessor folder
echo - Rename it to VideoProcessor_Windows
echo - Zip the folder to create VideoProcessor_Windows.zip
echo ===================================================

REM Deactivate virtual environment
call venv\Scripts\deactivate
