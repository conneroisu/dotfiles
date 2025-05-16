from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image, UnidentifiedImageError
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="""
Convert one image file to another format (e.g. PNG → WebP).
"""
    )
    _ = parser.add_argument(
        "input_path",
        type=Path,
        help="""
Path to the source image (e.g. input.png)
""",
    )
    _ = parser.add_argument(
        "output_path",
        type=Path,
        help="""
Path to save the converted image (e.g. output.webp)
""",
    )
    # Add quality option for lossy formats
    _ = parser.add_argument(
        "-q",
        "--quality",
        type=int,
        default=90,
        help="""
Quality for lossy formats (1-100, default: 90)
""",
    )
    # Add option for optimization
    _ = parser.add_argument(
        "-o",
        "--optimize",
        action="store_true",
        help="Optimize output file size",
    )
    # Add option for keeping metadata
    _ = parser.add_argument(
        "--keep-metadata",
        action="store_true",
        help="Preserve image metadata (EXIF, etc.)",
    )
    _ = parser.add_argument(
        "-b",
        "--background",
        default="#FFFFFF",
        help="""
Background color for transparent to non-transparent conversions 
(default: white)
""",
    )
    return parser.parse_args()


def get_format_info() -> (
    dict[str, dict[str, bool | list[str] | str]]
):
    """
    Returns information about supported formats and their specific
    requirements.
    """
    return {
        "JPEG": {
            "aliases": ["JPG"],
            "transparency": False,
            "animation": False,
            "lossless": False,
            "extensions": [".jpeg", ".jpg"],
        },
        "PNG": {
            "aliases": [],
            "transparency": True,
            "animation": False,
            "lossless": True,
            "extensions": [".png"],
        },
        "WEBP": {
            "aliases": [],
            "transparency": True,
            "animation": True,
            "lossless": True,  # Can be lossless or lossy
            "extensions": [".webp"],
        },
        "GIF": {
            "aliases": [],
            "transparency": True,
            "animation": True,
            "lossless": True,  # But with limited colors
            "extensions": [".gif"],
        },
        "TIFF": {
            "aliases": ["TIF"],
            "transparency": True,
            "animation": False,
            "lossless": True,
            "extensions": [".tiff", ".tif"],
        },
        "BMP": {
            "aliases": [],
            "transparency": False,
            "animation": False,
            "lossless": True,
            "extensions": [".bmp"],
        },
        "ICO": {
            "aliases": [],
            "transparency": True,
            "animation": False,
            "lossless": True,
            "extensions": [".ico"],
        },
        "AVIF": {
            "aliases": [],
            "transparency": True,
            "animation": True,
            "lossless": False,  # Primarily lossy
            "extensions": [".avif"],
        },
        "HEIF": {
            "aliases": ["HEIC"],
            "transparency": True,
            "animation": False,
            "lossless": False,  # Primarily lossy
            "extensions": [".heif", ".heic"],
        },
        "PPM": {
            "aliases": [],
            "transparency": False,
            "animation": False,
            "lossless": True,
            "extensions": [".ppm"],
        },
        "PSD": {
            "aliases": [],
            "transparency": True,
            "animation": False,
            "lossless": True,
            "extensions": [".psd"],
        },
        "SVG": {
            "aliases": [],
            "transparency": True,
            "animation": True,
            "lossless": True,
            "extensions": [".svg"],
            "note": "Limited support in PIL, use at  own risk",
        },
    }


def get_save_kwargs(
    img: Image.Image,
    out_format: str,
    quality: int,
    optimize: bool,
    keep_metadata: bool,
) -> dict[str, dict[str, bool | list[str] | str]]:
    save_kwargs = {"format": out_format}
    # Common settings for all formats
    if optimize:
        save_kwargs["optimize"] = True
    # Format specific settings
    if out_format == "JPEG":
        save_kwargs["quality"] = quality
        # JPEG can preserve some metadata
        if (
            keep_metadata
            and hasattr(img, "info")
            and "exif" in img.info
        ):
            save_kwargs["exif"] = img.info["exif"]
    elif out_format == "PNG":
        # PNG supports different compression levels (0-9)
        if optimize:
            save_kwargs["compress_level"] = 9
        # Preserve transparency
        if img.mode == "RGBA":
            save_kwargs["alpha_info"] = (
                img.info.get("alpha_info", True)
            )
    elif out_format == "WEBP":
        save_kwargs["quality"] = quality
        # WebP supports lossless mode
        save_kwargs["lossless"] = quality == 100
        # WebP supports progressive mode
        if optimize:
            save_kwargs["method"] = (
                6  # Highest compression method
            )
    elif out_format == "AVIF":
        # AVIF support might be limited depending on PIL version
        save_kwargs["quality"] = quality
    elif out_format == "TIFF":
        # TIFF supports compression
        save_kwargs["compression"] = (
            "tiff_lzw" if optimize else None
        )
    elif out_format == "HEIF":
        # HEIF/HEIC requires special handling depending on PIL version
        save_kwargs["quality"] = quality
    # Handle metadata preservation or removal
    if keep_metadata:
        # Forward all metadata if available and format supports it
        if hasattr(img, "info"):
            for key, value in img.info.items():
                if (
                    key not in save_kwargs
                    and key
                    not in [
                        "_bmp_header",
                        "_windowsxp_info",
                    ]
                ):
                    save_kwargs[key] = value
    return save_kwargs


def convert_image(
    input_path: Path,
    output_path: Path,
    quality: int = 90,
    optimize: bool = False,
    keep_metadata: bool = False,
    background_color: str = "#FFFFFF",
) -> None:
    """
    Convert an image from one format to another, handling special cases by
    format.
    """
    try:
        with Image.open(input_path) as img:
            # Get the original format and target format
            original_format = img.format
            out_format = (
                output_path.suffix.lstrip(
                    "."
                ).upper()
            )
            # Get format information
            format_info = get_format_info()
            # Handle format aliases
            for fmt, info in format_info.items():
                if out_format in info["aliases"]:
                    out_format = fmt
                    break
            # Ensure output format is supported
            supported_formats = set(
                format_info.keys()
            )
            if (
                out_format
                not in supported_formats
            ):
                print(
                    f"""
Warning: {out_format} may not be supported by PIL. 
Attempting conversion anyway...
"""
                )
            # Handle special format conversions
            # 1. Check if output format supports transparency
            if (
                img.mode in ("RGBA", "LA")
                and out_format in format_info
                and not format_info[out_format][
                    "transparency"
                ]
            ):
                print(
                    f"""
Converting transparent image to {out_format} which 
doesn't support transparency
"""
                )
                # Convert to RGB with background color
                bg = Image.new(
                    "RGB",
                    img.size,
                    background_color,
                )
                bg.paste(
                    img,
                    mask=(
                        img.getchannel("A")
                        if img.mode == "RGBA"
                        else img.getchannel("A")
                    ),
                )
                img = bg
            # 2. Special case for P (palette) mode
            elif img.mode == "P":
                if out_format in ["JPEG"]:
                    # Convert palette to RGB for JPEG
                    img = img.convert("RGB")
                elif out_format in ["PNG", "GIF"]:
                    # These formats support palette mode
                    pass
                else:
                    # For other formats, convert based on transparency
                    if (
                        "transparency" in img.info
                        and format_info.get(
                            out_format, {}
                        ).get(
                            "transparency", False
                        )
                    ):
                        img = img.convert("RGBA")
                    else:
                        img = img.convert("RGB")
            # 3. Handle animated formats
            if (
                getattr(img, "is_animated", False)
                and hasattr(img, "n_frames")
                and img.n_frames > 1
            ):
                if (
                    out_format
                    not in [
                        "GIF",
                        "WEBP",
                        "APNG",
                        "AVIF",
                    ]
                    or out_format
                    not in format_info
                    or not format_info[
                        out_format
                    ]["animation"]
                ):
                    print(
                        f"""
Warning: Converting animated image to {out_format}, 
may not support animation.
"""
                    )
                    # Will only save the first frame
                # Special case for animated GIFs and animated WebP
                if (
                    out_format in ["GIF", "WEBP"]
                    and format_info[out_format][
                        "animation"
                    ]
                ):
                    frames = []
                    durations = []
                    for frame_idx in range(
                        img.n_frames
                    ):
                        img.seek(frame_idx)
                        frames.append(img.copy())
                        durations.append(
                            img.info.get(
                                "duration", 100
                            )
                        )  # Default to 100ms
                    # Get save kwargs for the format
                    save_kwargs = get_save_kwargs(
                        frames[0],
                        out_format,
                        quality,
                        optimize,
                        keep_metadata,
                    )
                    save_kwargs.update(
                        {
                            "save_all": True,
                            "append_images": frames[
                                1:
                            ],
                            "loop": 0,  # Loop forever
                            "duration": durations,
                        }
                    )
                    # Save animated image
                    frames[0].save(
                        output_path, **save_kwargs
                    )
                    print(
                        f"""
Saved animated {out_format} to {output_path} ({img.n_frames} frames)
"""
                    )
                    return
            # Get format-specific save parameters
            save_kwargs = get_save_kwargs(
                img,
                out_format,
                quality,
                optimize,
                keep_metadata,
            )
            # Save the image with the appropriate parameters
            img.save(output_path, **save_kwargs)
            # Report success with details
            print(
                f"Converted: {input_path.name} → {output_path.name}"
            )
            print(
                f"Format: {original_format} → {out_format}"
            )
            print(
                f"Mode: {img.mode}, Size: {img.width}x{img.height}"
            )
            if (
                input_path.exists()
                and output_path.exists()
            ):
                compression_ratio = (
                    output_path.stat().st_size
                    / input_path.stat().st_size
                )
                print(
                    f"Original size: {input_path.stat().st_size:,} bytes"
                )
                print(
                    f"Converted size: {output_path.stat().st_size:,} bytes"
                )
                print(
                    f"""
Compression ratio: 
{compression_ratio:.2f}x ({(1-compression_ratio)*100:.1f}% 
{'' if compression_ratio < 1 else 'in'}efficiency)
"""
                )
    except FileNotFoundError:
        print(
            f"Error: file not found: {input_path}"
        )
        sys.exit(1)
    except UnidentifiedImageError:
        print(
            f"Error: cannot identify image file {input_path}"
        )
        sys.exit(1)
    except ValueError as e:
        print(f"Value error: {e}")
        sys.exit(1)
    except Image.DecompressionBombError:
        print(
            """
Error: Image is too large and might consume too much memory
           """
        )
        sys.exit(1)
    except OSError as e:
        print(f"OS error: {e}")
        if "cannot write mode" in str(e):
            print(
                """
Try a different output format or convert the image mode first
                """
            )
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e!r}")
        sys.exit(1)


def main() -> None:
    args = parse_args()
    # Validate input file exists
    if not args.input_path.exists():
        print(
            f"Error: input file does not exist: {args.input_path}"
        )
        sys.exit(1)
    # Validate quality range
    if args.quality < 1 or args.quality > 100:
        print(
            "Error: quality must be between 1 and 100"
        )
        sys.exit(1)
    # Create output directory if it doesn't exist
    output_dir = args.output_path.parent
    if not output_dir.exists():
        output_dir.mkdir(parents=True)
        print(
            f"Created output directory: {output_dir}"
        )
    # Check if input and output are the same file
    if (
        args.input_path.resolve()
        == args.output_path.resolve()
    ):
        print(
            "Error: input and output paths cannot be the same"
        )
        sys.exit(1)
    convert_image(
        args.input_path,
        args.output_path,
        quality=args.quality,
        optimize=args.optimize,
        keep_metadata=args.keep_metadata,
        background_color=args.background,
    )


if __name__ == "__main__":
    main()
