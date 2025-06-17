# Bugs Found in convert_img.py

## 1. Duplicate Code in image_to_base64() (Lines 248-250)

**Bug**: The LA mode handling has duplicate code:
```python
else:
    bg.paste(img, mask=img.getchannel("A"))
```

**Impact**: While not causing errors, this is redundant code that should be cleaned up.

**Fix**: Remove the duplicate lines or combine the LA and RGBA cases since they have identical handling.

## 2. Format Mismatch in create_traced_svg() (Line 377)

**Bug**: The code saves the image as "PPM" format but the file has a .pbm extension:
```python
img.save(temp_pbm_path, "PPM")
```

**Impact**: This could cause issues with potrace expecting a PBM file but receiving PPM format.

**Fix**: Change to save as PBM format:
```python
img.save(temp_pbm_path, "PBM")
```

## 3. No Division by Zero Protection in get_file_size_info()

**Bug**: The function divides by input file size without checking if it's zero:
```python
ratio = out_size / in_size
```

**Impact**: If the input file is empty (0 bytes), this will cause a ZeroDivisionError.

**Fix**: Add a check before division:
```python
if in_size == 0:
    print("Warning: Input file is empty")
    return
ratio = out_size / in_size
```

## 4. Potential Zero Dimensions in resize_image()

**Bug**: When calculating new dimensions with very small ratios, integer conversion could produce 0:
```python
new_h = int(orig_h * ratio)
```

**Impact**: Could create images with 0 width or height, causing errors downstream.

**Fix**: Ensure minimum dimension of 1:
```python
new_h = max(1, int(orig_h * ratio))
```

## 5. No Check for Existing Output File

**Issue**: The program doesn't warn when overwriting existing files.

**Fix**: Add a warning or confirmation prompt:
```python
if args.output_path.exists():
    print(f"Warning: Output file {args.output_path} already exists and will be overwritten")
```

## 6. Quality Parameter Ignored for PNG

**Issue**: The quality parameter is accepted but ignored for PNG format in embed mode.

**Fix**: Either warn the user or document that quality doesn't apply to PNG.

## How to Run Tests

Once in an environment with PIL/Pillow installed:
```bash
python -m unittest test_convert_img.py -v
```

The test suite includes:
- Argument parsing tests
- Input validation tests  
- Image resizing tests
- Base64 encoding tests
- SVG creation tests
- File size comparison tests
- Specific tests for the bugs mentioned above