#!/bin/bash
echo "==================================================="
echo "VideoPackagingFast - Complete macOS Build Script"
echo "==================================================="
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python is not installed"
    echo "Please install Python 3.8 or later and try again"
    exit 1
fi

# Create and activate virtual environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Download FFmpeg if not already present
echo "Checking for FFmpeg..."
if [ ! -f "ffmpeg_bin/ffmpeg" ]; then
    echo "Downloading FFmpeg..."
    python download_ffmpeg.py
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download FFmpeg"
        echo "Please download FFmpeg manually and place it in ffmpeg_bin/ffmpeg"
        exit 1
    fi
fi

# Clean previous build
echo "Cleaning previous build..."
rm -rf build dist

# Build the executable
echo "Building executable with PyInstaller..."
pyinstaller VideoProcessor_mac.spec

echo
echo "==================================================="
echo "Build completed successfully!"
echo "The application is in dist/VideoProcessor.app"
echo
echo "To create a distributable ZIP file:"
echo "- Copy the dist/VideoProcessor.app"
echo "- Create a folder named VideoProcessor_Mac"
echo "- Move VideoProcessor.app into VideoProcessor_Mac"
echo "- Zip the folder to create VideoProcessor_Mac.zip"
echo "==================================================="

# Deactivate virtual environment
deactivate
