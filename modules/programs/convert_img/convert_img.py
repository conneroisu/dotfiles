from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, UnidentifiedImageError


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
    return parser.parse_args()


def convert_image(
    input_path: Path, output_path: Path
) -> None:
    try:
        with Image.open(input_path) as img:
            out_format = (
                output_path.suffix.lstrip(
                    "."
                ).upper()
            )
            if out_format == "JPG":
                out_format = "JPEG"

            # JPEG doesn’t support alpha, so convert if needed
            if out_format in {
                "JPEG",
                "JPG",
            } and img.mode in (
                "RGBA",
                "LA",
                "P",
            ):
                img = img.convert("RGB")

            img.save(
                output_path, format=out_format
            )
            print(
                f"""
Saved {output_path} [{out_format}], original mode={img.mode!r}
"""
            )
    except FileNotFoundError:
        print(
            f"Error: file not found: {input_path}"
        )
    except UnidentifiedImageError:
        print(
            f"Error: cannot identify image file {input_path}"
        )
    except Exception as e:
        print(f"Unexpected error: {e!r}")


def main() -> None:
    args = parse_args()
    convert_image(
        args.input_path, args.output_path
    )


if __name__ == "__main__":
    main()
