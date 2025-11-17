"""
Test suite for remove-comments program
"""

import sys
import tempfile
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from remove_comments import CommentRemover


def test_python_single_line_comments():
    """Test removal of Python single-line comments."""
    content = """x = 5  # This is a comment
y = 10  # Another comment
# Full line comment
z = x + y"""

    expected = """x = 5
y = 10

z = x + y"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_python_docstring_preservation():
    """Test that Python docstrings are preserved."""
    content = '''def foo():
    """This is a docstring and should be preserved."""
    # This is a comment and should be removed
    return 42'''

    expected = '''def foo():
    """This is a docstring and should be preserved."""

    return 42'''

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_python_multiline_docstring():
    """Test multi-line docstring preservation."""
    content = '''def calculate(n):
    """
    Calculate something.

    Args:
        n: The number
    """
    # Comment to remove
    return n * 2'''

    expected = '''def calculate(n):
    """
    Calculate something.

    Args:
        n: The number
    """

    return n * 2'''

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_python_string_literals():
    """Test that string literals with # are preserved."""
    content = '''x = "# This is not a comment"
y = '# Neither is this'
z = "#" + "also not a comment"'''

    expected = '''x = "# This is not a comment"
y = '# Neither is this'
z = "#" + "also not a comment"'''

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_javascript_single_line_comments():
    """Test removal of JavaScript // comments."""
    content = """const x = 5; // This is a comment
const y = 10; // Another comment
// Full line comment
const z = x + y;"""

    expected = """const x = 5;
const y = 10;

const z = x + y;"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_javascript_multiline_comments():
    """Test removal of JavaScript /* */ comments."""
    content = """const x = 5;
/* This is a multi-line
   comment that should be removed */
const y = 10;"""

    expected = """const x = 5;


const y = 10;"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_javascript_string_literals():
    """Test that JavaScript string literals are preserved."""
    content = '''const url = "https://example.com"; // URL
const comment = "// This is not a comment";
const multi = "/* Also not a comment */";'''

    expected = '''const url = "https://example.com";
const comment = "// This is not a comment";
const multi = "/* Also not a comment */";'''

    with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_go_comments():
    """Test removal of Go comments."""
    content = """package main

// This is a single-line comment
func main() {
    x := 5 // Inline comment
    /* Multi-line
       comment */
    y := 10
}"""

    expected = """package main


func main() {
    x := 5


    y := 10
}"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.go', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_rust_comments():
    """Test removal of Rust comments."""
    content = """fn main() {
    let x = 5; // Single-line comment
    /* Multi-line
       comment */
    let y = 10;
}"""

    expected = """fn main() {
    let x = 5;


    let y = 10;
}"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.rs', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_ruby_comments():
    """Test removal of Ruby comments."""
    content = """x = 5 # This is a comment
# Full line comment
y = 10
=begin
Multi-line comment
block in Ruby
=end
z = x + y"""

    expected = """x = 5

y = 10




z = x + y"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.rb', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_shell_comments():
    """Test removal of shell script comments."""
    content = """#!/bin/bash
# This is a comment
echo "Hello" # Inline comment
# Another comment
echo "World"
"""

    expected = """#!/bin/bash

echo "Hello"

echo "World"
"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_nix_comments():
    """Test removal of Nix comments."""
    content = """{
  # Single-line comment
  pkgs,
  lib, # Inline comment
  /* Multi-line
     comment */
  ...
}: {
  value = 42;
}"""

    expected = """{

  pkgs,
  lib,


  ...
}: {
  value = 42;
}"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.nix', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_inline_multiline_comment():
    """Test single-line multi-line comment syntax."""
    content = """const x = 5; /* inline comment */ const y = 10;"""
    expected = """const x = 5;  const y = 10;"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


def test_escaped_quotes_in_strings():
    """Test that escaped quotes in strings are handled correctly."""
    content = '''x = "She said \\"Hello\\"" # Comment'''
    expected = '''x = "She said \\"Hello\\""'''

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(content)
        f.flush()
        remover = CommentRemover(f.name)
        result = remover.remove_comments(content)

    assert result == expected


if __name__ == '__main__':
    # Run tests
    test_functions = [
        test_python_single_line_comments,
        test_python_docstring_preservation,
        test_python_multiline_docstring,
        test_python_string_literals,
        test_javascript_single_line_comments,
        test_javascript_multiline_comments,
        test_javascript_string_literals,
        test_go_comments,
        test_rust_comments,
        test_ruby_comments,
        test_shell_comments,
        test_nix_comments,
        test_inline_multiline_comment,
        test_escaped_quotes_in_strings,
    ]

    passed = 0
    failed = 0

    for test_func in test_functions:
        try:
            test_func()
            print(f"✓ {test_func.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"✗ {test_func.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {test_func.__name__}: {type(e).__name__}: {e}")
            failed += 1

    print(f"\n{passed} passed, {failed} failed")
    sys.exit(0 if failed == 0 else 1)
