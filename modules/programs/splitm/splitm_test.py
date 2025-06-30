import pytest
from splitm import split_file


@pytest.fixture
def fake_filesystem(fs):  # pylint:disable=invalid-name
    """Variable name 'fs' causes a pylint warning. Provide a longer name
    acceptable to pylint for use in tests.
    """
    yield fs


def test_split_file(fake_filesystem):
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
    assert fake_filesystem.exists("/tf2/section_1.txt")
    assert fake_filesystem.exists("/tf2/section_2.txt")
    assert fake_filesystem.exists("/tf2/section_3.txt")

    assert fake_filesystem.read("/tf2/section_1.txt") == "This is a test file."
    assert fake_filesystem.read("/tf2/section_2.txt") == "This is the second section."
    assert fake_filesystem.read("/tf2/section_3.txt") == "This is the third section."
