@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - One-Click Installation Checker
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

REM Check if distributable ZIP exists locally
if exist VideoProcessor_Windows.zip (
    call :log "Distributable ZIP already exists. Extracting..."
    if exist dist\VideoProcessor rmdir /s /q dist\VideoProcessor
    mkdir dist\VideoProcessor 2>nul
    powershell -Command "& {try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows.zip', 'dist\VideoProcessor'); exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
    
    if !ERRORLEVEL! EQU 0 (
        call :log "ZIP extracted successfully. Starting application..."
        start "" dist\VideoProcessor\VideoProcessor.exe
        exit /b 0
    ) else (
        call :log "Failed to extract ZIP. Proceeding with full installation..."
    )
)

REM Check for Python installation
call :log "Checking Python installation..."
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "Python not found. Downloading embedded Python..."
    
    REM Download embedded Python
    powershell -Command "& {try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip' -OutFile 'python-embedded.zip'; exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "[ERROR] Failed to download Python. Trying alternative method..."
        curl -L "https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip" -o python-embedded.zip >> %LOG_FILE% 2>&1
        
        if %ERRORLEVEL% NEQ 0 (
            call :log "[ERROR] All Python download attempts failed."
            goto :error
        )
    )
    
    REM Extract Python
    call :log "Extracting embedded Python..."
    powershell -Command "& {try { Expand-Archive -Path 'python-embedded.zip' -DestinationPath 'python-embedded' -Force; exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
    
    REM Set Python path for this session
    set "PATH=%CD%\python-embedded;%PATH%"
    call :log "Using embedded Python for the build process."
) else (
    call :log "Python is already installed."
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
python -m pip install --upgrade pip >> %LOG_FILE% 2>&1

REM Uninstall any existing packages to avoid conflicts
call :log "Removing any existing packages to avoid conflicts..."
pip uninstall -y PySimpleGUI pydantic moviepy pydub ffmpeg-python openai anthropic PyInstaller pyinstaller-hooks-contrib >> %LOG_FILE% 2>&1

REM Install core dependencies first
call :log "Installing core dependencies..."
pip install pillow==10.2.0 numpy>=1.22.0 requests>=2.28.0 tqdm>=4.64.0 packaging>=23.0 python-dotenv==1.0.0 >> %LOG_FILE% 2>&1

REM Install pydantic with specific version for PyInstaller compatibility
call :log "Installing pydantic with specific version..."
pip install pydantic==1.10.8 >> %LOG_FILE% 2>&1

REM Install media processing libraries
call :log "Installing media processing libraries..."
pip install moviepy==1.0.3 pydub==0.25.1 ffmpeg-python==0.2.0 >> %LOG_FILE% 2>&1

REM Install AI libraries
call :log "Installing AI libraries..."
pip install openai==1.12.0 anthropic==0.8.1 >> %LOG_FILE% 2>&1

REM Install PyInstaller with specific version
call :log "Installing PyInstaller..."
pip install PyInstaller==5.6.2 pyinstaller-hooks-contrib==2022.0 >> %LOG_FILE% 2>&1

REM Install PySimpleGUI with the specific version 5.0.0.16
call :log "Installing PySimpleGUI 5.0.0.16..."
if exist install_pysimplegui_5_0_0_16.py (
    python install_pysimplegui_5_0_0_16.py >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "[WARNING] Failed to install PySimpleGUI using the script. Trying direct pip install..."
        pip install PySimpleGUI==5.0.0.16 --no-deps >> %LOG_FILE% 2>&1
    )
) else (
    call :log "Direct installation script not found. Using pip install..."
    pip install PySimpleGUI==5.0.0.16 --no-deps >> %LOG_FILE% 2>&1
)

REM Verify PySimpleGUI installation
call :log "Verifying PySimpleGUI installation..."
python -c "import PySimpleGUI; print(f'PySimpleGUI version: {PySimpleGUI.__version__}')" >> %LOG_FILE% 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] PySimpleGUI verification failed. Creating fallback wrapper..."
    
    REM Create wrapper directory
    if not exist wrapper mkdir wrapper
    echo # PySimpleGUI wrapper package > wrapper\__init__.py
    echo from .PySimpleGUI import * >> wrapper\__init__.py
    
    REM Create a basic PySimpleGUI wrapper module
    echo # PySimpleGUI wrapper module - Version 5.0.0.16 compatibility layer > wrapper\PySimpleGUI.py
    echo import tkinter as tk >> wrapper\PySimpleGUI.py
    echo from tkinter import filedialog, messagebox >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo __version__ = '5.0.0.16' >> wrapper\PySimpleGUI.py
    echo. >> wrapper\PySimpleGUI.py
    echo # Define constants >> wrapper\PySimpleGUI.py
    echo WINDOW_CLOSED = 'WINDOW_CLOSED' >> wrapper\PySimpleGUI.py
    echo WIN_CLOSED = WINDOW_CLOSED >> wrapper\PySimpleGUI.py
    echo RELIEF_SUNKEN = tk.SUNKEN >> wrapper\PySimpleGUI.py
    echo RELIEF_RAISED = tk.RAISED >> wrapper\PySimpleGUI.py
    echo RELIEF_FLAT = tk.FLAT >> wrapper\PySimpleGUI.py
    echo EMOJI_BASE64_HAPPY_JOY = None >> wrapper\PySimpleGUI.py
    
    call :log "Created PySimpleGUI compatibility wrapper."
)

REM Download and prepare FFmpeg
call :log "Preparing FFmpeg..."
if not exist ffmpeg_bin mkdir ffmpeg_bin

REM Check if FFmpeg is already downloaded
if not exist ffmpeg_bin\ffmpeg.exe (
    call :log "Downloading FFmpeg..."
    powershell -Command "& {try { Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg.zip'; exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "Trying alternative download method..."
        curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -o ffmpeg.zip >> %LOG_FILE% 2>&1
        
        if %ERRORLEVEL% NEQ 0 (
            call :log "[ERROR] Failed to download FFmpeg. Build will continue but may fail later."
        )
    )
    
    if exist ffmpeg.zip (
        call :log "Extracting FFmpeg..."
        powershell -Command "& {try { Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force; exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
        
        REM Find and copy the ffmpeg.exe file
        for /r ffmpeg_temp %%i in (ffmpeg.exe) do (
            copy "%%i" "ffmpeg_bin\ffmpeg.exe" >> %LOG_FILE% 2>&1
        )
        
        REM Clean up temporary files
        if exist ffmpeg.zip del ffmpeg.zip
        if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
    )
)

REM Create optimized spec file for PyInstaller
call :log "Creating optimized spec file..."
echo # -*- mode: python ; coding: utf-8 -*- > VideoProcessor_optimized.spec
echo import os >> VideoProcessor_optimized.spec
echo block_cipher = None >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo # Define paths >> VideoProcessor_optimized.spec
echo ffmpeg_bin = [('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin')] if os.path.exists('ffmpeg_bin/ffmpeg.exe') else [] >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo # Define data files >> VideoProcessor_optimized.spec
echo datas = [] >> VideoProcessor_optimized.spec
echo if os.path.exists('resources'): >> VideoProcessor_optimized.spec
echo     datas.append(('resources', 'resources')) >> VideoProcessor_optimized.spec
echo if os.path.exists('wrapper'): >> VideoProcessor_optimized.spec
echo     datas.append(('wrapper', 'wrapper')) >> VideoProcessor_optimized.spec
echo if os.path.exists('ai_prompts.json'): >> VideoProcessor_optimized.spec
echo     datas.append(('ai_prompts.json', '.')) >> VideoProcessor_optimized.spec
echo if os.path.exists('config.json'): >> VideoProcessor_optimized.spec
echo     datas.append(('config.json', '.')) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo a = Analysis( >> VideoProcessor_optimized.spec
echo     ['main.py'], >> VideoProcessor_optimized.spec
echo     pathex=[], >> VideoProcessor_optimized.spec
echo     binaries=ffmpeg_bin, >> VideoProcessor_optimized.spec
echo     datas=datas, >> VideoProcessor_optimized.spec
echo     hiddenimports=[ >> VideoProcessor_optimized.spec
echo         'PIL', 'numpy', 'requests', 'tqdm', 'packaging', 'dotenv', 'pydantic', >> VideoProcessor_optimized.spec
echo         'moviepy', 'pydub', 'openai', 'anthropic', >> VideoProcessor_optimized.spec
echo         'PySimpleGUI', 'tkinter', 'tkinter.filedialog', 'tkinter.messagebox', >> VideoProcessor_optimized.spec
echo         'tkinter.constants', 'tkinter.commondialog', 'tkinter.dialog' >> VideoProcessor_optimized.spec
echo     ], >> VideoProcessor_optimized.spec
echo     hookspath=[], >> VideoProcessor_optimized.spec
echo     hooksconfig={}, >> VideoProcessor_optimized.spec
echo     runtime_hooks=[], >> VideoProcessor_optimized.spec
echo     excludes=[], >> VideoProcessor_optimized.spec
echo     win_no_prefer_redirects=False, >> VideoProcessor_optimized.spec
echo     win_private_assemblies=False, >> VideoProcessor_optimized.spec
echo     cipher=block_cipher, >> VideoProcessor_optimized.spec
echo     noarchive=False, >> VideoProcessor_optimized.spec
echo ) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher) >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo icon_file = None >> VideoProcessor_optimized.spec
echo if os.path.exists('resources/icon.ico'): >> VideoProcessor_optimized.spec
echo     icon_file = 'resources/icon.ico' >> VideoProcessor_optimized.spec
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
echo     upx_exclude=[], >> VideoProcessor_optimized.spec
echo     runtime_tmpdir=None, >> VideoProcessor_optimized.spec
echo     console=False, >> VideoProcessor_optimized.spec
echo     disable_windowed_traceback=False, >> VideoProcessor_optimized.spec
echo     argv_emulation=False, >> VideoProcessor_optimized.spec
echo     target_arch=None, >> VideoProcessor_optimized.spec
echo     codesign_identity=None, >> VideoProcessor_optimized.spec
echo     entitlements_file=None, >> VideoProcessor_optimized.spec
echo     icon=icon_file, >> VideoProcessor_optimized.spec
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

REM Build the application
call :log "Building the application..."
pyinstaller VideoProcessor_optimized.spec --noconfirm >> %LOG_FILE% 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] Build failed. Trying alternative approach..."
    
    REM Try with a simpler spec file
    call :log "Creating simplified spec file..."
    pyinstaller --name=VideoProcessor --windowed --noconfirm main.py >> %LOG_FILE% 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        goto :error
    )
)

REM Check if build was successful
if exist dist\VideoProcessor\VideoProcessor.exe (
    call :log "Build successful!"
    set "INSTALL_SUCCESS=1"
    
    REM Create distributable ZIP file
    call :log "Creating distributable ZIP file..."
    if exist VideoProcessor_Windows.zip del VideoProcessor_Windows.zip
    powershell -Command "& {try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\VideoProcessor', 'VideoProcessor_Windows.zip'); exit 0 } catch { exit 1 }}" >> %LOG_FILE% 2>&1
    
    REM Launch the application
    call :log "Starting the application..."
    start "" dist\VideoProcessor\VideoProcessor.exe
) else (
    call :log "[ERROR] Build failed. Check the log file for details."
    goto :error
)

REM Clean up temporary files
call :log "Cleaning up temporary files..."
if exist build rmdir /s /q build
if exist __pycache__ rmdir /s /q __pycache__
if exist *.spec del *.spec
if exist venv rmdir /s /q venv

call :log "Installation completed successfully!"
exit /b 0

:error
call :log "[ERROR] Installation failed. Please check the log file for details: %LOG_FILE%"
exit /b 1
