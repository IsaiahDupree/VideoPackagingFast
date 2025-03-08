# VideoPackagingFast - Installation and GitHub Guide

This document provides comprehensive instructions for building the VideoPackagingFast application, testing the executable, and pushing changes to the GitHub master branch.

## Table of Contents
1. [Building the Application](#building-the-application)
2. [Testing the Executable](#testing-the-executable)
3. [Cleaning the Repository](#cleaning-the-repository)
4. [GitHub Workflow](#github-workflow)
5. [Troubleshooting](#troubleshooting)

## Building the Application

### Prerequisites

- Python 3.8 or later
- Git
- Windows or macOS
- Sufficient disk space (at least 1GB free)

### Build Process

We now have a simplified build process that addresses PySimpleGUI issues and bundles FFmpeg automatically:

1. **Simplified Build** (Recommended for most cases):

   ```batch
   build_simplified.bat
   ```

   This script:
   - Installs PySimpleGUI 5.0.0.16 specifically
   - Automatically bundles FFmpeg with the executable
   - Creates a distributable ZIP file
   - Launches the application for immediate testing

2. **Alternative Build Scripts** (If simplified build fails):

   ```batch
   build_direct_install.bat
   ```

   This script uses a direct installation method for PySimpleGUI to bypass dependency conflicts.

   ```batch
   build_with_pysimplegui_fix.bat
   ```

   This script attempts to fix PySimpleGUI import issues with a wrapper approach.

   ```batch
   build_windows_pydantic_fix.bat
   ```

   This script focuses on fixing pydantic compatibility issues with PyInstaller.

### Automatic Launch After Build

The simplified build script automatically launches the executable after a successful build. If you prefer to use the older build script with auto-launch:

```batch
build_and_run.bat
```

## Testing the Executable

After building, it's crucial to test the executable thoroughly:

1. **Manual Testing Checklist**:
   - [ ] Application launches without errors
   - [ ] All UI elements display correctly
   - [ ] Video processing functionality works
   - [ ] AI integration functions properly
   - [ ] Settings can be saved and loaded
   - [ ] FFmpeg integration works correctly

2. **Automated Testing** (if available):

   ```batch
   run_tests.bat
   ```

## Cleaning the Repository

Before pushing to GitHub, clean the repository to remove unnecessary files:

```batch
clean_repo.bat
```

This script will:
1. Remove build artifacts (build/, dist/ directories)
2. Remove virtual environments (venv/)
3. Remove temporary files and caches (`__pycache__/`, *.pyc)
4. Preserve important configuration files
5. Ensure no API keys or sensitive data remain

### Manual Cleaning Checklist

If you prefer to clean manually, ensure these items are addressed:

- [ ] Remove all build directories (build/, dist/)
- [ ] Remove virtual environments (venv/)
- [ ] Delete any API key files or .env files with sensitive data
- [ ] Remove large temporary files and test videos
- [ ] Clean up any personal configuration files
- [ ] Ensure .gitignore is properly configured

## GitHub Workflow

### Preparing for Push to Master

1. **Create a Feature Branch** (if not already on one):

   ```bash
   git checkout -b feature-name
   ```

2. **Stage Changes**:

   ```bash
   git add .
   ```

3. **Review Changes**:

   ```bash
   git status
   ```

   Verify that no sensitive files or large binaries are being committed.

4. **Commit Changes**:

   ```bash
   git commit -m "Descriptive message about your changes"
   ```

5. **Pull Latest Changes from Master**:

   ```bash
   git checkout master
   git pull origin master
   git checkout feature-name
   git rebase master
   ```

6. **Resolve Any Conflicts** if they occur during rebase.

### Pushing to Master

Once your changes are tested and the repository is clean:

```bash
git checkout master
git merge feature-name
git push origin master
```

Alternatively, you can push directly from your feature branch to master:

```bash
git push origin feature-name:master
```

### Post-Push Verification

After pushing to GitHub:

1. Verify the changes appear correctly on GitHub
2. Check GitHub Actions (if configured) for successful builds
3. Download a fresh copy and verify it builds correctly

## Troubleshooting

### Build Issues

1. **PySimpleGUI Issues**:
   - The simplified build script uses PySimpleGUI 5.0.0.16 specifically
   - If you encounter issues, run `install_pysimplegui_5_0_0_16.py` directly
   - For manual installation: `pip install PySimpleGUI==5.0.0.16`

2. **Pydantic Compatibility Issues**:
   - The simplified build uses pydantic 1.10.8 which is compatible with PyInstaller
   - If needed, manually install: `pip install pydantic==1.10.8`

3. **FFmpeg Not Found**:
   - The simplified build automatically bundles FFmpeg
   - If FFmpeg is missing, the build script will download it automatically

4. **Icon File Issues**:
   - The build script includes fallback icon handling
   - If needed, run `create_fallback_icon.py` to generate a valid icon

### GitHub Issues

1. **Unrelated Histories Error**:

   ```bash
   git pull origin master --allow-unrelated-histories
   ```

2. **Large File Rejection**:
   - Check for large files: `git ls-files --stage | grep -v ^100644`
   - Remove them: `git filter-branch --tree-filter 'rm -f path/to/large/file' HEAD`

3. **Authentication Issues**:
   - Use a personal access token
   - Configure SSH keys for GitHub

---

## Quick Reference

### Build and Test

```batch
build_simplified.bat
```

### Clean and Prepare for GitHub

```batch
clean_repo.bat
git add .
git commit -m "Your commit message"
git push origin master
```

---

*This guide was last updated on March 8, 2025.*
