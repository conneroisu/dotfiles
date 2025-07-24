import pytest
import os
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock
from pyfakefs.fake_filesystem import (
    FakeFilesystem,
)
import argparse

# Add the current directory to the path so we can import catls
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from catls import (
    escape,
    wildcard_to_regex,
    guess_filetype,
    is_binary,
    should_include,
    should_ignore,
    get_real_path,
    find_files,
    process_file,
    parse_args,
)


@pytest.fixture
def fake_filesystem(fs: FakeFilesystem):
    """Variable name 'fs' causes a pylint warning. Provide a longer name
    acceptable to pylint for use in tests.
    """
    yield fs


@pytest.fixture
def mock_args():
    """Create a mock args object with default values."""
    args = MagicMock()
    args.directory = "/test"
    args.recursive = False
    args.show_all = False
    args.debug = False
    args.ignore_regex = []  # Empty compiled regex patterns
    args.ignore_dir = []
    args.include_regex = []
    args.content_pattern = ""
    args.show_line_numbers = False
    return args


def test_escape():
    """Test the escape function for XML entities."""
    assert escape("hello") == "hello"
    assert escape("hello & world") == "hello &amp; world"
    assert escape("hello < world") == "hello &lt; world"
    assert escape("hello > world") == "hello &gt; world"
    assert escape('hello "world"') == "hello &quot;world&quot;"
    assert escape("hello 'world'") == "hello &#x27;world&#x27;"
    assert (
        escape("hello & < > \" ' world") == "hello &amp; &lt; &gt; &quot; &#x27; world"
    )


def test_wildcard_to_regex():
    """Test wildcard pattern conversion to regex."""
    assert wildcard_to_regex("*.py") == r".*\.py"
    assert wildcard_to_regex("test?.txt") == r"test.\.txt"
    assert wildcard_to_regex("file[abc].txt") == r"file\[abc\]\.txt"
    assert wildcard_to_regex("path/to/*.py") == r"path/to/.*\.py"


def test_guess_filetype():
    """Test file type guessing based on extension."""
    assert guess_filetype("test.py") == "python"
    assert guess_filetype("test.js") == "javascript"
    assert guess_filetype("test.rb") == "ruby"
    assert guess_filetype("test.nix") == "nix"
    assert guess_filetype("test.unknown") == ""
    assert guess_filetype("test") == ""


def test_is_binary():
    """Test binary file detection."""
    # Mock subprocess.run for file command
    with patch("subprocess.run") as mock_run:
        # Test text file
        mock_result = MagicMock()
        mock_result.stdout = "test.txt: ASCII text"
        mock_run.return_value = mock_result
        assert is_binary("test.txt") is False

        # Test binary file
        mock_result.stdout = "test.bin: ELF 64-bit executable"
        mock_run.return_value = mock_result
        assert is_binary("test.bin") is True


def test_should_include():
    """Test file inclusion logic."""
    # No include patterns - should include all
    assert should_include("test.py", []) is True

    # Wildcard patterns (these work with the implementation)
    assert should_include("test.py", ["*.py"]) is True
    assert should_include("test.js", ["*.py"]) is False

    # Multiple wildcard patterns
    assert should_include("test.py", ["*.py", "*.js"]) is True
    assert should_include("test.js", ["*.py", "*.js"]) is True
    assert should_include("test.rb", ["*.py", "*.js"]) is False


def test_should_ignore():
    """Test file ignore logic."""
    import re

    # No ignore patterns - should not ignore
    assert should_ignore("test.py", [], []) is False

    # Ignore regex patterns (compiled)
    assert (
        should_ignore(
            "test.pyc",
            [re.compile(r".*\.pyc")],
            [],
        )
        is True
    )
    assert (
        should_ignore(
            "test.py",
            [re.compile(r".*\.pyc")],
            [],
        )
        is False
    )

    # Ignore directories
    assert (
        should_ignore(
            "__pycache__/test.py",
            [],
            ["__pycache__"],
        )
        is True
    )
    assert should_ignore("src/test.py", [], ["__pycache__"]) is False

    # Combined patterns
    assert (
        should_ignore(
            "__pycache__/test.pyc",
            [re.compile(r".*\.pyc")],
            ["__pycache__"],
        )
        is True
    )


def test_get_real_path():
    """Test path resolution."""
    # Test with existing path
    test_path = "/tmp/test"
    with patch("pathlib.Path.resolve") as mock_resolve:
        mock_resolve.return_value = Path("/resolved/path")
        result = get_real_path(test_path)
        assert result == "/resolved/path"

    # Test fallback to abspath
    with patch(
        "pathlib.Path.resolve",
        side_effect=Exception("Path error"),
    ):
        with patch(
            "os.path.abspath",
            return_value="/fallback/path",
        ):
            result = get_real_path(test_path)
            assert result == "/fallback/path"


def test_find_files_basic(fake_filesystem, mock_args):
    """Test basic file finding functionality."""
    # Create test directory structure
    fake_filesystem.create_file(
        "/test/file1.py",
        contents="print('hello')",
    )
    fake_filesystem.create_file("/test/file2.txt", contents="text content")
    fake_filesystem.create_dir("/test/subdir")
    fake_filesystem.create_file(
        "/test/subdir/file3.py",
        contents="print('world')",
    )

    # Test non-recursive
    mock_args.directory = "/test"
    mock_args.recursive = False
    files = find_files(mock_args)

    # Should only find files in root directory
    assert len(files) == 2
    assert "/test/file1.py" in files
    assert "/test/file2.txt" in files
    assert "/test/subdir/file3.py" not in files


def test_find_files_recursive(fake_filesystem, mock_args):
    """Test recursive file finding."""
    # Create test directory structure
    fake_filesystem.create_file(
        "/test/file1.py",
        contents="print('hello')",
    )
    fake_filesystem.create_dir("/test/subdir")
    fake_filesystem.create_file(
        "/test/subdir/file2.py",
        contents="print('world')",
    )
    fake_filesystem.create_dir("/test/subdir/nested")
    fake_filesystem.create_file(
        "/test/subdir/nested/file3.py",
        contents="print('nested')",
    )

    # Test recursive
    mock_args.directory = "/test"
    mock_args.recursive = True
    files = find_files(mock_args)

    # Should find all files
    assert len(files) == 3
    assert "/test/file1.py" in files
    assert "/test/subdir/file2.py" in files
    assert "/test/subdir/nested/file3.py" in files


def test_find_files_hidden(fake_filesystem, mock_args):
    """Test hidden file handling."""
    # Create test files including hidden ones
    fake_filesystem.create_file("/test/visible.py", contents="visible")
    fake_filesystem.create_file("/test/.hidden.py", contents="hidden")

    # Test without show_all
    mock_args.directory = "/test"
    mock_args.show_all = False
    files = find_files(mock_args)

    assert len(files) == 1
    assert "/test/visible.py" in files
    assert "/test/.hidden.py" not in files

    # Test with show_all
    mock_args.show_all = True
    files = find_files(mock_args)

    assert len(files) == 2
    assert "/test/visible.py" in files
    assert "/test/.hidden.py" in files


def test_find_files_ignore_dirs(fake_filesystem, mock_args):
    """Test directory ignoring."""
    # Create test directory structure
    fake_filesystem.create_file(
        "/test/file1.py",
        contents="print('hello')",
    )
    fake_filesystem.create_dir("/test/__pycache__")
    fake_filesystem.create_file(
        "/test/__pycache__/file2.pyc",
        contents="compiled",
    )
    fake_filesystem.create_dir("/test/src")
    fake_filesystem.create_file(
        "/test/src/file3.py",
        contents="print('src')",
    )

    # Test ignoring __pycache__
    mock_args.directory = "/test"
    mock_args.recursive = True
    mock_args.ignore_dir = ["__pycache__"]
    files = find_files(mock_args)

    assert len(files) == 2
    assert "/test/file1.py" in files
    assert "/test/src/file3.py" in files
    assert "/test/__pycache__/file2.pyc" not in files


@patch("builtins.print")
def test_process_file_binary(mock_print, fake_filesystem, mock_args):
    """Test processing a binary file."""
    # Create binary file
    fake_filesystem.create_file(
        "/test/binary.bin",
        contents="\x00\x01\x02\x03",
    )

    mock_args.directory = "/test"

    # Mock is_binary to return True
    with patch("catls.is_binary", return_value=True):
        process_file("/test/binary.bin", mock_args)

    # Verify binary file handling
    calls = [call.args[0] for call in mock_print.call_args_list]
    assert '<file path="binary.bin">' in calls
    assert "<binary>true</binary>" in calls
    assert "<content>[Binary file - contents not displayed]</content>" in calls
    assert "</file>" in calls


@patch("builtins.print")
def test_process_file_ignore(mock_print, fake_filesystem, mock_args):
    """Test that ignored files are not processed."""
    import re

    # Create test file
    fake_filesystem.create_file("/test/ignored.pyc", contents="compiled")

    mock_args.directory = "/test"
    mock_args.ignore_regex = [re.compile(r".*\.pyc")]
    mock_args.ignore_dir = []
    mock_args.include_regex = []

    # Process the file
    process_file("/test/ignored.pyc", mock_args)

    # Should not print anything (file is ignored)
    assert len(mock_print.call_args_list) == 0


def test_parse_args():
    """Test argument parsing."""
    # Test default arguments
    with patch("sys.argv", ["catls.py", "/test/dir"]):
        args = parse_args()
        assert args.directory == "/test/dir"
        assert args.recursive is False
        assert args.show_all is False
        assert args.debug is False
        # ignore_regex has default patterns
        assert len(args.ignore_regex) > 0
        # ignore_dir has default directories
        assert len(args.ignore_dir) > 0
        assert args.include_regex == []
        assert args.content_pattern == ""
        assert args.show_line_numbers is False

    # Test with flags
    with patch(
        "sys.argv",
        [
            "catls.py",
            "/test/dir",
            "-r",
            "-a",
            "--debug",
            "-n",
        ],
    ):
        args = parse_args()
        assert args.recursive is True
        assert args.show_all is True
        assert args.debug is True
        assert args.show_line_numbers is True
