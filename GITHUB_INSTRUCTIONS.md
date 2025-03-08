# GitHub Instructions for VideoPackagingFast

This document provides comprehensive instructions for managing the VideoPackagingFast repository, including pushing updates, creating releases, and documenting progress.

## Repository Information

- **Repository URL**: [https://github.com/IsaiahDupree/VideoPackagingFast.git](https://github.com/IsaiahDupree/VideoPackagingFast.git)
- **Primary Branch**: master
- **License**: MIT

## Basic Git Commands

### Initial Setup

If you're setting up the repository for the first time:

```bash
# Clone the repository
git clone https://github.com/IsaiahDupree/VideoPackagingFast.git

# Navigate to the repository directory
cd VideoPackagingFast
```

### Daily Workflow

```bash
# Check status of your changes
git status

# Add specific files
git add filename.py

# Add all changed files
git add .

# Commit changes with a descriptive message
git commit -m "Brief description of changes"

# Push changes to GitHub
git push origin master
```

### Creating a New Branch

```bash
# Create and switch to a new branch
git checkout -b feature/new-feature-name

# Push the new branch to GitHub
git push -u origin feature/new-feature-name
```

### Merging Changes

```bash
# Switch to the master branch
git checkout master

# Merge your feature branch
git merge feature/new-feature-name

# Push merged changes to GitHub
git push origin master
```

## Creating Releases

1. Go to the [repository releases page](https://github.com/IsaiahDupree/VideoPackagingFast/releases)
2. Click "Draft a new release"
3. Enter a tag version (e.g., v1.0.0)
4. Write a release title and description
5. Attach the built executable files:
   - Windows: `VideoProcessor.exe` or `VideoPackagingFast_Windows.zip`
   - Mac: `VideoProcessor.app.zip`
6. Click "Publish release"

## Project Progress and Roadmap

### Current Progress

As of March 2025, we have:

1. **Core Functionality**
   - Implemented video processing with FFmpeg integration
   - Created cross-platform GUI using PySimpleGUI
   - Added AI-powered content generation with OpenAI/Anthropic
   - Implemented secure API key handling

2. **Build System**
   - Created reliable build scripts for Windows and Mac
   - Fixed compatibility issues with PyInstaller
   - Implemented one-click installer creation
   - Added automatic dependency management
   - Enhanced installation batch files with improved user feedback

3. **Documentation**
   - Comprehensive README with usage instructions
   - Build documentation for different environments
   - API integration documentation

### Future Directions

1. **Short-term Goals** (Next 1-3 months)
   - Implement batch processing for multiple videos
   - Add more social media platform templates
   - Improve error handling and user feedback
   - Create automated tests

2. **Mid-term Goals** (3-6 months)
   - Add video editing features (trimming, effects)
   - Implement cloud storage integration
   - Create a plugin system for extensibility
   - Add user presets for common operations

3. **Long-term Vision** (6+ months)
   - Web-based version with collaborative features
   - Mobile companion app
   - Advanced AI-powered video analysis
   - Integration with professional video editing workflows

## Contribution Guidelines

1. **Code Style**
   - Follow PEP 8 guidelines for Python code
   - Use descriptive variable and function names
   - Add comments for complex logic
   - Keep files under 300 lines when possible

2. **Pull Request Process**
   - Create a feature branch for your changes
   - Test thoroughly before submitting
   - Include a clear description of changes
   - Reference any related issues

3. **Issue Reporting**
   - Use the issue template when reporting bugs
   - Include steps to reproduce the issue
   - Specify your operating system and Python version
   - Attach screenshots if applicable

## Environment Setup for Contributors

1. **Required Software**
   - Python 3.8-3.10
   - Git
   - FFmpeg (optional, will be downloaded by scripts)

2. **Development Setup**

```bash
# Clone the repository
git clone https://github.com/IsaiahDupree/VideoPackagingFast.git

# Navigate to the repository
cd VideoPackagingFast

# Create a virtual environment
python -m venv venv

# Activate the virtual environment
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py
```

## Installation Batch Files

The repository includes two batch files for simplified installation on Windows:

1. **one_click_install.bat**
   - Provides a streamlined installation process for end users
   - Automatically downloads dependencies, builds the application, and creates a distributable ZIP
   - Includes comprehensive error handling and detailed logging
   - Keeps the window open to show installation results and requires user input to close

2. **one_click_install_check.bat**
   - Similar to one_click_install.bat but with additional verification steps
   - Performs more thorough dependency checking and validation
   - Provides detailed feedback about the installation process
   - Creates a log file with diagnostic information

Both batch files are designed to be user-friendly with clear progress indicators and will not close automatically, ensuring users can see the results of the installation process.

## Maintaining API Keys

The application uses API keys for OpenAI and Anthropic. These should never be committed to the repository.

1. **For Development**
   - Create a `.env` file in the root directory
   - Add your API keys: `OPENAI_API_KEY=your_key_here` or `ANTHROPIC_API_KEY=your_key_here`
   - The `.env` file is in `.gitignore` and will not be committed

2. **For End Users**
   - Users can set environment variables on their system
   - Or they can create a `.env` file when running the application

## Additional Resources

- [PySimpleGUI Documentation](https://pysimplegui.readthedocs.io/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
