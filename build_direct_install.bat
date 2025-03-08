@echo off
echo ===================================================
echo VideoPackagingFast - Build Script with Direct PySimpleGUI Install
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

REM Install dependencies with specific versions
echo Installing dependencies...
python -m pip install --upgrade pip

REM Install core dependencies first (avoiding PySimpleGUI for now)
echo Installing core dependencies first...
pip install pillow==10.2.0 
pip install numpy>=1.22.0 
pip install requests>=2.28.0 
pip install tqdm>=4.64.0 
pip install packaging>=23.0
pip install python-dotenv==1.0.0

REM Install specific version of pydantic that works with PyInstaller
echo Installing compatible pydantic version...
pip install pydantic==1.10.8

REM Install other dependencies
echo Installing media processing libraries...
pip install moviepy==1.0.3 
pip install pydub==0.25.1 
pip install ffmpeg-python==0.2.0

REM Install AI libraries
echo Installing AI libraries...
pip install openai==1.12.0 
pip install anthropic==0.8.1

REM Install PyInstaller with specific version
echo Installing PyInstaller...
pip install PyInstaller==5.6.2 
pip install pyinstaller-hooks-contrib==2022.0

REM Run the direct PySimpleGUI installer
echo Installing PySimpleGUI directly...
python direct_install_pysimplegui.py
if %ERRORLEVEL% NEQ 0 (
    echo Warning: PySimpleGUI direct installation failed
    echo Continuing with wrapper module...
)

REM Run the build issue fix scripts
echo Running build issue fix scripts...
python fix_build_issues.py
python fix_icon_and_dependencies.py
python create_fallback_icon.py

REM Download FFmpeg if not already present
echo Checking for FFmpeg...
if not exist ffmpeg_bin\ffmpeg.exe (
    echo Downloading FFmpeg...
    python setup_ffmpeg.py
    if %ERRORLEVEL% NEQ 0 (
        echo Warning: Failed to download FFmpeg
        echo The application may still work if FFmpeg is installed on your system
    )
)

REM Ensure wrapper directory exists in case it's needed
echo Ensuring wrapper directory exists...
if not exist wrapper mkdir wrapper
if not exist wrapper\__init__.py (
    echo # Wrapper package > wrapper\__init__.py
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

REM Create a modified spec file that includes the wrapper directory
echo Creating modified spec file...
python -c "
import os
with open('VideoProcessor_windows.spec', 'r') as f:
    content = f.read()
if 'wrapper' not in content:
    content = content.replace(
        \"datas = [\",
        \"datas = [('wrapper', 'wrapper'), \"
    )
    with open('VideoProcessor_windows_modified.spec', 'w') as f:
        f.write(content)
else:
    with open('VideoProcessor_windows_modified.spec', 'w') as f:
        f.write(content)
print('Modified spec file created')
"

REM Build the executable
echo Building executable with PyInstaller...
pyinstaller --noconfirm --clean VideoProcessor_windows_modified.spec

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
    
    REM Automatically create the ZIP file
    echo Creating distributable ZIP file...
    if exist VideoProcessor_Windows.zip del VideoProcessor_Windows.zip
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\VideoProcessor', 'VideoProcessor_Windows.zip')}"
    
    if %ERRORLEVEL% EQU 0 (
        echo ZIP file created successfully: VideoProcessor_Windows.zip
    ) else (
        echo Failed to create ZIP file. Please create it manually.
    )
    
    REM Create installer if NSIS is available
    where makensis > nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo NSIS found. Creating installer...
        
        REM Create installer assets if they don't exist
        if not exist assets\installer-welcome.bmp (
            echo Creating installer graphics...
            copy assets\logo.png assets\installer-welcome.bmp 2>nul
            if %ERRORLEVEL% NEQ 0 (
                echo No logo found, skipping installer graphics
            )
        )
        
        REM Run NSIS to create installer
        makensis installer.nsi
        
        if %ERRORLEVEL% EQU 0 (
            echo.
            echo ===================================================
            echo Installer created successfully!
            echo The installer is at: VideoPackagingFast_Setup.exe
            echo ===================================================
        ) else (
            echo.
            echo ===================================================
            echo Failed to create installer.
            echo You can still distribute the ZIP file.
            echo ===================================================
        )
    ) else (
        echo.
        echo ===================================================
        echo NSIS not found. Skipping installer creation.
        echo You can distribute the ZIP file directly.
        echo ===================================================
    )
) else (
    echo ===================================================
    echo Build failed with error code %ERRORLEVEL%
    echo.
    echo Troubleshooting tips:
    echo 1. Make sure no instances of the application are running
    echo 2. Try closing any Python processes or IDEs
    echo 3. Check for compatibility issues with dependencies
    echo 4. Run the application from source using: python main.py
    echo ===================================================
)

REM Deactivate virtual environment
call venv\Scripts\deactivate

pause
