import unittest
import os
import subprocess
import sys

class TestVideoProcessorBackend(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Test videos from the test_videos directory
        cls.test_videos_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'test_videos')
        test_videos = [f for f in os.listdir(cls.test_videos_dir) if f.endswith(('.mp4', '.mov', '.avi', '.mkv'))]
        if not test_videos:
            raise ValueError("No test videos found in test_videos directory")
        cls.test_video = os.path.join(cls.test_videos_dir, test_videos[0])
        cls.test_output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend_test_output')
        if not os.path.exists(cls.test_output_dir):
            os.makedirs(cls.test_output_dir, exist_ok=True)

    def test_single_video_backend(self):
        """Test backend processing for a single video."""
        cmd = [sys.executable, 'video_processor_backend.py', '--videos', self.test_video, '--output', self.test_output_dir]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print(result.stdout)
        self.assertIn("Video processed successfully", result.stdout)

    def test_multithread_video_backend(self):
        """Test backend processing for multiple videos concurrently."""
        cmd = [sys.executable, 'video_processor_backend.py', '--videos', self.test_video, self.test_video, '--output', self.test_output_dir]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print(result.stdout)
        self.assertIn("Processed 2 videos concurrently", result.stdout)

if __name__ == '__main__':
    unittest.main(verbosity=2)
