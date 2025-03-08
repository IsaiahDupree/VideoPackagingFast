@echo off
echo ===================================================
echo VideoPackagingFast - Windows Build Script (Fixed)
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

REM Install dependencies with specific PySimpleGUI handling
echo Installing dependencies...
python -m pip install --upgrade pip

REM Install PySimpleGUI with the correct source
echo Installing PySimpleGUI from official source...
pip install PySimpleGUI -i https://PySimpleGUI.net/install

REM Install other requirements
echo Installing other dependencies...
pip install moviepy==1.0.3 pydub==0.25.1 python-dotenv==1.0.0 pillow==10.2.0 ffmpeg-python==0.2.0 numpy>=1.22.0 tqdm>=4.64.0 requests>=2.28.0 packaging>=23.0 openai==1.12.0 anthropic==0.8.1 PyInstaller==5.6.2

REM Download FFmpeg if not already present
echo Checking for FFmpeg...
if not exist ffmpeg_bin\ffmpeg.exe (
    echo Downloading FFmpeg...
    python download_ffmpeg.py
    if %ERRORLEVEL% NEQ 0 (
        echo Warning: Failed to download FFmpeg
        echo The application may still work if FFmpeg is installed on your system
    )
)

REM Clean previous build
echo Cleaning previous build...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

REM Close any running instances of the application
echo Closing any running instances of the application...
taskkill /f /im VideoProcessor.exe 2>nul
taskkill /f /im python.exe 2>nul

REM Wait a moment for processes to fully terminate
timeout /t 2 /nobreak >nul

REM Build the executable
echo Building executable with PyInstaller...
pyinstaller VideoProcessor_windows.spec

echo.
if %ERRORLEVEL% EQU 0 (
    echo ===================================================
    echo Build completed successfully!
    echo The executable is in dist\VideoProcessor\
    echo.
    echo To create a distributable ZIP file:
    echo - Copy the entire dist\VideoProcessor folder
    echo - Rename it to VideoProcessor_Windows
    echo - Zip the folder to create VideoProcessor_Windows.zip
    echo ===================================================
) else (
    echo ===================================================
    echo Build failed with error code %ERRORLEVEL%
    echo.
    echo Troubleshooting tips:
    echo 1. Make sure no instances of the application are running
    echo 2. Try closing any Python processes or IDEs
    echo 3. Restart your computer and try again
    echo 4. Run the application from source using: python main.py
    echo ===================================================
)

REM Deactivate virtual environment
call venv\Scripts\deactivate

pause
