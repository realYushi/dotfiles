# Sourced for every zsh invocation (interactive, login, scripts).
# Keep this minimal & fast: only base environment + $HOME bootstrap.

# --- XDG base directory specification --------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
# XDG_RUNTIME_DIR is intentionally left unset on macOS (there is no
# /run/user/$UID). Tools that want it fall back to $TMPDIR per-session.

# --- zsh: move startup files out of $HOME ---------------------------
# .zshenv must stay here as the bootstrap that sets $ZDOTDIR; everything
# else (.zshrc, .zimrc, history, etc.) then lives under $ZDOTDIR.
# (Eliminating even this file would require setting ZDOTDIR in /etc/zshenv.)
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Disable macOS per-session save so ~/.zsh_sessions is never created.
export SHELL_SESSIONS_DISABLE=1
export PATH="/Users/yushi/.local/share/../bin:$PATH"
export PATH="/Users/yushi/.cache/.bun/bin:$PATH"
# --- ncurses: relocate user terminfo out of $HOME --------------------
# Keep a terminfo path pre-set by the terminal emulator (e.g. Ghostty's
# bundled xterm-ghostty) so the terminal keeps working, while making the
# XDG data dir the writable user-terminfo store (avoids ~/.terminfo).
export TERMINFO="${TERMINFO-$XDG_DATA_HOME/terminfo}"
export TERMINFO_DIRS="$XDG_DATA_HOME/terminfo:${TERMINFO_DIRS:-/usr/share/terminfo}"

# --- npm: relocate cache out of $HOME -------------------------------
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# --- pi coding agent: relocate config out of $HOME ------------------
export PI_CODING_AGENT_DIR="$XDG_CONFIG_HOME/pi/agent"
