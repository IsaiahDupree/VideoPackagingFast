@echo off
echo ===================================================
echo VideoPackagingFast - One-Click Installer Creator
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

REM Install PySimpleGUI and other dependencies
echo Installing application dependencies...
pip install PySimpleGUI==4.60.4
pip install moviepy==1.0.3 pydub==0.25.1 python-dotenv==1.0.0 pillow==10.2.0 ffmpeg-python==0.2.0 numpy>=1.22.0 tqdm>=4.64.0 requests>=2.28.0 packaging>=23.0 openai==1.12.0 anthropic==0.8.1

REM Install PyInstaller and NSIS for creating installers
echo Installing build tools...
pip install PyInstaller==5.6.2
pip install pyinstaller-hooks-contrib==2022.0

REM Ensure FFmpeg directory exists
if not exist ffmpeg_bin mkdir ffmpeg_bin

REM Download FFmpeg using a reliable method
echo Downloading FFmpeg...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/GyanD/codexffmpeg/releases/download/6.0/ffmpeg-6.0-essentials_build.zip' -OutFile 'ffmpeg.zip'}"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to download FFmpeg. Continuing anyway...
) else (
    echo Extracting FFmpeg...
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('ffmpeg.zip', 'ffmpeg_temp')}"
    
    echo Copying FFmpeg to ffmpeg_bin directory...
    for /r ffmpeg_temp %%i in (ffmpeg.exe) do copy "%%i" ffmpeg_bin\ffmpeg.exe
    
    echo Cleaning up temporary files...
    if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
    if exist ffmpeg.zip del ffmpeg.zip
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

REM Create a onefile build with PyInstaller
echo Building single-file executable with PyInstaller...
pyinstaller --noconfirm --clean --name "VideoProcessor" ^
  --add-data "assets;assets" ^
  --add-data "ffmpeg_bin;ffmpeg_bin" ^
  --add-data "utils;utils" ^
  --hidden-import pkg_resources.py2_warn ^
  --hidden-import PIL ^
  --hidden-import PIL._tkinter_finder ^
  --hidden-import PIL.Image ^
  --hidden-import PIL.ImageTk ^
  --hidden-import moviepy.audio.fx ^
  --hidden-import moviepy.video.fx ^
  --hidden-import engineio.async_drivers.threading ^
  --onefile ^
  --windowed ^
  --icon assets\icon.ico ^
  main.py

echo.
if %ERRORLEVEL% EQU 0 (
    echo ===================================================
    echo Build completed successfully!
    echo The single-file executable is at: dist\VideoProcessor.exe
    echo.
    echo This executable contains everything needed to run the application.
    echo No Python or FFmpeg installation is required.
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
