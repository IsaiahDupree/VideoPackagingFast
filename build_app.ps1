# VideoPackagingFast - Simple Cross-Platform Build Script
# This script builds the VideoPackagingFast application with minimal dependencies

# Setup variables
$logDir = "build_logs"
$outputDir = "installers"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "build_log_$timestamp.txt"

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
Write-Log "VideoPackagingFast Builder"
Write-Log "======================================================"
Write-Log "Build started at $(Get-Date)"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"
Write-Log "======================================================"

# Function to remove directory
function Remove-DirectoryContents {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        Write-Log "Cleaning directory: $Path"
        
        try {
            Remove-Item -Path $Path -Recurse -Force
            Write-Log "Successfully cleaned directory: $Path"
            return $true
        } catch {
            Write-Log "Warning: Could not clean directory: $Path. It may be in use."
            return $false
        }
    }
    
    return $true
}

# Main build process
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
    
    # Check common installation paths if still not found
    if (-not $pythonCommand) {
        $commonPaths = @(
            "C:\Python39\python.exe",
            "C:\Python310\python.exe",
            "C:\Python311\python.exe",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python39\python.exe",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python310\python.exe",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311\python.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $pythonCommand = $path
                Write-Log "Found Python at: $path"
                break
            }
        }
    }
    
    # Fail if Python not found
    if (-not $pythonCommand) {
        throw "Python not found. Please install Python 3.9+ and try again."
    }
    
    # Clean previous build artifacts
    Write-Log "Cleaning previous build artifacts..."
    
    Remove-DirectoryContents "build"
    Remove-DirectoryContents "dist"
    
    if (Test-Path "VideoProcessor.spec") {
        Remove-Item "VideoProcessor.spec" -Force -ErrorAction SilentlyContinue
    }
    
    # Wait a moment to ensure all files are released
    Start-Sleep -Seconds 2
    
    # Create spec file
    Write-Log "Creating PyInstaller spec file..."
    
    $specContent = @'
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('ai_prompts.json', '.'),
        ('config.json', '.'),
        ('resources', 'resources'),
        ('ffmpeg_bin', 'ffmpeg_bin'),
    ],
    hiddenimports=[
        'PIL._tkinter_finder',
        'PySimpleGUI',
        'tkinter',
        'tkinter.filedialog',
        'tkinter.constants',
        'openai',
        'anthropic',
        'moviepy',
        'pydub',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='VideoProcessor',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='VideoProcessor',
)
'@
    
    Set-Content -Path "VideoProcessor.spec" -Value $specContent
    Write-Log "Spec file created successfully"
    
    # Build with PyInstaller
    Write-Log "Building application with PyInstaller..."
    
    try {
        # Install PyInstaller if needed
        & $pythonCommand -m pip install pyinstaller
        
        # Run PyInstaller
        & $pythonCommand -m PyInstaller --clean VideoProcessor.spec
        
        if (-not (Test-Path "dist")) {
            throw "PyInstaller failed to create dist directory"
        }
        
        Write-Log "PyInstaller build completed successfully"
    } catch {
        Write-Log "PyInstaller build failed: $_" -IsError
        throw "PyInstaller build failed"
    }
    
    # Create ZIP package
    Write-Log "Creating ZIP package..."
    
    $zipName = "VideoProcessor_Windows.zip"
    $zipPath = Join-Path $outputDir $zipName
    
    try {
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        Compress-Archive -Path "dist\VideoProcessor\*" -DestinationPath $zipPath
        Write-Log "ZIP package created successfully: $zipPath"
    } catch {
        Write-Log "Failed to create ZIP package: $_" -IsError
        throw "Failed to create ZIP package"
    }
    
    # Success message
    Write-Log "Build completed successfully!"
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "The application package is located at: $zipPath" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    
} catch {
    # Error handling
    Write-Log "Build failed: $_" -IsError
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host "Build failed. Please check the log file: $logFile" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    exit 1
}

# Wait for user input
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
