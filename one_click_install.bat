@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - One-Click Installation
echo ===================================================
echo.

REM Set error handling
set "INSTALL_SUCCESS=0"
set "LOG_FILE=install_log_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"
echo Installation started at %date% %time% > %LOG_FILE%

REM Function to log messages
:log
    echo %~1
    echo %~1 >> %LOG_FILE%
    goto :eof

REM Close any running instances of the application
call :log "Closing any running instances of the application..."
taskkill /f /im VideoProcessor.exe 2>nul
timeout /t 2 /nobreak >nul

REM Check if the executable already exists
if exist dist\VideoProcessor\VideoProcessor.exe (
    call :log "Executable already exists. Would you like to run it directly?"
    choice /C YN /M "Run existing executable (Y) or reinstall (N)?"
    if !ERRORLEVEL! EQU 1 (
        call :log "Starting existing executable..."
        start "" dist\VideoProcessor\VideoProcessor.exe
        exit /b 0
    ) else (
        call :log "Proceeding with reinstallation..."
    )
)

REM Check if distributable ZIP exists
if exist VideoProcessor_Windows.zip (
    call :log "Distributable ZIP already exists. Extracting..."
    if exist dist\VideoProcessor rmdir /s /q dist\VideoProcessor
    mkdir dist\VideoProcessor 2>nul
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows.zip', 'dist\VideoProcessor')}" >> %LOG_FILE% 2>&1
    
    if !ERRORLEVEL! EQU 0 (
        call :log "ZIP extracted successfully. Starting application..."
        start "" dist\VideoProcessor\VideoProcessor.exe
        exit /b 0
    ) else (
        call :log "Failed to extract ZIP. Proceeding with full installation..."
    )
)

REM Check if Python is installed
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "Python is not installed. Downloading embedded Python..."
    
    REM Download embedded Python
    powershell -Command "& {Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip' -OutFile 'python-embedded.zip'}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "[ERROR] Failed to download Python. Please install Python 3.8 or later manually."
        goto :error
    )
    
    REM Extract Python
    call :log "Extracting embedded Python..."
    if exist python-embedded rmdir /s /q python-embedded
    mkdir python-embedded
    powershell -Command "& {Expand-Archive -Path 'python-embedded.zip' -DestinationPath 'python-embedded' -Force}" >> %LOG_FILE% 2>&1
    
    REM Set Python path for this session
    set "PATH=%CD%\python-embedded;%PATH%"
    call :log "Using embedded Python for the build process."
) else (
    call :log "Python is already installed."
)

REM Check if the distributable ZIP exists on GitHub
call :log "Checking for pre-built distributable on GitHub..."
powershell -Command "& {try { Invoke-WebRequest -Uri 'https://github.com/IsaiahDupree/VideoPackagingFast/releases/latest/download/VideoProcessor_Windows.zip' -OutFile 'VideoProcessor_Windows_github.zip' -TimeoutSec 10 } catch { exit 1 }}" >> %LOG_FILE% 2>&1

if %ERRORLEVEL% EQU 0 (
    call :log "Found pre-built distributable. Extracting..."
    if exist dist\VideoProcessor rmdir /s /q dist\VideoProcessor
    mkdir dist\VideoProcessor 2>nul
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows_github.zip', 'dist\VideoProcessor')}" >> %LOG_FILE% 2>&1
    
    if !ERRORLEVEL! EQU 0 (
        call :log "GitHub release extracted successfully. Starting application..."
        start "" dist\VideoProcessor\VideoProcessor.exe
        exit /b 0
    ) else (
        call :log "Failed to extract GitHub release. Proceeding with full installation..."
        if exist VideoProcessor_Windows_github.zip del VideoProcessor_Windows_github.zip
    )
) else (
    call :log "No pre-built distributable found on GitHub or network issue. Proceeding with full installation..."
)

REM Clean previous build artifacts
call :log "Cleaning previous build artifacts..."
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist __pycache__ rmdir /s /q __pycache__
if exist venv rmdir /s /q venv

REM Create and activate virtual environment
call :log "Creating virtual environment..."
python -m venv venv
call venv\Scripts\activate

REM Install dependencies with specific versions
call :log "Installing dependencies..."
python -m pip install --upgrade pip

REM Install core dependencies first
call :log "Installing core dependencies..."
pip install pillow==10.2.0 numpy>=1.22.0 requests>=2.28.0 tqdm>=4.64.0 packaging>=23.0 python-dotenv==1.0.0 pydantic==1.10.8 >> %LOG_FILE% 2>&1

REM Install media processing libraries
call :log "Installing media processing libraries..."
pip install moviepy==1.0.3 pydub==0.25.1 ffmpeg-python==0.2.0 >> %LOG_FILE% 2>&1

REM Install AI libraries
call :log "Installing AI libraries..."
pip install openai==1.12.0 anthropic==0.8.1 >> %LOG_FILE% 2>&1

REM Install PyInstaller with specific version
call :log "Installing PyInstaller..."
pip install PyInstaller==5.6.2 pyinstaller-hooks-contrib==2022.0 >> %LOG_FILE% 2>&1

REM Install PySimpleGUI with the specific version 5.0.0.16 using the direct method
call :log "Installing PySimpleGUI 5.0.0.16..."
python install_pysimplegui_5_0_0_16.py >> %LOG_FILE% 2>&1

REM Download and prepare FFmpeg
call :log "Preparing FFmpeg..."
if not exist ffmpeg_bin mkdir ffmpeg_bin

REM Check if FFmpeg is already downloaded
if not exist ffmpeg_bin\ffmpeg.exe (
    call :log "Downloading FFmpeg..."
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg.zip'}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "Trying alternative download method..."
        curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -o ffmpeg.zip >> %LOG_FILE% 2>&1
    )
    
    call :log "Extracting FFmpeg..."
    powershell -Command "& {Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force}" >> %LOG_FILE% 2>&1
    
    REM Find and copy the ffmpeg.exe file
    for /r ffmpeg_temp %%i in (ffmpeg.exe) do (
        copy "%%i" "ffmpeg_bin\ffmpeg.exe" >> %LOG_FILE% 2>&1
    )
    
    REM Clean up temporary files
    if exist ffmpeg.zip del ffmpeg.zip
    if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
)

REM Create optimized spec file for PySimpleGUI 5.0.0.16
call :log "Creating optimized spec file..."
echo # -*- mode: python ; coding: utf-8 -*- > VideoProcessor_optimized.spec
echo import os >> VideoProcessor_optimized.spec
echo import sys >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo block_cipher = None >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo # Define FFmpeg binary location >> VideoProcessor_optimized.spec
echo ffmpeg_bin = [('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin/ffmpeg.exe')] >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo # Collect all necessary data files >> VideoProcessor_optimized.spec
echo datas = [ >> VideoProcessor_optimized.spec
echo     ('ai_prompts.json', '.'), >> VideoProcessor_optimized.spec
echo     ('config.json', '.'), >> VideoProcessor_optimized.spec
echo     ('resources', 'resources'), >> VideoProcessor_optimized.spec
echo     ('wrapper', 'wrapper') if os.path.exists('wrapper') else ('', '') >> VideoProcessor_optimized.spec
echo ] >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo a = Analysis( >> VideoProcessor_optimized.spec
echo     ['main.py'], >> VideoProcessor_optimized.spec
echo     pathex=[], >> VideoProcessor_optimized.spec
echo     binaries=ffmpeg_bin, >> VideoProcessor_optimized.spec
echo     datas=datas, >> VideoProcessor_optimized.spec
echo     hiddenimports=[ >> VideoProcessor_optimized.spec
echo         'PIL._tkinter_finder', >> VideoProcessor_optimized.spec
echo         'PySimpleGUI', >> VideoProcessor_optimized.spec
echo         'PySimpleGUI.PySimpleGUI', >> VideoProcessor_optimized.spec
echo         'tkinter', >> VideoProcessor_optimized.spec
echo         'tkinter.filedialog', >> VideoProcessor_optimized.spec
echo         'tkinter.constants', >> VideoProcessor_optimized.spec
echo         'tkinter.commondialog', >> VideoProcessor_optimized.spec
echo         'tkinter.dialog', >> VideoProcessor_optimized.spec
echo         'openai', >> VideoProcessor_optimized.spec
echo         'anthropic', >> VideoProcessor_optimized.spec
echo         'pydub', >> VideoProcessor_optimized.spec
echo         'moviepy', >> VideoProcessor_optimized.spec
echo         'numpy', >> VideoProcessor_optimized.spec
echo         'dotenv', >> VideoProcessor_optimized.spec
echo         'requests', >> VideoProcessor_optimized.spec
echo         'packaging', >> VideoProcessor_optimized.spec
echo         'tqdm', >> VideoProcessor_optimized.spec
echo         'json', >> VideoProcessor_optimized.spec
echo         'logging', >> VideoProcessor_optimized.spec
echo         'os', >> VideoProcessor_optimized.spec
echo         'sys', >> VideoProcessor_optimized.spec
echo         'platform', >> VideoProcessor_optimized.spec
echo         'subprocess', >> VideoProcessor_optimized.spec
echo         'tempfile', >> VideoProcessor_optimized.spec
echo         'datetime', >> VideoProcessor_optimized.spec
echo     ], >> VideoProcessor_optimized.spec
echo     hookspath=[], >> VideoProcessor_optimized.spec
echo     hooksconfig={}, >> VideoProcessor_optimized.spec
echo     runtime_hooks=[], >> VideoProcessor_optimized.spec
echo     excludes=[ >> VideoProcessor_optimized.spec
echo         'transformers', >> VideoProcessor_optimized.spec
echo         'tensorflow', >> VideoProcessor_optimized.spec
echo         'torch', >> VideoProcessor_optimized.spec
echo         'whisper', >> VideoProcessor_optimized.spec
echo         'matplotlib', >> VideoProcessor_optimized.spec
echo         'PyQt5', >> VideoProcessor_optimized.spec
echo         'PySide2', >> VideoProcessor_optimized.spec
echo         'IPython', >> VideoProcessor_optimized.spec
echo         'jupyter', >> VideoProcessor_optimized.spec
echo     ], >> VideoProcessor_optimized.spec
echo     win_no_prefer_redirects=False, >> VideoProcessor_optimized.spec
echo     win_private_assemblies=False, >> VideoProcessor_optimized.spec
echo     cipher=block_cipher, >> VideoProcessor_optimized.spec
echo     noarchive=False, >> VideoProcessor_optimized.spec
echo ) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo exe = EXE( >> VideoProcessor_optimized.spec
echo     pyz, >> VideoProcessor_optimized.spec
echo     a.scripts, >> VideoProcessor_optimized.spec
echo     [], >> VideoProcessor_optimized.spec
echo     exclude_binaries=True, >> VideoProcessor_optimized.spec
echo     name='VideoProcessor', >> VideoProcessor_optimized.spec
echo     debug=False, >> VideoProcessor_optimized.spec
echo     bootloader_ignore_signals=False, >> VideoProcessor_optimized.spec
echo     strip=False, >> VideoProcessor_optimized.spec
echo     upx=True, >> VideoProcessor_optimized.spec
echo     console=False, >> VideoProcessor_optimized.spec
echo     disable_windowed_traceback=False, >> VideoProcessor_optimized.spec
echo     argv_emulation=False, >> VideoProcessor_optimized.spec
echo     target_arch=None, >> VideoProcessor_optimized.spec
echo     codesign_identity=None, >> VideoProcessor_optimized.spec
echo     entitlements_file=None, >> VideoProcessor_optimized.spec
echo     icon='resources/icon.ico' if os.path.exists('resources/icon.ico') else None, >> VideoProcessor_optimized.spec
echo ) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo coll = COLLECT( >> VideoProcessor_optimized.spec
echo     exe, >> VideoProcessor_optimized.spec
echo     a.binaries, >> VideoProcessor_optimized.spec
echo     a.zipfiles, >> VideoProcessor_optimized.spec
echo     a.datas, >> VideoProcessor_optimized.spec
echo     strip=False, >> VideoProcessor_optimized.spec
echo     upx=True, >> VideoProcessor_optimized.spec
echo     upx_exclude=[], >> VideoProcessor_optimized.spec
echo     name='VideoProcessor', >> VideoProcessor_optimized.spec
echo ) >> VideoProcessor_optimized.spec

REM Create PySimpleGUI wrapper directory if needed
if not exist wrapper (
    call :log "Creating PySimpleGUI wrapper directory..."
    mkdir wrapper
    echo # Wrapper package > wrapper\__init__.py
)

REM Build the executable
call :log "Building executable with PyInstaller..."
pyinstaller --noconfirm --clean VideoProcessor_optimized.spec >> %LOG_FILE% 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] First build attempt failed, trying alternative approach..."
    
    REM Create PySimpleGUI wrapper module
    call :log "Creating PySimpleGUI wrapper module..."
    if not exist wrapper\PySimpleGUI.py (
        echo # PySimpleGUI wrapper module > wrapper\PySimpleGUI.py
        echo try: >> wrapper\PySimpleGUI.py
        echo     # Try to import the original PySimpleGUI >> wrapper\PySimpleGUI.py
        echo     import PySimpleGUI as sg >> wrapper\PySimpleGUI.py
        echo     # Re-export everything >> wrapper\PySimpleGUI.py
        echo     from PySimpleGUI import * >> wrapper\PySimpleGUI.py
        echo except ImportError: >> wrapper\PySimpleGUI.py
        echo     # Fallback implementation with basic functionality >> wrapper\PySimpleGUI.py
        echo     import tkinter as tk >> wrapper\PySimpleGUI.py
        echo     from tkinter import filedialog, messagebox >> wrapper\PySimpleGUI.py
        echo     # Define minimal namespace >> wrapper\PySimpleGUI.py
        echo     WINDOW_CLOSED = 'WINDOW_CLOSED' >> wrapper\PySimpleGUI.py
        echo     WIN_CLOSED = WINDOW_CLOSED >> wrapper\PySimpleGUI.py
        echo     # Basic functions >> wrapper\PySimpleGUI.py
        echo     def popup_error(message, *args, **kwargs): >> wrapper\PySimpleGUI.py
        echo         return messagebox.showerror("Error", message) >> wrapper\PySimpleGUI.py
        echo     def popup(message, *args, **kwargs): >> wrapper\PySimpleGUI.py
        echo         return messagebox.showinfo("Information", message) >> wrapper\PySimpleGUI.py
    )
    
    REM Try building again with the wrapper
    call :log "Retrying build with wrapper..."
    pyinstaller --noconfirm --clean VideoProcessor_optimized.spec >> %LOG_FILE% 2>&1
)

REM Check if the executable was created
if exist dist\VideoProcessor\VideoProcessor.exe (
    call :log "[SUCCESS] Build completed successfully!"
    set "INSTALL_SUCCESS=1"
) else (
    call :log "[ERROR] Build failed - executable not found"
    goto :error
)

REM Create distributable ZIP file
if %INSTALL_SUCCESS% EQU 1 (
    call :log "Creating distributable ZIP file..."
    if exist VideoProcessor_Windows.zip del VideoProcessor_Windows.zip
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\VideoProcessor', 'VideoProcessor_Windows.zip')}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        call :log "[SUCCESS] ZIP file created successfully: VideoProcessor_Windows.zip"
    ) else (
        call :log "[WARNING] Failed to create ZIP file."
    )
    
    REM Launch the executable for immediate testing
    call :log "Launching the application..."
    start "" dist\VideoProcessor\VideoProcessor.exe
    
    REM Display success message
    echo.
    call :log "====================================================="
    call :log " Installation successful!"
    call :log " The application is now running."
    call :log " A distributable ZIP file has been created."
    call :log "====================================================="
)

goto :end

:error
call :log "[ERROR] Installation failed. Check the log file for details: %LOG_FILE%"
pause
exit /b 1

:end
call :log "Installation process completed."
exit /b 0
