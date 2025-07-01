"""
Split a file into sections based on a delimiter and save each section to a new file.

Usage:
    splitm.py [options] <input>

Options:
    -h, --help      Show this help message and exit
    -d, --delimiter Delimiter to split on
    -p, --prefix    Prefix for output filenames
"""

import argparse
from typing import cast
from dataclasses import dataclass


@dataclass()
class Args:
    """
    Dataclass to store command-line arguments.

    Attributes:
        input_filename: the name of the input file to split
        delimiter: the delimiter to split on
        output_prefix: prefix for output filenames
    """

    input_filename: str = "tmp"
    delimiter: str = "---"
    output_prefix: str = "section_"


def split_file(
    input_filename: str = "tmp",
    delimiter: str = "---",
    output_prefix: str = "section_",
):
    """
    Split a file into sections based on a delimiter and save each section to a new file.

    Args:
        input_filename (str): Name of the input file to split
        delimiter (str): Delimiter to split on
        output_prefix (str): Prefix for output filenames
    """

    try:
        # Read the entire file
        with open(
            input_filename, "r", encoding="utf-8"
        ) as file:
            content = file.read()

        # Split the content by the delimiter
        sections = content.split(delimiter)

        # Remove empty sections (in case file starts/ends with delimiter)
        sections = [
            section.strip()
            for section in sections
            if section.strip()
        ]

        if not sections:
            print(
                f"No content found in {input_filename} or no sections to split."
            )
            return

        # Save each section to a new file
        for i, section in enumerate(sections, 1):
            output_filename = (
                f"{output_prefix}{i}.txt"
            )

            with open(
                output_filename,
                "w",
                encoding="utf-8",
            ) as output_file:
                _ = output_file.write(section)

            print(
                f"Created {output_filename} ({len(section)} characters)"
            )

        print(
            f"\nSuccessfully split {input_filename} into {len(sections)} sections."
        )

    except FileNotFoundError:
        print(
            f"Error: File '{input_filename}' not found."
        )
    except PermissionError:
        print(
            f"Error: Permission denied when accessing '{input_filename}'."
        )
    except Exception as e:
        print(f"Error: {e}")


def parse_args():

    parser = argparse.ArgumentParser(
        description="Split a file into sections based on a delimiter and save each section to a new file.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    _ = parser.add_argument(
        "input",
        type=str,
        help="Name of the input file to split",
    )
    _ = parser.add_argument(
        "-d",
        "--delimiter",
        type=str,
        default="---",
        help="Delimiter to split on",
    )
    _ = parser.add_argument(
        "-p",
        "--prefix",
        type=str,
        default="section_",
        help="Prefix for output filenames",
    )
    parsed_args = parser.parse_args()
    args = Args()
    args.input_filename = cast(
        str,
        parsed_args.input,
    )
    args.delimiter = cast(
        str,
        parsed_args.delimiter,
    )
    args.output_prefix = cast(
        str,
        parsed_args.prefix,
    )

    return args


if __name__ == "__main__":

    # Run the function with default parameters
    args = parse_args()
    split_file(args.input_filename, args.delimiter, args.output_prefix)
