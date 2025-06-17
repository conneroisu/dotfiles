"""
Media Format Converter CLI Tool

Converts between various video and audio formats using FFmpeg.
Supports common formats like MP4, AVI, MOV, MP3, WAV, FLAC, etc.
"""

from __future__ import annotations
import argparse
import subprocess
import sys
from pathlib import Path


SUPPORTED_VIDEO_FORMATS = {
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

SUPPORTED_AUDIO_FORMATS = {
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

VIDEO_CODECS = {
    "mp4": "libx264",
    "webm": "libvpx-vp9",
    "mkv": "libx264",
    "avi": "libx264",
    "mov": "libx264",
    "gif": "gif",
}

AUDIO_CODECS = {
    "mp3": "libmp3lame",
    "aac": "aac",
    "ogg": "libvorbis",
    "opus": "libopus",
    "flac": "flac",
    "wav": "pcm_s16le",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert media files between various formats using FFmpeg",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    _ = parser.add_argument(
        "input_path",
        type=Path,
        help="Path to the input media file",
    )

    _ = parser.add_argument(
        "output_path",
        type=Path,
        help="Path to save the converted file",
    )

    _ = parser.add_argument(
        "-q",
        "--quality",
        choices=[
            "low",
            "medium",
            "high",
            "lossless",
        ],
        default="medium",
        help="Quality preset (default: medium)",
    )

    _ = parser.add_argument(
        "-r",
        "--resolution",
        help="Video resolution (e.g., 1920x1080, 1280x720, 854x480)",
    )

    _ = parser.add_argument(
        "-f",
        "--framerate",
        type=float,
        help="Video framerate (fps)",
    )

    _ = parser.add_argument(
        "-b",
        "--bitrate",
        help="Audio/video bitrate (e.g., 128k, 1M, 5000k)",
    )

    _ = parser.add_argument(
        "-s",
        "--start-time",
        help="Start time for trimming (e.g., 00:01:30, 90)",
    )

    _ = parser.add_argument(
        "-t",
        "--duration",
        help="Duration for trimming (e.g., 00:02:00, 120)",
    )

    _ = parser.add_argument(
        "--audio-only",
        action="store_true",
        help="Extract audio only from video files",
    )

    _ = parser.add_argument(
        "--video-only",
        action="store_true",
        help="Extract video only (no audio)",
    )

    _ = parser.add_argument(
        "--codec",
        help="Force specific codec (e.g., libx264, libvpx-vp9, libmp3lame)",
    )

    _ = parser.add_argument(
        "--preset",
        choices=[
            "ultrafast",
            "superfast",
            "veryfast",
            "faster",
            "fast",
            "medium",
            "slow",
            "slower",
            "veryslow",
        ],
        default="medium",
        help="Encoding preset for video (default: medium)",
    )

    _ = parser.add_argument(
        "--crf",
        type=int,
        help="Constant Rate Factor for video quality (0-51, lower is better)",
    )

    _ = parser.add_argument(
        "--custom-args",
        help="Additional FFmpeg arguments (advanced users)",
    )

    _ = parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite output file if it exists",
    )

    _ = parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed FFmpeg output",
    )

    _ = parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the FFmpeg command without executing it",
    )

    _ = parser.add_argument(
        "--gif-fps",
        type=float,
        default=10.0,
        help="Framerate for GIF output (default: 10.0)",
    )

    _ = parser.add_argument(
        "--gif-palette",
        action="store_true",
        help="Generate optimized palette for GIF (better quality, larger size)",
    )

    _ = parser.add_argument(
        "--gif-loop",
        type=int,
        default=0,
        help="Number of loops for GIF (0 = infinite, default: 0)",
    )

    return parser.parse_args()


def check_ffmpeg() -> bool:
    """Check if FFmpeg is available."""
    try:
        result = subprocess.run(
            ["ffmpeg", "-version"],
            capture_output=True,
            check=True,
        )
        print(result.stdout)
        return True
    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
    ):
        print(
            "Error: FFmpeg is not installed or not in PATH"
        )
        print("Install FFmpeg:")
        print(
            "  Ubuntu/Debian: sudo apt-get install ffmpeg"
        )
        print("  macOS: brew install ffmpeg")
        print(
            "  Windows: Download from https://ffmpeg.org/"
        )
        return False


def validate_input(input_path: Path) -> str:
    """Validate input file and return media type."""
    if not input_path.exists():
        print(
            f"Error: Input file does not exist: {input_path}"
        )
        sys.exit(1)

    if not input_path.is_file():
        print(
            f"Error: Input path is not a file: {input_path}"
        )
        sys.exit(1)

    extension = input_path.suffix.lower().lstrip(
        "."
    )

    if extension in SUPPORTED_VIDEO_FORMATS:
        return "video"
    elif extension in SUPPORTED_AUDIO_FORMATS:
        return "audio"
    else:
        print(
            f"Warning: Format '{extension}' may not be supported"
        )
        return "unknown"


def get_quality_settings(
    quality: str, media_type: str
) -> dict[str, str]:
    """Get quality settings based on preset."""
    settings = {}

    if media_type == "video":
        if quality == "low":
            settings.update(
                {"crf": "28", "preset": "fast"}
            )
        elif quality == "medium":
            settings.update(
                {"crf": "23", "preset": "medium"}
            )
        elif quality == "high":
            settings.update(
                {"crf": "18", "preset": "slow"}
            )
        elif quality == "lossless":
            settings.update(
                {"crf": "0", "preset": "medium"}
            )
    else:  # audio
        if quality == "low":
            settings.update({"ab": "128k"})
        elif quality == "medium":
            settings.update({"ab": "192k"})
        elif quality == "high":
            settings.update({"ab": "320k"})
        elif quality == "lossless":
            settings.update({"acodec": "flac"})

    return settings


def build_gif_with_palette(
    args: argparse.Namespace,
) -> bool:
    """Build GIF with optimized palette using two-pass encoding."""
    import tempfile

    try:
        with tempfile.NamedTemporaryFile(
            suffix=".png", delete=False
        ) as palette_file:
            palette_path = Path(palette_file.name)

        # First pass: generate palette
        palette_cmd = ["ffmpeg", "-y"]
        if not args.verbose:
            palette_cmd.extend(
                ["-loglevel", "error"]
            )

        palette_cmd.extend(
            ["-i", str(args.input_path)]
        )

        if args.start_time:
            palette_cmd.extend(
                ["-ss", args.start_time]
            )
        if args.duration:
            palette_cmd.extend(
                ["-t", args.duration]
            )

        # Generate palette
        palette_filter = (
            "palettegen=reserve_transparent=0"
        )
        if args.resolution:
            palette_filter = f"scale={args.resolution}:flags=lanczos,{palette_filter}"

        palette_cmd.extend(
            [
                "-vf",
                palette_filter,
                str(palette_path),
            ]
        )

        # Second pass: create GIF with palette
        gif_cmd = ["ffmpeg", "-y"]
        if not args.verbose:
            gif_cmd.extend(["-loglevel", "error"])

        gif_cmd.extend(
            [
                "-i",
                str(args.input_path),
                "-i",
                str(palette_path),
            ]
        )

        if args.start_time:
            gif_cmd.extend(
                ["-ss", args.start_time]
            )
        if args.duration:
            gif_cmd.extend(["-t", args.duration])

        # Apply filters
        gif_filter = f"fps={args.gif_fps}"
        if args.resolution:
            gif_filter = f"scale={args.resolution}:flags=lanczos,{gif_filter}"
        gif_filter += ",paletteuse"

        gif_cmd.extend(
            [
                "-filter_complex",
                f"[0:v]{gif_filter}[v];[v][1:v]paletteuse",
            ]
        )
        gif_cmd.extend(
            ["-loop", str(args.gif_loop)]
        )
        gif_cmd.append(str(args.output_path))

        if args.verbose:
            print("Generating palette...")
            print(" ".join(palette_cmd))
            print(
                "\nCreating GIF with palette..."
            )
            print(" ".join(gif_cmd))

        # Execute palette generation
        result = subprocess.run(
            palette_cmd,
            check=True,
            capture_output=not args.verbose,
        )
        print(result.stdout)

        # Execute GIF creation
        result = subprocess.run(
            gif_cmd,
            check=True,
            capture_output=not args.verbose,
        )
        print(result.stdout)

        # Clean up palette file
        palette_path.unlink(missing_ok=True)

        return True

    except subprocess.CalledProcessError as e:
        print(f"Error during GIF creation: {e}")
        if palette_path.exists():
            palette_path.unlink(missing_ok=True)
        return False


def build_ffmpeg_command(
    args: argparse.Namespace, input_type: str
) -> list[str]:
    """Build the FFmpeg command based on arguments."""
    cmd = ["ffmpeg"]

    if not args.verbose:
        cmd.extend(["-loglevel", "error"])

    # Input file
    cmd.extend(["-i", str(args.input_path)])

    # Start time and duration
    if args.start_time:
        cmd.extend(["-ss", args.start_time])
    if args.duration:
        cmd.extend(["-t", args.duration])

    # Get output format
    output_ext = (
        args.output_path.suffix.lower().lstrip(
            "."
        )
    )
    output_type = (
        "video"
        if output_ext in SUPPORTED_VIDEO_FORMATS
        else "audio"
    )

    # Quality settings
    quality_settings = get_quality_settings(
        args.quality, output_type
    )

    # Codec selection
    if args.codec:
        if output_type == "video":
            cmd.extend(["-vcodec", args.codec])
        else:
            cmd.extend(["-acodec", args.codec])
    else:
        # Auto-select codec based on format
        if (
            output_type == "video"
            and output_ext in VIDEO_CODECS
        ):
            cmd.extend(
                [
                    "-vcodec",
                    VIDEO_CODECS[output_ext],
                ]
            )
        elif (
            output_type == "audio"
            and output_ext in AUDIO_CODECS
        ):
            cmd.extend(
                [
                    "-acodec",
                    AUDIO_CODECS[output_ext],
                ]
            )

    # Video-specific settings
    if (
        output_type == "video"
        and not args.audio_only
    ):
        if args.resolution:
            cmd.extend(["-s", args.resolution])
        if args.framerate:
            cmd.extend(
                ["-r", str(args.framerate)]
            )
        if args.crf:
            cmd.extend(["-crf", str(args.crf)])
        elif "crf" in quality_settings:
            cmd.extend(
                ["-crf", quality_settings["crf"]]
            )
        if "preset" in quality_settings:
            cmd.extend(
                [
                    "-preset",
                    quality_settings["preset"],
                ]
            )
        elif args.preset:
            cmd.extend(["-preset", args.preset])

    # Audio settings
    if args.bitrate:
        if (
            output_type == "video"
            and not args.audio_only
        ):
            cmd.extend(["-b:v", args.bitrate])
        else:
            cmd.extend(["-b:a", args.bitrate])
    elif "ab" in quality_settings:
        cmd.extend(
            ["-b:a", quality_settings["ab"]]
        )

    # Stream selection
    if args.audio_only:
        cmd.extend(["-vn"])  # No video
    elif args.video_only:
        cmd.extend(["-an"])  # No audio

    # GIF-specific settings (only for simple GIF without palette)
    if (
        output_ext == "gif"
        and not args.gif_palette
    ):
        cmd.extend(["-r", str(args.gif_fps)])
        cmd.extend(["-loop", str(args.gif_loop)])

    # Custom arguments
    if args.custom_args:
        cmd.extend(args.custom_args.split())

    # Overwrite option
    if args.overwrite:
        cmd.append("-y")

    # Output file
    cmd.append(str(args.output_path))

    return cmd


def get_media_info(
    file_path: Path,
) -> dict[str, str]:
    """Get basic media file information."""
    try:
        cmd = [
            "ffprobe",
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_format",
            "-show_streams",
            str(file_path),
        ]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
        )

        import json

        data = json.loads(result.stdout)

        info = {}
        if "format" in data:
            info["duration"] = data["format"].get(
                "duration", "Unknown"
            )
            info["size"] = data["format"].get(
                "size", "Unknown"
            )

        for stream in data.get("streams", []):
            if stream["codec_type"] == "video":
                info["video_codec"] = stream.get(
                    "codec_name", "Unknown"
                )
                info["resolution"] = (
                    f"{stream.get('width', '?')}x{stream.get('height', '?')}"
                )
                info["fps"] = stream.get(
                    "r_frame_rate", "Unknown"
                )
            elif stream["codec_type"] == "audio":
                info["audio_codec"] = stream.get(
                    "codec_name", "Unknown"
                )
                info["sample_rate"] = stream.get(
                    "sample_rate", "Unknown"
                )
                info["channels"] = stream.get(
                    "channels", "Unknown"
                )

        return info
    except (
        subprocess.CalledProcessError,
        json.JSONDecodeError,
        ImportError,
    ):
        return {}


def print_file_info(
    input_path: Path, output_path: Path
) -> None:
    """Print file size and basic info comparison."""
    if input_path.exists():
        input_size = input_path.stat().st_size
        print(
            f"Input size:  {input_size:,} bytes"
        )

        # Get media info if ffprobe is available
        info = get_media_info(input_path)
        if info:
            print("Input info:")
            for key, value in info.items():
                print(f"  {key}: {value}")

    if output_path.exists():
        output_size = output_path.stat().st_size
        print(
            f"Output size: {output_size:,} bytes"
        )

        if input_path.exists():
            input_size = input_path.stat().st_size
            if input_size > 0:
                ratio = output_size / input_size
                print(
                    f"Size ratio:  {ratio:.2f}x",
                    end="",
                )
                if ratio > 1:
                    print(
                        f" ({(ratio-1)*100:.1f}% larger)"
                    )
                else:
                    print(
                        f" ({(1-ratio)*100:.1f}% smaller)"
                    )


def main() -> None:
    args = parse_args()

    # Check if FFmpeg is available
    if not check_ffmpeg():
        sys.exit(1)

    # Validate input
    input_type = validate_input(args.input_path)

    # Check for conflicting options
    if args.audio_only and args.video_only:
        print(
            "Error: Cannot specify both --audio-only and --video-only"
        )
        sys.exit(1)

    # Create output directory if needed
    output_dir = args.output_path.parent
    if not output_dir.exists():
        output_dir.mkdir(
            parents=True, exist_ok=True
        )
        print(
            f"Created output directory: {output_dir}"
        )

    # Check if output file exists
    if (
        args.output_path.exists()
        and not args.overwrite
    ):
        response = input(
            f"Output file {args.output_path} exists. Overwrite? [y/N]: "
        )
        if response.lower() not in ["y", "yes"]:
            print("Cancelled.")
            sys.exit(0)

    # Check for GIF with palette (requires special handling)
    output_ext = (
        args.output_path.suffix.lower().lstrip(
            "."
        )
    )
    if output_ext == "gif" and args.gif_palette:
        if args.dry_run:
            print(
                "GIF with palette generation (two-pass encoding)"
            )
            print(
                "This would execute palette generation and GIF creation commands"
            )
            return

        if args.verbose:
            print(
                "Creating GIF with optimized palette..."
            )

        success = build_gif_with_palette(args)
        if success:
            print(
                f"Successfully converted {args.input_path.name} → {args.output_path.name}"
            )
            print(
                "Method: GIF with optimized palette"
            )
            print_file_info(
                args.input_path, args.output_path
            )
        else:
            sys.exit(1)
        return

    # Build FFmpeg command
    cmd = build_ffmpeg_command(args, input_type)

    if args.dry_run:
        print("FFmpeg command:")
        print(" ".join(cmd))
        return

    if args.verbose:
        print("Running command:")
        print(" ".join(cmd))
        print()

    try:
        # Run FFmpeg
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=not args.verbose,
            text=True,
        )
        print(result.stdout)

        print(
            f"Successfully converted {args.input_path.name} → {args.output_path.name}"
        )
        print_file_info(
            args.input_path, args.output_path
        )

    except subprocess.CalledProcessError as e:
        print(
            f"Error during conversion: FFmpeg returned code {e.returncode}"
        )
        if e.stderr:
            print(f"Error output: {e.stderr}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nConversion cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
