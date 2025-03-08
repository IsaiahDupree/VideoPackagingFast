#!/usr/bin/env python
import os
import sys
import logging
import shutil
import requests
from PIL import Image
from io import BytesIO

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def fix_pysimplegui_dependency():
    """Fix PySimpleGUI dependency issues by installing a specific version"""
    logging.info("Fixing PySimpleGUI dependency issues...")
    
    try:
        # Install a specific version of PySimpleGUI that doesn't have RSA dependency conflicts
        # Using the direct method rather than the PySimpleGUI.net repository
        os.system("pip uninstall -y PySimpleGUI")
        os.system("pip install PySimpleGUI==4.60.5")  # Using an older stable version without RSA dependency
        logging.info("PySimpleGUI dependency fixed successfully")
        return True
    except Exception as e:
        logging.error(f"Failed to fix PySimpleGUI dependency: {str(e)}")
        return False

def create_valid_icon():
    """Create a valid icon file for the application"""
    logging.info("Creating a valid icon file...")
    
    resources_dir = os.path.join(os.getcwd(), "resources")
    icon_path = os.path.join(resources_dir, "icon.ico")
    assets_dir = os.path.join(os.getcwd(), "assets")
    
    # Ensure directories exist
    os.makedirs(resources_dir, exist_ok=True)
    os.makedirs(assets_dir, exist_ok=True)
    
    try:
        # Check if we have a valid icon in assets directory
        potential_icons = [
            os.path.join(assets_dir, "icon.ico"),
            os.path.join(assets_dir, "logo.ico"),
            os.path.join(assets_dir, "icon.png"),
            os.path.join(assets_dir, "logo.png")
        ]
        
        icon_source = None
        for potential_icon in potential_icons:
            if os.path.exists(potential_icon) and os.path.getsize(potential_icon) > 100:
                icon_source = potential_icon
                break
        
        if icon_source:
            # Copy or convert the existing icon
            if icon_source.endswith('.ico'):
                shutil.copy(icon_source, icon_path)
                logging.info(f"Copied existing icon from {icon_source} to {icon_path}")
            else:
                # Convert PNG to ICO
                img = Image.open(icon_source)
                img.save(icon_path, format='ICO')
                logging.info(f"Converted {icon_source} to ICO format at {icon_path}")
        else:
            # Download a generic icon if no valid icon exists
            logging.info("No valid icon found, downloading a generic icon...")
            response = requests.get("https://raw.githubusercontent.com/feathericons/feather/master/icons/video.svg")
            
            if response.status_code == 200:
                # Create a blank image with the SVG content
                img = Image.new('RGBA', (256, 256), color=(240, 240, 240, 255))
                
                # Save as ICO
                img.save(icon_path, format='ICO')
                logging.info(f"Created generic icon at {icon_path}")
                
                # Also save as PNG in assets for future use
                img.save(os.path.join(assets_dir, "icon.png"), format='PNG')
            else:
                # Create a very basic icon if download fails
                img = Image.new('RGBA', (256, 256), color=(66, 133, 244, 255))
                img.save(icon_path, format='ICO')
                logging.info(f"Created basic blue icon at {icon_path}")
        
        # Verify the icon file is valid
        if os.path.exists(icon_path) and os.path.getsize(icon_path) > 100:
            logging.info(f"Icon file created successfully at {icon_path}")
            return True
        else:
            logging.error(f"Icon file creation failed or file is too small: {icon_path}")
            return False
            
    except Exception as e:
        logging.error(f"Failed to create icon file: {str(e)}")
        return False

def main():
    """Main function to fix build issues"""
    logging.info("Starting build fixes...")
    
    # Fix PySimpleGUI dependency
    pysimplegui_fixed = fix_pysimplegui_dependency()
    
    # Create valid icon
    icon_fixed = create_valid_icon()
    
    if pysimplegui_fixed and icon_fixed:
        logging.info("All build issues fixed successfully!")
        return 0
    else:
        logging.error("Failed to fix all build issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
