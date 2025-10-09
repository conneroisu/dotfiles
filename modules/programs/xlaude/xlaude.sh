#!/usr/bin/env bash

export ANTHROPIC_BASE_URL=https://api.x.ai
export ANTHROPIC_AUTH_TOKEN=$(grep '^XAI_API_KEY=' ~/dotfiles/.env | cut -d '=' -f 2)

claude $@
