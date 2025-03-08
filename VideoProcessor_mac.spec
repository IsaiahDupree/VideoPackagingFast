# -*- mode: python ; coding: utf-8 -*-

import os
import sys

block_cipher = None

# Define FFmpeg binary location
ffmpeg_bin = None
if os.path.exists('ffmpeg_bin'):
    ffmpeg_bin = [('ffmpeg_bin/ffmpeg', 'ffmpeg_bin/ffmpeg')]

# Collect all necessary data files
datas = [
    ('ai_prompts.json', '.'),
    ('config.json', '.'),
    ('resources', 'resources')
]

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=ffmpeg_bin if ffmpeg_bin else [],
    datas=datas,
    hiddenimports=[
        'PIL._tkinter_finder',
        'openai',
        'anthropic',
        'pydub',
        'moviepy',
        'numpy',
        'tkinter',
        'dotenv',
        'requests',
        'packaging',
        'tqdm',
        'json',
        'logging',
        'os',
        'sys',
        'platform',
        'subprocess',
        'tempfile',
        'datetime',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'transformers',
        'tensorflow',
        'torch',
        'whisper',  # Remove whisper to reduce size unless it's essential
        'matplotlib',
        'PyQt5',
        'PySide2',
        'IPython',
        'jupyter',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='VideoProcessor',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=True,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

# For macOS, create a .app bundle
app = BUNDLE(
    exe,
    name='VideoProcessor.app',
    icon='resources/icon.icns',  # Make sure this file exists
    bundle_identifier='com.videoprocessor.app',
    info_plist={
        'NSHighResolutionCapable': 'True',
        'NSRequiresAquaSystemAppearance': 'False',
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleDisplayName': 'VideoProcessor',
        'LSApplicationCategoryType': 'public.app-category.video',
        'NSHumanReadableCopyright': 'Copyright 2025 Isaiah Dupree. All rights reserved.',
    },
)
