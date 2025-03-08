@echo off
echo ===================================================
echo VideoPackagingFast Installer Builder
echo ===================================================
echo.

:: Set up environment
set PYTHON_CMD=python
set INSTALLER_NAME=VideoPackagingFast_Installer

:: Check if Python is installed
%PYTHON_CMD% --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Python not found! Please install Python 3.8 or higher.
    pause
    exit /b 1
)

:: Install required packages
echo Installing required packages...
%PYTHON_CMD% -m pip install -q requests tqdm pyinstaller==5.6.2 pyinstaller-hooks-contrib==2022.0

:: Close any running instances of the application
echo Closing any running instances of the application...
taskkill /f /im VideoProcessor.exe 2>nul
taskkill /f /im %INSTALLER_NAME%.exe 2>nul
timeout /t 2 /nobreak >nul

:: Set up FFmpeg
echo Setting up FFmpeg...
%PYTHON_CMD% setup_ffmpeg.py
if %ERRORLEVEL% NEQ 0 (
    echo Failed to set up FFmpeg.
    pause
    exit /b 1
)

:: Clean previous build directories
echo Cleaning previous build...
if exist build (
    rmdir /s /q build 2>nul
    if exist build (
        echo Warning: Could not remove build directory completely.
        echo This may be due to locked files. Continuing anyway...
    )
)

if exist dist (
    rmdir /s /q dist 2>nul
    if exist dist (
        echo Warning: Could not remove dist directory completely.
        echo This may be due to locked files. Continuing anyway...
    )
)

:: Create a temporary installer directory
echo Creating installer directory...
if exist installer_temp (
    rmdir /s /q installer_temp 2>nul
)
mkdir installer_temp

:: Copy installer resources
echo Copying installer resources...
mkdir installer_temp\resources
copy resources\icon.ico installer_temp\resources\ >nul 2>&1

:: Create the installer script
echo Creating installer script...
(
echo import os
echo import sys
echo import subprocess
echo import shutil
echo import tempfile
echo import zipfile
echo import tkinter as tk
echo from tkinter import ttk, messagebox
echo.
echo class InstallerApp:
echo     def __init__^(self, root^):
echo         self.root = root
echo         self.root.title^("VideoPackagingFast Installer"^)
echo         self.root.geometry^("600x400"^)
echo         self.root.resizable^(False, False^)
echo.
echo         # Set application icon
echo         icon_path = os.path.join^(os.path.dirname^(os.path.abspath^(__file__^)^), "resources", "icon.ico"^)
echo         if os.path.exists^(icon_path^):
echo             self.root.iconbitmap^(icon_path^)
echo.
echo         # Configure style
echo         self.style = ttk.Style^(^)
echo         self.style.configure^("TButton", font=^("Arial", 12^)^)
echo         self.style.configure^("TLabel", font=^("Arial", 12^)^)
echo.
echo         # Main frame
echo         main_frame = ttk.Frame^(root, padding="20"^)
echo         main_frame.pack^(fill=tk.BOTH, expand=True^)
echo.
echo         # Header
echo         header_label = ttk.Label^(
echo             main_frame, 
echo             text="VideoPackagingFast Installer", 
echo             font=^("Arial", 18, "bold"^)
echo         ^)
echo         header_label.pack^(pady=10^)
echo.
echo         # Description
echo         desc_text = "This installer will set up VideoPackagingFast on your computer.\n"
echo         desc_text += "The application will be installed in your Documents folder."
echo         desc_label = ttk.Label^(main_frame, text=desc_text, wraplength=550^)
echo         desc_label.pack^(pady=10^)
echo.
echo         # Installation directory
echo         self.install_dir = os.path.join^(os.path.expanduser^("~"^), "Documents", "VideoPackagingFast"^)
echo         dir_frame = ttk.Frame^(main_frame^)
echo         dir_frame.pack^(fill=tk.X, pady=10^)
echo.
echo         dir_label = ttk.Label^(dir_frame, text="Installation Directory:"^)
echo         dir_label.pack^(side=tk.LEFT, padx=5^)
echo.
echo         self.dir_var = tk.StringVar^(value=self.install_dir^)
echo         dir_entry = ttk.Entry^(dir_frame, textvariable=self.dir_var, width=50^)
echo         dir_entry.pack^(side=tk.LEFT, padx=5, fill=tk.X, expand=True^)
echo.
echo         browse_btn = ttk.Button^(dir_frame, text="Browse", command=self.browse_directory^)
echo         browse_btn.pack^(side=tk.LEFT, padx=5^)
echo.
echo         # Progress bar
echo         self.progress_var = tk.DoubleVar^(^)
echo         progress_frame = ttk.Frame^(main_frame^)
echo         progress_frame.pack^(fill=tk.X, pady=10^)
echo         self.progress_bar = ttk.Progressbar^(
echo             progress_frame, 
echo             variable=self.progress_var, 
echo             length=550, 
echo             mode="determinate"
echo         ^)
echo         self.progress_bar.pack^(fill=tk.X, padx=5^)
echo.
echo         # Status label
echo         self.status_var = tk.StringVar^(value="Ready to install"^)
echo         status_label = ttk.Label^(main_frame, textvariable=self.status_var^)
echo         status_label.pack^(pady=5^)
echo.
echo         # Buttons
echo         button_frame = ttk.Frame^(main_frame^)
echo         button_frame.pack^(pady=20^)
echo.
echo         self.install_btn = ttk.Button^(
echo             button_frame, 
echo             text="Install", 
echo             command=self.start_installation,
echo             width=15
echo         ^)
echo         self.install_btn.pack^(side=tk.LEFT, padx=10^)
echo.
echo         exit_btn = ttk.Button^(
echo             button_frame, 
echo             text="Exit", 
echo             command=self.root.destroy,
echo             width=15
echo         ^)
echo         exit_btn.pack^(side=tk.LEFT, padx=10^)
echo.
echo     def browse_directory^(self^):
echo         from tkinter import filedialog
echo         directory = filedialog.askdirectory^(^)
echo         if directory:
echo             self.dir_var.set^(os.path.join^(directory, "VideoPackagingFast"^)^)
echo.
echo     def update_status^(self, message, progress=None^):
echo         self.status_var.set^(message^)
echo         if progress is not None:
echo             self.progress_var.set^(progress^)
echo         self.root.update^(^)
echo.
echo     def start_installation^(self^):
echo         self.install_btn.config^(state="disabled"^)
echo         self.update_status^("Starting installation...", 0^)
echo.
echo         try:
echo             # Create installation directory
echo             install_dir = self.dir_var.get^(^)
echo             if not os.path.exists^(install_dir^):
echo                 os.makedirs^(install_dir^)
echo.
echo             self.update_status^("Extracting application files...", 20^)
echo.
echo             # Get the path to the embedded ZIP file
echo             app_zip = os.path.join^(os.path.dirname^(os.path.abspath^(__file__^)^), "app.zip"^)
echo             if not os.path.exists^(app_zip^):
echo                 raise FileNotFoundError^("Application package not found!"^)
echo.
echo             # Extract the application
echo             with zipfile.ZipFile^(app_zip, 'r'^) as zip_ref:
echo                 total_files = len^(zip_ref.namelist^(^)^)
echo                 for i, file in enumerate^(zip_ref.namelist^(^)^):
echo                     zip_ref.extract^(file, install_dir^)
echo                     progress = 20 + ^(i / total_files^) * 60
echo                     if i %% 10 == 0:  # Update status every 10 files
echo                         self.update_status^(f"Extracting: {file}", progress^)
echo.
echo             self.update_status^("Creating shortcuts...", 80^)
echo.
echo             # Create desktop shortcut
echo             self.create_shortcut^(
echo                 os.path.join^(install_dir, "VideoProcessor.exe"^),
echo                 os.path.join^(os.path.expanduser^("~"^), "Desktop", "VideoPackagingFast.lnk"^)
echo             ^)
echo.
echo             # Create start menu shortcut
echo             start_menu_dir = os.path.join^(
echo                 os.environ.get^("APPDATA", ""^), 
echo                 "Microsoft", "Windows", "Start Menu", "Programs", "VideoPackagingFast"
echo             ^)
echo             if not os.path.exists^(start_menu_dir^):
echo                 os.makedirs^(start_menu_dir^)
echo             self.create_shortcut^(
echo                 os.path.join^(install_dir, "VideoProcessor.exe"^),
echo                 os.path.join^(start_menu_dir, "VideoPackagingFast.lnk"^)
echo             ^)
echo.
echo             # Create uninstaller
echo             self.create_uninstaller^(install_dir^)
echo.
echo             self.update_status^("Installation completed successfully!", 100^)
echo             messagebox.showinfo^(
echo                 "Installation Complete", 
echo                 f"VideoPackagingFast has been installed successfully!\n\nLocation: {install_dir}"
echo             ^)
echo.
echo             # Ask if user wants to launch the application
echo             if messagebox.askyesno^("Launch Application", "Do you want to launch VideoPackagingFast now?"^):
echo                 subprocess.Popen^(
echo                     [os.path.join^(install_dir, "VideoProcessor.exe"^)],
echo                     cwd=install_dir
echo                 ^)
echo                 self.root.destroy^(^)
echo.
echo         except Exception as e:
echo             self.update_status^(f"Error: {str^(e^)}", 0^)
echo             messagebox.showerror^("Installation Error", f"An error occurred during installation:\n\n{str^(e^)}"^)
echo             self.install_btn.config^(state="normal"^)
echo.
echo     def create_shortcut^(self, target_path, shortcut_path^):
echo         try:
echo             import pythoncom
echo             from win32com.client import Dispatch
echo.
echo             shell = Dispatch^("WScript.Shell"^)
echo             shortcut = shell.CreateShortCut^(shortcut_path^)
echo             shortcut.Targetpath = target_path
echo             shortcut.WorkingDirectory = os.path.dirname^(target_path^)
echo             shortcut.IconLocation = target_path
echo             shortcut.save^(^)
echo             return True
echo         except Exception as e:
echo             print^(f"Error creating shortcut: {str^(e^)}"^)
echo             return False
echo.
echo     def create_uninstaller^(self, install_dir^):
echo         uninstaller_path = os.path.join^(install_dir, "uninstall.bat"^)
echo         with open^(uninstaller_path, 'w'^) as f:
echo             f.write^("@echo off\n"^)
echo             f.write^("echo Uninstalling VideoPackagingFast...\n"^)
echo             f.write^("taskkill /f /im VideoProcessor.exe 2>nul\n"^)
echo             f.write^("timeout /t 2 /nobreak >nul\n"^)
echo             f.write^(f"rmdir /s /q \"{install_dir}\"\n"^)
echo             f.write^(f"del \"%userprofile%\\Desktop\\VideoPackagingFast.lnk\" 2>nul\n"^)
echo             f.write^(f"rmdir /s /q \"%appdata%\\Microsoft\\Windows\\Start Menu\\Programs\\VideoPackagingFast\" 2>nul\n"^)
echo             f.write^("echo Uninstallation complete.\n"^)
echo             f.write^("pause\n"^)
echo.
echo         # Create uninstaller shortcut in start menu
echo         start_menu_dir = os.path.join^(
echo             os.environ.get^("APPDATA", ""^), 
echo             "Microsoft", "Windows", "Start Menu", "Programs", "VideoPackagingFast"
echo         ^)
echo         self.create_shortcut^(
echo             uninstaller_path,
echo             os.path.join^(start_menu_dir, "Uninstall VideoPackagingFast.lnk"^)
echo         ^)
echo.
echo if __name__ == "__main__":
echo     # Add pywin32 for shortcut creation
echo     try:
echo         import win32com.client
echo     except ImportError:
echo         subprocess.check_call^([sys.executable, "-m", "pip", "install", "pywin32"^]^)
echo.
echo     root = tk.Tk^(^)
echo     app = InstallerApp^(root^)
echo     root.mainloop^(^)
) > installer_temp\installer.py

:: Build the application
echo Building the application...
%PYTHON_CMD% -m PyInstaller --noconfirm --clean VideoProcessor_windows.spec

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

:: Package the application
echo Packaging the application...
cd dist
if exist app.zip (
    del app.zip
)
powershell Compress-Archive -Path VideoProcessor\* -DestinationPath ..\installer_temp\app.zip
cd ..

:: Build the installer
echo Building the installer...
cd installer_temp
%PYTHON_CMD% -m PyInstaller --noconfirm --onefile --windowed --icon=resources\icon.ico --name=%INSTALLER_NAME% installer.py
cd ..

:: Copy the installer to the dist directory
echo Finalizing installer...
if not exist dist (
    mkdir dist
)
copy installer_temp\dist\%INSTALLER_NAME%.exe dist\ >nul 2>&1

:: Clean up
echo Cleaning up...
rmdir /s /q installer_temp 2>nul

echo.
echo ===================================================
echo Installer created successfully!
echo The installer is located at: dist\%INSTALLER_NAME%.exe
echo ===================================================

pause
