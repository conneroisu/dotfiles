#!/usr/bin/env bash
set -euo pipefail

### ---------- configurable “constants” ----------
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
FILE_PREFIX="Screenshot"
XBEL_FILE="$HOME/.local/share/recently-used.xbel"
APP_NAME="Eye of GNOME"
APP_EXEC="'eog %u'"
### ---------------------------------------------

mkdir -p "$SCREENSHOT_DIR"

# Path that will hold the new image
timestamp="$(date +%F_%T)"
ppath="$SCREENSHOT_DIR/${FILE_PREFIX}-${timestamp}.png"

# 1. Take the shot
grim -g "$(slurp)" - > "$ppath"

# 2. User feedback
dunstify -t 1000 "Screenshot captured → $ppath"
#
# 3. Register the file in GTK recent-files (recently-used.xbel)
iso_ts="$(date --iso-8601=seconds)"
file_uri="file://$ppath"

bookmark=$(cat <<EOF
  <bookmark href="$file_uri" added="$iso_ts" modified="$iso_ts">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="image/png"/>
        <bookmark:applications>
          <bookmark:application name="$APP_NAME" exec="$APP_EXEC" modified="$iso_ts" count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
EOF
)

# Inject before the closing </xbel>, using a temp file to avoid corruption.
tmp="$(mktemp)"
# Copy everything *except* the closing tag
head -n -1 "$XBEL_FILE" > "$tmp"
# Append the new bookmark + the closing tag
printf '%s\n</xbel>\n' "$bookmark" >> "$tmp"
# Atomically replace
mv "$tmp" "$XBEL_FILE"

# Optional extra logging
dunstify -t 2000 "recently-used.xbel updated (line count: $(wc -l < "$XBEL_FILE"))"
