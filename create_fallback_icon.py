#!/usr/bin/env python
import os
import sys
import logging
from PIL import Image, ImageDraw

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def create_fallback_icon():
    """Create a fallback icon file for the application"""
    logging.info("Creating fallback icon file...")
    
    resources_dir = os.path.join(os.getcwd(), "resources")
    fallback_icon_path = os.path.join(resources_dir, "fallback_icon.ico")
    
    # Ensure resources directory exists
    os.makedirs(resources_dir, exist_ok=True)
    
    try:
        # Create a simple icon - blue square with white "V" for Video
        img = Image.new('RGBA', (256, 256), color=(66, 133, 244, 255))
        draw = ImageDraw.Draw(img)
        
        # Draw a white "V" shape
        draw.polygon([(64, 64), (128, 192), (192, 64), (172, 64), (128, 148), (84, 64)], fill=(255, 255, 255))
        
        # Save as ICO
        img.save(fallback_icon_path, format='ICO')
        logging.info(f"Created fallback icon at {fallback_icon_path}")
        
        # Verify the icon file is valid
        if os.path.exists(fallback_icon_path) and os.path.getsize(fallback_icon_path) > 100:
            logging.info(f"Fallback icon file created successfully at {fallback_icon_path}")
            return True
        else:
            logging.error(f"Fallback icon file creation failed or file is too small: {fallback_icon_path}")
            return False
            
    except Exception as e:
        logging.error(f"Failed to create fallback icon file: {str(e)}")
        return False

if __name__ == "__main__":
    sys.exit(0 if create_fallback_icon() else 1)
