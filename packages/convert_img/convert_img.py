"""
Image Format Converter

This script converts images from one format to another.
Usage: python convert.py input_image output_image
"""

import sys
import os
from PIL import Image


def convert_image(input_path: str, output_path: str):
    """
    Convert an image from its current format to the format specified by the output path.

    Args:
        input_path (str): Path to the input image file
        output_path (str): Path where the converted image will be saved

    Returns:
        bool: True if conversion is successful, False otherwise
    """
    try:
        # Check if input file exists
        if not os.path.exists(input_path):
            print(f"Error: Input file '{input_path}' does not exist.")
            return False

        # Determine the output format from the extension
        output_format = os.path.splitext(output_path)[1].lstrip(".").upper()

        # Special case for JPG format (PIL uses JPEG internally)
        if output_format == "JPG":
            output_format = "JPEG"

        # Open the input image
        with Image.open(input_path) as img:
            # Convert image if it's not in RGB mode and the output format requires it
            if img.mode not in ("RGB", "RGBA") and output_format in ("JPEG", "WEBP"):
                img = img.convert("RGB")

            # Save the image in the new format
            img.save(output_path, format=output_format)

            print(f"Successfully converted '{input_path}' to '{output_path}'")
            return True

    except Exception as e:
        print(f"Error during conversion: {e}")
        return False


def main():
    """Main function to parse arguments and call the conversion function."""
    if len(sys.argv) != 3:
        print("Usage: python convert.py input_image output_image")
        return 1

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    if convert_image(input_path, output_path):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
