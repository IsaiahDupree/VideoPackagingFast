@echo off
echo Building VideoProcessor for Windows...

:: Close any running instances of the application
taskkill /f /im VideoProcessor.exe 2>nul
taskkill /f /im python.exe 2>nul

:: Wait a moment for processes to fully terminate
timeout /t 2 /nobreak >nul

:: Create a clean build environment
echo Cleaning build directories...
if exist build (
    rmdir /s /q build 2>nul
    if exist build (
        echo Warning: Could not remove build directory completely.
        echo This may be due to locked files. Continuing anyway...
    )
)

if exist dist (
    rmdir /s /q dist 2>nul
    if exist dist (
        echo Warning: Could not remove dist directory completely.
        echo This may be due to locked files. Continuing anyway...
    )
)

:: Run PyInstaller with our custom spec file
echo Running PyInstaller...
pyinstaller --noconfirm --clean VideoProcessor_windows.spec

echo.
if %ERRORLEVEL% EQU 0 (
    echo Build completed successfully!
    echo Executable is located in the dist/VideoProcessor folder
) else (
    echo Build failed with error code %ERRORLEVEL%
    echo.
    echo Troubleshooting tips:
    echo 1. Make sure no instances of the application are running
    echo 2. Try closing any Python processes or IDEs
    echo 3. Restart your computer and try again
    echo 4. Run the application from source using: python main.py
)

pause
