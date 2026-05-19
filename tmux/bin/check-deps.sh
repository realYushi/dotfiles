#!/usr/bin/env bash

set -euo pipefail

hold="${1:-}"
missing=0

report() {
    printf '%-24s %s\n' "$1" "$2"
}

check_cmd() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        report "$name" "$(command -v "$name")"
    else
        report "$name" "missing"
        missing=1
    fi
}

check_file() {
    local label="$1"
    local path="$2"
    if [ -e "$path" ]; then
        report "$label" "$path"
    else
        report "$label" "missing ($path)"
        missing=1
    fi
}

printf 'tmux config healthcheck\n\n'

check_cmd tmux
check_cmd nvim
check_cmd sesh
check_cmd fzf
check_cmd fzf-tmux
check_cmd fd
check_cmd git
check_cmd lsof
check_cmd python

if command -v python >/dev/null 2>&1; then
    if python - <<'PY' >/dev/null 2>&1
import importlib.util
raise SystemExit(0 if importlib.util.find_spec("libtmux") else 1)
PY
    then
        report "python:libtmux" "ok"
    else
        report "python:libtmux" "missing"
        missing=1
    fi
fi

check_file "which-key config" "$HOME/.config/tmux/plugins/tmux-which-key/config.yaml"
check_file "TPM" "$HOME/.config/tmux/plugins/tpm/tpm"
check_file "treemux python" "$HOME/.local/share/treemux-venv/bin/python3"
check_file "copy wrapper" "$HOME/.config/tmux/bin/copy.sh"
check_file "ram wrapper" "$HOME/.config/tmux/bin/ram-percentage.sh"

printf '\n'
if [ "$missing" -eq 0 ]; then
    printf 'All required dependencies are present.\n'
else
    printf 'Missing dependencies detected.\n'
fi

if [ "$hold" = "--hold" ]; then
    printf '\nPress Enter to close...'
    IFS= read -r _
fi

exit "$missing"
