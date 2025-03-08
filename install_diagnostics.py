#!/usr/bin/env python
"""
VideoPackagingFast - Installation Diagnostics Tool
This script analyzes installation logs and provides troubleshooting suggestions
"""

import os
import sys
import re
import argparse
from datetime import datetime

# Common error patterns and their solutions
ERROR_PATTERNS = {
    r"pip.*SSL.*certificate": {
        "description": "SSL Certificate Verification Error",
        "solution": "Try adding the --trusted-host flag to pip commands or update your certificates"
    },
    r"pip.*timeout": {
        "description": "Network Timeout Error",
        "solution": "Check your internet connection or try using a different network"
    },
    r"PySimpleGUI.*not found": {
        "description": "PySimpleGUI Installation Error",
        "solution": "Try running install_pysimplegui_5_0_0_16.py manually"
    },
    r"FFmpeg.*not found": {
        "description": "FFmpeg Download Error",
        "solution": "Download FFmpeg manually and place it in the ffmpeg_bin directory"
    },
    r"Python.*not found": {
        "description": "Python Installation Error",
        "solution": "Install Python 3.9 or later manually and ensure it's in your PATH"
    },
    r"ImportError: No module named": {
        "description": "Missing Python Module",
        "solution": "Try reinstalling the required packages with pip install -r requirements.txt"
    },
    r"PermissionError|Access is denied": {
        "description": "Permission Error",
        "solution": "Run the installer as administrator or check folder permissions"
    },
    r"disk space|no space": {
        "description": "Insufficient Disk Space",
        "solution": "Free up disk space and try again"
    },
    r"pyinstaller.*error": {
        "description": "PyInstaller Error",
        "solution": "Try using a different PyInstaller version or check for conflicting packages"
    },
    r"UnicodeDecodeError|UnicodeEncodeError": {
        "description": "Unicode Error",
        "solution": "Check for non-ASCII characters in your code or environment variables"
    }
}

def analyze_log(log_file):
    """Analyze an installation log file and print diagnostic information"""
    if not os.path.exists(log_file):
        print(f"Error: Log file '{log_file}' not found")
        return False
    
    print(f"\n=== Analyzing log file: {log_file} ===\n")
    
    try:
        with open(log_file, 'r', encoding='utf-8', errors='replace') as f:
            log_content = f.read()
    except Exception as e:
        print(f"Error reading log file: {e}")
        return False
    
    # Extract basic information
    lines = log_content.splitlines()
    start_time_match = re.search(r"Installation started at (.+)", log_content)
    start_time = start_time_match.group(1) if start_time_match else "Unknown"
    
    # Count warnings and errors
    warnings = len(re.findall(r"\[WARNING\]", log_content))
    errors = len(re.findall(r"\[ERROR\]", log_content))
    
    print(f"Installation started: {start_time}")
    print(f"Log contains: {warnings} warnings, {errors} errors")
    
    # Check for successful completion
    if "Installation completed successfully" in log_content:
        print("\n✅ Installation completed successfully")
        if errors > 0 or warnings > 0:
            print("   (But there were some warnings or errors during the process)")
    else:
        print("\n❌ Installation did not complete successfully")
    
    # Find errors and their context
    if errors > 0:
        print("\n=== Critical Errors ===")
        error_lines = [i for i, line in enumerate(lines) if "[ERROR]" in line]
        
        for line_num in error_lines:
            # Get context (3 lines before and after)
            start = max(0, line_num - 3)
            end = min(len(lines), line_num + 4)
            
            print(f"\nError context (lines {start+1}-{end}):")
            for i in range(start, end):
                prefix = "→ " if i == line_num else "  "
                print(f"{prefix}{lines[i]}")
    
    # Check for known error patterns
    print("\n=== Diagnostic Analysis ===")
    found_patterns = False
    
    for pattern, info in ERROR_PATTERNS.items():
        if re.search(pattern, log_content, re.IGNORECASE):
            found_patterns = True
            print(f"\nDetected: {info['description']}")
            print(f"Suggested solution: {info['solution']}")
    
    if not found_patterns:
        if errors > 0:
            print("\nNo specific error pattern recognized. Please review the full log file.")
        else:
            print("\nNo significant issues detected in the log.")
    
    # Check for system-related issues
    system_info_match = re.search(r"===== SYSTEM INFORMATION =====(.+?)===== END SYSTEM INFORMATION =====", 
                                 log_content, re.DOTALL)
    
    if system_info_match:
        system_info = system_info_match.group(1)
        
        # Check RAM
        ram_match = re.search(r"FreePhysicalMemory=(\d+)", system_info)
        if ram_match:
            free_ram_kb = int(ram_match.group(1))
            if free_ram_kb < 1000000:  # Less than ~1GB free
                print("\n⚠️ Low available RAM detected. This might affect build performance.")
        
        # Check disk space
        disk_match = re.search(r"FreeSpace=(\d+)", system_info)
        if disk_match:
            free_space_bytes = int(disk_match.group(1))
            if free_space_bytes < 2000000000:  # Less than ~2GB free
                print("\n⚠️ Low disk space detected. At least 2GB free space is recommended.")
        
        # Check internet connectivity
        if "Request timed out" in system_info or "Destination host unreachable" in system_info:
            print("\n⚠️ Internet connectivity issues detected. This may affect downloading dependencies.")
    
    print("\n=== End of Analysis ===\n")
    return True

def main():
    parser = argparse.ArgumentParser(description="Analyze VideoPackagingFast installation logs")
    parser.add_argument("log_file", nargs="?", help="Path to the log file to analyze")
    args = parser.parse_args()
    
    # If no log file specified, find the most recent one
    if not args.log_file:
        log_files = [f for f in os.listdir('.') if f.startswith('install_log_') and f.endswith('.txt')]
        if not log_files:
            print("No installation log files found in the current directory")
            return 1
        
        # Sort by modification time (most recent first)
        log_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        log_file = log_files[0]
        print(f"Analyzing most recent log file: {log_file}")
    else:
        log_file = args.log_file
    
    if not analyze_log(log_file):
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
