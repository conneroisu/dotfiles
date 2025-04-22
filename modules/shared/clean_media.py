#!/usr/bin/env python3
"""
MP4 Metadata Stripper and Resizer

This script removes metadata from MP4 files and optionally resizes them.
It uses FFmpeg for processing the video files.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path


def check_ffmpeg():
    """Check if FFmpeg is installed on the system."""
    try:
        _ = subprocess.run(
            ["ffmpeg", "-version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        return True
    except (subprocess.SubprocessError, FileNotFoundError):
        return False


def strip_metadata(
    input_file: str,
    output_file: str,
    width: int | None = None,
    height: int | None = None,
):
    """
    Strip metadata from MP4 file and optionally resize it.

    Args:
        input_file (str): Path to the input MP4 file
        output_file (str): Path to save the output MP4 file
        width (int, optional): New width for the video
        height (int, optional): New height for the video

    Returns:
        bool: True if successful, False otherwise
    """
    # Build the command
    cmd = ["ffmpeg", "-i", input_file, "-map_metadata", "-1"]

    # Add video filter for resizing if specified
    if width or height:
        if width and height:
            scale_filter = f"scale={width}:{height}"
        elif width:
            scale_filter = f"scale={width}:-1"  # Keep aspect ratio
        else:
            scale_filter = f"scale=-1:{height}"  # Keep aspect ratio

        cmd.extend(["-vf", scale_filter])

    # Add output file with metadata stripped
    cmd.extend(["-c:a", "copy", output_file])

    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error processing file: {e}")
        print(f"FFmpeg error: {e.stderr.decode()}")
        return False


def main():
    """Process command line arguments and run the script."""
    parser = argparse.ArgumentParser(
        description="Strip metadata from MP4 files and optionally resize them."
    )

    parser.add_argument("input_file", help="Input MP4 file path")

    parser.add_argument(
        "-o", "--output", help="Output file path (default: input_file_clean.mp4)"
    )

    parser.add_argument(
        "-w",
        "--width",
        type=int,
        help="New width for the video (keeping aspect ratio if only width is specified)",
    )

    parser.add_argument(
        "-ht",
        "--height",
        type=int,
        help="New height for the video (keeping aspect ratio if only height is specified)",
    )

    args = parser.parse_args()

    # Check if FFmpeg is installed
    if not check_ffmpeg():
        print("Error: FFmpeg is not installed or not found in PATH.")
        print("Please install FFmpeg and try again.")
        sys.exit(1)

    # Validate input file
    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"Error: Input file does not exist: {args.input_file}")
        sys.exit(1)

    if input_path.suffix.lower() != ".mp4":
        print(f"Warning: Input file doesn't have .mp4 extension: {args.input_file}")

    # Set output file path
    if args.output:
        output_file = args.output
    else:
        output_dir = input_path.parent
        output_name = f"{input_path.stem}_clean{input_path.suffix}"
        output_file = os.path.join(output_dir, output_name)

    # Strip metadata and optionally resize
    print(f"Processing file: {args.input_file}")
    print(f"Output will be saved to: {output_file}")

    if args.width or args.height:
        print(
            f"Resizing to: {args.width if args.width else 'auto'}x{args.height if args.height else 'auto'}"
        )

    success = strip_metadata(args.input_file, output_file, args.width, args.height)

    if success:
        print(f"Successfully processed file. Output saved to: {output_file}")
    else:
        print("Failed to process file.")
        sys.exit(1)


if __name__ == "__main__":
    main()
