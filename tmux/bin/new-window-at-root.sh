#!/usr/bin/env bash

set -euo pipefail

start_dir="$(tmux display-message -p '#{pane_current_path}')"
target_dir="$start_dir"

if command -v git >/dev/null 2>&1; then
    git_root="$(git -C "$start_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$git_root" ]; then
        target_dir="$git_root"
    fi
fi

exec tmux new-window -c "$target_dir"
