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
    default_ignore_globs: list[str] = field(
        default_factory=lambda: [
            ".git/*",
            ".svn/*",
            ".hg/*",
            "__pycache__/*",
            ".pytest_cache/*",
            ".mypy_cache/*",
            ".tox/*",
            ".venv/*",
            ".coverage",
            ".DS_Store",
            ".idea/*",
            ".vscode/*",
            "*_templ.go",
            "LICENSE",
            "LICENSE.md",
            "LICENSE.txt",
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
    globs: list[str] = field(default_factory=list)
    ignore_globs: list[str] = field(default_factory=list)
    directory: str = "."
    files: list[str] = field(default_factory=list)
    content_pattern: str = ""
    show_line_numbers: bool = False
    omit_bins: bool = False


def wildcard_to_regex(pattern: str) -> str:
    """Convert shell-style wildcard pattern to regex pattern."""
    result = re.escape(pattern)
    result = result.replace(r"\*", ".*").replace(r"\?", ".")
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
    ext = Path(file_path).suffix.lower().lstrip(".")

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


def matches_glob_pattern(file_path: str, pattern: str) -> bool:
    """Check if a file matches a glob pattern."""
    filename = os.path.basename(file_path)

    # Convert glob pattern to regex
    regex_pattern = wildcard_to_regex(pattern)
    regex = re.compile(regex_pattern)

    # Check both filename and full path
    return bool(regex.search(filename) or regex.search(file_path))


def should_include(
    file_path: str, glob_patterns: list[str], ignore_glob_patterns: list[str]
) -> bool:
    """Check if a file should be included based on glob patterns."""
    # If ignore patterns match, exclude the file
    for pattern in ignore_glob_patterns:
        if matches_glob_pattern(file_path, pattern):
            return False

    # If no include patterns specified, include by default (unless ignored above)
    if not glob_patterns:
        return True

    # Check if file matches any include pattern
    for pattern in glob_patterns:
        if matches_glob_pattern(file_path, pattern):
            return True

    return False


def get_real_path(path: str) -> str:
    """Get the real absolute path using Python's built-in path resolution."""
    try:
        return str(Path(path).resolve())
    except Exception:
        return os.path.abspath(path)


def should_ignore(
    file_path: str,
    ignore_glob_patterns: list[str],
    ignore_dirs: list[str],
) -> bool:
    """Check if a file matches any ignore pattern or is in an ignored directory."""
    real_file_path = get_real_path(file_path)

    for ignore_dir in ignore_dirs:
        if os.sep not in ignore_dir and ignore_dir in file_path.split(os.sep):
            return True

        if os.path.dirname(file_path).endswith(os.sep + ignore_dir):
            return True

        if os.sep in ignore_dir:
            real_ignore_dir = get_real_path(ignore_dir.rstrip("/"))
            if real_file_path.startswith(real_ignore_dir):
                return True

            dir_path = os.path.dirname(file_path)
            if ignore_dir.rstrip("/") in dir_path:
                return True

    for pattern in ignore_glob_patterns:
        if matches_glob_pattern(file_path, pattern):
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
        "--ignore-dir",
        action="append",
        help="Ignore directory DIR (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--globs",
        action="append",
        help="Only include files matching glob pattern (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--ignore-globs",
        action="append",
        help="Ignore files matching glob pattern (can be used multiple times)",
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
        "--omit-bins",
        action="store_true",
        help="Skip binary files in output",
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
    args.directory = cast(str, parsed_args.directory)
    args.files = cast(list[str], parsed_args.files or [])
    args.content_pattern = cast(str, parsed_args.pattern or "")
    args.show_line_numbers = cast(bool, parsed_args.line_numbers)
    args.omit_bins = cast(bool, parsed_args.omit_bins)

    ignore_dir_list = cast(list[str] | None, parsed_args.ignore_dir)
    if ignore_dir_list:
        args.ignore_dir.extend(ignore_dir_list)

    globs_list = cast(list[str] | None, parsed_args.globs)
    if globs_list:
        args.globs.extend(globs_list)

    ignore_globs_list = cast(list[str] | None, parsed_args.ignore_globs)
    if ignore_globs_list:
        args.ignore_globs.extend(ignore_globs_list)

    # Process files
    for file in args.files:
        if os.path.isfile(file):
            basename = os.path.basename(file)
            args.globs.append(basename)
        else:
            args.globs.append(file)

    return args


def find_files(args: Args) -> list[str]:
    """Find all files in the directory based on the provided arguments."""
    files: list[str] = []
    maxdepth = float("inf") if args.recursive else 1

    # Walk directory structure
    dir_stack: list[tuple[str, int]] = [(args.directory, 0)]
    while dir_stack:
        current_dir, current_depth = dir_stack.pop()

        if current_depth >= maxdepth:
            continue

        try:
            entries = sorted(os.listdir(current_dir))

            for entry in entries:
                if entry in (".", ".."):
                    continue

                if not args.show_all and entry.startswith("."):
                    continue

                full_path = os.path.join(current_dir, entry)

                if os.path.isdir(full_path):
                    if not should_ignore(
                        full_path,
                        args.default_ignore_globs + args.ignore_globs,
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
    return files


def process_file(file_path: str, args: Args) -> None:
    """Process a single file and output its contents."""
    if args.directory == ".":
        rel_path: str = file_path
    else:
        try:
            rel_path = str(Path(file_path).relative_to(Path(args.directory)))
        except ValueError:
            rel_path = file_path

    if not should_include(rel_path, args.globs, args.ignore_globs):
        return

    if should_ignore(
        rel_path,
        args.default_ignore_globs + args.ignore_globs,
        args.ignore_dir,
    ):
        if args.debug:
            print(
                f"Debug: Ignoring file: {rel_path}",
                file=sys.stderr,
            )
        return

    if args.omit_bins and is_binary(file_path):
        if args.debug:
            print(
                f"Debug: Skipping binary file: {rel_path}",
                file=sys.stderr,
            )
        return

    safe_path = escape(rel_path)
    print(f'<file path="{safe_path}">')

    if is_binary(file_path):
        print("<binary>true</binary>")  # binary
        print(  # binary content
            "<content>[Binary file - contents not displayed]</content>"
        )
    else:
        filetype = guess_filetype(file_path)
        print(f"<type>{escape(filetype)}</type>")

        try:
            with open(
                file_path,
                "r",
                encoding="utf-8",
                errors="replace",
            ) as f:
                content = f.readlines()

            line_count = len(content)
            filtered_content: list[tuple[int, str]] = []

            if args.content_pattern:
                try:
                    regex_pattern = wildcard_to_regex(args.content_pattern)
                    pattern = re.compile(regex_pattern)
                    for i, line in enumerate(content):
                        if pattern.search(line):
                            filtered_content.append((i + 1, line))
                except re.error as e:
                    print(f"<error>Error in pattern: {escape(str(e))}</error>")
                    filtered_content = [(i + 1, line) for i, line in enumerate(content)]
            else:
                filtered_content = [(i + 1, line) for i, line in enumerate(content)]

            filtered_count = len(filtered_content)

            if filtered_count > 1000 and not args.content_pattern:
                to_display = filtered_content[:100]
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
                print(f"... ({line_count - 100} more lines)")

            print("</content>")

        except Exception as e:
            print(f"<error>{escape(str(e))}</error>")

    print("</file>")


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
    args.ignore_dir = [d.rstrip("/") for d in args.ignore_dir]

    if args.debug:
        print(
            f"Debug: Ignoring directories: {args.ignore_dir}",
            file=sys.stderr,
        )

    # Find all files
    files = find_files(args)

    if not files:
        print(f"No files found in directory: {args.directory}")
        return

    print("<files>")

    for file_path in files:
        process_file(file_path, args)

    print("</files>")


if __name__ == "__main__":
    main()
