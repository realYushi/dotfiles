#!/usr/bin/env bash

set -euo pipefail

config_dir="$HOME/.config/tmux"

if tmux source-file "$config_dir/tmux.conf"; then
    if "$config_dir/bin/check-deps.sh" >/dev/null 2>&1; then
        tmux display-message "Reloaded"
    else
        tmux display-popup -E -w 70% -h 70% "$config_dir/bin/check-deps.sh --hold"
    fi
fi
