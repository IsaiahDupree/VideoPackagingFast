# VideoPackagingFast - Simplified Installation Guide

This guide provides streamlined instructions for installing and running the VideoPackagingFast application on Windows systems.

## One-Click Installation

We've created a simplified one-click installation process that handles all dependencies automatically, including PySimpleGUI 5.0.0.16 and FFmpeg.

### Option 1: Using the One-Click Installer (Recommended)

1. **Run the one-click installer**:

   ```batch
   one_click_install_check.bat
   ```

   This script will:
   - Check if the application is already installed
   - Download and install Python if needed
   - Install all required dependencies with correct versions
   - Install PySimpleGUI 5.0.0.16 with compatibility fixes
   - Download and configure FFmpeg
   - Build the application
   - Launch the application automatically

2. **That's it!** The application will start automatically when the installation is complete.

### Option 2: Using Pre-built Distributable

If you received a pre-built distributable ZIP file:

1. Extract `VideoProcessor_Windows.zip` to any folder
2. Run `VideoProcessor.exe` from the extracted folder

## Troubleshooting

If you encounter any issues during installation:

1. **Check the log file**:
   - The installer creates a log file named `install_log_YYYYMMDD_HHMMSS.txt`
   - This file contains detailed information about the installation process

2. **Common issues and solutions**:

   - **PySimpleGUI errors**:
     The installer includes special handling for PySimpleGUI 5.0.0.16 compatibility issues.
   - **FFmpeg not found**:
     The installer automatically downloads and configures FFmpeg.
   - **Python not installed**:
     The installer will download and use an embedded Python if needed.

## New Direct Packaging Approach

We've added a new simplified packaging approach that creates a ZIP file of the application without relying on PyInstaller, making the process more reliable:

### Using the Direct Packaging Tool

1. **Run the direct packaging script**:

   ```batch
   direct_package.bat
   ```

   This script will:
   - Create a clean package of all application files
   - Include all necessary Python scripts and resources
   - Package FFmpeg binaries (if available)
   - Create a requirements.txt file for dependencies
   - Generate startup scripts for Windows and macOS
   - Create a ZIP package in the `installers` folder

2. **Install from the ZIP package**:
   - Extract `VideoProcessor_Windows_Latest.zip` from the `installers` folder
   - Run `run_app.bat` to start the application

### Handling File Access Issues

If you see a warning about file access issues during packaging:

1. **Check the note file**:
   - Look for a file named `PACKAGING_ISSUE_YYYYMMDD_HHMMSS.md` in the `installers` folder
   - This file contains detailed instructions on how to resolve the issue

2. **Common solutions**:
   - Close any running instances of the application
   - Close any file explorers or terminals that might be accessing files in the application directory
   - Run the packaging script again
   - If issues persist, follow the manual packaging instructions in the note file

## Cross-Platform Support

VideoPackagingFast now includes improved cross-platform support:

### For macOS Users

1. **Run the macOS packaging script**:

   ```bash
   ./direct_package.sh
   ```

2. **Install from the ZIP package**:
   - Extract `VideoProcessor_macOS_Latest.zip` from the `installers` folder
   - Run `./run_app.sh` to start the application

The application is designed to work seamlessly on both Windows and macOS environments.

## System Requirements

- Windows 10 or later
- 4GB RAM minimum (8GB recommended)
- 1GB free disk space
- Internet connection (for initial installation)

## Uninstallation

To uninstall the application:

1. Delete the `dist\VideoProcessor` directory
2. Delete the `VideoProcessor_Windows.zip` file if present

No registry entries or system files are modified during installation.
