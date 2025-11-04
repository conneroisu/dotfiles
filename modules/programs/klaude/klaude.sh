#!/usr/bin/env bash

export ANTHROPIC_BASE_URL=https://api.kimi.com/coding/
export ANTHROPIC_AUTH_TOKEN=$(grep '^KIMI_API_KEY=' ~/dotfiles/.env | cut -d '=' -f 2)
export ANTHROPIC_MODEL=kimi-for-coding
export ANTHROPIC_SMALL_FAST_MODEL=kimi-for-coding

claude $@
