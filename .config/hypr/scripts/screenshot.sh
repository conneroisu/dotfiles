#!/bin/bash

# Define the path to save the screenshot
ppath=~/Pictures/Screenshot-"$(date +%F_%T)".png

# Take a screenshot of a selected region and copy it to clipboard, then save it to the defined path
if grim -g "$(slurp)" - | wl-copy && wl-paste > "$ppath"; then
    # Send notification with action buttons
    action=$(dunstify "Screenshot taken" "Saved at $(date +%F_%T)" \
        -A "open,default,Open with default app" \
        -A "folder,Open in file manager" \
        -t 10000 \
        -i "$ppath")
    # Handle the action based on user response
    case "$action" in
        "open")
            xdg-open "$ppath"
            ;;
        "folder")
            dolphin --select "$ppath"
            ;;
    esac
else
    dunstify "Screenshot failed" "Could not capture screenshot" -u critical
fi
