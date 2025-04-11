import argparse
from PIL import Image
import os
import sys


def clean_png(input_path: str, output_path: str | None = None, optimize: bool = True):
    """
    Removes metadata from a PNG file and optionally optimizes it.

    Args:
        input_path (str): Path to the input PNG file
        output_path (str, optional): Path to save the cleaned PNG file.
                                    If None, will overwrite the input file.
        optimize (bool): Whether to optimize the PNG file

    Returns:
        tuple: (success, message, original_size, new_size)
    """
    try:
        # If output_path is not provided, use the input path
        if output_path is None:
            output_path = input_path

        # Get original file size
        original_size = os.path.getsize(input_path)

        # Open the image with PIL
        img = Image.open(input_path)

        # Create a new image with the same data but no metadata
        # Convert to RGBA if it has alpha channel, otherwise RGB
        if img.mode == "RGBA":
            clean_img = Image.new("RGBA", img.size)
        else:
            img = img.convert("RGB")
            clean_img = Image.new("RGB", img.size)

        # Copy the pixel data from the original image
        clean_img.paste(img)

        clean_img.save(output_path, format="PNG", optimize=optimize, quality=100)

        # Get new file size
        new_size = os.path.getsize(output_path)

        # Calculate reduction percentage
        reduction = ((original_size - new_size) / original_size) * 100

        return (
            True,
            f"Successfully cleaned PNG file.\nOriginal size: {original_size:,} bytes\nNew size: {new_size:,} bytes\nReduction: {reduction:.2f}%",
            original_size,
            new_size,
        )

    except Exception as e:
        return (False, f"Error cleaning PNG file: {str(e)}", None, None)


def main():
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(
        description="Clean metadata from PNG files to reduce size"
    )
    _ = parser.add_argument("input", help="Input PNG file path")
    _ = parser.add_argument(
        "-o", "--output", help="Output PNG file path (default: overwrite input)"
    )
    _ = parser.add_argument(
        "--no-optimize",
        dest="optimize",
        action="store_false",
        help="Disable additional PNG optimization",
    )

    args = parser.parse_args()

    # Validate input file
    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' does not exist")
        sys.exit(1)

    if not args.input.lower().endswith(".png"):
        print(f"Warning: Input file '{args.input}' doesn't have a .png extension")

    # Process the PNG file
    success, message, original_size, new_size = clean_png(
        args.input, args.output, args.optimize
    )

    print(message)

    # Return appropriate exit code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
