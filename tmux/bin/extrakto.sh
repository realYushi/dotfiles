#!/bin/sh
# Wrapper so which-key can invoke extrakto without embedding #{pane_id}
# (the menu builder mangles command strings that mix nested quotes + formats).
# Usage: extrakto.sh [filter]
pane_id=$(tmux display-message -p '#{pane_id}')
filter="${1:-}"

if [ -n "$filter" ]; then
    exec "$HOME/.config/tmux/plugins/extrakto/scripts/open.sh" "${pane_id}" "${filter}"
fi

exec "$HOME/.config/tmux/plugins/extrakto/scripts/open.sh" "${pane_id}"
