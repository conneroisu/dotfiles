#!/usr/bin/env bash

# Screenshot script with error handling and recent files integration
# Dependencies: grim, slurp, wl-clipboard, dunst, sqlite3

# Configuration
SCREENSHOT_DIR="$HOME/Pictures"
TIMESTAMP="$(date +%F_%T)"
FILENAME="Screenshot-${TIMESTAMP}.png"
FULL_PATH="${SCREENSHOT_DIR}/${FILENAME}"
DB_PATH="$HOME/.local/share/kactivitymanagerd/resources/database"
TEMP_FILE="/tmp/screenshot_temp_$$.png"

# Color codes for notifications
RED="#FF0000"
GREEN="#00FF00"
YELLOW="#FFFF00"

# Function to send error notification
error_notify() {
    dunstify -u critical -h string:bgcolor:"$RED" "Screenshot Error" "$1" -t 3000
}

# Function to send success notification
success_notify() {
    dunstify -u normal -h string:bgcolor:"$GREEN" "Screenshot" "$1" -t 2000
}

# Function to send warning notification
warn_notify() {
    dunstify -u normal -h string:bgcolor:"$YELLOW" "Screenshot Warning" "$1" -t 2000
}

# Function to add file to KDE recent files
add_to_recent() {
    local file_path="$1"
    local file_uri="${file_path}"
    local current_timestamp="$(date +%s)"
    
    # Check if database exists
    if [[ ! -f "$DB_PATH" ]]; then
        warn_notify "KDE Activities database not found. Skipping recent files update."
        return 1
    fi
    
    # Get the current activity ID (use :global if not found)
    local activity_id
    activity_id=$(sqlite3 "$DB_PATH" "SELECT id FROM Activities WHERE current = 1 LIMIT 1;" 2>/dev/null)
    if [[ -z "$activity_id" ]]; then
        activity_id="2affd499-c9f4-4d8f-9b1d-c95133e574a6"
    fi
    
    # Add to recent files database with Unix timestamps
    sqlite3 "$DB_PATH" 2>/dev/null <<EOF
-- Add to ResourceEvent with Unix timestamps
INSERT INTO ResourceEvent (
    usedActivity,
    initiatingAgent,
    targettedResource,
    start,
    end
) VALUES (
    '${activity_id}',
    'org.kde.dolphin',
    '${file_uri}',
    ${current_timestamp},
    ${current_timestamp}
);

-- Update ResourceScoreCache with Unix timestamps
INSERT OR REPLACE INTO ResourceScoreCache (
    usedActivity,
    initiatingAgent,
    targettedResource,
    scoreType,
    cachedScore,
    firstUpdate,
    lastUpdate
) VALUES (
    '${activity_id}',
    'org.kde.dolphin',
    '${file_uri}',
    0,
    1.0,
    ${current_timestamp},
    ${current_timestamp}
);

-- Also add to ResourceInfo if it doesn't exist
INSERT OR IGNORE INTO ResourceInfo (
    targettedResource,
    title,
    mimetype,
    autoTitle,
    autoMimetype
) VALUES (
    '${file_uri}',
    '${FILENAME}',
    'image/png',
    1,
    1
);

-- Update ResourceLink
INSERT OR REPLACE INTO ResourceLink (
    usedActivity,
    initiatingAgent,
    targettedResource
) VALUES (
    '${activity_id}',
    'org.kde.dolphin',
    '${file_uri}'
);
EOF
    
    if [[ $? -eq 0 ]]; then
        return 0
    else
        warn_notify "Failed to add to recent files database"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in grim slurp wl-copy wl-paste dunstify sqlite3; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_notify "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Create screenshot directory if it doesn't exist
create_screenshot_dir() {
    if [[ ! -d "$SCREENSHOT_DIR" ]]; then
        mkdir -p "$SCREENSHOT_DIR" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            error_notify "Failed to create screenshot directory: $SCREENSHOT_DIR"
            exit 1
        fi
    fi
}

# Main screenshot function
take_screenshot() {
    # Get region selection
    local region
    region=$(slurp 2>/dev/null)
    
    # Check if user cancelled selection
    if [[ -z "$region" ]]; then
        warn_notify "Screenshot cancelled"
        exit 0
    fi
    
    # Take screenshot and save to temp file first
    if ! grim -g "$region" "$TEMP_FILE" 2>/dev/null; then
        error_notify "Failed to capture screenshot"
        exit 1
    fi
    
    # Check if screenshot file is valid and not empty
    if [[ ! -s "$TEMP_FILE" ]]; then
        error_notify "Screenshot file is empty"
        rm -f "$TEMP_FILE" 2>/dev/null
        exit 1
    fi
    
    # Copy to clipboard
    if ! wl-copy < "$TEMP_FILE" 2>/dev/null; then
        warn_notify "Failed to copy to clipboard, but screenshot was saved"
    fi
    
    # Move temp file to final destination
    if ! mv "$TEMP_FILE" "$FULL_PATH" 2>/dev/null; then
        error_notify "Failed to save screenshot to $FULL_PATH"
        rm -f "$TEMP_FILE" 2>/dev/null
        exit 1
    fi
    
    # Set proper permissions
    chmod 644 "$FULL_PATH" 2>/dev/null
    
    # Add to recent files
    add_to_recent "$FULL_PATH"
    
    # Send success notification with clickable action
    success_notify "Screenshot saved: $FILENAME"
    
    # Optional: Open in default viewer when clicking notification
    # You can uncomment this if you want the notification to be actionable
    # dunstify -u normal -h string:bgcolor:"$GREEN" \
    #          -A "open,Open" \
    #          "Screenshot" "Saved: $FILENAME" -t 2000 | {
    #     read -r action
    #     if [[ "$action" == "open" ]]; then
    #         xdg-open "$FULL_PATH" &
    #     fi
    # }
}

# Cleanup function
cleanup() {
    rm -f "$TEMP_FILE" 2>/dev/null
}

# Set trap for cleanup on exit
trap cleanup EXIT INT TERM

# Main execution
main() {
    # Check all dependencies first
    check_dependencies
    
    # Ensure screenshot directory exists
    create_screenshot_dir
    
    # Take the screenshot
    take_screenshot
    
    # Log to systemd journal if available
    if command -v logger &> /dev/null; then
        logger -t screenshot "Screenshot saved to $FULL_PATH"
    fi
    
    # Optional: Refresh Dolphin's recent files view if it's running
    # This sends a signal to refresh the view
    if pgrep -x dolphin > /dev/null; then
        qdbus org.kde.dolphin-* /dolphin/Dolphin_1 org.kde.dolphin.MainWindow.refreshViews 2>/dev/null || true
    fi
    
    # Optional: Play sound on success (uncomment if you want audio feedback)
    # if command -v paplay &> /dev/null; then
    #     paplay /usr/share/sounds/freedesktop/stereo/camera-shutter.oga 2>/dev/null &
    # fi
}

# Run main function
main "$@"

# Exit successfully
exit 0
