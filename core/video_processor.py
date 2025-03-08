"""
Core video processing functionality for the Video Processor application.
"""
import os
import json
import subprocess
import logging
import traceback
import threading
from pydub import AudioSegment
import platform
import datetime

from utils.logger import status_queue, log_exception
from utils.config import get_api_key, load_config

# Conditionally import dependencies that might cause issues with PyInstaller
try:
    import whisper
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    logging.warning("Whisper module not available. Transcription features will be disabled.")

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logging.warning("OpenAI module not available. AI content generation features will be disabled.")

try:
    import anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
    logging.warning("Anthropic module not available. Claude features will be disabled.")

# Set up logging in user's documents folder
if platform.system() == 'Windows':
    user_docs = os.path.expanduser('~\\Documents')
    log_dir = os.path.join(user_docs, 'VideoProcessor_Logs')
else:  # macOS or Linux
    user_docs = os.path.expanduser('~/Documents')
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

class VideoProcessor:
    """Class to handle video processing operations"""
    
    def __init__(self, video_path, output_dir, terminal_output_func=None):
        """Initialize the video processor with a video file and output directory"""
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
        self.logger = logging.getLogger("VideoProcessor")
        self.terminal_output = terminal_output_func
        
        # Load configuration
        self.config = load_config()
        
        # Set OpenAI API key from environment variables if OpenAI is available
        if OPENAI_AVAILABLE:
            api_key = get_api_key("OPENAI_API_KEY")
            if api_key:
                openai.api_key = api_key
                self._log("OpenAI API key loaded successfully")
            else:
                self._log("OpenAI API key not found. Some features may not work correctly.", "WARNING")
        else:
            self._log("OpenAI module not available. AI content generation features will be disabled.", "WARNING")
    
    def process_video(self):
        """Process a video file to generate social media content"""
        try:
            # Extract audio from video
            status_queue.put(f"Extracting audio from: {self.video_name}")
            self._log("Extracting audio from video: {self.video_name}")
            self._extract_audio()
            
            # Split audio into chunks
            status_queue.put(f"Splitting audio into chunks: {self.video_name}")
            self._log(f"Splitting audio into chunks: {self.video_name}")
            chunks = self._split_audio()
            
            # Transcribe each chunk
            transcripts = []
            for i, chunk_path in enumerate(chunks):
                status_queue.put(f"Transcribing chunk {i+1}/{len(chunks)} for {self.video_name}")
                self._log(f"Transcribing chunk {i+1}/{len(chunks)}: {os.path.basename(chunk_path)}")
                transcript = self._transcribe_audio(chunk_path)
                transcripts.append(transcript)
            
            # Combine transcripts
            full_transcript = " ".join(transcripts)
            
            # Save transcript
            with open(self.transcript_path, "w", encoding="utf-8") as f:
                f.write(full_transcript)
            self._log(f"Saved transcript to: {self.transcript_path}", "SUCCESS")
            
            # Generate social media content
            status_queue.put(f"Generating social media content for {self.video_name}")
            self._log(f"Generating social media content for: {self.video_name}")
            social_media_content = self._generate_social_media_content(full_transcript)
            
            # Save social media content
            with open(self.social_media_path, "w", encoding="utf-8") as f:
                f.write(social_media_content)
            
            # Save as JSON
            try:
                social_media_json = json.loads(social_media_content)
                with open(self.social_media_json_path, "w", encoding="utf-8") as f:
                    json.dump(social_media_json, f, indent=2, ensure_ascii=False)
                self._log(f"Saved social media content to: {self.social_media_json_path}", "SUCCESS")
            except json.JSONDecodeError:
                # If not valid JSON, save as plain text
                self._log("Social media content is not valid JSON, saving as plain text", "WARNING")
                with open(self.social_media_json_path, "w", encoding="utf-8") as f:
                    f.write(json.dumps({"content": social_media_content}, indent=2, ensure_ascii=False))
            
            status_queue.put(f"Processing completed for {self.video_name}")
            self._log(f"Processing completed for: {self.video_name}", "SUCCESS")
            return True
            
        except Exception as e:
            if self.terminal_output:
                error_msg = log_exception(self.logger, e, f"Error processing video {self.video_name}", self.terminal_output)
            else:
                error_msg = f"Error processing video {self.video_name}: {str(e)}"
                self.logger.error(error_msg)
                self.logger.error(traceback.format_exc())
            
            status_queue.put(f"Error processing {self.video_name}: {str(e)}")
            return False
    
    def _log(self, message, level="INFO"):
        """Log a message to both the logger and terminal output if available"""
        if level == "ERROR":
            self.logger.error(message)
        elif level == "WARNING":
            self.logger.warning(message)
        elif level == "SUCCESS":
            self.logger.info(message)
        else:
            self.logger.info(message)
            
        if self.terminal_output:
            self.terminal_output(message, level)
    
    def _extract_audio(self):
        """Extract audio from video file"""
        try:
            self._log(f"Extracting audio using ffmpeg: {self.video_path}")
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
                self._log(f"FFmpeg error: {stderr}", "ERROR")
                # Try alternative method if primary fails
                self._log("Trying alternative audio extraction method...", "WARNING")
                self._extract_audio_alternative()
            else:
                self._log("Audio extraction completed successfully", "SUCCESS")
                
        except Exception as e:
            if self.terminal_output:
                log_exception(self.logger, e, "Error extracting audio", self.terminal_output)
            else:
                self.logger.error(f"Error extracting audio: {str(e)}")
                self.logger.error(traceback.format_exc())
            
            # Try alternative method
            self._log("Trying alternative audio extraction method...", "WARNING")
            self._extract_audio_alternative()
    
    def _extract_audio_alternative(self):
        """Alternative method to extract audio using moviepy"""
        try:
            self._log("Using moviepy for audio extraction")
            from moviepy.editor import VideoFileClip
            
            video = VideoFileClip(self.video_path)
            audio = video.audio
            audio.write_audiofile(self.audio_path)
            video.close()
            self._log("Alternative audio extraction completed", "SUCCESS")
        except Exception as e:
            if self.terminal_output:
                log_exception(self.logger, e, "Error in alternative audio extraction", self.terminal_output)
            else:
                self.logger.error(f"Error in alternative audio extraction: {str(e)}")
                self.logger.error(traceback.format_exc())
            
            raise RuntimeError("Failed to extract audio using both primary and fallback methods") from e
    
    def _split_audio(self, chunk_length_ms=30000):
        """Split audio file into chunks"""
        try:
            # Load audio file
            audio = AudioSegment.from_wav(self.audio_path)
            
            # Calculate number of chunks
            num_chunks = len(audio) // chunk_length_ms + (1 if len(audio) % chunk_length_ms > 0 else 0)
            
            # Create chunks directory
            chunks_dir = os.path.join(self.output_folder, "chunks")
            os.makedirs(chunks_dir, exist_ok=True)
            
            # Split audio into chunks
            chunks = []
            for i in range(num_chunks):
                start = i * chunk_length_ms
                end = min(start + chunk_length_ms, len(audio))
                chunk = audio[start:end]
                
                # Save chunk
                chunk_path = os.path.join(chunks_dir, f"chunk_{i+1}.wav")
                chunk.export(chunk_path, format="wav")
                chunks.append(chunk_path)
                
                status_queue.put(f"Created chunk {i+1} for {self.video_name}")
                self._log(f"Created chunk {i+1}/{num_chunks}", "INFO")
            
            return chunks
            
        except Exception as e:
            if self.terminal_output:
                log_exception(self.logger, e, "Error splitting audio", self.terminal_output)
            else:
                self.logger.error(f"Error splitting audio: {str(e)}")
                self.logger.error(traceback.format_exc())
            
            raise
    
    def _transcribe_audio(self, audio_path):
        """Transcribe audio using Whisper"""
        try:
            self._log(f"Transcribing audio: {os.path.basename(audio_path)}")
            
            # Check if Whisper is available
            if not WHISPER_AVAILABLE:
                self._log("Whisper module not available. Cannot transcribe audio.", "ERROR")
                return "Transcription failed: Whisper module not available. Please run from source code or reinstall the application."
            
            # Load whisper model based on configuration
            whisper_config = self.config.get("whisper", {})
            model_name = whisper_config.get("model", "base")
            language = whisper_config.get("language", "en")
            
            self._log(f"Loading Whisper model: {model_name}")
            model = whisper.load_model(model_name)
            
            # Transcribe
            self._log("Transcribing audio...")
            result = model.transcribe(audio_path, language=language)
            
            self._log("Transcription completed", "SUCCESS")
            return result["text"]
            
        except Exception as e:
            if self.terminal_output:
                log_exception(self.logger, e, f"Error transcribing audio: {os.path.basename(audio_path)}", self.terminal_output)
            else:
                self.logger.error(f"Error transcribing audio: {str(e)}")
                self.logger.error(traceback.format_exc())
            
            # Return error message on failure
            return f"Transcription failed: {str(e)}"
    
    def _generate_social_media_content(self, transcript):
        """Generate social media content from transcript using OpenAI"""
        try:
            self._log("Generating social media content from transcript")
            
            # Check if transcript is an error message
            if transcript.startswith("Transcription failed:"):
                self._log(f"Cannot generate content: {transcript}", "ERROR")
                return {"error": transcript}
            
            # Check if OpenAI or Anthropic is available
            if not OPENAI_AVAILABLE and not ANTHROPIC_AVAILABLE:
                error_msg = "AI modules not available. Cannot generate social media content."
                self._log(error_msg, "ERROR")
                return {"error": error_msg}
            
            # Check if API key is set
            api_key = get_api_key("OPENAI_API_KEY")
            if not api_key:
                error_msg = "API key not found. Cannot generate social media content."
                self._log(error_msg, "ERROR")
                return {"error": error_msg}
            
            # Set API key if OpenAI is available
            if OPENAI_AVAILABLE:
                openai.api_key = api_key
                self._log("OpenAI API key loaded successfully")
            
            # Load OpenAI configuration
            openai_config = self.config.get("openai", {})
            model = openai_config.get("model", "gpt-4")
            temperature = openai_config.get("temperature", 0.7)
            max_tokens = openai_config.get("max_tokens", 1000)
            
            # Create prompt for social media content
            prompt = """
            Based on the following transcript, generate social media content in JSON format:
            1. A catchy title for YouTube
            2. A description for YouTube (with appropriate hashtags)
            3. Three tweets/posts for Twitter/X
            4. A LinkedIn post
            5. Three short clips suggestions with timestamps (if identifiable)
            
            Format the response as a valid JSON object with these keys: 
            youtube_title, youtube_description, tweets, linkedin_post, clip_suggestions
            
            Transcript:
            """
            
            # Call OpenAI API
            self._log(f"Calling AI API with model: {model}")
            
            # Handle different model types (OpenAI vs Anthropic)
            if model.startswith("claude") and ANTHROPIC_AVAILABLE:
                # Anthropic models
                client = anthropic.Anthropic(api_key=api_key)
                response = client.messages.create(
                    model=model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system="You are a social media content creator assistant.",
                    messages=[
                        {"role": "user", "content": prompt + transcript}
                    ]
                )
                content = response.content[0].text
            else:
                # OpenAI models
                if model in ["gpt-4o", "gpt-4o-mini", "gpt-4.5"]:
                    # Newer OpenAI models use the OpenAI client
                    from openai import OpenAI
                    client = OpenAI(api_key=openai.api_key)
                    response = client.chat.completions.create(
                        model=model,
                        messages=[
                            {"role": "system", "content": "You are a social media content creator assistant."},
                            {"role": "user", "content": prompt + transcript}
                        ],
                        temperature=temperature,
                        max_tokens=max_tokens
                    )
                    content = response.choices[0].message.content
                else:
                    # Legacy OpenAI models
                    response = openai.ChatCompletion.create(
                        model=model,
                        messages=[
                            {"role": "system", "content": "You are a social media content creator assistant."},
                            {"role": "user", "content": prompt + transcript}
                        ],
                        temperature=temperature,
                        max_tokens=max_tokens
                    )
                    content = response.choices[0].message.content
            
            self._log("Social media content generated successfully", "SUCCESS")
            
            return content
            
        except Exception as e:
            if self.terminal_output:
                log_exception(self.logger, e, "Error generating social media content", self.terminal_output)
            else:
                self.logger.error(f"Error generating social media content: {str(e)}")
                self.logger.error(traceback.format_exc())
            
            # Return error message as JSON
            return {"error": f"Failed to generate social media content: {str(e)}"}

def process_videos_multithreaded(video_paths, output_dir, terminal_output_func=None):
    """Process multiple videos concurrently using threading"""
    try:
        # Create a list to store threads
        threads = []
        
        # Create and start a thread for each video
        for video_path in video_paths:
            processor = VideoProcessor(video_path, output_dir, terminal_output_func)
            thread = threading.Thread(target=processor.process_video)
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        return True
        
    except Exception as e:
        logger = logging.getLogger("VideoProcessor")
        if terminal_output_func:
            log_exception(logger, e, "Error in multi-threaded processing", terminal_output_func)
        else:
            logger.error(f"Error in multi-threaded processing: {str(e)}")
            logger.error(traceback.format_exc())
        
        return False
