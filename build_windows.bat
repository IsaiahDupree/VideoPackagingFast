@echo off
echo Building VideoProcessor for Windows...
echo.

REM Create a clean build environment
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

REM Run PyInstaller with basic options
pyinstaller --noconfirm --clean ^
    --name "VideoProcessor" ^
    --add-data "ai_prompts.json;." ^
    --add-data "config.json;." ^
    --add-data "resources;resources" ^
    --hidden-import PIL._tkinter_finder ^
    --hidden-import openai ^
    --hidden-import anthropic ^
    --hidden-import whisper ^
    --hidden-import pydub ^
    --hidden-import moviepy ^
    --exclude-module transformers ^
    --exclude-module tensorflow ^
    --exclude-module torch ^
    --windowed ^
    main.py

echo.
if %ERRORLEVEL% EQU 0 (
    echo Build completed successfully!
    echo Executable is located in the dist/VideoProcessor folder
) else (
    echo Build failed with error code %ERRORLEVEL%
)

pause
