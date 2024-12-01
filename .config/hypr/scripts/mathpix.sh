#!/bin/bash
set -e

# Function to run command and notify
run_command() {
    local output
    if ! output=$(eval "$1" 2>&1); then
        dunstify "Error" "$2\n\nCommand output:\n$output" -u critical -t 15000
        exit 1
    fi
    echo "$output"
}

# Define the path to save the screenshot
ppath=~/Pictures/Screenshots/Screenshot-"$(date +%F_%T)".png
mdpath=~/Pictures/Screenshots/Screenshot-"$(date +%F_%T)".mmd

# Take a screenshot of a selected region and copy it to clipboard, then save it to the defined path
run_command "grim -g \"$(slurp)\" - > \"$ppath\"" "Failed to capture screenshot"

# Create a notification message
NOTE="Screenshot @ $ppath"

# Disable color output
export FORCE_COLOR=0

# Run mpx with all provided arguments
run_command '$HOME/.config/hypr/scripts/pixcli '$ppath
