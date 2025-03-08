# Build Instructions for VideoPackagingFast

This document provides detailed instructions for building the VideoPackagingFast application from source on both Windows and macOS platforms.

## Prerequisites

Before building the application, ensure you have the following installed:

- Python 3.8 or higher
- FFmpeg (available in your system PATH)
- Git (for cloning the repository)

## Common Setup (All Platforms)

1. **Clone the repository**
   ```
   git clone https://github.com/IsaiahDupree/VideoPackagingFast.git
   cd VideoPackagingFast
   ```

2. **Install dependencies**
   ```
   pip install -r requirements.txt
   ```

3. **Configure API keys**
   - Create a file named `.env` in the project root directory
   - Add your API keys:
     ```
     OPENAI_API_KEY=your_openai_api_key_here
     ANTHROPIC_API_KEY=your_anthropic_api_key_here
     ```
   - Alternatively, you can set these as environment variables in your system

## Running from Source (Recommended)

The simplest way to use the application is to run it directly from source:

```
python main.py
```

This method works on all platforms and ensures you have access to all features.

## Building Executables

### Windows

1. **Install PyInstaller** (if not already installed)
   ```
   pip install pyinstaller
   ```

2. **Run the build script**
   ```
   .\build_windows.bat
   ```

3. **Locate the executable**
   - The executable will be in the `dist/VideoProcessor` folder
   - You can run it by double-clicking `VideoProcessor.exe`

4. **Creating a distributable package**
   - Zip the entire `dist/VideoProcessor` folder
   - Share this ZIP file with users

### macOS

1. **Install PyInstaller** (if not already installed)
   ```
   pip install pyinstaller
   ```

2. **Make the build script executable**
   ```
   chmod +x build_mac.sh
   ```

3. **Run the build script**
   ```
   ./build_mac.sh
   ```

4. **Locate the application**
   - The application will be in the `dist` folder as `VideoProcessor.app`
   - You can run it by double-clicking the app

5. **Creating a distributable package**
   - Create a DMG file using Disk Utility or a tool like `create-dmg`
   - Alternatively, zip the `.app` file for distribution

## Troubleshooting Build Issues

### Common Issues

1. **Missing dependencies**
   - Ensure all dependencies are installed: `pip install -r requirements.txt`
   - Some packages may require additional system libraries

2. **FFmpeg not found**
   - Verify FFmpeg is installed and in your PATH
   - Test by running `ffmpeg -version` in your terminal

3. **PyInstaller errors**
   - Try using a specific version of PyInstaller: `pip install pyinstaller==5.6.2`
   - Clear the build and dist directories before rebuilding

4. **Missing modules in executable**
   - If the executable fails with "ModuleNotFoundError", edit the spec file to include the missing module
   - Add the module to the `hiddenimports` list in the spec file

5. **Permission issues**
   - Run the build script with administrator privileges
   - Ensure no files are locked by other processes

### Advanced: Customizing the Build

You can customize the build by editing the spec files:
- `VideoProcessor_windows.spec` for Windows
- `VideoProcessor_mac.spec` for macOS

These files control how PyInstaller packages the application.

## Running the Built Application

### Windows

1. Navigate to the `dist/VideoProcessor` folder
2. Double-click `VideoProcessor.exe`

### macOS

1. Navigate to the `dist` folder
2. Double-click `VideoProcessor.app`

## Notes for Developers

- The application is structured in a modular way with separate components for UI, core processing, and utilities
- When making changes, ensure cross-platform compatibility by using platform-agnostic paths and operations
- Test your changes on both Windows and macOS if possible
- Update the requirements.txt file if you add new dependencies

## Distributing to Users

For the best user experience, provide:

1. Clear installation instructions
2. Information about required dependencies (especially FFmpeg)
3. Instructions for obtaining and configuring API keys
4. A sample video for testing

Remember that users will need their own API keys for OpenAI or Anthropic services.
