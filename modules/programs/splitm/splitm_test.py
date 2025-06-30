import os
import pytest
from splitm import split_file
from pyfakefs.fake_filesystem import FakeFilesystem


@pytest.fixture
def fake_filesystem(fs: FakeFilesystem):  # pylint:disable=invalid-name
    """Variable name 'fs' causes a pylint warning. Provide a longer name
    acceptable to pylint for use in tests.
    """
    yield fs


def test_split_file(fake_filesystem: FakeFilesystem):
    """Test the split_file function."""
    fake_filesystem.create_file(
        "/tf2",
        contents="This is a test file.\n---\nThis is the second section.\n---\nThis is the third section.",
    )

    split_file(
        input_filename="/tf2",
        delimiter="---",
        output_prefix="section_",
    )

    assert fake_filesystem.exists("/tf2")
    assert fake_filesystem.exists("/section_1.txt")
    assert fake_filesystem.exists("/section_2.txt")
    assert fake_filesystem.exists("/section_3.txt")
    with open("/section_1.txt", "r") as f:
        assert f.read() == "This is a test file."
