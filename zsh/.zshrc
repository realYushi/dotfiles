# ---------------------------------------------------------------------------
# ~/.zshrc — interactive shell config
# Homebrew env lives in ~/.zprofile (login shells)
# ---------------------------------------------------------------------------

# --- History ---------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt extended_history        # timestamp + duration
setopt hist_expire_dups_first
setopt hist_ignore_dups        # skip consecutive duplicates
setopt hist_ignore_space       # leading space = don't record
setopt hist_verify
setopt share_history           # sync across tabs
setopt inc_append_history
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# --- Interactive behaviour -------------------------------------------------
setopt interactive_comments
setopt correct                 # spelling correction for commands
unsetopt flow_control          # free up ^S / ^Q
setopt no_beep
setopt prompt_subst
setopt complete_in_word
setopt always_to_end

WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'

# --- PATH ------------------------------------------------------------------
typeset -U path
path=(
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
export PATH

# Completion dirs — must all be on fpath BEFORE compinit runs
typeset -U fpath
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi
# extra completion definitions (docker, terraform, kubectl, rg, tmux, ...)
if [[ -d /opt/homebrew/share/zsh-completions ]]; then
  fpath=(/opt/homebrew/share/zsh-completions $fpath)
fi

# --- Editor / pager --------------------------------------------------------
# `--wait` makes zed block until the file is closed — required for git commit,
# crontab -e, rebase -i, etc. Plain `zed` returns immediately.
export EDITOR='zed --wait'
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"
export SUDO_EDITOR="$EDITOR"
# code-style CLI so muscle memory works
if command -v zed >/dev/null 2>&1; then
  alias v='zed'
  alias v.='zed .'
fi
# accept the grey autosuggestion with ctrl-space (right arrow / end also work)
# NOTE: bound later, after zsh-autosuggestions registers the widget
export PAGER=less
export LESS='-R -F -X -i -M'
export MANPAGER='less -R'
export BAT_PAGER='less -R'
export BAT_THEME='Catppuccin Latte'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# macOS has no `dircolors`, so give zsh completion (and eza/bat) a color map.
# Catppuccin Latte, expressed as ANSI codes, tuned for a LIGHT background.
if [[ -z $LS_COLORS ]]; then
  export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=33:cd=33:su=37;41:sg=30;43:tw=34:ow=34:st=37;44:*.tar=31:*.tgz=31:*.zip=31:*.gz=31:*.bz2=31:*.xz=31:*.zst=31:*.7z=31:*.rar=31:*.jpg=35:*.jpeg=35:*.png=35:*.gif=35:*.svg=35:*.webp=35:*.mp3=35:*.mp4=35:*.mkv=35:*.pdf=35:*.md=33:*.json=33:*.yml=33:*.yaml=33:*.toml=33:*.js=33:*.ts=33:*.py=33:*.go=33:*.rs=33:*.sh=32:*.zsh=32:*.bash=32'
fi

# --- Tool config -----------------------------------------------------------
export STARSHIP_CONFIG=$HOME/.config/starship.toml
# Catppuccin Latte
export FZF_DEFAULT_OPTS="
  --height 60% --layout=reverse --border --info=inline
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color=fg:#4c4f69,bg:#eff1f5,hl:#d20f39
  --color=fg+:#4c4f69,bg+:#ccd0da,hl+:#d20f39
  --color=info:#8839ef,prompt:#8839ef,pointer:#dc8a78,marker:#7287fd,spinner:#dc8a78,header:#d20f39
  --color=border:#9ca0b0,label:#4c4f69,query:#4c4f69
  --color=selected-bg:#bcc0cc
"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || eza -la --color=always {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} 2>/dev/null'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap"

# --- Quick aliases ---------------------------------------------------------
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -l --group-directories-first --icons=auto --git --time-style=long-iso'
alias la='eza -la --group-directories-first --icons=auto --git --time-style=long-iso'
alias lt='eza --tree --level=2 --icons=auto'
alias l.='eza -ld .*'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias h='history 1'
alias reload='exec zsh -l'
alias c='clear'
alias mkdir='mkdir -p'
alias tree='eza --tree --icons=auto'
alias cat='bat --paging=never'
alias df='df -h'
alias du='du -h'
alias ip='curl -s https://ifconfig.me; echo'
alias ports='lsof -iTCP -sTCP:LISTEN -P -n'
alias myip='ipconfig getifaddr en0'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# git
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --graph --oneline --decorate -20'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase --autostash'
alias gst='git stash'
alias gstp='git stash pop'
alias glg='lazygit'

# brew
alias bs='brew search'
alias bi='brew install'
alias bci='brew install --cask'
alias bu='brew upgrade && brew cleanup'
alias bd='brew doctor'

# --- Completions -----------------------------------------------------------
# compinit and ZLE widgets only make sense in a real interactive shell
if [[ -o interactive ]] && [[ -t 0 ]]; then
  autoload -Uz compinit
  # rebuild the dump at most once a day
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi

  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
  zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache
  # case-insensitive, substring matching, and . / .. in cd
  zstyle ':completion:*' special-dirs true
  zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
fi

# --- Key bindings (vi or emacs) -------------------------------------------
# bindkey needs ZLE, which only exists in real interactive shells
if [[ -t 0 ]]; then
  bindkey -e                      # emacs keys; switch to `bindkey -v` for vi
  bindkey '^[[A' up-line-or-search
  bindkey '^[[B' down-line-or-search
  bindkey '^[[1;5C' forward-word   # ctrl+right
  bindkey '^[[1;5D' backward-word  # ctrl+left
  bindkey '^H' backward-kill-word  # ctrl+backspace
fi

# --- Tool init -------------------------------------------------------------

# --- mise (dev tool version manager) ----------------------------------------
# Puts mise-installed shims ahead of Homebrew on PATH, and swaps versions
# automatically per directory. Must come after compinit so it can hook it.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# --- Quality of life: autosuggestions (grey ghost text from history) ------
if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9ca0b0'      # catppuccin latte overlay0
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)     # history first, then completion
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40                # skip huge pastes
  ZSH_AUTOSUGGEST_HISTORY_IGNORE='?(#c0,2)'         # ignore 1-2 char entries
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # accept the grey ghost text with ctrl-space
  bindkey '^ ' autosuggest-accept
fi

# fzf (its zsh integration calls zle, which only exists with an active terminal)
if (( $+commands[fzf] )) && [[ -t 0 ]]; then
  source <(fzf --zsh)
fi
# zoxide (cd smarter: `z foo`, `zi` interactive)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# starship prompt (keep last so it can override the prompt)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f %# '
fi

# --- Quality of life: syntax highlighting (must be sourced LAST) ----------
# turns commands green when valid, red when not; paths/strings/options colored
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  # styles are read at highlight time, so they must be set AFTER sourcing
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
  # Catppuccin Latte palette — readable on a light background
  ZSH_HIGHLIGHT_STYLES[command]=fg=#40a02b,bold
  ZSH_HIGHLIGHT_STYLES[builtin]=fg=#40a02b,bold
  ZSH_HIGHLIGHT_STYLES[alias]=fg=#179299,bold
  ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=#d20f39,bold
  ZSH_HIGHLIGHT_STYLES[path]=fg=#1e66f5,underline
  ZSH_HIGHLIGHT_STYLES[globbing]=fg=#8839ef
  ZSH_HIGHLIGHT_STYLES[comment]=fg=#9ca0b0
  ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=#df8e1d
  ZSH_HIGHLIGHT_STYLES[assign]=fg=#8839ef
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=#df8e1d
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=#df8e1d
  ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=fg=#df8e1d
  ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=#179299,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=#8839ef,bold
  ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold,underline
  ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
fi
