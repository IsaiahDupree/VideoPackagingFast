"""
Fix Build Issues for VideoPackagingFast

This script addresses common build issues with PyInstaller, pydantic, and moviepy.
Run this script before building the application to ensure compatibility.
"""
import os
import sys
import re
import subprocess
import importlib.util
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_pydantic_version():
    """Check pydantic version and fix compatibility issues."""
    try:
        import pydantic
        version = pydantic.__version__
        logger.info(f"Found pydantic version: {version}")
        
        # Check if it's V2 (which causes issues with PyInstaller)
        if version.startswith('2.'):
            logger.warning("Pydantic V2 detected, which may cause issues with PyInstaller")
            logger.info("Downgrading pydantic to a compatible version (1.10.8)...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", "pydantic==1.10.8", "--force-reinstall"])
            logger.info("Pydantic downgraded successfully")
            return True
        else:
            logger.info("Pydantic version is compatible with PyInstaller")
            return False
    except ImportError:
        logger.info("Pydantic not installed, installing compatible version...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pydantic==1.10.8"])
        logger.info("Pydantic installed successfully")
        return True

def fix_moviepy_syntax():
    """Fix the syntax warning in moviepy's sliders.py."""
    try:
        import moviepy
        moviepy_path = os.path.dirname(moviepy.__file__)
        sliders_path = os.path.join(moviepy_path, 'video', 'io', 'sliders.py')
        
        if not os.path.exists(sliders_path):
            logger.warning(f"Could not find sliders.py at {sliders_path}")
            return False
        
        logger.info(f"Fixing syntax in {sliders_path}")
        
        # Read the file
        with open(sliders_path, 'r') as f:
            content = f.read()
        
        # Fix the syntax warning (replace "is" with "==")
        fixed_content = re.sub(r"if event\.key is 'enter':", "if event.key == 'enter':", content)
        
        # Write the fixed content back
        if fixed_content != content:
            with open(sliders_path, 'w') as f:
                f.write(fixed_content)
            logger.info("Fixed moviepy syntax issue")
            return True
        else:
            logger.info("No moviepy syntax issues found or already fixed")
            return False
    
    except Exception as e:
        logger.error(f"Error fixing moviepy syntax: {str(e)}")
        return False

def fix_pyinstaller_hooks():
    """Fix PyInstaller hooks for pydantic."""
    try:
        # Find the PyInstaller hooks directory
        pyinstaller_spec = importlib.util.find_spec("PyInstaller")
        if not pyinstaller_spec or not pyinstaller_spec.submodule_search_locations:
            logger.warning("Could not find PyInstaller installation")
            return False
        
        pyinstaller_path = pyinstaller_spec.submodule_search_locations[0]
        hooks_contrib_spec = importlib.util.find_spec("_pyinstaller_hooks_contrib")
        
        if hooks_contrib_spec and hooks_contrib_spec.submodule_search_locations:
            hooks_contrib_path = hooks_contrib_spec.submodule_search_locations[0]
            pydantic_hook_path = os.path.join(hooks_contrib_path, 'hooks', 'stdhooks', 'hook-pydantic.py')
            
            if os.path.exists(pydantic_hook_path):
                logger.info(f"Found pydantic hook at {pydantic_hook_path}")
                
                # Create a backup
                backup_path = pydantic_hook_path + '.bak'
                if not os.path.exists(backup_path):
                    with open(pydantic_hook_path, 'r') as f:
                        original_content = f.read()
                    
                    with open(backup_path, 'w') as f:
                        f.write(original_content)
                    logger.info(f"Created backup at {backup_path}")
                
                # Fix the hook
                with open(pydantic_hook_path, 'r') as f:
                    content = f.read()
                
                # Replace the problematic line
                if "is_compiled = get_module_attribute('pydantic', 'compiled')" in content:
                    fixed_content = content.replace(
                        "is_compiled = get_module_attribute('pydantic', 'compiled') in {'True', True}",
                        "is_compiled = False  # Fixed for pydantic V2 compatibility"
                    )
                    
                    with open(pydantic_hook_path, 'w') as f:
                        f.write(fixed_content)
                    logger.info("Fixed pydantic hook for PyInstaller")
                    return True
                else:
                    logger.info("Pydantic hook already fixed or has a different format")
            else:
                logger.warning(f"Could not find pydantic hook at {pydantic_hook_path}")
        else:
            logger.warning("Could not find PyInstaller hooks contrib package")
        
        return False
    
    except Exception as e:
        logger.error(f"Error fixing PyInstaller hooks: {str(e)}")
        return False

def main():
    """Main function to fix all build issues."""
    logger.info("Starting build issue fixes...")
    
    # Fix pydantic version
    pydantic_fixed = check_pydantic_version()
    
    # Fix moviepy syntax
    moviepy_fixed = fix_moviepy_syntax()
    
    # Fix PyInstaller hooks
    hooks_fixed = fix_pyinstaller_hooks()
    
    if pydantic_fixed or moviepy_fixed or hooks_fixed:
        logger.info("Build issues fixed successfully!")
    else:
        logger.info("No build issues found or fixed")
    
    logger.info("All fixes completed")
    return 0

if __name__ == "__main__":
    sys.exit(main())
