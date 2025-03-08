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

### Option 1: Run from Source (Recommended)

1. **Clone the repository**
   ```
   git clone https://github.com/IsaiahDupree/VideoPackagingFast.git
   cd VideoPackagingFast
   ```

2. **Install dependencies**
   ```
   pip install -r requirements.txt
   ```

3. **Run the application**
   ```
   python main.py
   ```

### Option 2: Build an Executable (Advanced)

#### Windows
1. Run the build script:
   ```
   .\build_windows.bat
   ```
2. The executable will be in the `dist/VideoProcessor` folder

#### Mac
1. Run the build script:
   ```
   chmod +x build_mac.sh
   ./build_mac.sh
   ```
2. The application will be in the `dist` folder as `VideoProcessor.app`

## Requirements

- Python 3.8 or higher
- FFmpeg installed and available in PATH
- OpenAI or Anthropic API key

### Installing FFmpeg

#### Windows
1. Download FFmpeg from [ffmpeg.org](https://ffmpeg.org/download.html)
2. Extract the files to a folder (e.g., `C:\ffmpeg`)
3. Add the `bin` folder to your PATH environment variable

#### Mac
```
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
