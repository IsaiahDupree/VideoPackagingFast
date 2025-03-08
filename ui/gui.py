"""
GUI implementation for the Video Processor application.
"""
import os
import json
import PySimpleGUI as sg
import threading
import datetime
import time
import re
from moviepy.editor import VideoFileClip
import logging
import traceback
import queue
import platform

from core.video_processor import VideoProcessor, process_videos_multithreaded
from utils.config import load_config, save_config, get_api_key, set_api_key
from utils.prompts import load_prompts, save_prompts
from utils.logger import logger, log_exception
from utils.themes import THEMES, apply_theme
from utils.file_ops import open_file_explorer

# Create a status queue for communication between threads
status_queue = queue.Queue()

class VideoProcessorGUI:
    """Main GUI class for the Video Processor application"""
    
    def __init__(self):
        """Initialize the GUI"""
        self.window = None
        
        # Load configuration
        self.config = load_config()
        
        # Apply theme
        theme_name = self.config.get("ui", {}).get("theme", "Default Blue")
        apply_theme(theme_name)
        
        self.create_window()
        self.load_initial_data()
    
    def create_window(self):
        """Create the main application window"""
        
        # Create the layout
        layout = [
            [sg.TabGroup([
                [sg.Tab("Video Processing", self.create_process_tab(), key="-TAB_PROCESS-"),
                 sg.Tab("Results", self.create_results_tab(), key="-TAB_RESULTS-"),
                 sg.Tab("AI Prompts", self.create_prompts_tab(), key="-TAB_PROMPTS-"),
                 sg.Tab("Settings", self.create_settings_tab(), key="-TAB_SETTINGS-"),
                 sg.Tab("Terminal Output", self.create_terminal_tab(), key="-TAB_TERMINAL-")]
            ], key="-TABGROUP-", font=("Helvetica", 10), tab_background_color=None)],
            self.create_status_bar()
        ]
        
        # Create the window
        self.window = sg.Window(
            "Video Processor", 
            layout, 
            resizable=True, 
            finalize=True, 
            icon=sg.EMOJI_BASE64_HAPPY_JOY, 
            font=("Helvetica", 10)
        )
    
    def create_process_tab(self):
        """Create the video processing tab"""
        return [
            [sg.Frame("Video Selection", [
                [sg.Text("Select Video(s):", font=("Helvetica", 10))],
                [sg.Input(key="-VIDEO-", size=(60, 1)), 
                 sg.FilesBrowse(file_types=(("Video Files", "*.mp4 *.mov *.avi *.mkv"),), size=(10, 1))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Frame("Output Location", [
                [sg.Text("Output Directory:", font=("Helvetica", 10))],
                [sg.Input(key="-OUTPUT-", size=(60, 1)), 
                 sg.FolderBrowse(size=(10, 1))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Button("Process Video", size=(15, 1), button_color=("white", "#1E6FBA")), 
             sg.Button("View Results", size=(15, 1), button_color=("white", "#1E6FBA")), 
             sg.Button("Exit", size=(10, 1), button_color=("white", "#B31312"))],
            [sg.Text("Status:", size=(10, 1)), 
             sg.Text("Ready", size=(50, 1), key="-STATUS-", relief=sg.RELIEF_SUNKEN)],
            [sg.ProgressBar(100, orientation='h', size=(68, 20), key='-PROGRESS_BAR-', visible=False)]
        ]
    
    def create_results_tab(self):
        """Create the results tab"""
        return [
            [sg.Frame("Video Selection", [
                [sg.Text("Select Output Directory:", font=("Helvetica", 10))],
                [sg.Input(key="-RESULTS_DIR-", size=(60, 1)), 
                 sg.FolderBrowse(size=(10, 1))],
                [sg.Button("Load Results", size=(15, 1), button_color=("white", "#1E6FBA"))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Frame("Processed Videos", [
                [sg.Listbox(values=[], size=(80, 5), key="-VIDEO_LIST-", enable_events=True, 
                           font=("Helvetica", 10))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Column([
                [sg.Frame("Transcript", [
                    [sg.Multiline(size=(40, 20), key="-TRANSCRIPT-", disabled=True, 
                                font=("Courier", 10), background_color="#F0F0F0")]
                ], font=("Helvetica", 10, "bold"), pad=(10, 5))]
            ], vertical_alignment='top'),
             sg.Column([
                [sg.Frame("Social Media Content", [
                    [sg.Text("Title:", font=("Helvetica", 10, "bold"))],
                    [sg.Multiline(size=(40, 2), key="-SM_TITLE-", disabled=True, 
                                font=("Helvetica", 10), background_color="#F0F0F0")],
                    [sg.Text("Description:", font=("Helvetica", 10, "bold"))],
                    [sg.Multiline(size=(40, 5), key="-SM_DESCRIPTION-", disabled=True, 
                                font=("Helvetica", 10), background_color="#F0F0F0")],
                    [sg.Text("Hashtags:", font=("Helvetica", 10, "bold"))],
                    [sg.Multiline(size=(40, 2), key="-SM_HASHTAGS-", disabled=True, 
                                font=("Helvetica", 10), background_color="#F0F0F0")],
                    [sg.Text("Captions:", font=("Helvetica", 10, "bold"))],
                    [sg.Multiline(size=(40, 7), key="-SM_CAPTIONS-", disabled=True, 
                                font=("Helvetica", 10), background_color="#F0F0F0")]
                ], font=("Helvetica", 10, "bold"), pad=(10, 5))]
            ], vertical_alignment='top')]
        ]
    
    def create_prompts_tab(self):
        """Create the AI prompts tab"""
        return [
            [sg.Frame("AI System Prompt", [
                [sg.Multiline(key="-SYSTEM_PROMPT-", size=(70, 4), font=("Helvetica", 10))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Frame("Content Generation Prompt", [
                [sg.Multiline(key="-CONTENT_PROMPT-", size=(70, 10), font=("Helvetica", 10))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Button("Save Prompts", size=(15, 1), button_color=("white", "#1E6FBA")), 
             sg.Button("Reset to Default", size=(15, 1), button_color=("white", "#7D8597"))]
        ]
    
    def create_terminal_tab(self):
        """Create the terminal output tab"""
        return [
            [sg.Frame("Terminal Output", [
                [sg.Multiline(size=(70, 25), key="-TERMINAL_OUTPUT-", disabled=True, 
                             autoscroll=True, font=("Courier", 10), background_color="#000000", 
                             text_color="#FFFFFF")]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            [sg.Checkbox("Auto-scroll", default=True, key="-AUTOSCROLL-", font=("Helvetica", 10))]
        ]
    
    def create_settings_tab(self):
        """Create the settings tab"""
        # Get current API key (masked for security)
        api_key = get_api_key("OPENAI_API_KEY", "")
        masked_key = "••••••••" + api_key[-4:] if api_key and len(api_key) > 4 else ""
        
        # Load configuration
        config = load_config()
        
        return [
            [sg.Frame("API Settings", [
                [sg.Text("OpenAI API Key:", size=(15, 1)), 
                 sg.Input(masked_key, key="-API_KEY-", size=(50, 1), password_char='•'),
                 sg.Button("Show/Hide", key="-TOGGLE_API_KEY-", size=(8, 1))],
                [sg.Text("", size=(15, 1)), 
                 sg.Button("Update API Key", key="-UPDATE_API_KEY-", size=(15, 1))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            
            [sg.Frame("OpenAI Settings", [
                [sg.Text("Model:", size=(15, 1)), 
                 sg.Combo(["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo", "gpt-4.5", "gpt-4o", "gpt-4o-mini", "o1", "o3-mini"], 
                          default_value=config.get("openai", {}).get("model", "gpt-4"),
                          key="-OPENAI_MODEL-", size=(20, 1))],
                [sg.Text("Temperature:", size=(15, 1)), 
                 sg.Slider(range=(0.0, 1.0), default_value=config.get("openai", {}).get("temperature", 0.7),
                          resolution=0.1, orientation="h", size=(20, 15), key="-OPENAI_TEMP-")],
                [sg.Text("Max Tokens:", size=(15, 1)), 
                 sg.Slider(range=(100, 4000), default_value=config.get("openai", {}).get("max_tokens", 1000),
                          resolution=100, orientation="h", size=(20, 15), key="-OPENAI_TOKENS-")]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            
            [sg.Frame("Whisper Settings", [
                [sg.Text("Model:", size=(15, 1)), 
                 sg.Combo(["tiny", "base", "small", "medium", "large"], 
                          default_value=config.get("whisper", {}).get("model", "base"),
                          key="-WHISPER_MODEL-", size=(20, 1))],
                [sg.Text("Language:", size=(15, 1)), 
                 sg.Input(config.get("whisper", {}).get("language", "en"), 
                         key="-WHISPER_LANG-", size=(20, 1))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            
            [sg.Frame("Processing Settings", [
                [sg.Text("Chunk Size (sec):", size=(15, 1)), 
                 sg.Slider(range=(30, 1200), default_value=config.get("processing", {}).get("chunk_size", 600) / 60,
                          resolution=30, orientation="h", size=(20, 15), key="-CHUNK_SIZE-")],
                [sg.Text("Max Threads:", size=(15, 1)), 
                 sg.Slider(range=(1, 8), default_value=config.get("processing", {}).get("max_threads", 4),
                          resolution=1, orientation="h", size=(20, 15), key="-MAX_THREADS-")]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            
            [sg.Frame("UI Settings", [
                [sg.Text("Theme:", size=(15, 1)),
                 sg.Combo(list(THEMES.keys()), 
                         default_value=config.get("ui", {}).get("theme", "Default Blue"),
                         key="-UI_THEME-", size=(20, 1)),
                 sg.Button("Preview", key="-PREVIEW_THEME-", size=(8, 1))]
            ], font=("Helvetica", 10, "bold"), pad=(10, 5))],
            
            [sg.Button("Save Settings", size=(15, 1), button_color=("white", "#1E6FBA")), 
             sg.Button("Reset to Default", key="-RESET_SETTINGS-", size=(15, 1), button_color=("white", "#7D8597"))]
        ]
    
    def create_status_bar(self):
        """Create the status bar"""
        return [
            [sg.Text("Ready", key="-STATUSBAR-", size=(80, 1), relief=sg.RELIEF_SUNKEN, 
                    font=("Helvetica", 9), background_color="#1E6FBA", text_color="white")]
        ]
    
    def load_initial_data(self):
        """Load initial data for the application"""
        # Load prompts
        prompts = load_prompts()
        self.window["-SYSTEM_PROMPT-"].update(prompts["system_prompt"])
        self.window["-CONTENT_PROMPT-"].update(prompts["content_generation_prompt"])
    
    def update_terminal_output(self, text, level="INFO"):
        """Update the terminal output with formatted text"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        if level == "ERROR":
            formatted_text = f"[{timestamp}] \033[91m{level}: {text}\033[0m"  # Red for errors
        elif level == "WARNING":
            formatted_text = f"[{timestamp}] \033[93m{level}: {text}\033[0m"  # Yellow for warnings
        elif level == "SUCCESS":
            formatted_text = f"[{timestamp}] \033[92m{level}: {text}\033[0m"  # Green for success
        else:
            formatted_text = f"[{timestamp}] {level}: {text}"
        
        # Check if we're in the main thread
        if threading.current_thread() is threading.main_thread():
            # Directly update if in main thread
            self.window["-TERMINAL_OUTPUT-"].update(self.window["-TERMINAL_OUTPUT-"].get() + formatted_text + "\n")
            if self.window["-AUTOSCROLL-"].get():
                self.window["-TERMINAL_OUTPUT-"].Widget.see("end")
            self.window.refresh()
        else:
            # Send event to main thread if in worker thread
            self.window.write_event_value("-TERMINAL_UPDATE-", {"text": formatted_text})
    
    def process_single_video(self, video_path, output_dir):
        """Process a single video file"""
        try:
            self.update_terminal_output(f"Starting video processing for: {os.path.basename(video_path)}")
            processor = VideoProcessor(video_path, output_dir, self.update_terminal_output)
            result = processor.process_video()
            if result:
                # Use write_event_value instead of direct updates from worker threads
                self.window.write_event_value("-UPDATE_STATUS-", "Processing completed")
                self.update_terminal_output("Video processed successfully", "SUCCESS")
                # Send event to the main thread
                video_name = os.path.basename(video_path).split('.')[0]
                video_folder = os.path.join(output_dir, video_name)
                self.window.write_event_value("-VIDEO_PROCESSING_DONE-", {
                    "success": True, 
                    "filename": os.path.basename(video_path), 
                    "output_dir": output_dir, 
                    "video_folder": video_name
                })
            else:
                self.window.write_event_value("-UPDATE_STATUS-", "Processing failed")
                self.update_terminal_output("Video processing failed - check logs for details", "ERROR")
                self.window.write_event_value("-VIDEO_PROCESSING_DONE-", {"success": False, "filename": os.path.basename(video_path)})
        except Exception as e:
            error_msg = log_exception(logger, e, "Error processing video", self.update_terminal_output)
            self.window.write_event_value("-UPDATE_STATUS-", "Error processing video")
            self.window.write_event_value("-VIDEO_PROCESSING_DONE-", {"success": False, "error": str(e)})
    
    def process_multiple_videos(self, video_paths, output_dir):
        """Process multiple videos concurrently"""
        try:
            self.update_terminal_output(f"Starting multi-threaded processing of {len(video_paths)} videos")
            process_videos_multithreaded(video_paths, output_dir, self.update_terminal_output)
            self.window.write_event_value("-UPDATE_STATUS-", "Processing completed")
            self.update_terminal_output("All videos processed successfully", "SUCCESS")
            
            # For multiple videos, we'll just load the results directory without selecting a specific video
            self.window.write_event_value("-VIDEO_PROCESSING_DONE-", {
                "success": True, 
                "filename": "Multiple Videos", 
                "output_dir": output_dir
            })
        except Exception as e:
            error_msg = log_exception(logger, e, "Error processing videos", self.update_terminal_output)
            self.window.write_event_value("-UPDATE_STATUS-", "Error processing videos")
            self.window.write_event_value("-VIDEO_PROCESSING_DONE-", {"success": False, "error": str(e)})
    
    def load_video_results(self, folder_path):
        """Load list of processed videos from the results folder"""
        try:
            # Find all subdirectories in the results folder (each should be a processed video)
            video_folders = []
            for item in os.listdir(folder_path):
                item_path = os.path.join(folder_path, item)
                if os.path.isdir(item_path):
                    # Check if this folder contains our output files
                    if any(os.path.exists(os.path.join(item_path, f)) for f in ["transcript.txt", "social_media.json"]):
                        video_folders.append(item_path)
            
            # Update the video list
            self.window["-VIDEO_LIST-"].update(video_folders)
            
            if video_folders:
                self.update_terminal_output(f"Found {len(video_folders)} processed videos in {folder_path}")
            else:
                self.update_terminal_output(f"No processed videos found in {folder_path}")
                
        except Exception as e:
            error_msg = f"Error loading video results: {str(e)}"
            logger.error(error_msg)
            self.update_terminal_output(error_msg, "ERROR")
    
    def display_video_results(self, video_folder):
        """Display transcript and social media content for the selected video"""
        try:
            # Clear previous content
            self.window["-TRANSCRIPT-"].update("")
            self.window["-SM_TITLE-"].update("")
            self.window["-SM_DESCRIPTION-"].update("")
            self.window["-SM_HASHTAGS-"].update("")
            self.window["-SM_CAPTIONS-"].update("")
            
            # Load and display transcript
            transcript_path = os.path.join(video_folder, "transcript.txt")
            if os.path.exists(transcript_path):
                try:
                    with open(transcript_path, 'r', encoding='utf-8') as f:
                        transcript = f.read()
                    self.window["-TRANSCRIPT-"].update(transcript)
                    self.update_terminal_output(f"Loaded transcript from {os.path.basename(video_folder)}")
                except Exception as e:
                    self.update_terminal_output(f"Error reading transcript: {str(e)}", "ERROR")
            
            # Load and display social media content
            social_media_path = os.path.join(video_folder, "social_media.json")
            if os.path.exists(social_media_path):
                try:
                    with open(social_media_path, 'r', encoding='utf-8') as f:
                        content = json.load(f)
                    
                    # Update social media fields - map from the AI-generated format to the GUI fields
                    # Title field
                    if 'youtube_title' in content:
                        self.window["-SM_TITLE-"].update(content['youtube_title'])
                    elif 'title' in content:
                        self.window["-SM_TITLE-"].update(content['title'])
                    
                    # Description field
                    if 'youtube_description' in content:
                        self.window["-SM_DESCRIPTION-"].update(content['youtube_description'])
                    elif 'description' in content:
                        self.window["-SM_DESCRIPTION-"].update(content['description'])
                    
                    # Hashtags field - extract from description or use dedicated field
                    hashtags_text = ""
                    if 'hashtags' in content:
                        hashtags_text = ' '.join(content['hashtags']) if isinstance(content['hashtags'], list) else content['hashtags']
                    elif 'youtube_description' in content:
                        # Try to extract hashtags from the description
                        import re
                        hashtags = re.findall(r'#\w+', content['youtube_description'])
                        if hashtags:
                            hashtags_text = ' '.join(hashtags)
                    
                    self.window["-SM_HASHTAGS-"].update(hashtags_text)
                    
                    # Captions field - combine tweets/posts
                    captions_text = ""
                    if 'captions' in content:
                        if isinstance(content['captions'], list):
                            captions_text = '\n\n'.join(content['captions'])
                        else:
                            captions_text = content['captions']
                    elif 'tweets' in content:
                        if isinstance(content['tweets'], list):
                            captions_text = '\n\n'.join(content['tweets'])
                        else:
                            captions_text = content['tweets']
                    elif 'linkedin_post' in content:
                        captions_text = content['linkedin_post']
                    
                    self.window["-SM_CAPTIONS-"].update(captions_text)
                    
                    self.update_terminal_output(f"Loaded social media content from {os.path.basename(video_folder)}")
                except Exception as e:
                    self.update_terminal_output(f"Error reading social media content: {str(e)}", "ERROR")
            
        except Exception as e:
            error_msg = f"Error displaying video results: {str(e)}"
            logger.error(error_msg)
            self.update_terminal_output(error_msg, "ERROR")
    
    def run(self):
        """Run the main event loop"""
        while True:
            try:
                event, values = self.window.read(timeout=100)
                
                if event == sg.WINDOW_CLOSED:
                    logger.info("Window close event detected")
                    self.update_terminal_output("Application closing...", "INFO")
                    break
                    
                if event == "Exit":
                    logger.info("Exit button clicked")
                    self.update_terminal_output("Application closing...", "INFO")
                    break
                    
                # Update status from the queue
                if not status_queue.empty():
                    status = status_queue.get_nowait()
                    self.window["-STATUSBAR-"].update(status)
                    self.update_terminal_output(f"{status}")
                    self.window.refresh()
                    
                if event == "Process Video":
                    video_input = values["-VIDEO-"]
                    output_dir = values["-OUTPUT-"] if values["-OUTPUT-"] else os.path.dirname(video_input.split(';')[0])
                    video_paths = [v.strip() for v in video_input.split(';') if v.strip()] 
                    
                    if not video_paths:
                        sg.popup_error("Please select at least one video file")
                        self.update_terminal_output("Error: No video files selected", "ERROR")
                        continue
                        
                    self.update_terminal_output(f"Processing videos: {', '.join([os.path.basename(v) for v in video_paths])}")
                    self.update_terminal_output(f"Output directory: {output_dir}")
                    
                    if len(video_paths) > 1:
                        # Process videos concurrently
                        threading.Thread(
                            target=self.process_multiple_videos, 
                            args=(video_paths, output_dir), 
                            daemon=True
                        ).start()
                        self.window["-STATUSBAR-"].update(f"Processing {len(video_paths)} videos concurrently...")
                    else:
                        # Process single video
                        threading.Thread(
                            target=self.process_single_video, 
                            args=(video_paths[0], output_dir), 
                            daemon=True
                        ).start()
                        self.window["-STATUSBAR-"].update(f"Processing video: {os.path.basename(video_paths[0])}")
                        
                if event == "View Results":
                    folder_path = values["-OUTPUT-"]
                    if folder_path and os.path.isdir(folder_path):
                        # Use platform-agnostic file explorer opener
                        open_file_explorer(folder_path)
                        self.update_terminal_output(f"Opening results folder: {folder_path}")
                        # Also load results in the app
                        self.load_video_results(folder_path)
                        self.window["-TABGROUP-"].Widget.select(1)  # Switch to Results tab
                    else:
                        sg.popup("Please select a valid results folder.")
                
                if event == "Load Results":
                    folder_path = values["-RESULTS_DIR-"]
                    if folder_path and os.path.isdir(folder_path):
                        self.load_video_results(folder_path)
                    else:
                        sg.popup("Please select a valid results folder.")
                
                if event == "-VIDEO_LIST-" and values["-VIDEO_LIST-"]:
                    selected_video = values["-VIDEO_LIST-"][0]
                    self.display_video_results(selected_video)
                
                if event == "Save Prompts":
                    new_prompts = {
                        "system_prompt": values["-SYSTEM_PROMPT-"],
                        "content_generation_prompt": values["-CONTENT_PROMPT-"]
                    }
                    if save_prompts(new_prompts):
                        sg.popup("Prompts saved successfully!")
                        self.update_terminal_output("AI prompts saved successfully")
                    else:
                        sg.popup_error("Failed to save prompts!")
                        self.update_terminal_output("ERROR: Failed to save AI prompts")
                        
                if event == "Reset to Default":
                    if os.path.exists("ai_prompts.json"):
                        os.remove("ai_prompts.json")
                    prompts = load_prompts()
                    self.window["-SYSTEM_PROMPT-"].update(prompts["system_prompt"])
                    self.window["-CONTENT_PROMPT-"].update(prompts["content_generation_prompt"])
                    sg.popup("Prompts reset to default!")
                    self.update_terminal_output("AI prompts reset to default values")

                if event == "-TOGGLE_API_KEY-":
                    # Toggle between showing and hiding the API key
                    current_char = self.window["-API_KEY-"].PasswordCharacter
                    if current_char:
                        self.window["-API_KEY-"].update(password_char='')
                    else:
                        self.window["-API_KEY-"].update(password_char='•')
                
                if event == "-UPDATE_API_KEY-":
                    # Update the API key
                    new_key = values["-API_KEY-"]
                    if new_key and not new_key.startswith("••••"):
                        if set_api_key(new_key):
                            sg.popup("API key updated successfully!")
                            self.update_terminal_output("API key updated successfully")
                            # Update the masked display
                            self.window["-API_KEY-"].update("••••••••" + new_key[-4:] if len(new_key) > 4 else new_key)
                            self.window["-API_KEY-"].update(password_char='•')
                        else:
                            sg.popup_error("Failed to update API key!")
                            self.update_terminal_output("ERROR: Failed to update API key", "ERROR")
                
                if event == "Save Settings":
                    # Save all settings
                    config = load_config()
                    
                    # Update OpenAI settings
                    if "openai" not in config:
                        config["openai"] = {}
                    config["openai"]["model"] = values["-OPENAI_MODEL-"]
                    config["openai"]["temperature"] = float(values["-OPENAI_TEMP-"])
                    config["openai"]["max_tokens"] = int(values["-OPENAI_TOKENS-"])
                    
                    # Update Whisper settings
                    if "whisper" not in config:
                        config["whisper"] = {}
                    config["whisper"]["model"] = values["-WHISPER_MODEL-"]
                    config["whisper"]["language"] = values["-WHISPER_LANG-"]
                    
                    # Update processing settings
                    if "processing" not in config:
                        config["processing"] = {}
                    config["processing"]["chunk_size"] = int(values["-CHUNK_SIZE-"]) * 60  # Convert to seconds
                    config["processing"]["max_threads"] = int(values["-MAX_THREADS-"])
                    
                    # Update UI settings
                    if "ui" not in config:
                        config["ui"] = {}
                    config["ui"]["theme"] = values["-UI_THEME-"]
                    
                    # Save config
                    if save_config(config):
                        sg.popup("Settings saved successfully!")
                        self.update_terminal_output("Settings saved successfully")
                        # Inform user that theme changes will take effect after restart
                        if config["ui"]["theme"] != self.config.get("ui", {}).get("theme", "Default Blue"):
                            sg.popup_ok("Theme changes will take effect after restarting the application.")
                    else:
                        sg.popup_error("Failed to save settings!")
                        self.update_terminal_output("ERROR: Failed to save settings", "ERROR")
                
                if event == "-RESET_SETTINGS-":
                    # Reset settings to default
                    if os.path.exists("config.json"):
                        os.remove("config.json")
                    config = load_config()
                    
                    # Update UI elements
                    self.window["-OPENAI_MODEL-"].update(config["openai"]["model"])
                    self.window["-OPENAI_TEMP-"].update(config["openai"]["temperature"])
                    self.window["-OPENAI_TOKENS-"].update(config["openai"]["max_tokens"])
                    self.window["-WHISPER_MODEL-"].update(config["whisper"]["model"])
                    self.window["-WHISPER_LANG-"].update(config["whisper"]["language"])
                    self.window["-CHUNK_SIZE-"].update(config["processing"]["chunk_size"] / 60)
                    self.window["-MAX_THREADS-"].update(config["processing"]["max_threads"])
                    self.window["-UI_THEME-"].update(config["ui"]["theme"])
                    
                    sg.popup("Settings reset to default!")
                    self.update_terminal_output("Settings reset to default values")
                
                if event == "-PREVIEW_THEME-":
                    # Apply the selected theme immediately for preview
                    selected_theme = values["-UI_THEME-"]
                    if apply_theme(selected_theme):
                        # Store current window position and size
                        current_location = self.window.CurrentLocation()
                        current_size = self.window.size
                        
                        # Close current window
                        self.window.close()
                        
                        # Create a new window with the selected theme
                        self.create_window()
                        
                        # Restore position and size
                        self.window.move(*current_location)
                        self.window.size = current_size
                        
                        # Reload data
                        self.load_initial_data()
                        
                        # Update status
                        self.update_terminal_output(f"Theme preview: {selected_theme}", "INFO")
                    else:
                        sg.popup_error(f"Failed to apply theme: {selected_theme}")
                
                # Handle video processing completion event from worker threads
                if event == "-VIDEO_PROCESSING_DONE-":
                    result = values["-VIDEO_PROCESSING_DONE-"]
                    if result.get("success", False):
                        sg.popup_notify("Processing completed", f"Video {result.get('filename', '')} has been processed successfully")
                        
                        # Automatically load and display results after processing
                        if "output_dir" in result:
                            # Update the Results tab directory field
                            self.window["-RESULTS_DIR-"].update(result["output_dir"])
                            # Load the results
                            self.load_video_results(result["output_dir"])
                            
                            # If a specific video folder was processed, select and display it
                            if "video_folder" in result:
                                video_folders = self.window["-VIDEO_LIST-"].get_list_values()
                                for folder in video_folders:
                                    if os.path.basename(folder) == result["video_folder"]:
                                        self.window["-VIDEO_LIST-"].update(set_to_index=[video_folders.index(folder)])
                                        self.display_video_results(folder)
                                        break
                            
                            # Switch to Results tab
                            self.window["-TABGROUP-"].Widget.select(1)
                    else:
                        if "error" in result:
                            sg.popup_error(f"Error processing video: {result['error']}")
                        else:
                            sg.popup_error("Video processing failed - check logs for details")
                
                # Handle terminal update event from worker threads
                if event == "-TERMINAL_UPDATE-":
                    text = values["-TERMINAL_UPDATE-"]["text"]
                    self.window["-TERMINAL_OUTPUT-"].update(self.window["-TERMINAL_OUTPUT-"].get() + text + "\n")
                    if self.window["-AUTOSCROLL-"].get():
                        self.window["-TERMINAL_OUTPUT-"].Widget.see("end")
                    self.window.refresh()
                
                # Handle status update event from worker threads
                if event == "-UPDATE_STATUS-":
                    status = values["-UPDATE_STATUS-"]
                    self.window["-STATUSBAR-"].update(status)
            except Exception as e:
                error_msg = log_exception(logger, e, "Error processing event", self.update_terminal_output)
                self.window["-STATUSBAR-"].update("Error processing event")
