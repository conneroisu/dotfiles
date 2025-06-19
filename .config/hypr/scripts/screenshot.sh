#!/bin/bash
# Script to take a screenshot and save it to the clipboard.
# It should also add the image to the recently used.

set -euo pipefail

###############################################################################
# 1. Hard-coded variables  ────────────────────────────────────────────────────
###############################################################################
xbel_file="$HOME/.local/share/recently-used.xbel"
ppath="$HOME/Pictures/Screenshots/Screenshot-$(date +%F_%T).png"
target="$ppath"
###############################################################################

###############################################################################
# 2. Screenshot + user notifications  ────────────────────────────────────────
###############################################################################
grim -g "$(slurp)" - | wl-copy && wl-paste > "$ppath"
dunstify "Screenshot of the region taken at $(date +%F_%T)" -t 1000

NOTE="Screenshot @ $ppath"
dunstify "$NOTE" -t 10000 -A "copy, Copy to clipboard" --action="copy:wl-copy $ppath"
###############################################################################

###############################################################################
# 3. Ensure the XBEL file exists (create a minimal skeleton if missing) ░░░░░░
###############################################################################
if [[ ! -f $xbel_file ]]; then
  cat >"$xbel_file" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0"
      xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
</xbel>
EOF
fi
###############################################################################

###############################################################################
# 4. Build the bookmark (with applications block) and insert it  ─────────────
###############################################################################
ts_utc=$(date -u +%Y-%m-%dT%H:%M:%S.%6NZ)

read -r -d '' bookmark <<EOF
  <bookmark href="file://$target" added="$ts_utc" modified="$ts_utc" visited="$ts_utc">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="application/octet-stream"/>
        <bookmark:applications>
          <bookmark:application name="Eye of GNOME"
                                exec="&apos;eog %u&apos;"
                                modified="$ts_utc"
                                count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
EOF

tmp=$(mktemp)

awk -v b="$bookmark" '
  !done && />[[:space:]]*$/ { print; print b; done=1; next }
  { print }
' "$xbel_file" > "$tmp"

mv -- "$tmp" "$xbel_file"
###############################################################################

###############################################################################
# 5. Final desktop notification  ─────────────────────────────────────────────
###############################################################################
dunstify "✔ Screenshot saved and bookmarked" \
         "File: $ppath\nBookmark file: $xbel_file" \
         -t 3000
###############################################################################
