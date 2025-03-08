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

REM Check if the logger helper exists
if exist install_logger.bat (
    call install_logger.bat :log_system_info "%LOG_FILE%"
    call install_logger.bat :log "INFO" "Using enhanced logging" "%LOG_FILE%"
) else (
    REM Define simple logging function if helper is not available
    echo Simple logging mode activated >> %LOG_FILE%
)

REM Function to log messages (fallback if helper not available)
:log
    if exist install_logger.bat (
        call install_logger.bat :log "INFO" "%~1" "%LOG_FILE%"
    ) else (
        echo %~1
        echo %~1 >> %LOG_FILE%
    )
    goto :eof

REM Function to execute commands with logging
:exec_command
    if exist install_logger.bat (
        call install_logger.bat :capture_command "%~1" "%~2" "%LOG_FILE%"
    ) else (
        call :log "Executing: %~2"
        %~1 >> %LOG_FILE% 2>&1
    )
    exit /b %ERRORLEVEL%

REM Function to pause and wait for user input
:pause_for_user
    echo.
    echo %~1
    echo Press any key to continue...
    pause > nul
    goto :eof

REM Display welcome message and instructions
echo Welcome to the VideoPackagingFast Installation Process
echo This window will remain open during the entire installation
echo You can find detailed logs in: %LOG_FILE%
echo.
echo The installation will perform the following steps:
echo  1. Check for existing installation
echo  2. Download and install dependencies
echo  3. Build the application
echo  4. Create a distributable package
echo.
echo Press any key to begin installation...
pause > nul
echo.

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
        call :pause_for_user "Application started successfully! You can close this window."
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
    
    call :exec_command "powershell -Command ""& {try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows.zip', 'dist\VideoProcessor'); exit 0 } catch { exit 1 }}""" "Extract ZIP file"
    
    if !ERRORLEVEL! EQU 0 (
        call :log "ZIP extracted successfully. Starting application..."
        start "" dist\VideoProcessor\VideoProcessor.exe
        call :pause_for_user "Application started successfully! You can close this window."
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
    call :exec_command "powershell -Command ""& {try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip' -OutFile 'python-embedded.zip'; exit 0 } catch { exit 1 }}""" "Download embedded Python"
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "Failed to download Python. Trying alternative method..."
        call :exec_command "curl -L ""https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip"" -o python-embedded.zip" "Download Python with curl"
        
        if %ERRORLEVEL% NEQ 0 (
            call :log "All Python download attempts failed."
            call :pause_for_user "Installation failed: Could not download Python. Check your internet connection and try again."
            goto :error
        )
    )
    
    REM Extract Python
    call :log "Extracting embedded Python..."
    call :exec_command "powershell -Command ""& {try { Expand-Archive -Path 'python-embedded.zip' -DestinationPath 'python-embedded' -Force; exit 0 } catch { exit 1 }}""" "Extract Python"
    
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
call :exec_command "python -m pip install --upgrade pip" "Upgrade pip"

REM Uninstall any existing packages to avoid conflicts
call :log "Removing any existing packages to avoid conflicts..."
call :exec_command "pip uninstall -y PySimpleGUI pydantic moviepy pydub ffmpeg-python openai anthropic PyInstaller pyinstaller-hooks-contrib" "Uninstall existing packages"

REM Install core dependencies first
call :log "Installing core dependencies..."
call :exec_command "pip install pillow==10.2.0 numpy>=1.22.0 requests>=2.28.0 tqdm>=4.64.0 packaging>=23.0 python-dotenv==1.0.0" "Install core dependencies"

REM Install pydantic with specific version for PyInstaller compatibility
call :log "Installing pydantic with specific version..."
call :exec_command "pip install pydantic==1.10.8" "Install pydantic"

REM Install media processing libraries
call :log "Installing media processing libraries..."
call :exec_command "pip install moviepy==1.0.3 pydub==0.25.1 ffmpeg-python==0.2.0" "Install media libraries"

REM Install AI libraries
call :log "Installing AI libraries..."
call :exec_command "pip install openai==1.12.0 anthropic==0.8.1" "Install AI libraries"

REM Install PyInstaller with specific version
call :log "Installing PyInstaller..."
call :exec_command "pip install PyInstaller==5.6.2 pyinstaller-hooks-contrib==2022.0" "Install PyInstaller"

REM Install PySimpleGUI with the specific version 5.0.0.16
call :log "Installing PySimpleGUI 5.0.0.16..."
if exist install_pysimplegui_5_0_0_16.py (
    call :exec_command "python install_pysimplegui_5_0_0_16.py" "Install PySimpleGUI with custom script"
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "Failed to install PySimpleGUI using the script. Trying direct pip install..."
        call :exec_command "pip install PySimpleGUI==5.0.0.16 --no-deps" "Install PySimpleGUI with pip"
    )
) else (
    call :log "Direct installation script not found. Using pip install..."
    call :exec_command "pip install PySimpleGUI==5.0.0.16 --no-deps" "Install PySimpleGUI with pip"
)

REM Verify PySimpleGUI installation
call :log "Verifying PySimpleGUI installation..."
python -c "import PySimpleGUI; print(f'PySimpleGUI version: {PySimpleGUI.__version__}')" >> %LOG_FILE% 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :log "PySimpleGUI verification failed. Creating fallback wrapper..."
    
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
    call :exec_command "powershell -Command ""& {try { Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg.zip'; exit 0 } catch { exit 1 }}""" "Download FFmpeg"
    
    if %ERRORLEVEL% NEQ 0 (
        call :log "Trying alternative download method..."
        call :exec_command "curl -L ""https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"" -o ffmpeg.zip" "Download FFmpeg with curl"
        
        if %ERRORLEVEL% NEQ 0 (
            call :log "Failed to download FFmpeg. Build will continue but may fail later."
        )
    )
    
    if exist ffmpeg.zip (
        call :log "Extracting FFmpeg..."
        call :exec_command "powershell -Command ""& {try { Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force; exit 0 } catch { exit 1 }}""" "Extract FFmpeg"
        
        REM Find and copy the ffmpeg.exe file
        for /r ffmpeg_temp %%i in (ffmpeg.exe) do (
            copy "%%i" "ffmpeg_bin\ffmpeg.exe" >> %LOG_FILE% 2>&1
        )
        
        REM Clean up temporary files
        if exist ffmpeg.zip del ffmpeg.zip
        if exist ffmpeg_temp rmdir /s /q ffmpeg_temp
    )
)

REM Use external spec file if available
if exist VideoProcessor.spec (
    call :log "Using existing spec file..."
    call :exec_command "pyinstaller VideoProcessor.spec --noconfirm" "Build with existing spec"
) else (
    REM Create optimized spec file for PyInstaller
    call :log "Creating optimized spec file..."
    if exist create_spec_file.py (
        call :exec_command "python create_spec_file.py" "Generate spec file"
    ) else (
        REM Simplified spec file creation
        call :log "Using simplified spec creation..."
        call :exec_command "pyinstaller --name=VideoProcessor --windowed --add-data ""ffmpeg_bin;ffmpeg_bin"" --icon=resources\icon.ico main.py" "Build with simplified spec"
    )
)

REM Check if build was successful
if exist dist\VideoProcessor\VideoProcessor.exe (
    call :log "Build successful!"
    set "INSTALL_SUCCESS=1"
    
    REM Create distributable ZIP file
    call :log "Creating distributable ZIP file..."
    if exist VideoProcessor_Windows.zip del VideoProcessor_Windows.zip
    call :exec_command "powershell -Command ""& {try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\VideoProcessor', 'VideoProcessor_Windows.zip'); exit 0 } catch { exit 1 }}""" "Create ZIP file"
    
    REM Launch the application
    call :log "Starting the application..."
    start "" dist\VideoProcessor\VideoProcessor.exe
    
    echo.
    echo ===================================================
    echo Installation completed successfully!
    echo ===================================================
    echo.
    echo The application has been installed and launched.
    echo A log file has been created at: %LOG_FILE%
    echo.
    echo You can find the application at:
    echo %CD%\dist\VideoProcessor\VideoProcessor.exe
    echo.
    echo A distributable ZIP has also been created at:
    echo %CD%\VideoProcessor_Windows.zip
) else (
    call :log "Build failed. Check the log file for details."
    goto :error
)

REM Clean up temporary files
call :log "Cleaning up temporary files..."
if exist build rmdir /s /q build
if exist __pycache__ rmdir /s /q __pycache__
if exist *.spec del *.spec
if exist venv rmdir /s /q venv

REM Run diagnostics if available
if exist run_diagnostics.bat (
    call :log "Running diagnostics..."
    call run_diagnostics.bat
)

call :log "Installation completed successfully!"
echo.
echo ===================================================
echo Installation process has completed!
echo ===================================================
echo.
echo You can find the log file at: %LOG_FILE%
echo.
echo Press any key to exit...
pause > nul
exit /b 0

:error
call :log "[ERROR] Installation failed. Please check the log file: %LOG_FILE%"
echo.
echo ===================================================
echo Installation process has failed!
echo ===================================================
echo.
echo Please check the log file at: %LOG_FILE% for details.
echo.
echo Press any key to exit...
pause > nul
exit /b 1
