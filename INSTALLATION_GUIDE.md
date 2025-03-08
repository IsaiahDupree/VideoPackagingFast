# VideoPackagingFast Installation Guide

This guide provides step-by-step instructions for installing and running the VideoPackagingFast application on both Windows and macOS.

## Prerequisites

- **Python 3.9 or higher** installed on your system
- **Internet connection** for downloading dependencies (first run only)

## Windows Installation

### Option 1: Using the One-Click Installer (Recommended)

1. Double-click the `direct_package.bat` file
2. Wait for the packaging process to complete
3. Navigate to the `installers` folder
4. Extract the `VideoProcessor_Windows_Latest.zip` file to your desired location
5. Run `run_app.bat` to start the application

### Option 2: Manual Installation

1. Extract the `VideoProcessor_Windows_Latest.zip` file to your desired location
2. Open a Command Prompt in the extracted directory
3. Run `pip install -r requirements.txt` to install dependencies
4. Run `python main.py` to start the application

## macOS Installation

### Option 1: Using the Direct Packaging Script

1. Open Terminal
2. Navigate to the VideoPackagingFast directory
3. Run `chmod +x direct_package.sh` to make the script executable
4. Run `./direct_package.sh`
5. Navigate to the `installers` folder
6. Extract the `VideoProcessor_macOS_Latest.zip` file to your desired location
7. Run `chmod +x run_app.sh` to make the startup script executable
8. Run `./run_app.sh` to start the application

### Option 2: Manual Installation

1. Extract the `VideoProcessor_macOS_Latest.zip` file to your desired location
2. Open Terminal in the extracted directory
3. Run `pip3 install -r requirements.txt` to install dependencies
4. Run `python3 main.py` to start the application

## Troubleshooting

### Common Issues

1. **Python not found**: Ensure Python is installed and added to your system PATH
2. **Missing dependencies**: Run `pip install -r requirements.txt` (Windows) or `pip3 install -r requirements.txt` (macOS)
3. **Permission issues**: On macOS, ensure scripts are executable with `chmod +x script_name.sh`
4. **FFmpeg errors**: Ensure the `ffmpeg_bin` directory is included in your installation

### File Access Issues During Packaging

If you encounter file access issues during the packaging process:

1. Close any running instances of the application
2. Close any file explorers or terminals that might be accessing files in the application directory
3. Run the packaging script again

If issues persist, check the `PACKAGING_ISSUE_*.md` file in the `installers` directory for detailed instructions.

## Configuration

1. Create a `config.json` file with your API keys (see `config.json.example` for format)
2. Place your media files in the appropriate directories as specified in the application

## Support

For additional support, please refer to the project's GitHub repository or contact the development team.
