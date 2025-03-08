import os
import PySimpleGUI as sg
from moviepy.editor import VideoFileClip
import openai
import logging
import json
import datetime
import traceback
import threading
import queue
import time
import shutil
import subprocess
import sys

# Set up logging in user's documents folder
user_docs = os.path.expanduser('~\\Documents')
log_dir = os.path.join(user_docs, 'VideoProcessor_Logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, f'video_processor_{datetime.datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
logger.info(f"Application started. Log file: {log_file}")

# Set your OpenAI API key here
openai.api_key = '' # API key should be provided by the user via settings

# Global queue for status updates
status_queue = queue.Queue()

# Load AI prompts from file
def load_prompts():
    try:
        with open('ai_prompts.json', 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading prompts: {str(e)}")
        return {
            "system_prompt": "You are an expert social media content creator specializing in platform-specific content optimization.",
            "content_generation_prompt": "Based on this video transcript, generate optimized social media content."
        }

def save_prompts(prompts):
    try:
        with open('ai_prompts.json', 'w', encoding='utf-8') as f:
            json.dump(prompts, f, indent=4)
        return True
    except Exception as e:
        logger.error(f"Error saving prompts: {str(e)}")
        return False

class VideoProcessor:
    def __init__(self, video_path, output_dir):
        self.video_path = video_path
        self.output_dir = output_dir
        self.video_name = os.path.splitext(os.path.basename(video_path))[0]
        self.output_folder = os.path.join(output_dir, self.video_name)
        self.audio_path = os.path.join(self.output_folder, "audio.wav")
        self.transcript_path = os.path.join(self.output_folder, "transcript.txt")
        self.social_media_path = os.path.join(self.output_folder, "social_media.txt")
        self.social_media_json_path = os.path.join(self.output_folder, "social_media.json")
        
        # Create output folder if it doesn't exist
        os.makedirs(self.output_folder, exist_ok=True)
        
        # Initialize logger
        self.logger = logging.getLogger(__name__)
        
        # Set retry parameters
        self.max_retries = 3
        self.retry_delay = 2  # seconds
        
        # Create backup directory for recovery
        self.backup_dir = os.path.join(self.output_folder, "backups")
        os.makedirs(self.backup_dir, exist_ok=True)
        
        # Track processing state for recovery
        self.processing_state = {
            "audio_extracted": False,
            "audio_split": False,
            "transcription_complete": False,
            "social_media_generated": False
        }
        self.state_file = os.path.join(self.output_folder, "processing_state.json")
        self._load_processing_state()
    
    def _load_processing_state(self):
        """Load processing state from file if it exists"""
        try:
            from utils.file_ops import safe_read_json
            saved_state = safe_read_json(self.state_file, default={})
            if saved_state:
                self.processing_state.update(saved_state)
                self.logger.info(f"Loaded processing state: {self.processing_state}")
        except Exception as e:
            self.logger.error(f"Error loading processing state: {str(e)}")
    
    def _save_processing_state(self):
        """Save current processing state to file"""
        try:
            from utils.file_ops import safe_write_json
            safe_write_json(self.state_file, self.processing_state)
        except Exception as e:
            self.logger.error(f"Error saving processing state: {str(e)}")
    
    def process_video(self):
        """Process a video file to generate social media content with recovery capability"""
        try:
            # Validate video file
            from utils.file_ops import is_valid_video_file
            if not is_valid_video_file(self.video_path):
                error_msg = f"Invalid video file: {self.video_path}"
                status_queue.put(error_msg)
                update_terminal_output(error_msg, "ERROR")
                return False
            
            # Extract audio from video (with recovery)
            if not self.processing_state.get("audio_extracted", False):
                status_queue.put(f"Extracting audio from: {self.video_name}")
                update_terminal_output(f"Extracting audio from video: {self.video_name}")
                success = self._extract_audio_with_retry()
                if not success:
                    return False
                self.processing_state["audio_extracted"] = True
                self._save_processing_state()
            else:
                update_terminal_output(f"Audio already extracted for: {self.video_name}", "INFO")
            
            # Split audio into chunks (with recovery)
            if not self.processing_state.get("audio_split", False):
                status_queue.put(f"Splitting audio into chunks: {self.video_name}")
                update_terminal_output(f"Splitting audio into chunks: {self.video_name}")
                chunks = self._split_audio_with_retry()
                if not chunks:
                    return False
                self.processing_state["audio_split"] = True
                self.processing_state["chunks"] = chunks
                self._save_processing_state()
            else:
                chunks = self.processing_state.get("chunks", [])
                if not chunks:
                    # If we don't have chunks stored, try to split again
                    chunks = self._split_audio_with_retry()
                    if not chunks:
                        return False
                update_terminal_output(f"Using {len(chunks)} previously split audio chunks", "INFO")
            
            # Transcribe each chunk (with recovery)
            if not self.processing_state.get("transcription_complete", False):
                transcripts = []
                for i, chunk_path in enumerate(chunks):
                    status_queue.put(f"Transcribing chunk {i+1}/{len(chunks)} for {self.video_name}")
                    update_terminal_output(f"Transcribing chunk {i+1}/{len(chunks)}: {os.path.basename(chunk_path)}")
                    
                    # Check if we already have this chunk transcribed
                    chunk_key = f"transcript_chunk_{i}"
                    if chunk_key in self.processing_state:
                        transcript = self.processing_state[chunk_key]
                        update_terminal_output(f"Using cached transcription for chunk {i+1}", "INFO")
                    else:
                        transcript = self._transcribe_audio_with_retry(chunk_path)
                        if not transcript:
                            # If transcription fails, try alternative method
                            update_terminal_output(f"Trying alternative transcription method for chunk {i+1}", "WARNING")
                            transcript = self._transcribe_audio_alternative(chunk_path)
                        
                        if transcript:
                            self.processing_state[chunk_key] = transcript
                            self._save_processing_state()
                        else:
                            update_terminal_output(f"Failed to transcribe chunk {i+1}", "ERROR")
                            # Continue with other chunks instead of failing completely
                            transcript = "[Transcription failed for this segment]"
                    
                    transcripts.append(transcript)
                
                # Combine transcripts
                full_transcript = " ".join(transcripts)
                
                # Save transcript
                with open(self.transcript_path, "w", encoding="utf-8") as f:
                    f.write(full_transcript)
                update_terminal_output(f"Saved transcript to: {self.transcript_path}", "SUCCESS")
                
                self.processing_state["transcription_complete"] = True
                self.processing_state["full_transcript"] = full_transcript
                self._save_processing_state()
            else:
                # Use cached transcript
                full_transcript = self.processing_state.get("full_transcript", "")
                if not full_transcript and os.path.exists(self.transcript_path):
                    with open(self.transcript_path, "r", encoding="utf-8") as f:
                        full_transcript = f.read()
                    self.processing_state["full_transcript"] = full_transcript
                    self._save_processing_state()
                
                update_terminal_output(f"Using cached transcript for: {self.video_name}", "INFO")
            
            # Generate social media content (with recovery)
            if not self.processing_state.get("social_media_generated", False):
                status_queue.put(f"Generating social media content for {self.video_name}")
                update_terminal_output(f"Generating social media content for: {self.video_name}")
                social_media_content = self._generate_social_media_content_with_retry(full_transcript)
                if not social_media_content:
                    return False
                
                # Save social media content
                with open(self.social_media_path, "w", encoding="utf-8") as f:
                    f.write(social_media_content)
                
                # Save as JSON
                try:
                    social_media_json = json.loads(social_media_content)
                    with open(self.social_media_json_path, "w", encoding="utf-8") as f:
                        json.dump(social_media_json, f, indent=2, ensure_ascii=False)
                    update_terminal_output(f"Saved social media content to: {self.social_media_json_path}", "SUCCESS")
                except json.JSONDecodeError:
                    # If not valid JSON, save as plain text
                    update_terminal_output("Social media content is not valid JSON, saving as plain text", "WARNING")
                    with open(self.social_media_json_path, "w", encoding="utf-8") as f:
                        f.write(json.dumps({"content": social_media_content}, indent=2, ensure_ascii=False))
                
                self.processing_state["social_media_generated"] = True
                self._save_processing_state()
            else:
                update_terminal_output(f"Using cached social media content for: {self.video_name}", "INFO")
            
            status_queue.put(f"Processing completed for {self.video_name}")
            update_terminal_output(f"Processing completed for: {self.video_name}", "SUCCESS")
            return True
            
        except Exception as e:
            error_msg = log_exception(e, f"Error processing video {self.video_name}")
            status_queue.put(f"Error processing {self.video_name}: {str(e)}")
            return False
    
    def _extract_audio_with_retry(self):
        """Extract audio with automatic retry"""
        for attempt in range(self.max_retries):
            try:
                success = self._extract_audio()
                if success:
                    return True
                
                # If primary method fails, try alternative method
                if attempt == self.max_retries - 1:
                    update_terminal_output("Primary audio extraction failed, trying alternative method", "WARNING")
                    return self._extract_audio_alternative()
                
                update_terminal_output(f"Audio extraction failed, retrying ({attempt+1}/{self.max_retries})", "WARNING")
                time.sleep(self.retry_delay * (attempt + 1))  # Exponential backoff
            except Exception as e:
                log_exception(e, "Error in audio extraction")
                if attempt < self.max_retries - 1:
                    update_terminal_output(f"Audio extraction error, retrying ({attempt+1}/{self.max_retries})", "WARNING")
                    time.sleep(self.retry_delay * (attempt + 1))
                else:
                    update_terminal_output("All audio extraction attempts failed, trying alternative method", "WARNING")
                    return self._extract_audio_alternative()
        return False
    
    def _extract_audio(self):
        """Extract audio from video file using ffmpeg"""
        try:
            update_terminal_output(f"Extracting audio using ffmpeg: {self.video_path}")
            # Create the output directory if it doesn't exist
            os.makedirs(os.path.dirname(self.audio_path), exist_ok=True)
            
            # Command to extract audio
            command = [
                "ffmpeg", "-i", self.video_path, 
                "-vn", "-acodec", "pcm_s16le", 
                "-ar", "44100", "-ac", "1", 
                self.audio_path, "-y"
            ]
            
            # Run the command
            process = subprocess.Popen(
                command, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate()
            
            if process.returncode != 0:
                update_terminal_output(f"FFmpeg error: {stderr}", "ERROR")
                return False
            
            # Verify the audio file was created
            if not os.path.exists(self.audio_path) or os.path.getsize(self.audio_path) == 0:
                update_terminal_output("Audio extraction failed: Output file is empty or doesn't exist", "ERROR")
                return False
                
            update_terminal_output(f"Audio extracted successfully: {self.audio_path}", "SUCCESS")
            return True
            
        except Exception as e:
            log_exception(e, "Error extracting audio with ffmpeg")
            return False
    
    def _extract_audio_alternative(self):
        """Alternative method to extract audio using moviepy"""
        try:
            update_terminal_output("Trying alternative audio extraction with moviepy", "INFO")
            from moviepy.editor import VideoFileClip
            
            # Create the output directory if it doesn't exist
            os.makedirs(os.path.dirname(self.audio_path), exist_ok=True)
            
            # Extract audio using moviepy
            video = VideoFileClip(self.video_path)
            audio = video.audio
            audio.write_audiofile(self.audio_path, fps=44100, nbytes=2, codec='pcm_s16le')
            video.close()
            
            # Verify the audio file was created
            if not os.path.exists(self.audio_path) or os.path.getsize(self.audio_path) == 0:
                update_terminal_output("Alternative audio extraction failed", "ERROR")
                return False
                
            update_terminal_output(f"Audio extracted successfully using alternative method: {self.audio_path}", "SUCCESS")
            return True
            
        except Exception as e:
            log_exception(e, "Error in alternative audio extraction")
            return False

# ... rest of the code remains the same ...
