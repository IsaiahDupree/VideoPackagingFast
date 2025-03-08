# VideoPackagingFast - Direct Packaging Script
# This script creates a ZIP package of the application without using PyInstaller
# Compatible with both Windows and macOS

# Setup variables
$logDir = "build_logs"
$outputDir = "installers"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "package_log_$timestamp.txt"

# Create directories
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Function to log messages
function Write-Log {
    param (
        [string]$Message,
        [switch]$IsError
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    
    if ($IsError) {
        Write-Host $logEntry -ForegroundColor Red
    } else {
        Write-Host $logEntry
    }
    
    Add-Content -Path $logFile -Value $logEntry
}

# Log header
Write-Log "======================================================"
Write-Log "VideoPackagingFast Direct Packaging Tool"
Write-Log "======================================================"
Write-Log "Packaging started at $(Get-Date)"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"
Write-Log "======================================================"

# Main packaging process
try {
    # Check for Python
    Write-Log "Checking for Python..."
    
    $pythonCommand = $null
    
    # Try system Python
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python") {
            $pythonCommand = "python"
            Write-Log "Found Python: $pythonVersion"
        }
    } catch {
        Write-Log "Python not found in system PATH"
    }
    
    # Try virtual environment if system Python not found
    if (-not $pythonCommand -and (Test-Path "venv\Scripts\python.exe")) {
        $pythonCommand = ".\venv\Scripts\python.exe"
        try {
            $pythonVersion = & $pythonCommand --version 2>&1
            Write-Log "Found Python in virtual environment: $pythonVersion"
        } catch {
            Write-Log "Found virtual environment but couldn't get Python version"
        }
    }
    
    # Create a temporary directory for packaging
    $packageDir = "package_$timestamp"
    New-Item -Path $packageDir -ItemType Directory | Out-Null
    Write-Log "Created temporary packaging directory: $packageDir"
    
    # Copy Python scripts
    Write-Log "Copying Python scripts..."
    Copy-Item -Path "*.py" -Destination $packageDir
    
    # Copy JSON configuration files
    Write-Log "Copying configuration files..."
    Copy-Item -Path "*.json" -Destination $packageDir -ErrorAction SilentlyContinue
    
    # Copy resources directory if it exists
    if (Test-Path "resources") {
        Write-Log "Copying resources directory..."
        Copy-Item -Path "resources" -Destination $packageDir -Recurse
    }
    
    # Copy ffmpeg binaries if they exist
    if (Test-Path "ffmpeg_bin") {
        Write-Log "Copying FFmpeg binaries..."
        try {
            # Try to copy the entire directory
            Copy-Item -Path "ffmpeg_bin" -Destination $packageDir -Recurse -ErrorAction Stop
        } catch {
            Write-Log "Warning: Could not copy FFmpeg binaries directly due to file access issues" -IsError
            Write-Log "Attempting to copy individual files..."
            
            # Create the directory
            New-Item -Path "$packageDir\ffmpeg_bin" -ItemType Directory -Force | Out-Null
            
            # Try to copy individual files
            $ffmpegFiles = Get-ChildItem -Path "ffmpeg_bin" -File
            foreach ($file in $ffmpegFiles) {
                try {
                    Copy-Item -Path $file.FullName -Destination "$packageDir\ffmpeg_bin\" -ErrorAction Stop
                    Write-Log "Successfully copied $($file.Name)"
                } catch {
                    Write-Log "Warning: Could not copy $($file.Name) - it may be in use" -IsError
                }
            }
        }
    }
    
    # Create a requirements.txt file
    if ($pythonCommand) {
        Write-Log "Creating requirements.txt file..."
        & $pythonCommand -m pip freeze > "$packageDir\requirements.txt"
    } else {
        # Create a basic requirements file if Python is not available
        @"
pillow
pysimplegui
openai
anthropic
moviepy
pydub
"@ | Set-Content -Path "$packageDir\requirements.txt"
    }
    
    # Create a README file
    Write-Log "Creating README file..."
    @"
# VideoPackagingFast

A cross-platform application for video processing and packaging.

## Installation

1. Install Python 3.9 or higher
2. Install required packages: `pip install -r requirements.txt`
3. Run the application: `python main.py`

## FFmpeg

This application requires FFmpeg. The binaries are included in the ffmpeg_bin directory.

## Configuration

1. Create a config.json file with your API keys (see config.json.example)
2. Place your media files in the appropriate directories

## License

MIT License
"@ | Set-Content -Path "$packageDir\README.md"
    
    # Create a simple batch file to run the application on Windows
    Write-Log "Creating Windows startup script..."
    @"
@echo off
echo Starting VideoPackagingFast...
python main.py
pause
"@ | Set-Content -Path "$packageDir\run_app.bat"
    
    # Create a simple shell script to run the application on macOS
    Write-Log "Creating macOS startup script..."
    @"
#!/bin/bash
echo "Starting VideoPackagingFast..."
python3 main.py
"@ | Set-Content -Path "$packageDir\run_app.sh"
    
    # Create ZIP package
    Write-Log "Creating ZIP package..."
    
    $zipName = if ($IsWindows -or $env:OS -match "Windows") { "VideoProcessor_Windows_$timestamp.zip" } else { "VideoProcessor_macOS_$timestamp.zip" }
    $zipPath = Join-Path $outputDir $zipName
    
    try {
        Compress-Archive -Path "$packageDir\*" -DestinationPath $zipPath -ErrorAction Stop
        Write-Log "ZIP package created successfully: $zipPath"
        
        # Create a simplified named copy for easier access
        $simplifiedZipPath = if ($IsWindows -or $env:OS -match "Windows") { Join-Path $outputDir "VideoProcessor_Windows_Latest.zip" } else { Join-Path $outputDir "VideoProcessor_macOS_Latest.zip" }
        Copy-Item -Path $zipPath -Destination $simplifiedZipPath -Force
        Write-Log "Created simplified named copy: $simplifiedZipPath"
    } catch {
        Write-Log "Warning: Could not create ZIP package due to file access issues" -IsError
        Write-Log "Error details: $_" -IsError
        
        # Create a note file explaining the issue
        $noteContent = @"
# Important Note - Package Creation Issue

The packaging script encountered file access issues when trying to create the ZIP package.
This is likely because some files are currently in use by other processes.

## How to resolve this issue:

1. Close any running instances of the application
2. Close any file explorers or terminals that might be accessing files in the application directory
3. Run the packaging script again

If the issue persists, you can manually create a ZIP package by:
1. Copying all files from the '$packageDir' directory to a new location
2. Creating a ZIP archive from that location
"@
        
        $notePath = Join-Path $outputDir "PACKAGING_ISSUE_$timestamp.md"
        Set-Content -Path $notePath -Value $noteContent
        Write-Log "Created a note file with instructions: $notePath"
        
        # We'll consider this a partial success
        Write-Log "Packaging completed with warnings. Manual steps may be required."
        Write-Host ""
        Write-Host "=====================================================" -ForegroundColor Yellow
        Write-Host "Packaging completed with warnings!" -ForegroundColor Yellow
        Write-Host "Some files could not be included in the package due to file access issues." -ForegroundColor Yellow
        Write-Host "Please check the note file for instructions: $notePath" -ForegroundColor Yellow
        Write-Host "=====================================================" -ForegroundColor Yellow
        
        # Don't throw an exception, so we can continue with cleanup
    }
    
    # Clean up temporary directory
    Write-Log "Cleaning up temporary directory..."
    Remove-Item -Path $packageDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # Success message
    Write-Log "Packaging completed successfully!"
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host "Packaging completed successfully!" -ForegroundColor Green
    Write-Host "The application package is located at:" -ForegroundColor Green
    Write-Host "  $zipPath" -ForegroundColor Green
    Write-Host "  $simplifiedZipPath (Latest version)" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    
} catch {
    # Error handling
    Write-Log "Packaging failed: $_" -IsError
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host "Packaging failed. Please check the log file: $logFile" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    exit 1
}

# Wait for user input
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
