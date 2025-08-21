#!/bin/bash

# Define the path to save the screenshot
ppath=~/Pictures/Screenshot-"$(date +%F_%T)".png

# Take a screenshot of a selected region and copy it to clipboard, then save it to the defined path
grim -g "$(slurp)" - | wl-copy && wl-paste > "$ppath" | dunstify "Screenshot of the region taken at $(date +%F_%T)" -t 1000

# XML escaping function for special characters
xml_escape() {
    local input="$1"
    echo "$input" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Fallback method: Add to recent files using recently-used.xbel if Python method fails
if [ $? -ne 0 ]; then
    # Check if the screenshot file actually exists and is valid
    if [ -f "$ppath" ] && [ -s "$ppath" ]; then
        # Fallback: manually add to recently-used.xbel
        recent_file="$HOME/.local/share/recently-used.xbel"
        if [ -f "$recent_file" ]; then
            # Create backup
            cp "$recent_file" "$recent_file.bak"
            
            # Get absolute path and escape special characters for XML
            abs_path=$(realpath "$ppath")
            escaped_path=$(xml_escape "$abs_path")
            file_uri="file://$escaped_path"
            timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            
            # Create temporary file with new entry
            temp_file=$(mktemp)
            
            # Add new entry after the opening tag
            sed "/<recent-files>/a\\
  <bookmark href=\"$file_uri\" added=\"$timestamp\" modified=\"$timestamp\" visited=\"$timestamp\">\\
    <info>\\
      <metadata owner=\"http://freedesktop.org\">\\
        <mime:mime-type type=\"image/png\"/>\\
      </metadata>\\
    </info>\\
  </bookmark>" "$recent_file" > "$temp_file"
            
            # Replace original file
            mv "$temp_file" "$recent_file"
        fi
    fi
fi

# Create a notification message
NOTE="Screenshot @ $ppath"
