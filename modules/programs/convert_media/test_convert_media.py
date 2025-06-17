"""
Unit tests for convert_media module.
"""

import argparse
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch, call

import convert_media


class TestConvertMedia(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.input_file = (
            self.temp_dir / "input.mp4"
        )
        self.output_file = (
            self.temp_dir / "output.gif"
        )

        # Create dummy input file
        self.input_file.touch()

    def tearDown(self):
        """Clean up test fixtures."""
        import shutil

        shutil.rmtree(
            self.temp_dir, ignore_errors=True
        )

    def test_supported_formats(self):
        """Test that all expected formats are supported."""
        expected_video = {
            "mp4",
            "avi",
            "mov",
            "mkv",
            "webm",
            "flv",
            "wmv",
            "m4v",
            "3gp",
            "ogv",
            "gif",
        }
        expected_audio = {
            "mp3",
            "wav",
            "flac",
            "aac",
            "ogg",
            "wma",
            "m4a",
            "opus",
            "ac3",
            "aiff",
        }

        self.assertEqual(
            convert_media.SUPPORTED_VIDEO_FORMATS,
            expected_video,
        )
        self.assertEqual(
            convert_media.SUPPORTED_AUDIO_FORMATS,
            expected_audio,
        )

    def test_gif_codec_mapping(self):
        """Test that GIF has correct codec mapping."""
        self.assertIn(
            "gif", convert_media.VIDEO_CODECS
        )
        self.assertEqual(
            convert_media.VIDEO_CODECS["gif"],
            "gif",
        )

    def test_parse_args_basic(self):
        """Test basic argument parsing."""
        with patch(
            "sys.argv",
            [
                "convert_media",
                "input.mp4",
                "output.gif",
            ],
        ):
            args = convert_media.parse_args()
            self.assertEqual(
                args.input_path, Path("input.mp4")
            )
            self.assertEqual(
                args.output_path,
                Path("output.gif"),
            )
            self.assertEqual(
                args.quality, "medium"
            )
            self.assertEqual(args.gif_fps, 10.0)
            self.assertEqual(args.gif_loop, 0)
            self.assertFalse(args.gif_palette)

    def test_parse_args_gif_options(self):
        """Test GIF-specific argument parsing."""
        test_args = [
            "convert_media",
            "input.mp4",
            "output.gif",
            "--gif-fps",
            "15",
            "--gif-palette",
            "--gif-loop",
            "3",
        ]
        with patch("sys.argv", test_args):
            args = convert_media.parse_args()
            self.assertEqual(args.gif_fps, 15.0)
            self.assertTrue(args.gif_palette)
            self.assertEqual(args.gif_loop, 3)

    @patch("convert_media.subprocess.run")
    def test_check_ffmpeg_available(
        self, mock_run
    ):
        """Test FFmpeg availability check when available."""
        mock_run.return_value = Mock(returncode=0)
        result = convert_media.check_ffmpeg()
        self.assertTrue(result)
        mock_run.assert_called_once_with(
            ["ffmpeg", "-version"],
            capture_output=True,
            check=True,
        )

    @patch("convert_media.subprocess.run")
    def test_check_ffmpeg_not_available(
        self, mock_run
    ):
        """Test FFmpeg availability check when not available."""
        mock_run.side_effect = FileNotFoundError()
        with patch(
            "builtins.print"
        ) as mock_print:
            result = convert_media.check_ffmpeg()
            self.assertFalse(result)
            mock_print.assert_called()

    def test_validate_input_video_file(self):
        """Test input validation for video files."""
        video_file = self.temp_dir / "test.mp4"
        video_file.touch()

        result = convert_media.validate_input(
            video_file
        )
        self.assertEqual(result, "video")

    def test_validate_input_audio_file(self):
        """Test input validation for audio files."""
        audio_file = self.temp_dir / "test.mp3"
        audio_file.touch()

        result = convert_media.validate_input(
            audio_file
        )
        self.assertEqual(result, "audio")

    def test_validate_input_gif_file(self):
        """Test input validation for GIF files."""
        gif_file = self.temp_dir / "test.gif"
        gif_file.touch()

        result = convert_media.validate_input(
            gif_file
        )
        self.assertEqual(result, "video")

    def test_validate_input_nonexistent_file(
        self,
    ):
        """Test input validation for nonexistent files."""
        nonexistent = (
            self.temp_dir / "nonexistent.mp4"
        )

        with patch("builtins.print"), patch(
            "sys.exit"
        ) as mock_exit:
            convert_media.validate_input(
                nonexistent
            )
            mock_exit.assert_called_with(1)

    def test_get_quality_settings_video_low(self):
        """Test quality settings for low video quality."""
        settings = (
            convert_media.get_quality_settings(
                "low", "video"
            )
        )
        expected = {"crf": "28", "preset": "fast"}
        self.assertEqual(settings, expected)

    def test_get_quality_settings_video_high(
        self,
    ):
        """Test quality settings for high video quality."""
        settings = (
            convert_media.get_quality_settings(
                "high", "video"
            )
        )
        expected = {"crf": "18", "preset": "slow"}
        self.assertEqual(settings, expected)

    def test_get_quality_settings_audio_medium(
        self,
    ):
        """Test quality settings for medium audio quality."""
        settings = (
            convert_media.get_quality_settings(
                "medium", "audio"
            )
        )
        expected = {"ab": "192k"}
        self.assertEqual(settings, expected)

    def test_build_ffmpeg_command_basic(self):
        """Test basic FFmpeg command building."""
        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.avi"),
            quality="medium",
            resolution=None,
            framerate=None,
            bitrate=None,
            start_time=None,
            duration=None,
            audio_only=False,
            video_only=False,
            codec=None,
            preset="medium",
            crf=None,
            custom_args=None,
            overwrite=False,
            verbose=False,
            gif_fps=10.0,
            gif_palette=False,
            gif_loop=0,
        )

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        expected_start = [
            "ffmpeg",
            "-loglevel",
            "error",
            "-i",
            "input.mp4",
        ]
        self.assertEqual(cmd[:5], expected_start)
        self.assertIn("output.avi", cmd)
        self.assertIn("-vcodec", cmd)
        self.assertIn("libx264", cmd)

    def test_build_ffmpeg_command_gif_no_palette(
        self,
    ):
        """Test FFmpeg command building for GIF without palette."""
        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.gif"),
            quality="medium",
            resolution=None,
            framerate=None,
            bitrate=None,
            start_time=None,
            duration=None,
            audio_only=False,
            video_only=False,
            codec=None,
            preset="medium",
            crf=None,
            custom_args=None,
            overwrite=False,
            verbose=False,
            gif_fps=15.0,
            gif_palette=False,
            gif_loop=2,
        )

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        self.assertIn("-r", cmd)
        self.assertIn("15.0", cmd)
        self.assertIn("-loop", cmd)
        self.assertIn("2", cmd)

    def test_build_ffmpeg_command_with_trimming(
        self,
    ):
        """Test FFmpeg command building with start time and duration."""
        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.mp4"),
            quality="medium",
            resolution=None,
            framerate=None,
            bitrate=None,
            start_time="00:01:30",
            duration="00:02:00",
            audio_only=False,
            video_only=False,
            codec=None,
            preset="medium",
            crf=None,
            custom_args=None,
            overwrite=True,
            verbose=False,
            gif_fps=10.0,
            gif_palette=False,
            gif_loop=0,
        )

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        self.assertIn("-ss", cmd)
        self.assertIn("00:01:30", cmd)
        self.assertIn("-t", cmd)
        self.assertIn("00:02:00", cmd)
        self.assertIn("-y", cmd)

    def test_build_ffmpeg_command_audio_only(
        self,
    ):
        """Test FFmpeg command building for audio-only extraction."""
        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.mp3"),
            quality="medium",
            resolution=None,
            framerate=None,
            bitrate=None,
            start_time=None,
            duration=None,
            audio_only=True,
            video_only=False,
            codec=None,
            preset="medium",
            crf=None,
            custom_args=None,
            overwrite=False,
            verbose=False,
            gif_fps=10.0,
            gif_palette=False,
            gif_loop=0,
        )

        cmd = convert_media.build_ffmpeg_command(
            args, "video"
        )

        self.assertIn("-vn", cmd)
        self.assertIn("-acodec", cmd)
        self.assertIn("libmp3lame", cmd)

    @patch(
        "convert_media.tempfile.NamedTemporaryFile"
    )
    @patch("convert_media.subprocess.run")
    def test_build_gif_with_palette_success(
        self, mock_run, mock_tempfile
    ):
        """Test GIF creation with palette generation."""
        # Mock tempfile
        mock_temp = Mock()
        mock_temp.name = str(
            self.temp_dir / "palette.png"
        )
        mock_tempfile.return_value.__enter__.return_value = (
            mock_temp
        )

        # Mock successful subprocess runs
        mock_run.return_value = Mock(returncode=0)

        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.gif"),
            start_time=None,
            duration=None,
            resolution="640x480",
            gif_fps=12.0,
            gif_loop=1,
            verbose=False,
        )

        result = (
            convert_media.build_gif_with_palette(
                args
            )
        )

        self.assertTrue(result)
        self.assertEqual(
            mock_run.call_count, 2
        )  # Two passes

    @patch(
        "convert_media.tempfile.NamedTemporaryFile"
    )
    @patch("convert_media.subprocess.run")
    def test_build_gif_with_palette_failure(
        self, mock_run, mock_tempfile
    ):
        """Test GIF creation with palette generation failure."""
        # Mock tempfile
        mock_temp = Mock()
        mock_temp.name = str(
            self.temp_dir / "palette.png"
        )
        mock_tempfile.return_value.__enter__.return_value = (
            mock_temp
        )

        # Mock failed subprocess run
        mock_run.side_effect = convert_media.subprocess.CalledProcessError(
            1, "ffmpeg"
        )

        args = argparse.Namespace(
            input_path=Path("input.mp4"),
            output_path=Path("output.gif"),
            start_time=None,
            duration=None,
            resolution=None,
            gif_fps=10.0,
            gif_loop=0,
            verbose=False,
        )

        with patch("builtins.print"):
            result = convert_media.build_gif_with_palette(
                args
            )

        self.assertFalse(result)

    @patch("convert_media.subprocess.run")
    def test_get_media_info_success(
        self, mock_run
    ):
        """Test media info retrieval success."""
        mock_output = """
        {
            "format": {
                "duration": "120.5",
                "size": "1048576"
            },
            "streams": [
                {
                    "codec_type": "video",
                    "codec_name": "h264",
                    "width": 1920,
                    "height": 1080,
                    "r_frame_rate": "30/1"
                },
                {
                    "codec_type": "audio",
                    "codec_name": "aac",
                    "sample_rate": "44100",
                    "channels": 2
                }
            ]
        }
        """
        mock_run.return_value = Mock(
            stdout=mock_output, returncode=0
        )

        info = convert_media.get_media_info(
            self.input_file
        )

        expected = {
            "duration": "120.5",
            "size": "1048576",
            "video_codec": "h264",
            "resolution": "1920x1080",
            "fps": "30/1",
            "audio_codec": "aac",
            "sample_rate": "44100",
            "channels": 2,
        }

        self.assertEqual(info, expected)

    @patch("convert_media.subprocess.run")
    def test_get_media_info_failure(
        self, mock_run
    ):
        """Test media info retrieval failure."""
        mock_run.side_effect = convert_media.subprocess.CalledProcessError(
            1, "ffprobe"
        )

        info = convert_media.get_media_info(
            self.input_file
        )

        self.assertEqual(info, {})

    def test_print_file_info(self):
        """Test file info printing."""
        # Create test files with known sizes
        input_file = self.temp_dir / "input.txt"
        output_file = self.temp_dir / "output.txt"

        input_file.write_text(
            "x" * 1000
        )  # 1000 bytes
        output_file.write_text(
            "x" * 500
        )  # 500 bytes

        with patch(
            "builtins.print"
        ) as mock_print, patch(
            "convert_media.get_media_info",
            return_value={},
        ):
            convert_media.print_file_info(
                input_file, output_file
            )

        # Check that print was called with size information
        calls = [
            call.args[0]
            for call in mock_print.call_args_list
        ]
        size_calls = [
            call
            for call in calls
            if "size" in call.lower()
        ]
        self.assertTrue(
            len(size_calls) >= 2
        )  # Input and output size


if __name__ == "__main__":
    unittest.main()
