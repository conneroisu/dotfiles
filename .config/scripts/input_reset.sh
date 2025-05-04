#!/bin/bash

if tmux list-panes -s -F '#{pane_input_off}' | grep -q 1; then
    tmux select-pane -e
fi
