#!/bin/bash
echo "Building VideoProcessor for macOS..."
echo

# Create a clean build environment
rm -rf build dist

# Run PyInstaller with basic options
pyinstaller --noconfirm --clean \
    --name "VideoProcessor" \
    --add-data "ai_prompts.json:." \
    --add-data "config.json:." \
    --add-data "resources:resources" \
    --hidden-import PIL._tkinter_finder \
    --hidden-import openai \
    --hidden-import anthropic \
    --hidden-import whisper \
    --hidden-import pydub \
    --hidden-import moviepy \
    --exclude-module transformers \
    --exclude-module tensorflow \
    --exclude-module torch \
    --windowed \
    --osx-bundle-identifier "com.videoprocessor.app" \
    main.py

echo
if [ $? -eq 0 ]; then
    echo "Build completed successfully!"
    echo "Application is located in the dist folder as VideoProcessor.app"
    # Make the app executable
    chmod +x dist/VideoProcessor.app/Contents/MacOS/VideoProcessor
else
    echo "Build failed with error code $?"
fi
