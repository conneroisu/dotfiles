#!/usr/bin/env bash
# cf - Fuzzy directory finder
# Usage: cd $(cf [starting-directory])
#
# Interactively searches for directories using fd and fzf.
# Outputs the selected directory path to stdout.
# If no directory is selected (ESC/Ctrl-C), outputs nothing.
#
# Example:
#   cd $(cf)           # Search from current directory
#   cd $(cf ~/code)    # Search from ~/code

set -euo pipefail

# Determine starting directory
START_DIR="${1:-.}"

# Find directories with fd and select with fzf
# If user cancels (ESC), fzf returns non-zero and we catch it with || true
SELECTED_DIR=$(fd --type d --hidden --exclude .git . "$START_DIR" | \
  fzf --reverse --preview "ls --color {}" || true)

# Output the selected directory (or nothing if cancelled)
if [[ -n "$SELECTED_DIR" ]]; then
  echo "$SELECTED_DIR"
fi
