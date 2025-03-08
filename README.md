# VideoPackagingFast

A cross-platform video processing application that helps content creators generate social media content from video files. This application works on both Windows and Mac.

## Features

- Extract audio from video files
- Transcribe audio to text using Whisper (when available)
- Generate social media content using OpenAI or Anthropic APIs
- Cross-platform compatibility (Windows and Mac)
- Modern and intuitive user interface
- Customizable themes

## Running the Application

### Option 1: Download and Run the Pre-built Executable (For Beginners)

#### Windows Users

1. **Download the latest release**
   - Go to the [Releases](https://github.com/IsaiahDupree/VideoPackagingFast/releases) page
   - Download the `VideoProcessor_Windows.zip` file
   - Extract the ZIP file to a location on your computer (e.g., Desktop or Documents folder)

2. **Run the application**
   - Navigate to the extracted folder
   - Double-click on `VideoProcessor.exe` to launch the application
   - If Windows SmartScreen appears, click "More info" and then "Run anyway" (this happens because the app isn't signed with a certificate)

3. **First-time setup**
   - When you first run the application, you'll need to enter your API key
   - Click on the "Settings" tab
   - Enter your OpenAI or Anthropic API key
   - Click "Save Settings"

#### Mac Users

1. **Download the latest release**
   - Go to the [Releases](https://github.com/IsaiahDupree/VideoPackagingFast/releases) page
   - Download the `VideoProcessor_Mac.zip` file
   - Extract the ZIP file to a location on your computer

2. **Run the application**
   - Navigate to the extracted folder
   - Right-click on `VideoProcessor.app` and select "Open"
   - Click "Open" when prompted (this is necessary because the app isn't signed with an Apple certificate)

3. **First-time setup**
   - When you first run the application, you'll need to enter your API key
   - Click on the "Settings" tab
   - Enter your OpenAI or Anthropic API key
   - Click "Save Settings"

### Option 2: Run from Source (For Developers)

1. **Clone the repository**

   ```bash
   git clone https://github.com/IsaiahDupree/VideoPackagingFast.git
   cd VideoPackagingFast
   ```

2. **Install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**

   ```bash
   python main.py
   ```

### Option 3: Build an Executable (Advanced)

#### Windows

1. Run the build script:

   ```bash
   .\build_windows.bat
   ```

2. The executable will be in the `dist/VideoProcessor` folder

#### Mac

1. Run the build script:

   ```bash
   chmod +x build_mac.sh
   ./build_mac.sh
   ```

2. The application will be in the `dist` folder as `VideoProcessor.app`

## Troubleshooting

### Common Issues

#### Application Won't Start

- **Windows**: Make sure you have the Visual C++ Redistributable installed. You can download it from [Microsoft's website](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170).
- **Mac**: If you get a message that the app is damaged, try running `xattr -cr /path/to/VideoProcessor.app` in Terminal.

#### "FFmpeg Not Found" Error

- Make sure FFmpeg is installed correctly
- For pre-built executables, FFmpeg should be included, but if you encounter this error:
  - **Windows**: Download FFmpeg from [ffmpeg.org](https://ffmpeg.org/download.html) and add it to your PATH
  - **Mac**: Install FFmpeg using `brew install ffmpeg`

#### API Key Issues

- Verify that you've entered the correct API key in the Settings tab
- Check your internet connection
- Ensure your API key has sufficient credits/quota

#### Processing Takes Too Long

- Transcription and content generation can take time, especially for longer videos
- Consider using a shorter video for testing
- Check that your computer meets the minimum system requirements

### Getting Help

If you encounter any issues not covered here, please:

1. Check the [Issues](https://github.com/IsaiahDupree/VideoPackagingFast/issues) page to see if your problem has been reported
2. Create a new issue with details about your problem if needed

## System Requirements

### Minimum Requirements

- **OS**: Windows 10/11 or macOS 10.15+
- **Processor**: Dual-core 2.0 GHz or better
- **Memory**: 4 GB RAM (8 GB recommended)
- **Storage**: 500 MB free space
- **Internet**: Required for API access

### Recommended Requirements

- **OS**: Windows 11 or macOS 12+
- **Processor**: Quad-core 2.5 GHz or better
- **Memory**: 8 GB RAM or more
- **Storage**: 1 GB free space
- **Internet**: Broadband connection

## Dependencies

- Python 3.8 or higher
- FFmpeg installed and available in PATH
- OpenAI or Anthropic API key

### Installing FFmpeg

#### Windows

1. Download FFmpeg from [ffmpeg.org](https://ffmpeg.org/download.html)
2. Extract the files to a folder (e.g., `C:\ffmpeg`)
3. Add the `bin` folder to your PATH environment variable

#### Mac

```bash
brew install ffmpeg
```

## Configuration

The application requires an API key for OpenAI or Anthropic to generate social media content. You can set this up in two ways:

1. **Environment Variables**:
   - Set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in your environment variables

2. **In-App Configuration**:
   - Enter your API key in the Settings tab of the application

## Usage

1. Launch the application
2. Select a video file to process
3. Choose an output directory
4. Click "Process Video"
5. The application will:
   - Extract audio from the video
   - Transcribe the audio to text
   - Generate social media content based on the transcript
   - Save all outputs to the specified directory

## License

This project is licensed under the MIT License - see the LICENSE file for details.
