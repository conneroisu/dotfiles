#!/bin/bash

# Define the path to save the screenshot
ppath=~/Pictures/Screenshots/Screenshot-"$(date +%F_%T)".png

# Take a screenshot of a selected region and copy it to clipboard, then save it to the defined path
grim -g "$(slurp)" - | wl-copy && wl-paste > "$ppath" | dunstify "Screenshot of the region taken at $(date +%F_%T)" -t 1000

# Create a notification message
NOTE="Screenshot @ $ppath"

# Notify using hyprctl and dunstify
# hyprctl notify 1 10000 0 "$NOTE"
dunstify "$NOTE" -t 10000 -A "copy, Copy to clipboard" --action="copy:wl-copy $ppath"

# grim -g "$(slurp)" - | swappy -f -
