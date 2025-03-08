@echo off
echo ===================================================
echo VideoPackagingFast - Repository Cleanup Script
echo ===================================================
echo.

echo This script will clean the repository of build artifacts,
echo temporary files, and sensitive data before pushing to GitHub.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

echo.
echo [1/7] Removing build artifacts...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist "*.spec" del /q "*.spec"
echo Done.

echo.
echo [2/7] Removing virtual environments...
if exist venv rmdir /s /q venv
if exist env rmdir /s /q env
if exist .venv rmdir /s /q .venv
echo Done.

echo.
echo [3/7] Removing Python cache files...
for /d /r . %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d"
del /s /q *.pyc *.pyo *.pyd 2>nul
echo Done.

echo.
echo [4/7] Removing temporary files...
del /s /q *.log *.tmp *.bak 2>nul
del /q build_log_*.txt 2>nul
echo Done.

echo.
echo [5/7] Checking for sensitive data...
echo Backing up .env file if it exists...
if exist .env copy .env .env.backup > nul
if exist .env (
    echo Creating safe .env template...
    echo # VideoPackagingFast Environment Variables > .env.template
    echo # Replace these values with your actual API keys > .env.template
    echo. >> .env.template
    echo # OpenAI API Key >> .env.template
    echo OPENAI_API_KEY=your_openai_api_key_here >> .env.template
    echo. >> .env.template
    echo # Anthropic API Key >> .env.template
    echo ANTHROPIC_API_KEY=your_anthropic_api_key_here >> .env.template
    echo. >> .env.template
    echo # Other configuration >> .env.template
    echo DEBUG=False >> .env.template
    
    echo Removing sensitive .env file...
    del /q .env
    echo .env file has been backed up to .env.backup and removed from repository.
    echo A template .env.template has been created for reference.
)
echo Done.

echo.
echo [6/7] Removing large binary files...
echo Checking for large files (>10MB)...
for /r %%f in (*) do @if %%~zf gtr 10485760 echo Large file found: %%f

echo.
echo [7/7] Verifying .gitignore...
if not exist .gitignore (
    echo Creating .gitignore file...
    echo # Build artifacts > .gitignore
    echo build/ >> .gitignore
    echo dist/ >> .gitignore
    echo *.spec >> .gitignore
    echo. >> .gitignore
    echo # Virtual environments >> .gitignore
    echo venv/ >> .gitignore
    echo env/ >> .gitignore
    echo .venv/ >> .gitignore
    echo. >> .gitignore
    echo # Python cache >> .gitignore
    echo __pycache__/ >> .gitignore
    echo *.py[cod] >> .gitignore
    echo *$py.class >> .gitignore
    echo. >> .gitignore
    echo # Environment variables and secrets >> .gitignore
    echo .env >> .gitignore
    echo *.env >> .gitignore
    echo .env.backup >> .gitignore
    echo. >> .gitignore
    echo # Logs and temporary files >> .gitignore
    echo *.log >> .gitignore
    echo *.tmp >> .gitignore
    echo *.bak >> .gitignore
    echo build_log_*.txt >> .gitignore
    echo. >> .gitignore
    echo # IDE files >> .gitignore
    echo .idea/ >> .gitignore
    echo .vscode/ >> .gitignore
    echo *.swp >> .gitignore
    echo. >> .gitignore
    echo # OS specific files >> .gitignore
    echo .DS_Store >> .gitignore
    echo Thumbs.db >> .gitignore
    echo. >> .gitignore
    echo # Large binary files >> .gitignore
    echo *.mp4 >> .gitignore
    echo *.mov >> .gitignore
    echo *.avi >> .gitignore
    echo *.zip >> .gitignore
    echo *.exe >> .gitignore
    echo ffmpeg_bin/ >> .gitignore
    echo. >> .gitignore
    echo # Keep these files >> .gitignore
    echo !resources/*.ico >> .gitignore
    echo !resources/icon.png >> .gitignore
) else (
    echo .gitignore already exists. Verifying contents...
    findstr /c:"*.env" .gitignore > nul
    if errorlevel 1 (
        echo Adding .env to .gitignore...
        echo. >> .gitignore
        echo # Environment variables and secrets >> .gitignore
        echo .env >> .gitignore
        echo *.env >> .gitignore
        echo .env.backup >> .gitignore
    )
)
echo Done.

echo.
echo ===================================================
echo Repository cleanup complete!
echo.
echo The following files have been removed:
echo - Build artifacts (build/, dist/, *.spec)
echo - Virtual environments (venv/, env/, .venv/)
echo - Python cache files (__pycache__/, *.pyc, *.pyo, *.pyd)
echo - Temporary files (*.log, *.tmp, *.bak, build_log_*.txt)
echo - Sensitive data (.env - backed up to .env.backup)
echo.
echo The repository is now clean and ready for GitHub.
echo ===================================================

echo.
echo Would you like to run 'git status' to verify the clean state? (Y/N)
set /p CHOICE="> "
if /i "%CHOICE%"=="Y" (
    git status
)

echo.
echo Repository cleanup completed successfully.
echo.
