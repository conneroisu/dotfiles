#!/usr/bin/env python3
from __future__ import annotations
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path
from html import escape
from dataclasses import dataclass, field
from typing import cast


@dataclass
class Args:
    show_all: bool = False
    recursive: bool = False
    debug: bool = False
    ignore_regex: list[re.Pattern[str]] = field(
        default_factory=lambda: [
            re.compile(r"\.git/"),
            re.compile(r"\.svn/"),
            re.compile(r"\.hg/"),
            re.compile(r"__pycache__/"),
            re.compile(r"\.pytest_cache/"),
            re.compile(r"\.mypy_cache/"),
            re.compile(r"\.tox/"),
            re.compile(r"\.venv/"),
            re.compile(r"\.coverage"),
            re.compile(r"\.DS_Store"),
            re.compile(r"\.idea/"),
            re.compile(r"\.vscode/"),
            re.compile(r".*_templ\.go$"),
            re.compile(r"LICENSE$"),
            re.compile(r"LICENSE\.md$"),
            re.compile(r"LICENSE\.txt$"),
        ]
    )
    ignore_dir: list[str] = field(
        default_factory=lambda: [
            "node_modules",
            ".direnv",
            "build",
            "dist",
            "target",
            "venv",
            "env",
            ".env",
            "vendor",
            ".bundle",
            "coverage",
            "static",
        ]
    )
    include_regex: list[str] = field(
        default_factory=list
    )
    directory: str = "."
    files: list[str] = field(default_factory=list)
    content_pattern: str = ""
    show_line_numbers: bool = False


def wildcard_to_regex(pattern: str) -> str:
    """Convert shell-style wildcard pattern to regex pattern."""
    result = re.escape(pattern)
    result = result.replace(r"\*", ".*").replace(
        r"\?", "."
    )
    return result


def is_binary(file_path: str) -> bool:
    """Check if a file is binary using the 'file' command."""
    try:
        result = subprocess.run(
            ["file", file_path],
            capture_output=True,
            text=True,
        )
        return "text" not in result.stdout.lower()
    except (
        subprocess.SubprocessError,
        FileNotFoundError,
    ):
        try:
            with open(file_path, "rb") as f:
                chunk = f.read(1024)
                return b"\0" in chunk
        except Exception:
            return True


def guess_filetype(file_path: str) -> str:
    """Guess file type based on extension."""
    ext = (
        Path(file_path).suffix.lower().lstrip(".")
    )

    filetypes = {
        "sh": "bash",
        "bash": "bash",
        "rb": "ruby",
        "py": "python",
        "js": "javascript",
        "html": "html",
        "nix": "nix",
        "css": "css",
        "json": "json",
        "md": "markdown",
        "xml": "xml",
        "c": "c",
        "cpp": "cpp",
        "h": "c",
        "toml": "toml",
        "hpp": "cpp",
        "java": "java",
        "rs": "rust",
        "go": "go",
        "php": "php",
        "pl": "perl",
        "sql": "sql",
        "templ": "templ",
        "yml": "yaml",
        "yaml": "yaml",
    }

    return filetypes.get(ext, "")


def should_include(
    file_path: str, include_patterns: list[str]
) -> bool:
    """Check if a file should be included based on patterns."""
    if not include_patterns:
        return True

    filename = os.path.basename(file_path)

    for pattern in include_patterns:
        if "*" in pattern or "?" in pattern:
            regex_pattern = wildcard_to_regex(
                pattern
            )
            regex = re.compile(regex_pattern)
            if regex.search(
                filename
            ) or regex.search(file_path):
                return True
        else:
            try:
                if re.compile(pattern).search(
                    file_path
                ):
                    return True
            except re.error:
                continue

    return False


def get_real_path(path: str) -> str:
    """Get the real absolute path using shell commands."""
    try:
        result = subprocess.run(
            ["realpath", path],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        if (
            result.returncode == 0
            and result.stdout.strip()
        ):
            return result.stdout.strip()

        result = subprocess.run(
            ["readlink", "-f", path],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        if (
            result.returncode == 0
            and result.stdout.strip()
        ):
            return result.stdout.strip()
    except FileNotFoundError:
        pass

    try:
        return str(Path(path).resolve())
    except Exception:
        return os.path.abspath(path)


def should_ignore(
    file_path: str,
    ignore_patterns: list[re.Pattern[str]],
    ignore_dirs: list[str],
) -> bool:
    """Check if a file matches any ignore pattern or is in an ignored directory."""
    real_file_path = get_real_path(file_path)

    for ignore_dir in ignore_dirs:
        if (
            os.sep not in ignore_dir
            and ignore_dir
            in file_path.split(os.sep)
        ):
            return True

        if os.path.dirname(file_path).endswith(
            os.sep + ignore_dir
        ):
            return True

        if os.sep in ignore_dir:
            real_ignore_dir = get_real_path(
                ignore_dir.rstrip("/")
            )
            if real_file_path.startswith(
                real_ignore_dir
            ):
                return True

            dir_path = os.path.dirname(file_path)
            if ignore_dir.rstrip("/") in dir_path:
                return True

    for pattern in ignore_patterns:
        if pattern.search(file_path):
            return True

    return False


def parse_args() -> Args:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="List files and their contents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    _ = parser.add_argument(
        "-a",
        "--all",
        action="store_true",
        help="Include hidden files",
    )
    _ = parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recursively list files in subdirectories",
    )
    _ = parser.add_argument(
        "--ignore-regex",
        action="append",
        help="Ignore files matching PATTERN (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--ignore-dir",
        action="append",
        help="Ignore directory DIR (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--regex",
        action="append",
        help="Only include files matching PATTERN (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--pattern",
        help="Only show lines matching glob PATTERN",
    )
    _ = parser.add_argument(
        "-n",
        "--line-numbers",
        action="store_true",
        help="Show line numbers",
    )
    _ = parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug output",
    )
    _ = parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to scan",
    )
    _ = parser.add_argument(
        "files",
        nargs="*",
        help="Specific files to include",
    )

    parsed_args = parser.parse_args()

    args = Args()
    args.show_all = cast(
        bool,
        parsed_args.all,
    )
    args.recursive = cast(
        bool, 
        parsed_args.recursive,
    )
    args.debug = cast(
        bool,
        parsed_args.debug,
    )
    args.directory = cast(
        str, parsed_args.directory
    )
    args.files = cast(
        list[str], parsed_args.files or []
    )
    args.content_pattern = cast(
        str, parsed_args.pattern or ""
    )
    args.show_line_numbers = cast(
        bool, parsed_args.line_numbers
    )

    ignore_regex_list = cast(
        list[str] | None, parsed_args.ignore_regex
    )
    if ignore_regex_list:
        for pattern in ignore_regex_list:
            try:
                args.ignore_regex.append(
                    re.compile(pattern)
                )
            except re.error as e:
                print(
                    f"Error: Invalid regex pattern '{pattern}': {e}",
                    file=sys.stderr,
                )
                sys.exit(1)

    ignore_dir_list = cast(
        list[str] | None, parsed_args.ignore_dir
    )
    if ignore_dir_list:
        args.ignore_dir.extend(ignore_dir_list)

    regex_list = cast(
        list[str] | None, parsed_args.regex
    )
    if regex_list:
        args.include_regex.extend(regex_list)

    # Process files
    for file in args.files:
        if os.path.isfile(file):
            basename = os.path.basename(file)
            args.include_regex.append(
                f"^{re.escape(basename)}$"
            )
        else:
            args.include_regex.append(file)

    return args


def main():
    """Main function."""
    args = parse_args()

    if args.debug:
        os.environ["CATLS_DEBUG"] = "1"

    if not os.path.isdir(args.directory):
        print(
            f"Error: '{args.directory}' is not a valid directory.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Clean up ignore directories
    args.ignore_dir = [
        d.rstrip("/") for d in args.ignore_dir
    ]

    if args.debug:
        print(
            f"Debug: Ignoring directories: {args.ignore_dir}",
            file=sys.stderr,
        )

    # Find all files
    files: list[str] = []
    maxdepth = (
        float("inf") if args.recursive else 1
    )

    # Walk directory structure
    dir_stack = [(args.directory, 0)]
    while dir_stack:
        current_dir, current_depth = (
            dir_stack.pop()
        )

        if current_depth >= maxdepth:
            continue

        try:
            entries = sorted(
                os.listdir(current_dir)
            )

            for entry in entries:
                if entry in (".", ".."):
                    continue

                if (
                    not args.show_all
                    and entry.startswith(".")
                ):
                    continue

                full_path = os.path.join(
                    current_dir, entry
                )

                if os.path.isdir(full_path):
                    if not should_ignore(
                        full_path,
                        args.ignore_regex,
                        args.ignore_dir,
                    ):
                        dir_stack.append(
                            (
                                full_path,
                                current_depth + 1,
                            )
                        )
                    elif args.debug:
                        print(
                            f"Debug: Ignoring directory: {full_path}",
                            file=sys.stderr,
                        )
                elif os.path.isfile(full_path):
                    files.append(full_path)

        except OSError as e:
            print(
                f"Error accessing directory {current_dir}: {e}",
                file=sys.stderr,
            )

    files.sort()

    if not files:
        print(
            f"No files found in directory: {args.directory}"
        )
        return

    print("<files>")

    for file_path in files:
        if args.directory == ".":
            rel_path: str = file_path
        else:
            try:
                rel_path = str(
                    Path(file_path).relative_to(
                        Path(args.directory)
                    )
                )
            except ValueError:
                rel_path = file_path

        if not should_include(
            rel_path, args.include_regex
        ):
            continue

        if should_ignore(
            rel_path,
            args.ignore_regex,
            args.ignore_dir,
        ):
            if args.debug:
                print(
                    f"Debug: Ignoring file: {rel_path}",
                    file=sys.stderr,
                )
            continue

        safe_path = escape(rel_path)
        print(f'<file path="{safe_path}">')

        if is_binary(file_path):
            print(  # binary
                "<binary>true</binary>"
            )
            print(  # binary content
                "<content>[Binary file - contents not displayed]</content>"
            )
        else:
            filetype = guess_filetype(file_path)
            print(
                f"<type>{escape(filetype)}</type>"
            )

            try:
                with open(
                    file_path,
                    "r",
                    encoding="utf-8",
                    errors="replace",
                ) as f:
                    content = f.readlines()

                line_count = len(content)
                filtered_content: list[
                    tuple[int, str]
                ] = []

                if args.content_pattern:
                    try:
                        regex_pattern = wildcard_to_regex(
                            args.content_pattern
                        )
                        pattern = re.compile(
                            regex_pattern
                        )
                        for i, line in enumerate(
                            content
                        ):
                            if pattern.search(
                                line
                            ):
                                filtered_content.append(
                                    (i + 1, line)
                                )
                    except re.error as e:
                        print(
                            f"<error>Error in pattern: {escape(str(e))}</error>"
                        )
                        filtered_content = [
                            (i + 1, line)
                            for i, line in enumerate(
                                content
                            )
                        ]
                else:
                    filtered_content = [
                        (i + 1, line)
                        for i, line in enumerate(
                            content
                        )
                    ]

                filtered_count = len(
                    filtered_content
                )

                if (
                    filtered_count > 1000
                    and not args.content_pattern
                ):
                    to_display = filtered_content[
                        :100
                    ]
                    print_trailing_message = True
                else:
                    to_display = filtered_content
                    print_trailing_message = False

                print("<content>")
                for line_num, line in to_display:
                    if args.show_line_numbers:
                        print(
                            f"{line_num:>4}| {line}",
                            end="",
                        )
                    else:
                        print(line, end="")

                if print_trailing_message:
                    print(
                        f"... ({line_count - 100} more lines)"
                    )

                print("</content>")

            except Exception as e:
                print(
                    f"<error>{escape(str(e))}</error>"
                )

        print("</file>")

    print("</files>")


if __name__ == "__main__":
    main()
