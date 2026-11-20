These two files belong in `$HOME`, not in `~/.config`:

```bash
cp zsh/.zshrc    ~/.zshrc
cp zsh/.zprofile ~/.zprofile
```

They are kept here so a fresh machine can restore them with the rest of the
config. `$ZDOTDIR` is left at its default, so zsh reads `~/.zshrc` directly.
