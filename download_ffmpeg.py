"""
Download FFmpeg for packaging with the VideoProcessor executable.
This script downloads the appropriate FFmpeg binary for the current platform
and places it in the ffmpeg_bin directory for PyInstaller to include.
"""
import os
import sys
import platform
import requests
import zipfile
import shutil
import tempfile
from tqdm import tqdm

def download_file(url, destination):
    """Download a file with progress bar"""
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    block_size = 1024  # 1 Kibibyte
    
    with open(destination, 'wb') as file, tqdm(
            desc=f"Downloading {os.path.basename(destination)}",
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
        for data in response.iter_content(block_size):
            size = file.write(data)
            bar.update(size)

def download_ffmpeg_windows():
    """Download FFmpeg for Windows"""
    # FFmpeg Windows build from gyan.dev
    url = "https://github.com/GyanD/codexffmpeg/releases/download/6.0/ffmpeg-6.0-essentials_build.zip"
    
    temp_dir = tempfile.mkdtemp()
    zip_path = os.path.join(temp_dir, "ffmpeg.zip")
    
    try:
        print("Downloading FFmpeg for Windows...")
        download_file(url, zip_path)
        
        print("Extracting FFmpeg...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Find the bin directory in the extracted files
        ffmpeg_dir = None
        for root, dirs, files in os.walk(temp_dir):
            if "bin" in dirs:
                ffmpeg_dir = os.path.join(root, "bin")
                break
        
        if not ffmpeg_dir:
            print("Error: Could not find FFmpeg bin directory in the downloaded package")
            return False
        
        # Create ffmpeg_bin directory if it doesn't exist
        os.makedirs("ffmpeg_bin", exist_ok=True)
        
        # Copy ffmpeg.exe to our directory
        shutil.copy2(os.path.join(ffmpeg_dir, "ffmpeg.exe"), "ffmpeg_bin/ffmpeg.exe")
        print("FFmpeg successfully downloaded and extracted to ffmpeg_bin/ffmpeg.exe")
        return True
    
    except Exception as e:
        print(f"Error downloading FFmpeg: {e}")
        return False
    
    finally:
        # Clean up temporary directory
        shutil.rmtree(temp_dir, ignore_errors=True)

def download_ffmpeg_mac():
    """Download FFmpeg for macOS"""
    # FFmpeg macOS build
    url = "https://evermeet.cx/ffmpeg/getrelease/zip"
    
    temp_dir = tempfile.mkdtemp()
    zip_path = os.path.join(temp_dir, "ffmpeg.zip")
    
    try:
        print("Downloading FFmpeg for macOS...")
        download_file(url, zip_path)
        
        print("Extracting FFmpeg...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Create ffmpeg_bin directory if it doesn't exist
        os.makedirs("ffmpeg_bin", exist_ok=True)
        
        # Find the ffmpeg binary in the extracted files
        ffmpeg_path = None
        for root, dirs, files in os.walk(temp_dir):
            if "ffmpeg" in files:
                ffmpeg_path = os.path.join(root, "ffmpeg")
                break
        
        if not ffmpeg_path:
            print("Error: Could not find FFmpeg binary in the downloaded package")
            return False
        
        # Copy ffmpeg to our directory
        shutil.copy2(ffmpeg_path, "ffmpeg_bin/ffmpeg")
        # Make it executable
        os.chmod("ffmpeg_bin/ffmpeg", 0o755)
        print("FFmpeg successfully downloaded and extracted to ffmpeg_bin/ffmpeg")
        return True
    
    except Exception as e:
        print(f"Error downloading FFmpeg: {e}")
        return False
    
    finally:
        # Clean up temporary directory
        shutil.rmtree(temp_dir, ignore_errors=True)

def main():
    """Main function to download FFmpeg for the current platform"""
    system = platform.system()
    
    if system == "Windows":
        success = download_ffmpeg_windows()
    elif system == "Darwin":  # macOS
        success = download_ffmpeg_mac()
    else:
        print(f"Unsupported platform: {system}")
        return 1
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
