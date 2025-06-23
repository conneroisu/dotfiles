"""
Universal Image Format Converter CLI Tool

Converts between various image formats (JPEG, PNG, WebP, TIFF, BMP, GIF, 
AVIF, HEIF, ICO, PCX, TGA, ICNS, SVG) with support for format-specific 
options like quality, compression, and transparency handling.
"""

from __future__ import annotations
import argparse
import base64
import io
import sys
from pathlib import Path

from PIL import Image, UnidentifiedImageError


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert between various image formats. "
            "Supports JPEG, PNG, WebP, TIFF, BMP, GIF, AVIF, HEIF, ICO, SVG, etc. "
            "Auto-detects output format from file extension or use --format."
        ),
        formatter_class=(
            argparse.RawDescriptionHelpFormatter
        ),
    )

    parser.add_argument(
        "input_path",
        type=Path,
        help="Path to the input image file (supports JPEG, PNG, WebP, TIFF, "
             "BMP, GIF, AVIF, HEIF, ICO, etc.)",
    )

    parser.add_argument(
        "output_path",
        type=Path,
        help="Path to save the converted file (format auto-detected from extension)",
    )

    parser.add_argument(
        "-m",
        "--method",
        choices=["embed", "trace"],
        default="trace",
        help=(
            "Conversion method:\n"
            "  trace: Attempt to trace/vectorize image "
            "(requires potrace) (default)\n"
            "  embed: Embed image data in SVG"
        ),
    )

    parser.add_argument(
        "-f",
        "--format",
        choices=["auto", "png", "jpeg", "webp", "tiff", "bmp", "gif", "avif", "heif", "ico", "svg"],
        default="auto",
        help=(
            "Output format (default: auto - detect from file extension)\n"
            "For SVG: use --method to choose embed or trace conversion"
        ),
    )

    parser.add_argument(
        "-q",
        "--quality",
        type=int,
        default=90,
        help=(
            "Quality for lossy formats "
            "(1-100, default: 90)"
        ),
    )

    parser.add_argument(
        "-w",
        "--width",
        type=int,
        help=(
            "Override SVG width "
            "(maintains aspect ratio)"
        ),
    )

    parser.add_argument(
        "--height",
        type=int,
        help=(
            "Override SVG height "
            "(maintains aspect ratio)"
        ),
    )

    parser.add_argument(
        "--max-size",
        type=int,
        help=(
            "Maximum width or height "
            "(resizes proportionally)"
        ),
    )

    parser.add_argument(
        "--background",
        default="transparent",
        help=(
            "Background color for the SVG "
            "(default: transparent)\n"
            "Use 'transparent', hex colors like "
            "'#FFFFFF', or CSS color names"
        ),
    )

    parser.add_argument(
        "--optimize",
        action="store_true",
        help="Optimize the SVG output",
    )

    parser.add_argument(
        "--preserve-aspect",
        action="store_true",
        default=True,
        help="Preserve aspect ratio (default: True)",
    )

    parser.add_argument(
        "--trace-options",
        default="",
        help=(
            "Additional options for potrace "
            "(only with --method trace)\n"
            "Example: '--trace-options=\"-t 4 -O 0.2\"'"
        ),
    )

    return parser.parse_args()


def detect_output_format(output_path: Path, format_arg: str) -> str:
    """Detect output format from file extension or format argument."""
    # Map file extensions to formats
    ext_to_format = {
        ".jpg": "jpeg",
        ".jpeg": "jpeg", 
        ".png": "png",
        ".webp": "webp",
        ".tiff": "tiff",
        ".tif": "tiff",
        ".bmp": "bmp",
        ".gif": "gif",
        ".avif": "avif",
        ".heif": "heif",
        ".heic": "heif",
        ".ico": "ico",
        ".svg": "svg",
    }
    
    ext = output_path.suffix.lower()
    
    # SVG extension always takes precedence
    if ext == ".svg":
        return "svg"
    
    # For non-SVG extensions, use format argument if provided
    if format_arg != "auto":
        return format_arg.lower()
    
    # Use extension-based detection
    if ext in ext_to_format:
        return ext_to_format[ext]
    
    # Default to PNG if extension not recognized
    print(f"Warning: Unknown extension '{ext}', defaulting to PNG format")
    return "png"


def get_pillow_format(format_name: str) -> str:
    """Get the Pillow format string for a given format name."""
    format_map = {
        "jpeg": "JPEG",
        "png": "PNG", 
        "webp": "WEBP",
        "tiff": "TIFF",
        "bmp": "BMP",
        "gif": "GIF",
        "avif": "AVIF",
        "heif": "HEIF",
        "ico": "ICO",
    }
    return format_map.get(format_name, "PNG")


def prepare_image_for_format(img: Image.Image, output_format: str) -> Image.Image:
    """Prepare image for specific output format (handle transparency, etc.)."""
    if output_format in ("jpeg", "bmp"):
        # JPEG and BMP don't support transparency
        if img.mode in ("RGBA", "LA", "P"):
            # Create white background
            if img.mode == "P":
                img = img.convert("RGBA")
            
            if img.mode in ("RGBA", "LA"):
                bg = Image.new("RGB", img.size, (255, 255, 255))
                if img.mode == "RGBA":
                    bg.paste(img, mask=img.getchannel("A"))
                else:  # LA
                    bg.paste(img, mask=img.getchannel("A"))
                img = bg
            else:
                img = img.convert("RGB")
    elif output_format == "gif":
        # GIF supports transparency but limited colors
        if img.mode not in ("P", "L"):
            if img.mode == "RGBA":
                # Convert RGBA to P with transparency
                img = img.convert("P", palette=Image.ADAPTIVE)
            else:
                img = img.convert("P")
    elif output_format == "ico":
        # ICO format considerations
        if img.mode == "P":
            img = img.convert("RGBA")
    
    return img


def convert_image_to_image(
    input_path: Path, 
    output_path: Path, 
    output_format: str,
    quality: int = 90,
    width: int | None = None,
    height: int | None = None,
    max_size: int | None = None,
    optimize: bool = False
) -> None:
    """Convert image from one format to another."""
    with Image.open(input_path) as img:
        print(f"Input: {img.width}x{img.height}, Mode: {img.mode}, Format: {img.format}")
        
        # Resize if requested
        if width or height or max_size:
            img = resize_image(img, width, height, max_size)
            print(f"Resized to: {img.width}x{img.height}")
        
        # Prepare image for target format
        img = prepare_image_for_format(img, output_format)
        
        # Set up save arguments
        save_kwargs = {"format": get_pillow_format(output_format)}
        
        if output_format == "jpeg":
            save_kwargs["quality"] = quality
            save_kwargs["optimize"] = optimize
        elif output_format == "png":
            save_kwargs["optimize"] = optimize
        elif output_format == "webp":
            save_kwargs["quality"] = quality
            save_kwargs["optimize"] = optimize
        elif output_format == "tiff":
            save_kwargs["compression"] = "lzw"
        elif output_format == "avif":
            save_kwargs["quality"] = quality
            save_kwargs["optimize"] = optimize
        elif output_format == "gif":
            save_kwargs["optimize"] = optimize
        
        # Save the converted image
        img.save(output_path, **save_kwargs)
        
        print(f"Converted {input_path.name} → {output_path.name}")
        print(f"Output format: {output_format.upper()}")
        if output_format != "svg":
            print(f"Output size: {img.width}x{img.height}")


def validate_input(input_path: Path) -> None:
    """Validate the input file."""
    if not input_path.exists():
        print(
            f"Error: Input file does not exist: "
            f"{input_path}"
        )
        sys.exit(1)

    if not input_path.is_file():
        print(
            f"Error: Input path is not a file: "
            f"{input_path}"
        )
        sys.exit(1)

    # Check if it's a valid image
    try:
        with Image.open(input_path) as img:
            allowed_formats = [
                "WEBP",
                "PNG",
                "JPEG",
                "JPG",
                "GIF",
                "BMP",
                "TIFF",
                "TIF",
                "AVIF",
                "HEIF",
                "HEIC",
                "ICO",
                "PCX",
                "TGA",
                "ICNS",
                "PPM",
                "PGM",
                "PBM",
                "XBM",
                "XPM",
            ]
            if img.format not in allowed_formats:
                print(
                    f"Warning: Input format "
                    f"'{img.format}' may not be supported"
                )
    except UnidentifiedImageError:
        print(
            f"Error: Cannot identify image file: "
            f"{input_path}"
        )
        sys.exit(1)


def resize_image(
    img: Image.Image,
    width: int | None = None,
    height: int | None = None,
    max_size: int | None = None,
) -> Image.Image:
    """Resize image while preserving aspect ratio."""
    orig_w, orig_h = img.size

    if max_size:
        # Scale down if either dimension exceeds max_size
        if orig_w > max_size or orig_h > max_size:
            ratio = min(
                max_size / orig_w,
                max_size / orig_h,
            )
            new_w = int(orig_w * ratio)
            new_h = int(orig_h * ratio)
            return img.resize(
                (new_w, new_h),
                Image.Resampling.LANCZOS,
            )

    if width and height:
        return img.resize(
            (width, height),
            Image.Resampling.LANCZOS,
        )
    elif width:
        ratio = width / orig_w
        new_h = int(orig_h * ratio)
        return img.resize(
            (width, new_h),
            Image.Resampling.LANCZOS,
        )
    elif height:
        ratio = height / orig_h
        new_w = int(orig_w * ratio)
        return img.resize(
            (new_w, height),
            Image.Resampling.LANCZOS,
        )

    return img


def image_to_base64(
    img: Image.Image, fmt: str, quality: int = 90
) -> str:
    """Convert PIL Image to base64 encoded string."""
    buffer = io.BytesIO()

    # Handle format-specific options
    save_kwargs = {"format": fmt.upper()}

    if fmt.upper() == "JPEG":
        # Convert RGBA to RGB for JPEG
        if img.mode in ("RGBA", "LA"):
            bg = Image.new(
                "RGB", img.size, (255, 255, 255)
            )
            if img.mode == "RGBA":
                bg.paste(
                    img, mask=img.getchannel("A")
                )
            else:
                bg.paste(
                    img, mask=img.getchannel("A")
                )
            img = bg
        save_kwargs["quality"] = quality
        save_kwargs["optimize"] = True
    elif fmt.upper() == "PNG":
        save_kwargs["optimize"] = True
    elif fmt.upper() == "WEBP":
        save_kwargs["quality"] = quality
        save_kwargs["optimize"] = True
    elif fmt.upper() == "TIFF":
        save_kwargs["compression"] = "lzw"
    elif fmt.upper() == "BMP":
        # BMP doesn't support transparency, convert RGBA to RGB
        if img.mode in ("RGBA", "LA"):
            bg = Image.new("RGB", img.size, (255, 255, 255))
            if img.mode == "RGBA":
                bg.paste(img, mask=img.getchannel("A"))
            else:
                bg.paste(img, mask=img.getchannel("A"))
            img = bg
    elif fmt.upper() == "AVIF":
        save_kwargs["quality"] = quality
        save_kwargs["optimize"] = True

    img.save(buffer, **save_kwargs)
    img_data = buffer.getvalue()
    return base64.b64encode(img_data).decode(
        "utf-8"
    )


def create_embedded_svg(
    img: Image.Image,
    fmt: str,
    quality: int,
    bg: str,
    optimize: bool,
) -> str:
    """Create SVG with embedded raster image."""
    w, h = img.size

    # Get base64 encoded image
    b64_data = image_to_base64(img, fmt, quality)

    # Determine MIME type
    mime_types = {
        "png": "image/png",
        "jpeg": "image/jpeg",
        "webp": "image/webp",
        "tiff": "image/tiff",
        "bmp": "image/bmp",
        "avif": "image/avif",
    }
    mime = mime_types.get(
        fmt.lower(), "image/png"
    )

    # Create SVG content
    svg = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg"\n'
        '     xmlns:xlink="http://www.w3.org/1999/xlink"\n'
        f'     width="{w}"\n'
        f'     height="{h}"\n'
        f'     viewBox="0 0 {w} {h}">'
    )

    # Add background if specified
    if bg and bg.lower() != "transparent":
        svg += (
            f'\n  <rect width="100%" height="100%" '
            f'fill="{bg}"/>'
        )

    # Add the embedded image
    svg += (
        f'\n  <image x="0" y="0"\n'
        f'         width="{w}"\n'
        f'         height="{h}"\n'
        f'         href="data:{mime};base64,{b64_data}"/>\n'
        "</svg>"
    )

    return svg


def create_traced_svg(
    input_path: Path,
    output_path: Path,
    trace_opts: str,
) -> bool:
    """Create SVG using potrace for vector tracing."""
    try:
        import subprocess
        import tempfile

        # Check if potrace is available
        try:
            subprocess.run(
                ["potrace", "--version"],
                capture_output=True,
                check=True,
            )
        except (
            subprocess.CalledProcessError,
            FileNotFoundError,
        ):
            print(
                "Error: potrace is not installed or not in PATH"
            )
            print(
                "Install potrace to use vector tracing:"
            )
            print(
                "  Ubuntu/Debian: sudo apt-get install potrace"
            )
            print("  macOS: brew install potrace")
            print(
                "  Windows: Download from http://potrace.sourceforge.net/"
            )
            return False

        # Convert input to bitmap format
        # that potrace can handle
        with tempfile.NamedTemporaryFile(
            suffix=".pbm", delete=False
        ) as temp_pbm:
            temp_pbm_path = Path(temp_pbm.name)

        try:
            # Convert to PBM using PIL
            with Image.open(input_path) as img:
                # Convert to 1-bit black and white
                if img.mode != "1":
                    img = img.convert(
                        "L"
                    )  # Grayscale first
                    img = img.point(
                        lambda x: (
                            0 if x < 128 else 255
                        ),
                        "1",
                    )

                img.save(temp_pbm_path, "PPM")

            # Run potrace
            cmd = [
                "potrace",
                "-s",
            ]  # -s for SVG output

            if trace_opts:
                # Parse trace options
                cmd.extend(trace_opts.split())

            cmd.extend(
                [
                    "-o",
                    str(output_path),
                    str(temp_pbm_path),
                ]
            )

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                print(
                    f"Error running potrace: {result.stderr}"
                )
                return False

            print(
                f"Successfully traced to SVG: {output_path}"
            )
            return True

        finally:
            # Clean up temporary file
            if temp_pbm_path.exists():
                temp_pbm_path.unlink()

    except ImportError:
        print(
            "Error: subprocess module not available"
        )
        return False
    except Exception as e:
        print(f"Error during tracing: {e}")
        return False


def get_file_size_info(
    input_path: Path, output_path: Path
) -> None:
    """Print file size comparison."""
    if (
        input_path.exists()
        and output_path.exists()
    ):
        in_size = input_path.stat().st_size
        out_size = output_path.stat().st_size
        ratio = out_size / in_size

        print(f"Input size:  {in_size:,} bytes")
        print(f"Output size: {out_size:,} bytes")
        print(
            f"Size ratio:  {ratio:.2f}x", end=""
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

    # Validate arguments
    if args.quality < 1 or args.quality > 100:
        print(
            "Error: quality must be between 1 and 100"
        )
        sys.exit(1)

    # Validate input
    validate_input(args.input_path)

    # Create output directory if needed
    output_dir = args.output_path.parent
    if not output_dir.exists():
        output_dir.mkdir(
            parents=True, exist_ok=True
        )
        print(
            f"Created output directory: {output_dir}"
        )

    # Check if input and output are the same
    if (
        args.input_path.resolve()
        == args.output_path.resolve()
    ):
        print(
            "Error: Input and output paths cannot be the same"
        )
        sys.exit(1)

    # Detect output format
    output_format = detect_output_format(args.output_path, args.format)
    
    try:
        if output_format == "svg":
            # Handle SVG conversion
            if args.method == "trace":
                # Use potrace for vector tracing
                success = create_traced_svg(
                    args.input_path,
                    args.output_path,
                    args.trace_options,
                )
                if not success:
                    print("Falling back to embed method...")
                    args.method = "embed"
                else:
                    print(f"Converted {args.input_path.name} → {args.output_path.name}")
                    print("Method: Vector tracing")
                    get_file_size_info(args.input_path, args.output_path)
                    return

            if args.method == "embed":
                # Load and process the image
                with Image.open(args.input_path) as img:
                    print(f"Original: {img.width}x{img.height}, Mode: {img.mode}, Format: {img.format}")

                    # Resize if requested
                    if args.width or args.height or args.max_size:
                        img = resize_image(img, args.width, args.height, args.max_size)
                        print(f"Resized to: {img.width}x{img.height}")

                    # For SVG embedding, use format from args or default to PNG
                    embed_format = args.format if args.format != "auto" else "png"
                    if embed_format == "svg":
                        embed_format = "png"  # Can't embed SVG in SVG
                    
                    # Create SVG with embedded image
                    svg_content = create_embedded_svg(
                        img, embed_format, args.quality, args.background, args.optimize
                    )

                    # Write SVG file
                    with open(args.output_path, "w", encoding="utf-8") as f:
                        f.write(svg_content)

                    print(f"Converted {args.input_path.name} → {args.output_path.name}")
                    print(f"Method: Embedded {embed_format.upper()}")
                    print(f"SVG size: {img.width}x{img.height}")
                    get_file_size_info(args.input_path, args.output_path)
        else:
            # Handle image-to-image conversion
            convert_image_to_image(
                args.input_path,
                args.output_path, 
                output_format,
                args.quality,
                args.width,
                args.height,
                args.max_size,
                args.optimize
            )
            get_file_size_info(args.input_path, args.output_path)

    except Exception as e:
        print(f"Error during conversion: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
