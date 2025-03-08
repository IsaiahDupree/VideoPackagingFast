@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo VideoPackagingFast - Build Script with Direct PySimpleGUI Install
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

REM Check if Python is installed
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :log "[ERROR] Python is not installed or not in PATH"
    call :log "Please install Python 3.8 or later and try again"
    exit /b 1
)

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

REM Uninstall PySimpleGUI if it exists to avoid conflicts
call :log "Uninstalling any existing PySimpleGUI..."
pip uninstall -y PySimpleGUI >> %LOG_FILE% 2>&1

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

REM Install PySimpleGUI with the specific version 5.0.0.16
call :log "Installing PySimpleGUI 5.0.0.16..."
if exist install_pysimplegui_5_0_0_16.py (
    python install_pysimplegui_5_0_0_16.py >> %LOG_FILE% 2>&1
) else (
    call :log "[WARNING] install_pysimplegui_5_0_0_16.py not found"
    call :log "Creating a basic PySimpleGUI wrapper module..."
    
    REM Create wrapper directory
    if not exist wrapper mkdir wrapper
    if not exist wrapper\__init__.py (
        echo # PySimpleGUI wrapper package > wrapper\__init__.py
    )
    
    REM Create a basic PySimpleGUI wrapper module
    echo # PySimpleGUI wrapper module - Basic implementation > wrapper\PySimpleGUI.py
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
    
    call :log "Created basic PySimpleGUI wrapper module"
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

REM Create a simple spec file that includes all necessary files
call :log "Creating optimized spec file..."
echo # -*- mode: python -*- > VideoProcessor_optimized.spec
echo block_cipher = None >> VideoProcessor_optimized.spec
echo. >> VideoProcessor_optimized.spec
echo a = Analysis( >> VideoProcessor_optimized.spec
echo     ['main.py'], >> VideoProcessor_optimized.spec
echo     pathex=[], >> VideoProcessor_optimized.spec
echo     binaries=[('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin')], >> VideoProcessor_optimized.spec
echo     datas=[('wrapper', 'wrapper'), ('resources', 'resources')], >> VideoProcessor_optimized.spec
echo     hiddenimports=['PIL', 'numpy', 'requests', 'tqdm', 'packaging', 'dotenv', 'pydantic', 'moviepy', 'pydub', 'openai', 'anthropic'], >> VideoProcessor_optimized.spec
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
echo     icon='resources/icon.ico', >> VideoProcessor_optimized.spec
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

REM Build the executable
call :log "Building executable with PyInstaller..."
pyinstaller --noconfirm --clean VideoProcessor_optimized.spec >> %LOG_FILE% 2>&1

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
    
    REM Create a simple start.bat file for users without Python
    call :log "Creating simple start.bat file..."
    echo @echo off > start.bat
    echo echo Starting VideoPackagingFast application... >> start.bat
    echo. >> start.bat
    echo REM Check if the executable exists >> start.bat
    echo if exist dist\VideoProcessor\VideoProcessor.exe ( >> start.bat
    echo     start "" dist\VideoProcessor\VideoProcessor.exe >> start.bat
    echo ) else if exist VideoProcessor.exe ( >> start.bat
    echo     start "" VideoProcessor.exe >> start.bat
    echo ) else if exist VideoProcessor_Windows.zip ( >> start.bat
    echo     echo Extracting application from ZIP file... >> start.bat
    echo     if not exist dist\VideoProcessor mkdir dist\VideoProcessor >> start.bat
    echo     powershell -Command "^& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows.zip', 'dist\VideoProcessor')}" >> start.bat
    echo     if exist dist\VideoProcessor\VideoProcessor.exe ( >> start.bat
    echo         start "" dist\VideoProcessor\VideoProcessor.exe >> start.bat
    echo     ) else ( >> start.bat
    echo         echo Error: Could not find the executable after extraction. >> start.bat
    echo         pause >> start.bat
    echo     ) >> start.bat
    echo ) else ( >> start.bat
    echo     echo Error: VideoProcessor executable not found. >> start.bat
    echo     echo Please run build_direct_install.bat first to build the application. >> start.bat
    echo     pause >> start.bat
    echo ) >> start.bat
    
    REM Launch the executable for immediate testing
    call :log "Launching the application for testing..."
    start "" %EXECUTABLE_PATH%
    
    REM Display success message
    echo.
    call :log "====================================================="
    call :log " Build and launch successful!"
    call :log " The application is now running for testing."
    call :log " A distributable ZIP file has been created: VideoProcessor_Windows.zip"
    call :log " A simple start.bat file has been created for users without Python."
    call :log "====================================================="
    call :log " To distribute this application to users without Python:"
    call :log " 1. Share the VideoProcessor_Windows.zip file and start.bat"
    call :log " 2. Users only need to run start.bat to launch the application"
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
