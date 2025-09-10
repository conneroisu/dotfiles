# Test Files for catls Compression

This directory contains example files in various programming languages to demonstrate the `--compress-globs` functionality of catls.

## File Types Included

### Languages that support single-line compression:
- **JavaScript** (`example.js`) - Comments removed, compressed to single line
- **TypeScript** (`example.ts`) - Comments removed, compressed to single line  
- **C** (`example.c`) - Comments removed, compressed to single line
- **Go** (`example.go`) - Comments removed, compressed to single line
- **Rust** (`example.rs`) - Comments removed, compressed to single line
- **Java** (`example.java`) - Comments removed, compressed to single line

### Languages that only remove comments (preserve whitespace):
- **Python** (`example.py`) - Comments removed, whitespace preserved
- **Ruby** (`example.rb`) - Comments removed, whitespace preserved

## Testing the Compression

### Without compression:
```bash
python ../catls.py --globs "*.js" .
python ../catls.py --globs "*.py" .
```

### With compression (requires tree-sitter-languages):
```bash
python ../catls.py --globs "*.js" --compress-globs .
python ../catls.py --globs "*.py" --compress-globs .
python ../catls.py --globs "*.c" --compress-globs .
```

### Test all files:
```bash
python ../catls.py --recursive --compress-globs .
```

## Expected Behavior

- **Comment Removal**: All single-line (`//`, `#`) and multi-line (`/* */`, `""" """`) comments should be removed
- **String Preservation**: String literals should remain intact with their original content
- **Whitespace Compression**: For supported languages, code should be compressed to single lines
- **Whitespace Preservation**: For Python/Ruby, indentation and line breaks should be preserved
- **Graceful Fallback**: If tree-sitter is not installed, original content is displayed with a warning

## Notes

- These files contain extensive comments to test the comment removal functionality
- Each file implements meaningful functionality to ensure the compressed code remains valid
- String literals contain various characters to test preservation during compression