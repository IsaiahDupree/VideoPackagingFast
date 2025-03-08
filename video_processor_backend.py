import os
import logging
import json
import datetime
import traceback
import threading
import queue
import time
import shutil
import subprocess
import argparse

from moviepy.editor import VideoFileClip
import openai

# Set up logging in user's documents folder
user_docs = os.path.expanduser('~\Documents')
log_dir = os.path.join(user_docs, 'VideoProcessor_Backend_Logs')
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, f'video_processor_backend_{datetime.datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
logger.info(f"Backend application started. Log file: {log_file}")

# Set your OpenAI API key here
openai.api_key = '' # API key should be provided by the user via settings

# Global queue for status updates (if needed)
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
    def __init__(self, video_path, output_dir=None):
        self.video_path = video_path
        self.video_name = os.path.splitext(os.path.basename(video_path))[0]
        self.retries = 3  # Number of retries for operations
        self.retry_delay = 2  # Delay between retries in seconds
        
        # If no output directory specified, use video's directory
        if output_dir is None:
            output_dir = os.path.dirname(video_path)
        
        self.output_dir = os.path.join(output_dir, self.video_name)
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Create temporary directory for processing
        self.temp_dir = os.path.join(self.output_dir, f"temp_{self.video_name}")
        os.makedirs(self.temp_dir, exist_ok=True)
        
        # Load AI prompts
        self.prompts = load_prompts()

    def retry_operation(self, operation, *args, **kwargs):
        """Retry an operation with exponential backoff"""
        for attempt in range(self.retries):
            try:
                return operation(*args, **kwargs)
            except Exception as e:
                if attempt == self.retries - 1:
                    raise
                wait_time = self.retry_delay * (2 ** attempt)
                logger.warning(f"Operation failed, retrying in {wait_time} seconds... Error: {str(e)}")
                time.sleep(wait_time)

    def cleanup_temp_files(self):
        """Remove all temporary files after processing"""
        try:
            if os.path.exists(self.temp_dir):
                shutil.rmtree(self.temp_dir)
        except Exception as e:
            logger.error(f"Error cleaning up temporary files: {str(e)}")

    def _extract_audio(self):
        status_queue.put(f"Extracting audio from: {self.video_name}")
        audio_path = os.path.join(self.temp_dir, f"{self.video_name}.wav")
        try:
            clip = VideoFileClip(self.video_path)
            clip.audio.write_audiofile(audio_path)
            clip.close()
        except Exception as e:
            logger.warning(f"MoviePy failed: {str(e)}, trying ffmpeg...")
            subprocess.run([
                'ffmpeg', '-i', self.video_path,
                '-vn', '-acodec', 'pcm_s16le',
                '-ar', '44100', '-ac', '2', '-y',
                audio_path
            ], check=True, capture_output=True, text=True)
        return audio_path

    def extract_audio(self):
        return self.retry_operation(self._extract_audio)

    def split_audio(self, audio_path, chunk_duration=60):
        status_queue.put(f"Splitting audio into chunks: {self.video_name}")
        from pydub import AudioSegment
        audio = AudioSegment.from_file(audio_path)
        chunks = []
        for i in range(0, len(audio), chunk_duration * 1000):
            chunk = audio[i:i + chunk_duration * 1000]
            chunk_filename = os.path.join(self.temp_dir, f"chunk_{i//1000}.wav")
            chunk.export(chunk_filename, format="wav")
            chunks.append(chunk_filename)
            status_queue.put(f"Created chunk {len(chunks)} for {self.video_name}")
        return chunks

    def transcribe_video(self):
        audio_path = self.extract_audio()
        chunks = self.split_audio(audio_path)
        full_transcript = ""
        for i, chunk_file in enumerate(chunks):
            status_queue.put(f"Transcribing chunk {i+1}/{len(chunks)} for {self.video_name}")
            try:
                with open(chunk_file, "rb") as audio_file:
                    transcript = openai.Audio.transcribe("whisper-1", audio_file, request_timeout=15)
                full_transcript += transcript["text"] + " "
            except Exception as e:
                logger.error(f"Error transcribing chunk {i+1}: {str(e)}")
                continue
            finally:
                time.sleep(0.5)
                try:
                    os.remove(chunk_file)
                except Exception as e:
                    logger.error(f"Error removing chunk file {chunk_file}: {str(e)}")
        try:
            os.remove(audio_path)
        except Exception as e:
            logger.error(f"Error removing audio file {audio_path}: {str(e)}")
        return full_transcript.strip()

    def generate_social_media_content(self, transcript):
        messages = [
            {"role": "system", "content": self.prompts["system_prompt"]},
            {"role": "user", "content": self.prompts["content_generation_prompt"].format(transcript=transcript)}
        ]
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=messages,
                request_timeout=30
            )
            # Assuming response has simplified output for backend
            content = response.choices[0].message.content
            # For simplicity, wrap the content in a dict
            return json.loads(content) if content.strip().startswith('{') else {"generated_content": content}
        except Exception as e:
            logger.error(f"Error generating social media content: {str(e)}")
            return {"error": str(e)}

    def save_outputs(self, transcript, social_content):
        try:
            transcript_file = os.path.join(self.output_dir, "transcript.txt")
            with open(transcript_file, 'w', encoding='utf-8') as f:
                f.write(transcript)
            social_file = os.path.join(self.output_dir, "social_media.txt")
            with open(social_file, 'w', encoding='utf-8') as f:
                f.write(str(social_content))
            json_file = os.path.join(self.output_dir, "social_media.json")
            with open(json_file, 'w', encoding='utf-8') as f:
                json.dump({"source_info": self.video_name, "content": social_content}, f, indent=4)
            return True
        except Exception as e:
            logger.error(f"Error saving outputs: {str(e)}")
            return False

    def process_video(self):
        try:
            transcript = self.transcribe_video()
            if not transcript:
                return False
            social_content = self.generate_social_media_content(transcript)
            if not social_content or "error" in social_content:
                logger.error(f"Failed to generate social media content: {social_content.get('message', 'Unknown error')}")
                return False
            self.save_outputs(transcript, social_content)
            self.cleanup_temp_files()
            return True
        except Exception as e:
            logger.error(f"Error processing video {self.video_name}: {str(e)}")
            logger.error(traceback.format_exc())
            return False


def process_videos_multithreaded(video_paths, output_dir):
    """Process multiple videos concurrently using threads"""
    threads = []
    for video in video_paths:
        processor = VideoProcessor(video, output_dir)
        t = threading.Thread(target=processor.process_video)
        t.start()
        threads.append(t)
    for t in threads:
        t.join()


def main():
    parser = argparse.ArgumentParser(description='Backend Video Processor')
    parser.add_argument('--videos', nargs='+', help='List of video file paths', required=True)
    parser.add_argument('--output', help='Output directory', default=None)
    args = parser.parse_args()

    video_paths = args.videos
    output_dir = args.output if args.output else os.path.dirname(video_paths[0])

    if len(video_paths) > 1:
        process_videos_multithreaded(video_paths, output_dir)
        print(f"Processed {len(video_paths)} videos concurrently.")
    else:
        processor = VideoProcessor(video_paths[0], output_dir)
        result = processor.process_video()
        if result:
            print("Video processed successfully.")
        else:
            print("Video processing failed.")


if __name__ == '__main__':
    main()
