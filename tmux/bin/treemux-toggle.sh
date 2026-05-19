#!/usr/bin/env bash
# Trigger treemux toggle / focus from root-table or which-key (prefix disabled).
# Usage: treemux-toggle.sh [Tab|Bspace]
#   Tab    = toggle tree (keep focus)     — default
#   Bspace = toggle + focus tree
set -euo pipefail

key="${1:-Tab}"
pane_id="$(tmux display-message -p '#{pane_id}')"
value="$(tmux show-option -gqv "@treemux-key-$key")"

if [ -z "$value" ]; then
    tmux display-message "treemux not initialized (option @treemux-key-$key empty)"
    exit 1
fi

exec "$HOME/.config/tmux/plugins/treemux/scripts/toggle.sh" "$value" "$pane_id"
