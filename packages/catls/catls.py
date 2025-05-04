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


def get_real_path(path: str) -> str:
    """Get the real absolute path using shell commands.
    
    Args:
        path: Path to resolve
        
    Returns:
        Resolved absolute path
    """
    try:
        # First try with realpath which is common on most systems
        result = subprocess.run(
            ["realpath", path], 
            capture_output=True, 
            text=True, 
            check=False
        )
        if result.returncode == 0:
            return result.stdout.strip()
            
        # If realpath fails, try readlink -f
        result = subprocess.run(
            ["readlink", "-f", path], 
            capture_output=True, 
            text=True, 
            check=False
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        # Fall back to Python's implementation if shell commands fail
        pass
        
    # If all shell commands fail, use Python's abspath
    return os.path.abspath(path)


def should_ignore(
    file_path: str, ignore_patterns: list[str], ignore_dirs: list[str]
) -> bool:
    """Check if a file matches any ignore pattern or is in an ignored directory.

    Args:
        file_path: Path to the file
        ignore_patterns: List of regex patterns to match for exclusion
        ignore_dirs: List of directory paths to exclude

    Returns:
        True if the file should be ignored, False otherwise
    """
    # Use shell commands to get real paths for file
    real_file_path = get_real_path(file_path)
    
    # Check if the file matches basic filename checks for ignored dirs
    for ignore_dir in ignore_dirs:
        # Simple case: exact directory name match (like 'node_modules')
        if os.sep not in ignore_dir and ignore_dir in file_path.split(os.sep):
            return True
            
        # Check if the directory portion ends with the ignore_dir
        if os.path.dirname(file_path).endswith(os.sep + ignore_dir):
            return True
            
        # For path-like ignore directories (like ./pkg/lzma/)
        if os.sep in ignore_dir:
            # Use shell command to resolve the ignore_dir path
            real_ignore_dir = get_real_path(ignore_dir.rstrip('/'))
            
            # Check if file_path starts with ignore_dir (bash-like comparison)
            if real_file_path.startswith(real_ignore_dir):
                return True
                
            # Check if ignore_dir is a suffix of any directory component
            dir_path = os.path.dirname(file_path)
            if ignore_dir.rstrip('/') in dir_path:
                return True
                
    # Check if file matches any regex pattern
    for pattern in ignore_patterns:
        if re.search(pattern, file_path):
            return True

    return False


@dataclass
class Args:
    """Type-safe container for command line arguments."""

    show_all: bool = False
    recursive: bool = False
    debug: bool = False
    # Default common directories to ignore
    ignore_regex: list[str] = field(default_factory=lambda: [
        r"\.git/",
        r"\.svn/",
        r"\.hg/",
        r"__pycache__/",
        r"\.pytest_cache/",
        r"\.mypy_cache/",
        r"\.tox/",
        r"\.venv/",
        r"\.coverage",
        r"\.DS_Store",
        r"\.idea/",
        r"\.vscode/",
        r".*_templ\.go$",  # Added pattern to ignore *_templ.go files
        r"LICENSE$",       # Ignore LICENSE files
        r"LICENSE\.md$",   # Ignore LICENSE.md files
        r"LICENSE\.txt$",  # Ignore LICENSE.txt files
    ])
    # Default common directories to ignore
    ignore_dir: list[str] = field(default_factory=lambda: [
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
        "--ignore-regex",
        action="append",
        default=[],
        help="Ignore files matching PATTERN (can be used multiple times)",
    )
    _ = parser.add_argument(
        "--ignore-dir",
        action="append",
        default=[],
        help="Ignore directory DIR (can be used multiple times). Can be a directory name or path. Use './path/to/dir' for relative paths.",
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
    _ = parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug output"
    )

    # Create our type-safe Args container with default ignores
    args_container = Args()

    # Use custom parsing to handle shell wildcard expansion
    try:
        args_namespace, unknown = parser.parse_known_args()
        # Convert Namespace to dictionary and extract values with proper types
        args_dict = vars(args_namespace)

_numbers = args_dict.get("line_numbers", False)

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
    
    # Set up debug mode based on command line argument
    if args.debug:
        os.environ["CATLS_DEBUG"] = "1"

    # Set up directory and check if it exists
    directory: str = args.directory
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a valid directory.")
        sys.exit(1)
        
    # Special handling for --ignore-dir to match shell behavior
    # If we receive paths with ./ prefix, convert them to use basenames
    for i, ignore_dir in enumerate(args.ignore_dir):
        if os.environ.get("CATLS_DEBUG"):
            print(f"Debug: Processing ignore dir: {ignore_dir}", file=sys.stderr)
            
        # Strip trailing slashes for consistency
        args.ignore_dir[i] = ignore_dir.rstrip('/')

    # Find all files in the directory based on options
    files: list[str] = []

    # Calculate the proper maxdepth value for os.walk
    maxdepth: float | int = float("inf") if args.recursive else 1

    # Debug output for ignored directories
    if os.environ.get("CATLS_DEBUG"):
        print(f"Debug: Ignoring directories: {args.ignore_dir}", file=sys.stderr)
        
    # Debug the raw ignore directories first
    if os.environ.get("CATLS_DEBUG"):
        print(f"Debug: Raw ignore directories from arguments: {args.ignore_dir}", file=sys.stderr)
    
    # We'll keep the ignore_dir list as-is, since we'll use shell utilities
    # for path comparison directly when needed

    # Walk through the directory structure
    for dirpath, dirnames, filenames in os.walk(directory):
        # Skip hidden directories if not showing hidden files
        if not args.show_all:
            dirnames[:] = [d for d in dirnames if not d.startswith(".")]
            
        # Skip ignored directories early during the walk
        # This prevents descending into them unnecessarily
        dirnames_to_keep = []
        for d in dirnames:
            full_dir_path = os.path.join(dirpath, d)
            
            # Use shell-like path comparison for directory detection
            if not should_ignore(full_dir_path, args.ignore_regex, args.ignore_dir):
                dirnames_to_keep.append(d)
            elif os.environ.get("CATLS_DEBUG"):
                print(f"Debug: Ignoring directory: {full_dir_path}", file=sys.stderr)
                
        dirnames[:] = dirnames_to_keep

        # Calculate current depth
        current_depth: int = dirpath.count(os.sep) - directory.count(os.sep)
        if current_depth >= maxdepth:
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

    # Print XML header once
    print('<files>')
    
    # For each file, print filename and contents in XML format
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

        # Skip files matching ignore patterns or in ignored directories
        if should_ignore(rel_path, args.ignore_regex, args.ignore_dir):
            if os.environ.get("CATLS_DEBUG"):
                print(f"Debug: Ignoring file: {rel_path}", file=sys.stderr)
            continue

        # XML escape the path for safety
        import html
        safe_path = html.escape(rel_path)
        
        print(f'<file path="{safe_path}">')

        if is_binary(file_path):
            print('  <binary>true</binary>')
            print('  <content>[Binary file - contents not displayed]</content>')
        else:
            # Get file type hint
            filetype: str = guess_filetype(file_path)
            print(f'  <type>{html.escape(filetype)}</type>')

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
                        print(f'    <error>Error in pattern: {html.escape(str(e))}</error>')
                        filtered_content = [(i, line) for i, line in enumerate(content, 1)]
                else:
                    filtered_content = [(i, line) for i, line in enumerate(content, 1)]
                
                # Count filtered lines
                filtered_count: int = len(filtered_content)

                # Determine if we should limit displayed lines
                if filtered_count > 1000 and not args.content_pattern:
                    # If no pattern and many lines, just show first 100
                    to_display = filtered_content[:100]
                    print_trailing_message = True
                else:
                    # Otherwise show all filtered lines
                    to_display = filtered_content
                    print_trailing_message = False
                
                print('  <content>')
                # Print the content with optional line numbers
                for line_num, line in to_display:
                    if args.show_line_numbers:
                        print(f"{line_num:4d}| {line}", end="")
                    else:
                        print(line, end="")
                
                # Print message about omitted lines if needed
                if print_trailing_message:
                    print(f"... ({line_count - 100} more lines)")
                
                print('  </content>')
            except Exception as e:
                print(f'  <error>{html.escape(str(e))}</error>')

        print('</file>')
    
    # Print XML footer
    print('</files>')


if __name__ == "__main__":
    main()
