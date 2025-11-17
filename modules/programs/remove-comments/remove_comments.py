#!/usr/bin/env python3
"""
remove-comments: A multi-language comment removal tool

Removes comments from source code files while preserving:
- String literals (single and double quoted)
- Docstrings
- Code structure and whitespace
- Indentation

Supported languages:
- Python (.py)
- JavaScript/TypeScript (.js, .ts, .jsx, .tsx)
- Go (.go)
- Rust (.rs)
- Java (.java)
- Ruby (.rb)
- C/C++ (.c, .cpp, .h, .hpp)
- Shell (.sh, .bash)
- Nix (.nix)
"""

import argparse
import sys
import re
from pathlib import Path
from typing import Tuple, Optional


class CommentRemover:
    """Removes comments from source code while preserving strings and structure."""

    # Language configurations
    LANG_CONFIG = {
        '.py': {
            'single_line': '#',
            'multi_start': '"""',
            'multi_end': '"""',
            'multi_start_alt': "'''",
            'multi_end_alt': "'''",
            'preserve_docstrings': True,
        },
        '.js': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.ts': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.jsx': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.tsx': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.go': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.rs': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.java': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.rb': {
            'single_line': '#',
            'multi_start': '=begin',
            'multi_end': '=end',
            'preserve_docstrings': False,
        },
        '.c': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.cpp': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.h': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.hpp': {
            'single_line': '//',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
        '.sh': {
            'single_line': '#',
            'multi_start': None,
            'multi_end': None,
            'preserve_docstrings': False,
        },
        '.bash': {
            'single_line': '#',
            'multi_start': None,
            'multi_end': None,
            'preserve_docstrings': False,
        },
        '.nix': {
            'single_line': '#',
            'multi_start': '/*',
            'multi_end': '*/',
            'preserve_docstrings': False,
        },
    }

    def __init__(self, file_path: str):
        self.file_path = Path(file_path)
        self.ext = self.file_path.suffix.lower()

        if self.ext not in self.LANG_CONFIG:
            raise ValueError(f"Unsupported file type: {self.ext}")

        self.config = self.LANG_CONFIG[self.ext]

    def is_docstring_line(self, line: str, prev_line: str) -> bool:
        """Check if a line is likely a docstring (for Python)."""
        if not self.config.get('preserve_docstrings'):
            return False

        stripped = line.strip()
        prev_stripped = prev_line.strip()

        # Check for triple-quoted strings at start of functions/classes/modules
        if stripped.startswith('"""') or stripped.startswith("'''"):
            # If previous line is a def, class, or start of file
            if (prev_stripped.endswith(':') or
                prev_stripped == '' or
                prev_stripped.startswith('def ') or
                prev_stripped.startswith('class ')):
                return True

        return False

    def remove_comments(self, content: str) -> str:
        """Remove comments from the content while preserving strings."""
        lines = content.split('\n')
        result = []
        in_multiline = False
        in_docstring = False
        multiline_end = None

        for i, line in enumerate(lines):
            prev_line = lines[i - 1] if i > 0 else ''
            processed_line = self._process_line(
                line,
                in_multiline,
                in_docstring,
                prev_line
            )

            new_line, in_multiline, in_docstring, multiline_end = processed_line
            result.append(new_line)

        return '\n'.join(result)

    def _process_line(
        self,
        line: str,
        in_multiline: bool,
        in_docstring: bool,
        prev_line: str
    ) -> Tuple[str, bool, bool, Optional[str]]:
        """Process a single line, handling comments and strings."""

        # Preserve shebangs
        if line.strip().startswith('#!'):
            return line, False, False, None

        # Handle multi-line comments/docstrings
        if in_multiline or in_docstring:
            multi_end = (self.config['multi_end'] if in_multiline
                        else self.config['multi_end'])

            if in_docstring:
                # Preserve docstring content
                if multi_end in line:
                    return line, False, False, None
                return line, in_multiline, True, multi_end
            else:
                # Remove multi-line comment content
                if multi_end in line:
                    end_idx = line.find(multi_end) + len(multi_end)
                    remaining = line[end_idx:]
                    # Process the remaining part of the line
                    return self._process_line(remaining, False, False, prev_line)
                else:
                    # Preserve indentation on blank lines
                    indent = len(line) - len(line.lstrip())
                    return ' ' * indent, True, False, multi_end

        # Check for docstring start (Python)
        if self.is_docstring_line(line, prev_line):
            multi_start = self.config['multi_start']
            if multi_start and multi_start in line:
                if line.count(multi_start) >= 2:
                    # Single-line docstring
                    return line, False, False, None
                else:
                    # Multi-line docstring start
                    return line, False, True, self.config['multi_end']

        # Process line character by character to handle strings
        result = []
        i = 0
        in_string = False
        string_char = None

        while i < len(line):
            char = line[i]

            # Handle string literals
            if char in ('"', "'") and (i == 0 or line[i-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                    result.append(char)
                elif char == string_char:
                    in_string = False
                    string_char = None
                    result.append(char)
                else:
                    result.append(char)
                i += 1
                continue

            # If we're in a string, keep everything
            if in_string:
                result.append(char)
                i += 1
                continue

            # Check for multi-line comment start
            multi_start = self.config.get('multi_start')
            if multi_start and line[i:i+len(multi_start)] == multi_start:
                # Check if it's a docstring
                if self.is_docstring_line(line[i:], prev_line):
                    result.append(line[i:])
                    if line.count(multi_start) >= 2:
                        return ''.join(result), False, False, None
                    else:
                        return ''.join(result), False, True, self.config['multi_end']

                # Check if comment closes on same line
                multi_end = self.config['multi_end']
                end_idx = line.find(multi_end, i + len(multi_start))
                if end_idx != -1:
                    # Single-line multi-line comment
                    i = end_idx + len(multi_end)
                    continue
                else:
                    # Multi-line comment starts here
                    return ''.join(result).rstrip(), True, False, multi_end

            # Check for single-line comment
            single = self.config.get('single_line')
            if single and line[i:i+len(single)] == single:
                # Rest of line is a comment
                return ''.join(result).rstrip(), False, False, None

            result.append(char)
            i += 1

        return ''.join(result).rstrip(), False, False, None


def main():
    """Main entry point for the command-line interface."""
    parser = argparse.ArgumentParser(
        description='Remove comments from source code files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Supported file types:
  Python:      .py
  JavaScript:  .js, .jsx, .ts, .tsx
  Go:          .go
  Rust:        .rs
  Java:        .java
  Ruby:        .rb
  C/C++:       .c, .cpp, .h, .hpp
  Shell:       .sh, .bash
  Nix:         .nix

Examples:
  remove-comments input.py                  # Print to stdout
  remove-comments input.py > output.py      # Redirect to file
  remove-comments input.py -o output.py     # Write to output file
  remove-comments input.py --in-place       # Modify file in place
        """
    )

    parser.add_argument(
        'input',
        help='Input source file'
    )

    parser.add_argument(
        '-o', '--output',
        help='Output file (default: stdout)'
    )

    parser.add_argument(
        '-i', '--in-place',
        action='store_true',
        help='Modify the input file in place'
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )

    args = parser.parse_args()

    try:
        # Read input file
        input_path = Path(args.input)
        if not input_path.exists():
            print(f"Error: File not found: {args.input}", file=sys.stderr)
            return 1

        if args.verbose:
            print(f"Processing: {args.input}", file=sys.stderr)

        content = input_path.read_text()

        # Remove comments
        remover = CommentRemover(args.input)
        result = remover.remove_comments(content)

        # Write output
        if args.in_place:
            input_path.write_text(result)
            if args.verbose:
                print(f"Modified in place: {args.input}", file=sys.stderr)
        elif args.output:
            output_path = Path(args.output)
            output_path.write_text(result)
            if args.verbose:
                print(f"Wrote to: {args.output}", file=sys.stderr)
        else:
            print(result)

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
