#!/bin/bash

# Define the path to save the screenshot
ppath=~/Pictures/Screenshot-"$(date +%F_%T)".png

# Take a screenshot of a selected region and copy it to clipboard, then save it to the defined path
grim -g "$(slurp)" - | wl-copy && wl-paste > "$ppath" | dunstify "Screenshot of the region taken at $(date +%F_%T)" -t 1000
