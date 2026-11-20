# ~/.config dotfiles

A selective backup of the hand-maintained parts of `~/.config` on macOS.

The repo root **is** `~/.config`, so files here land at their real paths.

## Layout

| Path | What |
|---|---|
| `starship.toml` | prompt, Catppuccin Latte palette |
| `git/config` | XDG gitconfig (identity, delta + catppuccin-latte, rerere) |
| `git/ignore` | global gitignore |
| `zed/` | `settings.json`, `keymap.json`, `themes/catppuccin.json` |
| `bat/` | config + `Catppuccin-Latte.tmTheme` |
| `eza/theme.yml` | Catppuccin Latte file colours |
| `yazi/` | theme, keymap, plugins, flavors |
| `lazygit/`, `gomi/` | TUI configs |
| `mise/config.toml` | global tool versions |
| `billion-context/`, `magpie/`, `herdr-app/`, `omniwm/` | app settings only |

Shell config lives outside this repo: `~/.zshrc` and `~/.zprofile` in `$HOME`.

## Intentionally ignored

- caches, logs, and shell history
- nested `.git/` directories from embedded repos
- local editor/agent state (`.pi/`, `.claude/`, `.zed/`)
- vendored dependencies and plugin checkouts (`node_modules/`)
- GUI app internals — binaries, caches, session state, update payloads
  (only the settings files under `1Password/`, `billion-context/`,
  `herdr-app/`, `magpie/`, `omniwm/` are tracked)
- credential files. `gh/hosts.yml` and `magpie/providers.json` hold OAuth
  tokens / provider API keys and must never be committed.

## Restore on a new machine

```bash
brew install git mise
git clone git@github.com:realYushi/dotfiles.git ~/.config

# tools referenced by these configs
brew install starship bat eza yazi lazygit gomi git-delta neovim \
             fzf zoxide zsh-autosuggestions zsh-completions zsh-syntax-highlighting
brew install --cask zed font-jetbrains-mono-nerd-font

mise install          # bun, node, python 3.13, ruby, rust, uv
```

Then create `~/.ssh/config` pointing at the 1Password agent, and copy
`~/.zshrc` / `~/.zprofile` across.

## Notes

- Zed's Catppuccin themes come from `catppuccin/zed` (`themes/catppuccin.json`);
  Zed ships none of them.
- `git/config` is XDG-only. There must be **no** `~/.gitconfig`, or the two
  disagree and the `$HOME` one wins.
- Yazi plugins are reinstalled with `ya pkg install`.
