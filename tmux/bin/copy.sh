#!/usr/bin/env bash

set -euo pipefail

if command -v pbcopy >/dev/null 2>&1; then
    exec pbcopy "$@"
fi

if command -v wl-copy >/dev/null 2>&1; then
    exec wl-copy "$@"
fi

if command -v xclip >/dev/null 2>&1; then
    exec xclip -i -selection clipboard "$@"
fi

printf 'No supported clipboard tool found (tried pbcopy, wl-copy, xclip).\n' >&2
exit 1
