# -*- mode: python ; coding: utf-8 -*-

import platform
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# Determine platform-specific settings
if platform.system() == 'Darwin':  # macOS
    icon_file = None
    console = False
    name_suffix = '_mac'
elif platform.system() == 'Windows':  # Windows
    icon_file = 'resources/icon.ico'
    console = False
    name_suffix = '_win'
else:  # Linux
    icon_file = None
    console = False
    name_suffix = '_linux'

# Collect all necessary data files
datas = []
datas += collect_data_files('whisper')
datas += collect_data_files('anthropic')
datas += [('ai_prompts.json', '.')]
datas += [('config.json', '.')]
datas += [('resources', 'resources')]

# Collect all necessary hidden imports
hiddenimports = []
hiddenimports += collect_submodules('whisper')
hiddenimports += collect_submodules('anthropic')
hiddenimports += collect_submodules('openai')
hiddenimports += ['PIL', 'PIL._tkinter_finder']

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
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
    name=f'VideoProcessor{name_suffix}',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=console,
    disable_windowed_traceback=False,
    argv_emulation=True,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=icon_file,
)

# For macOS, create a .app bundle
if platform.system() == 'Darwin':
    app = BUNDLE(
        exe,
        name='VideoProcessor.app',
        icon=None,
        bundle_identifier='com.videoprocessor.app',
        info_plist={
            'NSHighResolutionCapable': 'True',
            'NSRequiresAquaSystemAppearance': 'False',
            'CFBundleShortVersionString': '1.0.0',
        },
    )
