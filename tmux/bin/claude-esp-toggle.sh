#!/usr/bin/env bash
# Toggle claude-esp-rs pane in current window.
# If a pane in the current window runs claude-esp-rs, kill it.
# Otherwise, open a right split running claude-esp-rs with forced dark theme.

set -euo pipefail

pane_id=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' \
  | awk '$2 == "claude-esp-rs" { print $1; exit }')

if [[ -n "${pane_id}" ]]; then
  tmux kill-pane -t "${pane_id}"
else
  tmux split-window -h -l 40% 'claude-esp-rs'
  tmux select-pane -P 'bg=#000000,fg=#ffffff'
  tmux set -p @pane_dark 1
fi
