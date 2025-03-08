@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - Build, Test and Run Script
echo ===================================================
echo.

REM Set error handling
set "BUILD_SUCCESS=0"
set "EXECUTABLE_PATH=dist\VideoProcessor\VideoProcessor.exe"

REM Check if Python is installed
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.8 or later and try again
    exit /b 1
)

REM Create a log file for the build process
set "LOG_FILE=build_log_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"
echo Build started at %date% %time% > %LOG_FILE%

REM Function to log messages
:log
    echo %~1
    echo %~1 >> %LOG_FILE%
    goto :eof

REM Close any running instances of the application
call :log "Closing any running instances of the application..."
taskkill /f /im VideoProcessor.exe 2>nul
taskkill /f /im python.exe 2>nul

REM Wait a moment for processes to fully terminate
timeout /t 2 /nobreak >nul

REM Clean previous build
call :log "Cleaning previous build..."
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist __pycache__ rmdir /s /q __pycache__

REM Create and activate virtual environment
call :log "Creating virtual environment..."
python -m venv venv
call venv\Scripts\activate

REM Install dependencies with specific versions
call :log "Installing dependencies..."
python -m pip install --upgrade pip

REM Install core dependencies first (avoiding PySimpleGUI for now)
call :log "Installing core dependencies first..."
pip install pillow==10.2.0 numpy>=1.22.0 requests>=2.28.0 tqdm>=4.64.0 packaging>=23.0 python-dotenv==1.0.0 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] Failed to install core dependencies"
    goto :error
)

REM Install specific version of pydantic that works with PyInstaller
call :log "Installing compatible pydantic version..."
pip install pydantic==1.10.8 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] Failed to install pydantic, continuing anyway..."
)

REM Install other dependencies
call :log "Installing media processing libraries..."
pip install moviepy==1.0.3 pydub==0.25.1 ffmpeg-python==0.2.0 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] Failed to install some media libraries, continuing anyway..."
)

REM Install AI libraries
call :log "Installing AI libraries..."
pip install openai==1.12.0 anthropic==0.8.1 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] Failed to install some AI libraries, continuing anyway..."
)

REM Install PyInstaller with specific version
call :log "Installing PyInstaller..."
pip install PyInstaller==5.6.2 pyinstaller-hooks-contrib==2022.0 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] Failed to install PyInstaller"
    goto :error
)

REM Run the direct PySimpleGUI installer
call :log "Installing PySimpleGUI directly..."
if exist direct_install_pysimplegui.py (
    python direct_install_pysimplegui.py >> %LOG_FILE% 2>&1
    if %ERRORLEVEL% NEQ 0 (
        call :log "[WARNING] Direct PySimpleGUI installation had issues"
        call :log "Trying alternative installation methods..."
    )
) else (
    call :log "[WARNING] direct_install_pysimplegui.py not found"
    call :log "Trying alternative installation methods..."
)

REM Try alternative PySimpleGUI installation methods if direct install failed or script not found
if exist fix_pysimplegui.py (
    call :log "Running fix_pysimplegui.py..."
    python fix_pysimplegui.py >> %LOG_FILE% 2>&1
)

REM Last resort - try pip install directly
call :log "Attempting direct pip installation of PySimpleGUI..."
pip install PySimpleGUI==5.0.0 >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] Direct pip installation failed, trying alternative versions..."
    pip install PySimpleGUI==4.60.5 >> %LOG_FILE% 2>&1
    if %ERRORLEVEL% NEQ 0 (
        call :log "[WARNING] All PySimpleGUI installation methods failed"
        call :log "Continuing with wrapper module..."
    )
)

REM Run the build issue fix scripts
call :log "Running build issue fix scripts..."
if exist fix_build_issues.py (
    python fix_build_issues.py >> %LOG_FILE% 2>&1
)
if exist fix_icon_and_dependencies.py (
    python fix_icon_and_dependencies.py >> %LOG_FILE% 2>&1
)
if exist create_fallback_icon.py (
    python create_fallback_icon.py >> %LOG_FILE% 2>&1
)

REM Download FFmpeg if not already present
call :log "Checking for FFmpeg..."
if not exist ffmpeg_bin\ffmpeg.exe (
    call :log "Downloading FFmpeg..."
    if exist setup_ffmpeg.py (
        python setup_ffmpeg.py >> %LOG_FILE% 2>&1
    ) else (
        call :log "Downloading FFmpeg using PowerShell..."
        powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg.zip'}" >> %LOG_FILE% 2>&1
        
        if %ERRORLEVEL% NEQ 0 (
            call :log "[WARNING] Failed to download FFmpeg using PowerShell"
            call :log "Trying alternative download method..."
            curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -o ffmpeg.zip >> %LOG_FILE% 2>&1
        )
        
        call :log "Extracting FFmpeg..."
        powershell -Command "& {Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force}" >> %LOG_FILE% 2>&1
        
        REM Find and copy the ffmpeg.exe file
        call :log "Copying FFmpeg executable..."
        if not exist ffmpeg_bin mkdir ffmpeg_bin
        for /r ffmpeg_temp %%i in (ffmpeg.exe) do (
            copy "%%i" "ffmpeg_bin\ffmpeg.exe" >> %LOG_FILE% 2>&1
        )
        
        REM Clean up temporary files
        if exist ffmpeg.zip del ffmpeg.zip
        if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
    )
)

REM Ensure wrapper directory exists in case it's needed
call :log "Ensuring wrapper directory exists..."
if not exist wrapper mkdir wrapper
if not exist wrapper\__init__.py (
    echo # Wrapper package > wrapper\__init__.py
)

REM Create a simple PySimpleGUI wrapper if it doesn't exist
if not exist wrapper\PySimpleGUI.py (
    call :log "Creating basic PySimpleGUI wrapper as fallback..."
    echo # PySimpleGUI wrapper module - Minimal implementation > wrapper\PySimpleGUI.py
    echo import tkinter as tk >> wrapper\PySimpleGUI.py
    echo from tkinter import filedialog, messagebox >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo # Define constants >> wrapper\PySimpleGUI.py
    echo WINDOW_CLOSED = 'WINDOW_CLOSED' >> wrapper\PySimpleGUI.py
    echo WIN_CLOSED = WINDOW_CLOSED >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo # Basic functions >> wrapper\PySimpleGUI.py
    echo def popup^(message, title=None, **kwargs^): >> wrapper\PySimpleGUI.py
    echo     return messagebox.showinfo^(title or 'Information', message^) >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo # Window class >> wrapper\PySimpleGUI.py
    echo class Window: >> wrapper\PySimpleGUI.py
    echo     def __init__^(self, title, layout=None, **kwargs^): >> wrapper\PySimpleGUI.py
    echo         self.title = title >> wrapper\PySimpleGUI.py
    echo         self.layout = layout or [] >> wrapper\PySimpleGUI.py
    echo         self.closed = False >> wrapper\PySimpleGUI.py
    echo     def read^(self, timeout=None^): >> wrapper\PySimpleGUI.py
    echo         return WINDOW_CLOSED, None >> wrapper\PySimpleGUI.py
    echo     def close^(self^): >> wrapper\PySimpleGUI.py
    echo         self.closed = True >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo print^("WARNING: Using PySimpleGUI wrapper module with limited functionality"^) >> wrapper\PySimpleGUI.py
)

REM Create a modified spec file that includes the wrapper directory and FFmpeg
call :log "Creating modified spec file..."
python -c "
import os
spec_file = 'VideoProcessor_windows.spec'
if not os.path.exists(spec_file):
    spec_file = next((f for f in os.listdir('.') if f.endswith('.spec')), None)
if spec_file:
    with open(spec_file, 'r') as f:
        content = f.read()
    
    # Add wrapper directory if not already included
    if 'wrapper' not in content:
        content = content.replace(
            \"datas = [\",
            \"datas = [('wrapper', 'wrapper'), \"
        )
    
    # Ensure FFmpeg is included in the binaries if the variable exists
    if 'binaries = [' in content and 'ffmpeg_bin' not in content:
        content = content.replace(
            \"binaries = [\",
            \"binaries = [('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin'), \"
        )
    
    with open('VideoProcessor_windows_modified.spec', 'w') as f:
        f.write(content)
    print('Modified spec file created')
else:
    print('No spec file found, will use default PyInstaller settings')
" >> %LOG_FILE% 2>&1

REM Build the executable
call :log "Building executable with PyInstaller..."
if exist VideoProcessor_windows_modified.spec (
    pyinstaller --noconfirm --clean VideoProcessor_windows_modified.spec >> %LOG_FILE% 2>&1
) else if exist VideoProcessor_windows.spec (
    pyinstaller --noconfirm --clean VideoProcessor_windows.spec >> %LOG_FILE% 2>&1
) else (
    call :log "No spec file found, using default PyInstaller settings..."
    pyinstaller --noconfirm --clean --onedir --windowed --icon=resources/icon.ico --add-data "wrapper;wrapper" --add-binary "ffmpeg_bin/ffmpeg.exe;ffmpeg_bin" main.py --name VideoProcessor >> %LOG_FILE% 2>&1
)

if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] Build failed with PyInstaller"
    goto :error
)

REM Check if the executable was created
if exist %EXECUTABLE_PATH% (
    call :log "[SUCCESS] Build completed successfully!"
    set "BUILD_SUCCESS=1"
) else (
    call :log "[ERROR] Build failed - executable not found"
    goto :error
)

REM Create distributable ZIP file
if %BUILD_SUCCESS% EQU 1 (
    call :log "Creating distributable ZIP file..."
    if exist VideoProcessor_Windows.zip del VideoProcessor_Windows.zip
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\VideoProcessor', 'VideoProcessor_Windows.zip')}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        call :log "[SUCCESS] ZIP file created successfully: VideoProcessor_Windows.zip"
    ) else (
        call :log "[WARNING] Failed to create ZIP file."
    )
    
    REM Launch the executable for immediate testing
    call :log "Launching the application for testing..."
    start "" %EXECUTABLE_PATH%
    
    REM Display success message
    echo.
    call :log "====================================================="
    call :log " Build and launch successful!"
    call :log " The application is now running for testing."
    call :log " A distributable ZIP file has been created."
    call :log "====================================================="
)

goto :end

:error
call :log "====================================================="
call :log " Build process encountered errors."
call :log " Please check the log file for details: %LOG_FILE%"
call :log "====================================================="
exit /b 1

:end
REM Deactivate virtual environment
call venv\Scripts\deactivate

echo.
call :log "Build process completed. See %LOG_FILE% for details."
if %BUILD_SUCCESS% EQU 1 (
    call :log "The application is now running for testing."
)

endlocal
