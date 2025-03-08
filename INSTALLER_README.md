# VideoPackagingFast Installer Guide

This document provides instructions for using the one-click installer for VideoPackagingFast.

## Installation Options

### Option 1: One-Click Installer (Recommended)

1. Download the latest `VideoPackagingFast_Installer.exe` from the [Releases page](https://github.com/IsaiahDupree/VideoPackagingFast/releases)
2. Run the installer
3. Follow the on-screen instructions
4. The application will be installed in your Documents folder by default, but you can choose a different location

### Option 2: Manual Installation

If you prefer to install the application manually:

1. Download the latest `VideoProcessor_Windows.zip` from the [Releases page](https://github.com/IsaiahDupree/VideoPackagingFast/releases)
2. Extract the ZIP file to a location of your choice
3. Run `VideoProcessor.exe` to start the application

## System Requirements

- Windows 10 or later
- 4GB RAM minimum (8GB recommended)
- 500MB free disk space
- Internet connection for AI features

## API Keys

To use the AI features, you'll need to set up API keys:

1. Create a file named `.env` in the installation directory
2. Add your API keys:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   ```
3. Alternatively, you can set these as environment variables in your system

## Troubleshooting

### Common Issues

1. **Application won't start**
   - Make sure no antivirus software is blocking the application
   - Try running as administrator

2. **Missing FFmpeg error**
   - The installer should have set up FFmpeg automatically
   - If you're still seeing this error, reinstall the application

3. **API key errors**
   - Verify that your API keys are correct
   - Check that the `.env` file is in the correct location

### Getting Help

If you encounter any issues not covered here:

1. Check the [GitHub Issues page](https://github.com/IsaiahDupree/VideoPackagingFast/issues) for similar problems
2. Create a new issue with details about your problem

## Uninstalling

To uninstall VideoPackagingFast:

1. Go to Start Menu > VideoPackagingFast > Uninstall VideoPackagingFast
2. Follow the on-screen instructions

Alternatively, you can run the `uninstall.bat` file in the installation directory.

## Building from Source

If you want to build the installer from source:

1. Clone the repository
2. Run `build_installer_windows.bat`
3. The installer will be created in the `dist` directory

## License

VideoPackagingFast is licensed under the MIT License. See the LICENSE file for details.
