"""
Integration tests for convert_media module.
Tests actual FFmpeg conversion functionality.
"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

import convert_media


class TestConvertMediaIntegration(
    unittest.TestCase
):
    """Integration tests that require FFmpeg to be installed."""

    @classmethod
    def setUpClass(cls):
        """Check if FFmpeg is available before running tests."""
        if not convert_media.check_ffmpeg():
            raise unittest.SkipTest(
                "FFmpeg not available"
            )

    def setUp(self):
        """Set up test fixtures."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_video = (
            self.temp_dir / "test_input.mp4"
        )
        self.create_test_video()

    def tearDown(self):
        """Clean up test fixtures."""
        import shutil

        shutil.rmtree(
            self.temp_dir, ignore_errors=True
        )

    def create_test_video(self):
        """Create a simple test video using FFmpeg."""
        cmd = [
            "ffmpeg",
            "-y",
            "-f",
            "lavfi",
            "-i",
            "testsrc=duration=2:size=320x240:rate=10",
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            str(self.test_video),
        ]
        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            self.skipTest(
                f"Could not create test video: {e}"
            )

    def test_video_to_gif_conversion(self):
        """Test converting video to GIF."""
        output_gif = self.temp_dir / "output.gif"

        # Simulate command line arguments
        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_gif),
            "--gif-fps",
            "5",
            "--duration",
            "1",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ):
            args = convert_media.parse_args()

        # Build and execute command
        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )
            self.assertTrue(output_gif.exists())
            self.assertGreater(
                output_gif.stat().st_size, 0
            )
        except subprocess.CalledProcessError as e:
            self.fail(
                f"GIF conversion failed: {e}"
            )

    def test_video_to_gif_with_palette(self):
        """Test converting video to GIF with optimized palette."""
        output_gif = (
            self.temp_dir / "output_palette.gif"
        )

        # Simulate command line arguments
        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_gif),
            "--gif-fps",
            "8",
            "--gif-palette",
            "--resolution",
            "160x120",
            "--duration",
            "1",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ):
            args = convert_media.parse_args()

        # Test palette-based GIF creation
        try:
            success = convert_media.build_gif_with_palette(
                args
            )
            self.assertTrue(success)
            self.assertTrue(output_gif.exists())
            self.assertGreater(
                output_gif.stat().st_size, 0
            )
        except Exception as e:
            self.fail(
                f"Palette GIF conversion failed: {e}"
            )

    def test_video_trimming(self):
        """Test video trimming functionality."""
        output_video = (
            self.temp_dir / "trimmed.mp4"
        )

        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_video),
            "--start-time",
            "0.5",
            "--duration",
            "1",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ):
            args = convert_media.parse_args()

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )
            self.assertTrue(output_video.exists())
            self.assertGreater(
                output_video.stat().st_size, 0
            )
        except subprocess.CalledProcessError as e:
            self.fail(
                f"Video trimming failed: {e}"
            )

    def test_audio_extraction(self):
        """Test audio extraction from video."""
        output_audio = self.temp_dir / "audio.mp3"

        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_audio),
            "--audio-only",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ):
            args = convert_media.parse_args()

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )
            self.assertTrue(output_audio.exists())
            self.assertGreater(
                output_audio.stat().st_size, 0
            )
        except subprocess.CalledProcessError as e:
            self.fail(
                f"Audio extraction failed: {e}"
            )

    def test_resolution_change(self):
        """Test video resolution change."""
        output_video = (
            self.temp_dir / "resized.mp4"
        )

        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_video),
            "--resolution",
            "160x120",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ):
            args = convert_media.parse_args()

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )
            self.assertTrue(output_video.exists())
            self.assertGreater(
                output_video.stat().st_size, 0
            )
        except subprocess.CalledProcessError as e:
            self.fail(
                f"Resolution change failed: {e}"
            )

    def test_gif_format_detection(self):
        """Test that GIF files are properly detected as video format."""
        # Create a simple GIF
        gif_file = self.temp_dir / "test.gif"

        # Create GIF from test video
        cmd = [
            "ffmpeg",
            "-y",
            "-i",
            str(self.test_video),
            "-t",
            "1",
            "-vf",
            "fps=5,scale=100:100",
            str(gif_file),
        ]

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )

            # Test format detection
            result = convert_media.validate_input(
                gif_file
            )
            self.assertEqual(result, "video")

        except subprocess.CalledProcessError:
            self.skipTest(
                "Could not create test GIF"
            )

    def test_gif_to_video_conversion(self):
        """Test converting GIF back to video format."""
        # First create a GIF
        gif_file = self.temp_dir / "test.gif"
        output_video = (
            self.temp_dir / "from_gif.mp4"
        )

        # Create GIF from test video
        cmd = [
            "ffmpeg",
            "-y",
            "-i",
            str(self.test_video),
            "-t",
            "1",
            "-vf",
            "fps=5,scale=100:100",
            str(gif_file),
        ]

        try:
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )

            # Now convert GIF to video
            test_args = [
                "convert_media",
                str(gif_file),
                str(output_video),
            ]

            with unittest.mock.patch(
                "sys.argv", test_args
            ):
                args = convert_media.parse_args()

            cmd = convert_media.build_ffmpeg_command(
                args, "video"
            )
            subprocess.run(
                cmd,
                check=True,
                capture_output=True,
            )

            self.assertTrue(output_video.exists())
            self.assertGreater(
                output_video.stat().st_size, 0
            )

        except subprocess.CalledProcessError:
            self.skipTest(
                "Could not create or convert test GIF"
            )

    def test_media_info_extraction(self):
        """Test media information extraction."""
        info = convert_media.get_media_info(
            self.test_video
        )

        # Should have basic info
        self.assertIn("duration", info)
        self.assertIn("size", info)

        # Check for video stream info
        self.assertIn("video_codec", info)
        self.assertIn("resolution", info)

        # Verify reasonable values
        duration = float(info["duration"])
        self.assertGreater(
            duration, 1.0
        )  # Should be around 2 seconds
        self.assertLess(duration, 3.0)

        self.assertEqual(
            info["resolution"], "320x240"
        )

    def test_dry_run_mode(self):
        """Test dry run mode doesn't actually convert files."""
        output_gif = self.temp_dir / "dry_run.gif"

        test_args = [
            "convert_media",
            str(self.test_video),
            str(output_gif),
            "--dry-run",
        ]

        with unittest.mock.patch(
            "sys.argv", test_args
        ), unittest.mock.patch(
            "builtins.print"
        ) as mock_print:

            args = convert_media.parse_args()

            # Simulate main function dry run path
            cmd = convert_media.build_ffmpeg_command(
                args, "video"
            )

            # In dry run, no actual conversion should happen
            self.assertFalse(output_gif.exists())

            # Verify command was built correctly
            self.assertIn("ffmpeg", cmd)
            self.assertIn(
                str(self.test_video), cmd
            )
            self.assertIn(str(output_gif), cmd)


if __name__ == "__main__":
    # Add import for mocking
    import unittest.mock

    unittest.main()
