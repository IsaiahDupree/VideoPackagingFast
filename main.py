"""
Video Processor Application - Main Entry Point

This application processes video files to generate social media content.
It extracts audio, transcribes it, and uses AI to generate content for various platforms.
"""
import os
import sys

# Add the current directory to the path to ensure all modules are importable
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import required modules
from ui.gui import VideoProcessorGUI
from utils.logger import graceful_shutdown, logger

def main():
    """Main entry point for the application"""
    try:
        # Create and run the GUI
        logger.info("Starting Video Processor application")
        app = VideoProcessorGUI()
        app.run()
    except Exception as e:
        import traceback
        error_msg = f"Critical error: {str(e)}"
        logger.error(error_msg)
        logger.error(traceback.format_exc())
        print(error_msg)
        print(traceback.format_exc())
        graceful_shutdown()
        sys.exit(1)

if __name__ == "__main__":
    main()
