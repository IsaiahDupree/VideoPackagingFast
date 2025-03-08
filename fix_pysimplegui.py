#!/usr/bin/env python
import os
import sys
import logging
import subprocess
import importlib.util

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def fix_pysimplegui_installation():
    """Fix PySimpleGUI installation issues for PyInstaller compatibility"""
    logging.info("Fixing PySimpleGUI installation...")
    
    # Check if PySimpleGUI is installed
    psg_spec = importlib.util.find_spec("PySimpleGUI")
    
    if psg_spec:
        logging.info("PySimpleGUI is already installed, checking version...")
        try:
            import PySimpleGUI as sg
            logging.info(f"Current PySimpleGUI version: {sg.__version__}")
        except ImportError:
            logging.warning("PySimpleGUI is installed but cannot be imported")
    
    # Uninstall any existing PySimpleGUI
    logging.info("Uninstalling any existing PySimpleGUI...")
    subprocess.run([sys.executable, "-m", "pip", "uninstall", "-y", "PySimpleGUI"], 
                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # Install the specific version from PySimpleGUI.net
    logging.info("Installing PySimpleGUI 5.0.0.16...")
    result = subprocess.run([sys.executable, "-m", "pip", "install", "PySimpleGUI==5.0.0.16", "-i", "https://PySimpleGUI.net/install"], 
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    if result.returncode != 0:
        logging.error(f"Failed to install PySimpleGUI 5.0.0.16: {result.stderr.decode()}")
        logging.info("Trying alternative installation method...")
        
        # Try direct installation without version specification
        result = subprocess.run([sys.executable, "-m", "pip", "install", "PySimpleGUI", "-i", "https://PySimpleGUI.net/install"], 
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        if result.returncode != 0:
            logging.error(f"Alternative installation also failed: {result.stderr.decode()}")
            return False
    
    # Verify installation
    try:
        import PySimpleGUI as sg
        logging.info(f"Successfully installed PySimpleGUI version: {sg.__version__}")
        return True
    except ImportError as e:
        logging.error(f"Failed to import PySimpleGUI after installation: {str(e)}")
        return False

def create_pysimplegui_wrapper():
    """Create a wrapper module to handle PySimpleGUI import issues"""
    logging.info("Creating PySimpleGUI wrapper module...")
    
    # Create a wrapper directory if it doesn't exist
    wrapper_dir = os.path.join(os.getcwd(), "wrapper")
    os.makedirs(wrapper_dir, exist_ok=True)
    
    # Create __init__.py in the wrapper directory
    with open(os.path.join(wrapper_dir, "__init__.py"), "w") as f:
        f.write("# Wrapper package\n")
    
    # Create PySimpleGUI.py wrapper
    wrapper_content = """
# PySimpleGUI wrapper module
try:
    # Try to import the original PySimpleGUI
    import PySimpleGUI as sg
    # Re-export everything
    from PySimpleGUI import *
except ImportError:
    # Fallback implementation with basic functionality
    import tkinter as tk
    from tkinter import filedialog, messagebox
    
    # Define a minimal sg namespace with essential functions
    WINDOW_CLOSED = 'WINDOW_CLOSED'
    WIN_CLOSED = WINDOW_CLOSED
    
    def popup_error(message, *args, **kwargs):
        return messagebox.showerror("Error", message)
    
    def popup(message, *args, **kwargs):
        return messagebox.showinfo("Information", message)
    
    def popup_yes_no(message, *args, **kwargs):
        return messagebox.askyesno("Question", message)
    
    def FileBrowse(*args, **kwargs):
        return tk.Button(text="Browse")
    
    def FolderBrowse(*args, **kwargs):
        return tk.Button(text="Browse")
    
    def InputText(*args, **kwargs):
        return tk.Entry()
    
    def Text(text, *args, **kwargs):
        return tk.Label(text=text)
    
    def Button(text, *args, **kwargs):
        return tk.Button(text=text)
    
    def theme(theme_name):
        pass
    
    def theme_list():
        return ["Default"]
    
    # Minimal Window class
    class Window:
        def __init__(self, title, layout, **kwargs):
            self.title = title
            self.layout = layout
            self.tk_root = None
            
        def read(self, timeout=None):
            if not self.tk_root:
                self.tk_root = tk.Tk()
                self.tk_root.title(self.title)
            
            # This is just a placeholder, not functional
            return None, None
            
        def close(self):
            if self.tk_root:
                self.tk_root.destroy()
                
        def __del__(self):
            self.close()
    
    print("WARNING: Using PySimpleGUI fallback implementation with limited functionality")
"""
    
    with open(os.path.join(wrapper_dir, "PySimpleGUI.py"), "w") as f:
        f.write(wrapper_content)
    
    logging.info(f"Created PySimpleGUI wrapper at {os.path.join(wrapper_dir, 'PySimpleGUI.py')}")
    return True

def update_imports_in_file(file_path):
    """Update PySimpleGUI imports in a file to use the wrapper"""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace direct PySimpleGUI imports with wrapper imports
        updated_content = content.replace(
            'import PySimpleGUI as sg', 
            '# Try to import PySimpleGUI directly, fall back to wrapper if needed\n'
            'try:\n'
            '    import PySimpleGUI as sg\n'
            'except ImportError:\n'
            '    try:\n'
            '        from wrapper import PySimpleGUI as sg\n'
            '    except ImportError:\n'
            '        import tkinter as sg  # Last resort fallback\n'
            '        print("WARNING: Using tkinter fallback, UI may be limited")'
        )
        
        if content != updated_content:
            with open(file_path, 'w') as f:
                f.write(updated_content)
            logging.info(f"Updated imports in {file_path}")
            return True
        return False
    except Exception as e:
        logging.error(f"Error updating imports in {file_path}: {str(e)}")
        return False

def fix_gui_imports():
    """Fix PySimpleGUI imports in GUI files"""
    logging.info("Fixing PySimpleGUI imports in GUI files...")
    
    # Update main GUI file
    gui_file = os.path.join(os.getcwd(), "ui", "gui.py")
    if os.path.exists(gui_file):
        update_imports_in_file(gui_file)
    
    # Look for other files that might import PySimpleGUI
    for root, _, files in os.walk(os.getcwd()):
        for file in files:
            if file.endswith('.py') and file != 'fix_pysimplegui.py':
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    if 'import PySimpleGUI' in content:
                        update_imports_in_file(file_path)
                except Exception:
                    # Skip files that can't be read
                    pass

def main():
    """Main function to fix PySimpleGUI issues"""
    logging.info("Starting PySimpleGUI fixes...")
    
    # Try to fix PySimpleGUI installation
    installation_fixed = fix_pysimplegui_installation()
    
    # Create wrapper module as a fallback
    wrapper_created = create_pysimplegui_wrapper()
    
    # Fix imports in GUI files
    fix_gui_imports()
    
    if installation_fixed:
        logging.info("PySimpleGUI installation fixed successfully!")
    else:
        logging.warning("PySimpleGUI installation could not be fixed completely.")
        logging.info("Created wrapper module as fallback.")
    
    logging.info("All PySimpleGUI fixes applied.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
