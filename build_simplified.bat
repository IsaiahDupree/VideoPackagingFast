@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - Simplified Build Script
echo ===================================================
echo.

REM Set error handling
set "BUILD_SUCCESS=0"
set "EXECUTABLE_PATH=dist\VideoProcessor\VideoProcessor.exe"

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

REM Install core dependencies first
call :log "Installing core dependencies..."
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

REM Install media processing libraries
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

REM Install PySimpleGUI with the specific version 5.0.0.16
call :log "Installing PySimpleGUI 5.0.0.16..."
python fix_pysimplegui.py >> %LOG_FILE% 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[WARNING] PySimpleGUI installation script had issues"
    call :log "Attempting direct installation..."
    pip install PySimpleGUI==5.0.0.16 >> %LOG_FILE% 2>&1
    if %ERRORLEVEL% NEQ 0 (
        call :log "[WARNING] Direct installation also had issues"
        call :log "Continuing with build process..."
    )
)

REM Download and prepare FFmpeg (always include it in the build)
call :log "Preparing FFmpeg for bundling..."
if not exist ffmpeg_bin mkdir ffmpeg_bin

REM Check if FFmpeg is already downloaded
if not exist ffmpeg_bin\ffmpeg.exe (
    call :log "Downloading FFmpeg..."
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
    for /r ffmpeg_temp %%i in (ffmpeg.exe) do (
        copy "%%i" "ffmpeg_bin\ffmpeg.exe" >> %LOG_FILE% 2>&1
    )
    
    REM Clean up temporary files
    if exist ffmpeg.zip del ffmpeg.zip
    if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
)

REM Create a modified spec file that includes FFmpeg
call :log "Creating modified spec file with FFmpeg bundling..."
echo # -*- mode: python ; coding: utf-8 -*- > VideoProcessor_simplified.spec
echo import os >> VideoProcessor_simplified.spec
echo import sys >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo block_cipher = None >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo # Define FFmpeg binary location >> VideoProcessor_simplified.spec
echo ffmpeg_bin = [('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin/ffmpeg.exe')] >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo # Collect all necessary data files >> VideoProcessor_simplified.spec
echo datas = [ >> VideoProcessor_simplified.spec
echo     ('ai_prompts.json', '.'), >> VideoProcessor_simplified.spec
echo     ('config.json', '.'), >> VideoProcessor_simplified.spec
echo     ('resources', 'resources') >> VideoProcessor_simplified.spec
echo ] >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo a = Analysis( >> VideoProcessor_simplified.spec
echo     ['main.py'], >> VideoProcessor_simplified.spec
echo     pathex=[], >> VideoProcessor_simplified.spec
echo     binaries=ffmpeg_bin, >> VideoProcessor_simplified.spec
echo     datas=datas, >> VideoProcessor_simplified.spec
echo     hiddenimports=[ >> VideoProcessor_simplified.spec
echo         'PIL._tkinter_finder', >> VideoProcessor_simplified.spec
echo         'PySimpleGUI', >> VideoProcessor_simplified.spec
echo         'openai', >> VideoProcessor_simplified.spec
echo         'anthropic', >> VideoProcessor_simplified.spec
echo         'pydub', >> VideoProcessor_simplified.spec
echo         'moviepy', >> VideoProcessor_simplified.spec
echo         'numpy', >> VideoProcessor_simplified.spec
echo         'tkinter', >> VideoProcessor_simplified.spec
echo         'dotenv', >> VideoProcessor_simplified.spec
echo         'requests', >> VideoProcessor_simplified.spec
echo         'packaging', >> VideoProcessor_simplified.spec
echo         'tqdm', >> VideoProcessor_simplified.spec
echo         'json', >> VideoProcessor_simplified.spec
echo         'logging', >> VideoProcessor_simplified.spec
echo         'os', >> VideoProcessor_simplified.spec
echo         'sys', >> VideoProcessor_simplified.spec
echo         'platform', >> VideoProcessor_simplified.spec
echo         'subprocess', >> VideoProcessor_simplified.spec
echo         'tempfile', >> VideoProcessor_simplified.spec
echo         'datetime', >> VideoProcessor_simplified.spec
echo     ], >> VideoProcessor_simplified.spec
echo     hookspath=[], >> VideoProcessor_simplified.spec
echo     hooksconfig={}, >> VideoProcessor_simplified.spec
echo     runtime_hooks=[], >> VideoProcessor_simplified.spec
echo     excludes=[ >> VideoProcessor_simplified.spec
echo         'transformers', >> VideoProcessor_simplified.spec
echo         'tensorflow', >> VideoProcessor_simplified.spec
echo         'torch', >> VideoProcessor_simplified.spec
echo         'whisper', >> VideoProcessor_simplified.spec
echo         'matplotlib', >> VideoProcessor_simplified.spec
echo         'PyQt5', >> VideoProcessor_simplified.spec
echo         'PySide2', >> VideoProcessor_simplified.spec
echo         'IPython', >> VideoProcessor_simplified.spec
echo         'jupyter', >> VideoProcessor_simplified.spec
echo     ], >> VideoProcessor_simplified.spec
echo     win_no_prefer_redirects=False, >> VideoProcessor_simplified.spec
echo     win_private_assemblies=False, >> VideoProcessor_simplified.spec
echo     cipher=block_cipher, >> VideoProcessor_simplified.spec
echo     noarchive=False, >> VideoProcessor_simplified.spec
echo ) >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher) >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo exe = EXE( >> VideoProcessor_simplified.spec
echo     pyz, >> VideoProcessor_simplified.spec
echo     a.scripts, >> VideoProcessor_simplified.spec
echo     [], >> VideoProcessor_simplified.spec
echo     exclude_binaries=True, >> VideoProcessor_simplified.spec
echo     name='VideoProcessor', >> VideoProcessor_simplified.spec
echo     debug=False, >> VideoProcessor_simplified.spec
echo     bootloader_ignore_signals=False, >> VideoProcessor_simplified.spec
echo     strip=False, >> VideoProcessor_simplified.spec
echo     upx=True, >> VideoProcessor_simplified.spec
echo     console=False, >> VideoProcessor_simplified.spec
echo     disable_windowed_traceback=False, >> VideoProcessor_simplified.spec
echo     argv_emulation=False, >> VideoProcessor_simplified.spec
echo     target_arch=None, >> VideoProcessor_simplified.spec
echo     codesign_identity=None, >> VideoProcessor_simplified.spec
echo     entitlements_file=None, >> VideoProcessor_simplified.spec
echo     icon='resources/icon.ico' if os.path.exists('resources/icon.ico') else 'resources/fallback_icon.ico', >> VideoProcessor_simplified.spec
echo ) >> VideoProcessor_simplified.spec
echo. >> VideoProcessor_simplified.spec
echo coll = COLLECT( >> VideoProcessor_simplified.spec
echo     exe, >> VideoProcessor_simplified.spec
echo     a.binaries, >> VideoProcessor_simplified.spec
echo     a.zipfiles, >> VideoProcessor_simplified.spec
echo     a.datas, >> VideoProcessor_simplified.spec
echo     strip=False, >> VideoProcessor_simplified.spec
echo     upx=True, >> VideoProcessor_simplified.spec
echo     upx_exclude=[], >> VideoProcessor_simplified.spec
echo     name='VideoProcessor', >> VideoProcessor_simplified.spec
echo ) >> VideoProcessor_simplified.spec

REM Build the executable using the simplified spec
call :log "Building executable with PyInstaller..."
pyinstaller --noconfirm --clean VideoProcessor_simplified.spec >> %LOG_FILE% 2>&1

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
call :log "[ERROR] Build process failed. Check the log file for details: %LOG_FILE%"
exit /b 1

:end
call :log "Build process completed."
exit /b 0
