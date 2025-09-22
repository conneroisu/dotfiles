#!/bin/sh

wl-clip-persist --clipboard regular
determinate-nixd init
ashell &
hyprshell run -vv &
