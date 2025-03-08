import unittest
import os
import shutil
import json
from video_processor import VideoProcessor, process_videos_multithreaded

class TestVideoProcessor(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Test videos from the test_videos directory
        cls.test_videos_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'test_videos')
        test_videos = [f for f in os.listdir(cls.test_videos_dir) if f.endswith(('.mp4', '.mov', '.avi', '.mkv'))]
        
        if not test_videos:
            raise ValueError("No test videos found in test_videos directory")
        
        cls.test_video = os.path.join(cls.test_videos_dir, test_videos[0])
        print(f"Using test video: {cls.test_video}")
        
        # Create test output directory
        cls.test_output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'test_output')
        os.makedirs(cls.test_output_dir, exist_ok=True)
        
        # Create VideoProcessor instance
        cls.processor = VideoProcessor(cls.test_video, cls.test_output_dir)

    def setUp(self):
        # Clean the test output directory before each test
        if os.path.exists(self.test_output_dir):
            for file in os.listdir(self.test_output_dir):
                file_path = os.path.join(self.test_output_dir, file)
                try:
                    if os.path.isfile(file_path):
                        os.unlink(file_path)
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path)
                except Exception as e:
                    print(f"Error: {e}")

    def test_1_extract_audio(self):
        """Test audio extraction from video"""
        print("\nTesting audio extraction...")
        audio_path = self.processor.extract_audio()
        self.assertTrue(os.path.exists(audio_path))
        self.assertTrue(os.path.getsize(audio_path) > 0)
        print(f"Audio extraction successful! Audio saved to: {audio_path}")

    def test_2_split_audio(self):
        """Test audio splitting into chunks"""
        print("\nTesting audio splitting...")
        # First extract audio
        audio_path = self.processor.extract_audio()
        
        # Then split it
        chunks = self.processor.split_audio(audio_path, chunk_duration=30)  # Using smaller chunks for testing
        self.assertTrue(len(chunks) > 0)
        for chunk in chunks:
            self.assertTrue(os.path.exists(chunk))
            self.assertTrue(os.path.getsize(chunk) > 0)
        print(f"Audio splitting successful! Created {len(chunks)} chunks")
        
        # Clean up chunks
        for chunk in chunks:
            if os.path.exists(chunk):
                os.remove(chunk)

    def test_3_transcribe_video(self):
        """Test full video transcription"""
        print("\nTesting full video transcription...")
        transcript = self.processor.transcribe_video()
        self.assertIsInstance(transcript, str)
        self.assertTrue(len(transcript) > 0)
        print("Full transcription successful!")
        print(f"Sample transcript: {transcript[:200]}...")
        
        # Save transcript for subsequent tests
        self.transcript = transcript
        return transcript

    def test_4_social_media_content(self):
        """Test social media content generation"""
        print("\nTesting social media content generation...")
        # Get transcript from previous test or generate a new one
        transcript = getattr(self, 'transcript', None)
        if not transcript:
            transcript = self.test_3_transcribe_video()
        
        # Generate content
        content = self.processor.generate_social_media_content(transcript)
        self.assertIsInstance(content, dict)
        self.assertNotIn("error", content)
        
        # Verify required fields exist
        self.assertIn("youtube", content)
        self.assertIn("tiktok", content)
        self.assertIn("instagram", content)
        self.assertIn("twitter", content)
        self.assertIn("snapchat", content)
        
        print("Social media content generation successful!")
        print(f"Sample content: {json.dumps(content['youtube'], indent=2)}")
        
        # Save content for subsequent tests
        self.social_content = content
        return content

    def test_5_save_outputs(self):
        """Test saving outputs to files"""
        print("\nTesting saving outputs...")
        # Get content from previous tests or generate new content
        transcript = getattr(self, 'transcript', None)
        social_content = getattr(self, 'social_content', None)
        
        if not transcript:
            transcript = self.test_3_transcribe_video()
        if not social_content:
            social_content = self.test_4_social_media_content()
        
        # Save outputs
        self.processor.save_outputs(transcript, social_content)
        
        # Verify files were created
        transcript_file = os.path.join(self.processor.output_dir, "transcript.txt")
        social_file = os.path.join(self.processor.output_dir, "social_media.txt")
        json_file = os.path.join(self.processor.output_dir, "social_media.json")
        
        self.assertTrue(os.path.exists(transcript_file))
        self.assertTrue(os.path.exists(social_file))
        self.assertTrue(os.path.exists(json_file))
        
        # Verify file contents
        with open(transcript_file, 'r', encoding='utf-8') as f:
            content = f.read()
            self.assertIn(transcript, content)
        
        with open(json_file, 'r', encoding='utf-8') as f:
            content = json.load(f)
            self.assertIn("source_info", content)
            self.assertIn("content", content)
        
        print("Outputs successfully saved!")

    def test_6_full_process(self):
        """Test the entire video processing workflow"""
        print("\nTesting full video processing workflow...")
        result = self.processor.process_video()
        self.assertTrue(result)
        
        # Verify output files
        transcript_file = os.path.join(self.processor.output_dir, "transcript.txt")
        social_file = os.path.join(self.processor.output_dir, "social_media.txt")
        json_file = os.path.join(self.processor.output_dir, "social_media.json")
        
        self.assertTrue(os.path.exists(transcript_file))
        self.assertTrue(os.path.exists(social_file))
        self.assertTrue(os.path.exists(json_file))
        
        print("Full video processing workflow completed successfully!")

    def test_7_multithread_processing(self):
        """Test concurrent processing of multiple videos."""
        # Simulate using the same video twice for multi-threaded processing
        video_list = [self.test_video, self.test_video]
        process_videos_multithreaded(video_list, self.test_output_dir)
        
        # Verify expected output files in each video's output directory
        for video in video_list:
            video_name = os.path.splitext(os.path.basename(video))[0]
            output_folder = os.path.join(self.test_output_dir, video_name)
            transcript_file = os.path.join(output_folder, "transcript.txt")
            self.assertTrue(os.path.exists(transcript_file), f"Transcript file not found for {video_name}")
        print("Multithreaded processing test completed successfully!")

    @classmethod
    def tearDownClass(cls):
        # Clean up test directory
        if os.path.exists(cls.test_output_dir):
            shutil.rmtree(cls.test_output_dir)
        print("\nTest cleanup completed.")

if __name__ == '__main__':
    unittest.main(verbosity=2)
