# -*- mode: python ; coding: utf-8 -*-
import os
import sys

block_cipher = None

# Define FFmpeg binary location
ffmpeg_bin = None
if os.path.exists('ffmpeg_bin'):
    ffmpeg_bin = [('ffmpeg_bin/ffmpeg.exe', 'ffmpeg_bin/ffmpeg.exe')]
elif os.path.exists('C:\\ffmpeg\\bin\\ffmpeg.exe'):
    ffmpeg_bin = [('C:\\ffmpeg\\bin\\ffmpeg.exe', 'ffmpeg_bin/ffmpeg.exe')]

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
        'whisper',
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
    [],
    exclude_binaries=True,
    name='VideoProcessor',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,  # Set to False for production release
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='resources/icon.ico',
)

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
