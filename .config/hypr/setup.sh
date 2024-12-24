#!/bin/zsh

# Function to display error notifications
notify_error() {
    hyprctl notify 3 5000 0 "Error: $1"
}

# Function to start a process with error handling
start_process() {
    local process_name="$1"
    local command="$2"
    
    if ! pgrep -x "$process_name" >/dev/null; then
        if ! $command & then
            notify_error "Failed to start $process_name"
            return 1
        fi
    else
        notify_error "$process_name is already running"
        return 1
    fi
}

# Start waybar
start_process "waybar" "waybar" || {
    echo "Failed to start waybar"
    exit 1
}
