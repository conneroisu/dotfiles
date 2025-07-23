#!/usr/bin/env python3
"""
CCCleaner - Claude Code History Cleaner

A configurable tool for cleaning Claude Code conversation history from .claude.json files.
Removes short messages without pasted content based on configurable criteria.
"""

import json
import sys
import os
import re
import argparse
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any


def should_remove_entry(entry: Dict[str, Any], min_length: int = 10) -> bool:
    """
    Determine if a history entry should be removed.
    
    Args:
        entry: A history entry dictionary
        min_length: Minimum message length threshold
        
    Returns:
        True if the entry should be removed, False otherwise
    """
    display = entry.get('display', '')
    pasted_contents = entry.get('pastedContents', {})
    
    # Keep entries with pasted content
    if pasted_contents and len(pasted_contents) > 0:
        for paste_data in pasted_contents.values():
            if isinstance(paste_data, dict) and paste_data.get('content', '').strip():
                return False
    
    # Remove short messages without meaningful pasted content
    return len(display) < min_length


def clean_project_history(project_data: Dict[str, Any], min_length: int = 10) -> Dict[str, int]:
    """
    Clean the history for a single project.
    
    Args:
        project_data: The project data dictionary
        min_length: Minimum message length threshold
        
    Returns:
        Dictionary with statistics about removed entries
    """
    if 'history' not in project_data:
        return {'original_count': 0, 'removed_count': 0, 'remaining_count': 0}
    
    original_history = project_data['history']
    original_count = len(original_history)
    
    # Filter out entries that should be removed
    filtered_history = [
        entry for entry in original_history 
        if not should_remove_entry(entry, min_length)
    ]
    
    project_data['history'] = filtered_history
    
    removed_count = original_count - len(filtered_history)
    
    return {
        'original_count': original_count,
        'removed_count': removed_count,
        'remaining_count': len(filtered_history)
    }


def clean_claude_json(file_path: str, min_length: int = 10, backup: bool = True) -> Dict[str, Any]:
    """
    Clean all project histories in a .claude.json file.
    
    Args:
        file_path: Path to the .claude.json file
        min_length: Minimum message length threshold
        backup: Whether to create a backup before modifying
        
    Returns:
        Dictionary with cleaning statistics
    """
    # Read the original file
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Create backup if requested
    if backup:
        backup_path = f"{file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(file_path, backup_path)
        print(f"Backup created: {backup_path}")
    
    # Process projects
    projects = data.get('projects', {})
    total_stats = {
        'projects_processed': 0,
        'total_original_entries': 0,
        'total_removed_entries': 0,
        'total_remaining_entries': 0,
        'project_details': {}
    }
    
    for project_path, project_data in projects.items():
        stats = clean_project_history(project_data, min_length)
        total_stats['projects_processed'] += 1
        total_stats['total_original_entries'] += stats['original_count']
        total_stats['total_removed_entries'] += stats['removed_count']
        total_stats['total_remaining_entries'] += stats['remaining_count']
        total_stats['project_details'][project_path] = stats
    
    # Write the cleaned data back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    return total_stats


def print_stats(stats: Dict[str, Any]) -> None:
    """Print cleaning statistics in a readable format."""
    print(f"\n=== Claude History Cleaning Results ===")
    print(f"Projects processed: {stats['projects_processed']}")
    print(f"Total entries before: {stats['total_original_entries']}")
    print(f"Total entries removed: {stats['total_removed_entries']}")
    print(f"Total entries remaining: {stats['total_remaining_entries']}")
    
    if stats['total_removed_entries'] > 0:
        percentage = (stats['total_removed_entries'] / stats['total_original_entries']) * 100
        print(f"Percentage removed: {percentage:.1f}%")
    
    print(f"\n=== Per-Project Details ===")
    for project_path, project_stats in stats['project_details'].items():
        if project_stats['removed_count'] > 0:
            print(f"{project_path}:")
            print(f"  Before: {project_stats['original_count']} entries")
            print(f"  Removed: {project_stats['removed_count']} entries")
            print(f"  After: {project_stats['remaining_count']} entries")


def dry_run_analysis(file_path: str, min_length: int = 10) -> None:
    """Perform dry-run analysis without modifying files."""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    projects = data.get('projects', {})
    total_would_remove = 0
    total_entries = 0
    
    print("=== DRY RUN - No changes will be made ===")
    
    for project_path, project_data in projects.items():
        history = project_data.get('history', [])
        total_entries += len(history)
        would_remove = sum(1 for entry in history if should_remove_entry(entry, min_length))
        total_would_remove += would_remove
        
        if would_remove > 0:
            print(f"{project_path}: {would_remove}/{len(history)} entries would be removed")
    
    print(f"\nSummary:")
    print(f"Total entries: {total_entries}")
    print(f"Would remove: {total_would_remove}")
    print(f"Would keep: {total_entries - total_would_remove}")
    
    if total_would_remove > 0:
        percentage = (total_would_remove / total_entries) * 100
        print(f"Percentage to remove: {percentage:.1f}%")
    else:
        print("No entries would be removed - file is already clean!")


def main():
    """Main function to handle command line arguments and execute cleaning."""
    parser = argparse.ArgumentParser(
        description="Clean Claude Code history entries with short messages and no pasted content",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  cccleaner                    # Clean ~/.claude.json (with backup)
  cccleaner --dry-run          # Preview what would be cleaned  
  cccleaner -d                 # Same as --dry-run (short form)
  cccleaner --min-length 5     # Remove messages < 5 characters
  cccleaner --no-backup        # Clean without creating backup
  cccleaner /path/to/file.json # Clean specific file
        """
    )
    
    parser.add_argument(
        'file_path',
        nargs='?',
        default=None,
        help='Path to .claude.json file (defaults to ~/.claude.json)'
    )
    parser.add_argument(
        '--dry-run', '-d',
        action='store_true',
        help='Show what would be removed without making changes'
    )
    parser.add_argument(
        '--min-length',
        type=int,
        default=10,
        help='Minimum message length to consider for removal (default: 10)'
    )
    parser.add_argument(
        '--no-backup',
        action='store_true',
        help='Skip creating a backup file'
    )
    
    args = parser.parse_args()
    
    # Determine file path
    if args.file_path is None:
        file_path = str(Path.home() / '.claude.json')
    else:
        file_path = args.file_path
    
    # Check if file exists
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    
    try:
        if args.dry_run:
            dry_run_analysis(file_path, args.min_length)
        else:
            # Perform actual cleaning
            stats = clean_claude_json(file_path, args.min_length, backup=not args.no_backup)
            print_stats(stats)
            print("\nCleaning completed successfully!")
    
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in file {file_path}: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()