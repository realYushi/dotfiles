#!/usr/bin/env bash

set -euo pipefail

config_dir="$HOME/.config/tmux"

which_key_src="$config_dir/which-key.yaml"
which_key_dst="$config_dir/plugins/tmux-which-key/config.yaml"
if [[ -f "$which_key_src" && ! -L "$which_key_dst" ]]; then
    ln -sf "$which_key_src" "$which_key_dst"
fi

if tmux source-file "$config_dir/tmux.conf"; then
    if "$config_dir/bin/check-deps.sh" >/dev/null 2>&1; then
        tmux display-message "Reloaded"
    else
        tmux display-popup -E -w 70% -h 70% "$config_dir/bin/check-deps.sh --hold"
    fi
fi
