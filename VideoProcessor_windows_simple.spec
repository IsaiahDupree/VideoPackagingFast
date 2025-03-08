# -*- mode: python ; coding: utf-8 -*-

import os
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# Determine the base directory
base_dir = os.path.abspath(os.path.dirname(__file__))

# Define paths relative to the base directory
ffmpeg_dir = os.path.join(base_dir, 'ffmpeg_bin')
assets_dir = os.path.join(base_dir, 'assets')
models_dir = os.path.join(base_dir, 'models')

# Collect all necessary data files
datas = [
    (assets_dir, 'assets'),
]

# Add FFmpeg if it exists
if os.path.exists(ffmpeg_dir):
    datas.append((ffmpeg_dir, 'ffmpeg_bin'))

# Add models directory if it exists
if os.path.exists(models_dir):
    datas.append((models_dir, 'models'))

# Basic analysis with simplified hidden imports
a = Analysis(
    ['main.py'],
    pathex=[base_dir],
    binaries=[],
    datas=datas,
    hiddenimports=[
        'pkg_resources.py2_warn',
        'pkg_resources.markers',
        'engineio.async_drivers.threading',
        'PIL',
        'PIL._tkinter_finder',
        'PIL.Image',
        'PIL.ImageTk',
        'moviepy.audio.fx',
        'moviepy.video.fx',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# Create the executable
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='VideoProcessor',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=os.path.join(assets_dir, 'icon.ico'),
)

# Create the collection
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='VideoProcessor',
)
