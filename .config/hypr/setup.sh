#!/bin/zsh

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
path=(
    $HOME/.cargo/bin
    $HOME/zig
    $HOME/.local/bin
    $HOME/flutter/bin
    $GOROOT/bin
    $GOPATH/bin
    $FLYCTL_INSTALL/bin
    /home/connerohnesorge/.turso
    /home/connerohnesorge/.config/herd-lite/bin
    /user/local/bin/
    $path
)
export PATH=$PATH:path

hyprnotify &

ags &
