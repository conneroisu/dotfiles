#!/usr/bin/env bash

stow --ignore=.git/ \
	--ignore=Makefile \
	--ignore=./flake.nix \
	--ignore=Taskfile.yaml \
	--ignore=README.md \
	--ignore=./.obsidian.vimrc \
	--ignore=./hosts/ \
	--ignore=./modules/ \
	--ignore=./overlays/ \
.
