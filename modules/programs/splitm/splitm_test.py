import pytest
from splitm import split_file
from pyfakefs.fake_filesystem import (
    FakeFilesystem,
)


@pytest.fixture
def fake_filesystem(
    fs: FakeFilesystem,
):  # pylint:disable=invalid-name
    """Variable name 'fs' causes a pylint warning. Provide a longer name
    acceptable to pylint for use in tests.
    """
    yield fs


def test_split_file(
    fake_filesystem: FakeFilesystem,
):
    """
    Test the split_file function.

    Args:
        fake_filesystem: A fake filesystem to use in the test.
    """
    test_content = "This is a test file.\n---\nThis is the second section.\n---\nThis is the third section."
    _ = fake_filesystem.create_file(  # pyright: ignore[reportUnknownMemberType]
        "/tf2",
        contents=test_content,
    )

    split_file(
        input_filename="/tf2",
        delimiter="---",
        output_prefix="section_",
    )

    assert fake_filesystem.exists("/tf2")  # pyright: ignore[reportUnknownMemberType]
    assert fake_filesystem.exists(  # pyright: ignore[reportUnknownMemberType]
        "/section_1.txt"
    )
    assert fake_filesystem.exists(  # pyright: ignore[reportUnknownMemberType]
        "/section_2.txt"
    )
    assert fake_filesystem.exists(  # pyright: ignore[reportUnknownMemberType]
        "/section_3.txt"
    )
    with open("/section_1.txt", "r") as f:
        assert f.read() == "This is a test file."
    with open("/section_2.txt", "r") as f:
        assert f.read() == "This is the second section."
    with open("/section_3.txt", "r") as f:
        assert f.read() == "This is the third section."
