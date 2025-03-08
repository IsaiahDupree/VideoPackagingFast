# Video Transcription and Social Media Content Generator

This application helps you transcribe videos and automatically generate social media content based on the transcriptions.

## Features

- Transcribe videos using OpenAI's Whisper API
- Generate social media content (YouTube, Twitter, LinkedIn) using AI models
- Support for multiple AI models including:
  - OpenAI: GPT-3.5-Turbo, GPT-4, GPT-4-Turbo, GPT-4.5, GPT-4o, GPT-4o-mini
  - Anthropic: o1, o3-mini
- Multiple UI themes for personalized experience
- Automatic display of results after processing
- Simple and intuitive GUI interface with three tabs:
  - Process: Select and process videos (transcription and content generation)
  - Results: View and edit generated content
  - Settings: Configure API keys, models, and UI preferences

## Setup

1. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

2. Set your OpenAI API key in the Settings tab or create a `.env` file with:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```

## Usage

1. Launch the application
2. In the Settings tab, enter your OpenAI or Anthropic API key
3. Select the video file you want to process
4. Choose an output directory
5. Click "Process Video" to start the transcription and content generation
6. View the results in the Results tab

## Cross-Platform Compatibility

This application is designed to work on both Windows and macOS with the following features:

- Platform-agnostic file paths
- Native file explorer integration for each OS
- Consistent UI across platforms
- Proper logging in user's Documents folder

## Building Executables

### Windows

To build the Windows executable:

1. Install the required dependencies: `pip install -r requirements.txt`
2. Run the build script: `.\build_windows.bat`
3. The executable will be created in the `dist/VideoProcessor` folder

### macOS

To build the macOS application:

1. Install the required dependencies: `pip install -r requirements.txt`
2. Make the build script executable: `chmod +x build_mac.sh`
3. Run the build script: `./build_mac.sh`
4. The application will be created in the `dist` folder as `VideoProcessor.app`

## Dependencies

- FFmpeg: Required for audio extraction
  - Windows: Download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH
  - macOS: Install using Homebrew: `brew install ffmpeg`

## Themes

The application includes multiple themes:
- Default (Light)
- Dark Mode
- Forest Green
- Sunset Orange
- Purple Haze

You can preview and select themes in the Settings tab.

## Notes

- The application supports common video formats: .mp4, .mov, .avi, .mkv
- Transcripts and social media content are saved in the output directory
- Make sure you have sufficient API credits for transcription and content generation

## Requirements

- Python 3.8 or higher
- Dependencies listed in requirements.txt
