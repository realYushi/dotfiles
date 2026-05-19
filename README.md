# ~/.config dotfiles

This repo is meant to be a selective backup of the hand-maintained parts of `~/.config`.

## Intentionally ignored

- caches, logs, and shell history
- nested `.git/` directories from embedded repos
- local agent/editor state (`.pi/`, `.claude/`, `.zed/`)
- vendored dependencies and plugin checkouts (`node_modules/`, `tmux/plugins/`)
- relocated tool homes with mixed config/auth/history (`claude/`, `codex/`, `pi/`, `swiftpm/`)
- machine-local overrides like `tmux/tmux.local.conf`
- known credential files like `cliamp/ytmusic_credentials.json`

## First commit

```bash
cd ~/.config
git init
git add .
git status --short
git commit -m "Initial dotfiles backup"
```

## Restore notes

- tmux plugins are reinstalled through TPM.
- Zim regenerates `zsh/.zim/` from `zsh/.zimrc`.
- Nested repo metadata is ignored, but the working files still back up normally.
