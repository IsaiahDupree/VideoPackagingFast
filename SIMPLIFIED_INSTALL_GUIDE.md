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

3. **Manual installation**:
   If the one-click installer fails, you can try the alternative build scripts:

   ```batch
   build_direct_install.bat
   ```

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
