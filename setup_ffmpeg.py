"""
FFmpeg Setup Script for VideoPackagingFast

This script downloads and sets up FFmpeg for the VideoPackagingFast application.
It handles platform-specific downloads and ensures FFmpeg is available for the application.
"""
import os
import sys
import platform
import subprocess
import zipfile
import shutil
import tempfile
import requests
from tqdm import tqdm
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# URLs for FFmpeg downloads
FFMPEG_URLS = {
    'windows': 'https://github.com/GyanD/codexffmpeg/releases/download/6.0/ffmpeg-6.0-essentials_build.zip',
    'darwin': 'https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip',  # macOS
    'linux': 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz'
}

def get_platform():
    """Get the current platform."""
    system = platform.system().lower()
    if system == 'darwin':
        return 'darwin'
    elif system == 'windows':
        return 'windows'
    elif system == 'linux':
        return 'linux'
    else:
        raise ValueError(f"Unsupported platform: {system}")

def download_file(url, destination):
    """Download a file with progress bar."""
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        block_size = 1024  # 1 Kibibyte
        
        logger.info(f"Downloading from {url}")
        
        with open(destination, 'wb') as file, tqdm(
                desc="Downloading",
                total=total_size,
                unit='iB',
                unit_scale=True,
                unit_divisor=1024,
        ) as bar:
            for data in response.iter_content(block_size):
                size = file.write(data)
                bar.update(size)
                
        logger.info(f"Download completed: {destination}")
        return True
    except Exception as e:
        logger.error(f"Error downloading file: {str(e)}")
        return False

def extract_zip(zip_path, extract_to):
    """Extract a zip file."""
    try:
        logger.info(f"Extracting {zip_path} to {extract_to}")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # Get the common prefix of all files in the zip
            all_files = zip_ref.namelist()
            common_prefix = os.path.commonprefix(all_files)
            
            # Extract all files
            zip_ref.extractall(extract_to)
        
        logger.info("Extraction completed")
        
        # Return the path to the extracted directory
        if common_prefix and common_prefix.endswith('/'):
            return os.path.join(extract_to, common_prefix.rstrip('/'))
        return extract_to
    except Exception as e:
        logger.error(f"Error extracting zip: {str(e)}")
        return None

def extract_tar(tar_path, extract_to):
    """Extract a tar.xz file."""
    try:
        logger.info(f"Extracting {tar_path} to {extract_to}")
        
        # Use tar command for extraction
        subprocess.run(['tar', '-xf', tar_path, '-C', extract_to], check=True)
        
        logger.info("Extraction completed")
        
        # Find the extracted directory (usually a single directory)
        extracted_dirs = [d for d in os.listdir(extract_to) if os.path.isdir(os.path.join(extract_to, d))]
        if extracted_dirs:
            return os.path.join(extract_to, extracted_dirs[0])
        return extract_to
    except Exception as e:
        logger.error(f"Error extracting tar: {str(e)}")
        return None

def setup_ffmpeg():
    """Download and set up FFmpeg."""
    try:
        platform_name = get_platform()
        ffmpeg_url = FFMPEG_URLS.get(platform_name)
        
        if not ffmpeg_url:
            logger.error(f"No FFmpeg URL defined for platform: {platform_name}")
            return False
        
        # Create directories
        temp_dir = tempfile.mkdtemp()
        ffmpeg_bin_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ffmpeg_bin')
        os.makedirs(ffmpeg_bin_dir, exist_ok=True)
        
        # Download FFmpeg
        if platform_name == 'windows':
            download_path = os.path.join(temp_dir, 'ffmpeg.zip')
            if not download_file(ffmpeg_url, download_path):
                return False
            
            # Extract FFmpeg
            extracted_dir = extract_zip(download_path, temp_dir)
            if not extracted_dir:
                return False
            
            # Find the bin directory
            bin_dir = None
            for root, dirs, files in os.walk(extracted_dir):
                if 'ffmpeg.exe' in files:
                    bin_dir = root
                    break
            
            if not bin_dir:
                logger.error("Could not find ffmpeg.exe in the extracted files")
                return False
            
            # Copy FFmpeg binaries
            for file in ['ffmpeg.exe', 'ffprobe.exe', 'ffplay.exe']:
                file_path = os.path.join(bin_dir, file)
                if os.path.exists(file_path):
                    shutil.copy2(file_path, ffmpeg_bin_dir)
                    logger.info(f"Copied {file} to {ffmpeg_bin_dir}")
                else:
                    logger.warning(f"File not found: {file_path}")
        
        elif platform_name == 'darwin':
            download_path = os.path.join(temp_dir, 'ffmpeg.zip')
            if not download_file(ffmpeg_url, download_path):
                return False
            
            # Extract FFmpeg
            extracted_dir = extract_zip(download_path, temp_dir)
            if not extracted_dir:
                return False
            
            # Find the ffmpeg binary
            ffmpeg_path = None
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    if file == 'ffmpeg':
                        ffmpeg_path = os.path.join(root, file)
                        break
            
            if not ffmpeg_path:
                logger.error("Could not find ffmpeg binary in the extracted files")
                return False
            
            # Copy FFmpeg binary
            shutil.copy2(ffmpeg_path, os.path.join(ffmpeg_bin_dir, 'ffmpeg'))
            os.chmod(os.path.join(ffmpeg_bin_dir, 'ffmpeg'), 0o755)  # Make executable
            logger.info(f"Copied ffmpeg to {ffmpeg_bin_dir}")
            
            # Try to download ffprobe separately
            ffprobe_url = 'https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip'
            ffprobe_path = os.path.join(temp_dir, 'ffprobe.zip')
            if download_file(ffprobe_url, ffprobe_path):
                extract_zip(ffprobe_path, temp_dir)
                for root, dirs, files in os.walk(temp_dir):
                    for file in files:
                        if file == 'ffprobe':
                            shutil.copy2(os.path.join(root, file), os.path.join(ffmpeg_bin_dir, 'ffprobe'))
                            os.chmod(os.path.join(ffmpeg_bin_dir, 'ffprobe'), 0o755)  # Make executable
                            logger.info(f"Copied ffprobe to {ffmpeg_bin_dir}")
                            break
        
        elif platform_name == 'linux':
            download_path = os.path.join(temp_dir, 'ffmpeg.tar.xz')
            if not download_file(ffmpeg_url, download_path):
                return False
            
            # Extract FFmpeg
            extracted_dir = extract_tar(download_path, temp_dir)
            if not extracted_dir:
                return False
            
            # Copy FFmpeg binaries
            for file in ['ffmpeg', 'ffprobe']:
                file_path = os.path.join(extracted_dir, file)
                if os.path.exists(file_path):
                    shutil.copy2(file_path, ffmpeg_bin_dir)
                    os.chmod(os.path.join(ffmpeg_bin_dir, file), 0o755)  # Make executable
                    logger.info(f"Copied {file} to {ffmpeg_bin_dir}")
                else:
                    logger.warning(f"File not found: {file_path}")
        
        # Clean up
        try:
            shutil.rmtree(temp_dir)
            logger.info("Cleaned up temporary files")
        except Exception as e:
            logger.warning(f"Error cleaning up temporary files: {str(e)}")
        
        return True
    
    except Exception as e:
        logger.error(f"Error setting up FFmpeg: {str(e)}")
        return False

def ensure_ffmpeg_in_path():
    """Ensure FFmpeg is in the system PATH."""
    try:
        # Try to run ffmpeg
        result = subprocess.run(['ffmpeg', '-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            logger.info("FFmpeg is already in the system PATH")
            return True
        
        logger.info("FFmpeg not found in system PATH, checking local installation")
        
        # Check if we have a local installation
        ffmpeg_bin_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ffmpeg_bin')
        if not os.path.exists(ffmpeg_bin_dir):
            logger.info("Local FFmpeg installation not found, setting up FFmpeg")
            if not setup_ffmpeg():
                return False
        
        # Add FFmpeg to PATH for this session
        os.environ['PATH'] = os.pathsep.join([ffmpeg_bin_dir, os.environ.get('PATH', '')])
        
        # Verify FFmpeg is now available
        result = subprocess.run(['ffmpeg', '-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            logger.info("FFmpeg is now available in the PATH")
            return True
        else:
            logger.error("FFmpeg is still not available after setup")
            return False
    
    except Exception as e:
        logger.error(f"Error ensuring FFmpeg in PATH: {str(e)}")
        return False

def create_assets_directory():
    """Create the assets directory if it doesn't exist."""
    try:
        assets_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets')
        os.makedirs(assets_dir, exist_ok=True)
        logger.info(f"Created assets directory: {assets_dir}")
        return True
    except Exception as e:
        logger.error(f"Error creating assets directory: {str(e)}")
        return False

if __name__ == "__main__":
    print("Setting up FFmpeg for VideoPackagingFast...")
    if ensure_ffmpeg_in_path():
        print("FFmpeg setup completed successfully!")
    else:
        print("FFmpeg setup failed. Please install FFmpeg manually.")
        sys.exit(1)
    
    print("Creating assets directory...")
    if create_assets_directory():
        print("Assets directory created successfully!")
    else:
        print("Failed to create assets directory.")
        sys.exit(1)
    
    print("Setup completed successfully!")
