@echo off
echo ===================================================
echo VideoPackagingFast - Windows Basic Build Script
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

REM Install a specific version of PySimpleGUI that we know works
echo Installing stable version of PySimpleGUI...
pip install PySimpleGUI==5.0.0.16

REM Install specific version of pydantic that works with PyInstaller
echo Installing compatible pydantic version...
pip install pydantic==1.10.8

REM Install PyInstaller with specific version
echo Installing PyInstaller...
pip install PyInstaller==5.6.2

REM Install other requirements (minimal set)
echo Installing other dependencies...
pip install moviepy==1.0.3 pydub==0.25.1 python-dotenv==1.0.0 pillow==10.2.0 ffmpeg-python==0.2.0 numpy>=1.22.0 tqdm>=4.64.0 requests>=2.28.0 packaging>=23.0

REM Install AI API dependencies if needed
pip install openai==1.12.0 anthropic==0.8.1

REM Ensure FFmpeg directory exists
if not exist ffmpeg_bin mkdir ffmpeg_bin

REM Download FFmpeg if not already present
echo Checking for FFmpeg...
if not exist ffmpeg_bin\ffmpeg.exe (
    echo FFmpeg not found, downloading...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/GyanD/codexffmpeg/releases/download/6.0/ffmpeg-6.0-essentials_build.zip' -OutFile 'ffmpeg.zip'}"
    powershell -Command "& {Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force}"
    for /r ffmpeg_temp %%i in (ffmpeg.exe) do copy "%%i" ffmpeg_bin\ffmpeg.exe
    rmdir /s /q ffmpeg_temp
    del ffmpeg.zip
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

REM Build the executable with direct PyInstaller command (no spec file)
echo Building executable with basic PyInstaller command...
pyinstaller --clean --name VideoProcessor ^
  --add-data "assets;assets" ^
  --add-data "ffmpeg_bin;ffmpeg_bin" ^
  --hidden-import pkg_resources.py2_warn ^
  --hidden-import PIL ^
  --hidden-import PIL._tkinter_finder ^
  --hidden-import PIL.Image ^
  --hidden-import PIL.ImageTk ^
  --windowed ^
  --icon assets\icon.ico ^
  main.py

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
    echo 3. Try running the application from source: python main.py
    echo 4. Check if all dependencies are installed correctly
    echo ===================================================
)

REM Deactivate virtual environment
call venv\Scripts\deactivate

pause
