#!/usr/bin/env python
"""
Direct PySimpleGUI installer for version 5.0.0.16
This script downloads and installs PySimpleGUI 5.0.0.16 directly,
bypassing pip's dependency resolution which can cause issues.
"""
import os
import sys
import logging
import shutil
import tempfile
import subprocess
from pathlib import Path
import urllib.request
import zipfile
import importlib.util

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def is_module_installed(module_name):
    """Check if a module is installed"""
    return importlib.util.find_spec(module_name) is not None

def get_site_packages_dir():
    """Get the site-packages directory for the current Python environment"""
    try:
        import site
        return site.getsitepackages()[0]
    except Exception as e:
        logging.error(f"Failed to get site-packages directory: {str(e)}")
        # Fallback to a common pattern
        if hasattr(sys, 'real_prefix') or hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix:
            # We're in a virtual environment
            return os.path.join(sys.prefix, 'lib', f'python{sys.version_info.major}.{sys.version_info.minor}', 'site-packages')
        else:
            # We're in a system Python
            return os.path.join(sys.prefix, 'lib', f'python{sys.version_info.major}.{sys.version_info.minor}', 'site-packages')

def download_pysimplegui_5_0_0_16():
    """Download PySimpleGUI 5.0.0.16 source code"""
    logging.info("Downloading PySimpleGUI 5.0.0.16 source code...")
    
    # Try multiple URLs to ensure we can get the source
    urls = [
        "https://github.com/PySimpleGUI/PySimpleGUI/archive/refs/tags/5.0.0.16.zip",
        "https://github.com/PySimpleGUI/PySimpleGUI/archive/5.0.0.16.zip",
        "https://files.pythonhosted.org/packages/source/P/PySimpleGUI/PySimpleGUI-5.0.0.16.zip"
    ]
    
    temp_dir = tempfile.mkdtemp()
    zip_path = os.path.join(temp_dir, "PySimpleGUI-5.0.0.16.zip")
    
    for url in urls:
        try:
            # Download the zip file
            logging.info(f"Trying to download from {url}...")
            urllib.request.urlretrieve(url, zip_path)
            
            # If we get here, the download was successful
            logging.info(f"Successfully downloaded from {url}")
            break
        except Exception as e:
            logging.warning(f"Failed to download from {url}: {str(e)}")
            if url == urls[-1]:
                logging.error("All download attempts failed")
                return None
    
    try:
        # Extract the zip file
        logging.info("Extracting PySimpleGUI source code...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        
        # Find the extracted directory
        extracted_dir = None
        for item in os.listdir(temp_dir):
            if os.path.isdir(os.path.join(temp_dir, item)) and item.startswith("PySimpleGUI"):
                extracted_dir = os.path.join(temp_dir, item)
                break
        
        if not extracted_dir:
            logging.error("Could not find extracted PySimpleGUI directory")
            return None
        
        return extracted_dir
    
    except Exception as e:
        logging.error(f"Failed to extract PySimpleGUI: {str(e)}")
        return None

def install_pysimplegui_directly():
    """Install PySimpleGUI 5.0.0.16 directly by copying the module to site-packages"""
    logging.info("Installing PySimpleGUI 5.0.0.16 directly...")
    
    # First try to uninstall any existing PySimpleGUI
    try:
        if is_module_installed("PySimpleGUI"):
            logging.info("Uninstalling existing PySimpleGUI...")
            subprocess.run([sys.executable, "-m", "pip", "uninstall", "-y", "PySimpleGUI"], 
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except Exception as e:
        logging.warning(f"Failed to uninstall existing PySimpleGUI: {str(e)}")
    
    # Download PySimpleGUI source
    source_dir = download_pysimplegui_5_0_0_16()
    if not source_dir:
        logging.error("Failed to download PySimpleGUI source")
        return False
    
    try:
        # Find the PySimpleGUI.py file or package directory
        psg_file = os.path.join(source_dir, "PySimpleGUI", "PySimpleGUI.py")
        psg_package_dir = os.path.join(source_dir, "PySimpleGUI")
        
        if not os.path.exists(psg_file) and os.path.exists(psg_package_dir):
            # Look for PySimpleGUI.py in the package directory
            for item in os.listdir(psg_package_dir):
                if item.lower() == "pysimplegui.py":
                    psg_file = os.path.join(psg_package_dir, item)
                    break
        
        if not os.path.exists(psg_file):
            # Try alternative location
            psg_file = os.path.join(source_dir, "PySimpleGUI.py")
            
        if not os.path.exists(psg_file):
            logging.error("Could not find PySimpleGUI.py in the downloaded source")
            return False
        
        # Get site-packages directory
        site_packages = get_site_packages_dir()
        logging.info(f"Site-packages directory: {site_packages}")
        
        # Create PySimpleGUI directory in site-packages if it doesn't exist
        psg_dir = os.path.join(site_packages, "PySimpleGUI")
        os.makedirs(psg_dir, exist_ok=True)
        
        # Copy PySimpleGUI files to site-packages
        if os.path.exists(psg_package_dir) and os.path.isdir(psg_package_dir):
            # Package mode - copy all files from the package directory
            logging.info(f"Installing PySimpleGUI as a package from {psg_package_dir}")
            for item in os.listdir(psg_package_dir):
                src = os.path.join(psg_package_dir, item)
                dst = os.path.join(psg_dir, item)
                if os.path.isfile(src):
                    shutil.copy(src, dst)
            logging.info(f"Copied PySimpleGUI package to {psg_dir}")
        else:
            # Single file mode
            logging.info(f"Installing PySimpleGUI as a single file from {psg_file}")
            shutil.copy(psg_file, os.path.join(site_packages, "PySimpleGUI.py"))
            logging.info(f"Copied PySimpleGUI.py to {site_packages}")
            
            # Create __init__.py in site-packages/PySimpleGUI
            with open(os.path.join(psg_dir, "__init__.py"), "w") as f:
                f.write("from PySimpleGUI import *\n")
            logging.info(f"Created __init__.py in {psg_dir}")
        
        # Create .egg-info directory to make pip aware of the package
        egg_info_dir = os.path.join(site_packages, "PySimpleGUI-5.0.0.16.egg-info")
        os.makedirs(egg_info_dir, exist_ok=True)
        
        # Create minimal egg-info files
        with open(os.path.join(egg_info_dir, "PKG-INFO"), "w") as f:
            f.write("Metadata-Version: 2.1\n")
            f.write("Name: PySimpleGUI\n")
            f.write("Version: 5.0.0.16\n")
        
        with open(os.path.join(egg_info_dir, "SOURCES.txt"), "w") as f:
            f.write("PySimpleGUI.py\n")
        
        with open(os.path.join(egg_info_dir, "dependency_links.txt"), "w") as f:
            f.write("")
        
        with open(os.path.join(egg_info_dir, "top_level.txt"), "w") as f:
            f.write("PySimpleGUI\n")
        
        logging.info(f"Created egg-info at {egg_info_dir}")
        
        # Verify installation
        try:
            logging.info("Verifying installation...")
            spec = importlib.util.find_spec("PySimpleGUI")
            if spec:
                logging.info(f"PySimpleGUI installed successfully at {spec.origin}")
                return True
            else:
                logging.error("PySimpleGUI not found after installation")
                return False
        except Exception as e:
            logging.error(f"Error verifying installation: {str(e)}")
            return False
    
    except Exception as e:
        logging.error(f"Failed to install PySimpleGUI: {str(e)}")
        return False
    finally:
        # Clean up the temporary directory
        if source_dir and os.path.exists(os.path.dirname(source_dir)):
            try:
                shutil.rmtree(os.path.dirname(source_dir))
            except Exception as e:
                logging.warning(f"Failed to clean up temporary directory: {str(e)}")

def create_version_file():
    """Create a version file to indicate the installed version"""
    try:
        with open("pysimplegui_version.txt", "w") as f:
            f.write("5.0.0.16")
        logging.info("Created version file: pysimplegui_version.txt")
        return True
    except Exception as e:
        logging.error(f"Failed to create version file: {str(e)}")
        return False

def main():
    """Main function to install PySimpleGUI 5.0.0.16"""
    logging.info("Starting PySimpleGUI 5.0.0.16 installation...")
    
    # Try to install PySimpleGUI directly
    if install_pysimplegui_directly():
        logging.info("PySimpleGUI 5.0.0.16 installed successfully!")
        create_version_file()
        return 0
    
    # If direct installation failed, try pip as a fallback
    logging.warning("Direct installation failed, trying pip as fallback...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "PySimpleGUI==5.0.0.16"], 
                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        logging.info("PySimpleGUI 5.0.0.16 installed via pip!")
        create_version_file()
        return 0
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to install PySimpleGUI via pip: {e.stderr.decode() if hasattr(e, 'stderr') else str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
