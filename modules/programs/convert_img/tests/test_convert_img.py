"""
Comprehensive tests for convert_img module.
"""
import base64
import subprocess
import sys
from pathlib import Path
from unittest.mock import Mock, patch

import pytest
from PIL import Image

# Add parent directory to path to import convert_img
sys.path.insert(0, str(Path(__file__).parent.parent))
import convert_img


class TestArgumentParsing:
    """Test command line argument parsing."""

    def test_parse_args_basic(self):
        """Test basic argument parsing."""
        with patch.object(sys, 'argv', ['convert_img', 'input.jpg', 'output.svg']):
            args = convert_img.parse_args()
            assert args.input_path == Path('input.jpg')
            assert args.output_path == Path('output.svg')
            assert args.method == 'trace'
            assert args.format == 'auto'
            assert args.quality == 90

    def test_parse_args_with_options(self):
        """Test argument parsing with various options."""
        with patch.object(sys, 'argv', [
            'convert_img', 'input.jpg', 'output.svg',
            '--method', 'embed',
            '--format', 'jpeg',
            '--quality', '80',
            '--width', '200',
            '--height', '150',
            '--background', 'white',
            '--optimize'
        ]):
            args = convert_img.parse_args()
            assert args.method == 'embed'
            assert args.format == 'jpeg'
            assert args.quality == 80
            assert args.width == 200
            assert args.height == 150
            assert args.background == 'white'
            assert args.optimize is True


class TestInputValidation:
    """Test input file validation."""

    def test_validate_input_nonexistent_file(self, temp_dir):
        """Test validation with non-existent file."""
        nonexistent = temp_dir / "nonexistent.jpg"
        with pytest.raises(SystemExit):
            convert_img.validate_input(nonexistent)

    def test_validate_input_directory(self, temp_dir):
        """Test validation with directory instead of file."""
        with pytest.raises(SystemExit):
            convert_img.validate_input(temp_dir)

    def test_validate_input_valid_image(self, sample_png):
        """Test validation with valid image file."""
        # Should not raise exception
        convert_img.validate_input(sample_png)

    def test_validate_input_invalid_image(self, temp_dir):
        """Test validation with invalid image file."""
        invalid_file = temp_dir / "invalid.txt"
        invalid_file.write_text("not an image")
        
        with pytest.raises(SystemExit):
            convert_img.validate_input(invalid_file)


class TestImageResizing:
    """Test image resizing functionality."""

    def test_resize_image_no_resize(self, sample_png):
        """Test image resizing with no parameters (should return unchanged)."""
        with Image.open(sample_png) as img:
            resized = convert_img.resize_image(img)
            assert resized.size == img.size

    def test_resize_image_by_width(self, sample_png):
        """Test image resizing by width only."""
        with Image.open(sample_png) as img:
            resized = convert_img.resize_image(img, width=50)
            assert resized.width == 50
            assert resized.height == 50  # Should maintain aspect ratio

    def test_resize_image_by_height(self, sample_png):
        """Test image resizing by height only."""
        with Image.open(sample_png) as img:
            resized = convert_img.resize_image(img, height=50)
            assert resized.height == 50
            assert resized.width == 50  # Should maintain aspect ratio

    def test_resize_image_by_max_size(self, sample_png):
        """Test image resizing by max size."""
        with Image.open(sample_png) as img:
            resized = convert_img.resize_image(img, max_size=50)
            assert max(resized.size) == 50

    def test_resize_image_both_dimensions(self, sample_png):
        """Test image resizing with both width and height."""
        with Image.open(sample_png) as img:
            resized = convert_img.resize_image(img, width=80, height=60)
            assert resized.size == (80, 60)


class TestBase64Encoding:
    """Test base64 image encoding."""

    def test_image_to_base64_png(self, sample_png):
        """Test PNG to base64 conversion."""
        with Image.open(sample_png) as img:
            b64_str = convert_img.image_to_base64(img, "png")
            assert isinstance(b64_str, str)
            # Verify it's valid base64
            decoded = base64.b64decode(b64_str)
            assert len(decoded) > 0

    def test_image_to_base64_jpeg(self, sample_png):
        """Test JPEG to base64 conversion."""
        with Image.open(sample_png) as img:
            b64_str = convert_img.image_to_base64(img, "jpeg", quality=80)
            assert isinstance(b64_str, str)
            decoded = base64.b64decode(b64_str)
            assert len(decoded) > 0

    def test_image_to_base64_webp(self, sample_png):
        """Test WebP to base64 conversion."""
        with Image.open(sample_png) as img:
            b64_str = convert_img.image_to_base64(img, "webp", quality=80)
            assert isinstance(b64_str, str)
            decoded = base64.b64decode(b64_str)
            assert len(decoded) > 0

    def test_image_to_base64_rgba_to_jpeg(self, sample_rgba_png):
        """Test RGBA image conversion to JPEG (should convert to RGB)."""
        with Image.open(sample_rgba_png) as img:
            b64_str = convert_img.image_to_base64(img, "jpeg")
            assert isinstance(b64_str, str)
            decoded = base64.b64decode(b64_str)
            assert len(decoded) > 0


class TestSVGCreation:
    """Test SVG creation functionality."""

    def test_create_embedded_svg_basic(self, sample_png):
        """Test basic embedded SVG creation."""
        with Image.open(sample_png) as img:
            svg_content = convert_img.create_embedded_svg(
                img, "png", 90, "transparent", False
            )
            assert svg_content.startswith('<?xml version="1.0"')
            assert '<svg' in svg_content
            assert 'image' in svg_content
            assert 'data:image/png;base64,' in svg_content

    def test_create_embedded_svg_with_background(self, sample_png):
        """Test embedded SVG creation with background."""
        with Image.open(sample_png) as img:
            svg_content = convert_img.create_embedded_svg(
                img, "png", 90, "white", False
            )
            assert 'fill="white"' in svg_content

    def test_create_embedded_svg_different_formats(self, sample_png):
        """Test embedded SVG creation with different formats."""
        formats = ["png", "jpeg", "webp", "tiff", "bmp", "avif"]
        with Image.open(sample_png) as img:
            for fmt in formats:
                svg_content = convert_img.create_embedded_svg(
                    img, fmt, 90, "transparent", False
                )
                assert f'data:image/{fmt};base64,' in svg_content


class TestTracedSVGCreation:
    """Test traced SVG creation (requires potrace)."""

    @patch('subprocess.run')
    def test_create_traced_svg_potrace_not_found(self, mock_run, temp_dir):
        """Test traced SVG creation when potrace is not available."""
        mock_run.side_effect = FileNotFoundError()
        
        input_path = temp_dir / "input.png"
        output_path = temp_dir / "output.svg"
        
        result = convert_img.create_traced_svg(input_path, output_path, "")
        assert result is False

    @patch('subprocess.run')
    def test_create_traced_svg_success(self, mock_run, sample_png, temp_dir):
        """Test successful traced SVG creation."""
        # Mock potrace version check
        mock_run.return_value = Mock(returncode=0, stderr="")
        
        output_path = temp_dir / "output.svg"
        
        # Create a dummy SVG file to simulate potrace output
        output_path.write_text('<svg></svg>')
        
        result = convert_img.create_traced_svg(sample_png, output_path, "")
        assert result is True


class TestMainFunction:
    """Test the main function integration."""

    def test_main_embed_method(self, sample_png, temp_dir, monkeypatch):
        """Test main function with embed method."""
        output_path = temp_dir / "output.svg"
        
        # Mock sys.argv
        test_args = [
            'convert_img',
            str(sample_png),
            str(output_path),
            '--method', 'embed',
            '--format', 'png'
        ]
        
        with patch.object(sys, 'argv', test_args):
            convert_img.main()
        
        assert output_path.exists()
        # Check if it's actually an SVG file by checking the extension and content
        if output_path.suffix.lower() == '.svg':
            content = output_path.read_text()
            assert '<svg' in content
            assert 'image' in content
        else:
            # If not SVG, verify it's a valid image file
            with Image.open(output_path) as result_img:
                assert result_img.size == (100, 100)

    def test_main_invalid_quality(self, sample_png, temp_dir):
        """Test main function with invalid quality parameter."""
        output_path = temp_dir / "output.svg"
        
        test_args = [
            'convert_img',
            str(sample_png),
            str(output_path),
            '--quality', '150'  # Invalid quality > 100
        ]
        
        with patch.object(sys, 'argv', test_args):
            with pytest.raises(SystemExit):
                convert_img.main()

    def test_main_same_input_output(self, sample_png):
        """Test main function with same input and output paths."""
        test_args = [
            'convert_img',
            str(sample_png),
            str(sample_png)  # Same path
        ]
        
        with patch.object(sys, 'argv', test_args):
            with pytest.raises(SystemExit):
                convert_img.main()


class TestFileSizeInfo:
    """Test file size information functionality."""

    def test_get_file_size_info(self, sample_png, temp_dir, capsys):
        """Test file size information display."""
        output_path = temp_dir / "output.txt"
        output_path.write_text("test content")
        
        convert_img.get_file_size_info(sample_png, output_path)
        
        captured = capsys.readouterr()
        assert "Input size:" in captured.out
        assert "Output size:" in captured.out
        assert "Size ratio:" in captured.out


class TestFormatSupport:
    """Test support for various image formats."""

    @pytest.mark.parametrize("sample_fixture", [
        "sample_png", "sample_jpeg", "sample_webp", 
        "sample_gif", "sample_bmp", "sample_tiff"
    ])
    def test_format_validation(self, sample_fixture, request):
        """Test that various formats are accepted."""
        sample_file = request.getfixturevalue(sample_fixture)
        # Should not raise exception
        convert_img.validate_input(sample_file)

    def test_embed_conversion_all_formats(self, temp_dir):
        """Test embedded conversion for different input formats."""
        formats = ["RGB", "RGBA", "L", "P"]
        
        for mode in formats:
            img_path = temp_dir / f"test_{mode.lower()}.png"
            output_path = temp_dir / f"output_{mode.lower()}.svg"
            
            if mode == "P":
                # Create palette mode image
                img = Image.new("RGB", (50, 50), color="red")
                img = img.convert("P")
            else:
                img = Image.new(mode, (50, 50), color="red" if mode != "L" else 128)
            
            img.save(img_path, "PNG")
            
            test_args = [
                'convert_img',
                str(img_path),
                str(output_path),
                '--method', 'embed'
            ]
            
            with patch.object(sys, 'argv', test_args):
                convert_img.main()
            
            assert output_path.exists()
            assert '<svg' in output_path.read_text()


class TestImageToImageConversion:
    """Test image-to-image format conversion functionality."""

    def test_detect_output_format_from_extension(self):
        """Test output format detection from file extensions."""
        test_cases = [
            (Path("image.jpg"), "auto", "jpeg"),
            (Path("image.png"), "auto", "png"),
            (Path("image.webp"), "auto", "webp"),
            (Path("image.tiff"), "auto", "tiff"),
            (Path("image.bmp"), "auto", "bmp"),
            (Path("image.gif"), "auto", "gif"),
            (Path("image.svg"), "auto", "svg"),
            (Path("image.unknown"), "auto", "png"),  # Default fallback
            (Path("image.jpg"), "png", "png"),  # Explicit format override
            (Path("image.svg"), "png", "svg"),  # SVG extension takes precedence
        ]
        
        for path, format_arg, expected in test_cases:
            result = convert_img.detect_output_format(path, format_arg)
            assert result == expected

    def test_get_pillow_format(self):
        """Test Pillow format string mapping."""
        test_cases = [
            ("jpeg", "JPEG"),
            ("png", "PNG"),
            ("webp", "WEBP"),
            ("tiff", "TIFF"),
            ("bmp", "BMP"),
            ("gif", "GIF"),
            ("unknown", "PNG"),  # Default fallback
        ]
        
        for input_format, expected in test_cases:
            result = convert_img.get_pillow_format(input_format)
            assert result == expected

    def test_prepare_image_for_format_transparency_handling(self, sample_rgba_png):
        """Test image preparation for formats that don't support transparency."""
        with Image.open(sample_rgba_png) as img:
            # Test JPEG conversion (no transparency)
            jpeg_img = convert_img.prepare_image_for_format(img, "jpeg")
            assert jpeg_img.mode == "RGB"
            
            # Test BMP conversion (no transparency)
            bmp_img = convert_img.prepare_image_for_format(img, "bmp")
            assert bmp_img.mode == "RGB"
            
            # Test PNG conversion (keeps transparency)
            png_img = convert_img.prepare_image_for_format(img, "png")
            assert png_img.mode == "RGBA"

    @pytest.mark.parametrize("input_format,output_format", [
        ("png", "jpeg"),
        ("png", "webp"),
        ("png", "bmp"),
        ("png", "tiff"),
        ("png", "gif"),
        ("jpeg", "png"),
        ("jpeg", "webp"),
        ("webp", "jpeg"),
        ("webp", "png"),
        ("bmp", "png"),
        ("tiff", "jpeg"),
    ])
    def test_image_to_image_conversion(self, temp_dir, input_format, output_format):
        """Test conversion between different image formats."""
        # Create input image
        input_path = temp_dir / f"input.{input_format}"
        output_path = temp_dir / f"output.{output_format}"
        
        img = Image.new("RGB", (100, 100), color="blue")
        img.save(input_path, input_format.upper())
        
        # Perform conversion
        convert_img.convert_image_to_image(
            input_path, output_path, output_format, quality=85
        )
        
        # Verify output
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.format.lower() == convert_img.get_pillow_format(output_format).lower()
            assert result_img.size == (100, 100)

    def test_conversion_with_resize(self, sample_png, temp_dir):
        """Test image conversion with resizing."""
        output_path = temp_dir / "resized.jpeg"
        
        convert_img.convert_image_to_image(
            sample_png, output_path, "jpeg", width=50, height=75
        )
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.size == (50, 75)
            assert result_img.format == "JPEG"

    def test_conversion_with_max_size(self, sample_png, temp_dir):
        """Test image conversion with max size constraint."""
        output_path = temp_dir / "max_size.webp"
        
        convert_img.convert_image_to_image(
            sample_png, output_path, "webp", max_size=50
        )
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert max(result_img.size) == 50
            assert result_img.format == "WEBP"

    def test_main_function_image_conversion(self, sample_png, temp_dir):
        """Test main function with image-to-image conversion."""
        output_path = temp_dir / "converted.jpeg"
        
        test_args = [
            'convert_img',
            str(sample_png),
            str(output_path),
            '--quality', '80'
        ]
        
        with patch.object(sys, 'argv', test_args):
            convert_img.main()
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.format == "JPEG"

    def test_main_function_explicit_format(self, sample_png, temp_dir):
        """Test main function with explicit format specification."""
        output_path = temp_dir / "output.bin"  # Unknown extension
        
        test_args = [
            'convert_img',
            str(sample_png),
            str(output_path),
            '--format', 'webp',
            '--quality', '75'
        ]
        
        with patch.object(sys, 'argv', test_args):
            convert_img.main()
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.format == "WEBP"

    def test_transparency_preservation_png_to_png(self, sample_rgba_png, temp_dir):
        """Test that transparency is preserved in PNG to PNG conversion."""
        output_path = temp_dir / "transparent.png"
        
        convert_img.convert_image_to_image(
            sample_rgba_png, output_path, "png"
        )
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.mode == "RGBA"
            assert result_img.format == "PNG"

    def test_transparency_removal_png_to_jpeg(self, sample_rgba_png, temp_dir):
        """Test that transparency is properly handled in PNG to JPEG conversion."""
        output_path = temp_dir / "no_transparency.jpeg"
        
        convert_img.convert_image_to_image(
            sample_rgba_png, output_path, "jpeg"
        )
        
        assert output_path.exists()
        with Image.open(output_path) as result_img:
            assert result_img.mode == "RGB"
            assert result_img.format == "JPEG"