# Interactive shell configuration

# Autosuggestions: rebind only on widget changes, not every keystroke.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source /opt/homebrew/opt/zimfw/share/zimfw.zsh init
fi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Initialize modules.
source ${ZIM_HOME}/init.zsh

# History (override zim's environment module defaults).
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY
IGNORE_EOF=3
export LESS="-R -F -X"
export LESSOPEN="|/opt/homebrew/bin/lesspipe.sh %s"
export EDITOR=nvim
export VISUAL="$EDITOR"

# Homebrew (interactive only to avoid slowing down scripts)
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
eval "$(mise activate zsh)"

(( ${+commands[gomi]} )) && alias rm="gomi"
alias ...="cd ../.."
alias ....="cd ../../.."

alias -s {md,txt,json,yaml,yml,toml,py,rs,go,ts,js,sh,zsh}=nvim

eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

# --- Catppuccin Latte ---

# fzf
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
  --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
  --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
  --color=selected-bg:#BCC0CC \
  --color=border:#9CA0B0,label:#4C4F69"




if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
