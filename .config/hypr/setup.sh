#!/bin/sh

wl-clip-persist --clipboard regular
determinate-nixd init
waybar &
waybar-lyric &
# -v --log-file=/tmp/waybar-lyric.log
hyprshell run -vv &
