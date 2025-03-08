# Building VideoProcessor for Different Platforms

This document provides instructions for building the VideoProcessor application as a standalone executable on different platforms.

## Prerequisites

Before building, ensure you have installed all required dependencies:

```bash
pip install -r requirements.txt
```

## Windows Build Instructions

1. Open a command prompt in the project directory
2. Run the build script:

```bash
build_windows.bat
```

3. The executable will be created in the `dist/VideoProcessor` folder
4. To run the application, simply double-click the executable file

## macOS Build Instructions

1. Open Terminal in the project directory
2. Make the build script executable:

```bash
chmod +x build_mac.sh
```

3. Run the build script:

```bash
./build_mac.sh
```

4. The application will be created in the `dist` folder as `VideoProcessor.app`
5. To run the application, simply double-click the .app bundle

## Linux Build Instructions

1. Open a terminal in the project directory
2. Make the build script executable:

```bash
chmod +x build_linux.sh
```

3. Run the build script:

```bash
./build_linux.sh
```

4. The executable will be created in the `dist` folder as `VideoProcessor_linux`
5. To run the application, make it executable and run it:

```bash
chmod +x dist/VideoProcessor_linux
./dist/VideoProcessor_linux
```

## Common Issues and Solutions

### FFmpeg Dependency

The application requires FFmpeg for audio and video processing. If you encounter issues:

- **Windows**: Download FFmpeg from [ffmpeg.org](https://ffmpeg.org/download.html) and add it to your PATH
- **macOS**: Install FFmpeg using Homebrew: `brew install ffmpeg`
- **Linux**: Install FFmpeg using your package manager: `sudo apt install ffmpeg` (Ubuntu/Debian) or `sudo yum install ffmpeg` (CentOS/RHEL)

### OpenAI Whisper Models

The first time you run the application, it will download the Whisper model files. This may take some time depending on your internet connection.

### API Keys

Remember to set your OpenAI and Anthropic API keys in the Settings tab before using the application.

## Troubleshooting

If you encounter any issues during the build process:

1. Ensure all dependencies are installed: `pip install -r requirements.txt`
2. Check that you have the latest version of PyInstaller: `pip install --upgrade pyinstaller`
3. For macOS, ensure you have the appropriate permissions: `chmod +x dist/VideoProcessor.app/Contents/MacOS/VideoProcessor_mac`

For any other issues, please refer to the PyInstaller documentation or open an issue on the project repository.
