# CCCleaner - Claude Code History Cleaner

A simple, effective tool for cleaning Claude Code conversation history from `.claude.json` files. Removes short messages without pasted content to reduce clutter while preserving important conversations.

## Features

- **Smart Filtering**: Removes messages shorter than configurable threshold
- **Content Preservation**: Keeps entries with pasted content regardless of length
- **Safe Operations**: Creates automatic backups before modification
- **Dry-Run Preview**: See what would be removed before making changes
- **Cross-Platform**: Works on NixOS and macOS

## Installation

Add to your host configuration:

```nix
myconfig.programs.cccleaner.enable = true;
```

Or automatically included with the engineer feature:
```nix
myconfig.features.engineer.enable = true;
```

## Usage

### Basic Operations

```bash
# Clean ~/.claude.json with backup
cccleaner

# Preview what would be cleaned (recommended first step)
cccleaner --dry-run
cccleaner -d  # Short form

# Clean specific file
cccleaner /path/to/backup.json
```

### Options

```bash
# Custom minimum length (default: 10 characters)
cccleaner --min-length 5

# Skip backup creation
cccleaner --no-backup

# Get help
cccleaner --help
```

### Example Output

```
=== DRY RUN - No changes will be made ===
/home/user/project1: 12/45 entries would be removed
/home/user/project2: 3/28 entries would be removed

Summary:
Total entries: 73
Would remove: 15
Would keep: 58
Percentage to remove: 20.5%
```

## How It Works

CCCleaner identifies entries for removal based on:

1. **Message Length**: Shorter than threshold (default 10 characters)
2. **Pasted Content**: No meaningful pasted content attached

**Always Preserved:**
- Messages with pasted content (code, errors, files)
- Messages meeting minimum length requirement
- All non-history data in the .claude.json file

## Common Use Cases

### Regular Maintenance
```bash
# Weekly cleanup
cccleaner -d  # Preview first
cccleaner     # Then clean
```

### Before Sharing
```bash
# Clean before sharing .claude.json
cccleaner --min-length 15 /path/to/shared.json
```

### Storage Optimization
```bash
# More aggressive cleaning
cccleaner --min-length 20
```

## Safety Features

- **Automatic Backups**: Every run creates timestamped backup unless `--no-backup`
- **Dry-Run Mode**: Always preview with `--dry-run` before cleaning
- **JSON Validation**: Validates file integrity before and after changes
- **Error Handling**: Never corrupts files, fails safely on errors

## Examples

### Typical Workflow
```bash
# 1. Check what would be cleaned
cccleaner -d

# 2. Clean if satisfied with preview
cccleaner

# 3. Verify results
ls -la ~/.claude.json.backup.*
```

### Custom Cleaning
```bash
# Be more conservative (keep messages 5+ chars)
cccleaner --min-length 5 -d

# Clean specific project backup
cccleaner --min-length 15 /backup/claude-history.json
```

## File Structure

- `cccleaner.py` - Main Python script
- `default.nix` - Nix module configuration  
- `README.md` - This documentation

## Development

Test the script directly:
```bash
python3 cccleaner.py --help
python3 cccleaner.py --dry-run
```

## License

Part of the [dotfiles](https://github.com/conneroisu/dotfiles) repository.