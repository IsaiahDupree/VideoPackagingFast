#!/bin/bash
# VideoPackagingFast - Direct Packaging Tool for macOS
# This script creates a ZIP package of the application without using PyInstaller

# Print header
echo "==================================================="
echo "VideoPackagingFast - Direct Packaging Tool (macOS)"
echo "==================================================="
echo ""

# Check for PowerShell Core (pwsh)
if command -v pwsh &> /dev/null; then
    echo "PowerShell Core found, using it for packaging..."
    pwsh -ExecutionPolicy Bypass -File "direct_package.ps1"
else
    # PowerShell Core not found, use native shell script implementation
    echo "PowerShell Core not found, using native shell script implementation..."
    
    # Setup variables
    timestamp=$(date +"%Y%m%d_%H%M%S")
    log_dir="build_logs"
    output_dir="installers"
    log_file="${log_dir}/package_log_${timestamp}.txt"
    
    # Create directories
    mkdir -p "$log_dir"
    mkdir -p "$output_dir"
    
    # Function to log messages
    log_message() {
        local message="$1"
        local is_error="$2"
        
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        log_entry="[${timestamp}] ${message}"
        
        if [ "$is_error" = "true" ]; then
            echo -e "\033[0;31m${log_entry}\033[0m"  # Red text
        else
            echo "$log_entry"
        fi
        
        echo "$log_entry" >> "$log_file"
    }
    
    # Log header
    log_message "======================================================"
    log_message "VideoPackagingFast Direct Packaging Tool (macOS)"
    log_message "======================================================"
    log_message "Packaging started at $(date)"
    log_message "OS: $(uname -a)"
    log_message "======================================================"
    
    # Main packaging process
    {
        # Check for Python
        log_message "Checking for Python..."
        
        if command -v python3 &> /dev/null; then
            python_command="python3"
            python_version=$(python3 --version)
            log_message "Found Python: $python_version"
        else
            log_message "Python3 not found in system PATH" "true"
            log_message "Please install Python 3.9 or higher before continuing" "true"
            exit 1
        fi
        
        # Create a temporary directory for packaging
        package_dir="package_${timestamp}"
        mkdir -p "$package_dir"
        log_message "Created temporary packaging directory: $package_dir"
        
        # Copy Python scripts
        log_message "Copying Python scripts..."
        cp *.py "$package_dir/" 2>/dev/null || log_message "No Python scripts found" "true"
        
        # Copy JSON configuration files
        log_message "Copying configuration files..."
        cp *.json "$package_dir/" 2>/dev/null || log_message "No JSON configuration files found"
        
        # Copy resources directory if it exists
        if [ -d "resources" ]; then
            log_message "Copying resources directory..."
            cp -R resources "$package_dir/"
        fi
        
        # Copy ffmpeg binaries if they exist
        if [ -d "ffmpeg_bin" ]; then
            log_message "Copying FFmpeg binaries..."
            
            # Try to copy the entire directory
            if cp -R ffmpeg_bin "$package_dir/" 2>/dev/null; then
                log_message "Successfully copied FFmpeg binaries"
            else
                log_message "Warning: Could not copy FFmpeg binaries directly due to file access issues" "true"
                log_message "Attempting to copy individual files..."
                
                # Create the directory
                mkdir -p "$package_dir/ffmpeg_bin"
                
                # Try to copy individual files
                for file in ffmpeg_bin/*; do
                    if cp "$file" "$package_dir/ffmpeg_bin/" 2>/dev/null; then
                        log_message "Successfully copied $(basename "$file")"
                    else
                        log_message "Warning: Could not copy $(basename "$file") - it may be in use" "true"
                    fi
                done
            fi
        fi
        
        # Create a requirements.txt file
        log_message "Creating requirements.txt file..."
        $python_command -m pip freeze > "$package_dir/requirements.txt" 2>/dev/null || {
            # Create a basic requirements file if pip freeze fails
            cat > "$package_dir/requirements.txt" << EOF
pillow
pysimplegui
openai
anthropic
moviepy
pydub
EOF
            log_message "Created basic requirements.txt file"
        }
        
        # Create a README file
        log_message "Creating README file..."
        cat > "$package_dir/README.md" << EOF
# VideoPackagingFast

A cross-platform application for video processing and packaging.

## Installation

1. Install Python 3.9 or higher
2. Install required packages: \`pip install -r requirements.txt\`
3. Run the application: \`python main.py\`

## FFmpeg

This application requires FFmpeg. The binaries are included in the ffmpeg_bin directory.

## Configuration

1. Create a config.json file with your API keys (see config.json.example)
2. Place your media files in the appropriate directories

## License

MIT License
EOF
        
        # Create a simple shell script to run the application on macOS
        log_message "Creating macOS startup script..."
        cat > "$package_dir/run_app.sh" << EOF
#!/bin/bash
echo "Starting VideoPackagingFast..."
python3 main.py
EOF
        chmod +x "$package_dir/run_app.sh"
        
        # Create ZIP package
        log_message "Creating ZIP package..."
        
        zip_name="VideoProcessor_macOS_${timestamp}.zip"
        zip_path="${output_dir}/${zip_name}"
        
        if (cd "$package_dir" && zip -r "../$zip_path" .); then
            log_message "ZIP package created successfully: $zip_path"
            
            # Create a simplified named copy for easier access
            simplified_zip_path="${output_dir}/VideoProcessor_macOS_Latest.zip"
            cp "$zip_path" "$simplified_zip_path"
            log_message "Created simplified named copy: $simplified_zip_path"
        else
            log_message "Warning: Could not create ZIP package due to file access issues" "true"
            
            # Create a note file explaining the issue
            note_path="${output_dir}/PACKAGING_ISSUE_${timestamp}.md"
            cat > "$note_path" << EOF
# Important Note - Package Creation Issue

The packaging script encountered file access issues when trying to create the ZIP package.
This is likely because some files are currently in use by other processes.

## How to resolve this issue:

1. Close any running instances of the application
2. Close any file explorers or terminals that might be accessing files in the application directory
3. Run the packaging script again

If the issue persists, you can manually create a ZIP package by:
1. Copying all files from the '$package_dir' directory to a new location
2. Creating a ZIP archive from that location
EOF
            
            log_message "Created a note file with instructions: $note_path"
            
            # We'll consider this a partial success
            log_message "Packaging completed with warnings. Manual steps may be required."
            echo ""
            echo "====================================================="
            echo "Packaging completed with warnings!"
            echo "Some files could not be included in the package due to file access issues."
            echo "Please check the note file for instructions: $note_path"
            echo "====================================================="
        fi
        
        # Clean up temporary directory
        log_message "Cleaning up temporary directory..."
        rm -rf "$package_dir"
        
        # Success message
        log_message "Packaging completed successfully!"
        echo ""
        echo "====================================================="
        echo "Packaging completed successfully!"
        echo "The application package is located at:"
        echo "  $zip_path"
        echo "  $simplified_zip_path (Latest version)"
        echo "====================================================="
        
    } || {
        # Error handling
        log_message "Packaging failed: $?" "true"
        echo ""
        echo "====================================================="
        echo "Packaging failed. Please check the log file: $log_file"
        echo "====================================================="
        exit 1
    }
fi

echo ""
echo "==================================================="
echo "Packaging process completed."
echo "==================================================="
echo ""
echo "Press Enter to continue..."
read
