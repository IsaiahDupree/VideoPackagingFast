@echo off
echo ===================================================
echo VideoPackagingFast - Simple Start
echo ===================================================
echo.

REM Check if the executable exists
if exist dist\VideoProcessor\VideoProcessor.exe (
    echo Starting application from dist folder...
    start "" dist\VideoProcessor\VideoProcessor.exe
) else if exist VideoProcessor.exe (
    echo Starting application from current folder...
    start "" VideoProcessor.exe
) else if exist VideoProcessor_Windows.zip (
    echo Extracting application from ZIP file...
    if not exist dist\VideoProcessor mkdir dist\VideoProcessor
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('VideoProcessor_Windows.zip', 'dist\VideoProcessor')}"
    
    if exist dist\VideoProcessor\VideoProcessor.exe (
        echo Starting application...
        start "" dist\VideoProcessor\VideoProcessor.exe
    ) else (
        echo Error: Could not find the executable after extraction.
        echo Please run build_direct_install.bat if you have Python installed.
        pause
    )
) else (
    echo Error: VideoProcessor executable not found.
    echo.
    echo If this is your first time running the application:
    echo 1. If you have Python installed, run build_direct_install.bat
    echo 2. If you received this as a package, make sure VideoProcessor_Windows.zip is in the same folder
    echo.
    pause
)
