"""
Test configuration and fixtures for convert_img tests.
"""

import tempfile
from pathlib import Path
from typing import Iterator

import pytest
from PIL import Image


@pytest.fixture
def temp_dir() -> Iterator[Path]:
    """Create a temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def sample_png(temp_dir: Path) -> Path:
    """Create a sample PNG image for testing."""
    img_path = temp_dir / "test.png"
    img = Image.new(
        "RGB", (100, 100), color="red"
    )
    img.save(img_path, "PNG")
    return img_path


@pytest.fixture
def sample_jpeg(temp_dir: Path) -> Path:
    """Create a sample JPEG image for testing."""
    img_path = temp_dir / "test.jpg"
    img = Image.new(
        "RGB", (100, 100), color="blue"
    )
    img.save(img_path, "JPEG", quality=90)
    return img_path


@pytest.fixture
def sample_webp(temp_dir: Path) -> Path:
    """Create a sample WebP image for testing."""
    img_path = temp_dir / "test.webp"
    img = Image.new(
        "RGB", (100, 100), color="green"
    )
    img.save(img_path, "WEBP", quality=90)
    return img_path


@pytest.fixture
def sample_gif(temp_dir: Path) -> Path:
    """Create a sample GIF image for testing."""
    img_path = temp_dir / "test.gif"
    img = Image.new(
        "RGB", (100, 100), color="yellow"
    )
    img.save(img_path, "GIF")
    return img_path


@pytest.fixture
def sample_bmp(temp_dir: Path) -> Path:
    """Create a sample BMP image for testing."""
    img_path = temp_dir / "test.bmp"
    img = Image.new(
        "RGB", (100, 100), color="cyan"
    )
    img.save(img_path, "BMP")
    return img_path


@pytest.fixture
def sample_tiff(temp_dir: Path) -> Path:
    """Create a sample TIFF image for testing."""
    img_path = temp_dir / "test.tiff"
    img = Image.new(
        "RGB", (100, 100), color="magenta"
    )
    img.save(img_path, "TIFF")
    return img_path


@pytest.fixture
def sample_rgba_png(temp_dir: Path) -> Path:
    """Create a sample RGBA PNG image for testing transparency."""
    img_path = temp_dir / "test_rgba.png"
    img = Image.new(
        "RGBA", (100, 100), color=(255, 0, 0, 128)
    )
    img.save(img_path, "PNG")
    return img_path
