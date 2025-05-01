#!/bin/bash
# Terminal session recorder that strips ANSI color codes

# Create a directory for logs if it doesn't exist
LOG_DIR="$HOME/terminal_logs"
mkdir -p "$LOG_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/terminal_session_$TIMESTAMP.log"
TEMP_FILE="$LOG_DIR/terminal_session_$TIMESTAMP.raw"

# Start recording
echo "Recording terminal session to $LOG_FILE"
echo "Type 'exit' or press Ctrl+D to end recording"
echo "------------------------------------------"

# Record to a temporary file first
script -f "$TEMP_FILE"

# Strip ANSI escape sequences from the output
# This pattern matches color codes and other terminal control sequences
cat "$TEMP_FILE" | perl -pe 's/\x1b\[[0-9;]*[mGKHF]//g' > "$LOG_FILE"

# Remove the temporary file
rm "$TEMP_FILE"

echo "------------------------------------------"
echo "Session recording saved to $LOG_FILE (with color codes removed)"
