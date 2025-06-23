#!/usr/bin/env python3
"""
Basic test runner for convert_img without pytest dependencies.
"""
import sys
import tempfile
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from PIL import Image
    print("✓ PIL/Pillow is available")
except ImportError as e:
    print(f"✗ PIL not available: {e}")
    sys.exit(1)

try:
    import convert_img
    print("✓ convert_img module imports successfully")
except ImportError as e:
    print(f"✗ convert_img import failed: {e}")
    sys.exit(1)

def test_format_detection():
    """Test output format detection."""
    test_cases = [
        (Path("image.jpg"), "auto", "jpeg"),
        (Path("image.png"), "auto", "png"),
        (Path("image.webp"), "auto", "webp"),
        (Path("image.svg"), "auto", "svg"),
        (Path("image.unknown"), "auto", "png"),  # Default fallback
        (Path("image.jpg"), "png", "png"),  # Explicit override
    ]
    
    for path, format_arg, expected in test_cases:
        result = convert_img.detect_output_format(path, format_arg)
        if result == expected:
            print(f"✓ Format detection: {path.suffix} -> {result}")
        else:
            print(f"✗ Format detection failed: {path.suffix} expected {expected}, got {result}")
            return False
    return True

def test_pillow_format_mapping():
    """Test Pillow format mapping."""
    test_cases = [
        ("jpeg", "JPEG"),
        ("png", "PNG"),
        ("webp", "WEBP"),
        ("tiff", "TIFF"),
        ("bmp", "BMP"),
        ("gif", "GIF"),
    ]
    
    for input_format, expected in test_cases:
        result = convert_img.get_pillow_format(input_format)
        if result == expected:
            print(f"✓ Pillow format: {input_format} -> {result}")
        else:
            print(f"✗ Pillow format failed: {input_format} expected {expected}, got {result}")
            return False
    return True

def test_image_preparation():
    """Test image preparation for different formats."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        
        # Create test RGBA image
        rgba_path = tmpdir / "test_rgba.png"
        rgba_img = Image.new("RGBA", (50, 50), (255, 0, 0, 128))
        rgba_img.save(rgba_path, "PNG")
        
        with Image.open(rgba_path) as img:
            # Test JPEG preparation (should remove alpha)
            jpeg_img = convert_img.prepare_image_for_format(img, "jpeg")
            if jpeg_img.mode == "RGB":
                print("✓ JPEG transparency removal works")
            else:
                print(f"✗ JPEG preparation failed: expected RGB, got {jpeg_img.mode}")
                return False
            
            # Test PNG preparation (should keep alpha)
            png_img = convert_img.prepare_image_for_format(img, "png")
            if png_img.mode == "RGBA":
                print("✓ PNG transparency preservation works")
            else:
                print(f"✗ PNG preparation failed: expected RGBA, got {png_img.mode}")
                return False
    
    return True

def test_image_resizing():
    """Test image resizing functionality."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        
        # Create test image
        test_path = tmpdir / "test.png"
        test_img = Image.new("RGB", (100, 100), "red")
        test_img.save(test_path, "PNG")
        
        with Image.open(test_path) as img:
            # Test width-only resize
            resized = convert_img.resize_image(img, width=50)
            if resized.size == (50, 50):
                print("✓ Width-only resize works")
            else:
                print(f"✗ Width resize failed: expected (50, 50), got {resized.size}")
                return False
            
            # Test max_size resize
            resized = convert_img.resize_image(img, max_size=25)
            if max(resized.size) == 25:
                print("✓ Max-size resize works")
            else:
                print(f"✗ Max-size resize failed: expected max 25, got {resized.size}")
                return False
    
    return True

def test_basic_conversion():
    """Test basic image conversion."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        
        # Create test image
        input_path = tmpdir / "input.png"
        test_img = Image.new("RGB", (50, 50), "blue")
        test_img.save(input_path, "PNG")
        
        # Test PNG to JPEG conversion
        output_path = tmpdir / "output.jpeg"
        try:
            convert_img.convert_image_to_image(
                input_path, output_path, "jpeg", quality=85
            )
            
            if output_path.exists():
                with Image.open(output_path) as result:
                    if result.format == "JPEG" and result.size == (50, 50):
                        print("✓ Basic PNG to JPEG conversion works")
                        return True
                    else:
                        print(f"✗ Conversion result incorrect: format={result.format}, size={result.size}")
                        return False
            else:
                print("✗ Output file not created")
                return False
        except Exception as e:
            print(f"✗ Conversion failed with error: {e}")
            return False

def test_input_validation():
    """Test input file validation."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        
        # Test valid image
        valid_path = tmpdir / "valid.png"
        Image.new("RGB", (10, 10), "red").save(valid_path, "PNG")
        
        try:
            convert_img.validate_input(valid_path)
            print("✓ Valid image validation works")
        except SystemExit:
            print("✗ Valid image rejected")
            return False
        
        # Test invalid file
        invalid_path = tmpdir / "invalid.txt"
        invalid_path.write_text("not an image")
        
        try:
            convert_img.validate_input(invalid_path)
            print("✗ Invalid file accepted")
            return False
        except SystemExit:
            print("✓ Invalid file properly rejected")
    
    return True

def main():
    """Run all basic tests."""
    print("Running basic convert_img tests...\n")
    
    tests = [
        ("Format Detection", test_format_detection),
        ("Pillow Format Mapping", test_pillow_format_mapping),
        ("Image Preparation", test_image_preparation),
        ("Image Resizing", test_image_resizing),
        ("Basic Conversion", test_basic_conversion),
        ("Input Validation", test_input_validation),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"✗ {test_name} failed with exception: {e}")
            failed += 1
    
    print(f"\n--- Test Results ---")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total:  {passed + failed}")
    
    if failed == 0:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n❌ {failed} test(s) failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())