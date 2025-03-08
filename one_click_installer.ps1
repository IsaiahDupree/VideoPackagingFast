# VideoPackagingFast - One-Click Installer Builder
# This script builds the VideoPackagingFast application with minimal dependencies
# and creates a ZIP package for easy distribution

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
Write-Log "VideoPackagingFast One-Click Installer Builder"
Write-Log "======================================================"
Write-Log "Build started at $(Get-Date)"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Log "PowerShell: $($PSVersionTable.PSVersion)"
Write-Log "======================================================"

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
            "C:\Python311\python.exe"
        )
        
        # Add user-specific paths
        if ($env:USERNAME) {
            $commonPaths += "C:\Users\$($env:USERNAME)\AppData\Local\Programs\Python\Python39\python.exe"
            $commonPaths += "C:\Users\$($env:USERNAME)\AppData\Local\Programs\Python\Python310\python.exe"
            $commonPaths += "C:\Users\$($env:USERNAME)\AppData\Local\Programs\Python\Python311\python.exe"
        }
        
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
    
    # Skip cleaning previous build artifacts to avoid permission issues
    Write-Log "Skipping cleanup of previous build artifacts to avoid permission issues..."
    
    # Create a unique build directory to avoid conflicts
    $buildDir = "build_$timestamp"
    New-Item -Path $buildDir -ItemType Directory | Out-Null
    Write-Log "Created unique build directory: $buildDir"
    
    # Create spec file
    Write-Log "Creating PyInstaller spec file..."
    
    $specFile = "VideoProcessor_$timestamp.spec"
    
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
    
    Set-Content -Path $specFile -Value $specContent
    Write-Log "Spec file created successfully: $specFile"
    
    # Build with PyInstaller
    Write-Log "Building application with PyInstaller..."
    
    try {
        # Install PyInstaller if needed
        & $pythonCommand -m pip install --upgrade pip
        & $pythonCommand -m pip install pyinstaller pillow pysimplegui openai anthropic moviepy pydub
        
        # Run PyInstaller with workpath and distpath set to our unique directories
        $distDir = "dist_$timestamp"
        New-Item -Path $distDir -ItemType Directory | Out-Null
        
        & $pythonCommand -m PyInstaller --workpath $buildDir --distpath $distDir --clean $specFile
        
        if (-not (Test-Path $distDir)) {
            throw "PyInstaller failed to create dist directory"
        }
        
        Write-Log "PyInstaller build completed successfully"
        
        # Check if VideoProcessor directory exists in the dist directory
        $appDir = Join-Path $distDir "VideoProcessor"
        if (-not (Test-Path $appDir)) {
            Write-Log "VideoProcessor directory not found in $distDir, checking for alternative output structure..."
            
            # Check if PyInstaller created a different output structure
            $possibleAppDirs = Get-ChildItem -Path $distDir -Directory
            if ($possibleAppDirs.Count -gt 0) {
                $appDir = $possibleAppDirs[0].FullName
                Write-Log "Found alternative output directory: $appDir"
            } else {
                # If no subdirectories, use the dist directory itself
                $appDir = $distDir
                Write-Log "Using dist directory directly: $appDir"
            }
        }
        
        # Create ZIP package directly from the build output
        Write-Log "Creating ZIP package..."
        
        $zipName = "VideoProcessor_Windows_$timestamp.zip"
        $zipPath = Join-Path $outputDir $zipName
        
        # Check if there are files to compress
        $filesToCompress = Get-ChildItem -Path $appDir -Recurse
        if ($filesToCompress.Count -eq 0) {
            Write-Log "Warning: No files found in output directory to compress" -IsError
            
            # Fall back to direct copy of the executable if it exists
            $exePath = Join-Path $distDir "VideoProcessor.exe"
            if (Test-Path $exePath) {
                Write-Log "Found executable, creating ZIP with just the executable..."
                Compress-Archive -Path $exePath -DestinationPath $zipPath
            } else {
                throw "No files found to package"
            }
        } else {
            Write-Log "Found $($filesToCompress.Count) files/directories to compress"
            Compress-Archive -Path "$appDir\*" -DestinationPath $zipPath -Force
        }
        
        Write-Log "ZIP package created successfully: $zipPath"
        
        # Create a simplified named copy for easier access
        $simplifiedZipPath = Join-Path $outputDir "VideoProcessor_Windows_Latest.zip"
        Copy-Item -Path $zipPath -Destination $simplifiedZipPath -Force
        Write-Log "Created simplified named copy: $simplifiedZipPath"
        
        # Clean up temporary files
        Write-Log "Cleaning up temporary files..."
        Remove-Item -Path $specFile -Force -ErrorAction SilentlyContinue
        
        # Try to clean up build directories but don't fail if we can't
        try {
            Remove-Item -Path $buildDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $distDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Log "Note: Could not remove temporary directories. They can be manually deleted later."
        }
        
        # Success message
        Write-Log "Build completed successfully!"
        Write-Host ""
        Write-Host "=====================================================" -ForegroundColor Green
        Write-Host "Build completed successfully!" -ForegroundColor Green
        Write-Host "The application package is located at:" -ForegroundColor Green
        Write-Host "  $zipPath" -ForegroundColor Green
        Write-Host "  $simplifiedZipPath (Latest version)" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Green
        
    } catch {
        Write-Log "PyInstaller build failed: $_" -IsError
        throw "PyInstaller build failed: $_"
    }
    
} catch {
    # Error handling
    Write-Log "Build failed: $_" -IsError
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host "Build failed. Please check the log file: $logFile" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    exit 1
}

# Wait for user input
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
