#!/usr/bin/env python3
import os
import re
import argparse
import subprocess
import sys
from dataclasses import dataclass, field


def wildcard_to_regex(pattern: str) -> str:
    """Convert a shell-style wildcard pattern to a regex pattern.

    Args:
        pattern: Shell-style wildcard pattern (e.g., *.py, test?.txt)

    Returns:
        Equivalent regex pattern
    """
    # Escape special regex characters except * and ?
    result = re.escape(pattern)
    # Convert shell wildcards to regex equivalents
    result = result.replace("\\*", ".*").replace("\\?", ".")
    return result


def is_binary(file_path: str) -> bool:
    """Check if a file is binary using the 'file' command.

    Args:
        file_path: Path to the file to check

    Returns:
        True if the file is binary, False otherwise
    """
    try:
        result: subprocess.CompletedProcess[str] = subprocess.run(
            ["file", file_path], capture_output=True, text=True
        )
        return "text" not in result.stdout.lower()
    except Exception:
        # If the 'file' command fails, try a simple binary check
        try:
            with open(file_path, "rb") as f:
                chunk: bytes = f.read(1024)
                return b"\0" in chunk
        except Exception:
            return True  # Assume binary if we can't check


def guess_filetype(file_path: str) -> str:
    """Guess file type based on extension.

    Args:
        file_path: Path to the file

    Returns:
        String representing the file type, or empty string if unknown
    """
    ext: str = os.path.splitext(file_path)[1].lower().lstrip(".")

    filetypes: dict[str, str] = {
        "sh": "bash",
        "bash": "bash",
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
        "rb": "ruby",
        "php": "php",
        "pl": "perl",
        "sql": "sql",
        "templ": "templ",
        "yml": "yaml",
        "yaml": "yaml",
    }

    return filetypes.get(ext, "")


def should_include(file_path: str, include_patterns: list[str]) -> bool:
    """Check if a file should be included based on patterns.

    Args:
        file_path: Path to the file
        include_patterns: List of regex patterns to match for inclusion

    Returns:
        True if the file should be included, False otherwise
    """
    if not include_patterns:
        return True  # Include all files if no patterns specified

    # Get just the filename portion for simpler matching
    filename = os.path.basename(file_path)

    for pattern in include_patterns:
        # Handle shell-style wildcards by converting to regex
        if "*" in pattern or "?" in pattern:
            # Convert shell wildcard to regex pattern
            regex_pattern = wildcard_to_regex(pattern)
            if re.search(regex_pattern, filename) or re.search(
                regex_pattern, file_path
            ):
                return True
        # Regular regex pattern
        elif re.search(pattern, file_path):
            return True

    return False


def should_ignore(file_path: str, ignore_patterns: list[str]) -> bool:
    """Check if a file matches any ignore pattern.

    Args:
        file_path: Path to the file
        ignore_patterns: List of patterns to match for exclusion

    Returns:
        True if the file should be ignored, False otherwise
    """
    # Normalize the path for consistent matching
    normalized_path = os.path.normcase(os.path.normpath(file_path))
    
    # Get path components for directory matching
    path_parts = normalized_path.split(os.sep)
    
    # Check exact filename match first
    filename = os.path.basename(normalized_path)
    if filename in ignore_patterns:
        return True
    
    # Check if any path component matches an exact directory name to ignore
    for part in path_parts:
        if part in ignore_patterns:
            return True
    
    # Check regex patterns
    for pattern in ignore_patterns:
        if pattern.endswith("/") or pattern.endswith("\\"):
            # This is a directory pattern, look for it in the path
            dir_name = pattern.rstrip("/\\")
            if dir_name in path_parts:
                return True
        elif "*" in pattern or "?" in pattern:
            # This is a wildcard pattern, convert to regex
            regex_pattern = wildcard_to_regex(pattern)
            if re.search(regex_pattern, normalized_path):
                return True
        elif re.search(pattern, normalized_path):
            # This is already a regex pattern
            return True
    
    return False


@dataclass
class Args:
    """Type-safe container for command line arguments."""

    show_all: bool = False
    recursive: bool = False
    # Default common files and directories to ignore
    ignore_patterns: list[str] = field(default_factory=lambda: [
        # Common version control directories
        ".git", ".git/", r"\.git/",
        ".svn", ".svn/", r"\.svn/",
        ".hg", ".hg/", r"\.hg/",
        # Common cache directories
        "__pycache__", "__pycache__/", r"__pycache__/",
        ".pytest_cache", ".pytest_cache/", r"\.pytest_cache/",
        ".mypy_cache", ".mypy_cache/", r"\.mypy_cache/",
        ".tox", ".tox/", r"\.tox/",
        ".venv", ".venv/", r"\.venv/",
        # Common system files
        ".coverage", r"\.coverage",
        ".DS_Store", r"\.DS_Store",
        # IDE directories
        ".idea", ".idea/", r"\.idea/",
        ".vscode", ".vscode/", r"\.vscode/",
        # Common package directories
        "node_modules", "node_modules/",
        # Nix-specific files/directories
        ".direnv", ".direnv/",
        "flake.lock",
        # Build directories
        "build", "build/",
        "dist", "dist/",
        "target", "target/",
        # Virtual environments
        "venv", "venv/",
        "env", "env/",
        ".env", ".env/",
        # Dependencies
        "vendor", "vendor/",
        ".bundle", ".bundle/",
        "coverage", "coverage/",
    ])
    include_regex: list[str] = field(default_factory=list)
    directory: str = "."
    files: list[str] = field(default_factory=list)
    content_pattern: str = ""
    show_line_numbers: bool = False


def parse_args() -> Args:
    """Parse command line arguments in a type-safe way.

    Returns:
        An Args object with properly typed fields
    """
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="List contents of files in the specified directory with filename headers"
    )
    _ = parser.add_argument(
        "-a", "--all", action="store_true", help="Include hidden files"
    )
    _ = parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recursively list files in subdirectories",
    )
    _ = parser.add_argument(
        "--ignore",
        action="append",
        default=[],
        help="Ignore files or directories matching PATTERN (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--regex",
        action="append",
        default=[],
        help="Only include files matching PATTERN (can be used multiple times)",
    )
    _ = parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to process (default: current directory)",
    )
    _ = parser.add_argument(
        "files",
        nargs="*",
        help="Files to process (if expanded by shell)",
    )
    _ = parser.add_argument(
        "--pattern",
        default="",
        help="Only show lines matching glob PATTERN (e.g., '*import*', 'def *')",
    )
    _ = parser.add_argument(
        "-n", "--line-numbers",
        action="store_true",
        help="Show line numbers"
    )

    # Create our type-safe Args container with default ignores
    args_container = Args()

    # Use custom parsing to handle shell wildcard expansion
    try:
        args_namespace, unknown = parser.parse_known_args()
        # Convert Namespace to dictionary and extract values with proper types
        args_dict = vars(args_namespace)

        # Transfer the known arguments to our type-safe container with proper types
        args_container.show_all = args_dict.get("all", False)
        args_container.recursive = args_dict.get("recursive", False)
        
        # Add any additional ignore patterns from command line
        if args_dict.get("ignore"):
            args_container.ignore_patterns.extend(args_dict.get("ignore", []))
            
        args_container.include_regex = args_dict.get("regex", [])
        args_container.directory = args_dict.get("directory", ".")
        args_container.files = args_dict.get("files", [])
        args_container.content_pattern = args_dict.get("pattern", "")
        args_container.show_line_numbers = args_dict.get("line_numbers", False)

        # If we have unknown arguments, they might be shell-expanded wildcards
        if unknown:
            # Add these as individual patterns to match
            for item in unknown:
                # Check if it's a file that exists (shell already expanded)
                if os.path.isfile(item):
                    args_container.files.append(item)
                else:
                    # It might be a pattern, add to regex
                    args_container.include_regex.append(item)
    except Exception as e:
        print(f"Error parsing arguments: {e}")
        parser.print_help()
        sys.exit(1)

    # Process shell-expanded files
    for file in args_container.files:
        # If it's a path, use the full path for matching
        if os.path.exists(file):
            # Use the basename for matching in our file list
            basename = os.path.basename(file)
            # Add an exact match regex
            args_container.include_regex.append(f"^{re.escape(basename)}$")

    return args_container


def main() -> None:
    """Main function to run the catls program."""
    # Parse command-line arguments in a type-safe way
    args: Args = parse_args()

    # Set up directory and check if it exists
    directory: str = args.directory
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a valid directory.")
        sys.exit(1)

    # Find all files in the directory based on options
    files: list[str] = []

    # Calculate the proper maxdepth value for os.walk
    maxdepth: float | int = float("inf") if args.recursive else 1

    # Walk through the directory structure
    for dirpath, dirnames, filenames in os.walk(directory):
        # Skip hidden directories if not showing hidden files
        if not args.show_all:
            dirnames[:] = [d for d in dirnames if not d.startswith(".")]
            
        # Skip ignored directories early during the walk
        # This prevents descending into them unnecessarily
        dirnames[:] = [d for d in dirnames if not should_ignore(
            os.path.join(dirpath, d), 
            args.ignore_patterns
        )]

        # Calculate current depth
        current_depth: int = dirpath.count(os.sep) - directory.count(os.sep)
        if current_depth > maxdepth:
            # Skip deeper directories
            dirnames[:] = []
            continue

        # Add files to the list
        for filename in filenames:
            # Skip hidden files if not showing hidden files
            if not args.show_all and filename.startswith("."):
                continue

            file_path: str = os.path.join(dirpath, filename)
            files.append(file_path)

    # Sort files alphabetically
    files.sort()

    # If no files found
    if not files:
        print(f"No files found in directory: {directory}")
        sys.exit(0)

    # For each file, print filename and contents in a code block
    for file_path in files:
        # Get relative path from the specified directory
        rel_path: str
        if directory == ".":
            rel_path = file_path
        else:
            try:
                rel_path = os.path.relpath(file_path, directory)
            except ValueError:
                # On some Windows systems, relpath might fail with paths on different drives
                rel_path = file_path

        # Skip files not matching include patterns
        if not should_include(rel_path, args.include_regex):
            continue

        # Skip files matching ignore patterns
        if should_ignore(rel_path, args.ignore_patterns):
            continue

        print(f"### {rel_path}")

        if is_binary(file_path):
            print("[Binary file - contents not displayed]")
        else:
            # Get file type hint
            filetype: str = guess_filetype(file_path)

            try:
                with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                    content: list[str] = f.readlines()

                # Count total lines
                line_count: int = len(content)
                
                # Filter content based on pattern if provided
                filtered_content: list[tuple[int, str]] = []
                if args.content_pattern:
                    try:
                        # Convert glob pattern to regex
                        regex_pattern = wildcard_to_regex(args.content_pattern)
                        pattern = re.compile(regex_pattern)
                        for i, line in enumerate(content, 1):
                            if pattern.search(line):
                                filtered_content.append((i, line))
                    except re.error as e:
                        print(f"Error in pattern: {e}")
                        filtered_content = [(i, line) for i, line in enumerate(content, 1)]
                else:
                    filtered_content = [(i, line) for i, line in enumerate(content, 1)]
                
                # Count filtered lines
                filtered_count: int = len(filtered_content)

                # Print code block header with file type if available
                if filetype:
                    print(f"```{filetype} file='{rel_path}'")
                else:
                    print("```")

                # If pattern is provided, show a summary
                if args.content_pattern:
                    print(f"# Showing {filtered_count} matching lines for pattern: '{args.content_pattern}'")
                
                # Determine if we should limit displayed lines
                if filtered_count > 1000 and not args.content_pattern:
                    # If no pattern and many lines, just show first 100
                    to_display = filtered_content[:100]
                    print_trailing_message = True
                else:
                    # Otherwise show all filtered lines
                    to_display = filtered_content
                    print_trailing_message = False
                
                # Print the content with optional line numbers
                for line_num, line in to_display:
                    if args.show_line_numbers:
                        print(f"{line_num:4d}| {line}", end="")
                    else:
                        print(line, end="")
                
                # Print message about omitted lines if needed
                if print_trailing_message:
                    print(f"... ({line_count - 100} more lines)")

                print("```")
            except Exception as e:
                print(f"Error reading file: {e}")
                print("```")
                print("[Error reading file content]")
                print("```")

        print()  # Empty line after each file


if __name__ == "__main__":
    main()
