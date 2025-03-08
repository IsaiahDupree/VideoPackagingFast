"""
Fix syntax warnings in moviepy sliders.py file.
This script patches the moviepy sliders.py file to fix the 'is' with a literal warning.
"""
import os
import sys
import site

def find_moviepy_sliders():
    """Find the moviepy sliders.py file in the virtual environment."""
    # Try site-packages first
    site_packages = site.getsitepackages()
    for site_pkg in site_packages:
        sliders_path = os.path.join(site_pkg, 'moviepy', 'video', 'io', 'sliders.py')
        if os.path.exists(sliders_path):
            return sliders_path
    
    # Try the venv directory
    venv_path = os.path.join(os.getcwd(), 'venv', 'Lib', 'site-packages', 'moviepy', 'video', 'io', 'sliders.py')
    if os.path.exists(venv_path):
        return venv_path
    
    return None

def fix_sliders_syntax(file_path):
    """Fix the 'is' with a literal warning in the sliders.py file."""
    if not file_path or not os.path.exists(file_path):
        print(f"Error: Could not find sliders.py at {file_path}")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace the problematic line
    if "if event.key is 'enter':" in content:
        content = content.replace("if event.key is 'enter':", "if event.key == 'enter':")
        print(f"Fixed 'is' with literal warning in {file_path}")
        
        # Write the fixed content back to the file
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    else:
        print(f"Warning: Could not find the problematic line in {file_path}")
        return False

def main():
    """Main function to find and fix the moviepy sliders.py file."""
    print("Searching for moviepy sliders.py file...")
    sliders_path = find_moviepy_sliders()
    
    if sliders_path:
        print(f"Found sliders.py at: {sliders_path}")
        if fix_sliders_syntax(sliders_path):
            print("Successfully fixed syntax warning in moviepy sliders.py")
        else:
            print("Failed to fix syntax warning in moviepy sliders.py")
    else:
        print("Error: Could not find moviepy sliders.py file")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
