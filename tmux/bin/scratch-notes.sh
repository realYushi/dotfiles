#!/usr/bin/env bash

set -euo pipefail

notes_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
notes_file="$notes_dir/scratch-notes.md"

if [[ "${1:-}" == "--run" ]]; then
    mkdir -p "$notes_dir"
    touch "$notes_file"
    exec "${VISUAL:-${EDITOR:-nvim}}" "$notes_file"
fi

exec tmux display-popup -E -w 80% -h 80% "$HOME/.config/tmux/bin/scratch-notes.sh --run"
