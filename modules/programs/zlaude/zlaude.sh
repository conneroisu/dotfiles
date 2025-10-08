#!/usr/bin/env bash

export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
export ANTHROPIC_AUTH_TOKEN=$(grep '^ZAI_API_KEY=' ~/dotfiles/.env | cut -d '=' -f 2)

claude $@
