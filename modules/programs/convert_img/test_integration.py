"""Integration tests for convert_img using real image file."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import convert_img


class TestIntegrationWithRealImage(unittest.TestCase):
    """Integration tests using the klaus-desktop.jpeg file."""
    
    def setUp(self):
        """Set up test with real image file."""
        self.test_image = Path(__file__).parent / "klaus-desktop.jpeg"
        self.assertTrue(self.test_image.exists(), "Test image klaus-desktop.jpeg not found")
        
        # Create temporary directory for outputs
        self.temp_dir = Path(tempfile.mkdtemp())
        
    def tearDown(self):
        """Clean up temporary files."""
        for file in self.temp_dir.glob("*"):
            file.unlink()
        self.temp_dir.rmdir()
    
    def test_embed_method_png(self):
        """Test embed method with PNG format using real image."""
        output_path = self.temp_dir / "test_output_png.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '-f', 'png'
        ]):
            convert_img.main()
        
        # Verify output file was created
        self.assertTrue(output_path.exists())
        
        # Verify it's valid SVG
        content = output_path.read_text()
        self.assertIn('<?xml version="1.0"', content)
        self.assertIn('<svg', content)
        self.assertIn('<image', content)
        self.assertIn('data:image/png;base64,', content)
        
        # Verify size is reasonable (not empty)
        self.assertGreater(output_path.stat().st_size, 1000)
    
    def test_embed_method_jpeg(self):
        """Test embed method with JPEG format using real image."""
        output_path = self.temp_dir / "test_output_jpeg.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '-f', 'jpeg',
            '-q', '80'
        ]):
            convert_img.main()
        
        # Verify output file was created
        self.assertTrue(output_path.exists())
        
        # Verify it contains JPEG data
        content = output_path.read_text()
        self.assertIn('data:image/jpeg;base64,', content)
    
    def test_embed_method_webp(self):
        """Test embed method with WebP format using real image."""
        output_path = self.temp_dir / "test_output_webp.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '-f', 'webp',
            '-q', '75'
        ]):
            convert_img.main()
        
        # Verify output file was created
        self.assertTrue(output_path.exists())
        
        # Verify it contains WebP data
        content = output_path.read_text()
        self.assertIn('data:image/webp;base64,', content)
    
    def test_resize_width(self):
        """Test resizing by width using real image."""
        output_path = self.temp_dir / "test_resized_width.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '-w', '200'
        ]):
            convert_img.main()
        
        # Verify output contains correct dimensions
        content = output_path.read_text()
        self.assertIn('width="200"', content)
        # Height should be proportional (can't predict exact value without knowing original)
        self.assertRegex(content, r'height="\d+"')
    
    def test_resize_height(self):
        """Test resizing by height using real image."""
        output_path = self.temp_dir / "test_resized_height.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '--height', '150'
        ]):
            convert_img.main()
        
        # Verify output contains correct dimensions
        content = output_path.read_text()
        self.assertIn('height="150"', content)
        self.assertRegex(content, r'width="\d+"')
    
    def test_max_size(self):
        """Test max size constraint using real image."""
        output_path = self.temp_dir / "test_max_size.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '--max-size', '100'
        ]):
            convert_img.main()
        
        # Verify dimensions are constrained
        content = output_path.read_text()
        
        # Extract width and height from SVG
        import re
        width_match = re.search(r'width="(\d+)"', content)
        height_match = re.search(r'height="(\d+)"', content)
        
        self.assertTrue(width_match and height_match)
        width = int(width_match.group(1))
        height = int(height_match.group(1))
        
        # At least one dimension should be <= 100
        self.assertTrue(width <= 100 or height <= 100)
    
    def test_background_color(self):
        """Test background color setting using real image."""
        output_path = self.temp_dir / "test_background.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '--background', '#FF0000'
        ]):
            convert_img.main()
        
        # Verify background rect is included
        content = output_path.read_text()
        self.assertIn('<rect', content)
        self.assertIn('fill="#FF0000"', content)
    
    def test_overwrite_warning(self):
        """Test that overwrite warning is shown."""
        output_path = self.temp_dir / "test_overwrite.svg"
        
        # Create initial file
        output_path.write_text("dummy content")
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed'
        ]):
            with patch('builtins.print') as mock_print:
                convert_img.main()
                
                # Check that warning was printed
                calls = [str(call) for call in mock_print.call_args_list]
                warning_found = any('already exists' in call for call in calls)
                self.assertTrue(warning_found, "Expected overwrite warning not found")
    
    def test_file_size_comparison(self):
        """Test file size comparison output."""
        output_path = self.temp_dir / "test_size_comparison.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed'
        ]):
            with patch('builtins.print') as mock_print:
                convert_img.main()
                
                # Check that size comparison was printed
                calls = [str(call) for call in mock_print.call_args_list]
                size_info_found = any('bytes' in call for call in calls)
                self.assertTrue(size_info_found, "Expected size comparison not found")
    
    def test_invalid_quality_bounds(self):
        """Test quality parameter validation."""
        output_path = self.temp_dir / "test_quality.svg"
        
        # Test quality too low
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-q', '0'
        ]):
            with patch('sys.exit') as mock_exit:
                convert_img.main()
                mock_exit.assert_called_with(1)
        
        # Test quality too high
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-q', '101'
        ]):
            with patch('sys.exit') as mock_exit:
                convert_img.main()
                mock_exit.assert_called_with(1)
    
    def test_trace_method_fallback(self):
        """Test that trace method falls back to embed when potrace unavailable."""
        output_path = self.temp_dir / "test_trace_fallback.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'trace'
        ]):
            # Mock potrace not being available
            with patch('subprocess.run', side_effect=FileNotFoundError()):
                with patch('builtins.print') as mock_print:
                    convert_img.main()
                    
                    # Should fall back to embed method
                    calls = [str(call) for call in mock_print.call_args_list]
                    fallback_found = any('Falling back' in call for call in calls)
                    self.assertTrue(fallback_found, "Expected fallback message not found")
        
        # Verify file was still created
        self.assertTrue(output_path.exists())
        content = output_path.read_text()
        self.assertIn('data:image/', content)  # Should contain embedded data
    
    def test_create_output_directory(self):
        """Test that output directory is created if it doesn't exist."""
        nested_output = self.temp_dir / "nested" / "subdir" / "output.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(nested_output),
            '-m', 'embed'
        ]):
            with patch('builtins.print') as mock_print:
                convert_img.main()
                
                # Check that directory creation message was printed
                calls = [str(call) for call in mock_print.call_args_list]
                dir_created = any('Created output directory' in call for call in calls)
                self.assertTrue(dir_created, "Expected directory creation message not found")
        
        # Verify file was created
        self.assertTrue(nested_output.exists())
    
    def test_edge_case_very_small_resize(self):
        """Test edge case with very small resize dimensions."""
        output_path = self.temp_dir / "test_tiny.svg"
        
        with patch('sys.argv', [
            'convert_img',
            str(self.test_image),
            str(output_path),
            '-m', 'embed',
            '-w', '1'  # Very small width
        ]):
            convert_img.main()
        
        # Should still create valid SVG with minimum 1px dimensions
        content = output_path.read_text()
        
        import re
        width_match = re.search(r'width="(\d+)"', content)
        height_match = re.search(r'height="(\d+)"', content)
        
        self.assertTrue(width_match and height_match)
        width = int(width_match.group(1))
        height = int(height_match.group(1))
        
        # Both dimensions should be at least 1
        self.assertGreaterEqual(width, 1)
        self.assertGreaterEqual(height, 1)


if __name__ == '__main__':
    unittest.main()