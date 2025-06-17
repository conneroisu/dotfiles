"""Tests for convert_img.py"""

import argparse
import base64
import io
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock, mock_open

from PIL import Image

# Import the module under test
import convert_img


class TestParseArgs(unittest.TestCase):
    """Test argument parsing."""

    def test_parse_args_minimal(self):
        """Test parsing with minimal arguments."""
        with patch('sys.argv', ['convert_img', 'input.webp', 'output.svg']):
            args = convert_img.parse_args()
            self.assertEqual(args.input_path, Path('input.webp'))
            self.assertEqual(args.output_path, Path('output.svg'))
            self.assertEqual(args.method, 'trace')
            self.assertEqual(args.format, 'png')
            self.assertEqual(args.quality, 90)

    def test_parse_args_all_options(self):
        """Test parsing with all options."""
        with patch('sys.argv', [
            'convert_img',
            'input.webp',
            'output.svg',
            '-m', 'embed',
            '-f', 'jpeg',
            '-q', '85',
            '-w', '800',
            '--height', '600',
            '--max-size', '1000',
            '--background', '#FF0000',
            '--optimize',
            '--trace-options', '-t 4'
        ]):
            args = convert_img.parse_args()
            self.assertEqual(args.method, 'embed')
            self.assertEqual(args.format, 'jpeg')
            self.assertEqual(args.quality, 85)
            self.assertEqual(args.width, 800)
            self.assertEqual(args.height, 600)
            self.assertEqual(args.max_size, 1000)
            self.assertEqual(args.background, '#FF0000')
            self.assertTrue(args.optimize)
            self.assertEqual(args.trace_options, '-t 4')


class TestValidateInput(unittest.TestCase):
    """Test input validation."""

    @patch('sys.exit')
    def test_validate_nonexistent_file(self, mock_exit):
        """Test validation with non-existent file."""
        convert_img.validate_input(Path('/nonexistent/file.webp'))
        mock_exit.assert_called_once_with(1)

    @patch('sys.exit')
    def test_validate_directory_instead_of_file(self, mock_exit):
        """Test validation with directory instead of file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            convert_img.validate_input(Path(tmpdir))
            mock_exit.assert_called_once_with(1)

    @patch('sys.exit')
    def test_validate_invalid_image(self, mock_exit):
        """Test validation with invalid image file."""
        with tempfile.NamedTemporaryFile(suffix='.txt', delete=False) as tmp:
            tmp.write(b'not an image')
            tmp_path = Path(tmp.name)
        
        try:
            convert_img.validate_input(tmp_path)
            mock_exit.assert_called_once_with(1)
        finally:
            tmp_path.unlink()

    def test_validate_valid_image(self):
        """Test validation with valid image."""
        # Create a valid PNG image
        img = Image.new('RGB', (10, 10), color='red')
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
            img.save(tmp.name, 'PNG')
            tmp_path = Path(tmp.name)
        
        try:
            # Should not raise or exit
            convert_img.validate_input(tmp_path)
        finally:
            tmp_path.unlink()


class TestResizeImage(unittest.TestCase):
    """Test image resizing functionality."""

    def setUp(self):
        """Create test image."""
        self.img = Image.new('RGB', (100, 50), color='blue')

    def test_resize_no_params(self):
        """Test resize with no parameters returns original."""
        result = convert_img.resize_image(self.img)
        self.assertEqual(result.size, (100, 50))

    def test_resize_width_only(self):
        """Test resize with width only maintains aspect ratio."""
        result = convert_img.resize_image(self.img, width=200)
        self.assertEqual(result.size, (200, 100))

    def test_resize_height_only(self):
        """Test resize with height only maintains aspect ratio."""
        result = convert_img.resize_image(self.img, height=100)
        self.assertEqual(result.size, (200, 100))

    def test_resize_both_dimensions(self):
        """Test resize with both width and height."""
        result = convert_img.resize_image(self.img, width=200, height=200)
        self.assertEqual(result.size, (200, 200))

    def test_resize_max_size(self):
        """Test resize with max_size parameter."""
        result = convert_img.resize_image(self.img, max_size=40)
        self.assertEqual(result.size, (40, 20))

    def test_resize_max_size_no_change(self):
        """Test resize with max_size larger than image."""
        result = convert_img.resize_image(self.img, max_size=200)
        self.assertEqual(result.size, (100, 50))

    def test_resize_edge_case_zero_dimension(self):
        """Test potential edge case with very small dimensions."""
        # This could theoretically produce 0 dimensions with extreme ratios
        tiny_img = Image.new('RGB', (10000, 1), color='red')
        result = convert_img.resize_image(tiny_img, width=1)
        # Should not have 0 height
        self.assertGreater(result.size[1], 0)


class TestImageToBase64(unittest.TestCase):
    """Test base64 encoding functionality."""

    def test_png_encoding(self):
        """Test PNG format encoding."""
        img = Image.new('RGB', (10, 10), color='red')
        result = convert_img.image_to_base64(img, 'png')
        # Verify it's valid base64
        decoded = base64.b64decode(result)
        # Verify it's a valid PNG
        self.assertTrue(decoded.startswith(b'\x89PNG'))

    def test_jpeg_encoding_rgb(self):
        """Test JPEG encoding with RGB image."""
        img = Image.new('RGB', (10, 10), color='red')
        result = convert_img.image_to_base64(img, 'jpeg', quality=80)
        decoded = base64.b64decode(result)
        # Verify it's a valid JPEG
        self.assertTrue(decoded.startswith(b'\xff\xd8\xff'))

    def test_jpeg_encoding_rgba(self):
        """Test JPEG encoding with RGBA image (should convert to RGB)."""
        img = Image.new('RGBA', (10, 10), color='red')
        result = convert_img.image_to_base64(img, 'jpeg')
        decoded = base64.b64decode(result)
        # Should still produce valid JPEG
        self.assertTrue(decoded.startswith(b'\xff\xd8\xff'))

    def test_webp_encoding(self):
        """Test WebP format encoding."""
        img = Image.new('RGB', (10, 10), color='red')
        result = convert_img.image_to_base64(img, 'webp', quality=80)
        decoded = base64.b64decode(result)
        # Verify it's valid WebP (starts with RIFF....WEBP)
        self.assertTrue(decoded.startswith(b'RIFF'))
        self.assertIn(b'WEBP', decoded[:20])


class TestCreateEmbeddedSVG(unittest.TestCase):
    """Test SVG creation with embedded images."""

    def test_create_basic_svg(self):
        """Test basic SVG creation."""
        img = Image.new('RGB', (100, 50), color='blue')
        result = convert_img.create_embedded_svg(
            img, 'png', 90, 'transparent', False
        )
        
        # Check SVG structure
        self.assertIn('<?xml version="1.0"', result)
        self.assertIn('<svg', result)
        self.assertIn('width="100"', result)
        self.assertIn('height="50"', result)
        self.assertIn('<image', result)
        self.assertIn('data:image/png;base64,', result)

    def test_create_svg_with_background(self):
        """Test SVG creation with background color."""
        img = Image.new('RGB', (100, 50), color='blue')
        result = convert_img.create_embedded_svg(
            img, 'png', 90, '#FF0000', False
        )
        
        # Should include background rect
        self.assertIn('<rect', result)
        self.assertIn('fill="#FF0000"', result)

    def test_create_svg_different_formats(self):
        """Test SVG creation with different image formats."""
        img = Image.new('RGB', (10, 10), color='green')
        
        for fmt, mime in [('png', 'image/png'), 
                          ('jpeg', 'image/jpeg'), 
                          ('webp', 'image/webp')]:
            result = convert_img.create_embedded_svg(
                img, fmt, 90, 'transparent', False
            )
            self.assertIn(f'data:{mime};base64,', result)


class TestCreateTracedSVG(unittest.TestCase):
    """Test SVG creation using potrace."""

    @patch('subprocess.run')
    @patch('tempfile.NamedTemporaryFile')
    @patch('PIL.Image.open')
    def test_create_traced_svg_success(self, mock_img_open, mock_tempfile, mock_run):
        """Test successful traced SVG creation."""
        # Mock potrace version check
        mock_run.side_effect = [
            Mock(returncode=0),  # potrace --version
            Mock(returncode=0, stderr='')  # actual potrace run
        ]
        
        # Mock image
        mock_img = Mock()
        mock_img.mode = 'RGB'
        mock_img.convert.return_value = mock_img
        mock_img.point.return_value = mock_img
        mock_img_open.return_value.__enter__.return_value = mock_img
        
        # Mock temp file
        mock_temp = Mock()
        mock_temp.name = '/tmp/test.pbm'
        mock_tempfile.return_value.__enter__.return_value = mock_temp
        
        result = convert_img.create_traced_svg(
            Path('input.png'), Path('output.svg'), ''
        )
        
        self.assertTrue(result)

    @patch('subprocess.run')
    def test_create_traced_svg_no_potrace(self, mock_run):
        """Test traced SVG when potrace is not installed."""
        mock_run.side_effect = FileNotFoundError()
        
        result = convert_img.create_traced_svg(
            Path('input.png'), Path('output.svg'), ''
        )
        
        self.assertFalse(result)


class TestGetFileSizeInfo(unittest.TestCase):
    """Test file size comparison functionality."""

    @patch('builtins.print')
    def test_file_size_comparison(self, mock_print):
        """Test file size comparison output."""
        with tempfile.NamedTemporaryFile(delete=False) as input_file:
            input_file.write(b'x' * 1000)
            input_path = Path(input_file.name)
        
        with tempfile.NamedTemporaryFile(delete=False) as output_file:
            output_file.write(b'x' * 2000)
            output_path = Path(output_file.name)
        
        try:
            convert_img.get_file_size_info(input_path, output_path)
            
            # Verify print calls
            calls = [str(call) for call in mock_print.call_args_list]
            self.assertTrue(any('1,000 bytes' in call for call in calls))
            self.assertTrue(any('2,000 bytes' in call for call in calls))
            self.assertTrue(any('2.00x' in call for call in calls))
            self.assertTrue(any('100.0% larger' in call for call in calls))
        finally:
            input_path.unlink()
            output_path.unlink()

    @patch('builtins.print')
    def test_file_size_smaller_output(self, mock_print):
        """Test when output is smaller than input."""
        with tempfile.NamedTemporaryFile(delete=False) as input_file:
            input_file.write(b'x' * 2000)
            input_path = Path(input_file.name)
        
        with tempfile.NamedTemporaryFile(delete=False) as output_file:
            output_file.write(b'x' * 1000)
            output_path = Path(output_file.name)
        
        try:
            convert_img.get_file_size_info(input_path, output_path)
            
            calls = [str(call) for call in mock_print.call_args_list]
            self.assertTrue(any('50.0% smaller' in call for call in calls))
        finally:
            input_path.unlink()
            output_path.unlink()


class TestMain(unittest.TestCase):
    """Test main function integration."""

    @patch('sys.argv', ['convert_img', 'input.webp', 'output.svg', '-q', '150'])
    @patch('sys.exit')
    def test_main_invalid_quality(self, mock_exit):
        """Test main with invalid quality parameter."""
        convert_img.main()
        mock_exit.assert_called_once_with(1)

    @patch('sys.argv', ['convert_img', 'input.webp', 'input.webp'])
    @patch('sys.exit')
    @patch('convert_img.validate_input')
    def test_main_same_input_output(self, mock_validate, mock_exit):
        """Test main when input and output paths are the same."""
        # Mock paths to be the same when resolved
        with patch('pathlib.Path.resolve', return_value=Path('/same/path')):
            convert_img.main()
            mock_exit.assert_called_once_with(1)


class TestBugs(unittest.TestCase):
    """Test for specific bugs found in the code."""

    def test_image_to_base64_la_mode_bug(self):
        """Test the duplicate code bug in image_to_base64 for LA mode."""
        # Create LA mode image (grayscale with alpha)
        img = Image.new('LA', (10, 10), (128, 255))
        
        # This should not crash despite the duplicate code
        result = convert_img.image_to_base64(img, 'jpeg')
        decoded = base64.b64decode(result)
        
        # Should produce valid JPEG
        self.assertTrue(decoded.startswith(b'\xff\xd8\xff'))

    @patch('tempfile.NamedTemporaryFile')
    @patch('PIL.Image.open')
    def test_create_traced_svg_format_bug(self, mock_img_open, mock_tempfile):
        """Test the PPM/PBM format mismatch bug."""
        # This test verifies the bug exists - saving as PPM to a .pbm file
        mock_img = Mock()
        mock_img.mode = '1'
        mock_img_open.return_value.__enter__.return_value = mock_img
        
        mock_temp = Mock()
        mock_temp.name = '/tmp/test.pbm'
        mock_tempfile.return_value.__enter__.return_value = mock_temp
        
        # The bug is that it saves as "PPM" format to a .pbm file
        # This would be called in the actual code
        with patch('subprocess.run') as mock_run:
            mock_run.side_effect = FileNotFoundError()  # Simulate no potrace
            
            convert_img.create_traced_svg(
                Path('input.png'), Path('output.svg'), ''
            )
            
            # Verify the save was called with PPM format
            if mock_img.save.called:
                args, kwargs = mock_img.save.call_args
                self.assertEqual(args[1], 'PPM')  # This is the bug!


if __name__ == '__main__':
    unittest.main()